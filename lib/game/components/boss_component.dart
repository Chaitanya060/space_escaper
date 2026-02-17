import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../data/boss_data.dart';
import '../space_escaper_game.dart';
import 'player_component.dart';
import 'alien_component.dart';

// ═══════════════════════════════════════
//  BOSS COMPONENT (Data-Driven)
// ═══════════════════════════════════════

class BossComponent extends PositionComponent
    with HasGameReference<SpaceEscaperGame>, CollisionCallbacks {
  final BossConfig config;
  late int maxHealth;
  late int health;
  int currentPhaseIndex = 0;
  double attackTimer = 0;
  int attackIndex = 0;
  double time = 0;
  bool entering = true;
  final double targetY = 120;

  // Shield state
  bool shieldActive = false;
  double shieldTimer = 0;

  // Charge state
  bool isCharging = false;
  Vector2? chargeTarget;
  double chargeTimer = 0;

  // Regen state
  double regenTimer = 0;

  // Teleport
  double teleportTimer = 0;
  double teleportCooldown = 3.0;

  // Clone visuals
  List<Vector2> clonePositions = [];
  double cloneTimer = 0;

  // Rebirth
  bool hasReborn = false;

  BossComponent({required this.config, required Vector2 position})
      : super(
          position: position,
          size: Vector2(config.width, config.height),
          anchor: Anchor.center,
        );

  BossPhase get currentPhase => config.phases[currentPhaseIndex];

  @override
  Future<void> onLoad() async {
    maxHealth = config.maxHealth;
    health = maxHealth;
    add(RectangleHitbox(
      size: Vector2(size.x * 0.8, size.y * 0.8),
      position: Vector2(size.x * 0.1, size.y * 0.1),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;

    // Entry animation
    if (entering) {
      position.y += 60 * dt;
      if (position.y >= targetY) {
        position.y = targetY;
        entering = false;
      }
      return;
    }

    // Phase transitions
    _checkPhaseTransition();

    // Shield timer
    if (shieldActive) {
      shieldTimer -= dt;
      if (shieldTimer <= 0) shieldActive = false;
    }

    // Regen
    if (regenTimer > 0) {
      regenTimer -= dt;
      health = min(maxHealth, health + (maxHealth ~/ 50)); // Heal 2% per tick
    }

    // Clone decay
    if (cloneTimer > 0) {
      cloneTimer -= dt;
      if (cloneTimer <= 0) clonePositions.clear();
    }

    // Charge movement
    if (isCharging && chargeTarget != null) {
      final dir = (chargeTarget! - position).normalized();
      position += dir * 600 * dt;
      chargeTimer -= dt;
      if (chargeTimer <= 0 || position.distanceTo(chargeTarget!) < 20) {
        isCharging = false;
        chargeTarget = null;
      }
    } else {
      _updateMovement(dt);
    }

    // Attack cycle
    final interval = 2.0 / currentPhase.attackSpeedMult;
    attackTimer += dt;
    if (attackTimer >= interval) {
      attackTimer = 0;
      _executeNextAttack();
    }
  }

  void _checkPhaseTransition() {
    final hpPercent = health / maxHealth;
    for (int i = config.phases.length - 1; i >= 0; i--) {
      if (hpPercent <= config.phases[i].healthThreshold && i > currentPhaseIndex) {
        currentPhaseIndex = i;
        attackIndex = 0;
        // Phase transition effect
        game.screenEffects.triggerShake(duration: 0.5, intensity: 10);
        game.showBanner = true;
        game.bannerTimer = 2.0;
        game.bannerText = '${config.emoji} PHASE ${currentPhaseIndex + 1}!';
        game.bannerColor = config.color;
        break;
      }
    }
  }

  void _updateMovement(double dt) {
    switch (config.movement) {
      case BossMovement.sway:
        position.x = game.size.x / 2 + sin(time * 0.8) * 80;
        break;
      case BossMovement.chase:
        final px = game.player.position.x;
        if (position.x < px - 5) position.x += 40 * dt;
        else if (position.x > px + 5) position.x -= 40 * dt;
        break;
      case BossMovement.patrol:
        position.x = game.size.x / 2 + sin(time * 1.2) * (game.size.x * 0.3);
        break;
      case BossMovement.circleOrbit:
        position.x = game.size.x / 2 + cos(time * 0.6) * 100;
        position.y = targetY + sin(time * 0.6) * 40;
        break;
      case BossMovement.teleport:
        teleportTimer -= dt;
        if (teleportTimer <= 0) {
          teleportTimer = teleportCooldown;
          position.x = 60 + Random().nextDouble() * (game.size.x - 120);
        }
        break;
      case BossMovement.charge:
        position.x = game.size.x / 2 + sin(time * 1.5) * 60;
        break;
      case BossMovement.stationary:
        position.x = game.size.x / 2;
        break;
    }
  }

  // ── ATTACK IMPLEMENTATIONS ──

  void _executeNextAttack() {
    final attacks = currentPhase.attacks;
    if (attacks.isEmpty) return;
    final attack = attacks[attackIndex % attacks.length];
    attackIndex++;

    // Apply scaling
    final scaledAttack = BossAttack(
      name: attack.name,
      type: attack.type,
      projectileCount: attack.projectileCount,
      speed: attack.speed * currentPhase.projectileSpeedMult,
      cooldown: attack.cooldown,
    );

    switch (scaledAttack.type) {
      case BossAttackType.radialBurst:
        _doRadialBurst(scaledAttack);
        break;
      case BossAttackType.targetedShot:
        _doTargetedShot(scaledAttack);
        break;
      case BossAttackType.homingMissiles:
        _doHomingMissiles(scaledAttack);
        break;
      case BossAttackType.laserSweep:
        _doLaserSweep(scaledAttack);
        break;
      case BossAttackType.aoeBlast:
        _doAoeBlast(scaledAttack);
        break;
      case BossAttackType.spawnMinions:
        _doSpawnMinions(scaledAttack);
        break;
      case BossAttackType.chargeRush:
        _doChargeRush();
        break;
      case BossAttackType.shieldActivate:
        shieldActive = true;
        shieldTimer = 3.0;
        break;
      case BossAttackType.debuffPlayer:
        _doDebuff();
        break;
      case BossAttackType.summonHazards:
        _doSummonHazards(scaledAttack);
        break;
      case BossAttackType.regenerate:
        regenTimer = 3.0;
        break;
      case BossAttackType.splitClone:
        _doSplitClone(scaledAttack);
        break;
      case BossAttackType.screenWipe:
        _doScreenWipe(scaledAttack);
        break;
      case BossAttackType.vortexPull:
        _doVortexPull();
        break;
      case BossAttackType.groundPound:
        _doGroundPound(scaledAttack);
        break;
      case BossAttackType.rapidFire:
        _doRapidFire(scaledAttack);
        break;
    }
  }

  void _doRadialBurst(BossAttack attack) {
    for (int i = 0; i < attack.projectileCount; i++) {
      final angle = (i / attack.projectileCount) * pi * 2;
      _fireBullet(
        Vector2(cos(angle), sin(angle)) * attack.speed,
        color: config.glowColor.withOpacity(1.0),
      );
    }
  }

  void _doTargetedShot(BossAttack attack) {
    final dir = (game.player.position - position).normalized();
    for (int i = 0; i < attack.projectileCount; i++) {
      final spread = (i - attack.projectileCount / 2) * 0.15;
      final rotated = Vector2(
        dir.x * cos(spread) - dir.y * sin(spread),
        dir.x * sin(spread) + dir.y * cos(spread),
      );
      _fireBullet(rotated * attack.speed, color: config.glowColor.withOpacity(1.0));
    }
  }

  void _doHomingMissiles(BossAttack attack) {
    final rng = Random();
    for (int i = 0; i < min(attack.projectileCount, 10); i++) {
      final angle = rng.nextDouble() * pi * 2;
      game.add(BossHomingBullet(
        position: position.clone(),
        speed: attack.speed,
        color: config.glowColor.withOpacity(1.0),
      ));
    }
  }

  void _doLaserSweep(BossAttack attack) {
    // Fire a line of bullets across the screen
    for (int i = 0; i < 8; i++) {
      final x = (i / 7) * game.size.x;
      _fireBullet(Vector2(0, 300), startPos: Vector2(x, position.y + size.y / 2),
          color: config.color, bulletSize: Vector2(8, 30));
    }
  }

  void _doAoeBlast(BossAttack attack) {
    // Screen-wide pulse
    game.screenEffects.triggerShake(duration: 0.3, intensity: 8);
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * pi * 2;
      _fireBullet(
        Vector2(cos(angle), sin(angle)) * 180,
        color: config.color,
        bulletSize: Vector2(10, 10),
      );
    }
  }

  void _doSpawnMinions(BossAttack attack) {
    final rng = Random();
    final count = min(attack.projectileCount, 12);
    final types = ['chaser', 'weaver', 'dasher'];
    for (int i = 0; i < count; i++) {
      game.add(AlienComponent(
        position: Vector2(
          40 + rng.nextDouble() * (game.size.x - 80),
          -20 - rng.nextDouble() * 60,
        ),
        alienType: types[rng.nextInt(types.length)],
      ));
    }
  }

  void _doChargeRush() {
    isCharging = true;
    chargeTarget = game.player.position.clone();
    chargeTimer = 1.5;
  }

  void _doDebuff() {
    // Invert controls for 3 seconds via game
    game.currentPhysicsMode = 'inverted';
    game.physicsTimer = 3.0;
    game.showBanner = true;
    game.bannerTimer = 1.5;
    game.bannerText = 'CONTROLS DISRUPTED!';
    game.bannerColor = const Color(0xFFFBBF24);
  }

  void _doSummonHazards(BossAttack attack) {
    final rng = Random();
    for (int i = 0; i < min(attack.projectileCount, 8); i++) {
      _fireBullet(
        Vector2((rng.nextDouble() - 0.5) * 100, 150),
        startPos: Vector2(40 + rng.nextDouble() * (game.size.x - 80), position.y + 20),
        color: config.color,
        bulletSize: Vector2(14, 14),
      );
    }
  }

  void _doSplitClone(BossAttack attack) {
    clonePositions.clear();
    final rng = Random();
    for (int i = 0; i < min(attack.projectileCount, 6); i++) {
      clonePositions.add(Vector2(
        60 + rng.nextDouble() * (game.size.x - 120),
        60 + rng.nextDouble() * 100,
      ));
    }
    cloneTimer = 5.0;
  }

  void _doScreenWipe(BossAttack attack) {
    game.screenEffects.triggerShake(duration: 1.0, intensity: 15);
    // Big radial burst with fast projectiles
    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * pi * 2;
      _fireBullet(
        Vector2(cos(angle), sin(angle)) * 350,
        color: Colors.white,
        bulletSize: Vector2(8, 8),
      );
    }
  }

  void _doVortexPull() {
    // Pull player toward boss for 2 seconds
    final dir = (position - game.player.position).normalized();
    game.player.position += dir * 60;
    game.screenEffects.triggerShake(duration: 0.3, intensity: 5);
  }

  void _doGroundPound(BossAttack attack) {
    game.screenEffects.triggerShake(duration: 0.5, intensity: 12);
    // Fire bullets spreading outward from bottom
    for (int i = 0; i < 10; i++) {
      final x = (i / 9) * game.size.x;
      _fireBullet(
        Vector2(0, 250),
        startPos: Vector2(x, position.y + size.y),
        color: config.color,
        bulletSize: Vector2(6, 6),
      );
    }
  }

  void _doRapidFire(BossAttack attack) {
    final dir = (game.player.position - position).normalized();
    for (int i = 0; i < min(attack.projectileCount, 8); i++) {
      final spread = (Random().nextDouble() - 0.5) * 0.3;
      final rotated = Vector2(
        dir.x * cos(spread) - dir.y * sin(spread),
        dir.x * sin(spread) + dir.y * cos(spread),
      );
      _fireBullet(rotated * attack.speed, color: config.glowColor.withOpacity(1.0));
    }
  }

  void _fireBullet(Vector2 velocity, {Vector2? startPos, Color? color, Vector2? bulletSize}) {
    game.add(BossBullet(
      position: startPos ?? position.clone(),
      velocity: velocity,
      bulletColor: color ?? config.glowColor.withOpacity(1.0),
      bulletSize: bulletSize,
    ));
  }

  // ── DAMAGE ──

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      if (other.hit()) game.playerHit();
    }
  }

  void takeDamage(int amount) {
    if (shieldActive) return;
    final effectiveAmount = (amount * currentPhase.armorMult).ceil();
    health -= effectiveAmount;
    if (health <= 0) {
      health = 0;
      if (config.rebirth && !hasReborn) {
        hasReborn = true;
        health = (maxHealth * 0.5).toInt();
        currentPhaseIndex = 0;
        game.showBanner = true;
        game.bannerTimer = 3.0;
        game.bannerText = '${config.emoji} REBORN!';
        game.bannerColor = const Color(0xFFFFD700);
        game.screenEffects.triggerShake(duration: 1.0, intensity: 15);
      } else {
        _onDefeated();
      }
    }
  }

  void _onDefeated() {
    game.onBossDefeated(config.id);
    removeFromParent();
  }

  // ── RENDER ──

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final center = Offset(w / 2, h / 2);

    // Draw clones (faded copies)
    for (final cp in clonePositions) {
      final offset = cp - position;
      canvas.save();
      canvas.translate(offset.x, offset.y);
      _renderBossBody(canvas, w, h, center, alpha: 0.4);
      canvas.restore();
    }

    // Main body
    _renderBossBody(canvas, w, h, center);

    // Shield effect
    if (shieldActive) {
      final shieldPaint = Paint()
        ..color = Colors.cyanAccent.withOpacity(0.3 + sin(time * 6) * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      // Draw shield shape matches boss shape roughly, or just circle for simplicity
      canvas.drawCircle(center, w * 0.55, shieldPaint);
    }

    // Health bar rendered directly on the boss
    _renderHealthBar(canvas, w);
  }

  void _renderBossBody(Canvas canvas, double w, double h, Offset center, {double alpha = 1.0}) {
    // Outer glow
    final glowPaint = Paint()
      ..color = config.glowColor.withOpacity(0.3 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    
    _drawShape(canvas, center, w * 0.45, config.shape, glowPaint);

    // Core body with gradient
    final bodyPaint = Paint()
      ..shader = RadialGradient(colors: [
        config.color.withOpacity(0.9 * alpha),
        config.glowColor.withOpacity(0.6 * alpha),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: center, radius: w * 0.4));
    
    _drawShape(canvas, center, w * 0.38, config.shape, bodyPaint);

    // Inner bright core
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.7 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    _drawShape(canvas, center, w * 0.12, config.shape, corePaint);

    // Rotating particles or details based on shape
    final particlePaint = Paint()..color = config.color.withOpacity(0.6 * alpha);
    for (int i = 0; i < 6; i++) {
      final angle = time * 1.5 + i * (pi / 3);
      final radius = w * 0.3 + sin(time * 2 + i) * 5;
      final dx = center.dx + cos(angle) * radius;
      final dy = center.dy + sin(angle) * radius;
      canvas.drawCircle(Offset(dx, dy), 3, particlePaint);
    }

    // Phase indicator pips
    if (config.phases.length > 1) {
      for (int i = 0; i < config.phases.length; i++) {
        final pipColor = i <= currentPhaseIndex
            ? config.color.withOpacity(alpha)
            : Colors.grey.withOpacity(0.3 * alpha);
        canvas.drawCircle(
          Offset(center.dx - (config.phases.length - 1) * 5 + i * 10, h - 5),
          3,
          Paint()..color = pipColor,
        );
      }
    }

    // Tier glow ring for high-tier bosses
    if (config.tier >= 4) {
      final ringPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.2 * alpha + sin(time * 3) * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      _drawShape(canvas, center, w * 0.48, config.shape, ringPaint);
    }
  }

  void _drawShape(Canvas canvas, Offset center, double radius, BossShape shape, Paint paint) {
    switch (shape) {
      case BossShape.circle:
        canvas.drawCircle(center, radius, paint);
        break;
      case BossShape.crystal:
        // Hexagon
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (i * 60) * pi / 180;
          final x = center.dx + cos(angle) * radius;
          final y = center.dy + sin(angle) * radius;
          if (i == 0) path.moveTo(x, y);
          else path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      case BossShape.sharp:
        // Star-like spikes (8 points)
        final path = Path();
        final innerRadius = radius * 0.5;
        for (int i = 0; i < 16; i++) {
          final angle = (i * 22.5) * pi / 180;
          final r = (i.isEven) ? radius : innerRadius;
          final x = center.dx + cos(angle) * r;
          final y = center.dy + sin(angle) * r;
          if (i == 0) path.moveTo(x, y);
          else path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      case BossShape.tech:
        // Square with cut corners
        final path = Path();
        final r = radius;
        final c = r * 0.3; // corner cut
        path.moveTo(center.dx - r + c, center.dy - r);
        path.lineTo(center.dx + r - c, center.dy - r);
        path.lineTo(center.dx + r, center.dy - r + c);
        path.lineTo(center.dx + r, center.dy + r - c);
        path.lineTo(center.dx + r - c, center.dy + r);
        path.lineTo(center.dx - r + c, center.dy + r);
        path.lineTo(center.dx - r, center.dy + r - c);
        path.lineTo(center.dx - r, center.dy - r + c);
        path.close();
        canvas.drawPath(path, paint);
        break;
      case BossShape.organic:
        // Blobs (simulated by drawing 3 overlapping circles)
        canvas.drawCircle(center, radius * 0.8, paint);
        canvas.drawCircle(Offset(center.dx - radius * 0.3, center.dy - radius * 0.3), radius * 0.6, paint);
        canvas.drawCircle(Offset(center.dx + radius * 0.3, center.dy + radius * 0.3), radius * 0.6, paint);
        break;
      case BossShape.skull:
        // Simplified skull shape
        final path = Path();
        path.addOval(Rect.fromCircle(center: Offset(center.dx, center.dy - radius * 0.2), radius: radius * 0.7));
        path.addRect(Rect.fromLTWH(center.dx - radius * 0.4, center.dy + radius * 0.2, radius * 0.8, radius * 0.6));
        canvas.drawPath(path, paint);
        break;
      case BossShape.star:
        // 5-point star
        final path = Path();
        final innerRadius = radius * 0.4;
        for (int i = 0; i < 10; i++) {
          final angle = (i * 36 - 18) * pi / 180;
          final r = (i.isEven) ? radius : innerRadius;
          final x = center.dx + cos(angle) * r;
          final y = center.dy + sin(angle) * r;
          if (i == 0) path.moveTo(x, y);
          else path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      case BossShape.eye:
        // Eye shape
        final path = Path();
        path.moveTo(center.dx - radius, center.dy);
        path.quadraticBezierTo(center.dx, center.dy - radius * 0.8, center.dx + radius, center.dy);
        path.quadraticBezierTo(center.dx, center.dy + radius * 0.8, center.dx - radius, center.dy);
        path.close();
        canvas.drawPath(path, paint);
        // Draw pupil if this is a fill paint
        if (paint.style == PaintingStyle.fill) {
           canvas.drawCircle(center, radius * 0.3, paint..color = Colors.black);
        }
        break;
      case BossShape.amorphous:
         // Wobbly circle
         final path = Path();
         for (int i = 0; i <= 360; i += 10) {
           final angle = i * pi / 180;
           final wobble = radius + sin(i * 0.1 + time * 5) * 10;
           final x = center.dx + cos(angle) * wobble;
           final y = center.dy + sin(angle) * wobble;
           if (i == 0) path.moveTo(x, y);
           else path.lineTo(x, y);
         }
         path.close();
         canvas.drawPath(path, paint);
         break;
    }
  }

  void _renderHealthBar(Canvas canvas, double w) {
    final barWidth = w * 0.9;
    final barHeight = 8.0;
    final barX = (w - barWidth) / 2;
    final barY = -18.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barWidth, barHeight), const Radius.circular(4)),
      Paint()..color = Colors.black54,
    );

    final hpPercent = health / maxHealth;
    final hpColor = hpPercent > 0.5
        ? Color.lerp(Colors.yellow, Colors.green, (hpPercent - 0.5) * 2)!
        : Color.lerp(Colors.red, Colors.yellow, hpPercent * 2)!;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barWidth * hpPercent, barHeight), const Radius.circular(4)),
      Paint()..color = hpColor,
    );

    // Boss name
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${config.emoji} ${config.name}',
        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset((w - textPainter.width) / 2, barY - 14));
  }
}

// ═══════════════════════════════════════
//  BOSS PROJECTILE
// ═══════════════════════════════════════

class BossBullet extends PositionComponent
    with HasGameReference<SpaceEscaperGame>, CollisionCallbacks {
  final Vector2 velocity;
  final Color bulletColor;

  BossBullet({
    required Vector2 position,
    required this.velocity,
    Vector2? bulletSize,
    this.bulletColor = const Color(0xFFFF6B35),
  }) : super(position: position, size: bulletSize ?? Vector2(6, 6), anchor: Anchor.center);

  @override
  Future<void> onLoad() async { add(CircleHitbox(radius: size.x / 2)); }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    if (position.y > game.size.y + 50 || position.y < -50 ||
        position.x < -50 || position.x > game.size.x + 50) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      if (other.hit()) game.playerHit();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = bulletColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 4, Paint()..color = Colors.white.withOpacity(0.8));
  }
}

// ═══════════════════════════════════════
//  BOSS HOMING BULLET
// ═══════════════════════════════════════

class BossHomingBullet extends PositionComponent
    with HasGameReference<SpaceEscaperGame>, CollisionCallbacks {
  final double speed;
  final Color color;
  double lifeTime = 0;

  BossHomingBullet({required Vector2 position, this.speed = 200, this.color = const Color(0xFFFF6B35)})
      : super(position: position, size: Vector2(8, 8), anchor: Anchor.center);

  @override
  Future<void> onLoad() async { add(CircleHitbox(radius: 4)); }

  @override
  void update(double dt) {
    super.update(dt);
    lifeTime += dt;
    if (lifeTime > 4.0) { removeFromParent(); return; }

    final dir = (game.player.position - position).normalized();
    position += dir * speed * dt;

    if (position.y > game.size.y + 50 || position.y < -50) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      if (other.hit()) game.playerHit();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 4, paint);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 2, Paint()..color = Colors.white);
  }
}
