import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../data/game_storage.dart';
import '../data/ship_data.dart';
import '../data/boss_data.dart';
import '../data/powerup_data.dart';
import '../data/progression_data.dart';
import 'components/player_component.dart';
import 'components/obstacle_spawner.dart';
import 'components/coin_spawner.dart';
import 'components/starfield_background.dart';
import 'components/physics_system.dart';
import 'components/bullet_component.dart';
import 'components/boss_component.dart';
import 'components/enemy_wave_system.dart';
import 'components/powerup_component.dart';
import 'components/ship_trail.dart';
import 'components/screen_effects.dart';
import 'components/satellite_component.dart';
import 'components/explosion_component.dart';

enum GameState { playing, paused, gameOver }
enum GameMode { endless, hardcore, survivalHell, bossRush, gauntlet }

class SpaceEscaperGame extends FlameGame
    with HasCollisionDetection, PanDetector {
  late PlayerComponent player;
  late ObstacleSpawner obstacleSpawner;
  late CoinSpawner coinSpawner;
  late StarfieldBackground starfield;
  late PhysicsSystemComponent physicsSystem;
  late EnemyWaveSystem waveSystem;
  late PowerUpSpawner powerUpSpawner;
  late ShipTrail shipTrail;
  late ScreenEffects screenEffects;

  GameState gameState = GameState.playing;
  GameMode gameMode = GameMode.endless;
  bool obstaclesEnabled = true;
  bool coinsEnabled = true;
  bool bossesEnabled = true;
  int bossRushTarget = 5;
  int bossRushDefeated = 0;
  bool disableSecondWind = false;
  double obstacleDensityMultiplier = 1.0;
  double bossRushIntermission = 0.0;
  bool isLoaded = false;
  final String? overrideShipId; // For Test Drive

  // Progression
  double distance = 0;
  double baseSpeed = 120;
  double currentSpeed = 120;
  double speedMultiplier = 1.0;
  double obstacleMultiplier = 1.0;
  int runCoins = 0;
  double timeSurvived = 0;
  int combo = 0;
  int maxCombo = 0;
  double comboTimer = 0;
  double multiplier = 1.0;
  double fireCooldownTimer = 0;

  // Run stats (for missions/XP)
  int aliensKilledThisRun = 0;
  int bossesKilledThisRun = 0;
  int physicsSurvivedThisRun = 0;
  int powerUpsCollectedThisRun = 0;
  int _xpGrantedFromDistance = 0;

  // Active power-ups
  final Map<PowerUpType, double> activePowerUps = {};
  double shieldDurationMultiplier = 1.0;

  // Kill streak (Plasma Phoenix)
  int killStreak = 0;
  double killStreakTimer = 0;

  // Boss
  bool bossActive = false;
  BossComponent? currentBoss;
  Set<String> bossesDefeatedThisRun = {};

  // Physics mode
  String currentPhysicsMode = 'normal';
  String? pendingPhysicsMode;
  double physicsTimer = 0;
  double physicsDuration = 0;
  double nextPhysicsChange = 30 + Random().nextDouble() * 30;
  bool physicsWarning = false;
  double warningTimer = 0;
  bool showBanner = false;
  double bannerTimer = 0;
  String bannerText = '';
  Color bannerColor = Colors.green;

  // Milestones
  final Set<int> reachedMilestones = {};
  String? milestoneAlert;
  double milestoneAlertTimer = 0;
  final Set<String> unlockedObstacles = {'asteroid', 'debris', 'barrier'};

  // Ship data
  late ShipData currentShip;

  // Touch input
  Vector2 _dragDelta = Vector2.zero();
  bool _isDragging = false;

  // Consumables for this run
  bool headStartActive = false;
  bool luckyCloverActive = false;
  bool shieldChargeActive = false;
  bool xpBoosterActive = false;

  // Active Ability
  double activeAbilityCooldownTimer = 0; // counts down to 0
  bool activeAbilityActive = false;
  double activeAbilityDurationTimer = 0;

  // Evolution
  bool evolved = false;
  bool evolvedTier2 = false;

  // Passive counters
  int hitCounter = 0; // for static build-up, overcharge
  bool timeDistortionActive = false;
  double timeDistortionTimer = 0;

  // Legendary+ passive counters
  int coreIgnitionStacks = 0;    // Star Forge: stacking drone dmg
  int killsSinceCoreIgnition = 0;
  bool rebirthUsed = false;       // Plasma Phoenix: once per game
  int bossKillCount = 0;          // Omega Nexus: stat scaling
  int scalingKills = 0;           // Infinity Colossus: damage per 100 kills
  int solarSurgeStacks = 0;       // Stellar Colossus: stacking damage

  // Callbacks
  VoidCallback? onGameOver;
  VoidCallback? onPauseRequest;
  
  SpaceEscaperGame({this.overrideShipId, GameMode? mode}) {
    if (mode != null) gameMode = mode;
  }

  @override
  Color backgroundColor() => const Color(0xFF050D1A);

  void resumeGame() { gameState = GameState.playing; }

  void pauseGame() {
    gameState = GameState.paused;
    if (onPauseRequest != null) onPauseRequest!();
  }

  String get distanceFormatted => distance.toInt().toString();

  void teleportPlayer() {
    player.position = Vector2(size.x / 2, size.y - 100);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Use override if present (Test Drive), otherwise storage
    final shipId = overrideShipId ?? GameStorage.selectedShip;
    currentShip = getShipById(shipId);
    _xpGrantedFromDistance = 0;

    // Mode setup
    if (gameMode == GameMode.survivalHell) {
      obstacleDensityMultiplier = 5.0;
      baseSpeed *= 0.8;
      disableSecondWind = true;
    } else if (gameMode == GameMode.bossRush) {
      obstaclesEnabled = false;
      coinsEnabled = true;
      bossesEnabled = true;
    } else if (gameMode == GameMode.gauntlet) {
      // Uses existing systems, special waves later
      bossesEnabled = true;
    }

    // Legacy auto-consume removed.
    // Consumables are now handled via GameStorage.consumeActiveItems() at the end of onLoad.

    // Background
    starfield = StarfieldBackground();
    add(starfield);

    // Physics system
    physicsSystem = PhysicsSystemComponent();
    add(physicsSystem);

    // Player
    player = PlayerComponent(shipData: currentShip, gameRef: this);
    add(player);

    // Spawners
    obstacleSpawner = ObstacleSpawner(gameRef: this);
    coinSpawner = CoinSpawner(gameRef: this);

    if (obstaclesEnabled) {
      add(obstacleSpawner);
    }
    if (coinsEnabled) {
      add(coinSpawner);
    }

    // Enemy wave system
    waveSystem = EnemyWaveSystem();
    if (gameMode != GameMode.bossRush) {
      add(waveSystem);
    }

    // Power-up spawner
    powerUpSpawner = PowerUpSpawner();
    add(powerUpSpawner);

    // Ship trail
    shipTrail = ShipTrail();
    add(shipTrail);

    // Satellites & Shield Circles
    _setupSatellites();

    // Screen effects
    screenEffects = ScreenEffects();
    add(screenEffects);

    // Apply ship stats
    baseSpeed += (currentShip.speedStat - 5) * 10;
    
    // Hardcore mode
    if (gameMode == GameMode.hardcore) {
      baseSpeed *= 1.3;
    }

    currentSpeed = baseSpeed;

    // ═══════════════════════════════════════
    //  CONSUMABLE EFFECTS (from Loadout selection)
    // ═══════════════════════════════════════
    final consumables = GameStorage.consumeActiveItems();

    // HEAD START: Skip ahead 2000m with speed boost + 5s invincibility
    if (consumables.contains('headStart')) {
      distance = 2000;
      currentSpeed = baseSpeed * 1.5;
      player.makeInvincible(); // Brief invincibility
      activePowerUps[PowerUpType.invincibility] = 5.0;
    }

    // LUCKY CLOVER: +20% more coins throughout the run
    if (consumables.contains('luckyClover')) {
      luckyCloverActive = true;
    }

    // SHIELD CHARGE: Start with an active shield (not in Survival Hell)
    if (consumables.contains('shieldCharge')) {
      if (gameMode != GameMode.survivalHell) {
        activePowerUps[PowerUpType.shield] = 20.0;
      }
    }

    // XP BOOSTER: Double XP for this run
    if (consumables.contains('xpBooster')) {
      xpBoosterActive = true;
    }

    isLoaded = true;

    if (gameMode == GameMode.bossRush) {
      final first = getBossForDistance(0, bossesDefeatedThisRun);
      if (first != null) _spawnBoss(first);
    }
  }

  void _setupSatellites() {
      // 1. Star Forge Drones
      if (currentShip.id == 'star_forge') {
          for(int i=0; i<6; i++) {
              add(SatelliteComponent(
                  orbitRadius: 70, 
                  orbitSpeed: 1.5, 
                  startAngle: i * (2*pi/6), 
                  color: const Color(0xFFFF6B35)));
          }
      }
      // 2. Shield Circles (Visual only for now, or passive damage)
      // Visualizing shield circles as satellites
      else if (currentShip.shieldCircles > 0) {
          double radiusBase = 50.0;
          for(int i=0; i<currentShip.shieldCircles; i++) {
              add(SatelliteComponent(
                  orbitRadius: radiusBase + (i * 10), 
                  orbitSpeed: 1.0 + (i * 0.2), 
                  startAngle: i * (pi/4), 
                  color: Colors.blueAccent));
          }
      }
  }

  @override
  void render(Canvas canvas) {
    if (!isLoaded) return;
    super.render(canvas);
  }

  @override
  void update(double dt) {
    if (!isLoaded) return;
    if (gameState != GameState.playing) return;
    super.update(dt);

    timeSurvived += dt;
    distance += currentSpeed * dt;

    final totalXpFromDistance = XpGain.fromDistance(distance);
    final deltaXp = totalXpFromDistance - _xpGrantedFromDistance;
    if (deltaXp > 0) {
      double xpMult = xpBoosterActive ? 2.0 : 1.0;
      
      // Skill tree: Quick Learner
      final xpLevel = GameStorage.getSkillLevel('xp_boost', shipId: currentShip.id);
      xpMult += xpLevel * 0.05;

      GameStorage.addXp((deltaXp * xpMult).ceil());
      _xpGrantedFromDistance = totalXpFromDistance;
    }

    if (gameMode == GameMode.bossRush && bossRushIntermission > 0) {
      bossRushIntermission -= dt;
      if (bossRushIntermission <= 0 && !bossActive) {
        final next = allBosses.firstWhere(
          (b) => !bossesDefeatedThisRun.contains(b.id),
          orElse: () => allBosses.first,
        );
        _spawnBoss(next);
      }
    }

    // Speed curve
    final earlyFactor = (distance / 800).clamp(0.0, 10.0);
    speedMultiplier = 1 + earlyFactor * 0.06;
    if (distance > 4000) {
      final lateFactor = ((distance - 4000) / 2000).clamp(0.0, 8.0);
      speedMultiplier += lateFactor * 0.04;
    }
    currentSpeed = baseSpeed * speedMultiplier;

    // Physics speed modifiers
    if (currentPhysicsMode == 'hyperdrive') {
      currentSpeed *= 1.6;
    } else if (currentPhysicsMode == 'timewarp') {
      currentSpeed *= 0.6;
    }

    // Bullet time power-up
    if (activePowerUps.containsKey(PowerUpType.bulletTime)) {
      currentSpeed *= 0.5;
    }

    // Obstacle density
    final densityFactor = (distance / 1200).clamp(0.0, 12.0);
    obstacleMultiplier = 1 + densityFactor * 0.06;
    obstacleMultiplier *= obstacleDensityMultiplier;

    // Fire cooldown & Auto-fire check (if not manual)
    if (fireCooldownTimer > 0) {
      fireCooldownTimer -= dt;
      if (fireCooldownTimer < 0) fireCooldownTimer = 0;
    }
    
    // AUTO FIRE for everyone
    if (fireCooldownTimer <= 0) {
        fireBullet();
    }

    // Combo timer
    if (comboTimer > 0) {
      if (!activePowerUps.containsKey(PowerUpType.comboFreeze)) {
        comboTimer -= dt;
      }
      if (comboTimer <= 0) {
        combo = 0;
        multiplier = 1.0;
      }
    }

    // Update active power-ups
    _updatePowerUps(dt);

    // Milestones
    _checkMilestones();

    if (milestoneAlertTimer > 0) {
      milestoneAlertTimer -= dt;
      if (milestoneAlertTimer <= 0) milestoneAlert = null;
    }

    // Boss spawning
    _checkBossSpawn();

    // Physics mode handling
    _updatePhysics(dt);

    // Banner
    if (showBanner) {
      bannerTimer -= dt;
      if (bannerTimer <= 0) showBanner = false;
    }

    // Track max combo
    if (combo > maxCombo) maxCombo = combo;

    // Kill streak decay
    if (killStreak > 0) {
      killStreakTimer -= dt;
      if (killStreakTimer <= 0) {
        killStreak = 0;
      }
    }

    // Active ability cooldown
    if (activeAbilityCooldownTimer > 0) {
      activeAbilityCooldownTimer -= dt;
    }
    if (activeAbilityActive) {
      activeAbilityDurationTimer -= dt;
      if (activeAbilityDurationTimer <= 0) {
        activeAbilityActive = false;
        _deactivateActiveAbility();
      }
    }

    // Time distortion (slow enemies)
    if (timeDistortionActive) {
      timeDistortionTimer -= dt;
      if (timeDistortionTimer <= 0) {
        timeDistortionActive = false;
      }
    }

    // Evolution check
    _checkEvolution();
  }

  // ═══════════════════════════════════════
  //  VISUAL EFFECTS HELPERS
  // ═══════════════════════════════════════

  void triggerPickupEffect(Vector2 position, Color color) {
    add(ExplosionComponent(
      position: position,
      color: color,
      maxRadius: 40,
      duration: 0.4,
    ));
  }

  // ═══════════════════════════════════════
  //  ACTIVE ABILITY SYSTEM
  // ═══════════════════════════════════════

  void triggerActiveAbility() {
    if (activeAbilityCooldownTimer > 0) return;
    if (currentShip.activeType == ActiveAbilityType.none) return;

    activeAbilityCooldownTimer = currentShip.activeCooldown;
    activeAbilityActive = true;
    activeAbilityDurationTimer = currentShip.activeDuration;

    screenEffects.triggerFlash(color: currentShip.color.withValues(alpha: 0.4));
    screenEffects.triggerModePulse(currentShip.color);

    showBanner = true;
    bannerTimer = 1.5;
    bannerText = currentShip.activeName.toUpperCase();
    bannerColor = currentShip.color;

    final origin = player.position.clone();

    switch (currentShip.activeType) {
      case ActiveAbilityType.hyperBoost:
        // Speed + fire rate handled in update/fireBullet
        break;

      case ActiveAbilityType.thunderDash:
        // Dash forward 150 pixels, damage nearby
        player.position.y -= 150;
        player.position.y = player.position.y.clamp(30, size.y - 30);
        add(ExplosionComponent(position: origin, color: const Color(0xFFFFEB3B), maxRadius: 80));
        screenEffects.triggerShake(duration: 0.3, intensity: 8);
        break;

      case ActiveAbilityType.cometStorm:
        // 5 bouncing projectiles in a fan
        for (int i = -2; i <= 2; i++) {
          final vel = Vector2(sin(i * 0.3), -cos(i * 0.3)) * 600;
          add(BulletComponent(
            position: origin.clone()..y -= 20,
            velocity: vel,
            type: BulletType.ricochet,
            damage: 5,
            color: const Color(0xFFFF9100),
          ));
        }
        break;

      case ActiveAbilityType.bulletCyclone:
        // 360° burst — 16 bullets
        for (int i = 0; i < 16; i++) {
          final angle = i * (2 * pi / 16);
          final vel = Vector2(cos(angle), sin(angle)) * 500;
          add(BulletComponent(
            position: origin.clone(),
            velocity: vel,
            damage: 3,
            color: currentShip.glowColor,
          ));
        }
        break;

      case ActiveAbilityType.meteorSlam:
        // AoE explosion
        add(ExplosionComponent(position: origin, color: const Color(0xFFFF5722), maxRadius: 120));
        screenEffects.triggerShake(duration: 0.5, intensity: 15);
        break;

      case ActiveAbilityType.iceNova:
        // Slow all enemies — handled via timeDistortion flag
        timeDistortionActive = true;
        timeDistortionTimer = 1.5;
        add(ExplosionComponent(position: origin, color: const Color(0xFF18FFFF), maxRadius: 100));
        break;

      case ActiveAbilityType.starSwarm:
        // 8 homing missiles
        for (int i = 0; i < 8; i++) {
          final angle = i * (2 * pi / 8);
          final vel = Vector2(cos(angle), sin(angle)) * 400;
          add(BulletComponent(
            position: origin.clone(),
            velocity: vel,
            type: BulletType.homing,
            damage: 4,
            color: const Color(0xFFFFEA00),
            homingTurnRate: 10.0,
          ));
        }
        break;

      case ActiveAbilityType.timeDistortion:
        // Slow everything
        timeDistortionActive = true;
        timeDistortionTimer = 3.0;
        screenEffects.triggerModePulse(const Color(0xFF22D3EE));
        break;

      case ActiveAbilityType.missileRain:
        // 6 rockets upward
        for (int i = -2; i <= 3; i++) {
          final vel = Vector2(i * 30.0, -600);
          add(BulletComponent(
            position: origin.clone()..y -= 20,
            velocity: vel,
            type: BulletType.explosive,
            damage: 8,
            color: const Color(0xFF34D399),
          ));
        }
        break;

      case ActiveAbilityType.lightningOverdrive:
        // Chain lightning burst — rapid fire handled in update
        for (int i = 0; i < 12; i++) {
          final angle = i * (2 * pi / 12);
          final vel = Vector2(cos(angle), sin(angle)) * 700;
          add(BulletComponent(
            position: origin.clone(),
            velocity: vel,
            type: BulletType.lightning,
            damage: 5,
            color: const Color(0xFFD500F9),
          ));
        }
        break;

      case ActiveAbilityType.fortressMode:
        // Invincible for duration
        player.makeInvincible();
        player.invincibleTimer = currentShip.activeDuration;
        break;

      case ActiveAbilityType.shadowClone:
        // Double attack rate handled in fireBullet cooldown
        break;

      // ─── LEGENDARY+ ABILITIES ─────────────────────

      case ActiveAbilityType.supernovaBurst:
        // Star Forge: giant explosion AoE
        add(ExplosionComponent(position: origin, color: const Color(0xFFFFD54F), maxRadius: 160));
        screenEffects.triggerShake(duration: 0.6, intensity: 15);
        // Damage all on-screen enemies (handled by explosion radius)
        break;

      case ActiveAbilityType.crystalCataclysm:
        // Diamond Emperor: crystal spike fan forward
        for (int i = -3; i <= 3; i++) {
          final angle = -pi / 2 + i * 0.12;
          add(BulletComponent(
            position: origin.clone(),
            velocity: Vector2(cos(angle), sin(angle)) * 800,
            type: BulletType.standard,
            damage: 8,
            color: const Color(0xFFB9F2FF),
          ));
        }
        screenEffects.triggerShake(duration: 0.3, intensity: 8);
        break;

      case ActiveAbilityType.phoenixDive:
        // Plasma Phoenix: dive forward + fire vortex
        player.position.y -= 180;
        player.position.y = player.position.y.clamp(30, size.y - 30);
        add(ExplosionComponent(position: origin, color: const Color(0xFFFF3D00), maxRadius: 120));
        add(ExplosionComponent(position: player.position.clone(), color: const Color(0xFFFF6D00), maxRadius: 100));
        screenEffects.triggerShake(duration: 0.5, intensity: 12);
        break;

      case ActiveAbilityType.blackHoleCollapse:
        // Void Sovereign: mini black hole (slow + pull all enemies)
        timeDistortionActive = true;
        timeDistortionTimer = currentShip.activeDuration;
        add(ExplosionComponent(position: Vector2(size.x / 2, size.y * 0.3), color: const Color(0xFF6200EA), maxRadius: 200));
        screenEffects.triggerShake(duration: 1.0, intensity: 10);
        break;

      case ActiveAbilityType.timeRewind:
        // Chrono Destroyer: restore health / undo 2s damage
        player.makeInvincible();
        player.invincibleTimer = 2.0;
        screenEffects.triggerFlash(color: const Color(0xFF00BFA5).withValues(alpha: 0.5));
        break;

      case ActiveAbilityType.astralWave:
        // Astral Leviathan: expanding energy wave
        add(ExplosionComponent(position: origin, color: const Color(0xFF304FFE), maxRadius: 250));
        screenEffects.triggerShake(duration: 0.8, intensity: 15);
        break;

      case ActiveAbilityType.infinityPulse:
        // Infinity Colossus: global damage burst
        add(ExplosionComponent(position: Vector2(size.x / 2, size.y / 2), color: Colors.white, maxRadius: 400));
        screenEffects.triggerShake(duration: 1.0, intensity: 20);
        screenEffects.triggerFlash(color: Colors.white.withValues(alpha: 0.6));
        break;

      case ActiveAbilityType.judgmentRay:
        // Celestial Warden: massive vertical laser
        for (int i = 0; i < 8; i++) {
          add(BulletComponent(
            position: Vector2(origin.x, origin.y - i * 60),
            velocity: Vector2(0, -1) * 1200,
            type: BulletType.standard,
            damage: 10,
            color: const Color(0xFFFFD600),
          ));
        }
        screenEffects.triggerFlash(color: const Color(0xFFFFD600).withValues(alpha: 0.4));
        screenEffects.triggerShake(duration: 0.5, intensity: 10);
        break;

      case ActiveAbilityType.abyssSurge:
        // Abyssal Reaver: screen darkens, enemies slowed
        timeDistortionActive = true;
        timeDistortionTimer = currentShip.activeDuration;
        screenEffects.triggerFlash(color: const Color(0xFF1A1A1A).withValues(alpha: 0.5));
        break;

      case ActiveAbilityType.dimensionalCollapse:
        // Quantum Harbinger: all enemies pulled to center
        add(ExplosionComponent(position: Vector2(size.x / 2, size.y / 2), color: const Color(0xFFAA00FF), maxRadius: 300));
        timeDistortionActive = true;
        timeDistortionTimer = currentShip.activeDuration;
        screenEffects.triggerShake(duration: 1.0, intensity: 15);
        break;

      case ActiveAbilityType.supernova:
        // Stellar Colossus: massive star explosion
        add(ExplosionComponent(position: origin, color: const Color(0xFFFF6D00), maxRadius: 300));
        add(ExplosionComponent(position: origin, color: const Color(0xFFFFAB00), maxRadius: 200));
        screenEffects.triggerShake(duration: 1.0, intensity: 20);
        screenEffects.triggerFlash(color: const Color(0xFFFFAB00).withValues(alpha: 0.5));
        break;

      case ActiveAbilityType.cosmicRain:
        // Eternal Sovereign: rain of cosmic projectiles
        for (int i = 0; i < 12; i++) {
          final x = Random().nextDouble() * size.x;
          add(BulletComponent(
            position: Vector2(x, 0),
            velocity: Vector2(0, 1) * 900,
            type: BulletType.standard,
            damage: 8,
            color: const Color(0xFF40C4FF),
          ));
        }
        screenEffects.triggerFlash(color: const Color(0xFF00B0FF).withValues(alpha: 0.3));
        break;

      case ActiveAbilityType.genesisCollapse:
        // Omega Nexus: screen distortion + massive damage
        add(ExplosionComponent(position: Vector2(size.x / 2, size.y / 2), color: Colors.white, maxRadius: 500));
        add(ExplosionComponent(position: origin, color: const Color(0xFF000000), maxRadius: 300));
        player.makeInvincible();
        player.invincibleTimer = currentShip.activeDuration;
        timeDistortionActive = true;
        timeDistortionTimer = currentShip.activeDuration;
        screenEffects.triggerShake(duration: 2.0, intensity: 25);
        screenEffects.triggerFlash(color: Colors.white.withValues(alpha: 0.8));
        break;

      case ActiveAbilityType.none:
        break;
    }
  }

  void _deactivateActiveAbility() {
    // Clean up effects when ability ends
    switch (currentShip.activeType) {
      case ActiveAbilityType.fortressMode:
      case ActiveAbilityType.genesisCollapse:
        player.invincible = false;
        break;
      case ActiveAbilityType.blackHoleCollapse:
      case ActiveAbilityType.abyssSurge:
      case ActiveAbilityType.dimensionalCollapse:
        timeDistortionActive = false;
        break;
      default:
        break;
    }
  }

  // ═══════════════════════════════════════
  //  EVOLUTION SYSTEM
  // ═══════════════════════════════════════

  void _checkEvolution() {
    final evo = currentShip.evolution;
    if (evo == null) return;

    if (!evolved && distance >= evo.distance) {
      evolved = true;
      // Spawn orbit drones
      for (int i = 0; i < evo.orbitCount; i++) {
        add(SatelliteComponent(
          orbitRadius: 60,
          orbitSpeed: 2.0,
          startAngle: i * (2 * pi / evo.orbitCount),
          color: evo.orbitColor,
          damage: evo.orbitDamage,
        ));
      }
      showBanner = true;
      bannerTimer = 3.0;
      bannerText = '⚡ EVOLVED! ${evo.desc.toUpperCase()}';
      bannerColor = evo.orbitColor;
      screenEffects.triggerModePulse(evo.orbitColor);
      screenEffects.triggerShake(duration: 0.5, intensity: 10);
    }

    if (!evolvedTier2 && distance >= evo.secondTierDistance) {
      evolvedTier2 = true;
      final extra = evo.secondTierOrbitCount - evo.orbitCount;
      for (int i = 0; i < extra; i++) {
        add(SatelliteComponent(
          orbitRadius: 80,
          orbitSpeed: 1.8,
          startAngle: i * (2 * pi / extra) + pi / 4,
          color: evo.orbitColor,
          damage: evo.orbitDamage + 5,
        ));
      }
      showBanner = true;
      bannerTimer = 3.0;
      bannerText = '🔥 TIER 2 EVOLUTION!';
      bannerColor = evo.orbitColor;
      screenEffects.triggerModePulse(evo.orbitColor);
    }
  }

  // ═══════════════════════════════════════
  //  PASSIVE HELPERS
  // ═══════════════════════════════════════

  /// Called when a bullet hits an enemy (from bullet collision)
void onBulletHit() {
  hitCounter++;

  // Storm Chaser: Static Build-Up — chain lightning every 8 hits
  if (currentShip.passiveType == PassiveType.staticBuildUp && hitCounter % 8 == 0) {
    final origin = player.position.clone();
    for (int i = 0; i < 3; i++) {
      final angle = Random().nextDouble() * 2 * pi;
      add(BulletComponent(
        position: origin.clone(),
        velocity: Vector2(cos(angle), sin(angle)) * 600,
        type: BulletType.lightning,
        damage: 3,
        color: const Color(0xFFFFEB3B),
      ));
    }
  }

  // Cosmic Viper: Overcharge — every 5th hit chains twice
  if (currentShip.passiveType == PassiveType.overcharge && hitCounter % 5 == 0) {
    final origin = player.position.clone();
    for (int i = 0; i < 2; i++) {
      final angle = Random().nextDouble() * 2 * pi;
      add(BulletComponent(
        position: origin.clone(),
        velocity: Vector2(cos(angle), sin(angle)) * 500,
        type: BulletType.lightning,
        damage: 3,
        color: const Color(0xFFD500F9),
      ));
    }
  }

  // Chrono Destroyer: Temporal Echo — 20% chance to repeat shot
  if (currentShip.passiveType == PassiveType.temporalEcho && Random().nextDouble() < 0.20) {
    final origin = player.position.clone()..y -= 30;
    add(BulletComponent(
      position: origin,
      velocity: Vector2(0, -1) * 900,
      type: BulletType.standard,
      damage: 3,
      color: const Color(0xFF1DE9B6),
    ));
  }

  // Quantum Harbinger: Multiverse Echo — 2% chance to duplicate shot
  if (currentShip.passiveType == PassiveType.multiverseEcho && Random().nextDouble() < 0.02) {
    final origin = player.position.clone()..y -= 30;
    for (int i = 0; i < 3; i++) {
      final angle = -pi / 2 + (Random().nextDouble() - 0.5) * 0.3;
      add(BulletComponent(
        position: origin.clone(),
        velocity: Vector2(cos(angle), sin(angle)) * 900,
        type: BulletType.standard,
        damage: 5,
        color: const Color(0xFFD500F9),
      ));
    }
  }
}

  /// Get fire rate multiplier from passive/active effects
  double getFireRateMultiplier() {
    double mult = 1.0;
    // Stellar Phantom: Adrenaline Mode — fire rate boost when combo < 5
    if (currentShip.passiveType == PassiveType.adrenalineMode && combo < 5) {
      mult *= 0.6; // 40% faster (lower cooldown)
    }
    // Hyper Boost active
    if (activeAbilityActive && currentShip.activeType == ActiveAbilityType.hyperBoost) {
      mult *= 0.7; // 30% faster
    }
    // Shadow Clone active
    if (activeAbilityActive && currentShip.activeType == ActiveAbilityType.shadowClone) {
      mult *= 0.5; // Double fire rate
    }
    return mult;
  }

  /// Get coin collection range multiplier
  double getCoinRangeMultiplier() {
    if (currentShip.passiveType == PassiveType.magneticCore) return 1.15;
    return 1.0;
  }

  /// Check if damage should be ignored (Phase Shield / Reflective Matrix)
bool shouldPhaseShield() {
  if (currentShip.passiveType == PassiveType.phaseShield) {
    return Random().nextDouble() < 0.10; // 10% chance
  }
  if (currentShip.passiveType == PassiveType.reflectiveMatrix) {
    return Random().nextDouble() < 0.15; // 15% chance
  }
  return false;
}

/// Get damage multiplier from scaling passives
double getDamageMultiplier() {
  double mult = 1.0;
  // Star Forge: Core Ignition stacks
  if (currentShip.passiveType == PassiveType.coreIgnition) {
    mult += coreIgnitionStacks * 0.1; // +10% per stack
  }
  // Infinity Colossus: per 100 kills
  if (currentShip.passiveType == PassiveType.infiniteScaling) {
    mult += (scalingKills ~/ 100) * 0.15; // +15% per 100 kills
  }
  // Stellar Colossus: Solar Surge stacking
  if (currentShip.passiveType == PassiveType.solarSurge) {
    mult += solarSurgeStacks * 0.02; // +2% per kill (caps naturally)
  }
  // Eternal Sovereign: combo scaling
  if (currentShip.passiveType == PassiveType.comboScaling) {
    mult += combo * 0.03; // +3% per combo
  }
  // Omega Nexus: boss kill scaling
  if (currentShip.passiveType == PassiveType.absoluteDominance) {
    mult += bossKillCount * 0.20; // +20% per boss killed
  }
  return mult;
}


  void activatePowerUp(PowerUpType type) {
    if (gameMode == GameMode.survivalHell && type == PowerUpType.shield) {
      return;
    }
    final info = getPowerUpInfo(type);
    double duration = info.duration;

    // Skill bonus
    final extLevel = GameStorage.getSkillLevel('powerup_duration', shipId: currentShip.id);
    duration *= (1 + extLevel * 0.1);

    // Consumable bonus (Shield)
    if (type == PowerUpType.shield) {
      duration *= shieldDurationMultiplier;
    }

    activePowerUps[type] = duration;
    powerUpsCollectedThisRun++;

    // Visuals
    screenEffects.triggerFlash(color: info.color.withValues(alpha: 0.3));
    screenEffects.triggerModePulse(info.color);

    // Immediate effects
    switch (type) {
      case PowerUpType.shield:
        // Shield is consumed on next hit; no immediate invincibility here
        break;
      case PowerUpType.coinStorm:
        for (int i = 0; i < 20; i++) {
          final x = 40 + Random().nextDouble() * (size.x - 80);
          coinSpawner.gameRef.add(CoinComponent(
            position: Vector2(x, -20 - i * 15),
            value: 1,
          ));
        }
        break;
      case PowerUpType.miniShip:
        player.size = Vector2(18, 22);
        break;
      case PowerUpType.invincibility:
        player.phasing = true;
        break;
      default:
        break;
    }

    showBanner = true;
    bannerTimer = 1.5;
    bannerText = info.name.toUpperCase();
    bannerColor = info.color;
  }

  void _updatePowerUps(double dt) {
    final expired = <PowerUpType>[];
    activePowerUps.forEach((type, remaining) {
      activePowerUps[type] = remaining - dt;
      if (activePowerUps[type]! <= 0) {
        expired.add(type);
      }
    });

    for (final type in expired) {
      activePowerUps.remove(type);
      _deactivatePowerUp(type);
    }
  }

  void _deactivatePowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.miniShip:
        player.size = Vector2(36, 44);
        break;
      case PowerUpType.invincibility:
        player.phasing = false;
        break;
      default:
        break;
    }
  }

  bool hasPowerUp(PowerUpType type) => activePowerUps.containsKey(type);

  // ═══════════════════════════════════════
  //  BOSS SYSTEM (30 Bosses)
  // ═══════════════════════════════════════

  void _checkBossSpawn() {
    if (bossActive) return;
    if (gameMode == GameMode.bossRush && bossRushIntermission > 0) return;
    if (!bossesEnabled) return;
    final boss = getBossForDistance(distance, bossesDefeatedThisRun);
    if (boss != null) {
      _spawnBoss(boss);
    }
  }

  void _spawnBoss(BossConfig config) {
    bossActive = true;

    currentBoss = BossComponent(
      config: config,
      position: Vector2(size.x / 2, -80),
    );
    add(currentBoss!);

    screenEffects.triggerShake(duration: 1.0, intensity: 12);
    screenEffects.triggerModePulse(config.color); // Pulse on boss spawn

    showBanner = true;
    bannerTimer = 3.0;
    bannerText = '${config.emoji} ${config.name.toUpperCase()}';
    bannerColor = config.color;
  }

  void onBossDefeated(String bossId) {
    bossActive = false;
    currentBoss = null;
    bossesKilledThisRun++;
    bossesDefeatedThisRun.add(bossId);

    final config = getBossById(bossId);
    final reward = config?.rewardCoins ?? 100;
    runCoins += reward;

    GameStorage.addDefeatedBoss(bossId);

    screenEffects.triggerShake(duration: 0.5, intensity: 15);
    screenEffects.triggerComboGlow();
    showBanner = true;
    bannerTimer = 3.0;
    bannerText = 'BOSS DEFEATED! +$reward COINS';
    bannerColor = const Color(0xFFFFD700);

    if (gameMode == GameMode.bossRush) {
      bossRushDefeated++;
      if (bossRushDefeated >= bossRushTarget) {
        _endRun();
      } else {
        bossRushIntermission = 2.0;
        // Intermission coin burst
        final rng = Random();
        for (int i = 0; i < 15; i++) {
          final x = 40 + rng.nextDouble() * (size.x - 80);
          add(CoinComponent(position: Vector2(x, -20 - i * 10), value: rng.nextDouble() < 0.2 ? 5 : 1));
        }
      }
    }
  }

  // ═══════════════════════════════════════
  //  SHOOTING
  // ═══════════════════════════════════════

  void fireBullet() {
    if (gameState != GameState.playing) return;
    
    // Set Cooldown
    fireCooldownTimer = _getFireCooldownForShip();

    // Skill tree: fire rate reduction
    final fireRateLevel = GameStorage.getSkillLevel('fire_rate', shipId: currentShip.id);
    fireCooldownTimer *= (1 - fireRateLevel * 0.05);

    // Plasma Phoenix kill streak boost
    if (currentShip.id == 'plasma_phoenix' && killStreak > 5) {
      fireCooldownTimer *= 0.8;
    }

    // Passive/Active fire rate multiplier
    fireCooldownTimer *= getFireRateMultiplier();

    final origin = player.position.clone()..y -= 30;
    final damaged = hasPowerUp(PowerUpType.damageBoost);
    
    // Skill tree: bullet speed bonus
    final bsLevel = GameStorage.getSkillLevel('bullet_speed', shipId: currentShip.id);
    final speedBonus = 1.0 + bsLevel * 0.05;

    // Skill tree: piercing rounds (bullet_damage ID in progression_data)
    final pierceLevel = GameStorage.getSkillLevel('bullet_damage', shipId: currentShip.id);

    // Helper to spawn bullets
    void spawn(Vector2 offset, double angle, {BulletType type = BulletType.standard, int dmg = 1, double speedMult = 1.0, double turnRate = 5.0, Vector2? size}) {
      final vel = Vector2(sin(angle), -cos(angle)) * (800 * speedBonus * speedMult);
      add(BulletComponent(
        position: origin + offset,
        velocity: vel,
        type: type,
        damage: dmg,
        penetrationCount: pierceLevel, // Pass penetration count
        color: currentShip.glowColor.withOpacity(1.0),
        size: size ?? (type == BulletType.blackHole ? Vector2(40, 40) : Vector2(6, 18)),
        homingTurnRate: turnRate,
      ));
    }

    // Logic for each WeaponType
    switch (currentShip.weaponType) {
      
      // 1. Nova Scout (Single Bullet) — with distance-based upgrades
      case WeaponType.singleBullet:
        spawn(Vector2(0, 0), 0);
        if (distance >= 40000) {
          // Triple shot
          spawn(Vector2(-12, 0), -0.1);
          spawn(Vector2(12, 0), 0.1);
        } else if (distance >= 25000) {
          // Double shot
          spawn(Vector2(10, 0), 0);
        }
        if (damaged) spawn(Vector2(15, 0), 0.05);
        break;

      // 2. Storm Chaser (Pulse Charger - Burst)
      case WeaponType.pulseCharge:
        // Simulating charge by firing 5 tight bullets
        for(int i=-2; i<=2; i++) {
           spawn(Vector2(i*4.0, 0), i*0.05, type: BulletType.standard, dmg: 2);
        }
        break;

      // 3. Comet Striker (Ricochet)
      case WeaponType.ricochet:
        spawn(Vector2(0, 0), 0.2, type: BulletType.ricochet, dmg: 2); // Angled start
        if (damaged) spawn(Vector2(0, 0), -0.2, type: BulletType.ricochet, dmg: 2);
        break;

      // 4. Meteor Dash (Shotgun)
      case WeaponType.shotgun:
        for(int i=-3; i<=3; i++) {
            if (i==0) continue;
            spawn(Vector2(i*2.0, 0), i*0.15, type: BulletType.standard, speedMult: 0.8 + Random().nextDouble()*0.4);
        }
        break;

      // 5. Aurora Wing (Frost Beam)
      case WeaponType.frostBeam:
        spawn(Vector2(0, 0), 0, type: BulletType.frost, speedMult: 1.5, dmg: 1);
        if (damaged) spawn(Vector2(5, 0), 0, type: BulletType.frost, speedMult: 1.5);
        break;

      // 6. Nebula Spark (Seeker Darts)
      case WeaponType.seekerDarts:
        spawn(Vector2(-10, 0), -0.5, type: BulletType.homing, turnRate: 8.0, dmg: 1);
        spawn(Vector2(0, 0), 0, type: BulletType.homing, turnRate: 8.0, dmg: 1);
        spawn(Vector2(10, 0), 0.5, type: BulletType.homing, turnRate: 8.0, dmg: 1);
        break;

      // 7. Stellar Phantom (Gatling)
      case WeaponType.gatling:
        spawn(Vector2(Random().nextDouble()*10 - 5, 0), 0, speedMult: 1.2);
        if (damaged) spawn(Vector2(Random().nextDouble()*10 - 5, 0), 0);
        break;

      // 8. Quantum Racer (Wave Beam)
      case WeaponType.waveBeam:
        spawn(Vector2(-5, 0), 0, type: BulletType.wave, dmg: 2);
        spawn(Vector2(5, 0), 0, type: BulletType.wave, dmg: 2);
        break;

      // 9. Nebula Cruiser (Rockets)
      case WeaponType.explosiveRockets:
        spawn(Vector2(0, 0), 0, type: BulletType.explosive, speedMult: 0.6, dmg: 5);
        if (damaged) spawn(Vector2(15, 0), 0, type: BulletType.explosive, speedMult: 0.6, dmg: 5);
        break;

      // 10. Cosmic Viper (Chain Lightning) -> simulating with fast spectral/tracking
      case WeaponType.chainLightning:
         spawn(Vector2(0, 0), 0, type: BulletType.lightning, speedMult: 2.0, dmg: 3);
         break;

      // 11. Galaxy Titan (Temporal Laser)
      case WeaponType.temporalLaser:
         spawn(Vector2(0, 0), 0, type: BulletType.timeShatter, speedMult: 1.2, dmg: 3);
         break;

      // 12. Void Reaper (Dimensional Blades)
      case WeaponType.dimensionalBlades:
         spawn(Vector2(-10, 0), -0.2, type: BulletType.blade, speedMult: 0.8, dmg: 4);
         spawn(Vector2(10, 0), 0.2, type: BulletType.blade, speedMult: 0.8, dmg: 4);
         break;

      // 13. Star Forge (Drone Swarm)
      case WeaponType.droneSwarm:
         // Drones (satellites) are separate, but ship also fires
         spawn(Vector2(0, 0), 0, dmg: 2);
         break;

      // 14. Diamond Emperor (Crystal Shatter)
      case WeaponType.crystalShatter:
         spawn(Vector2(0, 0), 0, type: BulletType.crystal, dmg: 5);
         break;

      // 15. Plasma Phoenix (Inferno)
      case WeaponType.infernoFlamethrower:
         for(int i=-1; i<=1; i++) {
             spawn(Vector2(i*4.0, 0), i*0.1, type: BulletType.flame, speedMult: 0.9, dmg: 2);
         }
         break;

      // 16. Void Sovereign (Gravity Pulse)
      case WeaponType.gravityPulse:
         spawn(Vector2(0, 0), 0, type: BulletType.blackHole, speedMult: 0.4, dmg: 3);
         break;

      // 17. Chrono Destroyer (Mines)
      case WeaponType.mines:
         spawn(Vector2(0, 0), 0, type: BulletType.mine, speedMult: 0.0, dmg: 10);
         break;

       // 18-25: High Tier God Ships
      case WeaponType.ionCannon:
         spawn(Vector2(0, 0), 0, type: BulletType.standard, size: Vector2(20, 60), dmg: 20);
         break;
      
      case WeaponType.annihilationWave:
         for(int i=-5; i<=5; i+=2) {
             spawn(Vector2(i*6.0, 0), 0, type: BulletType.wave, dmg: 10);
         }
         break;

      case WeaponType.holyLance:
         spawn(Vector2(0, 0), 0, type: BulletType.piercing, speedMult: 2.5, dmg: 15);
         break;
      
      case WeaponType.voidTentacles:
         for(int i=0; i<4; i++) {
            spawn(Vector2(0, 0), i*1.5, type: BulletType.homing, turnRate: 10.0, dmg: 8);
         }
         break;

      case WeaponType.realityFracture:
         spawn(Vector2(0, 0), 0, type: BulletType.timeShatter, size: Vector2(30,30), dmg: 25);
         break;

      case WeaponType.starCoreEruption:
         spawn(Vector2(0, 0), 0, type: BulletType.explosive, size: Vector2(40,40), dmg: 30);
         break;
      
      case WeaponType.cosmicJudgement:
         spawn(Vector2(0, 0), 0, type: BulletType.lightning, size: Vector2(10, 100), dmg: 50);
         break;

      case WeaponType.singularityGenesis:
         spawn(Vector2(0, 0), 0, type: BulletType.blackHole, size: Vector2(60,60), dmg: 100);
         break;
    }
  }

  double _getFireCooldownForShip() {
    switch (currentShip.weaponType) {
      case WeaponType.gatling: return 0.1;
      case WeaponType.frostBeam: return 0.08;
      case WeaponType.pulseCharge: return 1.5;
      case WeaponType.shotgun: return 0.8;
      case WeaponType.explosiveRockets: return 1.2;
      case WeaponType.temporalLaser: return 1.0;
      case WeaponType.infernoFlamethrower: return 0.05;
      case WeaponType.gravityPulse: return 2.0;
      case WeaponType.mines: return 2.0;
      case WeaponType.singularityGenesis: return 3.0;
      default: return 0.4;
    }
  }

  // ═══════════════════════════════════════
  //  MILESTONES
  // ═══════════════════════════════════════

  void _checkMilestones() {
    final milestones = {
      800: ('alien', 'Aliens Approaching!'),
      1500: ('blackhole', 'Black Holes Ahead!'),
      2500: ('satellite', 'Derelict Satellites!'),
      3500: ('solarflare', 'Solar Flares Detected!'),
      5000: ('meteor', 'Meteor Shower Warning!'),
      8000: ('wormhole', 'Wormhole Anomaly!'),
    };

    for (final entry in milestones.entries) {
      if (distance >= entry.key && !reachedMilestones.contains(entry.key)) {
        reachedMilestones.add(entry.key);
        unlockedObstacles.add(entry.value.$1);
        milestoneAlert = entry.value.$2;
        milestoneAlertTimer = 3;
      }
    }
  }

  // ═══════════════════════════════════════
  //  PHYSICS
  // ═══════════════════════════════════════

  void _updatePhysics(double dt) {
    if (currentPhysicsMode != 'normal') {
      physicsTimer -= dt;
      if (physicsTimer <= 0) {
        currentPhysicsMode = 'normal';
        physicsSurvivedThisRun++;
        final factor = 1 + (distance / 10000).floor() * 0.2;
        nextPhysicsChange = (30 + Random().nextDouble() * 30) / factor;
      }
    }

    if (currentPhysicsMode == 'normal' && !physicsWarning) {
      nextPhysicsChange -= dt;
      if (nextPhysicsChange <= 0) {
        _startPhysicsWarning();
      }
    }

    if (physicsWarning) {
      warningTimer -= dt;
      if (warningTimer <= 0) {
        _activatePhysicsMode();
      }
    }

    // Void Sovereign Gravity Resistance
    if (currentShip.id == 'void_sovereign') {
      if (currentPhysicsMode == 'reversed' || 
          currentPhysicsMode == 'zero' || 
          currentPhysicsMode == 'double') {
        currentPhysicsMode = 'normal';
      }
    }
  }

  void _startPhysicsWarning() {
    final modes = [
      'reversed', 'zero', 'double', 'inverted',
      'magnetic', 'turbulence', 'hyperdrive', 'timewarp', 'singularity',
    ];
    pendingPhysicsMode = modes[Random().nextInt(modes.length)];
    physicsWarning = true;
    warningTimer = 3.0;
  }

  void _activatePhysicsMode() {
    currentPhysicsMode = pendingPhysicsMode ?? 'normal';
    final durations = {
      'reversed': [15.0, 20.0],
      'zero': [10.0, 15.0],
      'double': [12.0, 18.0],
      'inverted': [10.0, 15.0],
      'magnetic': [15.0, 20.0],
      'turbulence': [12.0, 18.0],
      'hyperdrive': [8.0, 12.0],
      'timewarp': [8.0, 12.0],
      'singularity': [10.0, 15.0],
    };
    final d = durations[currentPhysicsMode] ?? [10.0, 15.0];
    physicsDuration = d[0] + Random().nextDouble() * (d[1] - d[0]);
    physicsTimer = physicsDuration;
    physicsWarning = false;
    pendingPhysicsMode = null;
    showBanner = true;
    bannerTimer = 2.0;

    final labels = {
      'reversed': ('GRAVITY REVERSED!', const Color(0xFFEF4444)),
      'zero': ('ZERO GRAVITY!', const Color(0xFFA855F7)),
      'double': ('DOUBLE GRAVITY!', const Color(0xFFFF6B35)),
      'inverted': ('CONTROLS INVERTED!', const Color(0xFFFBBF24)),
      'magnetic': ('MAGNETIC MODE!', const Color(0xFF3B82F6)),
      'turbulence': ('TURBULENCE!', const Color(0xFF06B6D4)),
      'hyperdrive': ('HYPERDRIVE!', const Color(0xFF00D9FF)),
      'timewarp': ('TIME WARP!', const Color(0xFF22C55E)),
      'singularity': ('SINGULARITY FIELD!', const Color(0xFF8B5CF6)),
    };
    bannerText = labels[currentPhysicsMode]?.$1 ?? '';
    bannerColor = labels[currentPhysicsMode]?.$2 ?? Colors.white;

    // Visual FX
    screenEffects.triggerModePulse(bannerColor);
  }

  Color getPhysicsModeColor() {
    final colors = {
      'normal': const Color(0xFF34D399),
      'reversed': const Color(0xFFEF4444),
      'zero': const Color(0xFFA855F7),
      'double': const Color(0xFFFF6B35),
      'inverted': const Color(0xFFFBBF24),
      'magnetic': const Color(0xFF3B82F6),
      'turbulence': const Color(0xFF06B6D4),
      'hyperdrive': const Color(0xFF00D9FF),
      'timewarp': const Color(0xFF22C55E),
      'singularity': const Color(0xFF8B5CF6),
    };
    return colors[currentPhysicsMode] ?? Colors.green;
  }

  String getPhysicsModeLabel() {
    final labels = {
      'reversed': 'GRAVITY REVERSED',
      'zero': 'ZERO GRAVITY',
      'double': 'DOUBLE GRAVITY',
      'inverted': 'CONTROLS INVERTED',
      'magnetic': 'MAGNETIC MODE',
      'turbulence': 'TURBULENCE',
      'hyperdrive': 'HYPERDRIVE',
      'timewarp': 'TIME WARP',
      'singularity': 'SINGULARITY FIELD',
    };
    return labels[currentPhysicsMode] ?? '';
  }

  double getSpawnInterval() {
    return max(0.4, 1.5 / obstacleMultiplier);
  }

  // ═══════════════════════════════════════
  //  INPUT
  // ═══════════════════════════════════════

  @override
  void onPanStart(DragStartInfo info) {
    _isDragging = true;
    _dragDelta = Vector2.zero();
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_isDragging && gameState == GameState.playing) {
      _dragDelta = info.delta.global;
      player.applyDragInput(_dragDelta);
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _isDragging = false;
    _dragDelta = Vector2.zero();
  }

  // ═══════════════════════════════════════
  //  COIN / COMBAT
  // ═══════════════════════════════════════

  void collectCoin(int value) {
    int earned = (value * multiplier).ceil();

    // Skill tree bonus
    final coinValueLevel = GameStorage.getSkillLevel('coin_value', shipId: currentShip.id);
    earned = (earned * (1 + coinValueLevel * 0.05)).ceil();

    // Lucky clover consumable
    if (luckyCloverActive) {
      earned = (earned * 1.2).ceil();
    }
    runCoins += earned;
    combo++;
    comboTimer = 2.0;

    // Skill tree combo duration bonus
    final comboDurLevel = GameStorage.getSkillLevel('combo_duration', shipId: currentShip.id);
    comboTimer += comboDurLevel * 0.3;

    if (combo >= 10) multiplier = 1.5;

    // Combo glow
    if (combo >= 50) {
      screenEffects.triggerComboGlow();
    }
  }

  void onAlienKilled() {
    aliensKilledThisRun++;
    int reward = 3;

    // Skill tree: bounty hunter
    final bountyLevel = GameStorage.getSkillLevel('alien_reward', shipId: currentShip.id);
    reward += bountyLevel * 2;

    runCoins += reward;
    waveSystem.onEnemyDestroyed();

    // Kill Streak for Plasma Phoenix
    if (currentShip.id == 'plasma_phoenix') {
      killStreak++;
      killStreakTimer = 3.0;
    }

    // Void Reaper: Soul Harvest — extend invincibility on kill
    if (currentShip.passiveType == PassiveType.soulHarvest) {
      if (player.invincible) {
        player.invincibleTimer += 0.3;
      } else {
        player.makeInvincible();
        player.invincibleTimer = 0.5;
      }
    }

    // Star Forge: Core Ignition — every 15 kills boosts drone damage
    if (currentShip.passiveType == PassiveType.coreIgnition) {
      killsSinceCoreIgnition++;
      if (killsSinceCoreIgnition >= 15) {
        killsSinceCoreIgnition = 0;
        coreIgnitionStacks++;
      }
    }

    // Infinity Colossus: Infinite Scaling — track kills for damage
    if (currentShip.passiveType == PassiveType.infiniteScaling) {
      scalingKills++;
    }

    // Stellar Colossus: Solar Surge — stacking damage
    if (currentShip.passiveType == PassiveType.solarSurge) {
      solarSurgeStacks++;
    }

    // Abyssal Reaver: Darkness Absorb — brief invincibility on kill
    if (currentShip.passiveType == PassiveType.darknessAbsorb) {
      if (!player.invincible) {
        player.makeInvincible();
        player.invincibleTimer = 0.3;
      }
    }
  }

  void playerHit() {
    if (player.invincible) return;
    if (player.phasing) return;

    if (activePowerUps.containsKey(PowerUpType.shield)) {
      return;
    }

    // Quantum Racer: Phase Shield — 10% chance to ignore damage
    // Diamond Emperor: Reflective Matrix — 15% chance to reflect
    if (shouldPhaseShield()) {
      showBanner = true;
      bannerTimer = 1.0;
      bannerText = currentShip.passiveType == PassiveType.reflectiveMatrix
          ? 'REFLECTED!' : 'PHASE SHIELD!';
      bannerColor = currentShip.color;
      return;
    }
    
    // Check for Shield Power-up
    if (activePowerUps.containsKey(PowerUpType.shield)) {
      activePowerUps.remove(PowerUpType.shield);
      return;
    }

    // Plasma Phoenix: Rebirth Protocol — revive once per game
    if (currentShip.passiveType == PassiveType.rebirthProtocol && !rebirthUsed) {
      rebirthUsed = true;
      player.makeInvincible();
      player.invincibleTimer = 3.0;
      showBanner = true;
      bannerTimer = 2.0;
      bannerText = '🔥 REBIRTH!';
      bannerColor = const Color(0xFFFF3D00);
      screenEffects.triggerFlash(color: const Color(0xFFFF3D00).withValues(alpha: 0.5));
      screenEffects.triggerShake(duration: 0.5, intensity: 12);
      return;
    }

    // Skill tree: second wind
    if (!disableSecondWind) {
      final secondWindLevel = GameStorage.getSkillLevel('bonus_life', shipId: currentShip.id);
      if (secondWindLevel > 0) {
        final chance = secondWindLevel * 0.1;
        if (Random().nextDouble() < chance) {
          player.makeInvincible();
          showBanner = true;
          bannerTimer = 1.5;
          bannerText = 'SECOND WIND!';
          bannerColor = Colors.cyan;
          return;
        }
      }
    }

    add(ExplosionComponent(position: player.position.clone(), color: const Color(0xFFFF6B35)));
    screenEffects.triggerShake(duration: 0.8, intensity: 20);
    screenEffects.triggerFlash(color: Colors.red.withValues(alpha: 0.6)); // Damage flash
    _endRun();
  }

  void _endRun() {
    if (gameState == GameState.gameOver) return;
    gameState = GameState.gameOver;
    if (gameMode == GameMode.survivalHell) {
      final bonus = (timeSurvived ~/ 5);
      if (bonus > 0) GameStorage.addStardust(bonus);
    }
    GameStorage.updateAfterRun(
      distance: distance,
      coinsCollected: runCoins,
      aliensKilled: aliensKilledThisRun,
      bossesKilled: bossesKilledThisRun,
      maxCombo: maxCombo,
      physicsSurvived: physicsSurvivedThisRun,
      powerUpsCollected: powerUpsCollectedThisRun,
    );
    if (onGameOver != null) onGameOver!();
  }

  void endRun() {
    _endRun();
  }

  // Public helper for Gauntlet to spawn next available boss
  void startGauntletBoss() {
    if (bossActive) return;
    final next = allBosses.firstWhere(
      (b) => !bossesDefeatedThisRun.contains(b.id),
      orElse: () => allBosses.first,
    );
    _spawnBoss(next);
  }
}
