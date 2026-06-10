import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/ble_service.dart';

class BleScanWidget extends StatefulWidget {
  final int currentRssi;
  final int rssiThreshold;

  const BleScanWidget({
    super.key,
    required this.currentRssi,
    required this.rssiThreshold,
  });

  @override
  State<BleScanWidget> createState() => _BleScanWidgetState();
}

class _BleScanWidgetState extends State<BleScanWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  late Animation<double> _radarAnim;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _radarAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _radarController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Color _statusColor(bool isInRange, bool isDetected) {
    if (isInRange) return AppTheme.success;
    if (isDetected) return AppTheme.warning;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final isDetected = widget.currentRssi > -95;
    final isInRange = widget.currentRssi >= widget.rssiThreshold - 5;
    final statusColor = _statusColor(isInRange, isDetected);

    return Container(
      decoration: AppTheme.glassMorphism(
        borderRadius: BorderRadius.circular(20),
        opacity: isInRange
            ? 0.10
            : isDetected
            ? 0.08
            : 0.05,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface.withAlpha(13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withAlpha(77), width: 1),
            ),
            child: Row(
              children: [
                // Radar animation
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _radarAnim,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _RadarPainter(
                              progress: _radarAnim.value,
                              color: statusColor,
                            ),
                            size: const Size(72, 72),
                          );
                        },
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor.withAlpha(51),
                        ),
                        child: Icon(
                          Icons.bluetooth_searching_rounded,
                          color: statusColor,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isInRange
                            ? 'In Range — Verifying...'
                            : isDetected
                            ? 'Signal Weak — Move Closer'
                            : 'Scanning for Teacher Device...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDetected
                            ? 'RSSI: ${widget.currentRssi} dBm · ${BleService.rssiQualityLabel(widget.currentRssi)}'
                            : 'Looking for BLE broadcast nearby',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress indicator
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          backgroundColor: AppTheme.shadowLight.withAlpha(20),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            statusColor,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final ringProgress = ((progress - i * 0.33) % 1.0).clamp(0.0, 1.0);
      final radius = maxRadius * ringProgress;
      final opacity = (1 - ringProgress) * 0.5;

      final paint = Paint()
        ..color = color.withAlpha((opacity * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius, paint);
    }

    // Sweep arc
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + progress * 2 * pi,
        colors: [color.withAlpha(0), color.withAlpha(77)],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius * 0.85),
      -pi / 2,
      progress * 2 * pi,
      true,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
