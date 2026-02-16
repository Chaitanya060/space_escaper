import 'package:flutter/material.dart';
import '../data/game_storage.dart';

class DailyRewardScreen extends StatelessWidget {
  const DailyRewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final streak = GameStorage.dailyLoginStreak;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1929), Color(0xFF0D0D2B)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            const Icon(Icons.calendar_today, color: Color(0xFFFFD700), size: 36),
            const SizedBox(height: 10),
            const Text(
              'DAILY REWARD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Day $streak Streak!',
              style: TextStyle(
                color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            // 7-day calendar
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final day = i + 1;
                final isToday = (streak - 1) % 7 == i;
                final isClaimed = streak > 0 && (streak % 7 != 0 ? day <= streak % 7 : true);
                final reward = _rewardForDay(day);

                return Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                        : isClaimed
                            ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                            : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday
                          ? const Color(0xFFFFD700)
                          : isClaimed
                              ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                              : const Color(0xFF1E293B),
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Day $day',
                        style: TextStyle(
                          color: isToday ? Colors.white : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        reward.$1,
                        color: isClaimed
                            ? const Color(0xFF22C55E)
                            : isToday
                                ? const Color(0xFFFFD700)
                                : Colors.white38,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reward.$2,
                        style: TextStyle(
                          color: isClaimed
                              ? const Color(0xFF22C55E)
                              : Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // Claim button
            GestureDetector(
              onTap: () {
                final reward = _claimReward(streak);
                GameStorage.addCoins(reward.$1);
                GameStorage.addStardust(reward.$2);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'CLAIM REWARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String) _rewardForDay(int day) {
    switch (day) {
      case 1: return (Icons.monetization_on, '50');
      case 2: return (Icons.monetization_on, '100');
      case 3: return (Icons.auto_awesome, '5');
      case 4: return (Icons.monetization_on, '200');
      case 5: return (Icons.auto_awesome, '10');
      case 6: return (Icons.monetization_on, '500');
      case 7: return (Icons.star, '1000');
      default: return (Icons.monetization_on, '50');
    }
  }

  (int, int) _claimReward(int streak) {
    final day = ((streak - 1) % 7) + 1;
    switch (day) {
      case 1: return (50, 0);
      case 2: return (100, 0);
      case 3: return (0, 5);
      case 4: return (200, 0);
      case 5: return (0, 10);
      case 6: return (500, 0);
      case 7: return (1000, 25);
      default: return (50, 0);
    }
  }
}
