import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../data/powerup_data.dart';
import '../space_escaper_game.dart';
import 'player_component.dart';

// ═══════════════════════════════════════
//  POWER-UP PICKUP (In-Game)
// ═══════════════════════════════════════

class PowerUpComponent extends PositionComponent
    with HasGameReference<SpaceEscaperGame>, CollisionCallbacks {
  final PowerUpType powerUpType;
  late PowerUpInfo info;
  double time = 0;
  double speed = 0;

  PowerUpComponent({
    required Vector2 position,
    required this.powerUpType,
  }) : super(
    position: position,
    size: Vector2(32, 32),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    info = getPowerUpInfo(powerUpType);
    speed = game.currentSpeed * 0.5;
    add(CircleHitbox(radius: 16));
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
    position.y += speed * dt;

    // Gentle float
    position.x += sin(time * 3) * 15 * dt;

    if (position.y > game.size.y + 50) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      game.activatePowerUp(powerUpType);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final r = size.x / 2;

    // Outer glow
    final glowPaint = Paint()
      ..color = info.color.withValues(alpha: 0.3 + sin(time * 4) * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, r * 1.2, glowPaint);

    // Background circle
    final bgPaint = Paint()
      ..color = info.color.withValues(alpha: 0.7);
    canvas.drawCircle(center, r * 0.85, bgPaint);

    // Inner bright core
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(center, r * 0.4, corePaint);

    // Spinning ring
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.7),
      time * 3, pi, false, ringPaint,
    );

    // Rarity sparkle for rare+
    if (info.rarity != 'common') {
      final sparkle = Paint()..color = Colors.white.withValues(alpha: sin(time * 8).abs() * 0.8);
      canvas.drawCircle(Offset(center.dx + cos(time * 5) * r * 0.5,
          center.dy + sin(time * 5) * r * 0.5), 2, sparkle);
    }
  }
}

// ═══════════════════════════════════════
//  POWER-UP SPAWNER
// ═══════════════════════════════════════

class PowerUpSpawner extends Component with HasGameReference<SpaceEscaperGame> {
  double spawnTimer = 0;
  double spawnInterval = 20; // seconds between power-up spawns
  final Random _rng = Random();

  @override
  void update(double dt) {
    super.update(dt);
    if (game.gameState != GameState.playing) return;

    spawnTimer += dt;

    // Slightly faster spawns at higher distances
    final adjustedInterval = max(12.0, spawnInterval - game.distance / 5000);

    if (spawnTimer >= adjustedInterval) {
      spawnTimer = 0;
      _spawnPowerUp();
    }
  }

  void _spawnPowerUp() {
    // Weighted random selection
    double totalWeight = 0;
    for (final p in allPowerUps) {
      if (!game.coinsEnabled && p.type == PowerUpType.coinStorm) continue;
      totalWeight += p.spawnWeight;
    }

    double roll = _rng.nextDouble() * totalWeight;
    PowerUpType selected = PowerUpType.shield;

    for (final p in allPowerUps) {
      if (!game.coinsEnabled && p.type == PowerUpType.coinStorm) continue;
      roll -= p.spawnWeight;
      if (roll <= 0) {
        selected = p.type;
        break;
      }
    }

    final x = 40 + _rng.nextDouble() * (game.size.x - 80);
    game.add(PowerUpComponent(
      position: Vector2(x, -40),
      powerUpType: selected,
    ));
  }
}
