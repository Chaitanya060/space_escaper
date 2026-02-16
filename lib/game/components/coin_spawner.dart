import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../data/game_storage.dart';
import '../../data/powerup_data.dart';
import '../space_escaper_game.dart';
import 'player_component.dart';

class CoinComponent extends PositionComponent
    with HasGameReference<SpaceEscaperGame>, CollisionCallbacks {
  final int value;
  double bobOffset;
  double time = 0;
  bool collected = false;

  CoinComponent({
    required Vector2 position,
    this.value = 1,
  })  : bobOffset = Random().nextDouble() * pi * 2,
        super(
          position: position,
          size: Vector2.all(value <= 1 ? 16 : value <= 3 ? 20 : 28),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: size.x / 2));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (collected) return;

    time += dt;
    position.y += game.currentSpeed * 0.4 * dt;

    // Magnetic attraction
    final player = game.player;
    final dx = player.position.x - position.x;
    final dy = player.position.y - position.y;
    final dist = sqrt(dx * dx + dy * dy);
    double magnetRadius = game.currentShip.ability == 'coinMagnet' ? 200.0 : 100.0;
    if (game.currentPhysicsMode == 'magnetic') {
      magnetRadius *= 1.5;
    }
    // Ultra magnet power-up
    if (game.hasPowerUp(PowerUpType.ultraMagnet)) {
      magnetRadius *= 3.0;
    }
    // Skill tree bonus
    final magnetLevel = GameStorage.getSkillLevel('magnet_range');
    magnetRadius *= (1 + magnetLevel * 0.1);
    if (dist < magnetRadius && dist > 0) {
      final strength = (1 - dist / magnetRadius) * 400;
      position.x += (dx / dist) * strength * dt;
      position.y += (dy / dist) * strength * dt;
    }

    if (position.y > game.size.y + 30) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent && !collected) {
      collected = true;
      game.collectCoin(value);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;

    final s = size.x / 2;
    final bob = sin(time * 3 + bobOffset) * 2;

    canvas.save();
    canvas.translate(0, bob);

    final isRare = value >= 5;
    final color = isRare ? const Color(0xFFA855F7) : const Color(0xFFFFD93D);

    // Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(s, s), s, glowPaint);

    // Diamond shape
    final diamondPaint = Paint()..color = color;
    final path = Path()
      ..moveTo(s, 0)
      ..lineTo(s + s * 0.7, s)
      ..lineTo(s, s * 2)
      ..lineTo(s - s * 0.7, s)
      ..close();
    canvas.drawPath(path, diamondPaint);

    // Inner highlight
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    final innerPath = Path()
      ..moveTo(s, s * 0.4)
      ..lineTo(s + s * 0.3, s)
      ..lineTo(s, s * 1.3)
      ..lineTo(s - s * 0.3, s)
      ..close();
    canvas.drawPath(innerPath, highlightPaint);

    canvas.restore();
  }
}

class CoinSpawner extends Component with HasGameReference<SpaceEscaperGame> {
  final SpaceEscaperGame gameRef;
  double spawnTimer = 0;
  final double spawnInterval = 2.3;

  CoinSpawner({required this.gameRef});

  @override
  void update(double dt) {
    if (game.gameState != GameState.playing) return;

    spawnTimer -= dt;
    if (spawnTimer <= 0) {
      spawnTimer = spawnInterval;
      _spawnPattern();
    }
  }

  void _spawnPattern() {
    final rng = Random();
    final patterns = ['line', 'arc', 'wave', 'cluster'];
    final pattern = patterns[rng.nextInt(patterns.length)];
    final startX = 60 + rng.nextDouble() * (game.size.x - 120);
    const y = -20.0;

    // Small chance to spawn stardust shards instead of coins
    final stardustRoll = rng.nextDouble();
    if (stardustRoll < 0.08) {
      // Spawn 3-5 stardust shards
      final count = 3 + rng.nextInt(3);
      for (int i = 0; i < count; i++) {
        game.add(StardustComponent(
          position: Vector2(
            startX + (rng.nextDouble() - 0.5) * 60,
            y - i * 20,
          ),
          amount: 1,
        ));
      }
      return;
    }

    final isRare = rng.nextDouble() < 0.02;
    final value = isRare ? 5 : 1;

    switch (pattern) {
      case 'line':
        for (int i = 0; i < 4; i++) {
          game.add(CoinComponent(
            position: Vector2(startX, y - i * 30),
            value: value,
          ));
        }
        break;
      case 'arc':
        for (int i = 0; i < 6; i++) {
          final a = (i / 6) * pi;
          game.add(CoinComponent(
            position: Vector2(startX + cos(a) * 50, y - sin(a) * 40 - i * 10),
            value: value,
          ));
        }
        break;
      case 'wave':
        for (int i = 0; i < 5; i++) {
          game.add(CoinComponent(
            position: Vector2(startX + sin(i * 0.8) * 40, y - i * 25),
            value: value,
          ));
        }
        break;
      case 'cluster':
        for (int i = 0; i < 3; i++) {
          game.add(CoinComponent(
            position: Vector2(
              startX + (rng.nextDouble() - 0.5) * 50,
              y + (rng.nextDouble() - 0.5) * 40,
            ),
            value: isRare ? 3 : 1,
          ));
        }
        break;
    }
  }
}

class StardustComponent extends PositionComponent
    with HasGameReference<SpaceEscaperGame>, CollisionCallbacks {
  final int amount;
  bool collected = false;
  double time = 0;
  double bobOffset;

  StardustComponent({required Vector2 position, this.amount = 1})
      : bobOffset = Random().nextDouble() * pi * 2,
        super(position: position, size: Vector2.all(18), anchor: Anchor.center);

  @override
  Future<void> onLoad() async { add(CircleHitbox(radius: size.x / 2)); }

  @override
  void update(double dt) {
    super.update(dt);
    if (collected) return;
    time += dt;
    position.y += game.currentSpeed * 0.35 * dt;
    if (position.y > game.size.y + 30) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent && !collected) {
      collected = true;
      GameStorage.addStardust(amount);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;
    final s = size.x / 2;
    final bob = sin(time * 3 + bobOffset) * 2;
    canvas.save();
    canvas.translate(0, bob);

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(s, s), s, glowPaint);

    // Hex crystal
    final p = Path()
      ..moveTo(s, 0)
      ..lineTo(s + s * 0.6, s * 0.5)
      ..lineTo(s + s * 0.6, s * 1.5)
      ..lineTo(s, s * 2)
      ..lineTo(s - s * 0.6, s * 1.5)
      ..lineTo(s - s * 0.6, s * 0.5)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFF8B5CF6));

    // Core
    canvas.drawCircle(Offset(s, s), s * 0.35, Paint()..color = Colors.white.withOpacity(0.7));
    canvas.restore();
  }
}
