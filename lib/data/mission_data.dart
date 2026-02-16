import 'dart:math';

enum MissionType { daily, weekly, achievement }
enum MissionCategory { distance, coins, aliens, combo, physics, boss, powerup, survival, shop }

class Mission {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final MissionCategory category;
  final int target;
  int progress;
  final int coinReward;
  final int stardustReward;
  final int xpReward;
  final String? skinReward;

  bool claimed;
  final bool isSingleRun;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.target,
    this.progress = 0,
    this.coinReward = 0,
    this.stardustReward = 0,
    this.xpReward = 0,
    this.skinReward,
    this.claimed = false,
    this.isSingleRun = false,
  });

  bool get isCompleted => progress >= target;
  double get progressPercent => (progress / target).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
    'id': id, 'progress': progress, 'claimed': claimed,
  };

  static Mission fromTemplate(MissionTemplate t, {int? progress, bool? claimed}) {
    return Mission(
      id: t.id,
      title: t.title,
      description: t.description,
      type: t.type,
      category: t.category,
      target: t.target,
      progress: progress ?? 0,
      coinReward: t.coinReward,
      stardustReward: t.stardustReward,
      xpReward: t.xpReward,
      skinReward: t.skinReward,
      claimed: claimed ?? false,
      isSingleRun: t.isSingleRun,
    );
  }
}

class MissionTemplate {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final MissionCategory category;
  final int target;
  final int coinReward;
  final int stardustReward;
  final int xpReward;
  final String? skinReward;
  final bool isSingleRun;

  const MissionTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.target,
    this.coinReward = 0,
    this.stardustReward = 0,
    this.xpReward = 0,
    this.skinReward,
    this.isSingleRun = false,
  });
}

// ═══════════════════════════════════════
//  DAILY MISSION POOL (Easy + Medium)
// ═══════════════════════════════════════
const List<MissionTemplate> dailyMissionPool = [
  // Easy
  MissionTemplate(id: 'd_dist_1000', title: 'Quick Sprint', description: 'Travel 1,000m in one run', type: MissionType.daily, category: MissionCategory.distance, target: 1000, coinReward: 50, xpReward: 15, isSingleRun: true),
  MissionTemplate(id: 'd_coins_100', title: 'Pocket Change', description: 'Collect 100 coins in one run', type: MissionType.daily, category: MissionCategory.coins, target: 100, coinReward: 60, xpReward: 15, isSingleRun: true),
  MissionTemplate(id: 'd_aliens_10', title: 'Target Practice', description: 'Destroy 10 aliens in one run', type: MissionType.daily, category: MissionCategory.aliens, target: 10, coinReward: 80, xpReward: 20, isSingleRun: true),
  MissionTemplate(id: 'd_combo_20', title: 'Warming Up', description: 'Reach 20 combo streak', type: MissionType.daily, category: MissionCategory.combo, target: 20, coinReward: 70, xpReward: 20, isSingleRun: true),

  // Medium
  MissionTemplate(id: 'd_dist_5000', title: 'Space Jog', description: 'Travel 5,000m in one run', type: MissionType.daily, category: MissionCategory.distance, target: 5000, coinReward: 150, xpReward: 40, isSingleRun: true),
  MissionTemplate(id: 'd_coins_500', title: 'Treasure Hunt', description: 'Collect 500 coins total today', type: MissionType.daily, category: MissionCategory.coins, target: 500, coinReward: 200, xpReward: 50),
  MissionTemplate(id: 'd_aliens_50', title: 'Pest Control', description: 'Destroy 50 aliens total today', type: MissionType.daily, category: MissionCategory.aliens, target: 50, coinReward: 250, xpReward: 60),
  MissionTemplate(id: 'd_boss_1', title: 'Boss Encounter', description: 'Defeat 1 boss today', type: MissionType.daily, category: MissionCategory.boss, target: 1, coinReward: 300, stardustReward: 2, xpReward: 100),
  MissionTemplate(id: 'd_physics_3', title: 'Gravity Surfer', description: 'Survive 3 physics modes today', type: MissionType.daily, category: MissionCategory.physics, target: 3, coinReward: 180, xpReward: 45),
  MissionTemplate(id: 'd_powerup_5', title: 'Power User', description: 'Collect 5 powerups today', type: MissionType.daily, category: MissionCategory.powerup, target: 5, coinReward: 120, xpReward: 30),
];

// ═══════════════════════════════════════
//  WEEKLY MISSION POOL
// ═══════════════════════════════════════
const List<MissionTemplate> weeklyMissionPool = [
  MissionTemplate(id: 'w_dist_50k', title: 'Orbital Voyage', description: 'Travel 50,000m total this week', type: MissionType.weekly, category: MissionCategory.distance, target: 50000, coinReward: 1000, stardustReward: 20, xpReward: 200),
  MissionTemplate(id: 'w_coins_5k', title: 'Fortune Amassed', description: 'Collect 5,000 coins this week', type: MissionType.weekly, category: MissionCategory.coins, target: 5000, coinReward: 1200, stardustReward: 25, xpReward: 250),
  MissionTemplate(id: 'w_aliens_500', title: 'Sector Cleansing', description: 'Destroy 500 aliens this week', type: MissionType.weekly, category: MissionCategory.aliens, target: 500, coinReward: 1500, stardustReward: 30, xpReward: 300),
  MissionTemplate(id: 'w_boss_10', title: 'Boss Marathon', description: 'Defeat 10 bosses this week', type: MissionType.weekly, category: MissionCategory.boss, target: 10, coinReward: 2000, stardustReward: 50, xpReward: 500),
  MissionTemplate(id: 'w_physics_20', title: 'Master of Physics', description: 'Survive 20 physics modes', type: MissionType.weekly, category: MissionCategory.physics, target: 20, coinReward: 800, stardustReward: 15, xpReward: 150),
];

// ═══════════════════════════════════════
//  ACHIEVEMENTS (70+ Tasks across Tiers)
// ═══════════════════════════════════════
const List<MissionTemplate> achievementMissions = [
  // ── TIER 1: EASY ──
  MissionTemplate(id: 'a_dist_1k', title: 'First Flight', description: 'Travel 1,000m in one run', type: MissionType.achievement, category: MissionCategory.distance, target: 1000, coinReward: 100, xpReward: 20, isSingleRun: true),
  MissionTemplate(id: 'a_dist_5k', title: 'Novice Pilot', description: 'Travel 5,000m in one run', type: MissionType.achievement, category: MissionCategory.distance, target: 5000, coinReward: 300, stardustReward: 2, xpReward: 50, isSingleRun: true),
  MissionTemplate(id: 'a_coins_100', title: 'Piggy Bank', description: 'Collect 100 coins total', type: MissionType.achievement, category: MissionCategory.coins, target: 100, coinReward: 50, xpReward: 10),
  MissionTemplate(id: 'a_aliens_10', title: 'Bug Splat', description: 'Destroy 10 aliens total', type: MissionType.achievement, category: MissionCategory.aliens, target: 10, coinReward: 100, xpReward: 20),
  MissionTemplate(id: 'a_boss_1', title: 'First Blood', description: 'Defeat 1 Boss', type: MissionType.achievement, category: MissionCategory.boss, target: 1, coinReward: 500, stardustReward: 5, xpReward: 100),
  MissionTemplate(id: 'a_combo_10', title: 'Combo Starter', description: 'Reach 10 combo streak', type: MissionType.achievement, category: MissionCategory.combo, target: 10, coinReward: 100, xpReward: 20, isSingleRun: true),
  MissionTemplate(id: 'a_powerup_1', title: 'Powered Up', description: 'Collect 1 Power-up', type: MissionType.achievement, category: MissionCategory.powerup, target: 1, coinReward: 50, xpReward: 10),
  MissionTemplate(id: 'a_runs_5', title: 'Cadet', description: 'Play 5 runs', type: MissionType.achievement, category: MissionCategory.survival, target: 5, coinReward: 100, xpReward: 20),
  MissionTemplate(id: 'a_physics_1', title: 'Anomalous', description: 'Survive 1 Physics Mode', type: MissionType.achievement, category: MissionCategory.physics, target: 1, coinReward: 100, xpReward: 20),
  MissionTemplate(id: 'a_shop_1', title: 'Consumer', description: 'Buy 1 item from Shop', type: MissionType.achievement, category: MissionCategory.shop, target: 1, coinReward: 10, xpReward: 5), // Logic to trigger this needed in shop

  // ── TIER 2: MEDIUM ──
  MissionTemplate(id: 'a_dist_10k', title: 'Space Traveler', description: 'Travel 10,000m in one run', type: MissionType.achievement, category: MissionCategory.distance, target: 10000, coinReward: 500, stardustReward: 5, xpReward: 100, isSingleRun: true),
  MissionTemplate(id: 'a_dist_20k', title: 'Void Walker', description: 'Travel 20,000m in one run', type: MissionType.achievement, category: MissionCategory.distance, target: 20000, coinReward: 800, stardustReward: 10, xpReward: 150, isSingleRun: true),
  MissionTemplate(id: 'a_coins_1k', title: 'Money Maker', description: 'Collect 1,000 coins in one run', type: MissionType.achievement, category: MissionCategory.coins, target: 1000, coinReward: 400, xpReward: 80, isSingleRun: true),
  MissionTemplate(id: 'a_aliens_100', title: 'Exterminator', description: 'Destroy 100 aliens total', type: MissionType.achievement, category: MissionCategory.aliens, target: 100, coinReward: 500, xpReward: 100),
  MissionTemplate(id: 'a_boss_5', title: 'Boss Slayer', description: 'Defeat 5 Bosses total', type: MissionType.achievement, category: MissionCategory.boss, target: 5, coinReward: 1000, stardustReward: 15, xpReward: 250),
  MissionTemplate(id: 'a_combo_50', title: 'Combo Master', description: 'Reach 50 combo streak', type: MissionType.achievement, category: MissionCategory.combo, target: 50, coinReward: 400, xpReward: 80, isSingleRun: true),
  MissionTemplate(id: 'a_powerup_50', title: 'Battery Full', description: 'Collect 50 Power-ups total', type: MissionType.achievement, category: MissionCategory.powerup, target: 50, coinReward: 300, xpReward: 60),
  MissionTemplate(id: 'a_runs_50', title: 'Frequent Flyer', description: 'Play 50 runs', type: MissionType.achievement, category: MissionCategory.survival, target: 50, coinReward: 500, xpReward: 100),
  MissionTemplate(id: 'a_physics_10', title: 'Physics Major', description: 'Survive 10 Physics Modes total', type: MissionType.achievement, category: MissionCategory.physics, target: 10, coinReward: 400, xpReward: 80),
  MissionTemplate(id: 'a_dist_total_100k', title: 'Long Haul', description: 'Travel 100,000m total lifetime', type: MissionType.achievement, category: MissionCategory.distance, target: 100000, coinReward: 1000, stardustReward: 10, xpReward: 200),

  // ── TIER 3: HARD ──
  MissionTemplate(id: 'a_dist_50k', title: 'Galactic Pioneer', description: 'Travel 50,000m in one run', type: MissionType.achievement, category: MissionCategory.distance, target: 50000, coinReward: 1500, stardustReward: 25, xpReward: 300, isSingleRun: true),
  MissionTemplate(id: 'a_coins_5k_run', title: 'Midas Touch', description: 'Collect 5,000 coins in one run', type: MissionType.achievement, category: MissionCategory.coins, target: 5000, coinReward: 1000, stardustReward: 20, xpReward: 250, isSingleRun: true),
  MissionTemplate(id: 'a_coins_total_100k', title: 'Tycoon', description: 'Collect 100,000 coins total', type: MissionType.achievement, category: MissionCategory.coins, target: 100000, coinReward: 5000, stardustReward: 50, xpReward: 500),
  MissionTemplate(id: 'a_aliens_1k', title: 'Xenocide', description: 'Destroy 1,000 aliens total', type: MissionType.achievement, category: MissionCategory.aliens, target: 1000, coinReward: 2000, stardustReward: 30, xpReward: 400),
  MissionTemplate(id: 'a_aliens_50_run', title: 'Rampage', description: 'Destroy 50 aliens in one run', type: MissionType.achievement, category: MissionCategory.aliens, target: 50, coinReward: 800, stardustReward: 10, xpReward: 150, isSingleRun: true),
  MissionTemplate(id: 'a_boss_20', title: 'Warlord', description: 'Defeat 20 Bosses total', type: MissionType.achievement, category: MissionCategory.boss, target: 20, coinReward: 3000, stardustReward: 40, xpReward: 600),
  MissionTemplate(id: 'a_combo_150', title: 'Combo God', description: 'Reach 150 combo streak', type: MissionType.achievement, category: MissionCategory.combo, target: 150, coinReward: 1500, stardustReward: 25, xpReward: 300, isSingleRun: true),
  MissionTemplate(id: 'a_physics_all', title: 'Anomaly Master', description: 'Survive all Physics Modes (tracker)', type: MissionType.achievement, category: MissionCategory.physics, target: 100, coinReward: 2000, stardustReward: 30, xpReward: 400), // Placeholder target
  MissionTemplate(id: 'a_powerup_200', title: 'Overcharged', description: 'Collect 200 Power-ups total', type: MissionType.achievement, category: MissionCategory.powerup, target: 200, coinReward: 1000, xpReward: 200),
  MissionTemplate(id: 'a_runs_200', title: 'Veteran', description: 'Play 200 runs', type: MissionType.achievement, category: MissionCategory.survival, target: 200, coinReward: 1500, xpReward: 300),

  // ── TIER 4: SUPER HARD (The 70+ list filler) ──
  MissionTemplate(id: 'a_dist_100k', title: 'Universal Legend', description: 'Travel 100,000m in one run', type: MissionType.achievement, category: MissionCategory.distance, target: 100000, coinReward: 5000, stardustReward: 100, xpReward: 1000, skinReward: 'void_emperor', isSingleRun: true),
  MissionTemplate(id: 'a_dist_200k', title: 'Beyond Variable', description: 'Travel 200,000m in one run', type: MissionType.achievement, category: MissionCategory.distance, target: 200000, coinReward: 10000, stardustReward: 200, xpReward: 2000, isSingleRun: true),
  MissionTemplate(id: 'a_boss_50', title: 'God Slayer', description: 'Defeat 50 Bosses total', type: MissionType.achievement, category: MissionCategory.boss, target: 50, coinReward: 5000, stardustReward: 80, xpReward: 1000),
  MissionTemplate(id: 'a_boss_rush_10', title: 'Boss Rush Elite', description: 'Defeat 10 bosses in one Boss Rush run', type: MissionType.achievement, category: MissionCategory.boss, target: 10, coinReward: 2000, stardustReward: 50, xpReward: 500, isSingleRun: true), // Needs bespoke logic hook
  MissionTemplate(id: 'a_combo_500', title: 'Infinity Combo', description: 'Reach 500 combo streak', type: MissionType.achievement, category: MissionCategory.combo, target: 500, coinReward: 5000, stardustReward: 100, xpReward: 1000, skinReward: 'combo_flame', isSingleRun: true),
  MissionTemplate(id: 'a_aliens_5k', title: 'Extinction Event', description: 'Destroy 5,000 aliens total', type: MissionType.achievement, category: MissionCategory.aliens, target: 5000, coinReward: 8000, stardustReward: 120, xpReward: 1500),
  MissionTemplate(id: 'a_runs_1000', title: 'Immortal Pilot', description: 'Play 1,000 runs', type: MissionType.achievement, category: MissionCategory.survival, target: 1000, coinReward: 5000, stardustReward: 50, xpReward: 1000),
  MissionTemplate(id: 'a_dist_total_1m', title: 'Light Year', description: 'Travel 1,000,000m total lifetime', type: MissionType.achievement, category: MissionCategory.distance, target: 1000000, coinReward: 10000, stardustReward: 100, xpReward: 2000),
  
  // Specific Boss Hunts (using boss category, id matching done via loop)
  MissionTemplate(id: 'a_kill_solar', title: 'Sun Extinguisher', description: 'Defeat Solar Titan', type: MissionType.achievement, category: MissionCategory.boss, target: 1, coinReward: 500, stardustReward: 10, xpReward: 50),
  MissionTemplate(id: 'a_kill_void', title: 'Void Breaker', description: 'Defeat Void Devourer', type: MissionType.achievement, category: MissionCategory.boss, target: 1, coinReward: 600, stardustReward: 12, xpReward: 60),
  MissionTemplate(id: 'a_kill_dread', title: 'Machine Wrecker', description: 'Defeat AI Dreadnought', type: MissionType.achievement, category: MissionCategory.boss, target: 1, coinReward: 700, stardustReward: 14, xpReward: 70),
  
  // Powerup Specific
  MissionTemplate(id: 'a_shield_100', title: 'Invulnerable', description: 'Collect 100 Shield powerups total', type: MissionType.achievement, category: MissionCategory.powerup, target: 100, coinReward: 1000, xpReward: 100),
  MissionTemplate(id: 'a_magnet_100', title: 'Attraction', description: 'Collect 100 Magnet powerups total', type: MissionType.achievement, category: MissionCategory.powerup, target: 100, coinReward: 1000, xpReward: 100),
  MissionTemplate(id: 'a_laser_100', title: 'Laser Focus', description: 'Collect 100 Laser powerups total', type: MissionType.achievement, category: MissionCategory.powerup, target: 100, coinReward: 1000, xpReward: 100),
  
  // 35 More Filler Achievements for Density
  MissionTemplate(id: 'a_dist_1500', title: 'Step 1', description: 'Travel 1,500m', type: MissionType.achievement, category: MissionCategory.distance, target: 1500, coinReward: 20, isSingleRun: true),
  MissionTemplate(id: 'a_dist_2500', title: 'Step 2', description: 'Travel 2,500m', type: MissionType.achievement, category: MissionCategory.distance, target: 2500, coinReward: 30, isSingleRun: true),
  MissionTemplate(id: 'a_dist_3500', title: 'Step 3', description: 'Travel 3,500m', type: MissionType.achievement, category: MissionCategory.distance, target: 3500, coinReward: 40, isSingleRun: true),
  MissionTemplate(id: 'a_dist_7500', title: 'Step 4', description: 'Travel 7,500m', type: MissionType.achievement, category: MissionCategory.distance, target: 7500, coinReward: 80, isSingleRun: true),
  MissionTemplate(id: 'a_dist_15k', title: 'Step 5', description: 'Travel 15,000m', type: MissionType.achievement, category: MissionCategory.distance, target: 15000, coinReward: 150, isSingleRun: true),
  MissionTemplate(id: 'a_coins_200', title: 'Saver 1', description: 'Collect 200 coins total', type: MissionType.achievement, category: MissionCategory.coins, target: 200, coinReward: 50),
  MissionTemplate(id: 'a_coins_300', title: 'Saver 2', description: 'Collect 300 coins total', type: MissionType.achievement, category: MissionCategory.coins, target: 300, coinReward: 75),
  MissionTemplate(id: 'a_coins_400', title: 'Saver 3', description: 'Collect 400 coins total', type: MissionType.achievement, category: MissionCategory.coins, target: 400, coinReward: 100),
  MissionTemplate(id: 'a_coins_600', title: 'Saver 4', description: 'Collect 600 coins total', type: MissionType.achievement, category: MissionCategory.coins, target: 600, coinReward: 125),
  MissionTemplate(id: 'a_coins_800', title: 'Saver 5', description: 'Collect 800 coins total', type: MissionType.achievement, category: MissionCategory.coins, target: 800, coinReward: 150),
  MissionTemplate(id: 'a_aliens_20', title: 'Hunter 1', description: 'Kill 20 aliens', type: MissionType.achievement, category: MissionCategory.aliens, target: 20, coinReward: 50),
  MissionTemplate(id: 'a_aliens_30', title: 'Hunter 2', description: 'Kill 30 aliens', type: MissionType.achievement, category: MissionCategory.aliens, target: 30, coinReward: 60),
  MissionTemplate(id: 'a_aliens_40', title: 'Hunter 3', description: 'Kill 40 aliens', type: MissionType.achievement, category: MissionCategory.aliens, target: 40, coinReward: 70),
  MissionTemplate(id: 'a_combo_15', title: 'Flow 1', description: '15 Combo', type: MissionType.achievement, category: MissionCategory.combo, target: 15, coinReward: 50, isSingleRun: true),
  MissionTemplate(id: 'a_combo_25', title: 'Flow 2', description: '25 Combo', type: MissionType.achievement, category: MissionCategory.combo, target: 25, coinReward: 75, isSingleRun: true),
  MissionTemplate(id: 'a_combo_35', title: 'Flow 3', description: '35 Combo', type: MissionType.achievement, category: MissionCategory.combo, target: 35, coinReward: 100, isSingleRun: true),
  MissionTemplate(id: 'a_combo_45', title: 'Flow 4', description: '45 Combo', type: MissionType.achievement, category: MissionCategory.combo, target: 45, coinReward: 125, isSingleRun: true),
  MissionTemplate(id: 'a_physics_2', title: 'Adapt 1', description: 'Survive 2 physics modes total', type: MissionType.achievement, category: MissionCategory.physics, target: 2, coinReward: 50),
  MissionTemplate(id: 'a_physics_4', title: 'Adapt 2', description: 'Survive 4 physics modes total', type: MissionType.achievement, category: MissionCategory.physics, target: 4, coinReward: 100),
  MissionTemplate(id: 'a_physics_6', title: 'Adapt 3', description: 'Survive 6 physics modes total', type: MissionType.achievement, category: MissionCategory.physics, target: 6, coinReward: 150),
  MissionTemplate(id: 'a_physics_8', title: 'Adapt 4', description: 'Survive 8 physics modes total', type: MissionType.achievement, category: MissionCategory.physics, target: 8, coinReward: 200),
  MissionTemplate(id: 'a_boss_2', title: 'Duelist 1', description: 'Defeat 2 bosses total', type: MissionType.achievement, category: MissionCategory.boss, target: 2, coinReward: 100),
  MissionTemplate(id: 'a_boss_3', title: 'Duelist 2', description: 'Defeat 3 bosses total', type: MissionType.achievement, category: MissionCategory.boss, target: 3, coinReward: 150),
  MissionTemplate(id: 'a_boss_4', title: 'Duelist 3', description: 'Defeat 4 bosses total', type: MissionType.achievement, category: MissionCategory.boss, target: 4, coinReward: 200),
  MissionTemplate(id: 'a_runs_10', title: 'Regular 1', description: 'Play 10 runs', type: MissionType.achievement, category: MissionCategory.survival, target: 10, coinReward: 50),
  MissionTemplate(id: 'a_runs_25', title: 'Regular 2', description: 'Play 25 runs', type: MissionType.achievement, category: MissionCategory.survival, target: 25, coinReward: 100),
  MissionTemplate(id: 'a_powerup_10', title: 'Collector 1', description: 'Collect 10 powerups total', type: MissionType.achievement, category: MissionCategory.powerup, target: 10, coinReward: 50),
  MissionTemplate(id: 'a_powerup_25', title: 'Collector 2', description: 'Collect 25 powerups total', type: MissionType.achievement, category: MissionCategory.powerup, target: 25, coinReward: 100),
  MissionTemplate(id: 'a_powerup_75', title: 'Collector 3', description: 'Collect 75 powerups total', type: MissionType.achievement, category: MissionCategory.powerup, target: 75, coinReward: 200),
  MissionTemplate(id: 'a_powerup_150', title: 'Collector 4', description: 'Collect 150 powerups total', type: MissionType.achievement, category: MissionCategory.powerup, target: 150, coinReward: 300),
];

/// Seed-based random picker
/// daySeed: integer (e.g., 20260216)
List<MissionTemplate> pickRandomSeeded(List<MissionTemplate> pool, int count, int seed) {
  final rng = Random(seed);
  final shuffled = List<MissionTemplate>.from(pool)..shuffle(rng);
  return shuffled.take(count).toList();
}
