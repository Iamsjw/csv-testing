import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class BleBroadcastIndicatorWidget extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final String sessionId;
  final bool isAdvertising;

  const BleBroadcastIndicatorWidget({
    super.key,
    required this.pulseAnimation,
    required this.sessionId,
    required this.isAdvertising,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassMorphism(
        borderRadius: BorderRadius.circular(20),
        opacity: isAdvertising ? 0.10 : 0.05,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isAdvertising
                  ? AppTheme.primary.withAlpha(26)
                  : AppTheme.surface.withAlpha(13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAdvertising
                    ? AppTheme.primary.withAlpha(102)
                    : AppTheme.shadowLight.withAlpha(25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Animated BLE pulse rings
                AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, child) {
                    return SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ring
                          if (isAdvertising)
                            Transform.scale(
                              scale: pulseAnimation.value * 1.4,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primary.withAlpha(
                                      ((1 - pulseAnimation.value) * 0.4 * 255)
                                          .round(),
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          // Middle ring
                          if (isAdvertising)
                            Transform.scale(
                              scale: pulseAnimation.value * 1.1,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primary.withAlpha(
                                      ((1 - pulseAnimation.value) * 0.5 * 255)
                                          .round(),
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          // Core
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAdvertising
                                  ? AppTheme.primary.withAlpha(51)
                                  : AppTheme.surface.withAlpha(13),
                              border: Border.all(
                                color: isAdvertising
                                    ? AppTheme.primary.withAlpha(153)
                                    : AppTheme.shadowLight.withAlpha(38),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.bluetooth_rounded,
                              color: isAdvertising
                                  ? AppTheme.primary
                                  : AppTheme.textDisabled,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isAdvertising ? 'BLE Broadcasting' : 'BLE Inactive',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isAdvertising
                                  ? AppTheme.successSoft
                                  : AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAdvertising ? 'ACTIVE' : 'OFF',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isAdvertising
                                    ? AppTheme.success
                                    : AppTheme.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAdvertising
                            ? 'Students within range can detect this session'
                            : 'BLE advertising not started',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      if (isAdvertising) ...[
                        const SizedBox(height: 6),
                        Text(
                          'ID: ${sessionId.substring(0, 8).toUpperCase()}...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primary.withAlpha(204),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
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
