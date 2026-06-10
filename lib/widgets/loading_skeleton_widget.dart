import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoadingSkeletonWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeletonWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<LoadingSkeletonWidget> createState() => _LoadingSkeletonWidgetState();
}

class _LoadingSkeletonWidgetState extends State<LoadingSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppTheme.surfaceVariant,
                AppTheme.surfaceRaised,
                AppTheme.surfaceVariant,
              ],
              stops: [
                (_shimmerAnimation.value - 0.5).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.5).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AttendanceListSkeletonWidget extends StatelessWidget {
  const AttendanceListSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              LoadingSkeletonWidget(width: 44, height: 44, borderRadius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeletonWidget(
                      width: double.infinity,
                      height: 14,
                      borderRadius: 7,
                    ),
                    const SizedBox(height: 6),
                    LoadingSkeletonWidget(
                      width: 120,
                      height: 11,
                      borderRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              LoadingSkeletonWidget(width: 64, height: 26, borderRadius: 8),
            ],
          ),
        ),
      ),
    );
  }
}
