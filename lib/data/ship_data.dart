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
    weaponUpgrades: [
      WeaponUpgrade(25000, 'double_shot', 'Double Shot'),
      WeaponUpgrade(40000, 'triple_shot', 'Triple Shot'),
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
    weaponUpgrades: [
      WeaponUpgrade(30000, 'charged_blast', 'Charged Lightning Blast'),
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
