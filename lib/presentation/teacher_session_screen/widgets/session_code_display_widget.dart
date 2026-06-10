import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class SessionCodeDisplayWidget extends StatelessWidget {
  final String code;
  final int remainingSeconds;
  final int totalSeconds;
  final String Function(int) formatDuration;
  final String securityLevel;

  const SessionCodeDisplayWidget({
    super.key,
    required this.code,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.formatDuration,
    required this.securityLevel,
  });

  double get _progressValue {
    if (totalSeconds == 0) return 0;
    return (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  Color get _timerColor {
    if (_progressValue > 0.5) return AppTheme.success;
    if (_progressValue > 0.25) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final isHigh = securityLevel == 'HIGH';
    return Container(
      decoration: AppTheme.glassMorphism(
        borderRadius: BorderRadius.circular(20),
        opacity: 0.08,
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
              border: Border.all(
                color: AppTheme.shadowLight.withAlpha(25),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Session Code',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isHigh
                            ? AppTheme.successSoft
                            : AppTheme.warningSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHigh
                                ? Icons.bluetooth_searching_rounded
                                : Icons.pin_outlined,
                            size: 12,
                            color: isHigh ? AppTheme.success : AppTheme.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$securityLevel SECURITY',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isHigh
                                  ? AppTheme.success
                                  : AppTheme.warning,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 6-digit code display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    return _CodeDigit(digit: code[i], index: i);
                  }),
                ),
                const SizedBox(height: 8),
                // Copy button
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Code copied to clipboard',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12),
                        ),
                        backgroundColor: AppTheme.surfaceVariant,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  label: Text(
                    'Copy Code',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Timer progress
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Time Remaining',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        Text(
                          formatDuration(remainingSeconds),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _timerColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressValue,
                        backgroundColor: AppTheme.shadowLight.withAlpha(20),
                        valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeDigit extends StatefulWidget {
  final String digit;
  final int index;

  const _CodeDigit({required this.digit, required this.index});

  @override
  State<_CodeDigit> createState() => _CodeDigitState();
}

class _CodeDigitState extends State<_CodeDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.index * 0.08,
          widget.index * 0.08 + 0.5,
          curve: Curves.easeOutBack,
        ),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: 44,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.surface.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primary.withAlpha(102),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              widget.digit,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
