import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../space_escaper_game.dart';

// ═══════════════════════════════════════
//  SHIP TRAIL SYSTEM
// ═══════════════════════════════════════

class ShipTrail extends Component with HasGameReference<SpaceEscaperGame> {
  final List<_TrailParticle> _particles = [];
  double _timer = 0;
  final double _emitRate = 0.03; // seconds between particles

  @override
  void update(double dt) {
    super.update(dt);
    if (game.gameState != GameState.playing) return;

    _timer += dt;
    if (_timer >= _emitRate) {
      _timer = 0;
      _emitParticle();
    }

    // Update particles
    _particles.removeWhere((p) {
      p.update(dt);
      return p.isDead;
    });
  }

  void _emitParticle() {
    final ship = game.currentShip;
    final pos = game.player.position;
    final w = game.player.size.x;

    // Emit from two engine points
    for (final offset in [Vector2(w * 0.35, game.player.size.y), Vector2(w * 0.65, game.player.size.y)]) {
      _particles.add(_TrailParticle(
        x: pos.x - w / 2 + offset.x + (Random().nextDouble() - 0.5) * 4,
        y: pos.y - game.player.size.y / 2 + offset.y,
        color: ship.color,
        trailType: ship.trailType,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      p.render(canvas);
    }
  }
}

class _TrailParticle {
  double x, y;
  double vx, vy;
  double life;
  final double maxLife;
  final Color color;
  final String trailType;
  final double size;

  _TrailParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.trailType,
  }) : life = 0,
       maxLife = _maxLifeForType(trailType),
       size = _sizeForType(trailType),
       vx = (Random().nextDouble() - 0.5) * _spreadForType(trailType),
       vy = 30 + Random().nextDouble() * 40;

  static double _maxLifeForType(String type) {
    switch (type) {
      case 'flame': return 0.5;
      case 'smoke': return 0.8;
      case 'wisp': return 0.6;
      case 'plasma': return 0.4;
      case 'bolt': return 0.3;
      default: return 0.4; // spark
    }
  }

  static double _sizeForType(String type) {
    switch (type) {
      case 'flame': return 5;
      case 'smoke': return 6;
      case 'wisp': return 4;
      case 'plasma': return 4;
      case 'bolt': return 3;
      default: return 3;
    }
  }

  static double _spreadForType(String type) {
    switch (type) {
      case 'smoke': return 20;
      case 'flame': return 10;
      case 'wisp': return 30;
      default: return 8;
    }
  }

  bool get isDead => life >= maxLife;
  double get progress => (life / maxLife).clamp(0.0, 1.0);

  void update(double dt) {
    life += dt;
    x += vx * dt;
    y += vy * dt;
  }

  void render(Canvas canvas) {
    final alpha = (1 - progress).clamp(0.0, 1.0);
    final r = size * (1 - progress * 0.5);

    switch (trailType) {
      case 'flame':
        final flameColor = Color.lerp(color, const Color(0xFFFF4500), progress)!;
        final paint = Paint()
          ..color = flameColor.withValues(alpha: alpha * 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(x, y), r, paint);
        break;
      case 'smoke':
        final smokePaint = Paint()
          ..color = color.withValues(alpha: alpha * 0.4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + progress * 4);
        canvas.drawCircle(Offset(x, y), r * (1 + progress * 0.8), smokePaint);
        break;
      case 'wisp':
        final wispPaint = Paint()
          ..color = color.withValues(alpha: alpha * 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        final offset = sin(life * 20) * 3;
        canvas.drawCircle(Offset(x + offset, y), r * 0.7, wispPaint);
        break;
      case 'plasma':
        final plasmaPaint = Paint()
          ..color = color.withValues(alpha: alpha * 0.7);
        canvas.drawCircle(Offset(x, y), r, plasmaPaint);
        // Core
        canvas.drawCircle(Offset(x, y), r * 0.4,
            Paint()..color = Colors.white.withValues(alpha: alpha * 0.5));
        break;
      case 'bolt':
        final boltPaint = Paint()
          ..color = color.withValues(alpha: alpha * 0.9)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(x, y), Offset(x + (Random().nextDouble() - 0.5) * 6, y + 4), boltPaint);
        break;
      default: // spark
        final sparkPaint = Paint()
          ..color = color.withValues(alpha: alpha * 0.8);
        canvas.drawCircle(Offset(x, y), r * 0.6, sparkPaint);
        break;
    }
  }
}
