import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../data/ship_data.dart';
import '../space_escaper_game.dart';

class PlayerComponent extends PositionComponent with HasGameReference<SpaceEscaperGame> {
  final ShipData shipData;
  final SpaceEscaperGame gameRef;

  double vx = 0;
  double vy = 0;
  double speed = 320;
  double friction = 0.88;

  bool alive = true;
  bool invincible = false;
  double invincibleTimer = 0;
  final double invincibleDuration = 1.5;
  bool phasing = false;
  bool bonusShieldReady = false;

  PlayerComponent({required this.shipData, required this.gameRef})
      : super(size: Vector2(36, 44), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = Vector2(gameRef.size.x / 2, gameRef.size.y * 0.75);
    add(RectangleHitbox(
      size: Vector2(size.x * 0.7, size.y * 0.7),
      position: Vector2(size.x * 0.15, size.y * 0.15),
    ));
    if (shipData.ability == 'goldenOverdrive') {
      bonusShieldReady = true;
    }
  }

  void applyDragInput(Vector2 delta) {
    // Direct position tracking for smooth touch control
    double mx = delta.x;
    double my = delta.y;

    // Apply physics mode changes
    switch (gameRef.currentPhysicsMode) {
      case 'reversed':
        my = -my;
        break;
      case 'inverted':
        mx = -mx;
        my = -my;
        break;
      case 'turbulence':
        mx += (Random().nextDouble() - 0.5) * 4;
        my += (Random().nextDouble() - 0.5) * 4;
        break;
      case 'hyperdrive':
        mx *= 0.7;
        break;
      case 'timewarp':
        mx *= 1.3;
        my *= 1.1;
        break;
      default:
        break;
    }

    position.x += mx * 1.2;
    position.y += my * 1.2;

    _clampToScreen();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!alive) return;

    // Apply continuous physics effects
    switch (gameRef.currentPhysicsMode) {
      case 'double':
        position.y += 60 * dt; // pull down
        break;
      case 'zero':
        // Drift continues (momentum)
        position.x += vx * dt;
        position.y += vy * dt;
        vx *= 0.99;
        vy *= 0.99;
        break;
      case 'turbulence':
        position.x += (Random().nextDouble() - 0.5) * 30 * dt;
        position.y += (Random().nextDouble() - 0.5) * 30 * dt;
        break;
      case 'singularity':
        final cx = gameRef.size.x / 2;
        final cy = gameRef.size.y / 2;
        final dx = cx - position.x;
        final dy = cy - position.y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist > 5) {
          final pull = 80 * dt;
          position.x += dx / dist * pull;
          position.y += dy / dist * pull;
        }
        break;
    }

    _clampToScreen();

    // Invincibility timer
    if (invincible) {
      invincibleTimer -= dt;
      if (invincibleTimer <= 0) {
        invincible = false;
      }
    }
  }

  void _clampToScreen() {
    final halfW = size.x / 2;
    final halfH = size.y / 2;
    position.x = position.x.clamp(halfW, gameRef.size.x - halfW);
    position.y = position.y.clamp(halfH, gameRef.size.y - halfH);
  }

  void makeInvincible() {
    invincible = true;
    invincibleTimer = invincibleDuration;
  }

  bool hit() {
    if (invincible || phasing) return false;
    if (bonusShieldReady) {
      bonusShieldReady = false;
      makeInvincible();
      return false;
    }
    alive = false;
    return true;
  }

  @override
  void render(Canvas canvas) {
    if (!alive) return;
    if (invincible && (invincibleTimer * 10).floor() % 2 == 0) return;

    final paint = Paint()
      ..color = shipData.color
      ..style = PaintingStyle.fill;

    // Glow shadow
    final glowPaint = Paint()
      ..color = shipData.color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final w = size.x;
    final h = size.y;

    // Glow
    final glowPath = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(0, h)
      ..lineTo(w / 4, h * 0.82)
      ..lineTo(w / 2, h * 0.9)
      ..lineTo(w * 0.75, h * 0.82)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(glowPath, glowPaint);

    // Ship body
    final bodyPath = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(0, h)
      ..lineTo(w / 4, h * 0.82)
      ..lineTo(w / 2, h * 0.9)
      ..lineTo(w * 0.75, h * 0.82)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(bodyPath, paint);

    // Cockpit
    final cockpitPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.35), width: w / 4, height: h / 3),
      cockpitPaint,
    );

    // Wing accent lines
    final accentPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w * 0.2, h * 0.7), Offset(w * 0.35, h * 0.35), accentPaint);
    canvas.drawLine(Offset(w * 0.8, h * 0.7), Offset(w * 0.65, h * 0.35), accentPaint);

    // Engine trail glow
    final trailPaint = Paint()
      ..color = shipData.color.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(w * 0.35, h), 4, trailPaint);
    canvas.drawCircle(Offset(w * 0.65, h), 4, trailPaint);
  }
}
