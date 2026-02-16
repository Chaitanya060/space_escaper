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
  // 1. Nova Scout (FREE)
  ShipData(
    id: 'nova_scout',
    name: 'Nova Scout',
    description: 'Basic forward shot. Reliable starter.',
    abilityDesc: 'Single Bullet',
    weaponType: WeaponType.singleBullet,
    unlockMethod: 'default',
    color: Color(0xFF00D9FF),
    glowColor: Color(0x8000D9FF),
    speedStat: 5, agilityStat: 5, shieldStat: 5,
    rarity: 'common', trailType: 'spark',
  ),

  // 2. Storm Chaser (2 Ads)
  ShipData(
    id: 'storm_chaser',
    name: 'Storm Chaser',
    adReq: 2,
    cost: 200,
    description: 'Hold to charge a powerful burst.',
    abilityDesc: 'Pulse Charger',
    weaponType: WeaponType.pulseCharge,
    unlockMethod: 'purchase',
    color: Color(0xFF2979FF),
    glowColor: Color(0x802979FF),
    speedStat: 6, agilityStat: 6, shieldStat: 4,
    rarity: 'common', trailType: 'spark',
  ),

  // 3. Comet Striker (4 Ads)
  ShipData(
    id: 'comet_striker',
    name: 'Comet Striker',
    adReq: 4,
    cost: 400,
    description: 'Fires bullets that bounce off edges.',
    abilityDesc: 'Ricochet Rounds',
    weaponType: WeaponType.ricochet,
    unlockMethod: 'purchase',
    color: Color(0xFF00E676),
    glowColor: Color(0x8000E676),
    speedStat: 7, agilityStat: 5, shieldStat: 5,
    rarity: 'common', trailType: 'plasma',
  ),

  // 4. Meteor Dash (6 Ads)
  ShipData(
    id: 'meteor_dash',
    name: 'Meteor Dash',
    adReq: 6,
    cost: 600,
    description: 'Short range shotgun spray.',
    abilityDesc: 'Shotgun Spray',
    weaponType: WeaponType.shotgun,
    unlockMethod: 'purchase',
    color: Color(0xFFFF9100),
    glowColor: Color(0x80FF9100),
    speedStat: 8, agilityStat: 4, shieldStat: 6,
    rarity: 'rare', trailType: 'flame',
  ),

  // 5. Aurora Wing (8 Ads)
  ShipData(
    id: 'aurora_wing',
    name: 'Aurora Wing',
    adReq: 8,
    cost: 800,
    description: 'Continuous beam that slows enemies.',
    abilityDesc: 'Frost Beam',
    weaponType: WeaponType.frostBeam,
    unlockMethod: 'purchase',
    color: Color(0xFF18FFFF),
    glowColor: Color(0x8018FFFF),
    speedStat: 6, agilityStat: 8, shieldStat: 5,
    rarity: 'rare', trailType: 'wisp',
  ),

  // 6. Nebula Spark (10 Ads)
  ShipData(
    id: 'nebula_spark',
    name: 'Nebula Spark',
    adReq: 10,
    cost: 1000,
    description: 'Auto-tracking weak darts.',
    abilityDesc: 'Seeker Darts',
    weaponType: WeaponType.seekerDarts,
    unlockMethod: 'purchase',
    color: Color(0xFFFFEA00),
    glowColor: Color(0x80FFEA00),
    speedStat: 5, agilityStat: 9, shieldStat: 4,
    rarity: 'rare', trailType: 'spark',
  ),

  // 7. Stellar Phantom (300 coins)
  ShipData(
    id: 'stellar_phantom',
    name: 'Stellar Phantom',
    cost: 300,
    description: 'Rapid-fire machine gun.',
    abilityDesc: 'Gatling Barrage',
    weaponType: WeaponType.gatling,
    unlockMethod: 'purchase',
    color: Color(0xFFA855F7),
    glowColor: Color(0x80A855F7),
    speedStat: 7, agilityStat: 6, shieldStat: 3,
    rarity: 'common', trailType: 'smoke',
  ),

  // 8. Quantum Racer (800 coins)
  ShipData(
    id: 'quantum_racer',
    name: 'Quantum Racer',
    cost: 800,
    description: 'Oscillating sine-wave energy beam.',
    abilityDesc: 'Wave Beam',
    weaponType: WeaponType.waveBeam,
    unlockMethod: 'purchase',
    color: Color(0xFF22D3EE),
    glowColor: Color(0x8022D3EE),
    speedStat: 8, agilityStat: 8, shieldStat: 4,
    rarity: 'rare', trailType: 'bolt',
  ),

  // 9. Nebula Cruiser (1,500 coins)
  ShipData(
    id: 'nebula_cruiser',
    name: 'Nebula Cruiser',
    cost: 1500,
    description: 'Slow rockets with large AoE.',
    abilityDesc: 'Explosive Rockets',
    weaponType: WeaponType.explosiveRockets,
    unlockMethod: 'purchase',
    color: Color(0xFF34D399),
    glowColor: Color(0x8034D399),
    speedStat: 4, agilityStat: 4, shieldStat: 8,
    rarity: 'rare', trailType: 'spark',
  ),

  // 10. Cosmic Viper (3,000 coins)
  ShipData(
    id: 'cosmic_viper',
    name: 'Cosmic Viper',
    cost: 3000,
    description: 'Electric arc jumps between enemies.',
    abilityDesc: 'Chain Lightning',
    weaponType: WeaponType.chainLightning,
    unlockMethod: 'purchase',
    color: Color(0xFFD500F9),
    glowColor: Color(0x80D500F9),
    speedStat: 7, agilityStat: 7, shieldStat: 5,
    rarity: 'epic', trailType: 'plasma',
  ),

  // 11. Galaxy Titan (6,000 coins)
  ShipData(
    id: 'galaxy_titan',
    name: 'Galaxy Titan',
    cost: 6000,
    description: 'Sweeping beam that slows enemies.',
    abilityDesc: 'Temporal Laser',
    weaponType: WeaponType.temporalLaser,
    unlockMethod: 'purchase',
    color: Color(0xFFF472B6),
    glowColor: Color(0x80F472B6),
    speedStat: 4, agilityStat: 3, shieldStat: 9,
    rarity: 'epic', trailType: 'smoke',
  ),

  // 12. Void Reaper (10,000 coins)
  ShipData(
    id: 'void_reaper',
    name: 'Void Reaper',
    cost: 10000,
    description: 'Energy blades orbit and slash outward.',
    abilityDesc: 'Dimensional Blades',
    weaponType: WeaponType.dimensionalBlades,
    unlockMethod: 'purchase',
    color: Color(0xFFEF4444),
    glowColor: Color(0x80EF4444),
    speedStat: 8, agilityStat: 7, shieldStat: 5,
    rarity: 'epic', trailType: 'wisp',
  ),

  // 13. Star Forge (15,000 coins)
  ShipData(
    id: 'star_forge',
    name: 'Star Forge',
    cost: 15000,
    description: 'Mini-drones that auto-attack.',
    abilityDesc: 'Drone Swarm',
    weaponType: WeaponType.droneSwarm,
    unlockMethod: 'purchase',
    color: Color(0xFFFF6B35),
    glowColor: Color(0x80FF6B35),
    speedStat: 6, agilityStat: 5, shieldStat: 8,
    rarity: 'legendary', trailType: 'flame',
  ),

  // 14. Diamond Emperor (22,000 coins)
  ShipData(
    id: 'diamond_emperor',
    name: 'Diamond Emperor',
    cost: 22000,
    description: 'Diamond splits into homing shards.',
    abilityDesc: 'Crystal Shatter',
    weaponType: WeaponType.crystalShatter,
    unlockMethod: 'purchase',
    color: Color(0xFFB9F2FF),
    glowColor: Color(0x80B9F2FF),
    speedStat: 9, agilityStat: 8, shieldStat: 9,
    rarity: 'legendary', trailType: 'bolt',
  ),

  // 15. Plasma Phoenix (35,000 coins)
  ShipData(
    id: 'plasma_phoenix',
    name: 'Plasma Phoenix',
    cost: 35000,
    description: 'Continuous flame cone.',
    abilityDesc: 'Inferno Flamethrower',
    weaponType: WeaponType.infernoFlamethrower,
    unlockMethod: 'purchase',
    color: Color(0xFFFF3D00),
    glowColor: Color(0x80FF3D00),
    speedStat: 10, agilityStat: 8, shieldStat: 6,
    rarity: 'legendary', trailType: 'flame',
  ),

  // 16. Void Sovereign (50,000 coins)
  ShipData(
    id: 'void_sovereign',
    name: 'Void Sovereign',
    cost: 50000,
    description: 'Expanding rings that push enemies.',
    abilityDesc: 'Gravity Pulse Cannon',
    weaponType: WeaponType.gravityPulse,
    unlockMethod: 'purchase',
    color: Color(0xFF6200EA),
    glowColor: Color(0x806200EA),
    speedStat: 8, agilityStat: 7, shieldStat: 10,
    rarity: 'legendary', trailType: 'wisp',
  ),

  // 17. Chrono Destroyer (70,000 coins)
  ShipData(
    id: 'chrono_destroyer',
    name: 'Chrono Destroyer',
    cost: 70000,
    description: 'Deploys time mines.',
    abilityDesc: 'Time Rift Mines',
    weaponType: WeaponType.mines,
    unlockMethod: 'purchase',
    color: Color(0xFF00BFA5),
    glowColor: Color(0x8000BFA5),
    speedStat: 9, agilityStat: 9, shieldStat: 8,
    rarity: 'mythic', trailType: 'plasma',
    shieldCircles: 1,
  ),

  // 18. Astral Leviathan (95,000 coins)
  ShipData(
    id: 'astral_leviathan',
    name: 'Astral Leviathan',
    cost: 95000,
    description: 'Fires massive ion blasts.',
    abilityDesc: 'Orbital Ion Cannon',
    weaponType: WeaponType.ionCannon,
    unlockMethod: 'purchase',
    color: Color(0xFF304FFE),
    glowColor: Color(0x80304FFE),
    speedStat: 7, agilityStat: 7, shieldStat: 10,
    rarity: 'mythic', trailType: 'bolt',
    shieldCircles: 2,
  ),

  // 19. Infinity Colossus (125,000 coins)
  ShipData(
    id: 'infinity_colossus',
    name: 'Infinity Colossus',
    cost: 125000,
    description: 'Fires a wave that annihilates everything.',
    abilityDesc: 'Annihilation Wave',
    weaponType: WeaponType.annihilationWave,
    unlockMethod: 'purchase',
    color: Color(0xFFFFFFFF),
    glowColor: Color(0x80FFFFFF),
    speedStat: 8, agilityStat: 8, shieldStat: 10,
    rarity: 'mythic', trailType: 'plasma',
    shieldCircles: 3,
  ),

  // 20. Celestial Warden (160,000 coins)
  ShipData(
    id: 'celestial_warden',
    name: 'Celestial Warden',
    cost: 160000,
    description: 'Rapid piercing lances.',
    abilityDesc: 'Holy Lance Barrage',
    weaponType: WeaponType.holyLance,
    unlockMethod: 'purchase',
    color: Color(0xFFFFD600),
    glowColor: Color(0x80FFD600),
    speedStat: 9, agilityStat: 9, shieldStat: 10,
    rarity: 'celestial', trailType: 'bolt',
    shieldCircles: 4,
  ),

  // 21. Abyssal Reaver (200,000 coins)
  ShipData(
    id: 'abyssal_reaver',
    name: 'Abyssal Reaver',
    cost: 200000,
    description: 'Summons void tentacles.',
    abilityDesc: 'Void Tentacles',
    weaponType: WeaponType.voidTentacles,
    unlockMethod: 'purchase',
    color: Color(0xFFC51162),
    glowColor: Color(0x80C51162),
    speedStat: 9, agilityStat: 9, shieldStat: 10,
    rarity: 'celestial', trailType: 'wisp',
    shieldCircles: 5,
  ),

  // 22. Quantum Harbinger (250,000 coins)
  ShipData(
    id: 'quantum_harbinger',
    name: 'Quantum Harbinger',
    cost: 250000,
    description: 'Fractures reality itself.',
    abilityDesc: 'Reality Fracture Cannon',
    weaponType: WeaponType.realityFracture,
    unlockMethod: 'purchase',
    color: Color(0xFFAA00FF),
    glowColor: Color(0x80AA00FF),
    speedStat: 10, agilityStat: 10, shieldStat: 10,
    rarity: 'celestial', trailType: 'plasma',
    shieldCircles: 6,
  ),

  // 23. Stellar Colossus (310,000 coins)
  ShipData(
    id: 'stellar_colossus',
    name: 'Stellar Colossus',
    cost: 310000,
    description: 'Erupts with the power of a dying star.',
    abilityDesc: 'Star Core Eruption',
    weaponType: WeaponType.starCoreEruption,
    unlockMethod: 'purchase',
    color: Color(0xFFFF6D00),
    glowColor: Color(0x80FF6D00),
    speedStat: 10, agilityStat: 10, shieldStat: 10,
    rarity: 'celestial', trailType: 'flame',
    shieldCircles: 7,
  ),

  // 24. Eternal Sovereign (400,000 coins)
  ShipData(
    id: 'eternal_sovereign',
    name: 'Eternal Sovereign',
    cost: 400000,
    description: 'Judges enemies with cosmic light.',
    abilityDesc: 'Cosmic Judgement Array',
    weaponType: WeaponType.cosmicJudgement,
    unlockMethod: 'purchase',
    color: Color(0xFF00B0FF),
    glowColor: Color(0x8000B0FF),
    speedStat: 10, agilityStat: 10, shieldStat: 10,
    rarity: 'celestial', trailType: 'bolt',
    shieldCircles: 8,
  ),

  // 25. Omega Nexus (500,000 coins)
  ShipData(
    id: 'omega_nexus',
    name: 'Omega Nexus',
    cost: 500000,
    description: 'Creates a singularity that ends all.',
    abilityDesc: 'Singularity Genesis',
    weaponType: WeaponType.singularityGenesis,
    unlockMethod: 'purchase',
    color: Color(0xFF000000), // Pure void
    glowColor: Color(0xFFFFFFFF), // White outline
    speedStat: 10, agilityStat: 10, shieldStat: 10,
    rarity: 'celestial', trailType: 'wisp',
    shieldCircles: 9,
  ),
];

ShipData getShipById(String id) {
  return ships.firstWhere((s) => s.id == id, orElse: () => ships[0]);
}
