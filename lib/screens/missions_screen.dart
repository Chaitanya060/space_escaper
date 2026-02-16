import 'package:flutter/material.dart';
import 'dart:convert';
import '../data/mission_data.dart';
import '../data/game_storage.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Mission> dailyMissions = [];
  List<Mission> weeklyMissions = [];
  List<Mission> achievements = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMissions();
  }

  void _loadMissions() {
    dailyMissions = _loadMissionState(GameStorage.dailyMissionsJson, dailyMissionPool);
    weeklyMissions = _loadMissionState(GameStorage.weeklyMissionsJson, weeklyMissionPool);
    achievements = _loadAchievementState();
  }

  List<Mission> _loadMissionState(String json, List<MissionTemplate> pool) {
    if (json.isEmpty || json == '[]') return [];
    try {
      final List<dynamic> raw = jsonDecode(json);
      return raw.map((item) {
        final template = pool.firstWhere(
          (t) => t.id == item['id'],
          orElse: () => pool.first,
        );
        return Mission.fromTemplate(
          template,
          progress: item['progress'] ?? 0,
          claimed: item['claimed'] ?? false,
        );
      }).toList();
    } catch (_) {
      final legacy = _tryParseLegacy(json);
      if (legacy.isEmpty) return [];
      return legacy.map((item) {
        final template = pool.firstWhere(
          (t) => t.id == item['id'],
          orElse: () => pool.first,
        );
        return Mission.fromTemplate(
          template,
          progress: item['progress'] ?? 0,
          claimed: item['claimed'] ?? false,
        );
      }).toList();
    }
  }

  List<Map<String, dynamic>> _tryParseLegacy(String raw) {
    if (!raw.contains(':')) return [];
    final entries = raw.split(',').where((e) => e.trim().isNotEmpty);
    final out = <Map<String, dynamic>>[];
    for (final e in entries) {
      final parts = e.split(':');
      if (parts.length < 3) continue;
      final id = parts[0];
      final progress = int.tryParse(parts[1]) ?? 0;
      final claimedStr = parts[2].toLowerCase();
      final claimed = claimedStr == 'true' || claimedStr == '1';
      out.add({'id': id, 'progress': progress, 'claimed': claimed});
    }
    return out;
  }

  List<Mission> _loadAchievementState() {
    final json = GameStorage.achievementsJson;
    if (json.isEmpty || json == '[]') {
      return achievementMissions.map(Mission.fromTemplate).toList();
    }
    try {
      final List<dynamic> raw = jsonDecode(json);
      return raw.map((item) {
        final template = achievementMissions.firstWhere(
          (t) => t.id == item['id'],
          orElse: () => achievementMissions.first,
        );
        return Mission.fromTemplate(
          template,
          progress: item['progress'] ?? 0,
          claimed: item['claimed'] ?? false,
        );
      }).toList();
    } catch (_) {
      return achievementMissions.map(Mission.fromTemplate).toList();
    }
  }

  void _saveDailyMissions() {
    GameStorage.dailyMissionsJson =
        jsonEncode(dailyMissions.map((m) => m.toJson()).toList());
  }

  void _saveWeeklyMissions() {
    GameStorage.weeklyMissionsJson =
        jsonEncode(weeklyMissions.map((m) => m.toJson()).toList());
  }

  void _saveAchievements() {
    GameStorage.achievementsJson =
        jsonEncode(achievements.map((m) => m.toJson()).toList());
  }

  int _currentWeekNumber() {
    final now = DateTime.now();
    final janFirst = DateTime(now.year, 1, 1);
    return ((now.difference(janFirst).inDays) / 7).ceil();
  }

  void _claimReward(Mission mission) {
    if (!mission.isCompleted || mission.claimed) return;
    setState(() {
      mission.claimed = true;
      GameStorage.addCoins(mission.coinReward);
      GameStorage.addStardust(mission.stardustReward);
      GameStorage.addXp(mission.xpReward);
      switch (mission.type) {
        case MissionType.daily:
          _saveDailyMissions();
          break;
        case MissionType.weekly:
          _saveWeeklyMissions();
          break;
        case MissionType.achievement:
          _saveAchievements();
          break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'MISSIONS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00D9FF),
          labelColor: const Color(0xFF00D9FF),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'DAILY'),
            Tab(text: 'WEEKLY'),
            Tab(text: 'ACHIEVEMENTS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMissionList(dailyMissions),
          _buildMissionList(weeklyMissions),
          _buildMissionList(achievements),
        ],
      ),
    );
  }

  Widget _buildMissionList(List<Mission> missions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: missions.length,
      itemBuilder: (context, index) {
        final m = missions[index];
        return _buildMissionCard(m);
      },
    );
  }

  Widget _buildMissionCard(Mission m) {
    final isComplete = m.isCompleted;
    final isClaimed = m.claimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isClaimed
            ? const Color(0xFF0A1929).withValues(alpha: 0.5)
            : const Color(0xFF0A1929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isComplete
              ? (isClaimed ? const Color(0xFF22C55E).withValues(alpha: 0.3) : const Color(0xFF22C55E))
              : const Color(0xFF1E293B),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.title,
                    style: TextStyle(
                      color: isClaimed ? Colors.white38 : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isComplete && !isClaimed)
                  GestureDetector(
                    onTap: () => _claimReward(m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'CLAIM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                if (isClaimed)
                  const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 24),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              m.description,
              style: TextStyle(
                color: isClaimed ? Colors.white24 : Colors.white54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: m.progressPercent,
                backgroundColor: const Color(0xFF1E293B),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? const Color(0xFF22C55E) : const Color(0xFF00D9FF),
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${m.progress}/${m.target}',
                  style: TextStyle(
                    color: isClaimed ? Colors.white24 : Colors.white54,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    if (m.coinReward > 0) ...[
                      const Icon(Icons.monetization_on, color: Color(0xFFFFD93D), size: 14),
                      const SizedBox(width: 2),
                      Text('${m.coinReward}',
                          style: const TextStyle(color: Color(0xFFFFD93D), fontSize: 12)),
                      const SizedBox(width: 8),
                    ],
                    if (m.stardustReward > 0) ...[
                      const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 14),
                      const SizedBox(width: 2),
                      Text('${m.stardustReward}',
                          style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 12)),
                      const SizedBox(width: 8),
                    ],
                    if (m.xpReward > 0) ...[
                      const Icon(Icons.star, color: Color(0xFF00D9FF), size: 14),
                      const SizedBox(width: 2),
                      Text('${m.xpReward} XP',
                          style: const TextStyle(color: Color(0xFF00D9FF), fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
