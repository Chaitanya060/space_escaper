import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../space_escaper_game.dart';
import 'player_component.dart';

class AlienComponent extends PositionComponent
    with HasGameReference<SpaceEscaperGame>, CollisionCallbacks {
  final String alienType; // 'chaser', 'weaver', 'dasher', 'shielder', 'bomber', 'splitter'
  double speedY = 0;
  double speedX = 0;
  double time = 0;
  double health = 1.0;
  double bomberTimer = 0;

  // Status Effects
  double slowFactor = 1.0;
  double slowTimer = 0;
  double frozenTimer = 0;
  
  void applySlow(double factor, double duration) {
    if (factor < slowFactor) slowFactor = factor;
    slowTimer = duration;
  }

  void freeze(double duration) {
    frozenTimer = duration;
  }

  AlienComponent({
    required Vector2 position,
    this.alienType = 'chaser',
  }) : super(
          position: position,
          size: Vector2(40, 40),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(size: Vector2(30, 30), position: Vector2(5, 5)));

    speedY = game.currentSpeed + 100;


    switch (alienType) {
      case 'weaver':
        speedX = 150;
        break;
      case 'dasher':
        speedY += 200;
        break;
      case 'shielder':
        health = 3.0;
        speedY = game.currentSpeed * 0.6;
        break;
      case 'bomber':
        speedY = game.currentSpeed * 0.7;
        break;
      case 'splitter':
        health = 2.0;
        break;
    }
  }

  @override
  void update(double dt) {
    // Status effects
    if (frozenTimer > 0) {
      frozenTimer -= dt;
      super.update(dt);
      return; // Frozen: no movement
    }
    
    if (slowTimer > 0) {
      slowTimer -= dt;
      if (slowTimer <= 0) {
        slowFactor = 1.0;
      }
    }

    final moveDt = dt * slowFactor;

    super.update(dt);
    time += dt; // Time still progresses for animations/patterns? Maybe slowed too?
    // Let's keep time normal for patterns but movement slowed.

    switch (alienType) {
      case 'chaser':
        final playerX = game.player.position.x;
        if (position.x < playerX - 10) {
          position.x += 100 * moveDt;
        } else if (position.x > playerX + 10) {
          position.x -= 100 * moveDt;
        }
        position.y += speedY * moveDt;
        break;
      case 'weaver':
        position.x += cos(time * 3) * speedX * moveDt;
        position.y += speedY * moveDt;
        break;
      case 'dasher':
        final burst = (sin(time * 5) > 0.8) ? 2.0 : 1.0;
        position.y += speedY * burst * moveDt;
        break;
      case 'shielder':
        position.y += speedY * moveDt;
        break;
      case 'bomber':
        position.y += speedY * moveDt;
        bomberTimer += dt; // Bomb timer not slowed?
        if (bomberTimer >= 1.5) {
          bomberTimer = 0;
          _dropBomb();
        }
        break;
      case 'splitter':
        position.y += speedY * moveDt;
        final playerX2 = game.player.position.x;
        if (position.x < playerX2 - 20) {
          position.x += 60 * moveDt;
        } else if (position.x > playerX2 + 20) {
          position.x -= 60 * moveDt;
        }
        break;
    }

    // Screen wrap for weaver
    if (position.x < 0) position.x = game.size.x;
    if (position.x > game.size.x) position.x = 0;

    if (position.y > game.size.y + 50) {
      removeFromParent();
    }
  }

  void _dropBomb() {
    game.add(_AlienBomb(position: position.clone()));
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      if (other.hit()) {
        game.playerHit();
      }
    }
  }

  void takeDamage(double amount) {
    health -= amount;
    if (health <= 0) {
      // Splitter: spawn 2 mini aliens
      if (alienType == 'splitter') {
        game.add(AlienComponent(
          position: position.clone() + Vector2(-15, 0),
          alienType: 'chaser',
        ));
        game.add(AlienComponent(
          position: position.clone() + Vector2(15, 0),
          alienType: 'chaser',
        ));
      }
      removeFromParent();
      game.onAlienKilled();
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    Paint bodyPaint;
    Paint glassPaint = Paint()..color = const Color(0xFF00D9FF).withValues(alpha: 0.8);

    switch (alienType) {
      case 'chaser':
        bodyPaint = Paint()..color = const Color(0xFFEF4444);
        break;
      case 'dasher':
        bodyPaint = Paint()..color = const Color(0xFFFFD93D);
        break;
      case 'weaver':
        bodyPaint = Paint()..color = const Color(0xFF555555);
        break;
      case 'shielder':
        bodyPaint = Paint()..color = const Color(0xFF3B82F6);
        break;
      case 'bomber':
        bodyPaint = Paint()..color = const Color(0xFFFF6B35);
        break;
      case 'splitter':
        bodyPaint = Paint()..color = const Color(0xFF22C55E);
        break;
      default:
        bodyPaint = Paint()..color = const Color(0xFFEF4444);
    }

    // Dome
    canvas.drawArc(
      Rect.fromLTWH(w * 0.25, 0, w * 0.5, h * 0.6),
      pi, pi, true, glassPaint,
    );

    // Saucer Body
    canvas.drawOval(
      Rect.fromLTWH(0, h * 0.3, w, h * 0.4),
      bodyPaint,
    );

    // Engine/Lights
    final t = (time * 10).floor();
    final lightColor = (t % 2 == 0) ? Colors.white : Colors.red;
    canvas.drawCircle(Offset(w / 2, h * 0.6), 4, Paint()..color = lightColor);

    // Shielder: draw shield ring
    if (alienType == 'shielder') {
      final shieldPaint = Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.3 + sin(time * 3) * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(w / 2, h / 2), w * 0.6, shieldPaint);
    }

    // Health bar for multi-health aliens
    if (health > 1) {
      final barW = w * 0.8;
      final barH = 3.0;
      final barX = (w - barW) / 2;
      final barY = -8.0;

      // Background
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(1)),
        Paint()..color = Colors.black54,
      );

      // Foreground
      final hpPercent = (health / (alienType == 'shielder' ? 3.0 : (alienType == 'splitter' ? 2.0 : 5.0))).clamp(0.0, 1.0);
      final hpColor = Color.lerp(Colors.red, const Color(0xFF22C55E), hpPercent)!;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barW * hpPercent, barH), const Radius.circular(1)),
        Paint()..color = hpColor,
      );
    }
  }
}

// ═══════════════════════════════════════
//  ALIEN BOMB (from Bomber type)
// ═══════════════════════════════════════

class _AlienBomb extends PositionComponent
    with HasGameReference<SpaceEscaperGame>, CollisionCallbacks {

  _AlienBomb({required Vector2 position})
      : super(position: position, size: Vector2(8, 8), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: 4));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += 250 * dt;
    if (position.y > game.size.y + 30) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      if (other.hit()) {
        game.playerHit();
      }
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 4, paint);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 2,
        Paint()..color = const Color(0xFFFFD93D));
  }
}
