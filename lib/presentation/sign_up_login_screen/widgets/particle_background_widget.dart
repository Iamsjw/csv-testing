import 'dart:math';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class _Particle {
  double x, y, vx, vy, size, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
  });
}

class ParticleBackgroundWidget extends StatefulWidget {
  const ParticleBackgroundWidget({super.key});

  @override
  State<ParticleBackgroundWidget> createState() =>
      _ParticleBackgroundWidgetState();
}

class _ParticleBackgroundWidgetState extends State<ParticleBackgroundWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rng = Random();
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(_updateParticles)
          ..repeat();
  }

  void _initParticles(Size size) {
    if (_particles.isNotEmpty) return;
    _size = size;
    for (int i = 0; i < 60; i++) {
      _particles.add(
        _Particle(
          x: _rng.nextDouble() * size.width,
          y: _rng.nextDouble() * size.height,
          vx: (_rng.nextDouble() - 0.5) * 0.4,
          vy: (_rng.nextDouble() - 0.5) * 0.4,
          size: _rng.nextDouble() * 3 + 1,
          opacity: _rng.nextDouble() * 0.5 + 0.1,
        ),
      );
    }
  }

  void _updateParticles() {
    if (_size == Size.zero) return;
    setState(() {
      for (final p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        if (p.x < 0) p.x = _size.width;
        if (p.x > _size.width) p.x = 0;
        if (p.y < 0) p.y = _size.height;
        if (p.y > _size.height) p.y = 0;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _initParticles(Size(constraints.maxWidth, constraints.maxHeight));
        return CustomPaint(
          painter: _ParticlePainter(_particles),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.5, 0),
                radius: 1.2,
                colors: [AppTheme.backgroundVariant, AppTheme.background],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      paint.color = AppTheme.primaryBlue.withAlpha((p.opacity * 255).round());
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
