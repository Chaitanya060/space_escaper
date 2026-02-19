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

  // Damage flash
  double flashTimer = 0;
  Color flashColor = Colors.white;

  // Mode Pulse
  double pulseTimer = 0;
  Color pulseColor = Colors.white;

  // Static noise (Dark Matter)
  final Random _rng = Random();
  final List<_SpeedLine> _speedLines = [];

  void triggerSpeedBurst() {
    final w = game.size.x;
    final h = game.size.y;
    for (int i = 0; i < 30; i++) {
      _speedLines.add(_SpeedLine(
        x: _rng.nextDouble() * w,
        y: _rng.nextDouble() * h,
        length: 30 + _rng.nextDouble() * 70,
        speed: 900 + _rng.nextDouble() * 600,
        color: Colors.white,
      ));
    }
    triggerFlash(color: Colors.cyanAccent.withValues(alpha: 0.7), duration: 0.12);
    triggerModePulse(const Color(0xFF00D9FF));
  }

  void triggerShake({double duration = 0.5, double intensity = 8}) {
    shakeTimer = duration;
    shakeIntensity = intensity;
  }

  void triggerFlash({Color color = Colors.white, double duration = 0.2}) {
    flashTimer = duration;
    flashColor = color;
  }

  void triggerModePulse(Color color) {
    pulseTimer = 1.0;
    pulseColor = color;
  }

  void triggerComboGlow() {
    comboGlowTimer = 1.0;
  }

  Vector2 getShakeOffset() {
    if (shakeTimer <= 0) return Vector2.zero();
    return Vector2(
      (_rng.nextDouble() - 0.5) * shakeIntensity * 2,
      (_rng.nextDouble() - 0.5) * shakeIntensity * 2,
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

    // Flash decay
    if (flashTimer > 0) flashTimer -= dt;

    // Pulse decay
    if (pulseTimer > 0) pulseTimer -= dt;

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
          x: _rng.nextDouble() * game.size.x,
          y: _rng.nextDouble() * game.size.y,
          length: 20 + _rng.nextDouble() * 40,
          speed: 500 + _rng.nextDouble() * 300,
          color: Colors.cyanAccent,
        ));
      }
    } else if (game.currentPhysicsMode == 'singularity') {
      // Warp lines
       if (_speedLines.length < 10) {
        _speedLines.add(_SpeedLine(
          x: _rng.nextDouble() * game.size.x,
          y: _rng.nextDouble() * game.size.y,
          length: 5,
          speed: 100,
          color: Colors.purpleAccent,
        ));
      }
    }

    // Update speed lines
    _speedLines.removeWhere((l) {
      if (game.currentPhysicsMode == 'singularity') {
         // swirl
         final cx = game.size.x / 2;
         final cy = game.size.y / 2;
         final dx = l.x - cx;
         final dy = l.y - cy;
         final angle = atan2(dy, dx) + 2 * dt;
         final dist = sqrt(dx*dx + dy*dy) - 50 * dt;
         l.x = cx + cos(angle) * dist;
         l.y = cy + sin(angle) * dist;
         return dist < 10;
      } else {
        l.y += l.speed * dt;
        return l.y > game.size.y + 50;
      }
    });
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;

    // Dark Matter Static
    if (game.currentPhysicsMode == 'dark_matter') {
       final staticPaint = Paint()..color = Colors.white.withValues(alpha: 0.1);
       for(int i=0; i<100; i++) {
         canvas.drawCircle(Offset(_rng.nextDouble() * w, _rng.nextDouble() * h), 1, staticPaint);
       }
    }

    // Distortion Ripples (Singularity)
    if (game.currentPhysicsMode == 'singularity') {
       final ripplePaint = Paint()
         ..color = Colors.purple.withValues(alpha: 0.1)
         ..style = PaintingStyle.stroke
         ..strokeWidth = 2;
       final center = Offset(w/2, h/2);
       for(int i=0; i<5; i++) {
          final r = (game.currentTime() * 100 + i * 50) % (w/2);
          canvas.drawCircle(center, r, ripplePaint);
       }
    }

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

    // Flash
    if (flashTimer > 0) {
      final alpha = (flashTimer / 0.2).clamp(0.0, 0.8);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = flashColor.withValues(alpha: alpha));
    }

    // Mode Pulse
    if (pulseTimer > 0) {
      final progress = 1.0 - pulseTimer; // 0 to 1
      final radius = progress * w * 0.8;
      final alpha = (1.0 - progress).clamp(0.0, 0.5);
      final pulsePaint = Paint()
        ..color = pulseColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20 * (1.0 - progress);
      canvas.drawCircle(Offset(w/2, h/2), radius, pulsePaint);
    }

    // Combo glow pulse
    if (comboGlowTimer > 0) {
      final glowAlpha = (comboGlowTimer * 0.3).clamp(0.0, 0.3);
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);
    }

    // Speed lines
    if (_speedLines.isNotEmpty) {
      for (final l in _speedLines) {
        canvas.drawLine(
          Offset(l.x, l.y),
          Offset(l.x, l.y + l.length),
          Paint()..color = l.color.withValues(alpha: 0.4)..strokeWidth = 1.5,
        );
      }
    }
  }
}

class _SpeedLine {
  double x, y;
  final double length;
  final double speed;
  final Color color;

  _SpeedLine({
    required this.x,
    required this.y,
    required this.length,
    required this.speed,
    this.color = Colors.white,
  });
}
