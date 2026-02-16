import 'package:flutter/material.dart';

// ═══════════════════════════════════════
//  LEVEL / XP SYSTEM
// ═══════════════════════════════════════

/// XP required to reach each level. Level N requires sum of xpForLevel(1..N).
int xpForLevel(int level) {
  // Quadratic curve: L1=100, L10=550, L50=2600, L100=5100
  return 100 + (level - 1) * 50;
}

/// Total XP needed from 0 to reach a given level
int totalXpForLevel(int level) {
  // Sum of arithmetic series: n/2 * (first + last)
  // first = 100, last = 100 + (level-1)*50
  return (level * (100 + 100 + (level - 1) * 50)) ~/ 2;
}

/// Get level from total XP
int levelFromXp(int totalXp) {
  int level = 1;
  int accumulated = 0;
  while (true) {
    final needed = xpForLevel(level);
    if (accumulated + needed > totalXp) break;
    accumulated += needed;
    level++;
    if (level > 100) break;
  }
  return level.clamp(1, 100);
}

/// XP progress within current level (0.0 to 1.0)
double xpProgress(int totalXp) {
  final level = levelFromXp(totalXp);
  if (level >= 100) return 1.0;
  final prevTotal = totalXpForLevel(level - 1);
  final needed = xpForLevel(level);
  return ((totalXp - prevTotal) / needed).clamp(0.0, 1.0);
}

// ═══════════════════════════════════════
//  XP SOURCES
// ═══════════════════════════════════════

class XpGain {
  static int fromDistance(double distance) => (distance / 100).floor();
  static int fromCoins(int coins) => coins;
  static int fromAlienKill() => 5;
  static int fromBossKill() => 50;
  static int fromMission() => 25;
  static int fromCombo(int maxCombo) => (maxCombo / 5).floor();
  static int fromPhysicsSurvived() => 10;
}

// ═══════════════════════════════════════
//  LEVEL REWARDS
// ═══════════════════════════════════════

class LevelReward {
  final int level;
  final int coins;
  final int stardust;
  final String? skinId;
  final String? title;

  const LevelReward({
    required this.level,
    this.coins = 0,
    this.stardust = 0,
    this.skinId,
    this.title,
  });
}

const List<LevelReward> levelRewards = [
  LevelReward(level: 2, coins: 100),
  LevelReward(level: 5, coins: 250, stardust: 5, title: 'Rookie Pilot'),
  LevelReward(level: 10, coins: 500, stardust: 10, title: 'Space Cadet'),
  LevelReward(level: 15, coins: 750, stardust: 15),
  LevelReward(level: 20, coins: 1000, stardust: 20, title: 'Veteran', skinId: 'neon_scout'),
  LevelReward(level: 25, coins: 1500, stardust: 25),
  LevelReward(level: 30, coins: 2000, stardust: 30, title: 'Commander'),
  LevelReward(level: 40, coins: 3000, stardust: 40, title: 'Admiral', skinId: 'chrome_phantom'),
  LevelReward(level: 50, coins: 5000, stardust: 50, title: 'Galaxy Elite', skinId: 'plasma_viper'),
  LevelReward(level: 60, coins: 6000, stardust: 60),
  LevelReward(level: 75, coins: 8000, stardust: 80, title: 'Void Master', skinId: 'void_emperor'),
  LevelReward(level: 100, coins: 15000, stardust: 150, title: 'Cosmic Legend', skinId: 'cosmic_legend'),
];

// ═══════════════════════════════════════
//  SKILL TREE
// ═══════════════════════════════════════

enum SkillBranch { offense, defense, utility }

class SkillNode {
  final String id;
  final String name;
  final String description;
  final SkillBranch branch;
  final int maxLevel;
  final int costPerLevel; // stardust
  final String? prerequisite;
  final IconData icon;

  const SkillNode({
    required this.id,
    required this.name,
    required this.description,
    required this.branch,
    this.maxLevel = 5,
    this.costPerLevel = 5,
    this.prerequisite,
    required this.icon,
  });
}

const List<SkillNode> skillTree = [
  // ── OFFENSE BRANCH ──
  SkillNode(
    id: 'bullet_speed', name: 'Rapid Fire',
    description: '+5% bullet speed per level',
    branch: SkillBranch.offense, maxLevel: 5, costPerLevel: 3,
    icon: Icons.flash_on,
  ),
  SkillNode(
    id: 'bullet_damage', name: 'Piercing Rounds',
    description: '+1 bullet penetration per level',
    branch: SkillBranch.offense, maxLevel: 3, costPerLevel: 8,
    prerequisite: 'bullet_speed', icon: Icons.gps_fixed,
  ),
  SkillNode(
    id: 'fire_rate', name: 'Trigger Happy',
    description: '-5% fire cooldown per level',
    branch: SkillBranch.offense, maxLevel: 5, costPerLevel: 5,
    icon: Icons.speed,
  ),
  SkillNode(
    id: 'alien_reward', name: 'Bounty Hunter',
    description: '+2 coins per alien kill per level',
    branch: SkillBranch.offense, maxLevel: 5, costPerLevel: 4,
    prerequisite: 'fire_rate', icon: Icons.attach_money,
  ),

  // ── DEFENSE BRANCH ──
  SkillNode(
    id: 'shield_duration', name: 'Shield Extender',
    description: '+0.5s invincibility per level',
    branch: SkillBranch.defense, maxLevel: 5, costPerLevel: 4,
    icon: Icons.shield,
  ),
  SkillNode(
    id: 'bonus_life', name: 'Second Wind',
    description: 'Chance to survive fatal hit (10% per level)',
    branch: SkillBranch.defense, maxLevel: 3, costPerLevel: 10,
    prerequisite: 'shield_duration', icon: Icons.favorite,
  ),
  SkillNode(
    id: 'smaller_hitbox', name: 'Evasion Matrix',
    description: '-3% hitbox size per level',
    branch: SkillBranch.defense, maxLevel: 5, costPerLevel: 5,
    icon: Icons.compress,
  ),

  // ── UTILITY BRANCH ──
  SkillNode(
    id: 'magnet_range', name: 'Magnetic Field',
    description: '+10% coin magnet range per level',
    branch: SkillBranch.utility, maxLevel: 5, costPerLevel: 3,
    icon: Icons.attractions,
  ),
  SkillNode(
    id: 'combo_duration', name: 'Combo Sustain',
    description: '+0.3s combo timer per level',
    branch: SkillBranch.utility, maxLevel: 5, costPerLevel: 4,
    prerequisite: 'magnet_range', icon: Icons.timer,
  ),
  SkillNode(
    id: 'xp_boost', name: 'Quick Learner',
    description: '+5% XP gain per level',
    branch: SkillBranch.utility, maxLevel: 5, costPerLevel: 5,
    icon: Icons.school,
  ),
  SkillNode(
    id: 'coin_value', name: 'Midas Touch',
    description: '+5% coin value per level',
    branch: SkillBranch.utility, maxLevel: 5, costPerLevel: 6,
    prerequisite: 'xp_boost', icon: Icons.monetization_on,
  ),
  SkillNode(
    id: 'powerup_duration', name: 'Power Extender',
    description: '+10% power-up duration per level',
    branch: SkillBranch.utility, maxLevel: 5, costPerLevel: 5,
    icon: Icons.battery_charging_full,
  ),
];

SkillNode? getSkillById(String id) {
  try {
    return skillTree.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
}
