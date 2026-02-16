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
enum GameMode { endless, zen, hardcore }

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

  // Active power-ups
  final Map<PowerUpType, double> activePowerUps = {};

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

  // Callbacks
  VoidCallback? onGameOver;
  VoidCallback? onPauseRequest;
  
  SpaceEscaperGame({this.overrideShipId});

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

    // Auto-activate one owned consumable of each type at run start
    if (GameStorage.useConsumable(ConsumableType.headStart.name)) {
      headStartActive = true;
    }
    if (GameStorage.useConsumable(ConsumableType.luckyClover.name)) {
      luckyCloverActive = true;
    }
    if (GameStorage.useConsumable(ConsumableType.shieldCharge.name)) {
      shieldChargeActive = true;
    }

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

    if (gameMode != GameMode.zen) {
      add(obstacleSpawner);
    }
    add(coinSpawner);

    // Enemy wave system
    waveSystem = EnemyWaveSystem();
    if (gameMode != GameMode.zen) {
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

    // Consumable effects
    if (headStartActive) {
      distance = 500;
      currentSpeed = baseSpeed * 1.3;
    }
    if (shieldChargeActive) {
      player.makeInvincible();
    }
    
    isLoaded = true;
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
  void update(double dt) {
    if (gameState != GameState.playing) return;
    super.update(dt);

    timeSurvived += dt;
    distance += currentSpeed * dt;

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
  }

  // ═══════════════════════════════════════
  //  POWER-UP SYSTEM
  // ═══════════════════════════════════════

  void activatePowerUp(PowerUpType type) {
    final info = getPowerUpInfo(type);
    double duration = info.duration;

    // Skill bonus
    final extLevel = GameStorage.getSkillLevel('powerup_duration');
    duration *= (1 + extLevel * 0.1);

    activePowerUps[type] = duration;
    powerUpsCollectedThisRun++;

    // Immediate effects
    switch (type) {
      case PowerUpType.shield:
        player.makeInvincible();
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
    if (bossActive || gameMode == GameMode.zen) return;
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

    // Persist defeated boss
    GameStorage.addDefeatedBoss(bossId);

    screenEffects.triggerShake(duration: 0.5, intensity: 15);
    screenEffects.triggerComboGlow();
    showBanner = true;
    bannerTimer = 3.0;
    bannerText = 'BOSS DEFEATED! +$reward COINS';
    bannerColor = const Color(0xFFFFD700);
  }

  // ═══════════════════════════════════════
  //  SHOOTING
  // ═══════════════════════════════════════

  void fireBullet() {
    if (gameState != GameState.playing) return;
    
    // Set Cooldown
    fireCooldownTimer = _getFireCooldownForShip();

    // Skill tree: fire rate reduction
    final fireRateLevel = GameStorage.getSkillLevel('fire_rate');
    fireCooldownTimer *= (1 - fireRateLevel * 0.05);

    // Plasma Phoenix kill streak boost
    if (currentShip.id == 'plasma_phoenix' && killStreak > 5) {
      fireCooldownTimer *= 0.8;
    }

    final origin = player.position.clone()..y -= 30;
    final damaged = hasPowerUp(PowerUpType.damageBoost);
    
    // Skill tree: bullet speed bonus
    final bsLevel = GameStorage.getSkillLevel('bullet_speed');
    final speedBonus = 1.0 + bsLevel * 0.05;

    // Helper to spawn bullets
    void spawn(Vector2 offset, double angle, {BulletType type = BulletType.standard, int dmg = 1, double speedMult = 1.0, double turnRate = 5.0, Vector2? size}) {
      final vel = Vector2(sin(angle), -cos(angle)) * (800 * speedBonus * speedMult);
      add(BulletComponent(
        position: origin + offset,
        velocity: vel,
        type: type,
        damage: dmg,
        color: currentShip.glowColor.withOpacity(1.0),
        size: size ?? (type == BulletType.blackHole ? Vector2(40, 40) : Vector2(6, 18)),
        homingTurnRate: turnRate,
      ));
    }

    // Logic for each WeaponType
    switch (currentShip.weaponType) {
      
      // 1. Nova Scout (Single Bullet)
      case WeaponType.singleBullet:
        spawn(Vector2(0, 0), 0);
        if (damaged) spawn(Vector2(10, 0), 0);
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

      default:
         spawn(Vector2(0, 0), 0);
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
    final coinValueLevel = GameStorage.getSkillLevel('coin_value');
    earned = (earned * (1 + coinValueLevel * 0.05)).ceil();

    // Lucky clover consumable
    if (luckyCloverActive) {
      earned = (earned * 1.2).ceil();
    }

    runCoins += earned;
    combo++;
    comboTimer = 2.0;

    // Skill tree combo duration bonus
    final comboDurLevel = GameStorage.getSkillLevel('combo_duration');
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
    final bountyLevel = GameStorage.getSkillLevel('alien_reward');
    reward += bountyLevel * 2;

    runCoins += reward;
    waveSystem.onEnemyDestroyed();

    // Kill Streak for Plasma Phoenix
    if (currentShip.id == 'plasma_phoenix') {
      killStreak++;
      killStreakTimer = 3.0;
    }
  }

  void playerHit() {
    if (player.invincible) return;
    if (player.phasing) return;

    // Skill tree: second wind
    final secondWindLevel = GameStorage.getSkillLevel('bonus_life');
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

    add(ExplosionComponent(position: player.position.clone(), color: const Color(0xFFFF6B35)));
    screenEffects.triggerShake(duration: 0.8, intensity: 20);
    gameState = GameState.gameOver;
    
    // Check if we need to revert ship (for test drive)
    // Actually we don't need to revert here, the UI will reload from storage next time
    
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
}
