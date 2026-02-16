import 'dart:math';

enum MissionType { daily, weekly, achievement }
enum MissionCategory { distance, coins, aliens, combo, physics, boss, powerup, survival }

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
//  DAILY MISSION POOL (pick 3 per day)
// ═══════════════════════════════════════
const List<MissionTemplate> dailyMissionPool = [
  MissionTemplate(
    id: 'd_dist_1000', title: 'Quick Sprint',
    description: 'Travel 1,000m in a single run',
    type: MissionType.daily, category: MissionCategory.distance,
    target: 1000, coinReward: 50, xpReward: 15, isSingleRun: true,
  ),
  MissionTemplate(
    id: 'd_dist_3000', title: 'Deep Space Run',
    description: 'Travel 3,000m in a single run',
    type: MissionType.daily, category: MissionCategory.distance,
    target: 3000, coinReward: 120, xpReward: 30, isSingleRun: true,
  ),
  MissionTemplate(
    id: 'd_coins_100', title: 'Coin Collector',
    description: 'Collect 100 coins in a single run',
    type: MissionType.daily, category: MissionCategory.coins,
    target: 100, coinReward: 60, xpReward: 15, isSingleRun: true,
  ),
  MissionTemplate(
    id: 'd_coins_300', title: 'Gold Rush',
    description: 'Collect 300 coins in a single run',
    type: MissionType.daily, category: MissionCategory.coins,
    target: 300, coinReward: 150, xpReward: 35, isSingleRun: true,
  ),
  MissionTemplate(
    id: 'd_aliens_10', title: 'Alien Hunter',
    description: 'Destroy 10 aliens in a single run',
    type: MissionType.daily, category: MissionCategory.aliens,
    target: 10, coinReward: 80, xpReward: 20, isSingleRun: true,
  ),
  MissionTemplate(
    id: 'd_combo_20', title: 'Combo Starter',
    description: 'Reach a 20 combo streak',
    type: MissionType.daily, category: MissionCategory.combo,
    target: 20, coinReward: 70, xpReward: 20, isSingleRun: true,
  ),
  MissionTemplate(
    id: 'd_physics_2', title: 'Physics Survivor',
    description: 'Survive 2 physics modes in one run',
    type: MissionType.daily, category: MissionCategory.physics,
    target: 2, coinReward: 90, xpReward: 25, isSingleRun: true,
  ),
  MissionTemplate(
    id: 'd_runs_3', title: 'Persistent Pilot',
    description: 'Complete 3 runs today',
    type: MissionType.daily, category: MissionCategory.survival,
    target: 3, coinReward: 100, xpReward: 20,
  ),
];

// ═══════════════════════════════════════
//  WEEKLY MISSION POOL (pick 5 per week)
// ═══════════════════════════════════════
const List<MissionTemplate> weeklyMissionPool = [
  MissionTemplate(
    id: 'w_dist_20000', title: 'Marathon Runner',
    description: 'Travel 20,000m total this week',
    type: MissionType.weekly, category: MissionCategory.distance,
    target: 20000, coinReward: 500, stardustReward: 10, xpReward: 100,
  ),
  MissionTemplate(
    id: 'w_coins_2000', title: 'Treasure Hunter',
    description: 'Collect 2,000 coins total this week',
    type: MissionType.weekly, category: MissionCategory.coins,
    target: 2000, coinReward: 400, stardustReward: 15, xpReward: 80,
  ),
  MissionTemplate(
    id: 'w_aliens_100', title: 'Exterminator',
    description: 'Destroy 100 aliens this week',
    type: MissionType.weekly, category: MissionCategory.aliens,
    target: 100, coinReward: 600, stardustReward: 20, xpReward: 120,
  ),
  MissionTemplate(
    id: 'w_boss_3', title: 'Boss Slayer',
    description: 'Defeat 3 bosses this week',
    type: MissionType.weekly, category: MissionCategory.boss,
    target: 3, coinReward: 800, stardustReward: 25, xpReward: 150,
  ),
  MissionTemplate(
    id: 'w_combo_50', title: 'Combo Master',
    description: 'Reach a 50 combo streak',
    type: MissionType.weekly, category: MissionCategory.combo,
    target: 50, coinReward: 500, stardustReward: 15, xpReward: 100, isSingleRun: true,
  ),
  MissionTemplate(
    id: 'w_physics_10', title: 'Anomaly Expert',
    description: 'Survive 10 physics modes total',
    type: MissionType.weekly, category: MissionCategory.physics,
    target: 10, coinReward: 450, stardustReward: 12, xpReward: 90,
  ),
  MissionTemplate(
    id: 'w_powerup_15', title: 'Power Collector',
    description: 'Collect 15 power-ups this week',
    type: MissionType.weekly, category: MissionCategory.powerup,
    target: 15, coinReward: 350, stardustReward: 10, xpReward: 70,
  ),
];

// ═══════════════════════════════════════
//  ACHIEVEMENT MISSIONS (permanent)
// ═══════════════════════════════════════
const List<MissionTemplate> achievementMissions = [
  // Distance
  MissionTemplate(
    id: 'a_dist_1k', title: 'First Flight',
    description: 'Travel 1,000m in a single run',
    type: MissionType.achievement, category: MissionCategory.distance,
    target: 1000, coinReward: 100, xpReward: 50, isSingleRun: true,
  ),
  MissionTemplate(
    id: 'a_dist_5k', title: 'Deep Explorer',
    description: 'Travel 5,000m in a single run',
    type: MissionType.achievement, category: MissionCategory.distance,
    target: 5000, coinReward: 300, stardustReward: 5, xpReward: 100, isSingleRun: true,
  ),
  MissionTemplate(
    id: 'a_dist_10k', title: 'Void Walker',
    description: 'Travel 10,000m in a single run',
    type: MissionType.achievement, category: MissionCategory.distance,
    target: 10000, coinReward: 800, stardustReward: 20, xpReward: 200, isSingleRun: true,
  ),
  MissionTemplate(
    id: 'a_dist_25k', title: 'Galactic Pioneer',
    description: 'Travel 25,000m in a single run',
    type: MissionType.achievement, category: MissionCategory.distance,
    target: 25000, coinReward: 2000, stardustReward: 50, xpReward: 500, isSingleRun: true,
  ),

  // Coins
  MissionTemplate(
    id: 'a_coins_500', title: 'Coin Hoarder',
    description: 'Collect 500 coins in a single run',
    type: MissionType.achievement, category: MissionCategory.coins,
    target: 500, coinReward: 200, stardustReward: 5, xpReward: 75, isSingleRun: true,
  ),
  MissionTemplate(
    id: 'a_coins_total_10k', title: 'Fortune Builder',
    description: 'Collect 10,000 coins total',
    type: MissionType.achievement, category: MissionCategory.coins,
    target: 10000, coinReward: 500, stardustReward: 25, xpReward: 200,
  ),

  // Aliens
  MissionTemplate(
    id: 'a_aliens_50', title: 'Alien Slayer',
    description: 'Destroy 50 aliens total',
    type: MissionType.achievement, category: MissionCategory.aliens,
    target: 50, coinReward: 200, stardustReward: 5, xpReward: 75,
  ),
  MissionTemplate(
    id: 'a_aliens_500', title: 'Xenocide',
    description: 'Destroy 500 aliens total',
    type: MissionType.achievement, category: MissionCategory.aliens,
    target: 500, coinReward: 1000, stardustReward: 30, xpReward: 300,
  ),

  // Combo
  MissionTemplate(
    id: 'a_combo_100', title: 'Combo King',
    description: 'Reach 100 combo streak',
    type: MissionType.achievement, category: MissionCategory.combo,
    target: 100, coinReward: 500, stardustReward: 15, xpReward: 150, isSingleRun: true,
  ),
  MissionTemplate(
    id: 'a_combo_200', title: 'Combo Legend',
    description: 'Reach 200 combo streak',
    type: MissionType.achievement, category: MissionCategory.combo,
    target: 200, coinReward: 1500, stardustReward: 40, xpReward: 400, skinReward: 'combo_flame', isSingleRun: true,
  ),

  // Boss
  MissionTemplate(
    id: 'a_boss_1', title: 'Boss Killer',
    description: 'Defeat your first boss',
    type: MissionType.achievement, category: MissionCategory.boss,
    target: 1, coinReward: 300, stardustReward: 10, xpReward: 100,
  ),
  MissionTemplate(
    id: 'a_boss_10', title: 'Warlord',
    description: 'Defeat 10 bosses total',
    type: MissionType.achievement, category: MissionCategory.boss,
    target: 10, coinReward: 1000, stardustReward: 30, xpReward: 300,
  ),

  // Physics
  MissionTemplate(
    id: 'a_physics_all', title: 'Anomaly Master',
    description: 'Survive all 9 physics modes',
    type: MissionType.achievement, category: MissionCategory.physics,
    target: 9, coinReward: 500, stardustReward: 20, xpReward: 200,
  ),
];

/// Pick N random templates from a pool
List<MissionTemplate> pickRandom(List<MissionTemplate> pool, int count) {
  final rng = Random();
  final shuffled = List<MissionTemplate>.from(pool)..shuffle(rng);
  return shuffled.take(count).toList();
}
