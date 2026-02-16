import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'mission_data.dart';

class GameStorage {
  static late SharedPreferences _prefs;



  // ═══════════════════════════════════════
  //  BOSS PROGRESSION
  // ═══════════════════════════════════════
  static Set<String> get defeatedBosses {
    final list = _prefs.getStringList('defeatedBosses');
    return list?.toSet() ?? {};
  }
  static set defeatedBosses(Set<String> v) =>
      _prefs.setStringList('defeatedBosses', v.toList());

  static void addDefeatedBoss(String bossId) {
    final set = defeatedBosses;
    set.add(bossId);
    defeatedBosses = set;
  }

  static String get highestBossDefeated {
    final defeated = defeatedBosses;
    if (defeated.isEmpty) return 'None';
    return defeated.last;
  }

  // ═══════════════════════════════════════
  //  ADS & TRIALS
  // ═══════════════════════════════════════
  static Map<String, int> get shipAdProgress {
    final json = _prefs.getString('shipAdProgress');
    if (json == null) return {};
    return Map<String, int>.from(jsonDecode(json));
  }
  static set shipAdProgress(Map<String, int> v) =>
      _prefs.setString('shipAdProgress', jsonEncode(v));

  static void incrementAdProgress(String shipId) {
    final progress = shipAdProgress;
    progress[shipId] = (progress[shipId] ?? 0) + 1;
    shipAdProgress = progress;
  }

  static int getAdProgress(String shipId) => shipAdProgress[shipId] ?? 0;

  // ═══════════════════════════════════════
  //  COINS & CURRENCY
  // ═══════════════════════════════════════
  static int get totalCoins => _prefs.getInt('totalCoins') ?? 0;
  static set totalCoins(int v) => _prefs.setInt('totalCoins', v);

  static int get stardust => _prefs.getInt('stardust') ?? 0;
  static set stardust(int v) => _prefs.setInt('stardust', v);

  // ═══════════════════════════════════════
  //  SCORES & RECORDS
  // ═══════════════════════════════════════
  static int get highScore => _prefs.getInt('highScore') ?? 0;
  static set highScore(int v) => _prefs.setInt('highScore', v);

  static double get bestDistance => _prefs.getDouble('bestDistance') ?? 0;
  static set bestDistance(double v) => _prefs.setDouble('bestDistance', v);

  static int get highestCombo => _prefs.getInt('highestCombo') ?? 0;
  static set highestCombo(int v) => _prefs.setInt('highestCombo', v);

  // ═══════════════════════════════════════
  //  LIFETIME STATS
  // ═══════════════════════════════════════
  static int get totalRuns => _prefs.getInt('totalRuns') ?? 0;
  static set totalRuns(int v) => _prefs.setInt('totalRuns', v);

  static double get totalDistanceTraveled =>
      _prefs.getDouble('totalDistanceTraveled') ?? 0;
  static set totalDistanceTraveled(double v) =>
      _prefs.setDouble('totalDistanceTraveled', v);

  static int get totalCoinsCollected =>
      _prefs.getInt('totalCoinsCollected') ?? 0;
  static set totalCoinsCollected(int v) =>
      _prefs.setInt('totalCoinsCollected', v);

  static int get totalAliensDestroyed =>
      _prefs.getInt('totalAliensDestroyed') ?? 0;
  static set totalAliensDestroyed(int v) =>
      _prefs.setInt('totalAliensDestroyed', v);

  static int get totalBossesDefeated =>
      _prefs.getInt('totalBossesDefeated') ?? 0;
  static set totalBossesDefeated(int v) =>
      _prefs.setInt('totalBossesDefeated', v);

  static int get totalPhysicsSurvived =>
      _prefs.getInt('totalPhysicsSurvived') ?? 0;
  static set totalPhysicsSurvived(int v) =>
      _prefs.setInt('totalPhysicsSurvived', v);

  static int get totalPowerUpsCollected =>
      _prefs.getInt('totalPowerUpsCollected') ?? 0;
  static set totalPowerUpsCollected(int v) =>
      _prefs.setInt('totalPowerUpsCollected', v);

  // ═══════════════════════════════════════
  //  XP & LEVEL
  // ═══════════════════════════════════════
  static int get playerXp => _prefs.getInt('playerXp') ?? 0;
  static set playerXp(int v) => _prefs.setInt('playerXp', v);

  static int get lastRewardedLevel => _prefs.getInt('lastRewardedLevel') ?? 0;
  static set lastRewardedLevel(int v) => _prefs.setInt('lastRewardedLevel', v);

  // ═══════════════════════════════════════
  //  SHIP
  // ═══════════════════════════════════════
  static String get selectedShip => _prefs.getString('selectedShip') ?? 'nova_scout';
  static set selectedShip(String v) => _prefs.setString('selectedShip', v);

  static List<String> get unlockedShips =>
      _prefs.getStringList('unlockedShips') ?? ['nova_scout'];
  static set unlockedShips(List<String> v) =>
      _prefs.setStringList('unlockedShips', v);

  // ═══════════════════════════════════════
  //  SKINS
  // ═══════════════════════════════════════
  static List<String> get ownedSkins =>
      _prefs.getStringList('ownedSkins') ?? [];
  static set ownedSkins(List<String> v) =>
      _prefs.setStringList('ownedSkins', v);

  static String? get equippedSkin => _prefs.getString('equippedSkin');
  static set equippedSkin(String? v) {
    if (v == null) {
      _prefs.remove('equippedSkin');
    } else {
      _prefs.setString('equippedSkin', v);
    }
  }

  // ═══════════════════════════════════════
  //  SKILL TREE
  // ═══════════════════════════════════════
  static Map<String, int> get skillLevels {
    final json = _prefs.getString('skillLevels');
    if (json == null) return {};
    return Map<String, int>.from(jsonDecode(json));
  }
  static set skillLevels(Map<String, int> v) =>
      _prefs.setString('skillLevels', jsonEncode(v));

  static int getSkillLevel(String skillId) => skillLevels[skillId] ?? 0;

  static void upgradeSkill(String skillId, int cost) {
    final levels = skillLevels;
    levels[skillId] = (levels[skillId] ?? 0) + 1;
    skillLevels = levels;
    stardust = stardust - cost;
  }

  // ═══════════════════════════════════════
  //  CONSUMABLES
  // ═══════════════════════════════════════
  static Map<String, int> get ownedConsumables {
    final json = _prefs.getString('ownedConsumables');
    if (json == null) return {};
    return Map<String, int>.from(jsonDecode(json));
  }
  static set ownedConsumables(Map<String, int> v) =>
      _prefs.setString('ownedConsumables', jsonEncode(v));

  static int getConsumableCount(String type) => ownedConsumables[type] ?? 0;

  static void addConsumable(String type) {
    final c = ownedConsumables;
    c[type] = (c[type] ?? 0) + 1;
    ownedConsumables = c;
  }

  static bool useConsumable(String type) {
    final c = ownedConsumables;
    if ((c[type] ?? 0) <= 0) return false;
    c[type] = c[type]! - 1;
    ownedConsumables = c;
    return true;
  }

  // ═══════════════════════════════════════
  //  DAILY LOGIN
  // ═══════════════════════════════════════
  static int get dailyLoginStreak => _prefs.getInt('dailyLoginStreak') ?? 0;
  static set dailyLoginStreak(int v) => _prefs.setInt('dailyLoginStreak', v);

  static String get lastLoginDate => _prefs.getString('lastLoginDate') ?? '';
  static set lastLoginDate(String v) => _prefs.setString('lastLoginDate', v);

  /// Returns true if this is a new day and streak was updated
  static bool checkDailyLogin() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastLoginDate == today) return false;

    final yesterday = DateTime.now().subtract(const Duration(days: 1))
        .toIso8601String().substring(0, 10);
    if (lastLoginDate == yesterday) {
      dailyLoginStreak = dailyLoginStreak + 1;
    } else {
      dailyLoginStreak = 1;
    }
    lastLoginDate = today;
    return true;
  }

  // ═══════════════════════════════════════
  //  MISSIONS (JSON-stored)
  // ═══════════════════════════════════════
  static String get dailyMissionsJson =>
      _prefs.getString('dailyMissions') ?? '[]';
  static set dailyMissionsJson(String v) =>
      _prefs.setString('dailyMissions', v);

  static String get dailyMissionsDate =>
      _prefs.getString('dailyMissionsDate') ?? '';
  static set dailyMissionsDate(String v) =>
      _prefs.setString('dailyMissionsDate', v);

  static String get weeklyMissionsJson =>
      _prefs.getString('weeklyMissions') ?? '[]';
  static set weeklyMissionsJson(String v) =>
      _prefs.setString('weeklyMissions', v);

  static int get weeklyMissionsWeek => _prefs.getInt('weeklyMissionsWeek') ?? 0;
  static set weeklyMissionsWeek(int v) => _prefs.setInt('weeklyMissionsWeek', v);

  static String get achievementsJson =>
      _prefs.getString('achievements') ?? '[]';
  static set achievementsJson(String v) =>
      _prefs.setString('achievements', v);

  static void initMissions() {
    // 1. Daily Missions
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (dailyMissionsDate != today) {
      final newMissions = pickRandom(dailyMissionPool, 3)
          .map((t) => Mission.fromTemplate(t)).toList();
      dailyMissionsJson = jsonEncode(newMissions);
      dailyMissionsDate = today;
    }

    // 2. Weekly Missions
    // Simple week calculation (days since epoch / 7)
    final currentWeek = (DateTime.now().millisecondsSinceEpoch / (1000 * 60 * 60 * 24 * 7)).floor();
    if (weeklyMissionsWeek != currentWeek) {
      final newMissions = pickRandom(weeklyMissionPool, 5)
          .map((t) => Mission.fromTemplate(t)).toList();
      weeklyMissionsJson = jsonEncode(newMissions);
      weeklyMissionsWeek = currentWeek;
    }

    // 3. Achievements (Initialize if empty)
    if (achievementsJson == '[]') {
      final achievements = achievementMissions
          .map((t) => Mission.fromTemplate(t)).toList();
      achievementsJson = jsonEncode(achievements);
    } else {
      // Check if new achievements were added to the game data that aren't in storage
      final List<dynamic> storedJson = jsonDecode(achievementsJson);
      final storedIds = storedJson.map((e) => e['id']).toSet();
      
      bool addedNew = false;
      List<Mission> currentAchievements = storedJson.map((e) {
          // Re-hydrate with template data
          final t = achievementMissions.firstWhere((t) => t.id == e['id'], 
              orElse: () => achievementMissions[0]); // Fallback if removed
          return Mission.fromTemplate(t, progress: e['progress'], claimed: e['claimed']);
      }).toList();

      for (var t in achievementMissions) {
        if (!storedIds.contains(t.id)) {
          currentAchievements.add(Mission.fromTemplate(t));
          addedNew = true;
        }
      }
      
      if (addedNew) {
        achievementsJson = jsonEncode(currentAchievements);
      }
    }
  }

  static void updateMissionProgress(MissionType type, MissionCategory category, int amount) {
    String jsonStr;
    Function(String) saver;
    List<dynamic> listCallback;
    
    switch (type) {
      case MissionType.daily:
        jsonStr = dailyMissionsJson;
        saver = (v) => dailyMissionsJson = v;
        break;
      case MissionType.weekly:
        jsonStr = weeklyMissionsJson;
        saver = (v) => weeklyMissionsJson = v;
        break;
      case MissionType.achievement:
        jsonStr = achievementsJson;
        saver = (v) => achievementsJson = v;
        break;
    }

    if (jsonStr == '[]') return;

    try {
      listCallback = jsonDecode(jsonStr);
    } catch (_) {
      final migrated = _tryMigrateLegacyMissionString(jsonStr);
      if (migrated != null) {
        saver(jsonEncode(migrated));
        listCallback = migrated;
      } else {
        return;
      }
    }
    bool changed = false;

    // We need to re-hydrate matches to check logic, then save simple json back
    final updatedList = listCallback.map((mJson) {
      final String id = mJson['id'];
      
      // Find template
      List<MissionTemplate> pool;
      if (type == MissionType.daily) pool = dailyMissionPool;
      else if (type == MissionType.weekly) pool = weeklyMissionPool;
      else pool = achievementMissions;
      
      final template = pool.firstWhere((t) => t.id == id,
          orElse: () => MissionTemplate(id: 'unknown', title: '', description: '', type: type, category: category, target: 1));
      
      if (template.id == 'unknown') return mJson; // Skip unknown

      final mission = Mission.fromTemplate(template, 
          progress: mJson['progress'], 
          claimed: mJson['claimed']);

      if (mission.category == category && !mission.claimed && !mission.isCompleted) {
        if (mission.isSingleRun) {
           // For single run, update only if amount > current progress
           if (amount > mission.progress) {
             mission.progress = amount;
             changed = true;
           }
        } else {
           // Cumulative
           mission.progress += amount;
           changed = true;
        }
        
        // Cap at target
        if (mission.progress > mission.target) mission.progress = mission.target;
      }
      return mission.toJson();
    }).toList();

    if (changed) {
      saver(jsonEncode(updatedList));
    }
  }

  static List<Map<String, dynamic>>? _tryMigrateLegacyMissionString(String raw) {
    if (!raw.contains(':')) return null;
    final entries = raw.split(',').where((e) => e.trim().isNotEmpty);
    final List<Map<String, dynamic>> out = [];
    for (final e in entries) {
      final parts = e.split(':');
      if (parts.length < 3) continue;
      final id = parts[0];
      final progress = int.tryParse(parts[1]) ?? 0;
      final claimedStr = parts[2].toLowerCase();
      final claimed = claimedStr == 'true' || claimedStr == '1';
      out.add({'id': id, 'progress': progress, 'claimed': claimed});
    }
    return out.isEmpty ? null : out;
  }

  // ═══════════════════════════════════════
  //  SETTINGS
  // ═══════════════════════════════════════
  static bool get soundEnabled => _prefs.getBool('soundEnabled') ?? true;
  static set soundEnabled(bool v) => _prefs.setBool('soundEnabled', v);

  static bool get musicEnabled => _prefs.getBool('musicEnabled') ?? true;
  static set musicEnabled(bool v) => _prefs.setBool('musicEnabled', v);

  // ═══════════════════════════════════════
  //  GAME MODE RECORDS
  // ═══════════════════════════════════════
  static double get hardcoreBestDistance =>
      _prefs.getDouble('hardcoreBestDistance') ?? 0;
  static set hardcoreBestDistance(double v) =>
      _prefs.setDouble('hardcoreBestDistance', v);

  static double get zenBestDistance =>
      _prefs.getDouble('zenBestDistance') ?? 0;
  static set zenBestDistance(double v) =>
      _prefs.setDouble('zenBestDistance', v);

  // ═══════════════════════════════════════
  //  METHODS
  // ═══════════════════════════════════════

  static void addCoins(int amount) {
    totalCoins = totalCoins + amount;
    totalCoinsCollected = totalCoinsCollected + amount;
  }

  static void addStardust(int amount) {
    stardust = stardust + amount;
  }

  static void addXp(int amount) {
    playerXp = playerXp + amount;
  }

  static bool spendCoins(int amount) {
    if (totalCoins < amount) return false;
    totalCoins = totalCoins - amount;
    return true;
  }

  static bool spendStardust(int amount) {
    if (stardust < amount) return false;
    stardust = stardust - amount;
    return true;
  }

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    initMissions();
  }

  static void updateAfterRun({
    required double distance,
    required int coinsCollected,
    required int aliensKilled,
    required int bossesKilled,
    required int maxCombo,
    required int physicsSurvived,
    required int powerUpsCollected,
  }) {
    totalRuns = totalRuns + 1;
    totalDistanceTraveled = totalDistanceTraveled + distance;
    totalAliensDestroyed = totalAliensDestroyed + aliensKilled;
    totalBossesDefeated = totalBossesDefeated + bossesKilled;
    totalPhysicsSurvived = totalPhysicsSurvived + physicsSurvived;
    totalPowerUpsCollected = totalPowerUpsCollected + powerUpsCollected;

    if (distance > bestDistance) bestDistance = distance;
    if (maxCombo > highestCombo) highestCombo = maxCombo;

    final score = distance.toInt() + coinsCollected * 10;
    if (score > highScore) highScore = score;

    if (coinsCollected > 0) {
      addCoins(coinsCollected);
    }

    // Update Missions & Achievements
    for (var type in [MissionType.daily, MissionType.weekly, MissionType.achievement]) {
      updateMissionProgress(type, MissionCategory.distance, distance.toInt());
      updateMissionProgress(type, MissionCategory.coins, coinsCollected);
      updateMissionProgress(type, MissionCategory.aliens, aliensKilled);
      updateMissionProgress(type, MissionCategory.boss, bossesKilled);
      updateMissionProgress(type, MissionCategory.combo, maxCombo);
      updateMissionProgress(type, MissionCategory.physics, physicsSurvived);
      updateMissionProgress(type, MissionCategory.powerup, powerUpsCollected);
      updateMissionProgress(type, MissionCategory.survival, 1);
    }
  }

  static void unlockShip(String shipId) {
    final ships = unlockedShips;
    if (!ships.contains(shipId)) {
      ships.add(shipId);
      unlockedShips = ships;
    }
  }

  static bool isShipUnlocked(String shipId) =>
      unlockedShips.contains(shipId);

  static bool canAfford(int cost) => totalCoins >= cost;

  static void resetProgress() {
    _prefs.clear();
  }
}
