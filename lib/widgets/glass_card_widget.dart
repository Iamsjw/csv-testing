import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GlassCardWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isRaised;

  const GlassCardWidget({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.isRaised = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: AppTheme.neumorphic(
        borderRadius: BorderRadius.circular(borderRadius),
        isRaised: isRaised,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: null, // No splash if no onTap
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding ?? const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withAlpha(200),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: AppTheme.shadowLight.withAlpha(30),
                    width: 1,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
