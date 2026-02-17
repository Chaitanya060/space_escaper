import 'package:flutter/material.dart';

// Attack types a boss can use
enum BossAttackType {
  radialBurst, targetedShot, homingMissiles, laserSweep,
  aoeBlast, spawnMinions, chargeRush, shieldActivate,
  debuffPlayer, summonHazards, regenerate, splitClone,
  screenWipe, vortexPull, groundPound, rapidFire,
}

// Movement styles
enum BossMovement { sway, chase, patrol, circleOrbit, teleport, charge, stationary }

// Visual shapes
enum BossShape { circle, crystal, sharp, tech, organic, skull, star, eye, amorphous }

class BossAttack {
  final String name;
  final BossAttackType type;
  final int projectileCount;
  final double speed;
  final double cooldown;
  const BossAttack({required this.name, required this.type, this.projectileCount = 8, this.speed = 250, this.cooldown = 2.0});
}

class BossPhase {
  final double healthThreshold; // Activate when HP% drops below this (1.0 = start)
  final List<BossAttack> attacks;
  final double attackSpeedMult;
  final double armorMult; // damage reduction multiplier (1.0 = normal)
  final double projectileSpeedMult; // projectile speed multiplier
  
  const BossPhase({
    required this.healthThreshold, 
    required this.attacks, 
    this.attackSpeedMult = 1.0, 
    this.armorMult = 1.0,
    this.projectileSpeedMult = 1.0,
  });
}

class BossConfig {
  final String id;
  final String name;
  final String emoji;
  final int tier; // 1-5
  final int spawnDistance;
  final int maxHealth;
  final double width;
  final double height;
  final BossMovement movement;
  final BossShape shape;
  final List<BossPhase> phases;
  final String weakness;
  final int rewardCoins;
  final String? rewardPowerUp;
  final String? rewardSpecial;
  final bool rebirth; // Phoenix mechanic
  final Color color;
  final Color glowColor;

  const BossConfig({
    required this.id, required this.name, required this.emoji, required this.tier,
    required this.spawnDistance, required this.maxHealth,
    this.width = 120, this.height = 100,
    required this.movement, required this.phases,
    this.shape = BossShape.circle,
    this.weakness = '', required this.rewardCoins,
    this.rewardPowerUp, this.rewardSpecial,
    this.rebirth = false,
    this.color = const Color(0xFFFF6B35),
    this.glowColor = const Color(0x80FF6B35),
  });
}

// ═══════════════════════════════════════
//  ALL 30 BOSSES
// ═══════════════════════════════════════

const List<BossConfig> allBosses = [
  // ── TIER 1: EARLY (5k-17k) ──
  BossConfig(
    id: 'solar_titan', name: 'Solar Titan', emoji: '☀️', tier: 1,
    spawnDistance: 5000, maxHealth: 200, width: 120, height: 100,
    movement: BossMovement.sway, shape: BossShape.circle,
    color: Color(0xFFFFD700), glowColor: Color(0x80FFD700),
    rewardCoins: 800, rewardPowerUp: 'shield',
    weakness: 'Shoot core when shield drops',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Solar Flares', type: BossAttackType.radialBurst, projectileCount: 6, speed: 180, cooldown: 3.0),
        BossAttack(name: 'Heat Wave', type: BossAttackType.aoeBlast, cooldown: 5.0),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.2, projectileSpeedMult: 1.2, attacks: [
        BossAttack(name: 'Solar Flares', type: BossAttackType.radialBurst, projectileCount: 8, speed: 220),
        BossAttack(name: 'Corona Shield', type: BossAttackType.shieldActivate, cooldown: 10.0),
        BossAttack(name: 'Sunspot Mines', type: BossAttackType.summonHazards, projectileCount: 4),
      ]),
    ],
  ),
  BossConfig(
    id: 'void_devourer', name: 'Void Devourer', emoji: '🌀', tier: 1,
    spawnDistance: 8000, maxHealth: 350, width: 140, height: 120,
    movement: BossMovement.chase, shape: BossShape.amorphous,
    color: Color(0xFF8B5CF6), glowColor: Color(0x808B5CF6),
    rewardCoins: 1200, rewardPowerUp: 'ultraMagnet',
    weakness: 'Destroy tentacles to stun',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Gravity Vortex', type: BossAttackType.vortexPull, cooldown: 4.0),
        BossAttack(name: 'Void Tendrils', type: BossAttackType.radialBurst, projectileCount: 6, speed: 160),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.2, projectileSpeedMult: 1.2, attacks: [
        BossAttack(name: 'Dark Matter Orbs', type: BossAttackType.summonHazards, projectileCount: 3),
        BossAttack(name: 'Singularity Pulse', type: BossAttackType.aoeBlast, cooldown: 6.0),
        BossAttack(name: 'Void Tendrils', type: BossAttackType.radialBurst, projectileCount: 8, speed: 200),
      ]),
    ],
  ),
  BossConfig(
    id: 'ai_dreadnought', name: 'AI Dreadnought', emoji: '🤖', tier: 1,
    spawnDistance: 11000, maxHealth: 550, width: 130, height: 110,
    movement: BossMovement.patrol, shape: BossShape.tech,
    color: Color(0xFF374151), glowColor: Color(0x8000D9FF),
    rewardCoins: 1800, rewardPowerUp: 'damageBoost',
    weakness: 'Destroy power cores on sides',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Laser Grid', type: BossAttackType.laserSweep, cooldown: 4.0),
        BossAttack(name: 'Missile Storm', type: BossAttackType.homingMissiles, projectileCount: 6, speed: 150),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.3, projectileSpeedMult: 1.3, attacks: [
        BossAttack(name: 'Missile Storm', type: BossAttackType.homingMissiles, projectileCount: 10, speed: 180),
        BossAttack(name: 'Defense Turrets', type: BossAttackType.rapidFire, projectileCount: 4),
        BossAttack(name: 'EMP Blast', type: BossAttackType.debuffPlayer, cooldown: 12.0),
      ]),
    ],
  ),
  BossConfig(
    id: 'thunder_leviathan', name: 'Thunder Leviathan', emoji: '⚡', tier: 1,
    spawnDistance: 14000, maxHealth: 800, width: 140, height: 110,
    movement: BossMovement.charge, shape: BossShape.sharp,
    color: Color(0xFFFBBF24), glowColor: Color(0x80FBBF24),
    rewardCoins: 2500, rewardPowerUp: 'bulletTime',
    weakness: 'Only vulnerable during charge (glows yellow)',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Chain Lightning', type: BossAttackType.radialBurst, projectileCount: 8, speed: 250),
        BossAttack(name: 'Thunder Dive', type: BossAttackType.chargeRush, cooldown: 6.0),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.3, projectileSpeedMult: 1.3, attacks: [
        BossAttack(name: 'Static Field', type: BossAttackType.summonHazards, projectileCount: 6),
        BossAttack(name: 'Lightning Storm', type: BossAttackType.radialBurst, projectileCount: 12, speed: 300),
        BossAttack(name: 'EMP', type: BossAttackType.debuffPlayer, cooldown: 10.0),
      ]),
    ],
  ),
  BossConfig(
    id: 'cryo_colossus', name: 'Cryo Colossus', emoji: '🧊', tier: 1,
    spawnDistance: 17000, maxHealth: 1100, width: 130, height: 120,
    movement: BossMovement.sway, shape: BossShape.crystal,
    color: Color(0xFF06B6D4), glowColor: Color(0x8006B6D4),
    rewardCoins: 3200, rewardPowerUp: 'comboFreeze',
    weakness: 'Fire weapons deal 3x damage',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Ice Spike Rain', type: BossAttackType.radialBurst, projectileCount: 10, speed: 180),
        BossAttack(name: 'Freeze Beam', type: BossAttackType.laserSweep, cooldown: 5.0),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.2, armorMult: 0.8, projectileSpeedMult: 1.4, attacks: [
        BossAttack(name: 'Blizzard', type: BossAttackType.aoeBlast, cooldown: 8.0),
        BossAttack(name: 'Ice Wall Maze', type: BossAttackType.summonHazards, projectileCount: 8),
        BossAttack(name: 'Permafrost', type: BossAttackType.debuffPlayer, cooldown: 10.0),
      ]),
    ],
  ),

  // ── TIER 2: MID (20k-38k) ──
  BossConfig(
    id: 'tempest_titan', name: 'Tempest Titan', emoji: '🌪️', tier: 2,
    spawnDistance: 20000, maxHealth: 7000, width: 140, height: 130,
    movement: BossMovement.circleOrbit, shape: BossShape.amorphous,
    color: Color(0xFF60A5FA), glowColor: Color(0x8060A5FA),
    rewardCoins: 4000, rewardSpecial: 'shieldCharge',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Hurricane Force', type: BossAttackType.vortexPull, cooldown: 3.0),
        BossAttack(name: 'Tornado Spawns', type: BossAttackType.summonHazards, projectileCount: 5),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.4, projectileSpeedMult: 1.3, attacks: [
        BossAttack(name: 'Debris Hurricane', type: BossAttackType.radialBurst, projectileCount: 30, speed: 280),
        BossAttack(name: 'Wind Blades', type: BossAttackType.targetedShot, projectileCount: 8, speed: 350),
        BossAttack(name: 'Lightning Strikes', type: BossAttackType.radialBurst, projectileCount: 6, speed: 400),
      ]),
    ],
  ),
  BossConfig(
    id: 'scorpion_mech', name: 'Scorpion Mech', emoji: '🦂', tier: 2,
    spawnDistance: 23000, maxHealth: 8500, width: 150, height: 120,
    movement: BossMovement.chase, shape: BossShape.tech,
    color: Color(0xFFEF4444), glowColor: Color(0x80EF4444),
    rewardCoins: 5000, rewardPowerUp: 'miniShip',
    weakness: 'Hit glowing weak spot on tail',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Plasma Tail', type: BossAttackType.rapidFire, projectileCount: 3, speed: 300),
        BossAttack(name: 'Acid Missiles', type: BossAttackType.homingMissiles, projectileCount: 8, speed: 200),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 2.0, projectileSpeedMult: 1.5, attacks: [
        BossAttack(name: 'Claw Pincer', type: BossAttackType.chargeRush, cooldown: 3.0),
        BossAttack(name: 'Underground Assault', type: BossAttackType.groundPound, cooldown: 5.0),
        BossAttack(name: 'Rage Mode', type: BossAttackType.rapidFire, projectileCount: 6, speed: 400),
      ]),
    ],
  ),
  BossConfig(
    id: 'plasma_dragon', name: 'Plasma Dragon', emoji: '🐉', tier: 2,
    spawnDistance: 26000, maxHealth: 10000, width: 160, height: 140,
    movement: BossMovement.sway, shape: BossShape.sharp,
    color: Color(0xFFFF3D00), glowColor: Color(0x80FF3D00),
    rewardCoins: 6500, rewardPowerUp: 'invincibility',
    weakness: 'Mouth during breath, belly during flight',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Flame Breath', type: BossAttackType.radialBurst, projectileCount: 12, speed: 250),
        BossAttack(name: 'Wing Gust', type: BossAttackType.aoeBlast, cooldown: 4.0),
        BossAttack(name: 'Meteor Summon', type: BossAttackType.summonHazards, projectileCount: 10),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.6, projectileSpeedMult: 1.4, attacks: [
        BossAttack(name: 'Inferno Mode', type: BossAttackType.radialBurst, projectileCount: 20, speed: 300),
        BossAttack(name: 'Dragon Dive', type: BossAttackType.chargeRush, cooldown: 3.0),
        BossAttack(name: 'Supernova', type: BossAttackType.screenWipe, cooldown: 8.0),
      ]),
    ],
  ),
  BossConfig(
    id: 'cosmic_eye', name: 'Cosmic Eye', emoji: '👁️', tier: 2,
    spawnDistance: 29000, maxHealth: 12000, width: 130, height: 130,
    movement: BossMovement.teleport, shape: BossShape.eye,
    color: Color(0xFFD500F9), glowColor: Color(0x80D500F9),
    rewardCoins: 8000, rewardPowerUp: 'coinStorm',
    weakness: 'Only real eye takes damage',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Death Stare', type: BossAttackType.laserSweep, cooldown: 3.0),
        BossAttack(name: 'Vision Blast', type: BossAttackType.radialBurst, projectileCount: 8, speed: 300),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.4, projectileSpeedMult: 1.4, attacks: [
        BossAttack(name: 'Clone Army', type: BossAttackType.splitClone, projectileCount: 4),
        BossAttack(name: 'Hypnotic Pulse', type: BossAttackType.debuffPlayer, cooldown: 10.0),
        BossAttack(name: 'Death Stare', type: BossAttackType.laserSweep, cooldown: 2.0),
      ]),
    ],
  ),
  BossConfig(
    id: 'arachnid_queen', name: 'Arachnid Queen', emoji: '🕷️', tier: 2,
    spawnDistance: 32000, maxHealth: 14000, width: 150, height: 140,
    movement: BossMovement.chase, shape: BossShape.organic,
    color: Color(0xFF22C55E), glowColor: Color(0x8022C55E),
    rewardCoins: 10000, rewardSpecial: 'secondWind',
    weakness: 'Must destroy all legs first',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Web Trap', type: BossAttackType.debuffPlayer, cooldown: 5.0),
        BossAttack(name: 'Egg Sacs', type: BossAttackType.spawnMinions, projectileCount: 8),
        BossAttack(name: 'Leg Slam', type: BossAttackType.groundPound, cooldown: 3.0),
      ]),
      BossPhase(healthThreshold: 0.4, attackSpeedMult: 1.5, projectileSpeedMult: 1.4, attacks: [
        BossAttack(name: 'Poison Bite', type: BossAttackType.chargeRush, cooldown: 2.0),
        BossAttack(name: 'Web Cocoon', type: BossAttackType.debuffPlayer, cooldown: 8.0),
        BossAttack(name: 'Egg Sacs', type: BossAttackType.spawnMinions, projectileCount: 15),
      ]),
    ],
  ),
  BossConfig(
    id: 'magma_behemoth', name: 'Magma Behemoth', emoji: '🌋', tier: 2,
    spawnDistance: 35000, maxHealth: 16000, width: 150, height: 140,
    movement: BossMovement.sway, shape: BossShape.organic,
    color: Color(0xFFFF6B35), glowColor: Color(0x80FF6B35),
    rewardCoins: 12000, rewardPowerUp: 'damageBoost',
    weakness: 'Cool down armor with ice weapons',
    phases: [
      BossPhase(healthThreshold: 1.0, armorMult: 0.5, attacks: [
        BossAttack(name: 'Lava Pool', type: BossAttackType.summonHazards, projectileCount: 6),
        BossAttack(name: 'Fireball Volley', type: BossAttackType.radialBurst, projectileCount: 16, speed: 220),
      ]),
      BossPhase(healthThreshold: 0.5, armorMult: 0.5, attackSpeedMult: 1.5, projectileSpeedMult: 1.4, attacks: [
        BossAttack(name: 'Molten Fists', type: BossAttackType.groundPound, cooldown: 3.0),
        BossAttack(name: 'Volcanic Eruption', type: BossAttackType.screenWipe, cooldown: 10.0),
        BossAttack(name: 'Fireball Volley', type: BossAttackType.radialBurst, projectileCount: 24, speed: 280),
      ]),
    ],
  ),
  BossConfig(
    id: 'eclipse_phantom', name: 'Eclipse Phantom', emoji: '🌑', tier: 2,
    spawnDistance: 38000, maxHealth: 18000, width: 130, height: 130,
    movement: BossMovement.teleport, shape: BossShape.skull,
    color: Color(0xFF1F2937), glowColor: Color(0x80A855F7),
    rewardCoins: 15000, rewardPowerUp: 'ultraMagnet',
    weakness: 'Only vulnerable 2s after teleport',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Shadow Clone', type: BossAttackType.splitClone, projectileCount: 5),
        BossAttack(name: 'Eclipse Beam', type: BossAttackType.laserSweep, cooldown: 3.0),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.5, projectileSpeedMult: 1.5, attacks: [
        BossAttack(name: 'Dark Matter Void', type: BossAttackType.summonHazards, projectileCount: 6),
        BossAttack(name: 'Teleport Assault', type: BossAttackType.chargeRush, cooldown: 2.0),
        BossAttack(name: 'Nightmare Realm', type: BossAttackType.debuffPlayer, cooldown: 10.0),
      ]),
    ],
  ),

  // ── TIER 3: HARD (42k-70k) ──
  BossConfig(
    id: 'hive_mind', name: 'Hive Mind Mothership', emoji: '👽', tier: 3,
    spawnDistance: 42000, maxHealth: 20000, width: 160, height: 140,
    movement: BossMovement.stationary, shape: BossShape.organic,
    color: Color(0xFF4ADE80), glowColor: Color(0x804ADE80),
    rewardCoins: 18000,
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Alien Swarm', type: BossAttackType.spawnMinions, projectileCount: 15),
        BossAttack(name: 'Plasma Battery', type: BossAttackType.rapidFire, projectileCount: 10, speed: 350),
        BossAttack(name: 'Regeneration', type: BossAttackType.regenerate, cooldown: 10.0),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.3, projectileSpeedMult: 1.5, attacks: [
        BossAttack(name: 'Tractor Beam', type: BossAttackType.vortexPull, cooldown: 4.0),
        BossAttack(name: 'Shield Drones', type: BossAttackType.shieldActivate, cooldown: 12.0),
        BossAttack(name: 'Alien Swarm', type: BossAttackType.spawnMinions, projectileCount: 25),
      ]),
    ],
  ),
  BossConfig(
    id: 'quantum_anomaly', name: 'Quantum Anomaly', emoji: '⚛️', tier: 3,
    spawnDistance: 46000, maxHealth: 25000, width: 130, height: 130,
    movement: BossMovement.teleport, shape: BossShape.star,
    color: Color(0xFFA78BFA), glowColor: Color(0x80A78BFA),
    rewardCoins: 22000, rewardSpecial: 'stardust_800',
    weakness: 'All timelines must be hit equally',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Probability Warp', type: BossAttackType.radialBurst, projectileCount: 10, speed: 300),
        BossAttack(name: 'Quantum Tunneling', type: BossAttackType.shieldActivate, cooldown: 6.0),
      ]),
      BossPhase(healthThreshold: 0.66, projectileSpeedMult: 1.3, attacks: [
        BossAttack(name: 'Timeline Split', type: BossAttackType.splitClone, projectileCount: 3),
        BossAttack(name: 'Probability Warp', type: BossAttackType.radialBurst, projectileCount: 16, speed: 350),
      ]),
      BossPhase(healthThreshold: 0.33, attackSpeedMult: 1.5, projectileSpeedMult: 1.5, attacks: [
        BossAttack(name: 'Reality Collapse', type: BossAttackType.screenWipe, cooldown: 8.0),
        BossAttack(name: 'Superposition', type: BossAttackType.splitClone, projectileCount: 6),
        BossAttack(name: "Schrödinger's Strike", type: BossAttackType.targetedShot, projectileCount: 12, speed: 400),
      ]),
    ],
  ),
  BossConfig(
    id: 'phoenix_sovereign', name: 'Phoenix Sovereign', emoji: '🦅', tier: 3,
    spawnDistance: 50000, maxHealth: 30000, width: 150, height: 140,
    movement: BossMovement.sway, rebirth: true, shape: BossShape.sharp,
    color: Color(0xFFFF6B35), glowColor: Color(0x80FFD700),
    rewardCoins: 25000, rewardSpecial: 'phoenix_feather',
    weakness: 'Must kill twice',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Flame Wings', type: BossAttackType.radialBurst, projectileCount: 14, speed: 280),
        BossAttack(name: 'Meteor Dive', type: BossAttackType.chargeRush, cooldown: 4.0),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.5, projectileSpeedMult: 1.5, attacks: [
        BossAttack(name: 'Ash Cloud', type: BossAttackType.debuffPlayer, cooldown: 8.0),
        BossAttack(name: 'Solar Flare', type: BossAttackType.aoeBlast, cooldown: 5.0),
        BossAttack(name: 'Flame Wings', type: BossAttackType.radialBurst, projectileCount: 20, speed: 320),
      ]),
    ],
  ),
  BossConfig(
    id: 'leviathan_titan', name: 'Leviathan Titan', emoji: '🌊', tier: 3,
    spawnDistance: 54000, maxHealth: 35000, width: 160, height: 140,
    movement: BossMovement.sway, shape: BossShape.organic,
    color: Color(0xFF0EA5E9), glowColor: Color(0x800EA5E9),
    rewardCoins: 28000, rewardSpecial: 'water_shield',
    weakness: 'Electric weapons deal 4x damage',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Tidal Wave', type: BossAttackType.screenWipe, cooldown: 6.0),
        BossAttack(name: 'Whirlpool', type: BossAttackType.vortexPull, cooldown: 4.0),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.4, projectileSpeedMult: 1.5, attacks: [
        BossAttack(name: 'Water Serpents', type: BossAttackType.spawnMinions, projectileCount: 5),
        BossAttack(name: 'Tsunami', type: BossAttackType.aoeBlast, cooldown: 5.0),
        BossAttack(name: 'Deep Dive', type: BossAttackType.chargeRush, cooldown: 4.0),
      ]),
    ],
  ),
  BossConfig(
    id: 'ancient_golem', name: 'Ancient Golem', emoji: '🗿', tier: 3,
    spawnDistance: 58000, maxHealth: 40000, width: 150, height: 150,
    movement: BossMovement.chase, shape: BossShape.tech,
    color: Color(0xFF78716C), glowColor: Color(0x8078716C),
    rewardCoins: 32000, rewardSpecial: 'stone_shield',
    weakness: 'Destroy armor first, then weak core',
    phases: [
      BossPhase(healthThreshold: 1.0, armorMult: 0.2, attacks: [
        BossAttack(name: 'Boulder Throw', type: BossAttackType.targetedShot, projectileCount: 3, speed: 250),
        BossAttack(name: 'Earthquake', type: BossAttackType.groundPound, cooldown: 4.0),
      ]),
      BossPhase(healthThreshold: 0.5, armorMult: 1.0, attackSpeedMult: 1.5, projectileSpeedMult: 1.5, attacks: [
        BossAttack(name: 'Stone Spikes', type: BossAttackType.summonHazards, projectileCount: 10),
        BossAttack(name: 'Rage Smash', type: BossAttackType.chargeRush, cooldown: 2.0),
        BossAttack(name: 'Boulder Throw', type: BossAttackType.targetedShot, projectileCount: 6, speed: 350),
      ]),
    ],
  ),
  BossConfig(
    id: 'vampire_lord', name: 'Vampire Lord', emoji: '🦇', tier: 3,
    spawnDistance: 62000, maxHealth: 45000, width: 130, height: 130,
    movement: BossMovement.teleport, shape: BossShape.skull,
    color: Color(0xFFDC2626), glowColor: Color(0x80DC2626),
    rewardCoins: 36000, rewardSpecial: 'vampiric_bullets',
    weakness: 'Only light weapons work',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Blood Drain', type: BossAttackType.targetedShot, projectileCount: 4, speed: 280),
        BossAttack(name: 'Bat Swarm', type: BossAttackType.spawnMinions, projectileCount: 15),
        BossAttack(name: 'Life Steal', type: BossAttackType.regenerate, cooldown: 10.0),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.5, projectileSpeedMult: 1.6, attacks: [
        BossAttack(name: 'Shadow Teleport', type: BossAttackType.chargeRush, cooldown: 2.0),
        BossAttack(name: 'Blood Moon', type: BossAttackType.spawnMinions, projectileCount: 25),
        BossAttack(name: 'Blood Drain', type: BossAttackType.targetedShot, projectileCount: 8, speed: 350),
      ]),
    ],
  ),
  BossConfig(
    id: 'alpha_predator', name: 'Alpha Predator', emoji: '🐺', tier: 3,
    spawnDistance: 66000, maxHealth: 50000, width: 140, height: 120,
    movement: BossMovement.charge, shape: BossShape.sharp,
    color: Color(0xFF71717A), glowColor: Color(0x8071717A),
    rewardCoins: 40000, rewardSpecial: 'pack_leader',
    weakness: 'Hit during howl animation',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Pack Summon', type: BossAttackType.spawnMinions, projectileCount: 10),
        BossAttack(name: 'Feral Rush', type: BossAttackType.chargeRush, cooldown: 3.0),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.8, projectileSpeedMult: 1.6, attacks: [
        BossAttack(name: 'Howl', type: BossAttackType.aoeBlast, cooldown: 6.0),
        BossAttack(name: 'Claw Frenzy', type: BossAttackType.rapidFire, projectileCount: 10, speed: 400),
        BossAttack(name: 'Hunt Mode', type: BossAttackType.chargeRush, cooldown: 2.0),
      ]),
    ],
  ),
  BossConfig(
    id: 'poseidon_wrath', name: "Poseidon's Wrath", emoji: '🔱', tier: 3,
    spawnDistance: 70000, maxHealth: 55000, width: 150, height: 140,
    movement: BossMovement.sway, shape: BossShape.crystal,
    color: Color(0xFF0284C7), glowColor: Color(0x800284C7),
    rewardCoins: 45000, rewardSpecial: 'trident_weapon',
    weakness: 'Break trident first',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Trident Attack', type: BossAttackType.targetedShot, projectileCount: 3, speed: 300),
        BossAttack(name: 'Water Wall', type: BossAttackType.aoeBlast, cooldown: 5.0),
      ]),
      BossPhase(healthThreshold: 0.66, projectileSpeedMult: 1.4, attacks: [
        BossAttack(name: 'Sea Monsters', type: BossAttackType.spawnMinions, projectileCount: 8),
        BossAttack(name: 'Whirlpool', type: BossAttackType.vortexPull, cooldown: 4.0),
      ]),
      BossPhase(healthThreshold: 0.33, attackSpeedMult: 1.6, projectileSpeedMult: 1.6, attacks: [
        BossAttack(name: "Ocean's Fury", type: BossAttackType.screenWipe, cooldown: 6.0),
        BossAttack(name: 'Trident Storm', type: BossAttackType.radialBurst, projectileCount: 20, speed: 350),
        BossAttack(name: 'Kraken Summon', type: BossAttackType.spawnMinions, projectileCount: 15),
        BossAttack(name: 'Maelstrom', type: BossAttackType.vortexPull, cooldown: 3.0),
      ]),
    ],
  ),

  // ── TIER 4: NIGHTMARE (75k-110k) ──
  BossConfig(
    id: 'death_incarnate', name: 'Death Incarnate', emoji: '☠️', tier: 4,
    spawnDistance: 75000, maxHealth: 60000, width: 140, height: 140,
    movement: BossMovement.teleport, shape: BossShape.skull,
    color: Color(0xFF000000), glowColor: Color(0x80EF4444),
    rewardCoins: 50000, rewardSpecial: 'deaths_scythe',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Soul Reaper', type: BossAttackType.laserSweep, cooldown: 3.0),
        BossAttack(name: 'Necrotic Aura', type: BossAttackType.aoeBlast, cooldown: 5.0),
        BossAttack(name: 'Undead Army', type: BossAttackType.spawnMinions, projectileCount: 20),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.5, projectileSpeedMult: 1.7, attacks: [
        BossAttack(name: 'Death Touch', type: BossAttackType.chargeRush, cooldown: 2.0),
        BossAttack(name: 'Life Drain', type: BossAttackType.regenerate, cooldown: 8.0),
        BossAttack(name: 'Undead Army', type: BossAttackType.spawnMinions, projectileCount: 30),
      ]),
    ],
  ),
  BossConfig(
    id: 'celestial_guardian', name: 'Celestial Guardian', emoji: '🌟', tier: 4,
    spawnDistance: 80000, maxHealth: 70000, width: 150, height: 150,
    movement: BossMovement.stationary, shape: BossShape.star,
    color: Color(0xFFFFD700), glowColor: Color(0x80FFD700),
    rewardCoins: 55000, rewardSpecial: 'angel_wings',
    phases: [
      BossPhase(healthThreshold: 1.0, armorMult: 0.7, attacks: [
        BossAttack(name: 'Divine Judgment', type: BossAttackType.laserSweep, cooldown: 3.0),
        BossAttack(name: 'Angel Wings', type: BossAttackType.radialBurst, projectileCount: 24, speed: 280),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.4, projectileSpeedMult: 1.7, attacks: [
        BossAttack(name: 'Holy Smite', type: BossAttackType.targetedShot, projectileCount: 6, speed: 400),
        BossAttack(name: "Heaven's Gate", type: BossAttackType.spawnMinions, projectileCount: 15),
        BossAttack(name: 'Resurrection', type: BossAttackType.regenerate, cooldown: 12.0),
      ]),
    ],
  ),
  BossConfig(
    id: 'abyssal_horror', name: 'Abyssal Horror', emoji: '🕳️', tier: 4,
    spawnDistance: 85000, maxHealth: 80000, width: 160, height: 150,
    movement: BossMovement.teleport, shape: BossShape.amorphous,
    color: Color(0xFF1E1B4B), glowColor: Color(0x804C1D95),
    rewardCoins: 65000, rewardSpecial: 'void_cloak',
    weakness: 'Only vulnerable when tentacles destroyed',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Void Zone', type: BossAttackType.summonHazards, projectileCount: 6),
        BossAttack(name: 'Tentacle Storm', type: BossAttackType.radialBurst, projectileCount: 20, speed: 250),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.5, armorMult: 0.5, projectileSpeedMult: 1.8, attacks: [
        BossAttack(name: 'Reality Tear', type: BossAttackType.screenWipe, cooldown: 8.0),
        BossAttack(name: 'Madness Aura', type: BossAttackType.debuffPlayer, cooldown: 6.0),
        BossAttack(name: 'Eldritch Blast', type: BossAttackType.radialBurst, projectileCount: 30, speed: 300),
      ]),
    ],
  ),
  BossConfig(
    id: 'chaos_jester', name: 'Chaos Jester', emoji: '🎭', tier: 4,
    spawnDistance: 90000, maxHealth: 90000, width: 130, height: 130,
    movement: BossMovement.teleport, shape: BossShape.star,
    color: Color(0xFFF97316), glowColor: Color(0x80F97316),
    rewardCoins: 75000, rewardSpecial: 'chaos_orb',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Random Chaos', type: BossAttackType.radialBurst, projectileCount: 15, speed: 300),
        BossAttack(name: 'Clone Madness', type: BossAttackType.splitClone, projectileCount: 8),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.6, projectileSpeedMult: 1.8, attacks: [
        BossAttack(name: 'Physics Break', type: BossAttackType.debuffPlayer, cooldown: 5.0),
        BossAttack(name: 'Bomb Carnival', type: BossAttackType.summonHazards, projectileCount: 15),
        BossAttack(name: 'Time Glitch', type: BossAttackType.aoeBlast, cooldown: 4.0),
      ]),
    ],
  ),
  BossConfig(
    id: 'genesis_core', name: 'Genesis Core', emoji: '🧬', tier: 4,
    spawnDistance: 95000, maxHealth: 100000, width: 140, height: 140,
    movement: BossMovement.stationary, shape: BossShape.organic,
    color: Color(0xFF10B981), glowColor: Color(0x8010B981),
    rewardCoins: 85000, rewardSpecial: 'genesis_seed',
    weakness: 'Must destroy all 4 cores simultaneously',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Life Creation', type: BossAttackType.spawnMinions, projectileCount: 15),
        BossAttack(name: 'DNA Spiral', type: BossAttackType.radialBurst, projectileCount: 12, speed: 250),
        BossAttack(name: 'Regeneration', type: BossAttackType.regenerate, cooldown: 5.0),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.4, projectileSpeedMult: 1.8, attacks: [
        BossAttack(name: 'Cell Division', type: BossAttackType.splitClone, projectileCount: 4),
        BossAttack(name: 'Evolution Beam', type: BossAttackType.laserSweep, cooldown: 3.0),
        BossAttack(name: 'Primordial Soup', type: BossAttackType.summonHazards, projectileCount: 12),
      ]),
    ],
  ),
  BossConfig(
    id: 'galaxy_eater', name: 'Galaxy Eater', emoji: '🌌', tier: 4,
    spawnDistance: 100000, maxHealth: 120000, width: 170, height: 160,
    movement: BossMovement.sway, shape: BossShape.amorphous,
    color: Color(0xFF312E81), glowColor: Color(0x80818CF8),
    rewardCoins: 100000, rewardSpecial: 'star_fragment',
    weakness: 'Only vulnerable during supernova',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Planet Consumption', type: BossAttackType.vortexPull, cooldown: 4.0),
        BossAttack(name: 'Star Destruction', type: BossAttackType.radialBurst, projectileCount: 16, speed: 280),
      ]),
      BossPhase(healthThreshold: 0.66, projectileSpeedMult: 1.4, attacks: [
        BossAttack(name: 'Black Hole Creation', type: BossAttackType.summonHazards, projectileCount: 4),
        BossAttack(name: 'Nebula Cloud', type: BossAttackType.debuffPlayer, cooldown: 8.0),
      ]),
      BossPhase(healthThreshold: 0.33, attackSpeedMult: 1.6, projectileSpeedMult: 1.8, attacks: [
        BossAttack(name: 'Galactic Collapse', type: BossAttackType.vortexPull, cooldown: 3.0),
        BossAttack(name: 'Supernova', type: BossAttackType.screenWipe, cooldown: 6.0),
        BossAttack(name: 'Gravity Well', type: BossAttackType.aoeBlast, cooldown: 4.0),
      ]),
    ],
  ),
  BossConfig(
    id: 'war_machine_omega', name: 'War Machine Omega', emoji: '⚔️', tier: 4,
    spawnDistance: 105000, maxHealth: 150000, width: 160, height: 150,
    movement: BossMovement.patrol, shape: BossShape.tech,
    color: Color(0xFF374151), glowColor: Color(0x80EF4444),
    rewardCoins: 120000, rewardSpecial: 'omega_cannon',
    phases: [
      BossPhase(healthThreshold: 1.0, armorMult: 0.1, attacks: [
        BossAttack(name: 'Gatling Cannons', type: BossAttackType.rapidFire, projectileCount: 20, speed: 400),
        BossAttack(name: 'Laser Grid', type: BossAttackType.laserSweep, cooldown: 3.0),
      ]),
      BossPhase(healthThreshold: 0.5, armorMult: 0.1, attackSpeedMult: 1.5, projectileSpeedMult: 1.9, attacks: [
        BossAttack(name: 'Nuke Launch', type: BossAttackType.screenWipe, cooldown: 8.0),
        BossAttack(name: 'Missile Storm', type: BossAttackType.homingMissiles, projectileCount: 15, speed: 250),
        BossAttack(name: 'Tank Army', type: BossAttackType.spawnMinions, projectileCount: 10),
      ]),
    ],
  ),
  BossConfig(
    id: 'titan_fusion', name: 'Titan Fusion', emoji: '🦾', tier: 4,
    spawnDistance: 110000, maxHealth: 180000, width: 170, height: 160,
    movement: BossMovement.teleport, shape: BossShape.tech,
    color: Color(0xFFDC2626), glowColor: Color(0x80FFD700),
    rewardCoins: 150000, rewardSpecial: 'titan_core',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Death Power', type: BossAttackType.laserSweep, cooldown: 3.0),
        BossAttack(name: 'Celestial Power', type: BossAttackType.radialBurst, projectileCount: 16, speed: 300),
      ]),
      BossPhase(healthThreshold: 0.75, projectileSpeedMult: 1.3, attacks: [
        BossAttack(name: 'Abyssal Power', type: BossAttackType.summonHazards, projectileCount: 8),
        BossAttack(name: 'Chaos Power', type: BossAttackType.splitClone, projectileCount: 5),
      ]),
      BossPhase(healthThreshold: 0.5, projectileSpeedMult: 1.6, attacks: [
        BossAttack(name: 'Genesis Power', type: BossAttackType.spawnMinions, projectileCount: 20),
        BossAttack(name: 'Galaxy Power', type: BossAttackType.vortexPull, cooldown: 3.0),
      ]),
      BossPhase(healthThreshold: 0.25, attackSpeedMult: 2.0, projectileSpeedMult: 2.0, attacks: [
        BossAttack(name: 'All Powers', type: BossAttackType.radialBurst, projectileCount: 30, speed: 350),
        BossAttack(name: 'Fusion Charge', type: BossAttackType.chargeRush, cooldown: 2.0),
        BossAttack(name: 'Omega Blast', type: BossAttackType.screenWipe, cooldown: 5.0),
      ]),
    ],
  ),

  // ── TIER 5: GOD-TIER (120k-200k) ──
  BossConfig(
    id: 'world_ender', name: 'World Ender', emoji: '🌍', tier: 5,
    spawnDistance: 120000, maxHealth: 250000, width: 180, height: 170,
    movement: BossMovement.sway, shape: BossShape.amorphous,
    color: Color(0xFF1E3A8A), glowColor: Color(0x80FF0000),
    rewardCoins: 200000, rewardSpecial: 'world_breaker_title',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Planet Throw', type: BossAttackType.targetedShot, projectileCount: 3, speed: 250),
        BossAttack(name: 'Destroyer Beam', type: BossAttackType.laserSweep, cooldown: 4.0),
      ]),
      BossPhase(healthThreshold: 0.8, projectileSpeedMult: 1.3, attacks: [
        BossAttack(name: 'Star Absorption', type: BossAttackType.vortexPull, cooldown: 3.0),
        BossAttack(name: 'Star Burst', type: BossAttackType.radialBurst, projectileCount: 20, speed: 300),
      ]),
      BossPhase(healthThreshold: 0.6, projectileSpeedMult: 1.6, attacks: [
        BossAttack(name: 'Black Holes', type: BossAttackType.summonHazards, projectileCount: 6),
        BossAttack(name: 'Gravity Warp', type: BossAttackType.debuffPlayer, cooldown: 6.0),
      ]),
      BossPhase(healthThreshold: 0.4, projectileSpeedMult: 1.9, attacks: [
        BossAttack(name: 'Time Bend', type: BossAttackType.aoeBlast, cooldown: 4.0),
        BossAttack(name: 'Space Fracture', type: BossAttackType.screenWipe, cooldown: 5.0),
      ]),
      BossPhase(healthThreshold: 0.2, attackSpeedMult: 2.0, projectileSpeedMult: 2.2, attacks: [
        BossAttack(name: 'Apocalypse', type: BossAttackType.radialBurst, projectileCount: 30, speed: 400),
        BossAttack(name: 'Final Strike', type: BossAttackType.laserSweep, cooldown: 2.0),
        BossAttack(name: 'Universe Collapse', type: BossAttackType.screenWipe, cooldown: 4.0),
      ]),
    ],
  ),
  BossConfig(
    id: 'the_infinite', name: 'THE INFINITE', emoji: '∞', tier: 5,
    spawnDistance: 200000, maxHealth: 500000, width: 200, height: 180,
    movement: BossMovement.teleport, shape: BossShape.eye,
    color: Color(0xFFFFFFFF), glowColor: Color(0x80000000),
    rewardCoins: 500000, rewardSpecial: 'infinity_crown',
    phases: [
      BossPhase(healthThreshold: 1.0, attacks: [
        BossAttack(name: 'Beginning', type: BossAttackType.radialBurst, projectileCount: 8, speed: 200),
      ]),
      BossPhase(healthThreshold: 0.83, projectileSpeedMult: 1.3, attacks: [
        BossAttack(name: 'Evolution', type: BossAttackType.homingMissiles, projectileCount: 12, speed: 250),
        BossAttack(name: 'Adapt', type: BossAttackType.shieldActivate, cooldown: 8.0),
      ]),
      BossPhase(healthThreshold: 0.66, projectileSpeedMult: 1.6, attacks: [
        BossAttack(name: 'Chaos', type: BossAttackType.radialBurst, projectileCount: 24, speed: 350),
        BossAttack(name: 'Reality Break', type: BossAttackType.debuffPlayer, cooldown: 5.0),
      ]),
      BossPhase(healthThreshold: 0.5, attackSpeedMult: 1.5, projectileSpeedMult: 1.9, attacks: [
        BossAttack(name: 'Omnipotence', type: BossAttackType.screenWipe, cooldown: 4.0),
        BossAttack(name: 'All Attacks', type: BossAttackType.radialBurst, projectileCount: 30, speed: 400),
        BossAttack(name: 'Minion Flood', type: BossAttackType.spawnMinions, projectileCount: 25),
      ]),
      BossPhase(healthThreshold: 0.25, armorMult: 0.3, projectileSpeedMult: 2.2, attacks: [
        BossAttack(name: 'Transcendence', type: BossAttackType.shieldActivate, cooldown: 6.0),
        BossAttack(name: 'Infinity Beam', type: BossAttackType.laserSweep, cooldown: 2.0),
        BossAttack(name: 'Time Stop', type: BossAttackType.debuffPlayer, cooldown: 4.0),
      ]),
      BossPhase(healthThreshold: 0.1, attackSpeedMult: 2.5, projectileSpeedMult: 2.5, attacks: [
        BossAttack(name: 'THE END', type: BossAttackType.screenWipe, cooldown: 3.0),
        BossAttack(name: 'Existence Erasure', type: BossAttackType.radialBurst, projectileCount: 40, speed: 500),
        BossAttack(name: 'Final Judgment', type: BossAttackType.vortexPull, cooldown: 2.0),
      ]),
    ],
  ),
];

BossConfig? getBossForDistance(double distance, Set<String> defeated) {
  for (final boss in allBosses) {
    if (distance >= boss.spawnDistance && !defeated.contains(boss.id)) {
      return boss;
    }
  }
  return null;
}

BossConfig? getBossById(String id) {
  try { return allBosses.firstWhere((b) => b.id == id); } catch (_) { return null; }
}
