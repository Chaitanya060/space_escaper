import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../space_escaper_game.dart';

// ═══════════════════════════════════════
//  SCREEN EFFECTS SYSTEM
// ═══════════════════════════════════════

class ScreenEffects extends Component with HasGameReference<SpaceEscaperGame> {
  // Shake
  double shakeTimer = 0;
  double shakeIntensity = 0;

  // Red vignette
  double vignetteIntensity = 0;

  // Combo glow pulse
  double comboGlowTimer = 0;

  // Speed lines (hyperdrive)
  final List<_SpeedLine> _speedLines = [];

  void triggerShake({double duration = 0.5, double intensity = 8}) {
    shakeTimer = duration;
    shakeIntensity = intensity;
  }

  void triggerComboGlow() {
    comboGlowTimer = 1.0;
  }

  Vector2 getShakeOffset() {
    if (shakeTimer <= 0) return Vector2.zero();
    final rng = Random();
    return Vector2(
      (rng.nextDouble() - 0.5) * shakeIntensity * 2,
      (rng.nextDouble() - 0.5) * shakeIntensity * 2,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Shake decay
    if (shakeTimer > 0) {
      shakeTimer -= dt;
      shakeIntensity *= 0.95;
    }

    // Combo glow
    if (comboGlowTimer > 0) {
      comboGlowTimer -= dt;
    }

    // Combo check
    if (game.combo >= 50 && comboGlowTimer <= 0) {
      triggerComboGlow();
    }

    // Vignette based on danger
    if (game.player.invincible) {
      vignetteIntensity = 0.3;
    } else {
      vignetteIntensity *= 0.95;
    }

    // Hyperdrive speed lines
    if (game.currentPhysicsMode == 'hyperdrive') {
      if (_speedLines.length < 20) {
        _speedLines.add(_SpeedLine(
          x: Random().nextDouble() * game.size.x,
          y: Random().nextDouble() * game.size.y,
          length: 20 + Random().nextDouble() * 40,
          speed: 500 + Random().nextDouble() * 300,
        ));
      }
    }

    // Update speed lines
    _speedLines.removeWhere((l) {
      l.y += l.speed * dt;
      return l.y > game.size.y + 50;
    });
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;

    // Red vignette
    if (vignetteIntensity > 0.01) {
      final vignettePaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            Colors.transparent,
            Colors.red.withValues(alpha: vignetteIntensity),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignettePaint);
    }

    // Combo glow pulse
    if (comboGlowTimer > 0) {
      final glowAlpha = (comboGlowTimer * 0.3).clamp(0.0, 0.3);
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);
    }

    // Hyperdrive speed lines
    if (_speedLines.isNotEmpty) {
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = 1.5;
      for (final l in _speedLines) {
        canvas.drawLine(
          Offset(l.x, l.y),
          Offset(l.x, l.y + l.length),
          linePaint,
        );
      }
    }
  }
}

class _SpeedLine {
  double x, y;
  final double length;
  final double speed;

  _SpeedLine({
    required this.x,
    required this.y,
    required this.length,
    required this.speed,
  });
}
