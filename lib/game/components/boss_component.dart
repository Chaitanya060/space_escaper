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

  double damageFlashTimer = 0;

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

    if (damageFlashTimer > 0) {
      damageFlashTimer -= dt;
    }

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

  int _scaledSafeSpan(int slots) {
    final base = 3 + (config.tier ~/ 2);
    return base.clamp(3, max(3, slots - 1));
  }

  bool _inWrappedSpan(int i, int start, int span, int slots) {
    final d = (i - start) % slots;
    return d >= 0 && d < span;
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
      // ── Tier 1 Boss-Specific Attacks ──
      case BossAttackType.solarFlareRings:
        _doSolarFlareRings(scaledAttack);
        break;
      case BossAttackType.heatWaveBeam:
        _doHeatWaveBeam(scaledAttack);
        break;
      case BossAttackType.coronaShield:
        _doCoronaShield();
        break;
      case BossAttackType.sunspotMines:
        _doSunspotMines(scaledAttack);
        break;
      case BossAttackType.voidTendrils:
        _doVoidTendrils(scaledAttack);
        break;
      case BossAttackType.darkMatterOrbs:
        _doDarkMatterOrbs(scaledAttack);
        break;
      case BossAttackType.singularityPulse:
        _doSingularityPulse();
        break;
      case BossAttackType.laserGridPattern:
        _doLaserGridPattern(scaledAttack);
        break;
      case BossAttackType.defenseTurrets:
        _doDefenseTurrets(scaledAttack);
        break;
      case BossAttackType.empBlast:
        _doEmpBlast();
        break;
      case BossAttackType.chainLightning:
        _doChainLightning(scaledAttack);
        break;
      case BossAttackType.thunderDive:
        _doThunderDive();
        break;
      case BossAttackType.staticField:
        _doStaticField();
        break;
      case BossAttackType.lightningStorm:
        _doLightningStorm(scaledAttack);
        break;
      case BossAttackType.iceSpikeRain:
        _doIceSpikeRain(scaledAttack);
        break;
      case BossAttackType.freezeBeam:
        _doFreezeBeam();
        break;
      case BossAttackType.blizzard:
        _doBlizzard();
        break;
      case BossAttackType.iceWallMaze:
        _doIceWallMaze();
        break;
      case BossAttackType.permafrost:
      _doPermafrost();
      break;
    
    // ── Tier 2 Boss-Specific Attacks ──
    case BossAttackType.hurricaneForce:
      _doHurricaneForce(scaledAttack);
      break;
    case BossAttackType.tornadoSpawns:
      _doTornadoSpawns(scaledAttack);
      break;
    case BossAttackType.debrisHurricane:
      _doDebrisHurricane(scaledAttack);
      break;
    case BossAttackType.windBlades:
      _doWindBlades(scaledAttack);
      break;
    case BossAttackType.shieldCharge:
      _doShieldCharge(scaledAttack);
      break;
    case BossAttackType.plasmaTail:
      _doPlasmaTail(scaledAttack);
      break;
    case BossAttackType.acidMissiles:
      _doAcidMissiles(scaledAttack);
      break;
    case BossAttackType.clawPincer:
      _doClawPincer(scaledAttack);
      break;
    case BossAttackType.undergroundAssault:
      _doUndergroundAssault(scaledAttack);
      break;
    case BossAttackType.flameBreath:
      _doFlameBreath(scaledAttack);
      break;
    case BossAttackType.wingGust:
      _doWingGust(scaledAttack);
      break;
    case BossAttackType.meteorSummon:
      _doMeteorSummon(scaledAttack);
      break;
    case BossAttackType.dragonDive:
      _doDragonDive(scaledAttack);
      break;
    case BossAttackType.supernova:
      _doSupernova(scaledAttack);
      break;
    case BossAttackType.deathStare:
      _doDeathStare(scaledAttack);
      break;
    case BossAttackType.visionBlast:
      _doVisionBlast(scaledAttack);
      break;
    case BossAttackType.hypnoticPulse:
      _doHypnoticPulse(scaledAttack);
      break;
    case BossAttackType.webTrap:
      _doWebTrap(scaledAttack);
      break;
    case BossAttackType.legSlam:
      _doLegSlam(scaledAttack);
      break;
    case BossAttackType.poisonBite:
      _doPoisonBite(scaledAttack);
      break;
    case BossAttackType.webCocoon:
      _doWebCocoon(scaledAttack);
      break;
    case BossAttackType.eggSacs:
      _doSpawnMinions(scaledAttack);
      break;
    case BossAttackType.lavaPool:
      _doLavaPool(scaledAttack);
      break;
    case BossAttackType.moltenFists:
      _doMoltenFists(scaledAttack);
      break;
    case BossAttackType.volcanicEruption:
      _doVolcanicEruption(scaledAttack);
      break;
    case BossAttackType.fireballVolley:
      _doFireballVolley(scaledAttack);
      break;
    case BossAttackType.shadowClone:
      _doSplitClone(scaledAttack); // Re-use split clone
      break;
    case BossAttackType.eclipseBeam:
      _doEclipseBeam(scaledAttack);
      break;
    }
  }

  void _doFireballVolley(BossAttack attack) {
    final targetDir = (game.player.position - position).normalized();
    final angleStep = 0.2; 
    final count = attack.projectileCount;
    final startAngle = -((count - 1) * angleStep) / 2;

    for (int i = 0; i < count; i++) {
      final angle = startAngle + i * angleStep;
      final dx = targetDir.x * cos(angle) - targetDir.y * sin(angle);
      final dy = targetDir.x * sin(angle) + targetDir.y * cos(angle);
      final velocity = Vector2(dx, dy) * attack.speed;

      _fireBullet(velocity, color: Colors.orange, bulletSize: Vector2(12, 12));
    }
  }

  void _doRadialBurst(BossAttack attack) {
    // Create gap for escape - skip 2-3 bullets
    final gapAngle = Random().nextDouble() * pi * 2;
    for (int i = 0; i < attack.projectileCount; i++) {
      final angle = (i / attack.projectileCount) * pi * 2;
      // Skip bullets in gap area (wider gap for easier escape)
      final gapDiff = (angle - gapAngle).abs() % (pi * 2);
      if (gapDiff < 0.95 || gapDiff > pi * 2 - 0.95) continue;
      _fireBullet(
        Vector2(cos(angle), sin(angle)) * attack.speed,
        color: config.glowColor.withValues(alpha: 1.0),
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
      _fireBullet(rotated * attack.speed, color: config.glowColor.withValues(alpha: 1.0));
    }
  }

  void _doHomingMissiles(BossAttack attack) {
    final rng = Random();
    for (int i = 0; i < min(attack.projectileCount, 10); i++) {
      final angle = rng.nextDouble() * pi * 2;
      game.add(BossHomingBullet(
        position: position.clone(),
        speed: attack.speed,
        color: config.glowColor.withValues(alpha: 1.0),
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
    // Screen-wide pulse with escape gap
    game.screenEffects.triggerShake(duration: 0.3, intensity: 8);
    final gapAngle = Random().nextDouble() * pi * 2;
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * pi * 2;
      // Skip bullets in gap area for escape route
      final gapDiff = (angle - gapAngle).abs() % (pi * 2);
      if (gapDiff < 0.95 || gapDiff > pi * 2 - 0.95) continue;
      _fireBullet(
        Vector2(cos(angle), sin(angle)) * 180,
        color: config.color,
        bulletSize: Vector2(10, 10),
      );
    }
  }

  void _doSpawnMinions(BossAttack attack) {
    if (game.gameMode == GameMode.bossRush) return;
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
    if (game.gameMode == GameMode.bossRush) return;
    // Invert controls for 3 seconds via game
    game.currentPhysicsMode = 'inverted';
    game.physicsTimer = 3.0;
    game.showBanner = true;
    game.bannerTimer = 1.5;
    game.bannerText = 'CONTROLS DISRUPTED!';
    game.bannerColor = const Color(0xFFFBBF24);
  }

  void _doSummonHazards(BossAttack attack) {
    if (game.gameMode == GameMode.bossRush) return;
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
    // Big radial burst with fast projectiles - with escape gap
    final gapAngle = Random().nextDouble() * pi * 2;
    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * pi * 2;
      // Skip bullets in gap area for escape route
      final gapDiff = (angle - gapAngle).abs() % (pi * 2);
      if (gapDiff < 1.3 || gapDiff > pi * 2 - 1.3) continue;
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
    // Fire bullets spreading outward from bottom with safe gap
    final cols = 10;
    final safeCol = Random().nextInt(cols);
    final safeSpan = _scaledSafeSpan(cols);
    for (int i = 0; i < cols; i++) {
      if (_inWrappedSpan(i, safeCol, safeSpan, cols)) continue;
      final x = (i / (cols - 1)) * game.size.x;
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
      _fireBullet(rotated * attack.speed, color: config.glowColor.withValues(alpha: 1.0));
    }
  }

  void _fireBullet(Vector2 velocity, {Vector2? startPos, Color? color, Vector2? bulletSize}) {
    game.add(BossBullet(
      position: startPos ?? position.clone(),
      velocity: velocity,
      bulletColor: color ?? config.glowColor.withValues(alpha: 1.0),
      bulletSize: bulletSize,
    ));
  }

  // ══════════════════════════════════════════
  //  TIER 1 BOSS-SPECIFIC ATTACKS
  // ══════════════════════════════════════════

  // ── SOLAR TITAN ──

  void _doSolarFlareRings(BossAttack attack) {
    // Fire expanding rings with gaps — multiple concentric rings
    final ringCount = attack.projectileCount.clamp(1, 5);
    for (int ring = 0; ring < ringCount; ring++) {
      final gapAngle = Random().nextDouble() * pi * 2; // random gap
      for (int i = 0; i < 12; i++) {
        final angle = (i / 12) * pi * 2;
        // Skip 3 bullets around the gap (increased from 2 for larger gap)
        final gapDiff = (angle - gapAngle).abs() % (pi * 2);
        if (gapDiff < 1.4 || gapDiff > pi * 2 - 1.4) continue;
        final speed = attack.speed + ring * 30;
        _fireBullet(
          Vector2(cos(angle), sin(angle)) * speed,
          color: const Color(0xFFFFD700),
          bulletSize: Vector2(6, 6),
        );
      }
    }
    game.screenEffects.triggerFlash(color: const Color(0xFFFFD700).withValues(alpha: 0.3), duration: 0.15);
  }

  void _doHeatWaveBeam(BossAttack attack) {
    // Horizontal sweeping beam — a dense line of bullets across X with safe gap
    game.screenEffects.triggerFlash(color: const Color(0xFFFF6B00).withValues(alpha: 0.3), duration: 0.3);
    final cols = 15;
    final safeCol = Random().nextInt(cols);
    final safeSpan = _scaledSafeSpan(cols);
    for (int i = 0; i < cols; i++) {
      if (_inWrappedSpan(i, safeCol, safeSpan, cols)) continue;
      final x = (i / (cols - 1)) * game.size.x;
      _fireBullet(
        Vector2(0, 200),
        startPos: Vector2(x, position.y + size.y / 2),
        color: const Color(0xFFFF6B00),
        bulletSize: Vector2(10, 25),
      );
    }
  }

  void _doCoronaShield() {
    // Activate a fire shield + push outward ring with escape gap
    shieldActive = true;
    shieldTimer = 4.0;
    // Push-back ring with gap
    final gapAngle = Random().nextDouble() * pi * 2;
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * pi * 2;
      // Skip bullets in gap area for escape route
      final gapDiff = (angle - gapAngle).abs() % (pi * 2);
      if (gapDiff < 1.3 || gapDiff > pi * 2 - 1.3) continue;
      _fireBullet(
        Vector2(cos(angle), sin(angle)) * 250,
        color: const Color(0xFFFF4500),
        bulletSize: Vector2(8, 8),
      );
    }
    game.screenEffects.triggerShake(duration: 0.3, intensity: 6);
    game.showBanner = true;
    game.bannerTimer = 1.5;
    game.bannerText = '☀️ CORONA SHIELD!';
    game.bannerColor = const Color(0xFFFFD700);
  }

  void _doSunspotMines(BossAttack attack) {
    // Spawn slow-moving mines that drift downward
    final rng = Random();
    for (int i = 0; i < min(attack.projectileCount, 8); i++) {
      final x = 50 + rng.nextDouble() * (game.size.x - 100);
      _fireBullet(
        Vector2((rng.nextDouble() - 0.5) * 40, 60 + rng.nextDouble() * 40),
        startPos: Vector2(x, position.y + 20),
        color: const Color(0xFFFF8C00),
        bulletSize: Vector2(16, 16),
      );
    }
  }

  // ── VOID DEVOURER ──

  void _doVoidTendrils(BossAttack attack) {
    // 8-directional shots (cardinal + diagonal) with escape gap
    final count = min(attack.projectileCount, 16);
    final gapAngle = Random().nextDouble() * pi * 2;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * pi * 2;
      // Skip bullets in gap area for escape route
      final gapDiff = (angle - gapAngle).abs() % (pi * 2);
      if (gapDiff < 1.3 || gapDiff > pi * 2 - 1.3) continue;
      _fireBullet(
        Vector2(cos(angle), sin(angle)) * attack.speed,
        color: const Color(0xFF8B5CF6),
        bulletSize: Vector2(5, 20),
      );
    }
    // Secondary inner ring slightly delayed - also with gap
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * pi * 2 + pi / 4;
      final gapDiff = (angle - gapAngle).abs() % (pi * 2);
      if (gapDiff < 1.4 || gapDiff > pi * 2 - 1.4) continue;
      _fireBullet(
        Vector2(cos(angle), sin(angle)) * (attack.speed * 0.6),
        color: const Color(0xFFA855F7),
        bulletSize: Vector2(8, 8),
      );
    }
  }

  void _doDarkMatterOrbs(BossAttack attack) {
    // Slow floating orbs that drift randomly
    final rng = Random();
    for (int i = 0; i < min(attack.projectileCount, 8); i++) {
      _fireBullet(
        Vector2((rng.nextDouble() - 0.5) * 60, 40 + rng.nextDouble() * 60),
        color: const Color(0xFF581C87),
        bulletSize: Vector2(18, 18),
      );
    }
  }

  void _doSingularityPulse() {
    // Pull player toward boss + expanding push wave with escape gap
    final dir = (position - game.player.position).normalized();
    game.player.position += dir * 80;
    game.screenEffects.triggerShake(duration: 0.5, intensity: 8);
    // Expanding ring of bullets with gap
    final gapAngle = Random().nextDouble() * pi * 2;
    for (int i = 0; i < 20; i++) {
      final angle = (i / 20) * pi * 2;
      // Skip bullets in gap area for escape route
      final gapDiff = (angle - gapAngle).abs() % (pi * 2);
      if (gapDiff < 1.3 || gapDiff > pi * 2 - 1.3) continue;
      _fireBullet(
        Vector2(cos(angle), sin(angle)) * 200,
        color: const Color(0xFF7C3AED),
        bulletSize: Vector2(6, 6),
      );
    }
  }

  // ── AI DREADNOUGHT ──

  void _doLaserGridPattern(BossAttack attack) {
    // Grid of vertical + horizontal laser lines with safe gaps
    final rng = Random();
    final safeCol = rng.nextInt(5);
    final safeSpan = _scaledSafeSpan(5);
    final safeRow = rng.nextInt(3);

    // Vertical lines - skip a multi-column span for a safe gap
    for (int i = 0; i < 5; i++) {
      if (_inWrappedSpan(i, safeCol, safeSpan, 5)) continue;
      final x = game.size.x * (i + 1) / 6;
      _fireBullet(
        Vector2(0, 350),
        startPos: Vector2(x, position.y + size.y / 2),
        color: const Color(0xFFEF4444),
        bulletSize: Vector2(4, 40),
      );
    }
    // Horizontal lines
    for (int i = 0; i < 3; i++) {
      if (i == safeRow) continue;
      for (int j = 0; j < 8; j++) {
        _fireBullet(
          Vector2(0, 200 + i * 60),
          startPos: Vector2(j * (game.size.x / 7), position.y + size.y / 2 + i * 20),
          color: const Color(0xFFDC2626),
          bulletSize: Vector2(30, 4),
        );
      }
    }
    game.screenEffects.triggerFlash(color: const Color(0xFFEF4444).withValues(alpha: 0.2), duration: 0.15);
  }

  void _doDefenseTurrets(BossAttack attack) {
    // Spawn rotating burst from left and right sides
    final turretCount = min(attack.projectileCount, 4);
    for (int t = 0; t < turretCount; t++) {
      final turretX = t.isEven ? position.x - size.x * 0.4 : position.x + size.x * 0.4;
      final turretPos = Vector2(turretX, position.y + size.y * 0.3);
      for (int i = 0; i < 6; i++) {
        final angle = (i / 6) * pi * 2 + time * 2;
        _fireBullet(
          Vector2(cos(angle), sin(angle)) * 180,
          startPos: turretPos,
          color: const Color(0xFF00D9FF),
          bulletSize: Vector2(5, 5),
        );
      }
    }
  }

  void _doEmpBlast() {
    // Slows player movement and fire rate
    game.player.applySlow(3.0, amount: 0.4);
    game.screenEffects.triggerShake(duration: 0.3, intensity: 6);
    game.screenEffects.triggerFlash(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), duration: 0.3);
    game.showBanner = true;
    game.bannerTimer = 1.5;
    game.bannerText = '⚡ EMP BLAST!';
    game.bannerColor = const Color(0xFF3B82F6);
    // Fire a slow expanding ring with escape gap
    final gapAngle = Random().nextDouble() * pi * 2;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * pi * 2;
      // Skip bullets in gap area for escape route
      final gapDiff = (angle - gapAngle).abs() % (pi * 2);
      if (gapDiff < 1.4 || gapDiff > pi * 2 - 1.4) continue;
      _fireBullet(
        Vector2(cos(angle), sin(angle)) * 150,
        color: const Color(0xFF60A5FA),
        bulletSize: Vector2(8, 8),
      );
    }
  }

  // ── THUNDER LEVIATHAN ──

  void _doChainLightning(BossAttack attack) {
    // Fast chaining bolt toward player with branches
    final dir = (game.player.position - position).normalized();
    final count = min(attack.projectileCount, 5);
    for (int i = 0; i < count; i++) {
      final spread = (i - count / 2) * 0.2;
      final rotated = Vector2(
        dir.x * cos(spread) - dir.y * sin(spread),
        dir.x * sin(spread) + dir.y * cos(spread),
      );
      _fireBullet(
        rotated * attack.speed,
        color: const Color(0xFFFBBF24),
        bulletSize: Vector2(4, 30),
      );
    }
    game.screenEffects.triggerFlash(color: const Color(0xFFFBBF24).withValues(alpha: 0.3), duration: 0.1);
  }

  void _doThunderDive() {
    // Charge rush toward player with shockwave on landing
    isCharging = true;
    chargeTarget = game.player.position.clone();
    chargeTimer = 1.2;
    // Shockwave ring with escape gap
    final gapAngle = Random().nextDouble() * pi * 2;
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * pi * 2;
      // Skip bullets in gap area for escape route
      final gapDiff = (angle - gapAngle).abs() % (pi * 2);
      if (gapDiff < 1.3 || gapDiff > pi * 2 - 1.3) continue;
      _fireBullet(
        Vector2(cos(angle), sin(angle)) * 220,
        color: const Color(0xFFFFD700),
        bulletSize: Vector2(7, 7),
      );
    }
    game.screenEffects.triggerShake(duration: 0.6, intensity: 12);
    game.screenEffects.triggerFlash(color: Colors.white.withValues(alpha: 0.5), duration: 0.15);
  }

  void _doStaticField() {
    // Dangerous electric floor zone — horizontal carpet of bullets
    game.screenEffects.triggerShake(duration: 0.2, intensity: 4);
    final rng = Random();
    final cols = 8; // fewer columns for wider spacing
    final safeLane = rng.nextInt(cols);
    final safeSpan = _scaledSafeSpan(cols);
    final margin = game.size.x * 0.06;
    for (int i = 0; i < cols; i++) {
      if (_inWrappedSpan(i, safeLane, safeSpan, cols)) continue;
      for (int j = 0; j < 3; j++) {
        final x = margin + (i / (cols - 1)) * (game.size.x - margin * 2);
        _fireBullet(
          Vector2(0, 60 + j * 30),
          startPos: Vector2(x, game.size.y * 0.5 + j * 40),
          color: const Color(0xFFFBBF24).withValues(alpha: 0.8),
          bulletSize: Vector2(12, 4),
        );
      }
    }
    game.showBanner = true;
    game.bannerTimer = 1.0;
    game.bannerText = '⚡ STATIC FIELD!';
    game.bannerColor = const Color(0xFFFBBF24);
  }

  void _doLightningStorm(BossAttack attack) {
    // Random targeted lightning strikes around player
    final rng = Random();
    final playerPos = game.player.position;
    final count = min(attack.projectileCount, 10);
    for (int i = 0; i < count; i++) {
      final targetX = playerPos.x + (rng.nextDouble() - 0.5) * 150;
      final targetY = playerPos.y + (rng.nextDouble() - 0.5) * 100;
      _fireBullet(
        Vector2(0, 500),
        startPos: Vector2(targetX.clamp(20, game.size.x - 20), -10 - rng.nextDouble() * 40),
        color: const Color(0xFFFFFFFF),
        bulletSize: Vector2(3, 35),
      );
    }
    game.screenEffects.triggerFlash(color: const Color(0xFFFBBF24).withValues(alpha: 0.4), duration: 0.1);
  }

  // ── CRYO COLOSSUS ──

  void _doIceSpikeRain(BossAttack attack) {
    // Diagonal rain pattern from top
    final rng = Random();
    final count = min(attack.projectileCount, 15);
    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * game.size.x;
      _fireBullet(
        Vector2((rng.nextDouble() - 0.5) * 80, attack.speed),
        startPos: Vector2(x, -10),
        color: const Color(0xFF67E8F9),
        bulletSize: Vector2(5, 18),
      );
    }
  }

  void _doFreezeBeam() {
    // Wide beam that freezes on hit — wide horizontal beam with safe gap
    game.player.applyFreeze(1.5);
    game.screenEffects.triggerFlash(color: const Color(0xFF06B6D4).withValues(alpha: 0.4), duration: 0.3);
    // Visual beam bullets
    final cols = 10;
    final safeCol = Random().nextInt(cols);
    final safeSpan = _scaledSafeSpan(cols);
    for (int i = 0; i < cols; i++) {
      if (_inWrappedSpan(i, safeCol, safeSpan, cols)) continue;
      final x = (i / (cols - 1)) * game.size.x;
      _fireBullet(
        Vector2(0, 180),
        startPos: Vector2(x, position.y + size.y / 2),
        color: const Color(0xFF22D3EE),
        bulletSize: Vector2(12, 20),
      );
    }
    game.showBanner = true;
    game.bannerTimer = 1.0;
    game.bannerText = '🧊 FROZEN!';
    game.bannerColor = const Color(0xFF06B6D4);
  }

  void _doBlizzard() {
    // Reduce visibility + slow player + snow particles
    game.player.applySlow(4.0, amount: 0.5);
    game.screenEffects.triggerFlash(color: Colors.white.withValues(alpha: 0.3), duration: 0.5);
    // Snow particles from all directions
    final rng = Random();
    for (int i = 0; i < 20; i++) {
      _fireBullet(
        Vector2((rng.nextDouble() - 0.5) * 100, 100 + rng.nextDouble() * 100),
        startPos: Vector2(rng.nextDouble() * game.size.x, -10),
        color: Colors.white.withValues(alpha: 0.7),
        bulletSize: Vector2(4, 4),
      );
    }
    game.showBanner = true;
    game.bannerTimer = 2.0;
    game.bannerText = '🧊 BLIZZARD!';
    game.bannerColor = const Color(0xFF06B6D4);
  }

  void _doIceWallMaze() {
    // Ice wall sections with gaps - skip 2 slots for wider gap
    final safeSlot = Random().nextInt(5);
    final safeSpan = _scaledSafeSpan(5);
    for (int i = 0; i < 5; i++) {
      if (_inWrappedSpan(i, safeSlot, safeSpan, 5)) continue;
      final x = game.size.x * (i + 0.5) / 5;
      for (int j = 0; j < 3; j++) {
        _fireBullet(
          Vector2(0, 100),
          startPos: Vector2(x, position.y + size.y / 2 + j * 20),
          color: const Color(0xFF67E8F9),
          bulletSize: Vector2(30, 10),
        );
      }
    }
  }

  void _doPermafrost() {
    // Permanent slow zones + freeze
    game.player.applyFreeze(2.0);
    game.player.applySlow(5.0, amount: 0.3);
    game.screenEffects.triggerShake(duration: 0.5, intensity: 8);
    game.screenEffects.triggerFlash(color: const Color(0xFF06B6D4).withValues(alpha: 0.5), duration: 0.4);
    // Ice ring with escape gap
    final gapAngle = Random().nextDouble() * pi * 2;
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * pi * 2;
      // Skip bullets in gap area for escape route
      final gapDiff = (angle - gapAngle).abs() % (pi * 2);
      if (gapDiff < 1.3 || gapDiff > pi * 2 - 1.3) continue;
      _fireBullet(
        Vector2(cos(angle), sin(angle)) * 120,
        color: const Color(0xFF06B6D4),
        bulletSize: Vector2(10, 10),
      );
    }
    game.showBanner = true;
    game.bannerTimer = 2.0;
    game.bannerText = '🧊 PERMAFROST!';
    game.bannerColor = const Color(0xFF22D3EE);
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
    damageFlashTimer = 0.15;

    if (health <= 0) {
      health = 0;
      if (config.rebirth && !hasReborn) {
        hasReborn = true;
        health = maxHealth;
        game.showBanner = true;
        game.bannerTimer = 2.0;
        game.bannerText = '${config.emoji} REBORN!';
        game.bannerColor = config.color;
        game.screenEffects.triggerShake(duration: 0.8, intensity: 14);
      } else {
        game.screenEffects.triggerShake(duration: 1.0, intensity: 15);
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
        ..color = Colors.cyanAccent.withValues(alpha: 0.3 + sin(time * 6) * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      // Draw shield shape matches boss shape roughly, or just circle for simplicity
      canvas.drawCircle(center, w * 0.55, shieldPaint);
    }

    // Health bar rendered directly on the boss
    _renderHealthVisual(canvas, w, h, center);
  }

  double get _hpPercent => (health / maxHealth).clamp(0.0, 1.0);

  void _renderHealthVisual(Canvas canvas, double w, double h, Offset center) {
    switch (config.id) {
      case 'solar_titan':
        _renderSolarTitanHp(canvas, w, h, center);
        return;
      case 'void_devourer':
        _renderVoidDevourerHp(canvas, w, h, center);
        return;
      case 'ai_dreadnought':
        _renderAiDreadnoughtHp(canvas, w, h, center);
        return;
      case 'thunder_leviathan':
        _renderThunderLeviathanHp(canvas, w, h, center);
        return;
      case 'cryo_colossus':
        _renderCryoColossusHp(canvas, w, h, center);
        return;
      default:
        _renderHealthBar(canvas, w);
        return;
    }
  }

  void _renderSolarTitanHp(Canvas canvas, double w, double h, Offset center) {
    final hp = _hpPercent;
    final isPhase = hp <= 0.5;
    final isRage = hp <= 0.2;

    final ringRadius = w * 0.42;
    final stroke = 6.0;

    final ringBaseColor = isRage ? const Color(0xFFB91C1C) : const Color(0xFFFFD700);
    final flash = damageFlashTimer > 0 ? (0.4 + 0.6 * (sin(time * 40).abs())) : 1.0;

    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringRadius),
      -pi / 2,
      pi * 2,
      false,
      bgPaint,
    );

    final hpPaint = Paint()
      ..color = ringBaseColor.withValues(alpha: (0.9 * flash).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    if (!isPhase) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        -pi / 2,
        pi * 2 * hp,
        false,
        hpPaint,
      );
    } else {
      final halfGap = 0.25;
      final arc = (pi * 2 - halfGap) * hp;
      final a = time * 1.6;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        -pi / 2 + a,
        arc.clamp(0.0, pi * 2),
        false,
        hpPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        -pi / 2 - a,
        arc.clamp(0.0, pi * 2),
        false,
        hpPaint,
      );
    }

    if (hp <= 0.35) {
      final crackCount = (4 + ((1.0 - hp) * 10).floor()).clamp(4, 14);
      final crackPaint = Paint()
        ..color = (isRage ? const Color(0xFFFF3D00) : const Color(0xFFFFA000)).withValues(alpha: 0.55)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      for (int i = 0; i < crackCount; i++) {
        final ang = (i / crackCount) * pi * 2 + sin(time * 2 + i) * 0.2;
        final p1 = Offset(center.dx + cos(ang) * (ringRadius - 10), center.dy + sin(ang) * (ringRadius - 10));
        final p2 = Offset(center.dx + cos(ang) * (ringRadius + 6), center.dy + sin(ang) * (ringRadius + 6));
        canvas.drawLine(p1, p2, crackPaint);
      }
    }
  }

  void _renderVoidDevourerHp(Canvas canvas, double w, double h, Offset center) {
    final hp = _hpPercent;
    final isPhase = hp <= 0.5;
    final isRage = hp <= 0.2;
    final flash = damageFlashTimer > 0 ? (0.35 + 0.65 * (sin(time * 50).abs())) : 1.0;

    final radius = w * 0.30;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, pi * 2, false, bgPaint);

    final glowColor = isRage ? const Color(0xFFEC4899) : const Color(0xFF8B5CF6);
    final hpPaint = Paint()
      ..color = glowColor.withValues(alpha: (0.9 * flash).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final wobble = isPhase ? (sin(time * 6) * 0.15) : 0.0;
    final start = -pi / 2 + wobble;
    final sweep = (pi * 2 * hp).clamp(0.05, pi * 2);
    canvas.drawArc(rect, start, sweep, false, hpPaint);

      if (isRage) {
        final ripplePaint = Paint()
          ..color = glowColor.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        for (int i = 0; i < 3; i++) {
          final r = radius + 14 + i * 10 + sin(time * 4 + i) * 3;
          canvas.drawCircle(center, r, ripplePaint);
        }
      }
    }

  // ═══════════════════════════════════════
  //  TIER 2 BOSS ATTACK IMPLEMENTATIONS
  // ═══════════════════════════════════════

  // -- Tempest Titan --
  void _doHurricaneForce(BossAttack attack) {
    // Constant wind push for a duration
    game.screenEffects.triggerShake(duration: 0.5, intensity: 5);
    // Logic handled in update loop by checking a flag or adding a wind component
    // For now, simple implementation: push player over time
    // We'll add a 'windForce' vector to player in next step or use a timer here
    // Simulating wind by spawning invisible projectiles that push? No, direct position mod is better
    // Let's add a wind effect helper
    _applyWindForce(Vector2(-50, 0), duration: 8.0); 
  }

  void _doTornadoSpawns(BossAttack attack) {
    // Spawn small tornadoes that move towards player
    final rng = Random();
    for (int i = 0; i < attack.projectileCount; i++) {
      _fireBullet(
        (game.player.position - Vector2(rng.nextDouble() * game.size.x, 0)).normalized() * 100,
        startPos: Vector2(game.size.x * rng.nextDouble(), rng.nextBool() ? 0 : game.size.y),
        color: Colors.grey,
        bulletSize: Vector2(30, 30), // Bigger graphical size for tornado
      );
    }
  }

  void _doDebrisHurricane(BossAttack attack) {
    // Waves of debris from side
    game.screenEffects.triggerShake(duration: 1.0, intensity: 8);
    final rng = Random();
    for (int i = 0; i < attack.projectileCount; i++) {
       double speed = attack.speed * (0.8 + rng.nextDouble() * 0.4);
       _fireBullet(
         Vector2(-speed, (rng.nextDouble() - 0.5) * 50),
         startPos: Vector2(game.size.x + 50, rng.nextDouble() * game.size.y),
         color: Colors.brown,
         bulletSize: Vector2(12 + rng.nextDouble() * 12, 12 + rng.nextDouble() * 12),
       );
    }
  }

  void _doWindBlades(BossAttack attack) {
    // Bouncing fast projectiles
    final rng = Random();
    for (int i = 0; i < attack.projectileCount; i++) {
      double angle = rng.nextDouble() * pi * 2;
      Vector2 dir = Vector2(cos(angle), sin(angle));
      _fireBullet(
        dir * attack.speed,
        color: Colors.cyanAccent,
        bulletSize: Vector2(20, 5),
        // Note: Bounce logic would need to be in BossBullet, for now they just fly
      );
    }
  }

  void _doShieldCharge(BossAttack attack) {
    _doChargeRush(); // Reuse charge for now
    shieldActive = true;
    shieldTimer = 5.0;
  }

  // -- Scorpion Mech --
  void _doPlasmaTail(BossAttack attack) {
    // Arcing shot to player pos
     Vector2 target = game.player.position.clone();
     Vector2 dir = (target - position).normalized();
     _fireBullet(
       dir * attack.speed,
       color: Colors.greenAccent,
       bulletSize: Vector2(25, 25),
     );
  }

  void _doAcidMissiles(BossAttack attack) {
    // Homing missiles that leave puddles (puddle logic simplified to projectile)
    _doHomingMissiles(attack);
  }

  void _doClawPincer(BossAttack attack) {
    // Fast charge
    _doChargeRush();
  }

  void _doUndergroundAssault(BossAttack attack) {
    // Teleport ground slam
    game.screenEffects.triggerShake(duration: 0.5, intensity: 10);
    // Teleport near player and slam down
    position.setFrom(Vector2(game.player.position.x, game.player.position.y - 200));
    // Fire shockwave on landing
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * pi * 2;
      _fireBullet(
        Vector2(cos(angle), sin(angle)) * 200,
        color: Colors.brown,
        bulletSize: Vector2(10, 10),
      );
    }
  }

  // -- Plasma Dragon --
  void _doFlameBreath(BossAttack attack) {
    // Sweeping beam of fire
    // Simulate with many bullets in an arc
    double startAngle = pi / 4;
    double endAngle = 3 * pi / 4;
    int count = attack.projectileCount;
    for (int i = 0; i < count; i++) {
      double t = i / (count - 1);
      double angle = startAngle + (endAngle - startAngle) * t;
      _fireBullet(
        Vector2(cos(angle), sin(angle)) * attack.speed,
        color: Colors.orange,
        bulletSize: Vector2(15, 15),
      );
    }
  }

  void _doWingGust(BossAttack attack) {
    // Push back all entities
    _applyWindForce(Vector2(-100, 0), duration: 2.0);
    game.screenEffects.triggerShake(duration: 0.5, intensity: 10);
  }

  void _doMeteorSummon(BossAttack attack) {
    // Rain from top
    final rng = Random();
    for (int i = 0; i < attack.projectileCount; i++) {
      _fireBullet(
        Vector2(-50, 200 + rng.nextDouble() * 100),
        startPos: Vector2(rng.nextDouble() * game.size.x, -50),
        color: Colors.deepOrange,
        bulletSize: Vector2(30, 30),
      );
    }
  }

  void _doDragonDive(BossAttack attack) {
    _doChargeRush();
  }

  void _doSupernova(BossAttack attack) {
    _doScreenWipe(attack);
  }

  // -- Cosmic Eye --
  void _doDeathStare(BossAttack attack) {
    _doLaserSweep(attack);
  }

  void _doVisionBlast(BossAttack attack) {
    // Huge cone blast
    double centerAngle = (game.player.position - position).angleTo(Vector2(1, 0)); // Angle to player
    // Actually angleTo returns angle between vectors. 
    Vector2 dirToPlayer = game.player.position - position;
    double angle = atan2(dirToPlayer.y, dirToPlayer.x);
    
    int rays = 10;
    for (int i = -rays ~/ 2; i <= rays ~/ 2; i++) {
      double a = angle + i * 0.1; // Cone spread
      _fireBullet(
        Vector2(cos(a), sin(a)) * attack.speed,
        color: Colors.purpleAccent,
        bulletSize: Vector2(10, 10),
      );
    }
  }

  void _doHypnoticPulse(BossAttack attack) {
     _doDebuff(); // Reusing control inversion
  }

  // -- Arachnid Queen --
  void _doWebTrap(BossAttack attack) {
    // Projectile that freezes player on hit
    Vector2 dir = (game.player.position - position).normalized();
    // We need a way to mark this bullet as "web"
    // For now, use generic bullet but we can't easily add custom logic without BossBullet refactor
    // Let's rely on standard collision damage, maybe player slows down when taking damage from this boss?
    // Or just fire a targeted shot that is fast
    _fireBullet(dir * attack.speed, color: Colors.white, bulletSize: Vector2(15,15));
  }

  void _doLegSlam(BossAttack attack) {
    _doGroundPound(attack);
  }

  void _doPoisonBite(BossAttack attack) {
    _doChargeRush();
  }

  void _doWebCocoon(BossAttack attack) {
    // AoE slow/freeze
    game.player.applyFreeze(2.0); // Reusing freeze mechanics
  }
  
  // -- Magma Behemoth --
  void _doLavaPool(BossAttack attack) {
    _doSummonHazards(attack);
  }

  void _doMoltenFists(BossAttack attack) {
    _doGroundPound(attack);
  }

  void _doVolcanicEruption(BossAttack attack) {
    _doScreenWipe(attack); // Massive damage/shake
  }

  // -- Eclipse Phantom --
  void _doEclipseBeam(BossAttack attack) {
    // Charge then fire massive beam
    // Visuals only for now, mechanically a laser sweep with delay
    // We can simulate delay by firing a very slow projectile first? 
    // Or just use laser sweep
    _doLaserSweep(attack);
  }

  // Helper for wind/push force
  void _applyWindForce(Vector2 force, {required double duration}) {
     // Apply to player velocity or position directly over time
     // Since update loop handles movement, we can just nudge position here for instant effect
     // or set a flag. Let's do instant impulse for simplicity this turn
     // Ideally needs a 'wind' vector in player.
     // For now, instant push + shake
     game.player.position += force * 0.5; 
  }

  void _renderAiDreadnoughtHp(Canvas canvas, double w, double h, Offset center) {
    final hp = _hpPercent;
    final isPhase = hp <= 0.5;
    final isRage = hp <= 0.2;
    final flash = damageFlashTimer > 0 ? (0.35 + 0.65 * (sin(time * 55).abs())) : 1.0;

    const segments = 10;
    final aliveSegments = (hp * segments).ceil().clamp(0, segments);

    final outer = w * 0.48;
    final plateW = outer * 0.22;
    final plateH = 6.0;

    for (int i = 0; i < segments; i++) {
      if (i >= aliveSegments) continue;
      final ang = (i / segments) * pi * 2 + time * 0.25;
      final dx = cos(ang) * outer;
      final dy = sin(ang) * outer;

      canvas.save();
      canvas.translate(center.dx + dx, center.dy + dy);
      canvas.rotate(ang);

      final t = i / (segments - 1);
      final base = isRage ? const Color(0xFFDC2626) : const Color(0xFF00D9FF);
      final col = Color.lerp(base, Colors.white, isPhase ? 0.15 : 0.05)!
          .withValues(alpha: (0.75 * flash).clamp(0.0, 1.0));
      final paint = Paint()
        ..color = col
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: plateW, height: plateH),
          const Radius.circular(4),
        ),
        paint,
      );
      canvas.restore();
    }

    if (damageFlashTimer > 0) {
      final sparkPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.8)
        ..strokeWidth = 1.8;
      for (int i = 0; i < 6; i++) {
        final ang = (i / 6) * pi * 2 + time * 8;
        final p1 = Offset(center.dx + cos(ang) * (w * 0.18), center.dy + sin(ang) * (w * 0.18));
        final p2 = Offset(center.dx + cos(ang) * (w * 0.28), center.dy + sin(ang) * (w * 0.28));
        canvas.drawLine(p1, p2, sparkPaint);
      }
    }
  }

  void _renderThunderLeviathanHp(Canvas canvas, double w, double h, Offset center) {
    final hp = _hpPercent;
    final isPhase = hp <= 0.5;
    final isRage = hp <= 0.2;
    final flash = damageFlashTimer > 0 ? (0.35 + 0.65 * (sin(time * 60).abs())) : 1.0;

    final radius = w * 0.43;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawArc(rect, -pi / 2, pi * 2, false, bgPaint);

    final col = isPhase ? const Color(0xFFFFFFFF) : const Color(0xFFFBBF24);
    final hpPaint = Paint()
      ..color = (isRage ? const Color(0xFF60A5FA) : col).withValues(alpha: (0.9 * flash).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final sweep = (pi * 2 * hp).clamp(0.05, pi * 2);
    canvas.drawArc(rect, -pi / 2 + sin(time * 2) * 0.08, sweep, false, hpPaint);

    if (isRage) {
      final crackle = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35)
        ..strokeWidth = 1.2;
      for (int i = 0; i < 10; i++) {
        final a = Random(i).nextDouble() * pi * 2 + time * 3;
        final p1 = Offset(center.dx + cos(a) * (radius - 6), center.dy + sin(a) * (radius - 6));
        final p2 = Offset(center.dx + cos(a) * (radius + 10), center.dy + sin(a) * (radius + 10));
        canvas.drawLine(p1, p2, crackle);
      }
    }
  }

  void _renderCryoColossusHp(Canvas canvas, double w, double h, Offset center) {
    final hp = _hpPercent;
    final isPhase = hp <= 0.5;
    final isRage = hp <= 0.2;
    final flash = damageFlashTimer > 0 ? (0.35 + 0.65 * (sin(time * 45).abs())) : 1.0;

    final radius = w * 0.46;
    final thickness = (3.0 + hp * 8.0);
    final iceColor = isRage ? const Color(0xFF93C5FD) : const Color(0xFF06B6D4);

    final shellPaint = Paint()
      ..color = iceColor.withValues(alpha: (0.45 * flash).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    _drawShape(canvas, center, radius, config.shape, shellPaint);

    if (hp <= 0.55) {
      final crackCount = (3 + ((1.0 - hp) * 10).floor()).clamp(3, 14);
      final crackPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1.2;
      for (int i = 0; i < crackCount; i++) {
        final ang = (i / crackCount) * pi * 2 + sin(time * 3 + i) * 0.2;
        final p1 = Offset(center.dx + cos(ang) * (radius * 0.55), center.dy + sin(ang) * (radius * 0.55));
        final p2 = Offset(center.dx + cos(ang) * (radius * 1.02), center.dy + sin(ang) * (radius * 1.02));
        canvas.drawLine(p1, p2, crackPaint);
      }
    }

    if (damageFlashTimer > 0) {
      final shardPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < 5; i++) {
        final ang = (i / 5) * pi * 2 + time * 6;
        final p = Offset(center.dx + cos(ang) * (radius * 0.85), center.dy + sin(ang) * (radius * 0.85));
        canvas.drawCircle(p, 2.2, shardPaint);
      }
    }
  }

  void _renderBossBody(Canvas canvas, double w, double h, Offset center, {double alpha = 1.0}) {
    // Dispatch to boss-specific rendering
    switch (config.id) {
      // Tier 1
      case 'solar_titan':
        _renderSolarTitanBody(canvas, w, h, center, alpha);
        return;
      case 'void_devourer':
        _renderVoidDevourerBody(canvas, w, h, center, alpha);
        return;
      case 'ai_dreadnought':
        _renderAiDreadnoughtBody(canvas, w, h, center, alpha);
        return;
      case 'thunder_leviathan':
        _renderThunderLeviathanBody(canvas, w, h, center, alpha);
        return;
      case 'cryo_colossus':
        _renderCryoColossusBody(canvas, w, h, center, alpha);
        return;
        
      // Tier 2
      case 'tempest_titan':
        _renderTempestTitanBody(canvas, w, h, center, alpha);
        return;
      case 'scorpion_mech':
        _renderScorpionMechBody(canvas, w, h, center, alpha);
        return;
      case 'plasma_dragon':
        _renderPlasmaDragonBody(canvas, w, h, center, alpha);
        return;
      case 'cosmic_eye':
        _renderCosmicEyeBody(canvas, w, h, center, alpha);
        return;
      case 'arachnid_queen':
        _renderArachnidQueenBody(canvas, w, h, center, alpha);
        return;
      case 'magma_behemoth':
        _renderMagmaBehemothBody(canvas, w, h, center, alpha);
        return;
      case 'eclipse_phantom':
        _renderEclipsePhantomBody(canvas, w, h, center, alpha);
        return;

      // Tier 3
      case 'hive_mind_mothership':
        _renderHiveMindMothershipBody(canvas, w, h, center, alpha);
        return;
      case 'quantum_anomaly':
        _renderQuantumAnomalyBody(canvas, w, h, center, alpha);
        return;
      case 'phoenix_sovereign':
        _renderPhoenixSovereignBody(canvas, w, h, center, alpha);
        return;
      case 'leviathan_titan':
        _renderLeviathanTitanBody(canvas, w, h, center, alpha);
        return;
      case 'ancient_golem':
        _renderAncientGolemBody(canvas, w, h, center, alpha);
        return;
      case 'vampire_lord':
        _renderVampireLordBody(canvas, w, h, center, alpha);
        return;
      case 'alpha_predator':
        _renderAlphaPredatorBody(canvas, w, h, center, alpha);
        return;
      case 'poseidons_wrath':
        _renderPoseidonsWrathBody(canvas, w, h, center, alpha);
        return;

      // Tier 4
      case 'death_incarnate':
        _renderDeathIncarnateBody(canvas, w, h, center, alpha);
        return;
      case 'celestial_guardian':
        _renderCelestialGuardianBody(canvas, w, h, center, alpha);
        return;
      case 'abyssal_horror':
        _renderAbyssalHorrorBody(canvas, w, h, center, alpha);
        return;
      case 'chaos_jester':
        _renderChaosJesterBody(canvas, w, h, center, alpha);
        return;
      case 'genesis_core':
        _renderGenesisCoreBody(canvas, w, h, center, alpha);
        return;
      case 'galaxy_eater':
        _renderGalaxyEaterBody(canvas, w, h, center, alpha);
        return;
      case 'war_machine_omega':
        _renderWarMachineOmegaBody(canvas, w, h, center, alpha);
        return;
      case 'titan_fusion':
        _renderTitanFusionBody(canvas, w, h, center, alpha);
        return;

      // Tier 5
      case 'world_ender':
        _renderWorldEnderBody(canvas, w, h, center, alpha);
        return;
      case 'the_infinite':
        _renderTheInfiniteBody(canvas, w, h, center, alpha);
        return;
    }

    // Generic fallback
    _renderGenericBossBody(canvas, w, h, center, alpha);
  }

  void _renderGenericBossBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    final glowPaint = Paint()
      ..color = config.glowColor.withValues(alpha: 0.3 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    _drawShape(canvas, center, w * 0.45, config.shape, glowPaint);

    final bodyPaint = Paint()
      ..shader = RadialGradient(colors: [
        config.color.withValues(alpha: 0.9 * alpha),
        config.glowColor.withValues(alpha: 0.6 * alpha),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: center, radius: w * 0.4));
    _drawShape(canvas, center, w * 0.38, config.shape, bodyPaint);

    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    _drawShape(canvas, center, w * 0.12, config.shape, corePaint);

    final particlePaint = Paint()..color = config.color.withValues(alpha: 0.6 * alpha);
    for (int i = 0; i < 6; i++) {
      final angle = time * 1.5 + i * (pi / 3);
      final radius = w * 0.3 + sin(time * 2 + i) * 5;
      canvas.drawCircle(Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius), 3, particlePaint);
    }

    if (config.phases.length > 1) {
      for (int i = 0; i < config.phases.length; i++) {
        final pipColor = i <= currentPhaseIndex
            ? config.color.withValues(alpha: alpha) : Colors.grey.withValues(alpha: 0.3 * alpha);
        canvas.drawCircle(
          Offset(center.dx - (config.phases.length - 1) * 5 + i * 10, h - 5), 3,
          Paint()..color = pipColor,
        );
      }
    }

    if (config.tier >= 4) {
      final ringPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.2 * alpha + sin(time * 3) * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      _drawShape(canvas, center, w * 0.48, config.shape, ringPaint);
    }
  }

  // ═══════════════════════════════════════
  //  TIER 2 BOSS-SPECIFIC BODIES
  // ═══════════════════════════════════════

  void _renderTempestTitanBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Swirling storm entity
    final cloudPaint = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF60A5FA).withValues(alpha: 0.8 * alpha),
        const Color(0xFF1E3A8A).withValues(alpha: 0.6 * alpha),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: center, radius: w * 0.5));
    
    // Draw multiple rotating cloud layers
    for (int i = 0; i < 3; i++) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(time * (0.5 + i * 0.2));
        final path = Path();
        for (int j = 0; j < 5; j++) {
            final angle = (j * 72) * pi / 180;
            final r = w * (0.3 + i * 0.1);
            final x = cos(angle) * r;
            final y = sin(angle) * r;
            canvas.drawCircle(Offset(x, y), w * 0.15, cloudPaint);
        }
        canvas.restore();
    }
    
    // Lightning details
    if (Random().nextDouble() > 0.8) {
        final boltPaint = Paint()..color = Colors.white.withValues(alpha: 0.8 * alpha)..strokeWidth = 2..style = PaintingStyle.stroke;
        final start = Offset(center.dx + (Random().nextDouble() - 0.5) * w * 0.4, center.dy + (Random().nextDouble() - 0.5) * w * 0.4);
        final end = Offset(start.dx + (Random().nextDouble() - 0.5) * 30, start.dy + 30);
        canvas.drawLine(start, end, boltPaint);
    }

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderScorpionMechBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Metallic scorpion
    final paint = Paint()..color = const Color(0xFF1F2937).withValues(alpha: alpha);
    final glow = Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.5 * alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Body segments
    for (int i = 0; i < 3; i++) {
        final r = w * (0.2 + i * 0.1);
        canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy - i * 15), width: r * 1.5, height: r), paint);
    }
    
    // Tail
    final tailPaint = Paint()..color = const Color(0xFF374151).withValues(alpha: alpha)..strokeWidth = 8..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(center.dx, center.dy - 30);
    path.quadraticBezierTo(center.dx, center.dy - 80, center.dx + 40, center.dy - 60);
    path.quadraticBezierTo(center.dx + 60, center.dy - 40, center.dx + 50, center.dy - 20);
    canvas.drawPath(path, tailPaint);
    
    // Stinger
    canvas.drawCircle(Offset(center.dx + 50, center.dy - 20), 8, Paint()..color = Colors.greenAccent.withValues(alpha: alpha));

    // Claws
    canvas.drawArc(Rect.fromCenter(center: Offset(center.dx-40, center.dy+30), width: 30, height: 40), 0, pi*1.5, true, paint);
    canvas.drawArc(Rect.fromCenter(center: Offset(center.dx+40, center.dy+30), width: 30, height: 40), -pi*0.5, pi*1.5, true, paint);

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderPlasmaDragonBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Dragon head and wings
    final paint = Paint()..color = const Color(0xFF1A0A2E).withValues(alpha: alpha);
    final plasma = Paint()..color = const Color(0xFFFF3D00).withValues(alpha: 0.7 * alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    // Wings
    final wingPath = Path();
    wingPath.moveTo(center.dx, center.dy);
    wingPath.lineTo(center.dx - w*0.6, center.dy - h*0.3);
    wingPath.quadraticBezierTo(center.dx - w*0.4, center.dy, center.dx - w*0.5, center.dy + h*0.2);
    wingPath.lineTo(center.dx, center.dy + h*0.1);
    wingPath.lineTo(center.dx + w*0.6, center.dy - h*0.3);
    wingPath.quadraticBezierTo(center.dx + w*0.4, center.dy, center.dx + w*0.5, center.dy + h*0.2);
    wingPath.close();
    canvas.drawPath(wingPath, paint);
    
    // Glowing veins
    canvas.drawPath(wingPath, Paint()..color = const Color(0xFFFF3D00).withValues(alpha: 0.3 * alpha)..style=PaintingStyle.stroke..strokeWidth=2);

    // Head
    canvas.drawOval(Rect.fromCenter(center: center, width: w*0.2, height: h*0.3), paint);
    // Glowing throat
    canvas.drawCircle(center, w*0.08, plasma);

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderCosmicEyeBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Giant eye
    final sclera = Paint()..color = Colors.white.withValues(alpha: alpha);
    final iris = Paint()..shader = RadialGradient(colors: [Colors.purple, Colors.black]).createShader(Rect.fromCircle(center: center, radius: w*0.25));
    final pupil = Paint()..color = Colors.black.withValues(alpha: alpha);
    
    // Eye shape
    final path = Path();
    path.moveTo(center.dx - w*0.45, center.dy);
    path.quadraticBezierTo(center.dx, center.dy - h*0.35, center.dx + w*0.45, center.dy);
    path.quadraticBezierTo(center.dx, center.dy + h*0.35, center.dx - w*0.45, center.dy);
    path.close();
    
    canvas.drawPath(path, sclera);
    canvas.drawCircle(center, w*0.18, iris);
    canvas.drawCircle(center, w*0.08, pupil);
    
    // Veins/Eldritch markings
    final veinPaint = Paint()..color = Colors.purple.withValues(alpha: 0.3 * alpha)..style=PaintingStyle.stroke..strokeWidth=1;
    canvas.drawPath(path, Paint()..color = Colors.purple.withValues(alpha: 0.5 * alpha)..style=PaintingStyle.stroke..strokeWidth=3);

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderArachnidQueenBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Spider body
    final paint = Paint()..color = const Color(0xFF111827).withValues(alpha: alpha);
    final markings = Paint()..color = const Color(0xFF22C55E).withValues(alpha: alpha);

    // Abdomen
    canvas.drawCircle(Offset(center.dx, center.dy - h*0.1), w*0.3, paint);
    // Cephalothorax
    canvas.drawCircle(Offset(center.dx, center.dy + h*0.2), w*0.2, paint);
    
    // Legs (8)
    final legPaint = Paint()..color = const Color(0xFF111827).withValues(alpha: alpha)..strokeWidth=4..style=PaintingStyle.stroke;
    for(int i=0; i<4; i++) {
        // Left
        canvas.drawLine(Offset(center.dx, center.dy+h*0.2), Offset(center.dx - w*0.5, center.dy + h*0.2 - (i-1.5)*20), legPaint);
        // Right
        canvas.drawLine(Offset(center.dx, center.dy+h*0.2), Offset(center.dx + w*0.5, center.dy + h*0.2 - (i-1.5)*20), legPaint);
    }
    
    // Glowing markings
    canvas.drawCircle(Offset(center.dx, center.dy - h*0.1), w*0.1, markings);
    
    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderMagmaBehemothBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Rock golem with lava cracks
    final rockPaint = Paint()..color = const Color(0xFF4B5563).withValues(alpha: alpha);
    final lavaPaint = Paint()..color = const Color(0xFFFF6B35).withValues(alpha: alpha)..strokeWidth=2..style=PaintingStyle.stroke;

    // Body (bulky)
    canvas.drawRect(Rect.fromCenter(center: center, width: w*0.6, height: h*0.7), rockPaint);
    // Head
    canvas.drawRect(Rect.fromCenter(center: Offset(center.dx, center.dy-h*0.4), width: w*0.3, height: h*0.2), rockPaint);
    
    // Cracks
    canvas.drawLine(Offset(center.dx-w*0.2, center.dy-h*0.2), Offset(center.dx+w*0.2, center.dy+h*0.2), lavaPaint);
    canvas.drawLine(Offset(center.dx+w*0.2, center.dy-h*0.2), Offset(center.dx-w*0.2, center.dy+h*0.2), lavaPaint);
    
    // Eyes
    canvas.drawCircle(Offset(center.dx-10, center.dy-h*0.4), 4, Paint()..color=Colors.orangeAccent);
    canvas.drawCircle(Offset(center.dx+10, center.dy-h*0.4), 4, Paint()..color=Colors.orangeAccent);

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderEclipsePhantomBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Shadowy figure
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.8 * alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final corePaint = Paint()..color = const Color(0xFF1F2937).withValues(alpha: alpha);

    // Hood/Cloak shape
    final path = Path();
    path.moveTo(center.dx, center.dy - h*0.5);
    path.lineTo(center.dx - w*0.3, center.dy + h*0.5);
    path.lineTo(center.dx + w*0.3, center.dy + h*0.5);
    path.close();
    
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, corePaint);
    
    // Glowing eyes
    final eyePaint = Paint()..color = const Color(0xFFA855F7).withValues(alpha: alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(center.dx - 10, center.dy - h*0.2), 4, eyePaint);
    canvas.drawCircle(Offset(center.dx + 10, center.dy - h*0.2), 4, eyePaint);

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  // ═══════════════════════════════════════
  //  TIER 3 BOSS-SPECIFIC BODIES
  // ═══════════════════════════════════════

  void _renderHiveMindMothershipBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Bio-mechanical ship
    final hullPaint = Paint()..color = const Color(0xFF064E3B).withValues(alpha: alpha);
    final glowPaint = Paint()..color = const Color(0xFF4ADE80).withValues(alpha: 0.6 * alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    // Main Hull
    final path = Path();
    path.moveTo(center.dx, center.dy + h*0.4);
    path.quadraticBezierTo(center.dx - w*0.6, center.dy - h*0.2, center.dx, center.dy - h*0.5);
    path.quadraticBezierTo(center.dx + w*0.6, center.dy - h*0.2, center.dx, center.dy + h*0.4);
    path.close();
    canvas.drawPath(path, hullPaint);
    
    // Pulsing nodes
    canvas.drawCircle(Offset(center.dx - w*0.3, center.dy - h*0.1), w*0.08, glowPaint);
    canvas.drawCircle(Offset(center.dx + w*0.3, center.dy - h*0.1), w*0.08, glowPaint);
    canvas.drawCircle(Offset(center.dx, center.dy), w*0.15, glowPaint);
    
    // Hanging tendrils
    final tendrilPaint = Paint()..color = const Color(0xFF065F46).withValues(alpha: alpha)..style=PaintingStyle.stroke..strokeWidth=3;
    for(int i=0; i<5; i++) {
        final x = center.dx + (i-2)*20 + sin(time*3 + i)*5;
        canvas.drawLine(Offset(x, center.dy+h*0.2), Offset(x, center.dy+h*0.5), tendrilPaint);
    }

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderQuantumAnomalyBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Glitching shapes
    final shapes = [BossShape.circle, BossShape.sharp, BossShape.tech];
    final shape = shapes[(time * 2).floor() % shapes.length];
    
    final paint = Paint()
      ..shader = RadialGradient(colors: [Colors.white, const Color(0xFFA78BFA)]).createShader(Rect.fromCircle(center: center, radius: w*0.4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    // Draw multiple overlapping ghost shapes
    for(int i=0; i<3; i++) {
        final offset = Offset((Random().nextDouble()-0.5)*10, (Random().nextDouble()-0.5)*10);
        canvas.save();
        canvas.translate(offset.dx, offset.dy);
        _drawShape(canvas, center, w*0.4, shape, paint..color = const Color(0xFFA78BFA).withValues(alpha: 0.3 * alpha));
        canvas.restore();
    }
    
    _drawShape(canvas, center, w*0.4, shape, Paint()..color = Colors.white.withValues(alpha: 0.8 * alpha));

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderPhoenixSovereignBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Fire bird
    final fireColors = [Colors.red, Colors.orange, Colors.yellow];
    
    // Wings
    for (int i=0; i<2; i++) {
        final sign = i==0 ? -1 : 1;
        final wingPath = Path();
        wingPath.moveTo(center.dx, center.dy);
        wingPath.quadraticBezierTo(center.dx + sign*w*0.8, center.dy - h*0.5, center.dx + sign*w*0.6, center.dy + h*0.2);
        wingPath.close();
        canvas.drawPath(wingPath, Paint()..shader = LinearGradient(colors: fireColors).createShader(Rect.fromLTWH(center.dx-w, center.dy-h, w*2, h*2)));
    }
    
    // Body
    canvas.drawCircle(center, w*0.15, Paint()..color = Colors.white.withValues(alpha: alpha));
    
    // Aura
    canvas.drawCircle(center, w*0.5, Paint()..color = Colors.orange.withValues(alpha: 0.2 * alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderLeviathanTitanBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Sea serpent
    final scalePaint = Paint()..color = const Color(0xFF0EA5E9).withValues(alpha: alpha);
    final finPaint = Paint()..color = const Color(0xFF0284C7).withValues(alpha: alpha);
    
    // Body coils
    for (int i=0; i<5; i++) {
        final x = center.dx + sin(time + i)*30;
        final y = center.dy - h*0.4 + i*25;
        canvas.drawCircle(Offset(x, y), w*0.25 - i*3, scalePaint);
    }
    
    // Head
    canvas.drawOval(Rect.fromCenter(center: center, width: w*0.4, height: h*0.5), scalePaint);
    
    // Glowing eyes/mouth
    canvas.drawCircle(Offset(center.dx-15, center.dy-10), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx+15, center.dy-10), 5, Paint()..color = Colors.white);

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderAncientGolemBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Stone giant
    final stonePaint = Paint()..color = const Color(0xFF57534E).withValues(alpha: alpha);
    final runePaint = Paint()..color = const Color(0xFFFACC15).withValues(alpha: 0.8 * alpha)..style=PaintingStyle.stroke..strokeWidth=2;
    
    // Blocks
    canvas.drawRect(Rect.fromCenter(center: center, width: w*0.7, height: h*0.7), stonePaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(center.dx, center.dy-h*0.45), width: w*0.4, height: h*0.3), stonePaint);
    
    // Runes
    canvas.drawCircle(center, w*0.2, runePaint);
    canvas.drawLine(Offset(center.dx-w*0.2, center.dy), Offset(center.dx+w*0.2, center.dy), runePaint);
    canvas.drawLine(Offset(center.dx, center.dy-h*0.2), Offset(center.dx, center.dy+h*0.2), runePaint);

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderVampireLordBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Aristocrat
    final capePaint = Paint()..color = const Color(0xFF7F1D1D).withValues(alpha: alpha);
    final suitPaint = Paint()..color = Colors.black.withValues(alpha: alpha);
    
    // Cape
    final path = Path();
    path.moveTo(center.dx, center.dy - h*0.4);
    path.lineTo(center.dx - w*0.4, center.dy + h*0.5);
    path.lineTo(center.dx + w*0.4, center.dy + h*0.5);
    path.close();
    canvas.drawPath(path, capePaint);
    
    // Body
    canvas.drawRect(Rect.fromCenter(center: center, width: w*0.25, height: h*0.6), suitPaint);
    
    // Head/Pale face
    canvas.drawCircle(Offset(center.dx, center.dy - h*0.35), w*0.12, Paint()..color = Colors.grey[200]!);
    
    // Red Eyes
    canvas.drawCircle(Offset(center.dx-5, center.dy - h*0.35), 3, Paint()..color = Colors.red);
    canvas.drawCircle(Offset(center.dx+5, center.dy - h*0.35), 3, Paint()..color = Colors.red);

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderAlphaPredatorBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Wolf
    final furPaint = Paint()..color = const Color(0xFF3F3F46).withValues(alpha: alpha);
    final markPaint = Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.8 * alpha)..style=PaintingStyle.stroke..strokeWidth=2;
    
    // Head shape
    final path = Path();
    path.moveTo(center.dx, center.dy + h*0.4); // Chin
    path.lineTo(center.dx - w*0.35, center.dy - h*0.2); // Left ear base
    path.lineTo(center.dx - w*0.4, center.dy - h*0.5); // Left ear tip
    path.lineTo(center.dx - w*0.1, center.dy - h*0.3); // Head top
    path.lineTo(center.dx + w*0.1, center.dy - h*0.3);
    path.lineTo(center.dx + w*0.4, center.dy - h*0.5); // Right ear tip
    path.lineTo(center.dx + w*0.35, center.dy - h*0.2); // Right ear base
    path.close();
    canvas.drawPath(path, furPaint);
    
    // Markings
    canvas.drawLine(Offset(center.dx - w*0.2, center.dy), Offset(center.dx - w*0.1, center.dy - h*0.1), markPaint);
    canvas.drawLine(Offset(center.dx + w*0.2, center.dy), Offset(center.dx + w*0.1, center.dy - h*0.1), markPaint);
    
    // Eyes
    canvas.drawCircle(Offset(center.dx - w*0.15, center.dy - h*0.15), 5, Paint()..color = const Color(0xFF3B82F6));
    canvas.drawCircle(Offset(center.dx + w*0.15, center.dy - h*0.15), 5, Paint()..color = const Color(0xFF3B82F6));

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderPoseidonsWrathBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Water Titan
    final bodyPaint = Paint()..shader = RadialGradient(colors: [const Color(0xFF0EA5E9), const Color(0xFF1E3A8A)]).createShader(Rect.fromCircle(center: center, radius: w*0.5));
    
    // Torso
    canvas.drawRect(Rect.fromCenter(center: center, width: w*0.5, height: h*0.6), bodyPaint);
    // Head/Beard
    canvas.drawCircle(Offset(center.dx, center.dy - h*0.4), w*0.15, Paint()..color = Colors.blueGrey);
    
    // Trident (simple representation)
    final tridentPaint = Paint()..color = const Color(0xFFFFD700)..strokeWidth=4;
    canvas.drawLine(Offset(center.dx + w*0.4, center.dy - h*0.5), Offset(center.dx + w*0.4, center.dy + h*0.5), tridentPaint);
    // Fork
    canvas.drawLine(Offset(center.dx + w*0.3, center.dy - h*0.4), Offset(center.dx + w*0.5, center.dy - h*0.4), tridentPaint);
    
    _renderPhasePips(canvas, center, w, h, alpha);
  }

  // ═══════════════════════════════════════
  //  TIER 1 BOSS-SPECIFIC BODIES

  // ═══════════════════════════════════════

  void _renderSolarTitanBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Fiery humanoid with radiant core
    // Outer corona glow
    final coronaPaint = Paint()
      ..color = const Color(0xFFFF8C00).withValues(alpha: 0.25 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, w * 0.55, coronaPaint);

    // Solar body - pulsing sun
    final bodyPulse = 1.0 + sin(time * 3) * 0.05;
    final bodyPaint = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFFFFFFF).withValues(alpha: 0.8 * alpha),
        const Color(0xFFFFD700).withValues(alpha: 0.9 * alpha),
        const Color(0xFFFF6B00).withValues(alpha: 0.7 * alpha),
        const Color(0xFFFF4500).withValues(alpha: 0.3 * alpha),
      ]).createShader(Rect.fromCircle(center: center, radius: w * 0.4 * bodyPulse));
    canvas.drawCircle(center, w * 0.38 * bodyPulse, bodyPaint);

    // Solar flare tendrils
    final flarePaint = Paint()
      ..color = const Color(0xFFFF6B00).withValues(alpha: 0.6 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (int i = 0; i < 8; i++) {
      final angle = time * 0.8 + i * (pi / 4);
      final len = w * 0.3 + sin(time * 4 + i * 2) * w * 0.1;
      final p1 = Offset(center.dx + cos(angle) * w * 0.3, center.dy + sin(angle) * w * 0.3);
      final p2 = Offset(center.dx + cos(angle + 0.2) * len, center.dy + sin(angle + 0.2) * len);
      canvas.drawLine(p1, p2, flarePaint);
    }

    // Bright white core
    canvas.drawCircle(center, w * 0.1, Paint()
      ..color = Colors.white.withValues(alpha: 0.9 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderVoidDevourerBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Dark amorphous mass with glowing purple core
    // Dark void aura
    final auraPaint = Paint()
      ..color = const Color(0xFF1A0A2E).withValues(alpha: 0.5 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(center, w * 0.55, auraPaint);

    // Wobbly dark body
    final bodyPath = Path();
    for (int i = 0; i <= 360; i += 8) {
      final angle = i * pi / 180;
      final wobble = w * 0.38 + sin(i * 0.15 + time * 5) * w * 0.06;
      final x = center.dx + cos(angle) * wobble;
      final y = center.dy + sin(angle) * wobble;
      if (i == 0) bodyPath.moveTo(x, y);
      else bodyPath.lineTo(x, y);
    }
    bodyPath.close();
    canvas.drawPath(bodyPath, Paint()
      ..color = const Color(0xFF1A0533).withValues(alpha: 0.9 * alpha));

    // Purple energy core
    final corePaint = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFE040FB).withValues(alpha: 0.8 * alpha),
        const Color(0xFF8B5CF6).withValues(alpha: 0.5 * alpha),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: center, radius: w * 0.2));
    canvas.drawCircle(center, w * 0.15, corePaint);

    // Tentacle tips (glowing dots at edges)
    for (int i = 0; i < 6; i++) {
      final angle = time * 1.2 + i * (pi / 3);
      final r = w * 0.4 + sin(time * 3 + i) * w * 0.05;
      final tipPaint = Paint()
        ..color = const Color(0xFFA855F7).withValues(alpha: 0.7 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r), 4, tipPaint);
    }

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderAiDreadnoughtBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Metallic warship with angular panels
    // Tech body - cut-corner rectangle
    final r = w * 0.4;
    final c = r * 0.3;
    final bodyPath = Path()
      ..moveTo(center.dx - r + c, center.dy - r)
      ..lineTo(center.dx + r - c, center.dy - r)
      ..lineTo(center.dx + r, center.dy - r + c)
      ..lineTo(center.dx + r, center.dy + r - c)
      ..lineTo(center.dx + r - c, center.dy + r)
      ..lineTo(center.dx - r + c, center.dy + r)
      ..lineTo(center.dx - r, center.dy + r - c)
      ..lineTo(center.dx - r, center.dy - r + c)
      ..close();

    // Dark metallic fill
    canvas.drawPath(bodyPath, Paint()
      ..color = const Color(0xFF1F2937).withOpacity(0.95 * alpha));

    // Cyan edge glow
    canvas.drawPath(bodyPath, Paint()
      ..color = const Color(0xFF00D9FF).withOpacity(0.5 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Panel lines
    final panelPaint = Paint()
      ..color = const Color(0xFF374151).withOpacity(0.6 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx, center.dy - r + 5), Offset(center.dx, center.dy + r - 5), panelPaint);
    canvas.drawLine(Offset(center.dx - r + 5, center.dy), Offset(center.dx + r - 5, center.dy), panelPaint);

    // Blinking red lights
    final blinkOn = ((time * 2).floor() % 2) == 0;
    if (blinkOn) {
      final lightPaint = Paint()
        ..color = const Color(0xFFEF4444).withOpacity(0.9 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(center.dx - r * 0.5, center.dy - r * 0.5), 3, lightPaint);
      canvas.drawCircle(Offset(center.dx + r * 0.5, center.dy - r * 0.5), 3, lightPaint);
    }

    // Cyan core
    canvas.drawCircle(center, w * 0.08, Paint()
      ..color = const Color(0xFF00D9FF).withOpacity(0.8 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderThunderLeviathanBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Serpent silhouette with storm clouds
    // Storm cloud backdrop
    final cloudPaint = Paint()
      ..color = const Color(0xFF374151).withOpacity(0.4 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy - 5), width: w * 0.9, height: h * 0.5), cloudPaint);

    // Serpent body - star/spike shape
    final bodyPath = Path();
    final innerRadius = w * 0.2;
    final outerRadius = w * 0.42;
    for (int i = 0; i < 16; i++) {
      final angle = (i * 22.5) * pi / 180 + time * 0.3;
      final rad = (i.isEven) ? outerRadius : innerRadius;
      final x = center.dx + cos(angle) * rad;
      final y = center.dy + sin(angle) * rad;
      if (i == 0) bodyPath.moveTo(x, y);
      else bodyPath.lineTo(x, y);
    }
    bodyPath.close();
    canvas.drawPath(bodyPath, Paint()
      ..color = const Color(0xFF1F2937).withOpacity(0.9 * alpha));

    // Lightning streaks on body
    final boltPaint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.7 * alpha)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 4; i++) {
      final a = time * 3 + i * (pi / 2);
      final p1 = Offset(center.dx + cos(a) * w * 0.1, center.dy + sin(a) * w * 0.1);
      final p2 = Offset(center.dx + cos(a + 0.5) * w * 0.35, center.dy + sin(a + 0.5) * w * 0.35);
      canvas.drawLine(p1, p2, boltPaint);
    }

    // Glowing yellow eyes
    final eyePaint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.9 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(center.dx - w * 0.1, center.dy - h * 0.08), 4, eyePaint);
    canvas.drawCircle(Offset(center.dx + w * 0.1, center.dy - h * 0.08), 4, eyePaint);

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderCryoColossusBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Ice giant with crystalline armor
    // Frost aura
    final auraPaint = Paint()
      ..color = const Color(0xFF06B6D4).withOpacity(0.15 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, w * 0.55, auraPaint);

    // Hexagonal crystalline body
    final bodyPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * pi / 180 + time * 0.2;
      final x = center.dx + cos(angle) * w * 0.4;
      final y = center.dy + sin(angle) * w * 0.4;
      if (i == 0) bodyPath.moveTo(x, y);
      else bodyPath.lineTo(x, y);
    }
    bodyPath.close();

    // Ice blue fill
    canvas.drawPath(bodyPath, Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF67E8F9).withOpacity(0.8 * alpha),
        const Color(0xFF06B6D4).withOpacity(0.6 * alpha),
        const Color(0xFF164E63).withOpacity(0.4 * alpha),
      ]).createShader(Rect.fromCircle(center: center, radius: w * 0.4)));

    // Crystal edge glow
    canvas.drawPath(bodyPath, Paint()
      ..color = Colors.white.withOpacity(0.5 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Inner crystal lines
    final crystalPaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 3; i++) {
      final a1 = (i * 60) * pi / 180 + time * 0.2;
      final a2 = ((i + 3) * 60) * pi / 180 + time * 0.2;
      canvas.drawLine(
        Offset(center.dx + cos(a1) * w * 0.35, center.dy + sin(a1) * w * 0.35),
        Offset(center.dx + cos(a2) * w * 0.35, center.dy + sin(a2) * w * 0.35),
        crystalPaint,
      );
    }

    // Frost particles orbiting
    for (int i = 0; i < 8; i++) {
      final angle = time * 1.5 + i * (pi / 4);
      final r = w * 0.45 + sin(time * 2 + i) * 5;
      canvas.drawCircle(
        Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r),
        2, Paint()..color = Colors.white.withOpacity(0.5 * alpha),
      );
    }

    // Bright ice core
    canvas.drawCircle(center, w * 0.1, Paint()
      ..color = Colors.white.withOpacity(0.7 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderPhasePips(Canvas canvas, Offset center, double w, double h, double alpha) {
    if (config.phases.length > 1) {
      for (int i = 0; i < config.phases.length; i++) {
        final pipColor = i <= currentPhaseIndex
            ? config.color.withOpacity(alpha) : Colors.grey.withOpacity(0.3 * alpha);
        canvas.drawCircle(
          Offset(center.dx - (config.phases.length - 1) * 5 + i * 10, h - 5), 3,
          Paint()..color = pipColor,
        );
      }
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

  // ═══════════════════════════════════════
  //  TIER 4 BOSS-SPECIFIC BODIES
  // ═══════════════════════════════════════

  void _renderDeathIncarnateBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Grim Reaper
    final cloakPaint = Paint()..color = Colors.black.withOpacity(alpha);
    final bonePaint = Paint()..color = Colors.grey[300]!.withOpacity(alpha);
    final eyePaint = Paint()..color = const Color(0xFFEF4444).withOpacity(alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Cloak
    final path = Path();
    path.moveTo(center.dx, center.dy - h*0.5);
    path.quadraticBezierTo(center.dx - w*0.6, center.dy, center.dx - w*0.4, center.dy + h*0.5);
    path.lineTo(center.dx + w*0.4, center.dy + h*0.5);
    path.quadraticBezierTo(center.dx + w*0.6, center.dy, center.dx, center.dy - h*0.5);
    path.close();
    canvas.drawPath(path, cloakPaint);
    
    // Hood void
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy - h*0.3), width: w*0.25, height: h*0.3), Colors.black.withOpacity(alpha) as Paint);
    
    // Glowing red eyes
    canvas.drawCircle(Offset(center.dx - 8, center.dy - h*0.3), 4, eyePaint);
    canvas.drawCircle(Offset(center.dx + 8, center.dy - h*0.3), 4, eyePaint);
    
    // Scythe blade
    final scythePaint = Paint()..color = const Color(0xFF10B981).withOpacity(0.8 * alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final scythePath = Path();
    scythePath.moveTo(center.dx + w*0.4, center.dy - h*0.4);
    scythePath.quadraticBezierTo(center.dx + w*0.7, center.dy - h*0.5, center.dx + w*0.8, center.dy);
    scythePath.quadraticBezierTo(center.dx + w*0.5, center.dy - h*0.2, center.dx + w*0.4, center.dy - h*0.4);
    canvas.drawPath(scythePath, scythePaint);

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderCelestialGuardianBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Angel
    final armorPaint = Paint()..color = const Color(0xFFFFD700).withOpacity(alpha);
    final wingPaint = Paint()..color = Colors.white.withOpacity(0.8 * alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    // 6 Wings
    for (int i=0; i<3; i++) {
        // Left
        canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - w*0.4, center.dy - h*0.2 + i*30), width: w*0.5, height: h*0.15), wingPaint);
        // Right
        canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + w*0.4, center.dy - h*0.2 + i*30), width: w*0.5, height: h*0.15), wingPaint);
    }
    
    // Golden Armor Body
    canvas.drawRect(Rect.fromCenter(center: center, width: w*0.3, height: h*0.6), armorPaint);
    canvas.drawCircle(Offset(center.dx, center.dy - h*0.4), w*0.12, armorPaint);
    
    // Halo
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy - h*0.55), width: w*0.25, height: h*0.05), Paint()..color = Colors.white.withOpacity(alpha)..style = PaintingStyle.stroke..strokeWidth = 2);

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderAbyssalHorrorBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Eldritch mess
    final bodyPaint = Paint()..color = const Color(0xFF312E81).withOpacity(alpha);
    final voidPaint = Paint()..color = Colors.black.withOpacity(alpha);
    
    // Amorphous blob
    canvas.drawCircle(center, w*0.4, bodyPaint);
    
    // Holes/Void spots
    canvas.drawCircle(Offset(center.dx - w*0.2, center.dy - h*0.1), w*0.1, voidPaint);
    canvas.drawCircle(Offset(center.dx + w*0.15, center.dy + h*0.2), w*0.12, voidPaint);
    canvas.drawCircle(Offset(center.dx, center.dy), w*0.08, voidPaint);
    
    // Tentacles wiggling
    final tentaclePaint = Paint()..color = const Color(0xFF4C1D95).withOpacity(alpha)..style = PaintingStyle.stroke..strokeWidth = 6;
    for(int i=0; i<6; i++) {
        final angle = i * (pi/3) + time;
        final end = Offset(center.dx + cos(angle)*w*0.7, center.dy + sin(angle)*w*0.7);
        canvas.drawLine(center, end, tentaclePaint);
    }

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderChaosJesterBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Jester
    final leftPaint = Paint()..color = Colors.white.withOpacity(alpha);
    final rightPaint = Paint()..color = Colors.black.withOpacity(alpha);
    
    // Split face
    canvas.drawArc(Rect.fromCenter(center: center, width: w*0.4, height: w*0.4), pi/2, pi, true, leftPaint);
    canvas.drawArc(Rect.fromCenter(center: center, width: w*0.4, height: w*0.4), -pi/2, pi, true, rightPaint);
    
    // Hat
    canvas.drawPath(Path()..moveTo(center.dx, center.dy-h*0.2)..lineTo(center.dx-w*0.3, center.dy-h*0.6)..lineTo(center.dx, center.dy-h*0.3)..close(), leftPaint);
    canvas.drawPath(Path()..moveTo(center.dx, center.dy-h*0.2)..lineTo(center.dx+w*0.3, center.dy-h*0.6)..lineTo(center.dx, center.dy-h*0.3)..close(), rightPaint);
    
    // Eyes
    canvas.drawCircle(Offset(center.dx - w*0.1, center.dy - h*0.05), 5, Paint()..color = Colors.red); // Angry
    canvas.drawCircle(Offset(center.dx + w*0.1, center.dy - h*0.05), 5, Paint()..color = Colors.green); // Happy

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderGenesisCoreBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // DNA Sphere
    final corePaint = Paint()..color = const Color(0xFF10B981).withOpacity(alpha);
    final helixPaint = Paint()..color = const Color(0xFFFBBF24).withOpacity(0.8 * alpha)..style = PaintingStyle.stroke..strokeWidth = 3;
    
    canvas.drawCircle(center, w*0.4, corePaint);
    
    // Double Helix
    final path1 = Path();
    final path2 = Path();
    for(int i=0; i<20; i++) {
        final y = center.dy - h*0.4 + i*(h*0.8/20);
        final x1 = center.dx + sin(i*0.5 + time*2)*w*0.3;
        final x2 = center.dx + sin(i*0.5 + time*2 + pi)*w*0.3;
        if (i==0) { path1.moveTo(x1, y); path2.moveTo(x2, y); }
        else { path1.lineTo(x1, y); path2.lineTo(x2, y); }
        
        // Rungs
        if (i%2 == 0) canvas.drawLine(Offset(x1, y), Offset(x2, y), helixPaint);
    }
    canvas.drawPath(path1, helixPaint);
    canvas.drawPath(path2, helixPaint);

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderGalaxyEaterBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Cosmic Cloud
    final spacePaint = Paint()..shader = RadialGradient(colors: [const Color(0xFF312E81), Colors.black]).createShader(Rect.fromCircle(center: center, radius: w*0.5));
    canvas.drawCircle(center, w*0.5, spacePaint);
    
    // Stars inside
    final starPaint = Paint()..color = Colors.white.withOpacity(alpha);
    for(int i=0; i<10; i++) {
        final x = center.dx + (Random(i).nextDouble()-0.5)*w*0.8;
        final y = center.dy + (Random(i+1).nextDouble()-0.5)*h*0.8;
        canvas.drawCircle(Offset(x, y), 2, starPaint);
    }
    
    // Accretion disk
    final diskPaint = Paint()..color = const Color(0xFF818CF8).withOpacity(0.4 * alpha)..style = PaintingStyle.stroke..strokeWidth = 6;
    canvas.drawOval(Rect.fromCenter(center: center, width: w*1.2, height: h*0.4), diskPaint);

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderWarMachineOmegaBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Mech
    final metalPaint = Paint()..color = const Color(0xFF374151).withOpacity(alpha);
    final gunPaint = Paint()..color = const Color(0xFF1F2937).withOpacity(alpha);
    
    // Torso
    canvas.drawRect(Rect.fromCenter(center: center, width: w*0.5, height: h*0.5), metalPaint);
    
    // Shoulder Cannons
    canvas.drawRect(Rect.fromCenter(center: Offset(center.dx - w*0.35, center.dy - h*0.2), width: w*0.2, height: h*0.3), gunPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(center.dx + w*0.35, center.dy - h*0.2), width: w*0.2, height: h*0.3), gunPaint);
    
    // Cockpit eye
    canvas.drawCircle(center, w*0.1, Paint()..color = Colors.red..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderTitanFusionBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Shifting form
    final phaseTime = (time * 0.5).floor();
    final forms = [
        _renderDeathIncarnateBody,
        _renderCelestialGuardianBody,
        _renderAbyssalHorrorBody,
        _renderChaosJesterBody,
        _renderGenesisCoreBody,
        _renderGalaxyEaterBody,
        _renderWarMachineOmegaBody
    ];
    
    // Call the delegate rendering method for current form
    // Note: We can't easily call methods by index in Dart without reflection or a map.
    // Simulating "Fusion" by drawing a glitchy mix
    
    final mixPaint = Paint()..shader = SweepGradient(colors: [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.red]).createShader(Rect.fromCircle(center: center, radius: w*0.5));
    canvas.drawCircle(center, w*0.4 + sin(time*10)*5, mixPaint);
    
    // Glitch lines
    final glitchPaint = Paint()..color = Colors.white.withOpacity(0.8 * alpha)..style = PaintingStyle.stroke..strokeWidth = 2;
    for(int i=0; i<5; i++) {
        final y = center.dy + (Random().nextDouble()-0.5)*h;
        canvas.drawLine(Offset(center.dx - w*0.6, y), Offset(center.dx + w*0.6, y), glitchPaint);
    }

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  // ═══════════════════════════════════════
  //  TIER 5 BOSS-SPECIFIC BODIES
  // ═══════════════════════════════════════

  void _renderWorldEnderBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Planet-sized Entity
    final surfacePaint = Paint()..shader = RadialGradient(colors: [const Color(0xFF4C1D95), Colors.black]).createShader(Rect.fromCircle(center: center, radius: w*0.5));
    canvas.drawCircle(center, w*0.5, surfacePaint);
    
    // Cracks showing magma/energy
    final crackPaint = Paint()..color = const Color(0xFFEF4444).withOpacity(0.8 * alpha)..style = PaintingStyle.stroke..strokeWidth = 2;
    for(int i=0; i<8; i++) {
        final angle = i * (pi/4) + time*0.2;
        final start = Offset(center.dx + cos(angle)*w*0.2, center.dy + sin(angle)*w*0.2);
        final end = Offset(center.dx + cos(angle)*w*0.5, center.dy + sin(angle)*w*0.5);
        canvas.drawLine(start, end, crackPaint);
    }
    
    // Singular Giant Eye
    final eyeWhite = Paint()..color = Colors.white.withOpacity(alpha);
    final eyeIris = Paint()..color = Colors.red.withOpacity(alpha);
    final eyePupil = Paint()..color = Colors.black.withOpacity(alpha);
    
    canvas.drawOval(Rect.fromCenter(center: center, width: w*0.4, height: h*0.3), eyeWhite);
    canvas.drawCircle(center, w*0.12, eyeIris);
    canvas.drawCircle(center, w*0.05, eyePupil);
    
    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderTheInfiniteBody(Canvas canvas, double w, double h, Offset center, double alpha) {
    // Abstract geometric god
    final colors = [Colors.cyan, const Color(0xFFFF00FF), Colors.yellow, Colors.white];
    final color = colors[(time * 4).floor() % colors.length];
    
    final paint = Paint()
      ..color = color.withOpacity(0.8 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    // Rotating concentric shapes
    for(int i=0; i<4; i++) {
        final radius = w * (0.2 + i*0.1);
        final angle = time * (1 + i*0.5) * (i%2==0 ? 1 : -1);
        
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle);
        
        if (i%2==0) {
            canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: radius*2, height: radius*2), paint);
        } else {
             // Triangle
             final path = Path();
             path.moveTo(0, -radius);
             path.lineTo(radius * 0.866, radius * 0.5);
             path.lineTo(-radius * 0.866, radius * 0.5);
             path.close();
             canvas.drawPath(path, paint);
        }
        canvas.restore();
    }
    
    // Central singularity
    canvas.drawCircle(center, w*0.1, Paint()..color = Colors.white.withOpacity(alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    _renderPhasePips(canvas, center, w, h, alpha);
  }

  void _renderHealthBar(Canvas canvas, double w) {
    final barWidth = w * 0.9;
    final barHeight = 8.0;
    final barX = (w - barWidth) / 2;
    final barY = size.y * 0.78;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barWidth, barHeight), const Radius.circular(4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    final hpPercent = health / maxHealth;
    final hpColor = hpPercent > 0.5
        ? Color.lerp(Colors.yellow, Colors.green, (hpPercent - 0.5) * 2)!
        : Color.lerp(Colors.red, Colors.yellow, hpPercent * 2)!;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barWidth * hpPercent, barHeight), const Radius.circular(4)),
      Paint()
        ..color = hpColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
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
