import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/ble_service.dart';
import '../../../theme/app_theme.dart';

class RssiMeterWidget extends StatelessWidget {
  final int rssi;
  final int threshold;

  const RssiMeterWidget({
    super.key,
    required this.rssi,
    required this.threshold,
  });

  Color get _signalColor {
    if (rssi >= threshold) return AppTheme.success;
    if (rssi >= threshold - 10) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final quality = BleService.rssiQualityPercent(rssi);
    final signalColor = _signalColor;

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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface.withAlpha(13),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.shadowLight.withAlpha(25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.signal_cellular_alt_rounded,
                          size: 14,
                          color: signalColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Signal Strength',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '$rssi dBm',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: signalColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          BleService.rssiQualityLabel(rssi),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Signal bars
                Row(
                  children: List.generate(10, (i) {
                    final barFilled = quality * 10 > i;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 20.0 * (0.4 + i * 0.06),
                          decoration: BoxDecoration(
                            color: barFilled
                                ? signalColor
                                : AppTheme.shadowLight.withAlpha(20),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Required: ≥ $threshold dBm',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: rssi >= threshold
                            ? AppTheme.successSoft
                            : AppTheme.errorSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rssi >= threshold ? 'IN RANGE' : 'TOO FAR',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: rssi >= threshold
                              ? AppTheme.success
                              : AppTheme.error,
                          letterSpacing: 0.5,
                        ),
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
