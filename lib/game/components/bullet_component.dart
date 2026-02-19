import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../data/powerup_data.dart';
import '../space_escaper_game.dart';
import 'alien_component.dart';
import 'boss_component.dart';
import 'obstacle_spawner.dart';

enum BulletType {
  standard,
  explosive,
  homing,
  blackHole,
  piercing,
  spectral,
  timeShatter,
  ricochet,
  wave,
  frost,
  lightning,
  blade,
  crystal,
  flame,
  mine,
}

class BulletComponent extends PositionComponent
    with HasGameReference<SpaceEscaperGame>, CollisionCallbacks {
  final double bulletSpeed;
  final Color bulletColor;
  final BulletType type;
  final Vector2 velocity;
  final int damage;
  int penetrationCount;

  // Homing
  PositionComponent? _target;
  double _homingTurnRate;

  // Wave
  double _timeAlive = 0;
  final double _waveAmplitude = 3.0;
  final double _waveFrequency = 10.0;
  // Resonance stacks could be tracked on the enemy, but for now simple damage.

  // Ricochet
  int _bouncesLeft = 3;

  // Black Hole
  double _blackHoleDuration = 4.0;
  final double _pullRadius = 150.0;

  // Mine
  bool _mineArmed = false;
  double _mineArmTimer = 0.5;
  final double proximityRadius;

  // New Fields
  final double freezeDuration;
  final double slowAmount;
  
  // Chain Lightning
  int chainCount;
  final double _chainRange = 300.0;
  final List<PositionComponent> _hitTargets = [];

  // Explosion
  final double blastRadius;
  final bool isNuclear;

  // Crystal
  final int shardCount;
  
  // Black Hole
  bool destroyProjectiles = false;

  BulletComponent({
    required Vector2 position,
    double speed = 800,
    Color color = const Color(0xFF00FF00),
    Vector2? size,
    this.type = BulletType.standard,
    Vector2? velocity,
    this.damage = 1,
    this.penetrationCount = 0,
    double homingTurnRate = 5.0,
    this.freezeDuration = 0,
    this.slowAmount = 0,
    this.chainCount = 0,
    this.blastRadius = 0,
    this.isNuclear = false,
    this.shardCount = 0,
    this.proximityRadius = 0,
    this.destroyProjectiles = false,
  })  : bulletSpeed = speed,
        bulletColor = color,
        velocity = velocity ?? Vector2(0, -speed),
        _homingTurnRate = homingTurnRate,
        super(
          position: position,
          size: size ?? Vector2(4, 16),
          anchor: Anchor.center,
        ) {
    }

  @override
  Future<void> onLoad() async {
    if (type == BulletType.blackHole) {
      size = Vector2(40, 40);
      add(CircleHitbox());
    } else if (type == BulletType.explosive || type == BulletType.mine) {
      add(CircleHitbox());
    } else if (type == BulletType.blade) {
      add(CircleHitbox()); // Blade spins
    } else {
      add(RectangleHitbox());
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timeAlive += dt;

    if (type == BulletType.blackHole) {
      _updateBlackHole(dt);
      return;
    }

    if (type == BulletType.mine) {
      _updateMine(dt);
      return; // Mines don't move typically (or move very slow)
    }

    if (type == BulletType.homing) {
      _updateHoming(dt);
    }

    if (type == BulletType.wave) {
      _updateWave(dt);
    } else {
      position += velocity * dt;
    }

    if (type == BulletType.ricochet) {
      _handleRicochet();
    }
    
    // Blade spin
    if (type == BulletType.blade) {
      angle += dt * 10;
    }
    // Standard rotation alignment for others
    else if (type != BulletType.mine && type != BulletType.blackHole && type != BulletType.wave) {
       angle = atan2(velocity.x, -velocity.y);
    }

    // Bounds check
    if (type != BulletType.ricochet) {
        if (position.y < -100 || position.y > game.size.y + 100 ||
            position.x < -100 || position.x > game.size.x + 100) {
          removeFromParent();
        }
    } else {
        // Ricochet dies only if it goes off bottom or top (if we want side bounces only)
        // Or if bounces run out
        if (position.y < -100 || position.y > game.size.y + 100) {
            removeFromParent();
        }
    }
  }

  void _updateWave(double dt) {
    // Move forward base
    position += velocity * dt;
    
    // Add sine wave offset perpendicular to movement
    // Doing this properly requires maintaining a 'base' position or calculating offset
    // Simple way: adjust velocity's X component based on sine
    // Better way:
    final perp = Vector2(-velocity.y, velocity.x).normalized();
    final waveOffset = perp * cos(_timeAlive * _waveFrequency) * _waveAmplitude * 60 * dt; 
    position += waveOffset;
    
    // Rotate sprite to face movement roughly
    angle = atan2(velocity.x + waveOffset.x, -velocity.y - waveOffset.y);
  }

  void _updateHoming(double dt) {
    bool needNewTarget = _target == null || !_target!.isMounted;
    if (!needNewTarget) {
      if (_target is AlienComponent && (_target as AlienComponent).health <= 0) {
        needNewTarget = true;
      } else if (_target is BossComponent && (_target as BossComponent).health <= 0) {
        needNewTarget = true;
      }
    }

    if (needNewTarget) {
      _target = null;
      _findTarget();
    }

    if (_target != null) {
      final direction = (_target!.position - position).normalized();
      final currentDir = velocity.normalized();
      final smoothDir = (currentDir + direction * _homingTurnRate * dt).normalized();
      velocity.setFrom(smoothDir * bulletSpeed);
      angle = atan2(velocity.x, -velocity.y);
    }
  }

  void _findTarget() {
      // Find new target (prefer boss if present)
      double minDist = 600; // Increased range
      for (final child in game.children) {
        if (child is BossComponent && child.health > 0) {
          final dist = child.position.distanceTo(position);
          if (dist < minDist) {
            minDist = dist;
            _target = child;
          }
        }
        if (child is AlienComponent && child.y > 0 && child.y < game.size.y && child.health > 0) {
          final dist = child.position.distanceTo(position);
          if (dist < minDist && !_hitTargets.contains(child)) {
            minDist = dist;
            _target = child;
          }
        }
      }
  }

  void _updateBlackHole(double dt) {
    position.y -= bulletSpeed * dt * 0.2; // Move slowly
    _blackHoleDuration -= dt;
    angle += dt * 5; // Spin

    // Pull enemies
    game.children.whereType<AlienComponent>().forEach((alien) {
      final dist = alien.position.distanceTo(position);
      if (dist < _pullRadius) {
        final dir = (position - alien.position).normalized();
        alien.position += dir * 100 * dt;
        alien.takeDamage(10 * dt); // Continuous high damage
      }
    });

    // Pull and damage bosses
    for (final boss in game.children.whereType<BossComponent>()) {
      final dist = boss.position.distanceTo(position);
      if (dist < _pullRadius) {
        final dir = (position - boss.position).normalized();
        boss.position += dir * 40 * dt;
        final tick = (damage * dt * 0.6).round();
        if (tick > 0) boss.takeDamage(tick);
      }
    }

    // Destroy projectiles if enabled
    /* if (destroyProjectiles) {
       // Need EnemyBulletComponent to exist, generic removal for now not possible easily without checking types
       // Assuming we add EnemyBulletComponent logic later or generic PositionComponent check
    } */

    if (_blackHoleDuration <= 0) removeFromParent();
  }

  void _updateMine(double dt) {
      if (!_mineArmed) {
          _mineArmTimer -= dt;
          if (_mineArmTimer <= 0) _mineArmed = true;
      }
      position.y += 50 * dt; // Drift down slowly
      
      // Proximity Trigger
      if (_mineArmed) {
          double triggerRange = proximityRadius > 0 ? proximityRadius : 60.0;
           for(final child in game.children) {
               if (child is AlienComponent && !child.isRemoving) {
                   if (child.position.distanceTo(position) < triggerRange) {
                       _explode(position);
                       removeFromParent();
                       return;
                   }
               } else if (child is BossComponent) {
                   if (child.position.distanceTo(position) < triggerRange) {
                       _explode(position);
                       removeFromParent();
                       return;
                   }
               }
           }
      }

      if (position.y > game.size.y + 50) removeFromParent();
  }

  void _handleRicochet() {
      bool bounced = false;
      if (position.x <= 0) {
          velocity.x = -velocity.x;
          position.x = 1;
          bounced = true;
      } else if (position.x >= game.size.x) {
          velocity.x = -velocity.x;
          position.x = game.size.x - 1;
          bounced = true;
      }

      if (bounced) {
          _bouncesLeft--;
           // Visual spark
           // game.add(ParticleEffect...);
          if (_bouncesLeft < 0) removeFromParent();
      }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (type == BulletType.blackHole) return; 

    // Mine only works if armed (or maybe instantly if hit?)
    if (type == BulletType.mine && !_mineArmed) return;

    if (type == BulletType.spectral && other is ObstacleComponent) return;

    int finalDamage = damage;
    if (game.hasPowerUp(PowerUpType.damageBoost)) finalDamage *= 2;

    bool hit = false;
    Vector2? hitPos;

    if (other is AlienComponent) {
      hit = true;
      hitPos = other.position;
      
      // Apply effects
      if (type == BulletType.frost) {
          if (slowAmount > 0) other.applySlow(1.0 - slowAmount, freezeDuration > 0 ? 0.5 : 2.0);
          if (freezeDuration > 0) other.freeze(freezeDuration);
      }
      
      other.takeDamage(finalDamage.toDouble());

      // Chain Lightning Logic
      if (type == BulletType.lightning && chainCount > 0) {
          _handleChainLightning(other);
      }
    }
    else if (other is BossComponent) {
      hit = true;
      hitPos = other.position;
      other.takeDamage(finalDamage);
    }
    else if (other is ObstacleComponent) {
       if (other.type == 'asteroid' || other.type == 'debris' || other.type == 'meteor') {
          hit = true;
          hitPos = other.position;
          other.removeFromParent();
          game.runCoins += 1;
       }
    }

    if (hit) {
        if (type == BulletType.explosive || type == BulletType.mine) {
            _explode(hitPos!);
        }
        else if (type == BulletType.crystal) {
            _shatter(hitPos!);
        }

        if (type != BulletType.piercing && 
            type != BulletType.spectral && 
            type != BulletType.blade && 
            type != BulletType.flame &&
            type != BulletType.lightning && // Lightning usually doesn't stick
            type != BulletType.wave) {
          
          if (penetrationCount > 0) {
            penetrationCount--;
          } else {
            removeFromParent();
          }
        }
    }
  }

  void _explode(Vector2 center) {
    double radius = blastRadius > 0 ? blastRadius : 120;
    
    // Nuclear visual
    if (isNuclear) {
        radius = 500; // Screen wipe
        // game.triggerNukeEffect(); // If we had one
    }

    game.children.whereType<AlienComponent>().forEach((alien) {
        final dist = alien.position.distanceTo(center);
        if (dist < radius) {
            double splashDmg = damage * 0.5;
            if (isNuclear) splashDmg = damage * 2.0;
            alien.takeDamage(splashDmg);
            // EMP effect?
        }
    });

    for (final boss in game.children.whereType<BossComponent>()) {
      final dist = boss.position.distanceTo(center);
      if (dist < radius) {
        double splashDmg = damage * 0.3;
        if (isNuclear) splashDmg = damage.toDouble();
        boss.takeDamage(splashDmg.round());
      }
    }
  }

  void _handleChainLightning(PositionComponent currentTarget) {
      _hitTargets.add(currentTarget);
      chainCount--;
      
      PositionComponent? nextTarget;
      double minDist = _chainRange;

      for (final child in game.children) {
          if (child is AlienComponent && !_hitTargets.contains(child) && child.health > 0) {
              final dist = child.position.distanceTo(currentTarget.position);
              if (dist < minDist) {
                  minDist = dist;
                  nextTarget = child;
              }
          }
      }

      if (nextTarget != null) {
          // Spawn new lightning segment
          game.add(BulletComponent(
              position: currentTarget.position,
              velocity: (nextTarget.position - currentTarget.position).normalized() * bulletSpeed,
              type: BulletType.lightning,
              damage: damage, // Maybe degrade damage?
              chainCount: chainCount,
              color: bulletColor,
              size: size,
          ));
      }
  }

  void _shatter(Vector2 center) {
      if (shardCount <= 0) return;
      
      // Create smaller shards
      int count = shardCount > 0 ? shardCount : 4; 
      
      for (int i=0; i<count; i++) {
          double angle = i * (2*pi/count);
          game.add(BulletComponent(
              position: center,
              velocity: Vector2(cos(angle), sin(angle)) * 600,
              type: BulletType.standard,
              damage: (damage * 0.5).ceil(), 
              size: Vector2(4, 8),
              color: Colors.cyanAccent,
          ));
      }
  }

  @override
  void render(Canvas canvas) {
    if (type == BulletType.blackHole) {
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [Colors.black, Colors.purple, Colors.transparent],
            stops: [0.2, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: Offset(size.x/2, size.y/2), radius: size.x/2));
        canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2, paint);
        return;
    }

    final paint = Paint()
      ..color = bulletColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2); // Reduced blur for performance
    
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    if (type == BulletType.explosive || type == BulletType.mine) {
        canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2, paint);
    } else if (type == BulletType.blade) {
        // Draw crescent
        final path = Path();
        path.moveTo(size.x/2, 0);
        path.quadraticBezierTo(size.x, size.y/2, size.x/2, size.y);
        path.quadraticBezierTo(0, size.y/2, size.x/2, 0);
        canvas.drawPath(path, paint);
    } else if (type == BulletType.flame) {
        canvas.drawOval(size.toRect(), paint);
    } else {
        // Standard rect shape
        canvas.drawRect(size.toRect(), paint);
        canvas.drawRect(Rect.fromLTWH(size.x*0.25, size.y*0.25, size.x*0.5, size.y*0.5), corePaint);
    }
  }
}
