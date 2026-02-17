import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../space_escaper_game.dart';
import 'alien_component.dart';
import 'boss_component.dart';

class SatelliteComponent extends PositionComponent
    with HasGameReference<SpaceEscaperGame>, CollisionCallbacks {
  final double orbitRadius;
  final double orbitSpeed;
  final double startAngle;
  final Color color;
  final int damage;
  
  double _currentAngle;

  SatelliteComponent({
    required this.orbitRadius,
    this.orbitSpeed = 2.0,
    this.startAngle = 0.0,
    this.color = Colors.cyan,
    this.damage = 10,
  }) : _currentAngle = startAngle,
       super(size: Vector2(16, 16), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  double _damageTimer = 0;

  @override
  void update(double dt) {
    super.update(dt);
    
    // Orbit logic
    _currentAngle += orbitSpeed * dt;
    final player = game.player;
    
    // Keep position relative to player
    position.x = player.position.x + cos(_currentAngle) * orbitRadius;
    position.y = player.position.y + sin(_currentAngle) * orbitRadius;

    if (_damageTimer > 0) _damageTimer -= dt;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is BossComponent && _damageTimer <= 0) {
      other.takeDamage(damage);
      _createHitEffect();
      _damageTimer = 0.2; // Damage tick every 0.2s
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is AlienComponent) {
      other.takeDamage(damage.toDouble());
      _createHitEffect();
    } else if (other is BossComponent) {
       // Handled in onCollision for continuous damage
       if (_damageTimer <= 0) {
         other.takeDamage(damage);
         _createHitEffect();
         _damageTimer = 0.2;
       }
    }
  }

  void _createHitEffect() {
    // Visual flash?
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2, paint);
    canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/4, corePaint);
  }
}
