import 'package:flutter/material.dart';
import '../data/game_storage.dart';
import '../data/progression_data.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final xp = GameStorage.playerXp;
    final level = levelFromXp(xp);
    final progress = xpProgress(xp);
    final nextLevelXp = xpForLevel(level);

    return Scaffold(
      backgroundColor: const Color(0xFF050D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PILOT PROFILE',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Level badge
            _buildLevelBadge(level, progress, nextLevelXp, xp),
            const SizedBox(height: 24),

            // Currency
            _buildCurrencyRow(),
            const SizedBox(height: 24),

            // Stats grid
            _buildStatsGrid(),
            const SizedBox(height: 24),

            // Skill tree preview
            _buildSkillTreePreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(int level, double progress, int nextXp, int totalXp) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A1929),
            const Color(0xFF0D0D2B).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Level circle
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00D9FF), Color(0xFF0066FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D9FF).withValues(alpha: 0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getTitleForLevel(level),
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          // XP bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$totalXp / ${totalXpForLevel(level)} XP',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _getTitleForLevel(int level) {
    for (int i = levelRewards.length - 1; i >= 0; i--) {
      if (level >= levelRewards[i].level && levelRewards[i].title != null) {
        return levelRewards[i].title!;
      }
    }
    return 'RECRUIT';
  }

  Widget _buildCurrencyRow() {
    return Row(
      children: [
        Expanded(
          child: _currencyCard(
            Icons.monetization_on,
            'COINS',
            '${GameStorage.totalCoins}',
            const Color(0xFFFFD93D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _currencyCard(
            Icons.auto_awesome,
            'STARDUST',
            '${GameStorage.stardust}',
            const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _currencyCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.6), fontSize: 11, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      ('Total Runs', '${GameStorage.totalRuns}', Icons.replay),
      ('Best Distance', '${GameStorage.bestDistance.toStringAsFixed(0)}m', Icons.straighten),
      ('Highest Combo', '${GameStorage.highestCombo}', Icons.whatshot),
      ('Aliens Destroyed', '${GameStorage.totalAliensDestroyed}', Icons.pest_control),
      ('Bosses Defeated', '${GameStorage.totalBossesDefeated}', Icons.shield),
      ('Total Coins', '${GameStorage.totalCoinsCollected}', Icons.monetization_on),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'LIFETIME STATS',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          ...stats.map((s) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(s.$3, color: const Color(0xFF00D9FF), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.$1,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                    ),
                    Text(s.$2,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSkillTreePreview() {
    final branches = {
      'Offense': SkillBranch.offense,
      'Defense': SkillBranch.defense,
      'Utility': SkillBranch.utility,
    };

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'SKILL TREE',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          ...branches.entries.map((branch) {
            final skills = skillTree
                .where((s) => s.branch == branch.value)
                .toList();
            return ExpansionTile(
              title: Text(
                branch.key,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              iconColor: const Color(0xFF00D9FF),
              collapsedIconColor: Colors.white38,
              children: skills.map((skill) {
                final level = GameStorage.getSkillLevel(skill.id);
                return ListTile(
                  leading: Icon(skill.icon,
                      color: level > 0
                          ? const Color(0xFF00D9FF)
                          : Colors.white24),
                  title: Text(
                    '${skill.name} (Lv $level/${skill.maxLevel})',
                    style: TextStyle(
                      color: level > 0 ? Colors.white : Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    skill.description,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}
