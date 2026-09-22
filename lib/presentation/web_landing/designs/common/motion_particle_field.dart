import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Lightweight ambient particle and cinematic glow effect background.
/// Uses custom painting with a smooth ticker, consuming minimal CPU/GPU.
class MotionParticleField extends StatefulWidget {
  const MotionParticleField({
    super.key,
    this.primaryColor,
    this.secondaryColor,
    this.particleCount = 20,
  });

  final Color? primaryColor;
  final Color? secondaryColor;
  final int particleCount;

  @override
  State<MotionParticleField> createState() => _MotionParticleFieldState();
}

class _MotionParticleFieldState extends State<MotionParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final random = math.Random(42);
    _particles = List.generate(
      widget.particleCount,
      (_) => _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: random.nextDouble() * 2.8 + 1.2,
        speedX: (random.nextDouble() - 0.5) * 0.04,
        speedY: -random.nextDouble() * 0.06 - 0.02,
        opacity: random.nextDouble() * 0.45 + 0.15,
        pulseSpeed: random.nextDouble() * 2.0 + 1.0,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor ?? const Color(0xFFE50914);
    final secondary = widget.secondaryColor ?? const Color(0xFF3B82F6);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            primaryColor: primary,
            secondaryColor: secondary,
          ),
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedX,
    required this.speedY,
    required this.opacity,
    required this.pulseSpeed,
  });

  double x;
  double y;
  final double radius;
  final double speedX;
  final double speedY;
  final double opacity;
  final double pulseSpeed;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final List<_Particle> particles;
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    // Ambient glow orbs
    final glowPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.08),
          primaryColor.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * (0.2 + 0.1 * math.sin(progress * math.pi * 2)),
            size.height * (0.3 + 0.08 * math.cos(progress * math.pi * 2)),
          ),
          radius: size.width * 0.35,
        ),
      );
    canvas.drawCircle(
      Offset(
        size.width * (0.2 + 0.1 * math.sin(progress * math.pi * 2)),
        size.height * (0.3 + 0.08 * math.cos(progress * math.pi * 2)),
      ),
      size.width * 0.35,
      glowPaint1,
    );

    final glowPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          secondaryColor.withOpacity(0.06),
          secondaryColor.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * (0.8 - 0.08 * math.cos(progress * math.pi * 2)),
            size.height * (0.7 + 0.1 * math.sin(progress * math.pi * 2)),
          ),
          radius: size.width * 0.4,
        ),
      );
    canvas.drawCircle(
      Offset(
        size.width * (0.8 - 0.08 * math.cos(progress * math.pi * 2)),
        size.height * (0.7 + 0.1 * math.sin(progress * math.pi * 2)),
      ),
      size.width * 0.4,
      glowPaint2,
    );

    // Dynamic particles
    for (final p in particles) {
      final currentX = (p.x + p.speedX * progress * 5) % 1.0;
      final currentY = (p.y + p.speedY * progress * 5) % 1.0;
      final posX = (currentX < 0 ? currentX + 1.0 : currentX) * size.width;
      final posY = (currentY < 0 ? currentY + 1.0 : currentY) * size.height;

      final pulse = (math.sin(progress * math.pi * 2 * p.pulseSpeed) + 1.0) / 2.0;
      final currentOpacity = (p.opacity * (0.6 + 0.4 * pulse)).clamp(0.0, 1.0);

      paint.color = primaryColor.withOpacity(currentOpacity);
      canvas.drawCircle(Offset(posX, posY), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
