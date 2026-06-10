import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/ble_service.dart';
import './widgets/attendance_history_widget.dart';
import './widgets/ble_scan_widget.dart';
import './widgets/code_entry_widget.dart';
import './widgets/rssi_meter_widget.dart';

enum _MarkingState {
  idle,
  enteringCode,
  scanningBle,
  verifying,
  success,
  failed,
}

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // TODO: Replace with Riverpod StudentAttendanceNotifier for production

  UserModel? _currentUser;
  List<AttendanceModel> _attendanceHistory = [];
  SessionModel? _currentSession;

  _MarkingState _markingState = _MarkingState.idle;
  int _currentRssi = -100;
  String? _errorMessage;
  bool _isLoading = true;
  bool _permissionsGranted = false;
  bool _bluetoothOn = false;
  bool _bleDialogShown = false;

  late AnimationController _successController;
  late AnimationController _entranceController;
  late AnimationController _shakeController;
  late Animation<double> _successScale;
  late Animation<double> _entranceFade;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOutBack),
    );
    _entranceFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    _loadInitialData();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from Android Settings (e.g., after enabling Bluetooth),
    // re-check Bluetooth status so the UI updates without requiring a manual refresh.
    if (state == AppLifecycleState.resumed) {
      BleService.isBluetoothOn().then((isOn) {
        if (mounted) {
          setState(() => _bluetoothOn = isOn);
          if (isOn) {
            _bleDialogShown = false; // BT is now on, reset flag
          }
        }
      }).catchError((_) {});
    }
  }

  Future<void> _refreshData() async {
    try {
      _currentUser = await SupabaseService.getCurrentUserProfile();
      if (_currentUser == null) return;
      _attendanceHistory = await SupabaseService.getStudentAttendanceHistory(
        _currentUser!.id,
      );
      _bluetoothOn = await BleService.isBluetoothOn();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = await SupabaseService.getCurrentUserProfile();
      if (_currentUser == null) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.signUpLoginScreen,
            (_) => false,
          );
        }
        return;
      }

      _attendanceHistory = await SupabaseService.getStudentAttendanceHistory(
        _currentUser!.id,
      );
      _permissionsGranted = await BleService.requestPermissions();
      _bluetoothOn = await BleService.isBluetoothOn();

      if (mounted) {
        setState(() => _isLoading = false);
        _entranceController.forward();

        // Show Bluetooth dialog if off
        if (!_bluetoothOn && !_bleDialogShown) {
          _bleDialogShown = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _showBluetoothDialog();
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBluetoothDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.warningSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bluetooth_disabled_rounded,
                color: AppTheme.warning,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bluetooth is Off',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please turn on Bluetooth to use proximity verification for HIGH security sessions. Without Bluetooth, you may not be able to mark attendance in some sessions.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _bleDialogShown = false;
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'Dismiss',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Just dismiss — the app lifecycle observer will
                      // re-check Bluetooth state when the user returns
                      // from Android Settings (didChangeAppLifecycleState).
                      // This avoids crashing when the system Bluetooth
                      // enable dialog triggers an Activity lifecycle change.
                      _bleDialogShown = false;
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'Enable Bluetooth',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCode(String code) async {
    if (code.length != 6) return;
    setState(() {
      _errorMessage = null;
      _markingState = _MarkingState.verifying;
    });

    try {
      // Find session by code
      final session = await SupabaseService.getActiveSessionByCode(code);

      if (session == null) {
        _setError('Invalid or expired session code.');
        return;
      }

      // Check if already marked
      final alreadyMarked = await SupabaseService.hasStudentMarkedAttendance(
        studentId: _currentUser!.id,
        sessionId: session.id,
      );
      if (alreadyMarked) {
        _setError('You have already marked attendance for this session.');
        return;
      }

      _currentSession = session;

      if (session.securityLevel == 'HIGH') {
        // BLE verification required
        setState(() => _markingState = _MarkingState.scanningBle);
        await _performBleVerification(session);
      } else {
        // LOW security — direct mark
        await _markAttendance(session.id);
      }
    } catch (e) {
      _setError('Verification failed. Please try again.');
    }
  }

  Future<void> _performBleVerification(SessionModel session) async {
    if (!_permissionsGranted) {
      _setError('Bluetooth permissions required for HIGH security sessions.');
      return;
    }
    if (!_bluetoothOn) {
      _setError('Please enable Bluetooth to verify proximity.');
      return;
    }

    try {
      final result = await BleService.scanForSession(
        sessionId: session.id,
        timeoutSeconds: 15,
        rssiThreshold: session.rssiThreshold,
        onRssiUpdate: (rssi) {
          if (mounted) setState(() => _currentRssi = rssi);
        },
      );

      if (result == null) {
        // BLE scan failed — offer manual fallback
        _offerManualFallback(session);
        return;
      }

      // RSSI tolerance: ±5 dBm
      final adjustedThreshold = session.rssiThreshold - 5;
      if (result.rssi >= adjustedThreshold) {
        await _markAttendance(session.id);
      } else {
        _setError(
          'You are too far from the classroom. Move closer and try again.\nDetected RSSI: ${result.rssi} dBm (Required: ≥ ${session.rssiThreshold} dBm)',
        );
      }
    } catch (e) {
      _offerManualFallback(session);
    }
  }

  void _offerManualFallback(SessionModel session) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => _BleFailedDialog(
        onRetry: () {
          Navigator.pop(ctx);
          setState(() => _markingState = _MarkingState.scanningBle);
          _performBleVerification(session);
        },
        onCancel: () {
          Navigator.pop(ctx);
          setState(() => _markingState = _MarkingState.idle);
        },
      ),
    );
  }

  Future<void> _markAttendance(String sessionId) async {
    setState(() => _markingState = _MarkingState.verifying);
    final success = await SupabaseService.markAttendance(
      studentId: _currentUser!.id,
      sessionId: sessionId,
    );

    if (success) {
      setState(() {
        _markingState = _MarkingState.success;
      });
      _successController.forward();
      // Reload history
      _attendanceHistory = await SupabaseService.getStudentAttendanceHistory(
        _currentUser!.id,
      );
      if (mounted) setState(() {});

      // Auto-reset after 3 seconds
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _markingState = _MarkingState.idle;
            _currentRssi = -100;
          });
          _successController.reset();
        }
      });
    } else {
      _setError(
        'Failed to mark attendance. Already marked or session expired.',
      );
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _markingState = _MarkingState.failed;
    });
    _shakeController.forward(from: 0);
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _markingState = _MarkingState.idle;
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sign Out',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await SupabaseService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.signUpLoginScreen,
        (_) => false,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _successController.dispose();
    _entranceController.dispose();
    _shakeController.dispose();
    BleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.surface,
              title: Text(
                'Sign Out',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              content: Text(
                'Do you want to sign out?',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          );
          if (shouldExit ?? false) {
            await _signOut();
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.background,
          body: Stack(
            children: [
              _buildBackground(),
              SafeArea(
                child: _isLoading
                    ? _buildLoadingState()
                    : RefreshIndicator(
                        onRefresh: _refreshData,
                        color: AppTheme.primary,
                        backgroundColor: AppTheme.surface,
                        child: FadeTransition(
                          opacity: _entranceFade,
                          child: isTablet
                              ? _buildTabletLayout()
                              : _buildPhoneLayout(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.8, -0.6),
            radius: 1.0,
            colors: [AppTheme.primaryCyan.withAlpha(18), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: AppTheme.primaryCyan,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        _buildAppBar(),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Success overlay
              if (_markingState == _MarkingState.success)
                _buildSuccessCard()
              else ...[
                _buildMarkAttendanceSection(),
                const SizedBox(height: 24),
                AttendanceHistoryWidget(history: _attendanceHistory),
              ],
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 10, 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_markingState == _MarkingState.success)
                      _buildSuccessCard()
                    else
                      _buildMarkAttendanceSection(),
                  ]),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 20, 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Expanded(
                  child: AttendanceHistoryWidget(history: _attendanceHistory),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.shadowLight.withAlpha(25),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.shadowLight.withAlpha(25),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UpasthitiX',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (_currentUser != null)
                Text(
                  _currentUser!.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        // BLE status indicator
        Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _bluetoothOn
                ? AppTheme.primaryCyan.withAlpha(26)
                : AppTheme.surface.withAlpha(13),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bluetooth_rounded,
                size: 14,
                color: _bluetoothOn ? AppTheme.primaryCyan : AppTheme.textMuted,
              ),
              const SizedBox(width: 3),
              Text(
                _bluetoothOn ? 'ON' : 'OFF',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _bluetoothOn
                      ? AppTheme.primaryCyan
                      : AppTheme.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _signOut,
          icon: Icon(
            Icons.logout_rounded,
            color: AppTheme.textSecondary,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildMarkAttendanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting
        _buildGreetingCard(),
        const SizedBox(height: 20),

        // BLE scan state
        if (_markingState == _MarkingState.scanningBle) ...[
          BleScanWidget(
            currentRssi: _currentRssi,
            rssiThreshold: _currentSession?.rssiThreshold ?? -70,
          ),
          const SizedBox(height: 16),
        ],

        // RSSI meter when scanning
        if (_markingState == _MarkingState.scanningBle &&
            _currentRssi > -100) ...[
          RssiMeterWidget(
            rssi: _currentRssi,
            threshold: _currentSession?.rssiThreshold ?? -70,
          ),
          const SizedBox(height: 16),
        ],

        // Error message
        if (_errorMessage != null) _buildErrorCard(),

        // Code entry (shown when idle or failed)
        if (_markingState == _MarkingState.idle ||
            _markingState == _MarkingState.failed ||
            _markingState == _MarkingState.enteringCode) ...[
          CodeEntryWidget(
            onCodeSubmit: _submitCode,
            isLoading: _markingState == _MarkingState.verifying,
            shakeAnimation: _shakeAnim,
            hasError: _markingState == _MarkingState.failed,
          ),
        ],

        if (_markingState == _MarkingState.verifying &&
            _markingState != _MarkingState.scanningBle)
          _buildVerifyingCard(),

        // BLE permission warning
        if (!_permissionsGranted || !_bluetoothOn) _buildBleWarningCard(),
      ],
    );
  }

  Widget _buildGreetingCard() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    final presentToday = _attendanceHistory
        .where(
          (a) =>
              a.isPresent &&
              a.timestamp.day == DateTime.now().day &&
              a.timestamp.month == DateTime.now().month,
        )
        .length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryCyan.withAlpha(31),
            AppTheme.primaryBlue.withAlpha(20),
          ],
        ),
        border: Border.all(color: AppTheme.primaryCyan.withAlpha(64), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting,',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        _currentUser?.name ?? 'Student',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$presentToday class${presentToday != 1 ? 'es' : ''} attended today',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.primaryCyan,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryCyan.withAlpha(26),
                    border: Border.all(
                      color: AppTheme.primaryCyan.withAlpha(77),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _currentUser?.name.isNotEmpty == true
                          ? _currentUser!.name[0].toUpperCase()
                          : 'S',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryCyan,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return ScaleTransition(
      scale: _successScale,
      child: Container(
        decoration: AppTheme.glassMorphism(
          borderRadius: BorderRadius.circular(24),
          opacity: 0.10,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.successSoft,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.success.withAlpha(77),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.success.withAlpha(34),
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.success,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Attendance Marked!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentSession != null
                        ? 'Session code: ${_currentSession!.code}'
                        : 'Your attendance has been recorded',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Redirecting in 3 seconds...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyingCard() {
    return Container(
      decoration: AppTheme.glassMorphism(
        borderRadius: BorderRadius.circular(16),
        opacity: 0.05,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface.withAlpha(13),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.shadowLight.withAlpha(25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Verifying attendance...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.error.withAlpha(77), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBleWarningCard() {
    if (_permissionsGranted && _bluetoothOn) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withAlpha(77), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !_permissionsGranted
                      ? 'Bluetooth permissions required'
                      : 'Bluetooth is turned off',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warning,
                  ),
                ),
                Text(
                  !_permissionsGranted
                      ? 'Grant permissions for HIGH security sessions'
                      : 'Enable Bluetooth for proximity verification',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              _permissionsGranted = await BleService.requestPermissions();
              _bluetoothOn = await BleService.isBluetoothOn();
              if (mounted) setState(() {});
            },
            child: Text(
              'Fix',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BLE Failed Dialog ───────────────────────────────────────────────────────

class _BleFailedDialog extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _BleFailedDialog({required this.onRetry, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.warningSoft,
              ),
              child: Icon(
                Icons.bluetooth_disabled_rounded,
                color: AppTheme.warning,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'BLE Scan Failed',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Couldn't detect the teacher's device. Make sure you're in the classroom and Bluetooth is enabled.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onRetry,
                    child: Text(
                      'Retry Scan',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
