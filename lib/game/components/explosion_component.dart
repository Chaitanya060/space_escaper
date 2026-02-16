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
    this.duration = 0.6,
    this.color = const Color(0xFFFF6B35),
    this.maxRadius = 80,
  }) : super(position: position, size: Vector2.all(1), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final rng = Random();
    for (int i = 0; i < 24; i++) {
      final ang = rng.nextDouble() * pi * 2;
      final sp = 80 + rng.nextDouble() * 220;
      parts.add(_Particle(Vector2(cos(ang), sin(ang)) * sp, 0.8 + rng.nextDouble() * 0.4));
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

    final ring = Paint()
      ..color = color.withOpacity(0.6 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset.zero, ringR, ring);

    final glow = Paint()
      ..color = color.withOpacity(0.25 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, ringR * 0.6, glow);

    for (final p in parts) {
      final pa = Paint()
        ..color = color.withOpacity(p.life.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(p.pos.x, p.pos.y), 3, pa);
    }
  }
}

class _Particle {
  Vector2 pos = Vector2.zero();
  Vector2 vel;
  double life;
  _Particle(this.vel, this.life);
}
