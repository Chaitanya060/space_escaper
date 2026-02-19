import 'dart:ui';

enum WeaponType {
  singleBullet,
  pulseCharge,
  ricochet,
  shotgun,
  frostBeam,
  seekerDarts,
  gatling,
  waveBeam,
  explosiveRockets,
  chainLightning,
  temporalLaser,
  dimensionalBlades,
  droneSwarm,
  crystalShatter,
  infernoFlamethrower,
  gravityPulse,
  mines,
  ionCannon,
  annihilationWave,
  holyLance,
  voidTentacles,
  realityFracture,
  starCoreEruption,
  cosmicJudgement,
  singularityGenesis,
}

enum ActiveAbilityType {
  none,
  hyperBoost,         // Nova Scout
  thunderDash,        // Storm Chaser
  cometStorm,         // Comet Striker
  bulletCyclone,      // Stellar Phantom
  meteorSlam,         // Meteor Dash
  iceNova,            // Aurora Wing
  starSwarm,          // Nebula Spark
  timeDistortion,     // Quantum Racer
  missileRain,        // Nebula Cruiser
  lightningOverdrive, // Cosmic Viper
  fortressMode,       // Galaxy Titan
  shadowClone,        // Void Reaper
  // Legendary+
  supernovaBurst,     // Star Forge
  crystalCataclysm,   // Diamond Emperor
  phoenixDive,        // Plasma Phoenix
  blackHoleCollapse,  // Void Sovereign
  timeRewind,         // Chrono Destroyer
  astralWave,         // Astral Leviathan
  infinityPulse,      // Infinity Colossus
  judgmentRay,        // Celestial Warden
  abyssSurge,         // Abyssal Reaver
  dimensionalCollapse,// Quantum Harbinger
  supernova,          // Stellar Colossus
  cosmicRain,         // Eternal Sovereign
  genesisCollapse,    // Omega Nexus
}

enum PassiveType {
  none,
  magneticCore,      // +15% coin range
  staticBuildUp,     // chain lightning every 8 hits
  cometBounce,       // 25% extra bounce
  adrenalineMode,    // fire rate boost when low combo
  flameTrail,        // dash leaves fire
  frozenWeakness,    // slowed enemies +20% dmg
  curveGuidance,     // bullets adjust path
  phaseShield,       // 10% chance ignore damage
  blastAmplifier,    // explosion radius scales with combo
  overcharge,        // every 5th hit chains twice
  reinforcedHull,    // +30% shield duration
  soulHarvest,       // extend invincibility on kill
  // Legendary+
  coreIgnition,      // kill stacking drone damage
  reflectiveMatrix,  // 15% reflect bullets
  rebirthProtocol,   // once per game revive
  eventHorizon,      // nearby enemies slower
  temporalEcho,      // 20% repeat last shot
  cosmicShield,      // shield regen
  infiniteScaling,   // damage per 100 kills
  divineProtection,  // shield regen faster
  darknessAbsorb,    // gain shield on kill
  multiverseEcho,    // 2% duplicate shot
  solarSurge,        // stacking damage
  comboScaling,      // damage scales with combo
  absoluteDominance, // stats increase per boss kill
}

class WeaponUpgrade {
  final int distance;
  final String upgradeId; // 'double_shot', 'triple_shot', etc.
  final String label;

  const WeaponUpgrade(this.distance, this.upgradeId, this.label);
}

class WeaponLevelData {
  final int level;
  final String name;
  final int shots;
  final int damage;
  final int distanceThreshold;
  final String specialBonus;

  const WeaponLevelData({
    required this.level,
    required this.name,
    required this.shots,
    required this.damage,
    required this.distanceThreshold,
    this.specialBonus = '',
  });
}

class EvolutionData {
  final int distance;
  final int orbitCount;
  final Color orbitColor;
  final int orbitDamage;
  final String desc;
  final int secondTierDistance;
  final int secondTierOrbitCount;

  const EvolutionData({
    this.distance = 70000,
    this.orbitCount = 1,
    this.orbitColor = const Color(0xFF00D9FF),
    this.orbitDamage = 10,
    this.desc = '',
    this.secondTierDistance = 100000,
    this.secondTierOrbitCount = 2,
  });
}

class ShipData {
  final String id;
  final String name;
  final int cost; // If unlockMethod is 'purchase'
  final int adReq; // If unlockMethod is 'ads'
  final String description;
  final String abilityDesc; // Weapon description essentially
  final WeaponType weaponType;
  final String unlockMethod; // 'default', 'ads', 'purchase'
  final Color color;
  final Color glowColor;
  final double speedStat;
  final double agilityStat;
  final double shieldStat;
  final String rarity; // common, rare, epic, legendary, mythic, celestial
  final String trailType;
  final int shieldCircles; // 0 to 9

  // === NEW: Passive, Active, Evolution ===
  final PassiveType passiveType;
  final String passiveName;
  final String passiveDesc;
  final ActiveAbilityType activeType;
  final String activeName;
  final String activeDesc;
  final double activeCooldown; // seconds
  final double activeDuration; // seconds the effect lasts
  final List<WeaponUpgrade> weaponUpgrades;
  final List<WeaponLevelData> weaponLevels;
  final EvolutionData? evolution;

  const ShipData({
    required this.id,
    required this.name,
    this.cost = 0,
    this.adReq = 0,
    required this.description,
    required this.abilityDesc,
    required this.weaponType,
    required this.unlockMethod,
    required this.color,
    required this.glowColor,
    required this.speedStat,
    required this.agilityStat,
    required this.shieldStat,
    this.rarity = 'common',
    this.trailType = 'spark',
    this.shieldCircles = 0,
    this.passiveType = PassiveType.none,
    this.passiveName = '',
    this.passiveDesc = '',
    this.activeType = ActiveAbilityType.none,
    this.activeName = '',
    this.activeDesc = '',
    this.activeCooldown = 15.0,
    this.activeDuration = 2.0,
    this.weaponUpgrades = const [],
    this.weaponLevels = const [],
    this.evolution,
  });

  // Calculate test drive cost based on rarity/value
  int get testDriveCost {
    if (unlockMethod == 'default') return 0;
    if (unlockMethod == 'ads') return 20;
    if (cost < 5000) return 50;
    if (cost < 20000) return 100;
    if (cost < 100000) return 200;
    return 500;
  }

  String get ability => '';
}

const List<ShipData> ships = [
  // ─────────────── COMMON SHIPS ───────────────

  // 1. Nova Scout (FREE) — Balanced starter
  ShipData(
    id: 'nova_scout',
    name: 'Nova Scout',
    description: 'Balanced starter ship. Reliable and versatile.',
    abilityDesc: 'Pulse Blaster',
    weaponType: WeaponType.singleBullet,
    unlockMethod: 'default',
    color: Color(0xFF00D9FF),
    glowColor: Color(0x8000D9FF),
    speedStat: 5, agilityStat: 5, shieldStat: 5,
    rarity: 'common', trailType: 'spark',
    passiveType: PassiveType.magneticCore,
    passiveName: 'Magnetic Core',
    passiveDesc: '+15% coin collection range',
    activeType: ActiveAbilityType.hyperBoost,
    activeName: 'Hyper Boost',
    activeDesc: '2s speed boost, +30% fire rate',
    activeCooldown: 12.0, activeDuration: 2.0,
    weaponUpgrades: [],
    weaponLevels: [
      WeaponLevelData(level: 1, name: 'Basic Round', shots: 1, damage: 1, distanceThreshold: 0),
      WeaponLevelData(level: 2, name: 'Piercing Round', shots: 2, damage: 3, distanceThreshold: 8000, specialBonus: 'Ignores 25% armor'),
      WeaponLevelData(level: 3, name: 'Plasma Slug', shots: 3, damage: 7, distanceThreshold: 20000, specialBonus: 'Leaves burn trail'),
      WeaponLevelData(level: 4, name: 'Quantum Bullet', shots: 4, damage: 15, distanceThreshold: 40000, specialBonus: 'Phases through shields'),
      WeaponLevelData(level: 5, name: 'Void Sniper', shots: 5, damage: 32, distanceThreshold: 70000, specialBonus: 'Splits into 3 on impact'),
    ],
    evolution: EvolutionData(
      orbitCount: 1, orbitColor: Color(0xFF00D9FF), orbitDamage: 10,
      desc: '1 orbit micro-drone', secondTierOrbitCount: 2,
    ),
  ),

  // 2. Storm Chaser — Lightning striker
  ShipData(
    id: 'storm_chaser',
    name: 'Storm Chaser',
    adReq: 2,
    cost: 200,
    description: 'Lightning striker. Hold to charge a powerful burst.',
    abilityDesc: 'Charge Pulse Cannon',
    weaponType: WeaponType.pulseCharge,
    unlockMethod: 'purchase',
    color: Color(0xFF2979FF),
    glowColor: Color(0x802979FF),
    speedStat: 6, agilityStat: 6, shieldStat: 4,
    rarity: 'common', trailType: 'spark',
    passiveType: PassiveType.staticBuildUp,
    passiveName: 'Static Build-Up',
    passiveDesc: 'Every 8 hits triggers lightning chain',
    activeType: ActiveAbilityType.thunderDash,
    activeName: 'Thunder Dash',
    activeDesc: 'Dash forward damaging enemies',
    activeCooldown: 10.0, activeDuration: 0.5,

    weaponUpgrades: [],
    weaponLevels: [
      WeaponLevelData(level: 1, name: 'Pulse Burst', shots: 5, damage: 2, distanceThreshold: 0),
      WeaponLevelData(level: 2, name: 'Storm Burst', shots: 7, damage: 4, distanceThreshold: 8000, specialBonus: 'Chains to 1 nearby enemy'),
      WeaponLevelData(level: 3, name: 'Thunder Volley', shots: 10, damage: 8, distanceThreshold: 20000, specialBonus: 'Stuns enemy 0.5s'),
      WeaponLevelData(level: 4, name: 'Lightning Barrage', shots: 12, damage: 14, distanceThreshold: 40000, specialBonus: 'Arcs to 2 targets'),
      WeaponLevelData(level: 5, name: 'Omega Pulse', shots: 15, damage: 28, distanceThreshold: 70000, specialBonus: 'Massive AoE detonation'),
    ],
    evolution: EvolutionData(
      orbitCount: 1, orbitColor: Color(0xFFFFEB3B), orbitDamage: 12,
      desc: 'Electric orbit ball', secondTierOrbitCount: 2,
    ),
  ),

  // 3. Comet Striker — Ricochet specialist
  ShipData(
    id: 'comet_striker',
    name: 'Comet Striker',
    adReq: 4,
    cost: 400,
    description: 'Ricochet specialist. Bullets bounce off edges.',
    abilityDesc: 'Ricochet Blades',
    weaponType: WeaponType.ricochet,
    unlockMethod: 'purchase',
    color: Color(0xFF00E676),
    glowColor: Color(0x8000E676),
    speedStat: 7, agilityStat: 5, shieldStat: 5,
    rarity: 'common', trailType: 'plasma',
    passiveType: PassiveType.cometBounce,
    passiveName: 'Comet Bounce',
    passiveDesc: '25% chance for extra bounce',
    activeType: ActiveAbilityType.cometStorm,
    activeName: 'Comet Storm',
    activeDesc: '5 bouncing projectiles',
    activeCooldown: 14.0, activeDuration: 0.1,

    weaponUpgrades: [],
    weaponLevels: [
      WeaponLevelData(level: 1, name: 'Ricochet Shot', shots: 1, damage: 2, distanceThreshold: 0, specialBonus: '1 bounce'),
      WeaponLevelData(level: 2, name: 'Smart Bounce', shots: 2, damage: 5, distanceThreshold: 8000, specialBonus: '2 bounces, seeks enemy'),
      WeaponLevelData(level: 3, name: 'Triple Comet', shots: 3, damage: 10, distanceThreshold: 20000, specialBonus: '3 bounces, explodes on 3rd hit'),
      WeaponLevelData(level: 4, name: 'Chaos Comet', shots: 4, damage: 20, distanceThreshold: 40000, specialBonus: '4 bounces, fire trail'),
      WeaponLevelData(level: 5, name: 'Eternal Comet', shots: 6, damage: 40, distanceThreshold: 70000, specialBonus: 'Infinite bounces, loops screen'),
    ],
    evolution: EvolutionData(
      orbitCount: 1, orbitColor: Color(0xFFFF9100), orbitDamage: 15,
      desc: 'Orbit sphere causes explosion on contact',
      secondTierOrbitCount: 2,
    ),
  ),

  // 4. Stellar Phantom — Rapid fire DPS
  ShipData(
    id: 'stellar_phantom',
    name: 'Stellar Phantom',
    cost: 300,
    description: 'Rapid-fire DPS machine gun.',
    abilityDesc: 'Gatling Barrage',
    weaponType: WeaponType.gatling,
    unlockMethod: 'purchase',
    color: Color(0xFFA855F7),
    glowColor: Color(0x80A855F7),
    speedStat: 7, agilityStat: 6, shieldStat: 3,
    rarity: 'common', trailType: 'smoke',
    passiveType: PassiveType.adrenalineMode,
    passiveName: 'Adrenaline Mode',
    passiveDesc: 'Fire rate +40% when combo < 5',
    activeType: ActiveAbilityType.bulletCyclone,
    activeName: 'Bullet Cyclone',
    activeDesc: '360° bullet burst',
    activeCooldown: 15.0, activeDuration: 0.1,

    weaponUpgrades: [],
    weaponLevels: [
      WeaponLevelData(level: 1, name: 'Gatling Fire', shots: 1, damage: 1, distanceThreshold: 0, specialBonus: '8/s fire rate'),
      WeaponLevelData(level: 2, name: 'Twin Barrels', shots: 1, damage: 2, distanceThreshold: 8000, specialBonus: '12/s fire rate, ignores 15% armor'),
      WeaponLevelData(level: 3, name: 'Phantom Barrage', shots: 1, damage: 4, distanceThreshold: 20000, specialBonus: '16/s fire rate, tracer rounds mark enemy'),
      WeaponLevelData(level: 4, name: 'Ghost Shredder', shots: 1, damage: 7, distanceThreshold: 40000, specialBonus: '20/s fire rate, overheat mode'),
      WeaponLevelData(level: 5, name: 'Spectral Annihilator', shots: 1, damage: 14, distanceThreshold: 70000, specialBonus: '30/s fire rate, phases shields'),
    ],
    evolution: EvolutionData(
      orbitCount: 1, orbitColor: Color(0xFFA855F7), orbitDamage: 8,
      desc: 'Orbit shield reduces damage 15%',
      secondTierOrbitCount: 2,
    ),
  ),

  // ─────────────── RARE SHIPS ───────────────

  // 5. Meteor Dash — Close combat brawler
  ShipData(
    id: 'meteor_dash',
    name: 'Meteor Dash',
    adReq: 6,
    cost: 600,
    description: 'Close combat brawler. Short range shotgun spray.',
    abilityDesc: 'Scatter Cannon',
    weaponType: WeaponType.shotgun,
    unlockMethod: 'purchase',
    color: Color(0xFFFF9100),
    glowColor: Color(0x80FF9100),
    speedStat: 8, agilityStat: 4, shieldStat: 6,
    rarity: 'rare', trailType: 'flame',
    passiveType: PassiveType.flameTrail,
    passiveName: 'Flame Trail',
    passiveDesc: 'Dash leaves fire damage trail',
    activeType: ActiveAbilityType.meteorSlam,
    activeName: 'Meteor Slam',
    activeDesc: 'AoE impact damage',
    activeCooldown: 12.0, activeDuration: 0.1,
    weaponUpgrades: [],
    weaponLevels: [
      WeaponLevelData(level: 1, name: 'Scatter Shot', shots: 6, damage: 1, distanceThreshold: 0, specialBonus: 'Random spread'),
      WeaponLevelData(level: 2, name: 'Heavy Buckshot', shots: 8, damage: 3, distanceThreshold: 8000, specialBonus: 'Knockback on all pellets'),
      WeaponLevelData(level: 3, name: 'Dragon Breath', shots: 10, damage: 6, distanceThreshold: 20000, specialBonus: 'Pellets burn for 2s'),
      WeaponLevelData(level: 4, name: 'Meteor Cluster', shots: 13, damage: 12, distanceThreshold: 40000, specialBonus: 'Micro-explosions on contact'),
      WeaponLevelData(level: 5, name: 'Supernova Blast', shots: 18, damage: 25, distanceThreshold: 70000, specialBonus: '360° full-circle explosion'),
    ],
    evolution: EvolutionData(
      orbitCount: 2, orbitColor: Color(0xFFFF5722), orbitDamage: 15,
      desc: '2 fire orbit spheres (burn damage)',
      secondTierOrbitCount: 3,
    ),
  ),

  // 6. Aurora Wing — Freeze controller
  ShipData(
    id: 'aurora_wing',
    name: 'Aurora Wing',
    adReq: 8,
    cost: 800,
    description: 'Freeze controller. Continuous beam that slows enemies.',
    abilityDesc: 'Frost Beam',
    weaponType: WeaponType.frostBeam,
    unlockMethod: 'purchase',
    color: Color(0xFF18FFFF),
    glowColor: Color(0x8018FFFF),
    speedStat: 6, agilityStat: 8, shieldStat: 5,
    rarity: 'rare', trailType: 'wisp',
    passiveType: PassiveType.frozenWeakness,
    passiveName: 'Frozen Weakness',
    passiveDesc: 'Slowed enemies take +20% damage',
    activeType: ActiveAbilityType.iceNova,
    activeName: 'Ice Nova',
    activeDesc: 'Freezes enemies for 1.5 sec',
    activeCooldown: 18.0, activeDuration: 1.5,
    weaponUpgrades: [],
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Frost Beam', shots: 1, damage: 1, distanceThreshold: 0, specialBonus: 'Slows 20%'),
      const WeaponLevelData(level: 2, name: 'Blizzard Ray', shots: 1, damage: 3, distanceThreshold: 8000, specialBonus: 'Slows 50%, shatters on freeze'),
      const WeaponLevelData(level: 3, name: 'Arctic Lance', shots: 2, damage: 7, distanceThreshold: 20000, specialBonus: 'Full freeze 1.5s, AoE shards'),
      const WeaponLevelData(level: 4, name: 'Polar Vortex', shots: 2, damage: 14, distanceThreshold: 40000, specialBonus: 'Ice storm radius, pulls enemies in'),
      const WeaponLevelData(level: 5, name: 'Absolute Zero', shots: 3, damage: 28, distanceThreshold: 70000, specialBonus: 'Frozen enemies take x3 damage'),
    ],
    evolution: EvolutionData(
      orbitCount: 2, orbitColor: Color(0xFF18FFFF), orbitDamage: 8,
      desc: 'Ice shards orbit, freeze on contact',
      secondTierOrbitCount: 3,
    ),
  ),

  // 7. Nebula Spark — Auto targeting
  ShipData(
    id: 'nebula_spark',
    name: 'Nebula Spark',
    adReq: 10,
    cost: 1000,
    description: 'Auto targeting ship. Homing darts.',
    abilityDesc: 'Seeker Darts',
    weaponType: WeaponType.seekerDarts,
    unlockMethod: 'purchase',
    color: Color(0xFFFFEA00),
    glowColor: Color(0x80FFEA00),
    speedStat: 5, agilityStat: 9, shieldStat: 4,
    rarity: 'rare', trailType: 'spark',
    passiveType: PassiveType.curveGuidance,
    passiveName: 'Curve Guidance',
    passiveDesc: 'Bullets slightly adjust path',
    activeType: ActiveAbilityType.starSwarm,
    activeName: 'Star Swarm',
    activeDesc: '8 homing missiles',
    activeCooldown: 16.0, activeDuration: 0.1,
    weaponUpgrades: [],
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Seeker Darts', shots: 3, damage: 1, distanceThreshold: 0, specialBonus: 'Single-target homing'),
      const WeaponLevelData(level: 2, name: 'Smart Missiles', shots: 5, damage: 3, distanceThreshold: 8000, specialBonus: 'Splits into 2 on impact'),
      const WeaponLevelData(level: 3, name: 'Hunter Swarm', shots: 7, damage: 6, distanceThreshold: 20000, specialBonus: 'Locks onto 3 different targets'),
      const WeaponLevelData(level: 4, name: 'Nemesis Cluster', shots: 10, damage: 12, distanceThreshold: 40000, specialBonus: 'Each dart explodes on contact'),
      const WeaponLevelData(level: 5, name: 'Oblivion Swarm', shots: 15, damage: 25, distanceThreshold: 70000, specialBonus: 'Darts respawn once if missed'),
    ],
    evolution: EvolutionData(
      orbitCount: 2, orbitColor: Color(0xFFFFEA00), orbitDamage: 10,
      desc: 'Orbit drones auto-target enemies',
      secondTierOrbitCount: 3,
    ),
  ),

  // 8. Quantum Racer — Phase damage ship
  ShipData(
    id: 'quantum_racer',
    name: 'Quantum Racer',
    cost: 800,
    description: 'Phase damage ship. Oscillating wave beam pierces enemies.',
    abilityDesc: 'Wave Beam',
    weaponType: WeaponType.waveBeam,
    unlockMethod: 'purchase',
    color: Color(0xFF22D3EE),
    glowColor: Color(0x8022D3EE),
    speedStat: 8, agilityStat: 8, shieldStat: 4,
    rarity: 'rare', trailType: 'bolt',
    passiveType: PassiveType.phaseShield,
    passiveName: 'Phase Shield',
    passiveDesc: '10% chance to ignore damage',
    activeType: ActiveAbilityType.timeDistortion,
    activeName: 'Time Distortion',
    activeDesc: 'Slow all enemies for 3s',
    activeCooldown: 20.0, activeDuration: 3.0,
    weaponUpgrades: [],
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Wave Shot', shots: 2, damage: 2, distanceThreshold: 0, specialBonus: 'Passes through walls'),
      const WeaponLevelData(level: 2, name: 'Resonance Beam', shots: 3, damage: 5, distanceThreshold: 8000, specialBonus: 'Stacks deal +50% on 2nd hit'),
      const WeaponLevelData(level: 3, name: 'Tsunami Pulse', shots: 4, damage: 10, distanceThreshold: 20000, specialBonus: 'Pulls all enemies toward center'),
      const WeaponLevelData(level: 4, name: 'Quantum Cascade', shots: 5, damage: 20, distanceThreshold: 40000, specialBonus: 'Destroys enemy shields instantly'),
      const WeaponLevelData(level: 5, name: 'Reality Wave', shots: 6, damage: 40, distanceThreshold: 70000, specialBonus: 'Dimensional rift dmg zone'),
    ],
    evolution: EvolutionData(
      orbitCount: 2, orbitColor: Color(0xFF22D3EE), orbitDamage: 12,
      desc: 'Orbit spheres deal true damage',
      secondTierOrbitCount: 3,
    ),
  ),

  // 9. Nebula Cruiser — Heavy artillery
  ShipData(
    id: 'nebula_cruiser',
    name: 'Nebula Cruiser',
    cost: 1500,
    description: 'Heavy artillery. Slow rockets with large AoE.',
    abilityDesc: 'Explosive Rockets',
    weaponType: WeaponType.explosiveRockets,
    unlockMethod: 'purchase',
    color: Color(0xFF34D399),
    glowColor: Color(0x8034D399),
    speedStat: 4, agilityStat: 4, shieldStat: 8,
    rarity: 'rare', trailType: 'spark',
    passiveType: PassiveType.blastAmplifier,
    passiveName: 'Blast Amplifier',
    passiveDesc: 'Explosion radius increases per combo',
    activeType: ActiveAbilityType.missileRain,
    activeName: 'Missile Rain',
    activeDesc: '6 rockets launched',
    activeCooldown: 14.0, activeDuration: 0.1,
    weaponUpgrades: [],
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Rocket Strike', shots: 1, damage: 5, distanceThreshold: 0, specialBonus: '5m blast radius'),
      const WeaponLevelData(level: 2, name: 'Cluster Rocket', shots: 2, damage: 12, distanceThreshold: 8000, specialBonus: 'Releases 4 bomblets'),
      const WeaponLevelData(level: 3, name: 'Hellfire Salvo', shots: 3, damage: 25, distanceThreshold: 20000, specialBonus: 'Napalm burn zone 3s'),
      const WeaponLevelData(level: 4, name: 'Nova Warhead', shots: 4, damage: 50, distanceThreshold: 40000, specialBonus: 'EMP disables enemies'),
      const WeaponLevelData(level: 5, name: 'Doomsday Payload', shots: 6, damage: 100, distanceThreshold: 70000, specialBonus: 'Nuclear mushroom screen wipe'),
    ],
    evolution: EvolutionData(
      orbitCount: 2, orbitColor: Color(0xFF34D399), orbitDamage: 15,
      desc: 'Orbit mines detonate on proximity',
      secondTierOrbitCount: 3,
    ),
  ),

  // ─────────────── EPIC SHIPS ───────────────

  // 10. Cosmic Viper — Chain damage king
  ShipData(
    id: 'cosmic_viper',
    name: 'Cosmic Viper',
    cost: 3000,
    description: 'Chain damage king. Electric arc jumps between enemies.',
    abilityDesc: 'Chain Lightning Beam',
    weaponType: WeaponType.chainLightning,
    unlockMethod: 'purchase',
    color: Color(0xFFD500F9),
    glowColor: Color(0x80D500F9),
    speedStat: 7, agilityStat: 7, shieldStat: 5,
    rarity: 'epic', trailType: 'plasma',
    passiveType: PassiveType.overcharge,
    passiveName: 'Overcharge',
    passiveDesc: 'Every 5th hit chains twice',
    activeType: ActiveAbilityType.lightningOverdrive,
    activeName: 'Lightning Overdrive',
    activeDesc: 'Chain lightning burst',
    activeCooldown: 15.0, activeDuration: 3.0,
    weaponUpgrades: [],
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Chain Lightning', shots: 1, damage: 3, distanceThreshold: 0, specialBonus: 'Chains 2 targets'),
      const WeaponLevelData(level: 2, name: 'Arc Storm', shots: 1, damage: 8, distanceThreshold: 8000, specialBonus: 'Chains 4 targets, +2 dmg per jump'),
      const WeaponLevelData(level: 3, name: 'Tesla Surge', shots: 2, damage: 16, distanceThreshold: 20000, specialBonus: 'Stuns chained enemies'),
      const WeaponLevelData(level: 4, name: 'Superconductor', shots: 2, damage: 30, distanceThreshold: 40000, specialBonus: 'Chains 8 targets, full screen'),
      const WeaponLevelData(level: 5, name: 'Zeus Protocol', shots: 3, damage: 60, distanceThreshold: 70000, specialBonus: 'Infinite chain logic'),
    ],
    evolution: EvolutionData(
      orbitCount: 3, orbitColor: Color(0xFFD500F9), orbitDamage: 12,
      desc: '3 electric orbit cores',
      secondTierOrbitCount: 4,
    ),
  ),

  // 11. Galaxy Titan — Tank ship
  ShipData(
    id: 'galaxy_titan',
    name: 'Galaxy Titan',
    cost: 6000,
    description: 'Tank ship. Maximum survivability.',
    abilityDesc: 'Heavy Plasma Cannon',
    weaponType: WeaponType.temporalLaser,
    unlockMethod: 'purchase',
    color: Color(0xFFF472B6),
    glowColor: Color(0x80F472B6),
    speedStat: 4, agilityStat: 3, shieldStat: 9,
    rarity: 'epic', trailType: 'smoke',
    passiveType: PassiveType.reinforcedHull,
    passiveName: 'Reinforced Hull',
    passiveDesc: '+30% shield duration',
    activeType: ActiveAbilityType.fortressMode,
    activeName: 'Fortress Mode',
    activeDesc: '2 sec invincible',
    activeCooldown: 20.0, activeDuration: 2.0,
    weaponUpgrades: [],
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Plasma Cannon', shots: 1, damage: 5, distanceThreshold: 0, specialBonus: 'Slows enemies 10%'),
      const WeaponLevelData(level: 2, name: 'Heavy Plasma', shots: 1, damage: 12, distanceThreshold: 8000, specialBonus: 'Pierces 1 enemy'),
      const WeaponLevelData(level: 3, name: 'Titan Beam', shots: 2, damage: 25, distanceThreshold: 20000, specialBonus: 'Explodes on impact'),
      const WeaponLevelData(level: 4, name: 'Fortress Blast', shots: 2, damage: 50, distanceThreshold: 40000, specialBonus: 'Creates temporary shield wall'),
      const WeaponLevelData(level: 5, name: 'Omega Cannon', shots: 3, damage: 100, distanceThreshold: 70000, specialBonus: 'Massive AoE, stuns all'),
    ],
    evolution: EvolutionData(
      orbitCount: 3, orbitColor: Color(0xFFF472B6), orbitDamage: 10,
      desc: '3 large protective spheres',
      secondTierOrbitCount: 4,
    ),
  ),

  // 12. Void Reaper — Life steal assassin
  ShipData(
    id: 'void_reaper',
    name: 'Void Reaper',
    cost: 10000,
    description: 'Life steal assassin. Energy blades orbit and slash.',
    abilityDesc: 'Dimensional Blades',
    weaponType: WeaponType.dimensionalBlades,
    unlockMethod: 'purchase',
    color: Color(0xFFEF4444),
    glowColor: Color(0x80EF4444),
    speedStat: 8, agilityStat: 7, shieldStat: 5,
    rarity: 'epic', trailType: 'wisp',
    passiveType: PassiveType.soulHarvest,
    passiveName: 'Soul Harvest',
    passiveDesc: 'Heal on kill (extend invincibility)',
    activeType: ActiveAbilityType.shadowClone,
    activeName: 'Shadow Clone',
    activeDesc: 'Double attack rate for 3s',
    activeCooldown: 18.0, activeDuration: 3.0,
    weaponUpgrades: [],
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Dimension Blades', shots: 2, damage: 4, distanceThreshold: 0, specialBonus: 'Ignores 20% defense'),
      const WeaponLevelData(level: 2, name: 'Void Slash', shots: 3, damage: 10, distanceThreshold: 8000, specialBonus: 'Bleed 3 dmg/s'),
      const WeaponLevelData(level: 3, name: 'Rift Cutter', shots: 4, damage: 20, distanceThreshold: 20000, specialBonus: 'Ignores 100% armor'),
      const WeaponLevelData(level: 4, name: 'Soul Slice', shots: 5, damage: 40, distanceThreshold: 40000, specialBonus: 'Cuts shields into health'),
      const WeaponLevelData(level: 5, name: 'Soul Severance', shots: 8, damage: 80, distanceThreshold: 70000, specialBonus: 'Hits 3x per swing (multiverse)'),
    ],
    evolution: EvolutionData(
      orbitCount: 2, orbitColor: Color(0xFFEF4444), orbitDamage: 15,
      desc: 'Dark orbit spheres absorb bullets',
      secondTierOrbitCount: 3,
    ),
  ),

  // ─────────────── LEGENDARY SHIPS ───────────────

  // 13. Star Forge — Sustained scaling DPS
  ShipData(
    id: 'star_forge',
    name: 'Star Forge',
    cost: 15000,
    description: 'Stellar drones auto-fire. Kills stack drone damage permanently.',
    abilityDesc: 'Stellar Drone Array',
    weaponType: WeaponType.droneSwarm,
    unlockMethod: 'purchase',
    color: Color(0xFFFFB300),
    glowColor: Color(0x80FFB300),
    speedStat: 6, agilityStat: 5, shieldStat: 8,
    rarity: 'legendary', trailType: 'flame',
    passiveType: PassiveType.coreIgnition,
    passiveName: 'Core Ignition',
    passiveDesc: 'Every 15 kills boosts drone damage permanently',
    activeType: ActiveAbilityType.supernovaBurst,
    activeName: 'Supernova Burst',
    activeDesc: 'Drones merge into giant star explosion',
    activeCooldown: 20.0, activeDuration: 0.1,
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Forge Shot', shots: 1, damage: 2, distanceThreshold: 0, specialBonus: '2 Drones (5 dmg)'),
      const WeaponLevelData(level: 2, name: 'Swarm Launch', shots: 1, damage: 5, distanceThreshold: 8000, specialBonus: '4 Drones (12 dmg)'),
      const WeaponLevelData(level: 3, name: 'Battle Forge', shots: 1, damage: 12, distanceThreshold: 20000, specialBonus: '6 Drones (25 dmg) + Repair'),
      const WeaponLevelData(level: 4, name: 'Forge Armada', shots: 1, damage: 25, distanceThreshold: 40000, specialBonus: '8 Drones (50 dmg) + Shield'),
      const WeaponLevelData(level: 5, name: 'Legion Genesis', shots: 1, damage: 50, distanceThreshold: 70000, specialBonus: '12 Drones (100 dmg) + Replicate'),
    ],
    evolution: EvolutionData(
      orbitCount: 3, orbitColor: Color(0xFFFFD54F), orbitDamage: 15,
      desc: '3 orbit mini-stars',
      secondTierDistance: 120000, secondTierOrbitCount: 5,
    ),
  ),

  // 14. Diamond Emperor — High precision burst
  ShipData(
    id: 'diamond_emperor',
    name: 'Diamond Emperor',
    cost: 22000,
    description: 'Crystal shards split on impact. 15% chance to reflect bullets.',
    abilityDesc: 'Crystal Shatter Cannon',
    weaponType: WeaponType.crystalShatter,
    unlockMethod: 'purchase',
    color: Color(0xFFB9F2FF),
    glowColor: Color(0x80B9F2FF),
    speedStat: 9, agilityStat: 8, shieldStat: 9,
    rarity: 'legendary', trailType: 'bolt',
    passiveType: PassiveType.reflectiveMatrix,
    passiveName: 'Reflective Matrix',
    passiveDesc: '15% chance to reflect incoming bullets',
    activeType: ActiveAbilityType.crystalCataclysm,
    activeName: 'Crystal Cataclysm',
    activeDesc: 'Giant crystal spike erupts forward',
    activeCooldown: 16.0, activeDuration: 0.1,
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Crystal Shot', shots: 1, damage: 5, distanceThreshold: 0, specialBonus: 'Shatters -> 4 shards'),
      const WeaponLevelData(level: 2, name: 'Diamond Burst', shots: 1, damage: 12, distanceThreshold: 8000, specialBonus: 'Refracts into lasers'),
      const WeaponLevelData(level: 3, name: 'Prism Cannon', shots: 2, damage: 25, distanceThreshold: 20000, specialBonus: 'Beams bounce 3x'),
      const WeaponLevelData(level: 4, name: 'Emperor\'s Gaze', shots: 2, damage: 50, distanceThreshold: 40000, specialBonus: 'Crystal armor 30% resist'),
      const WeaponLevelData(level: 5, name: 'Prismatic Doom', shots: 3, damage: 100, distanceThreshold: 70000, specialBonus: '1000 Shard Screen Fill'),
    ],
    evolution: EvolutionData(
      orbitCount: 2, orbitColor: Color(0xFFE0F7FA), orbitDamage: 15,
      desc: 'Diamond orbit shards',
      secondTierDistance: 100000, secondTierOrbitCount: 4,
    ),
  ),

  // 15. Plasma Phoenix — High risk high speed
  ShipData(
    id: 'plasma_phoenix',
    name: 'Plasma Phoenix',
    cost: 35000,
    description: 'Continuous plasma stream. Revive once per game.',
    abilityDesc: 'Inferno Flamethrower',
    weaponType: WeaponType.infernoFlamethrower,
    unlockMethod: 'purchase',
    color: Color(0xFFFF3D00),
    glowColor: Color(0x80FF3D00),
    speedStat: 10, agilityStat: 8, shieldStat: 6,
    rarity: 'legendary', trailType: 'flame',
    passiveType: PassiveType.rebirthProtocol,
    passiveName: 'Rebirth Protocol',
    passiveDesc: 'Once per game revive on death',
    activeType: ActiveAbilityType.phoenixDive,
    activeName: 'Phoenix Dive',
    activeDesc: 'Dive attack leaving fire vortex',
    activeCooldown: 18.0, activeDuration: 0.5,
    evolution: EvolutionData(
      orbitCount: 2, orbitColor: Color(0xFFFF5722), orbitDamage: 18,
      desc: 'Fire orbit cores',
      secondTierDistance: 120000, secondTierOrbitCount: 4,
    ),
  ),

  // 16. Void Sovereign — Control + tank
  ShipData(
    id: 'void_sovereign',
    name: 'Void Sovereign',
    cost: 50000,
    description: 'Gravity cannon pulls enemies inward. Nearby enemies slowed.',
    abilityDesc: 'Gravity Cannon',
    weaponType: WeaponType.gravityPulse,
    unlockMethod: 'purchase',
    color: Color(0xFF6200EA),
    glowColor: Color(0x806200EA),
    speedStat: 8, agilityStat: 7, shieldStat: 10,
    rarity: 'legendary', trailType: 'wisp',
    passiveType: PassiveType.eventHorizon,
    passiveName: 'Event Horizon',
    passiveDesc: 'Nearby enemies move slower',
    activeType: ActiveAbilityType.blackHoleCollapse,
    activeName: 'Black Hole Collapse',
    activeDesc: 'Create mini black hole',
    activeCooldown: 22.0, activeDuration: 2.0,
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Event Horizon', shots: 1, damage: 3, distanceThreshold: 0, specialBonus: 'Gravity Well 4s (60 total dmg)'),
      const WeaponLevelData(level: 2, name: 'Singularity', shots: 1, damage: 3, distanceThreshold: 10000, specialBonus: 'Well 5s (140 dmg) + Anti-Proj'),
      const WeaponLevelData(level: 3, name: 'Collapse', shots: 1, damage: 3, distanceThreshold: 25000, specialBonus: 'Well 6s (300 dmg) + Crush Weak'),
      const WeaponLevelData(level: 4, name: 'Supermassive', shots: 1, damage: 3, distanceThreshold: 50000, specialBonus: 'Well 7s (600 dmg) + Collision Dmg'),
      const WeaponLevelData(level: 5, name: 'Galactic Core', shots: 1, damage: 3, distanceThreshold: 80000, specialBonus: 'Well 10s (1200 dmg) + Secondary Wells'),
    ],
    evolution: EvolutionData(
      orbitCount: 3, orbitColor: Color(0xFF7C4DFF), orbitDamage: 12,
      desc: 'Dark orbit spheres absorb bullets',
      secondTierDistance: 150000, secondTierOrbitCount: 5,
    ),
  ),

  // ─────────────── MYTHIC SHIPS ───────────────

  // 17. Chrono Destroyer — Advanced tactical control
  ShipData(
    id: 'chrono_destroyer',
    name: 'Chrono Destroyer',
    cost: 70000,
    description: 'Time mines explode after delay. 20% chance to repeat last shot.',
    abilityDesc: 'Time Rift Mines',
    weaponType: WeaponType.mines,
    unlockMethod: 'purchase',
    color: Color(0xFF00BFA5),
    glowColor: Color(0x8000BFA5),
    speedStat: 9, agilityStat: 9, shieldStat: 8,
    rarity: 'mythic', trailType: 'plasma',
    shieldCircles: 1,
    passiveType: PassiveType.temporalEcho,
    passiveName: 'Temporal Echo',
    passiveDesc: '20% chance to repeat last shot',
    activeType: ActiveAbilityType.timeRewind,
    activeName: 'Time Rewind',
    activeDesc: 'Rewind 2 seconds of damage',
    activeCooldown: 25.0, activeDuration: 0.1,
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Time Mine', shots: 1, damage: 10, distanceThreshold: 0, specialBonus: 'Rewind 2s'),
      const WeaponLevelData(level: 2, name: 'Temporal Charge', shots: 1, damage: 10, distanceThreshold: 10000, specialBonus: 'Rewind 3s + Bomb (50 dmg)'),
      const WeaponLevelData(level: 3, name: 'Rift Bomb', shots: 1, damage: 10, distanceThreshold: 25000, specialBonus: 'Rewind 4s + Bomb (120 dmg)'),
      const WeaponLevelData(level: 4, name: 'Chrono Trigger', shots: 1, damage: 10, distanceThreshold: 50000, specialBonus: 'Rewind 5s + Bomb (250 dmg) + Stun'),
      const WeaponLevelData(level: 5, name: 'Timeline Collapse', shots: 1, damage: 10, distanceThreshold: 80000, specialBonus: 'Rewind 7s + Bomb (500 dmg) + Clone'),
    ],
    evolution: EvolutionData(
      orbitCount: 2, orbitColor: Color(0xFF1DE9B6), orbitDamage: 20,
      desc: 'Orbit time rings',
      secondTierDistance: 120000, secondTierOrbitCount: 4,
    ),
  ),

  // 18. Astral Leviathan — Sustained tank
  ShipData(
    id: 'astral_leviathan',
    name: 'Astral Leviathan',
    cost: 95000,
    description: 'Side cannons auto-fire. Shield regenerates slowly.',
    abilityDesc: 'Orbital Ion Cannons',
    weaponType: WeaponType.ionCannon,
    unlockMethod: 'purchase',
    color: Color(0xFF304FFE),
    glowColor: Color(0x80304FFE),
    speedStat: 7, agilityStat: 7, shieldStat: 10,
    rarity: 'mythic', trailType: 'bolt',
    shieldCircles: 2,
    passiveType: PassiveType.cosmicShield,
    passiveName: 'Cosmic Shield',
    passiveDesc: 'Shield regenerates slowly over time',
    activeType: ActiveAbilityType.astralWave,
    activeName: 'Astral Wave',
    activeDesc: 'Massive expanding energy wave',
    activeCooldown: 20.0, activeDuration: 0.1,
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Ion Beam', shots: 1, damage: 20, distanceThreshold: 0, specialBonus: 'Beam 300 dmg'),
      const WeaponLevelData(level: 2, name: 'Heavy Ion', shots: 1, damage: 20, distanceThreshold: 10000, specialBonus: 'Beam 600 dmg + Pierce'),
      const WeaponLevelData(level: 3, name: 'Orbital Strike', shots: 1, damage: 20, distanceThreshold: 25000, specialBonus: 'Beam 1200 dmg + Burn Path'),
      const WeaponLevelData(level: 4, name: 'Constellation Fire', shots: 1, damage: 20, distanceThreshold: 50000, specialBonus: 'Beam 2500 dmg + Stun'),
      const WeaponLevelData(level: 5, name: 'Galaxy Breaker', shots: 1, damage: 20, distanceThreshold: 80000, specialBonus: 'Beam 5000 dmg + Screen Wipe'),
    ],
    evolution: EvolutionData(
      orbitCount: 4, orbitColor: Color(0xFF536DFE), orbitDamage: 18,
      desc: '4 orbit celestial orbs',
      secondTierDistance: 120000, secondTierOrbitCount: 6,
    ),
  ),

  // 19. Infinity Colossus — Endgame scaling monster
  ShipData(
    id: 'infinity_colossus',
    name: 'Infinity Colossus',
    cost: 125000,
    description: 'Continuous piercing beam. Damage increases per 100 kills.',
    abilityDesc: 'Annihilation Beam',
    weaponType: WeaponType.annihilationWave,
    unlockMethod: 'purchase',
    color: Color(0xFFFFFFFF),
    glowColor: Color(0x80FFFFFF),
    speedStat: 8, agilityStat: 8, shieldStat: 10,
    rarity: 'mythic', trailType: 'plasma',
    shieldCircles: 3,
    passiveType: PassiveType.infiniteScaling,
    passiveName: 'Infinite Scaling',
    passiveDesc: 'Damage increases per 100 kills',
    activeType: ActiveAbilityType.infinityPulse,
    activeName: 'Infinity Pulse',
    activeDesc: 'Global damage burst',
    activeCooldown: 22.0, activeDuration: 0.1,
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Wave Fire', shots: 6, damage: 10, distanceThreshold: 0, specialBonus: 'Barrage 5s (3x Rate)'),
      const WeaponLevelData(level: 2, name: 'Flux Cannon', shots: 6, damage: 12, distanceThreshold: 10000, specialBonus: 'Barrage 6s (4x Rate) +25% Dmg'),
      const WeaponLevelData(level: 3, name: 'Infinity Stream', shots: 6, damage: 15, distanceThreshold: 25000, specialBonus: 'Barrage 7s (5x Rate) +50% Dmg'),
      const WeaponLevelData(level: 4, name: 'Eternal Barrage', shots: 6, damage: 20, distanceThreshold: 50000, specialBonus: 'Barrage 8s (7x Rate) + Armor'),
      const WeaponLevelData(level: 5, name: 'Omni Assault', shots: 6, damage: 30, distanceThreshold: 80000, specialBonus: 'Barrage 10s (10x Rate) + Invuln'),
    ],
    evolution: EvolutionData(
      orbitCount: 2, orbitColor: Color(0xFFE0E0E0), orbitDamage: 25,
      desc: 'Orbit infinity rings',
      secondTierDistance: 150000, secondTierOrbitCount: 4,
    ),
  ),

  // ─────────────── CELESTIAL (GOD TIER) ───────────────

  // 20. Celestial Warden — Balanced god-tier
  ShipData(
    id: 'celestial_warden',
    name: 'Celestial Warden',
    cost: 160000,
    description: 'Golden energy spears. Shield auto-regenerates faster.',
    abilityDesc: 'Holy Lance Barrage',
    weaponType: WeaponType.holyLance,
    unlockMethod: 'purchase',
    color: Color(0xFFFFD600),
    glowColor: Color(0x80FFD600),
    speedStat: 9, agilityStat: 9, shieldStat: 10,
    rarity: 'celestial', trailType: 'bolt',
    shieldCircles: 4,
    passiveType: PassiveType.divineProtection,
    passiveName: 'Divine Protection',
    passiveDesc: 'Shield auto-regenerates faster',
    activeType: ActiveAbilityType.judgmentRay,
    activeName: 'Judgment Ray',
    activeDesc: 'Massive vertical laser',
    activeCooldown: 20.0, activeDuration: 1.5,
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Sacred Lance', shots: 1, damage: 15, distanceThreshold: 0, specialBonus: 'Barrier 5s (200 blk) + Heal'),
      const WeaponLevelData(level: 2, name: 'Holy Strike', shots: 1, damage: 20, distanceThreshold: 10000, specialBonus: 'Barrier 6s (400 blk) + Reflect'),
      const WeaponLevelData(level: 3, name: 'Divine Piercer', shots: 1, damage: 30, distanceThreshold: 25000, specialBonus: 'Barrier 7s (800 blk) + Amplify'),
      const WeaponLevelData(level: 4, name: 'Seraphim Spear', shots: 1, damage: 50, distanceThreshold: 50000, specialBonus: 'Barrier 8s (1500 blk) + Dmg Boost'),
      const WeaponLevelData(level: 5, name: 'Godkiller', shots: 1, damage: 80, distanceThreshold: 80000, specialBonus: 'Barrier 10s (3000 blk) + Heal Zones'),
    ],
    evolution: EvolutionData(
      orbitCount: 5, orbitColor: Color(0xFFFFD600), orbitDamage: 20,
      desc: '5 orbit light orbs + damage aura',
      secondTierDistance: 120000, secondTierOrbitCount: 7,
    ),
  ),

  // 21. Abyssal Reaver — Offensive sustain
  ShipData(
    id: 'abyssal_reaver',
    name: 'Abyssal Reaver',
    cost: 200000,
    description: 'Void tentacle strikes. Gain shield on kill.',
    abilityDesc: 'Void Tentacle Strikes',
    weaponType: WeaponType.voidTentacles,
    unlockMethod: 'purchase',
    color: Color(0xFFC51162),
    glowColor: Color(0x80C51162),
    speedStat: 9, agilityStat: 9, shieldStat: 10,
    rarity: 'celestial', trailType: 'wisp',
    shieldCircles: 5,
    passiveType: PassiveType.darknessAbsorb,
    passiveName: 'Darkness Absorb',
    passiveDesc: 'Gain shield on kill',
    activeType: ActiveAbilityType.abyssSurge,
    activeName: 'Abyss Surge',
    activeDesc: 'Screen darkens, enemies slowed',
    activeCooldown: 18.0, activeDuration: 3.0,
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Void Strike', shots: 4, damage: 8, distanceThreshold: 0, specialBonus: 'Wave +25% Dmg (6s)'),
      const WeaponLevelData(level: 2, name: 'Abyss Lash', shots: 4, damage: 8, distanceThreshold: 10000, specialBonus: 'Wave +50% Dmg + Slow'),
      const WeaponLevelData(level: 3, name: 'Eldritch Storm', shots: 4, damage: 8, distanceThreshold: 25000, specialBonus: 'Wave +75% Dmg + Corruption'),
      const WeaponLevelData(level: 4, name: 'Void Reaver', shots: 4, damage: 8, distanceThreshold: 50000, specialBonus: 'Wave +100% Dmg + Tentacles'),
      const WeaponLevelData(level: 5, name: 'Outer God', shots: 4, damage: 8, distanceThreshold: 80000, specialBonus: 'Wave +150% Dmg + Void Zones'),
    ],
    evolution: EvolutionData(
      orbitCount: 4, orbitColor: Color(0xFFD50000), orbitDamage: 22,
      desc: 'Shadow orbit spikes',
      secondTierDistance: 120000, secondTierOrbitCount: 6,
    ),
  ),

  // 22. Quantum Harbinger — Extreme DPS
  ShipData(
    id: 'quantum_harbinger',
    name: 'Quantum Harbinger',
    cost: 250000,
    description: 'Splits space on impact. 2% chance to duplicate shot.',
    abilityDesc: 'Reality Fracture Cannon',
    weaponType: WeaponType.realityFracture,
    unlockMethod: 'purchase',
    color: Color(0xFFAA00FF),
    glowColor: Color(0x80AA00FF),
    speedStat: 10, agilityStat: 10, shieldStat: 10,
    rarity: 'celestial', trailType: 'plasma',
    shieldCircles: 6,
    passiveType: PassiveType.multiverseEcho,
    passiveName: 'Multiverse Echo',
    passiveDesc: '2% chance to duplicate shot',
    activeType: ActiveAbilityType.dimensionalCollapse,
    activeName: 'Dimensional Collapse',
    activeDesc: 'All enemies pulled to center',
    activeCooldown: 22.0, activeDuration: 2.0,
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Shatter Shot', shots: 1, damage: 25, distanceThreshold: 0, specialBonus: 'Collapse 3s (2x Dmg)'),
      const WeaponLevelData(level: 2, name: 'Quantum Split', shots: 1, damage: 25, distanceThreshold: 10000, specialBonus: 'Collapse 4s (3x Dmg) + Echoes'),
      const WeaponLevelData(level: 3, name: 'Reality Break', shots: 1, damage: 25, distanceThreshold: 25000, specialBonus: 'Collapse 5s (4x Dmg) + No Dodge'),
      const WeaponLevelData(level: 4, name: 'Flux Cannon', shots: 1, damage: 25, distanceThreshold: 50000, specialBonus: 'Collapse 6s (6x Dmg) + 3 Positions'),
      const WeaponLevelData(level: 5, name: 'Zero Point', shots: 1, damage: 25, distanceThreshold: 80000, specialBonus: 'Collapse 8s (10x Dmg) + 5 Positions'),
    ],
    evolution: EvolutionData(
      orbitCount: 3, orbitColor: Color(0xFFD500F9), orbitDamage: 25,
      desc: 'Orbit quantum shards',
      secondTierDistance: 120000, secondTierOrbitCount: 5,
    ),
  ),

  // 23. Stellar Colossus — Giant destructive power
  ShipData(
    id: 'stellar_colossus',
    name: 'Stellar Colossus',
    cost: 310000,
    description: 'Erupts with the power of a dying star. Stacking damage.',
    abilityDesc: 'Star Core Eruption',
    weaponType: WeaponType.starCoreEruption,
    unlockMethod: 'purchase',
    color: Color(0xFFFF6D00),
    glowColor: Color(0x80FF6D00),
    speedStat: 10, agilityStat: 10, shieldStat: 10,
    rarity: 'celestial', trailType: 'flame',
    shieldCircles: 7,
    passiveType: PassiveType.solarSurge,
    passiveName: 'Solar Surge',
    passiveDesc: 'Stacking damage boost per kill',
    activeType: ActiveAbilityType.supernova,
    activeName: 'Supernova',
    activeDesc: 'Massive star explosion',
    activeCooldown: 25.0, activeDuration: 0.1,
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Core Flare', shots: 1, damage: 30, distanceThreshold: 0, specialBonus: 'Supernova 1500 Dmg'),
      const WeaponLevelData(level: 2, name: 'Solar Eruption', shots: 1, damage: 30, distanceThreshold: 10000, specialBonus: 'Supernova 3000 Dmg + Invuln'),
      const WeaponLevelData(level: 3, name: 'Red Giant', shots: 1, damage: 30, distanceThreshold: 25000, specialBonus: 'Supernova 6000 Dmg + Burn Zones'),
      const WeaponLevelData(level: 4, name: 'Nova Burst', shots: 1, damage: 30, distanceThreshold: 50000, specialBonus: 'Supernova 12000 Dmg + Mini Stars'),
      const WeaponLevelData(level: 5, name: 'Hypernova', shots: 1, damage: 30, distanceThreshold: 80000, specialBonus: 'Supernova 25000 Dmg + Execute'),
    ],
    evolution: EvolutionData(
      orbitCount: 6, orbitColor: Color(0xFFFFAB00), orbitDamage: 25,
      desc: '6 orbit mini stars',
      secondTierDistance: 150000, secondTierOrbitCount: 8,
    ),
  ),

  // 24. Eternal Sovereign — Divine scaling
  ShipData(
    id: 'eternal_sovereign',
    name: 'Eternal Sovereign',
    cost: 400000,
    description: 'Cosmic judgment. Damage scales with combo.',
    abilityDesc: 'Cosmic Judgement Array',
    weaponType: WeaponType.cosmicJudgement,
    unlockMethod: 'purchase',
    color: Color(0xFF00B0FF),
    glowColor: Color(0x8000B0FF),
    speedStat: 10, agilityStat: 10, shieldStat: 10,
    rarity: 'celestial', trailType: 'bolt',
    shieldCircles: 8,
    passiveType: PassiveType.comboScaling,
    passiveName: 'Divine Scaling',
    passiveDesc: 'Damage scales with combo multiplier',
    activeType: ActiveAbilityType.cosmicRain,
    activeName: 'Cosmic Rain',
    activeDesc: 'Rain of cosmic projectiles',
    activeCooldown: 20.0, activeDuration: 0.1,
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Judgement', shots: 1, damage: 50, distanceThreshold: 0, specialBonus: 'Lightning 500 Dmg + Exec 15%'),
      const WeaponLevelData(level: 2, name: 'Divine Bolt', shots: 1, damage: 50, distanceThreshold: 10000, specialBonus: 'Lightning 1000 Dmg + Stun'),
      const WeaponLevelData(level: 3, name: 'Wrath', shots: 1, damage: 50, distanceThreshold: 25000, specialBonus: 'Lightning 2000 Dmg + Chain'),
      const WeaponLevelData(level: 4, name: 'Skyfall', shots: 1, damage: 50, distanceThreshold: 50000, specialBonus: 'Lightning 4000 Dmg + Elec Zones'),
      const WeaponLevelData(level: 5, name: 'Apocalypse', shots: 1, damage: 50, distanceThreshold: 80000, specialBonus: 'Lightning 8000 Dmg + Exec 40%'),
    ],
    evolution: EvolutionData(
      orbitCount: 4, orbitColor: Color(0xFF40C4FF), orbitDamage: 30,
      desc: 'Halo ring orbit',
      secondTierDistance: 150000, secondTierOrbitCount: 6,
    ),
  ),

  // 25. Omega Nexus — Final God Mode (Ultimate)
  ShipData(
    id: 'omega_nexus',
    name: 'Omega Nexus',
    cost: 500000,
    description: 'Creates mini black holes. All stats increase per boss kill.',
    abilityDesc: 'Singularity Cannon',
    weaponType: WeaponType.singularityGenesis,
    unlockMethod: 'purchase',
    color: Color(0xFF000000),
    glowColor: Color(0xFFFFFFFF),
    speedStat: 10, agilityStat: 10, shieldStat: 10,
    rarity: 'celestial', trailType: 'wisp',
    shieldCircles: 9,
    passiveType: PassiveType.absoluteDominance,
    passiveName: 'Absolute Dominance',
    passiveDesc: 'All stats increase per boss kill',
    activeType: ActiveAbilityType.genesisCollapse,
    activeName: 'Genesis Collapse',
    activeDesc: 'Screen distortion + massive damage',
    activeCooldown: 30.0, activeDuration: 2.0,
    weaponLevels: [
      const WeaponLevelData(level: 1, name: 'Alpha', shots: 1, damage: 100, distanceThreshold: 0, specialBonus: 'Omega 8s (3x Dmg, 2x Spd)'),
      const WeaponLevelData(level: 2, name: 'Beta', shots: 1, damage: 100, distanceThreshold: 10000, specialBonus: 'Omega 10s (5x Dmg) + No Proj'),
      const WeaponLevelData(level: 3, name: 'Gamma', shots: 1, damage: 100, distanceThreshold: 25000, specialBonus: 'Omega 12s (8x Dmg) + Blk Holes'),
      const WeaponLevelData(level: 4, name: 'Delta', shots: 1, damage: 100, distanceThreshold: 50000, specialBonus: 'Omega 15s (12x Dmg) + Time Slow'),
      const WeaponLevelData(level: 5, name: 'Omega', shots: 1, damage: 100, distanceThreshold: 80000, specialBonus: 'Omega 20s (20x Dmg) + Reality Tear'),
    ],
    evolution: EvolutionData(
      orbitCount: 5, orbitColor: Color(0xFFFFFFFF), orbitDamage: 35,
      desc: '5 orbit singularities',
      secondTierDistance: 150000, secondTierOrbitCount: 8,
    ),
  ),
];

ShipData getShipById(String id) {
  return ships.firstWhere((s) => s.id == id, orElse: () => ships[0]);
}
