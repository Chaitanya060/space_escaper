import 'package:flutter/material.dart';

// ═══════════════════════════════════════
//  IN-GAME POWER-UPS
// ═══════════════════════════════════════

enum PowerUpType {
  shield,
  coinStorm,
  damageBoost,
  ultraMagnet,
  comboFreeze,
  miniShip,
  bulletTime,
  invincibility,
}

class PowerUpInfo {
  final PowerUpType type;
  final String name;
  final String description;
  final double duration; // seconds
  final Color color;
  final IconData icon;
  final double spawnWeight; // higher = more common
  final String rarity; // common, rare, epic, legendary

  const PowerUpInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.duration,
    required this.color,
    required this.icon,
    this.spawnWeight = 1.0,
    this.rarity = 'common',
  });
}

const List<PowerUpInfo> allPowerUps = [
  PowerUpInfo(
    type: PowerUpType.shield,
    name: 'Shield Bubble',
    description: 'Absorbs one hit',
    duration: 10,
    color: Color(0xFF3B82F6),
    icon: Icons.shield,
    spawnWeight: 1.2,
    rarity: 'common',
  ),
  PowerUpInfo(
    type: PowerUpType.coinStorm,
    name: 'Coin Storm',
    description: 'Tons of coins spawn',
    duration: 10,
    color: Color(0xFFFBBF24),
    icon: Icons.monetization_on,
    spawnWeight: 0.8,
    rarity: 'rare',
  ),
  PowerUpInfo(
    type: PowerUpType.damageBoost,
    name: 'Damage Boost',
    description: 'Double bullet power',
    duration: 15,
    color: Color(0xFFEF4444),
    icon: Icons.local_fire_department,
    spawnWeight: 0.9,
    rarity: 'common',
  ),
  PowerUpInfo(
    type: PowerUpType.ultraMagnet,
    name: 'Ultra Magnet',
    description: '3x coin magnet radius',
    duration: 12,
    color: Color(0xFF8B5CF6),
    icon: Icons.attractions,
    spawnWeight: 1.0,
    rarity: 'common',
  ),
  PowerUpInfo(
    type: PowerUpType.comboFreeze,
    name: 'Combo Freeze',
    description: 'Combo timer pauses',
    duration: 20,
    color: Color(0xFF06B6D4),
    icon: Icons.ac_unit,
    spawnWeight: 0.7,
    rarity: 'rare',
  ),
  PowerUpInfo(
    type: PowerUpType.miniShip,
    name: 'Mini Ship',
    description: 'Ship shrinks 50%',
    duration: 10,
    color: Color(0xFF22C55E),
    icon: Icons.compress,
    spawnWeight: 0.6,
    rarity: 'rare',
  ),
  PowerUpInfo(
    type: PowerUpType.bulletTime,
    name: 'Bullet Time',
    description: 'Everything slows down',
    duration: 5,
    color: Color(0xFFF97316),
    icon: Icons.slow_motion_video,
    spawnWeight: 0.4,
    rarity: 'epic',
  ),
  PowerUpInfo(
    type: PowerUpType.invincibility,
    name: 'Invincibility Star',
    description: 'Ghost through everything',
    duration: 5,
    color: Color(0xFFFFD700),
    icon: Icons.star,
    spawnWeight: 0.2,
    rarity: 'legendary',
  ),
];

PowerUpInfo getPowerUpInfo(PowerUpType type) {
  return allPowerUps.firstWhere((p) => p.type == type);
}

// ═══════════════════════════════════════
//  PRE-RUN CONSUMABLES
// ═══════════════════════════════════════

enum ConsumableType {
  headStart,
  luckyClover,
  shieldCharge,
}

class ConsumableInfo {
  final ConsumableType type;
  final String name;
  final String description;
  final int coinCost;
  final int stardustCost;
  final IconData icon;
  final Color color;

  const ConsumableInfo({
    required this.type,
    required this.name,
    required this.description,
    this.coinCost = 0,
    this.stardustCost = 0,
    required this.icon,
    required this.color,
  });
}

const List<ConsumableInfo> allConsumables = [
  ConsumableInfo(
    type: ConsumableType.headStart,
    name: 'Head Start',
    description: 'Start at 500m with speed boost',
    coinCost: 200,
    icon: Icons.rocket_launch,
    color: Color(0xFF3B82F6),
  ),
  ConsumableInfo(
    type: ConsumableType.luckyClover,
    name: 'Lucky Clover',
    description: '+20% coin spawn rate',
    coinCost: 150,
    icon: Icons.eco,
    color: Color(0xFF22C55E),
  ),
  ConsumableInfo(
    type: ConsumableType.shieldCharge,
    name: 'Shield Charge',
    description: 'Start with shield protection',
    coinCost: 250,
    icon: Icons.shield,
    color: Color(0xFF8B5CF6),
  ),
];

ConsumableInfo getConsumableInfo(ConsumableType type) {
  return allConsumables.firstWhere((c) => c.type == type);
}

// ═══════════════════════════════════════
//  RARITY SYSTEM
// ═══════════════════════════════════════

class Rarity {
  static const String common = 'common';
  static const String rare = 'rare';
  static const String epic = 'epic';
  static const String legendary = 'legendary';

  static Color getColor(String rarity) {
    switch (rarity) {
      case 'common': return const Color(0xFF9CA3AF);
      case 'rare': return const Color(0xFF3B82F6);
      case 'epic': return const Color(0xFF8B5CF6);
      case 'legendary': return const Color(0xFFFFD700);
      default: return const Color(0xFF9CA3AF);
    }
  }

  static Color getGlow(String rarity) {
    switch (rarity) {
      case 'common': return const Color(0x409CA3AF);
      case 'rare': return const Color(0x603B82F6);
      case 'epic': return const Color(0x808B5CF6);
      case 'legendary': return const Color(0xA0FFD700);
      default: return const Color(0x409CA3AF);
    }
  }

  static String getLabel(String rarity) {
    switch (rarity) {
      case 'common': return 'COMMON';
      case 'rare': return 'RARE';
      case 'epic': return 'EPIC';
      case 'legendary': return 'LEGENDARY';
      default: return 'COMMON';
    }
  }
}
