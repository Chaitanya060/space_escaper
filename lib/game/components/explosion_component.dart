import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../space_escaper_game.dart';

class ExplosionComponent extends PositionComponent with HasGameReference<SpaceEscaperGame> {
  double t = 0;
  final double duration;
  final Color color;
  final double maxRadius;
  final List<_Particle> parts = [];

  ExplosionComponent({
    required Vector2 position,
    this.duration = 1.2,
    this.color = const Color(0xFFFF6B35),
    this.maxRadius = 150,
  }) : super(position: position, size: Vector2.all(1), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final rng = Random();
    // More particles for a spectacular explosion
    for (int i = 0; i < 40; i++) {
      final ang = rng.nextDouble() * pi * 2;
      final sp = 60 + rng.nextDouble() * 300;
      final sz = 2.0 + rng.nextDouble() * 4; // Varied sizes
      parts.add(_Particle(Vector2(cos(ang), sin(ang)) * sp, 0.8 + rng.nextDouble() * 0.6, sz));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    for (final p in parts) {
      p.pos += p.vel * dt;
      p.life -= dt;
    }
    parts.removeWhere((p) => p.life <= 0);
    if (t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = (t / duration).clamp(0.0, 1.0);
    final ringR = maxRadius * Curves.easeOut.transform(progress);
    final alpha = (1 - progress);

    // Bright flash at start
    if (progress < 0.3) {
      final flashAlpha = (1 - progress / 0.3);
      final flashPaint = Paint()
        ..color = Colors.white.withOpacity(0.8 * flashAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(Offset.zero, maxRadius * 0.4 * flashAlpha, flashPaint);
    }

    // Expanding shockwave ring
    final ring = Paint()
      ..color = color.withOpacity(0.7 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * (1 - progress);
    canvas.drawCircle(Offset.zero, ringR, ring);

    // Inner fire glow
    final glow = Paint()
      ..color = color.withOpacity(0.35 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(Offset.zero, ringR * 0.5, glow);

    // Debris particles with varied sizes
    for (final p in parts) {
      final pa = Paint()
        ..color = color.withOpacity(p.life.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(p.pos.x, p.pos.y), p.sz, pa);
    }
  }
}

class _Particle {
  Vector2 pos = Vector2.zero();
  Vector2 vel;
  double life;
  double sz;
  _Particle(this.vel, this.life, this.sz);
}
