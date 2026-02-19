import 'dart:math';
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
  int bossRushTarget = 30;
  int bossRushDefeated = 0;
  bool disableSecondWind = false;
  double obstacleDensityMultiplier = 1.0;
  double bossRushIntermission = 0.0;
  @override
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
  int _hellPulseLevel = 0;
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

  // Time Rewind History
  final List<Vector2> _positionHistory = [];
  double _historyTimer = 0;
  
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
      coinsEnabled = false;
      bossesEnabled = false;
    } else if (gameMode == GameMode.bossRush) {
      obstaclesEnabled = false;
      coinsEnabled = false;
      bossesEnabled = true;
      bossRushTarget = min(30, allBosses.length);
    } else if (gameMode == GameMode.gauntlet) {
      // Uses existing systems, special waves later
      bossesEnabled = true;
      coinsEnabled = false;
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
    if (gameMode != GameMode.bossRush) {
      _setupSatellites();
    }

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

    // DAMAGE CORE: Start with damage boost
    if (consumables.contains('damageCore')) {
      final info = getPowerUpInfo(PowerUpType.damageBoost);
      activePowerUps[PowerUpType.damageBoost] = info.duration;
    }

    isLoaded = true;

    if (gameMode == GameMode.bossRush) {
      if (allBosses.isNotEmpty) {
        _spawnBoss(allBosses.first);
      }
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

    if (gameMode == GameMode.survivalHell) {
      final level = (distance / 2500).floor();
      if (level > _hellPulseLevel) {
        _hellPulseLevel = level;
        screenEffects.triggerModePulse(const Color(0xFFEF4444));
        screenEffects.triggerFlash(color: Colors.red.withValues(alpha: 0.35), duration: 0.18);
        showBanner = true;
        bannerTimer = 1.2;
        bannerText = 'HELL INTENSIFIES!';
        bannerColor = const Color(0xFFEF4444);
      }
    }

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
        final remaining = allBosses.where((b) => !bossesDefeatedThisRun.contains(b.id)).toList();
        if (remaining.isEmpty) {
          _endRun();
        } else {
          _spawnBoss(remaining.first);
        }
      }
    }

    // Speed curve
    if (gameMode == GameMode.survivalHell) {
       speedMultiplier = 1.0 + (distance / 5200).clamp(0.0, 2.2);
    } else if (gameMode == GameMode.gauntlet) {
       speedMultiplier = 1.0 + (distance / 2600).clamp(0.0, 4.2);
    } else {
       // Standard / Hardcore
       final earlyFactor = (distance / 800).clamp(0.0, 10.0);
       speedMultiplier = 1 + earlyFactor * 0.06;
       if (distance > 4000) {
         final lateFactor = ((distance - 4000) / 2000).clamp(0.0, 8.0);
         speedMultiplier += lateFactor * 0.04;
       }
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
    // Obstacle density
    if (gameMode == GameMode.survivalHell) {
       double hellBonus = (distance / 2600) * 0.45;
       obstacleDensityMultiplier = (2.4 + hellBonus).clamp(2.4, 5.4);
       obstacleMultiplier = obstacleDensityMultiplier;
    } else if (gameMode == GameMode.gauntlet) {
       // Gauntlet: Starts normal, gets harder
       final densityFactor = (distance / 1000).clamp(0.0, 10.0);
       obstacleMultiplier = 1 + densityFactor * 0.18; // Faster ramp up than normal
    } else {
       // Normal
       final densityFactor = (distance / 1200).clamp(0.0, 12.0);
       obstacleMultiplier = 1 + densityFactor * 0.06;
       obstacleMultiplier *= obstacleDensityMultiplier;
    }

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
    if (gameMode != GameMode.bossRush) {
      _updatePhysics(dt);
    } else {
      currentPhysicsMode = 'normal';
      pendingPhysicsMode = null;
      physicsWarning = false;
      warningTimer = 0;
    }

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

    // Time Rewind History (Chrono Destroyer)
    if (currentShip.id == 'chrono_destroyer') {
       _historyTimer += dt;
       if (_historyTimer >= 0.1) {
          _historyTimer = 0;
          _positionHistory.add(player.position.clone());
          if (_positionHistory.length > 50) { // Keep last 5s
             _positionHistory.removeAt(0);
          }
       }
    }
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
        // Chrono Destroyer: restore position and grant invincibility
        if (_positionHistory.length > 20) {
            final targetIdx = max(0, _positionHistory.length - 20);
            player.position = _positionHistory[targetIdx].clone();
        }
        player.makeInvincible();
        player.invincibleTimer = 3.0; // Slightly longer for escape
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
    if (!coinsEnabled && type == PowerUpType.coinStorm) {
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
        if (!coinsEnabled) break;
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

    GameStorage.addDefeatedBoss(bossId);

    screenEffects.triggerShake(duration: 0.5, intensity: 15);
    screenEffects.triggerComboGlow();
    showBanner = true;
    bannerTimer = 3.0;
    bannerText = 'BOSS DEFEATED!';
    bannerColor = const Color(0xFF22C55E);

    // Boss defeats should not grant/drop coins (coins come from normal gameplay only).

    if (gameMode == GameMode.bossRush) {
      bossRushDefeated++;
      if (bossRushDefeated >= bossRushTarget) {
        _endRun();
      } else {
        bossRushIntermission = 2.0;
      }
    }
  }

  // ═══════════════════════════════════════
  //  WEAPON UPGRADES
  // ═══════════════════════════════════════

  int lastWeaponLevel = 1;

  WeaponLevelData getWeaponLevel() {
    if (currentShip.weaponLevels.isEmpty) {
      return const WeaponLevelData(level: 1, name: 'Basic', shots: 1, damage: 1, distanceThreshold: 0);
    }
    
    WeaponLevelData current = currentShip.weaponLevels.first;
    for (final levelData in currentShip.weaponLevels) {
      if (distance >= levelData.distanceThreshold) {
        current = levelData;
      } else {
        break;
      }
    }
    return current;
  }

  void _checkWeaponLevelUp() {
    final currentData = getWeaponLevel();
    if (currentData.level > lastWeaponLevel) {
      lastWeaponLevel = currentData.level;
      
      // Upgrade Banner
      showBanner = true;
      bannerTimer = 3.0;
      bannerText = 'WEAPON UPGRADE: ${currentData.name.toUpperCase()}!';
      bannerColor = currentShip.color;
      
      screenEffects.triggerFlash(color: currentShip.color.withValues(alpha: 0.3));
      screenEffects.triggerModePulse(currentShip.color);
      
      // Bonus notification for special effects
      if (currentData.specialBonus.isNotEmpty) {
        // We could queue another banner or just let the player discover it
        // For now, simple sound or flash is enough
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
    
    // Skill tree: bullet speed bonus
    final bsLevel = GameStorage.getSkillLevel('bullet_speed', shipId: currentShip.id);
    final speedBonus = 1.0 + bsLevel * 0.05;

    // Skill tree: piercing rounds (bullet_damage ID in progression_data)
    final pierceLevel = GameStorage.getSkillLevel('bullet_damage', shipId: currentShip.id);

    // Helper to spawn bullets
    void spawn(Vector2 offset, double angle, {
        BulletType type = BulletType.standard, 
        int dmg = 1, 
        double speedMult = 1.0, 
        double turnRate = 5.0, 
        Vector2? size,
        double freezeDur = 0,
        double slowAmt = 0,
        int chain = 0,
        double blast = 0,
        bool nuclear = false,
        int shards = 0,
        double proxRadius = 0,
        bool destroyProj = false,
    }) {
      // When boss is active, aim toward the boss instead of always upward
      Vector2 baseDir;
      if (bossActive && currentBoss != null) {
        baseDir = (currentBoss!.position - origin).normalized();
        final rotated = Vector2(
          baseDir.x * cos(angle) - baseDir.y * sin(angle),
          baseDir.x * sin(angle) + baseDir.y * cos(angle),
        );
        baseDir = rotated;
      } else {
        baseDir = Vector2(sin(angle), -cos(angle));
      }
      final vel = baseDir * (800 * speedBonus * speedMult);
      add(BulletComponent(
        position: origin + offset,
        velocity: vel,
        type: type,
        damage: dmg,
        penetrationCount: pierceLevel,
        color: currentShip.glowColor.withValues(alpha: 1.0),
        size: size ?? (type == BulletType.blackHole ? Vector2(40, 40) : Vector2(6, 18)),
        homingTurnRate: turnRate,
        freezeDuration: freezeDur,
        slowAmount: slowAmt,
        chainCount: chain,
        blastRadius: blast,
        isNuclear: nuclear,
        shardCount: shards,
        proximityRadius: proxRadius,
        destroyProjectiles: destroyProj,
      ));
    }

    // Logic for each WeaponType
    final levelData = getWeaponLevel();

    switch (currentShip.weaponType) {
      
      // 1. Nova Scout (Single Bullet)
      case WeaponType.singleBullet:
        final count = levelData.shots;
        final isPiercing = levelData.level >= 2;
        
        for (int i = 0; i < count; i++) {
            double angleOffset = 0;
            if (count > 1) {
                angleOffset = (i - (count - 1) / 2) * 0.1;
            }
            spawn(Vector2(angleOffset * 50, 0), angleOffset, type: isPiercing ? BulletType.piercing : BulletType.standard, dmg: levelData.damage, speedMult: 1.0 + (levelData.level * 0.1));
        }
        break;

      // 2. Storm Chaser
      case WeaponType.pulseCharge:
        final count = levelData.shots;
        final isExplosive = levelData.level >= 5;
        for(int i=0; i<count; i++) {
           double angleOffset = (i - (count-1)/2) * 0.05;
           spawn(Vector2(angleOffset * 40, 0), angleOffset, type: isExplosive ? BulletType.explosive : BulletType.standard, dmg: levelData.damage);
        }
        break;

      // 3. Comet Striker
      case WeaponType.ricochet:
        final count = levelData.shots;
        for(int i=0; i<count; i++) {
            double angle = 0.2 * (i % 2 == 0 ? 1 : -1) * (1 + i~/2);
            spawn(Vector2(0, 0), angle, type: BulletType.ricochet, dmg: levelData.damage, speedMult: 1.2);
        }
        break;

      // 4. Meteor Dash
      case WeaponType.shotgun:
        int pellets = levelData.shots;
        double spreadAngle = levelData.level >= 5 ? pi * 2 : 0.5;
        for(int i=0; i<pellets; i++) {
            double angle = (levelData.level >= 5) ? (i / pellets) * pi * 2 : (Random().nextDouble() - 0.5) * spreadAngle;
            spawn(Vector2(0, 0), angle, type: BulletType.standard, speedMult: 0.8 + Random().nextDouble()*0.4, dmg: levelData.damage, size: Vector2(6, 6));
        }
        break;

       // 7. Stellar Phantom (Gatling)
       case WeaponType.gatling:
        final isPhasing = levelData.level >= 5;
        spawn(Vector2(Random().nextDouble()*10 - 5, 0), 0, speedMult: 1.2 + (levelData.level * 0.1), type: isPhasing ? BulletType.piercing : BulletType.standard, dmg: levelData.damage);
        break;

      // 5. Aurora Wing (Frost Beam)
      case WeaponType.frostBeam:
        final count = levelData.shots;
        final freezeTime = (levelData.level >= 3) ? 1.5 : 0.5;
        final slow = (levelData.level >= 2) ? 0.5 : 0.2;
        for(int i=0; i<count; i++) {
             double angle = (i - (count-1)/2) * 0.05;
             spawn(Vector2(angle*20, 0), angle, type: BulletType.frost, dmg: levelData.damage, freezeDur: freezeTime, slowAmt: slow);
        }
        break;

      // 6. Nebula Spark (Seeker Darts)
      case WeaponType.seekerDarts:
        final count = levelData.shots;
        for(int i=0; i<count; i++) {
            double angle = (i - (count-1)/2) * 0.2;
            spawn(Vector2(angle*30, 0), angle, type: BulletType.homing, turnRate: 8.0, dmg: levelData.damage);
        }
        break;

      // 8. Quantum Racer (Wave Beam)
      case WeaponType.waveBeam:
        final count = levelData.shots;
        for(int i=0; i<count; i++) {
            double angle = (i - (count-1)/2) * 0.1;
            spawn(Vector2(angle*20, 0), angle, type: BulletType.wave, dmg: levelData.damage);
        }
        break;

      // 9. Nebula Cruiser (Rockets)
      case WeaponType.explosiveRockets:
        final count = levelData.shots;
        final isNuke = levelData.level >= 5;
        for(int i=0; i<count; i++) {
            double angle = (i - (count-1)/2) * 0.15;
            spawn(Vector2(angle*40, 0), angle, type: BulletType.explosive, speedMult: 0.6, dmg: levelData.damage, blast: 120.0 + (levelData.level * 20), nuclear: isNuke);
        }
        break;

      // 10. Cosmic Viper (Chain Lightning)
      case WeaponType.chainLightning:
         final count = levelData.shots;
         int chains = 2 + (levelData.level * 2);
         if (levelData.level >= 5) chains = 100; // Infinite
         for(int i=0; i<count; i++) {
             spawn(Vector2(0, 0), i*0.1, type: BulletType.lightning, speedMult: 2.0, dmg: levelData.damage, chain: chains);
         }
         break;

      // 11. Galaxy Titan (Temporal Laser)
      case WeaponType.temporalLaser:
         final count = levelData.shots;
         for(int i=0; i<count; i++) {
             spawn(Vector2((i - count/2)*10, 0), 0, type: BulletType.timeShatter, speedMult: 1.2, dmg: levelData.damage);
         }
         break;

      // 12. Void Reaper (Dimensional Blades)
      case WeaponType.dimensionalBlades:
         final count = levelData.shots;
         for(int i=0; i<count; i++) {
             double angle = (i % 2 == 0 ? 1 : -1) * 0.2 + (i*0.05);
             spawn(Vector2(i*10.0, 0), angle, type: BulletType.blade, speedMult: 0.8, dmg: levelData.damage);
         }
         break;

      // 13. Star Forge (Drone Swarm)
      case WeaponType.droneSwarm:
         spawn(Vector2(0, 0), 0, dmg: levelData.damage);
         break;

      // 14. Diamond Emperor (Crystal Shatter)
      case WeaponType.crystalShatter:
         final count = levelData.shots;
         int shards = levelData.level >= 5 ? 20 : 4;
         for(int i=0; i<count; i++) {
             spawn(Vector2(0, 0), (i - count/2)*0.1, type: BulletType.crystal, dmg: levelData.damage, shards: shards);
         }
         break;

      // 15. Plasma Phoenix (Inferno)
      case WeaponType.infernoFlamethrower:
         final count = levelData.shots;
         for(int i=0; i<count; i++) {
             double angle = (i - (count-1)/2) * 0.08;
             spawn(Vector2(angle*10, 0), angle, type: BulletType.flame, speedMult: 0.9, dmg: levelData.damage);
         }
         break;

      // 16. Void Sovereign (Gravity Pulse)
      case WeaponType.gravityPulse:
         // Gravity Well logic
         final lvl = levelData.level;
         spawn(Vector2(0, 0), 0, type: BulletType.blackHole, speedMult: 0.4, dmg: levelData.damage, proxRadius: 150.0 + (lvl*50), destroyProj: lvl >= 2);
         if (lvl >= 5) {
            // Secondary wells
            spawn(Vector2(-100, 0), -0.2, type: BulletType.blackHole, speedMult: 0.4, dmg: levelData.damage);
            spawn(Vector2(100, 0), 0.2, type: BulletType.blackHole, speedMult: 0.4, dmg: levelData.damage);
         }
         break;

      // 17. Chrono Destroyer (Mines)
      case WeaponType.mines:
         // Mines
         final mineDmg = levelData.level >= 2 ? 50 : 10;
         spawn(Vector2(0, 0), 0, type: BulletType.mine, speedMult: 0.0, dmg: mineDmg, proxRadius: 100);
         break;

       // 18. Astral Leviathan (Ion Cannon)
      case WeaponType.ionCannon:
         // Giant piercing shot
         final lvl = levelData.level;
         final width = 20.0 + (lvl * 10);
         spawn(Vector2(0, 0), 0, type: BulletType.piercing, size: Vector2(width, 100), dmg: levelData.damage, speedMult: 3.0);
         break;
      
      // 19. Infinity Colossus (Annihilation Wave)
      case WeaponType.annihilationWave:
         final count = levelData.shots;
         for(int i=0; i<count; i++) {
             double xOff = (i - (count-1)/2) * 20.0;
             spawn(Vector2(xOff, 0), 0, type: BulletType.wave, dmg: levelData.damage);
         }
         break;

      // 20. Celestial Warden (Holy Lance)
      case WeaponType.holyLance:
         spawn(Vector2(0, 0), 0, type: BulletType.piercing, speedMult: 2.5, dmg: levelData.damage, size: Vector2(10, 60));
         break;
      
      // 21. Abyssal Reaver (Void Tentacles)
      case WeaponType.voidTentacles:
         final count = levelData.shots;
         for(int i=0; i<count; i++) {
            double angle = (i - (count-1)/2) * 0.3;
            // High turn rate homing
            spawn(Vector2(angle*20, 0), angle, type: BulletType.homing, turnRate: 15.0, dmg: levelData.damage);
         }
         break;

      // 22. Quantum Harbinger (Reality Fracture)
      case WeaponType.realityFracture:
         spawn(Vector2(0, 0), 0, type: BulletType.timeShatter, size: Vector2(30,30), dmg: levelData.damage);
         // Echoes logic could be handled by spawning extras
         if (levelData.level >= 2) {
             spawn(Vector2(-30, 20), -0.1, type: BulletType.timeShatter, dmg: levelData.damage ~/ 2);
             spawn(Vector2(30, 20), 0.1, type: BulletType.timeShatter, dmg: levelData.damage ~/ 2);
         }
         break;

      // 23. Stellar Colossus (Star Core)
      case WeaponType.starCoreEruption:
         final lvl = levelData.level;
         final nuke = lvl >= 4;
         spawn(Vector2(0, 0), 0, type: BulletType.explosive, size: Vector2(40,40), dmg: levelData.damage, blast: 200.0 + (lvl * 50), nuclear: nuke);
         break;
      
      // 24. Eternal Sovereign (Cosmic Judgement)
      case WeaponType.cosmicJudgement:
         // Lightning that chains
         final lvl = levelData.level;
         spawn(Vector2(0, 0), 0, type: BulletType.lightning, size: Vector2(10, 100), dmg: levelData.damage, chain: 10 + lvl*2);
         break;

      // 25. Omega Nexus (Singularity Genesis)
      case WeaponType.singularityGenesis:
         final lvl = levelData.level;
         spawn(Vector2(0, 0), 0, type: BulletType.blackHole, size: Vector2(60,60), dmg: levelData.damage, proxRadius: 300, destroyProj: lvl >= 2);
         break;
    }
  }

  double _getFireCooldownForShip() {
    switch (currentShip.weaponType) {
      case WeaponType.gatling: 
        // Dynamic fire rate based on WeaponLevel
        // Base 0.1s -> L5 0.033s (30/s)
        final level = getWeaponLevel().level;
        if (level == 1) return 0.125; // 8/s
        if (level == 2) return 0.083; // 12/s
        if (level == 3) return 0.062; // 16/s
        if (level == 4) return 0.05;  // 20/s
        return 0.033;                 // 30/s
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
    
    _checkWeaponLevelUp();

    // No text alerts for Boss Rush (obstacles are disabled)
    if (gameMode == GameMode.bossRush) return;

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
    if (!coinsEnabled) return;
    int earned = (value * multiplier).ceil();

    // Skill tree bonus
    final coinValueLevel = GameStorage.getSkillLevel('coin_value', shipId: currentShip.id);
    earned = (earned * (1 + coinValueLevel * 0.05)).ceil();

    // Slightly reduced economy in classic/endless
    if (gameMode == GameMode.endless) {
      earned = (earned * 0.85).ceil();
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

    if (coinsEnabled) {
      // Slightly reduced economy in classic/endless
      if (gameMode == GameMode.endless) {
        reward = (reward * 0.85).ceil();
      }
      runCoins += reward;
    }
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
    // No stardust rewards in survivalHell, bossRush, gauntlet
    if (gameMode != GameMode.survivalHell && gameMode != GameMode.bossRush && gameMode != GameMode.gauntlet) {
      final divisor = gameMode == GameMode.endless ? 10 : 8;
      final bonus = (timeSurvived ~/ divisor);
      if (bonus > 0) GameStorage.addStardust(bonus);
    }
    GameStorage.updateAfterRun(
      distance: distance,
      coinsCollected: coinsEnabled ? runCoins : 0,
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
