import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/game_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050D1A), Color(0xFF0A1929), Color(0xFF0D0D2B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white54, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text('SETTINGS', style: GoogleFonts.orbitron(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white,
                      shadows: [const Shadow(color: Color(0x6600D9FF), blurRadius: 12)],
                    )),
                    const Spacer(),
                    const SizedBox(width: 40), // Balance the header
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Sound toggle
                    _settingTile(
                      icon: Icons.volume_up,
                      label: 'Sound Effects',
                      value: GameStorage.soundEnabled,
                      onChanged: (v) => setState(() => GameStorage.soundEnabled = v),
                    ),
                    const SizedBox(height: 12),
                    // Music toggle
                    _settingTile(
                      icon: Icons.music_note,
                      label: 'Music',
                      value: GameStorage.musicEnabled,
                      onChanged: (v) => setState(() => GameStorage.musicEnabled = v),
                    ),
                    const SizedBox(height: 30),

                    // Stats section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STATISTICS', style: GoogleFonts.orbitron(
                            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 2,
                          )),
                          const SizedBox(height: 14),
                          _statRow('Total Runs', '${GameStorage.totalRuns}'),
                          _statRow('Total Distance', _formatDist(GameStorage.totalDistanceTraveled)),
                          _statRow('Best Distance', _formatDist(GameStorage.bestDistance)),
                          _statRow('High Score', '${GameStorage.highScore}'),
                          _statRow('Coins Collected', '${GameStorage.totalCoinsCollected}'),
                          _statRow('Ships Unlocked', '${GameStorage.unlockedShips.length} / 8'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Reset
                    GestureDetector(
                      onTap: _confirmReset,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text('RESET ALL PROGRESS', style: GoogleFonts.orbitron(
                            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2,
                            color: const Color(0xFFEF4444),
                          )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D9FF), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70,
            )),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF00D9FF),
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
          Text(value, style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1929),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset Progress?', style: GoogleFonts.orbitron(
          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
        )),
        content: Text(
          'This will erase all coins, unlocked ships, and scores. This cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              GameStorage.resetProgress();
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text('Reset', style: GoogleFonts.inter(color: const Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  String _formatDist(double d) {
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(1)} km';
    return '${d.toInt()} m';
  }
}
