import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';

class BleAdvertisementData {
  final String sessionId;
  final int rssi;
  final String deviceId;

  const BleAdvertisementData({
    required this.sessionId,
    required this.rssi,
    required this.deviceId,
  });
}

class BleService {
  static StreamSubscription<List<ScanResult>>? _scanSubscription;
  static Timer? _scanTimer;
  static final List<int> _rssiSamples = [];
  static bool _isAdvertising = false;

  // Common service UUID for cross-platform BLE advertising/scanning.
  static const String upasthitixServiceUuid =
      "19B10000-E8F2-537E-4F6C-D104768A1214";

  // ---- Permissions ------------------------------------------------

  /// Checks if system-level location services (GPS) are enabled.
  /// Required for BLE scanning on Android 6-11 even when permission is granted.
  static Future<bool> isLocationEnabled() async {
    if (kIsWeb || Platform.isIOS) return true;
    try {
      return await Permission.locationWhenInUse.serviceStatus.isEnabled;
    } catch (_) {
      return true; // assume OK if check fails
    }
  }

  /// Request a single permission safely — returns its status.
  static Future<PermissionStatus> _requestOne(Permission p) async {
    try {
      return await p.request();
    } catch (e) {
      debugPrint('[BLE] Failed to request ${p.toString()}: $e');
      return PermissionStatus.denied;
    }
  }

  /// Check a single permission status safely.
  static Future<PermissionStatus> _checkOne(Permission p) async {
    try {
      return await p.status;
    } catch (e) {
      debugPrint('[BLE] Failed to check ${p.toString()}: $e');
      return PermissionStatus.denied;
    }
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      // Android: request location first (needed for all versions)
      if (Platform.isAndroid) {
        final loc = await _requestOne(Permission.locationWhenInUse);
        debugPrint('[BLE] locationWhenInUse = $loc');
        // ACCESS_FINE_LOCATION is required for BLE scanning on Android 6-11.
        // Requesting it explicitly fixes devices that only received coarse location.
        try {
          await _requestOne(Permission.location);
        } catch (_) {}
        // On Android 12+ also request Bluetooth permissions individually
        // Using try-catch per permission so one failure doesn't block others
        try {
          await _requestOne(Permission.bluetoothScan);
        } catch (_) {}
        try {
          await _requestOne(Permission.bluetoothConnect);
        } catch (_) {}
        // bluetoothAdvertise only exists on API 31+; request safely
        try {
          await _requestOne(Permission.bluetoothAdvertise);
        } catch (_) {
          // Not available on this device — ignore
        }
        // Success if location granted (minimum for scanning)
        final locStatus = await _checkOne(Permission.locationWhenInUse);
        final btScan = await _checkOne(Permission.bluetoothScan);
        final allGranted = locStatus.isGranted && btScan.isGranted;
        debugPrint('[BLE] Android permissions: loc=$locStatus btScan=$btScan -> $allGranted');
        return allGranted;
      }

      // iOS / others
      final results = await Future.wait([
        _requestOne(Permission.bluetoothScan),
        _requestOne(Permission.bluetoothConnect),
        _requestOne(Permission.locationWhenInUse),
      ]);
      final allGranted = results.every((s) => s.isGranted);
      debugPrint('[BLE] iOS/other permissions: $results -> granted=$allGranted');
      return allGranted;
    } catch (e) {
      debugPrint('[BLE] Permission request failed: $e');
      return false;
    }
  }

  static Future<bool> hasPermissions() async {
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        // On Android, location is the minimum requirement for BLE scan
        final loc = await _checkOne(Permission.locationWhenInUse);
        if (!loc.isGranted) return false;
        // On API 31+, also check BT permissions
        try {
          final btScan = await _checkOne(Permission.bluetoothScan);
          if (btScan != PermissionStatus.denied && !btScan.isGranted) return false;
        } catch (_) {}
        return true;
      }
      final results = await Future.wait([
        _checkOne(Permission.bluetoothScan),
        _checkOne(Permission.bluetoothConnect),
        _checkOne(Permission.locationWhenInUse),
      ]);
      return results.every((s) => s.isGranted);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isBluetoothOn() async {
    if (kIsWeb) return false;
    try {
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  // ---- Teacher: BLE Advertising ----------------------------------------

  static bool get isAdvertising => _isAdvertising;

  static Future<bool> isPeripheralSupported() async {
    if (kIsWeb) return false;
    try {
      return await FlutterBlePeripheral().isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Start advertising using manufacturerData + serviceUuid for maximum device compatibility.
  /// The serviceUuid is used as a scan filter target for reliable discovery.
  static Future<bool> startAdvertising(String sessionId) async {
    if (kIsWeb) {
      debugPrint('[BLE] Web not supported');
      return false;
    }

    // Stop any ongoing scan that might conflict
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    // Step 1: Check Bluetooth
    debugPrint('[BLE] Checking Bluetooth state...');
    final isOn = await isBluetoothOn();
    debugPrint('[BLE] Bluetooth isOn=$isOn');
    if (!isOn) {
      debugPrint('[BLE] Cannot advertise: Bluetooth is off');
      return false;
    }

    // Step 2: Check peripheral support
    debugPrint('[BLE] Checking peripheral support...');
    try {
      final supported = await isPeripheralSupported();
      debugPrint('[BLE] Peripheral supported=$supported');
      if (!supported) {
        debugPrint('[BLE] Peripheral mode not supported on this device');
        return false;
      }
    } catch (e) {
      debugPrint('[BLE] Error checking peripheral support: $e');
      return false;
    }

    // Step 3: Build advertising data with serviceUuid for reliable scanning
    try {
      final prefix = sessionId.length >= 8
          ? sessionId.substring(0, 8)
          : sessionId;
      debugPrint('[BLE] Advertising prefix: $prefix');
      final prefixBytes = utf8.encode(prefix);

      // Android: use manufacturerData + serviceUuid for reliable scanning on all devices.
      // The serviceUuid serves as a scan filter target for devices like Vivo/iQOO.
      // iOS: use serviceData with the serviceUuid.
      final advertiseData = Platform.isIOS
          ? AdvertiseData(
              serviceUuid: upasthitixServiceUuid,
              serviceData: Uint8List.fromList(prefixBytes),
              includeDeviceName: false,
            )
          : AdvertiseData(
              manufacturerId: 0x1234,
              manufacturerData: Uint8List.fromList(prefixBytes),
              serviceUuid: upasthitixServiceUuid,
              includeDeviceName: false,
            );

      final settings = AdvertiseSettings(
        // advertiseSet: false → legacy advertising mode.
        // Broader chipset compatibility (some mid-range Vivo/Realme chips do not
        // properly support extended / LE Coded advertising that advertiseSet:true uses).
        // Devices that already worked with true also work with false.
        advertiseSet: false,
        advertiseMode: AdvertiseMode.advertiseModeLowLatency,
        connectable: false,
        timeout: 0,
      );

      debugPrint('[BLE] Calling FlutterBlePeripheral().start()...');
      await FlutterBlePeripheral().start(
        advertiseData: advertiseData,
        advertiseSettings: settings,
      );
      debugPrint('[BLE] FlutterBlePeripheral().start() returned');

      // Give it a moment, then verify
      await Future.delayed(const Duration(milliseconds: 800));
      final advertising = await FlutterBlePeripheral().isAdvertising;
      debugPrint('[BLE] isAdvertising after start: $advertising');

      if (!advertising) {
        debugPrint('[BLE] Warning: isAdvertising is false after start()');
        await Future.delayed(const Duration(seconds: 1));
        final retry = await FlutterBlePeripheral().isAdvertising;
        debugPrint('[BLE] Retry isAdvertising: $retry');
        if (!retry) {
          _isAdvertising = false;
          return false;
        }
      }

      _isAdvertising = true;
      debugPrint(
        '[BLE] Started advertising session: $sessionId (prefix: $prefix)',
      );
      return true;
    } catch (e, stackTrace) {
      debugPrint('[BLE] Failed to start advertising: $e');
      debugPrint('[BLE] Stack trace: $stackTrace');
      return false;
    }
  }

  static Future<void> stopAdvertising() async {
    try {
      await FlutterBlePeripheral().stop();
      debugPrint('[BLE] FlutterBlePeripheral().stop() succeeded');
    } catch (e) {
      debugPrint('[BLE] Error stopping advertising: $e');
    }
    _isAdvertising = false;
    debugPrint('[BLE] Stopped advertising');
  }

  // ---- Student: BLE Scanning -------------------------------------------

  static Future<BleAdvertisementData?> scanForSession({
    required String sessionId,
    required int timeoutSeconds,
    required int rssiThreshold,
    void Function(int rssi)? onRssiUpdate,
  }) async {
    if (kIsWeb) return null;

    final isOn = await isBluetoothOn();
    if (!isOn) return null;

    // Check & request permissions if needed
    if (!await hasPermissions()) {
      debugPrint('[BLE] Permissions not granted, requesting...');
      if (!await requestPermissions()) {
        debugPrint('[BLE] Permission request failed or denied');
        return null;
      }
    }

    // On Android, verify location services are ON (required for BLE scan on API < 31)
    if (Platform.isAndroid) {
      final locEnabled = await isLocationEnabled();
      if (!locEnabled) {
        debugPrint('[BLE] Location services are OFF — BLE scan will not work');
        return null;
      }
    }

    _rssiSamples.clear();
    final completer = Completer<BleAdvertisementData?>();

    // ─── Two-phase scan strategy ─────────────────────────────────────────────
    //
    // Phase 1 — Filtered scan (first ~55 % of timeout):
    //   Passes a service-UUID filter to the OS.  On Android 12+ this routes the
    //   filter to the hardware scanner, bypassing OEM software throttling
    //   (Vivo / iQOO / Xiaomi / Realme).  Safe for already-working devices
    //   because the teacher already advertises upasthitixServiceUuid.
    //
    // Phase 2 — Unfiltered fallback (remaining ~45 % of timeout):
    //   Catches the rare edge case where a specific chipset does not surface the
    //   service UUID in the advertisement packet despite it being set, so the
    //   OS-level filter would have blocked it.  Devices found in Phase 1 are
    //   not re-scanned — the completer is already done.
    //
    // RSSI gate: 2 samples (was 3).  OEM-throttled devices can deliver fewer
    // scan events per second; 2 samples still gives a reliable average while
    // making detection 33 % faster on cooperating hardware.
    // ─────────────────────────────────────────────────────────────────────────
    final filteredSecs = (timeoutSeconds * 0.55).round();
    final fallbackSecs = timeoutSeconds - filteredSecs;
    Timer? phase2Timer;

    void processResults(List<ScanResult> results) {
      for (final result in results) {
        final matched = _isTargetSession(result, sessionId);
        if (matched) {
          final rssi = result.rssi;
          _rssiSamples.add(rssi);
          onRssiUpdate?.call(rssi);

          if (_rssiSamples.length >= 2) {
            final avgRssi =
                _rssiSamples.reduce((a, b) => a + b) ~/ _rssiSamples.length;
            if (!completer.isCompleted) {
              completer.complete(
                BleAdvertisementData(
                  sessionId: sessionId,
                  rssi: avgRssi,
                  deviceId: result.device.remoteId.str,
                ),
              );
            }
          }
        }
      }
    }

    try {
      // ── Phase 1: filtered ──────────────────────────────────────────────────
      debugPrint('[BLE] Phase 1: filtered scan for session: $sessionId '
          '(${filteredSecs}s)');
      final serviceFilter = Platform.isAndroid
          ? [Guid(upasthitixServiceUuid)]
          : <Guid>[];
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: filteredSecs),
        androidScanMode: AndroidScanMode.lowLatency,
        withServices: serviceFilter,
      );

      _scanSubscription =
          FlutterBluePlus.scanResults.listen(processResults);

      // ── Phase 2: unfiltered fallback ───────────────────────────────────────
      phase2Timer = Timer(Duration(seconds: filteredSecs), () async {
        if (completer.isCompleted) return;
        debugPrint('[BLE] Phase 2: switching to unfiltered fallback '
            '(${fallbackSecs}s)...');
        try {
          await FlutterBluePlus.stopScan();
          await Future.delayed(const Duration(milliseconds: 150));
          // Re-use the same _scanSubscription — scanResults stream
          // continues to emit during the new scan automatically.
          await FlutterBluePlus.startScan(
            timeout: Duration(seconds: fallbackSecs),
            androidScanMode: AndroidScanMode.lowLatency,
            // No withServices filter — catches everything
          );
        } catch (e) {
          debugPrint('[BLE] Phase 2 start error: $e');
        }
      });

      // Overall hard timeout (phase durations + small buffer)
      _scanTimer = Timer(Duration(seconds: timeoutSeconds + 2), () {
        if (!completer.isCompleted) {
          debugPrint('[BLE] Scan timed out after $timeoutSeconds seconds');
          completer.complete(null);
        }
      });

      final result = await completer.future;
      phase2Timer.cancel();
      await _stopScan();
      return result;
    } catch (e) {
      debugPrint('[BLE] Scan error: $e');
      phase2Timer?.cancel();
      await _stopScan();
      return null;
    }
  }

  /// Checks whether a scan result matches the target session.
  /// Uses multiple strategies for maximum reliability:
  /// (1) raw byte comparison, (2) UTF-8 string matching,
  /// (3) serviceData matching, (4) device name matching.
  static bool _isTargetSession(ScanResult result, String sessionId) {
    try {
      final prefix = sessionId.length >= 8
          ? sessionId.substring(0, 8)
          : sessionId;
      final prefixBytes = utf8.encode(prefix);

      // Check manufacturerData (primary method with flutter_ble_peripheral on Android)
      final mfgData = result.advertisementData.manufacturerData;
      for (final entry in mfgData.entries) {
        final value = entry.value;
        // Try raw byte comparison first (most reliable across devices)
        if (value.length >= prefixBytes.length) {
          bool match = true;
          for (int i = 0; i < prefixBytes.length; i++) {
            if (value[i] != prefixBytes[i]) {
              match = false;
              break;
            }
          }
          if (match) {
            debugPrint('[BLE] Matched via manufacturerData raw bytes: $prefix');
            return true;
          }
        }
        // Fallback to UTF-8 decode
        final decoded = utf8.decode(value, allowMalformed: true);
        if (decoded.contains(prefix)) {
          debugPrint('[BLE] Matched via manufacturerData UTF-8: $prefix');
          return true;
        }
      }

      // Check serviceData (used on iOS, and now also on Android)
      final svcData = result.advertisementData.serviceData;
      for (final entry in svcData.entries) {
        final value = entry.value;
        if (value.length >= prefixBytes.length) {
          bool match = true;
          for (int i = 0; i < prefixBytes.length; i++) {
            if (value[i] != prefixBytes[i]) {
              match = false;
              break;
            }
          }
          if (match) {
            debugPrint('[BLE] Matched via serviceData raw bytes: $prefix');
            return true;
          }
        }
        final decoded = utf8.decode(value, allowMalformed: true);
        if (decoded.contains(prefix)) {
          debugPrint('[BLE] Matched via serviceData UTF-8: $prefix');
          return true;
        }
      }

      // Fallback: match by device name
      final name = result.device.platformName;
      final advName = result.advertisementData.advName;
      final targetName = 'UX_$prefix';

      if (name.contains(targetName) ||
          advName.contains(targetName) ||
          name.contains('Upasthitix') ||
          advName.contains('Upasthitix')) {
        debugPrint('[BLE] Matched via device name: $targetName');
        return true;
      }

      // Extra debug: log nearby devices for troubleshooting
      if (result.rssi > -90) {
        debugPrint(
          '[BLE] Nearby device not matched - '
          'name: ${result.device.platformName}, '
          'rssi: ${result.rssi}, '
          'mfgIds: ${result.advertisementData.manufacturerData.keys.toList()}, '
          'svcUuids: ${result.advertisementData.serviceUuids}',
        );
      }
    } catch (e) {
      debugPrint('[BLE] Error matching session: $e');
    }
    return false;
  }

  static Future<void> _stopScan() async {
    try {
      _scanTimer?.cancel();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  static Future<void> dispose() async {
    await _stopScan();
    await stopAdvertising();
  }

  // ---- RSSI signal quality -------------------------------------------

  static String rssiQualityLabel(int rssi) {
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -60) return 'Good';
    if (rssi >= -70) return 'Fair';
    if (rssi >= -80) return 'Weak';
    return 'Very Weak';
  }

  static double rssiQualityPercent(int rssi) {
    return ((rssi + 100) / 70).clamp(0.0, 1.0);
  }
}
