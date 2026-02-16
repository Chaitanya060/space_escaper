import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/game_storage.dart';
import '../data/progression_data.dart';
import 'game_screen.dart';
import 'ship_select_screen.dart';
import 'settings_screen.dart';
import 'missions_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'daily_reward_screen.dart';
import '../game/space_escaper_game.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // Check daily login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (GameStorage.checkDailyLogin()) {
        showDialog(
          context: context,
          builder: (_) => const DailyRewardScreen(),
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = levelFromXp(GameStorage.playerXp);

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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D9FF), Color(0xFF0066FF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        'LV $level',
                        style: GoogleFonts.orbitron(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF00D9FF), Color(0xFF6B46C1), Color(0xFFFF6B35)],
                        ).createShader(bounds),
                        child: Text(
                          'SPACE\nESCAPER',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.orbitron(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'INFINITE SPACE RUNNER',
                      style: GoogleFonts.orbitron(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 6,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Currency row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statWidget('COINS', GameStorage.totalCoins.toString(), const Color(0xFFFFD93D)),
                        const SizedBox(width: 20),
                        _statWidget('STARDUST', GameStorage.stardust.toString(), const Color(0xFF8B5CF6)),
                        const SizedBox(width: 20),
                        _statWidget('BEST', _formatDistance(GameStorage.bestDistance), const Color(0xFF00D9FF)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Main action buttons
                    _holoButton('▶  LAUNCH', isPrimary: true, onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF0A1929),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => _modePicker(),
                      );
                    }),
                    const SizedBox(height: 12),
                    _holoButton('✦  SPACECRAFT', onTap: () {
                      Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ShipSelectScreen()));
                    }),
                    const SizedBox(height: 12),

                    // Feature row (Missions, Profile, Shop)
                    Row(
                      children: [
                        Expanded(
                          child: _compactButton(Icons.assignment, 'MISSIONS', onTap: () {
                            Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MissionsScreen()));
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _compactButton(Icons.person, 'PROFILE', onTap: () {
                            Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen()));
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _compactButton(Icons.store, 'SHOP', onTap: () {
                            Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ShopScreen()));
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _holoButton('⚙  SETTINGS', onTap: () {
                      Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    }),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeChip(String title, Color color, VoidCallback onTap, {String? subtitle}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.orbitron(color: color, fontWeight: FontWeight.w800)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _modePicker() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('SELECT MODE', style: GoogleFonts.orbitron(
              color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3)),
            const SizedBox(height: 12),
            _modeChip('CLASSIC', const Color(0xFF00D9FF), () {
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const GameScreen()));
            }, subtitle: 'Endless survival, increasing difficulty'),
            const SizedBox(height: 10),
            _modeChip('TIME ATTACK 90s', const Color(0xFFF97316), () {
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const GameScreen(mode: GameMode.timeAttack, timeLimitSec: 90)));
            }, subtitle: 'Reach maximum distance before the clock runs out'),
            const SizedBox(height: 10),
            _modeChip('COIN FRENZY', const Color(0xFFFFD93D), () {
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const GameScreen(mode: GameMode.coinFrenzy, timeLimitSec: 120)));
            }, subtitle: '2 minutes of massive coins, minimal danger'),
            const SizedBox(height: 10),
            _modeChip('SURVIVAL HELL', const Color(0xFFEF4444), () {
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const GameScreen(mode: GameMode.survivalHell)));
            }, subtitle: 'One hit death, dense obstacles, stardust rewards'),
            const SizedBox(height: 10),
            _modeChip('BOSS RUSH', const Color(0xFFA855F7), () {
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const GameScreen(mode: GameMode.bossRush)));
            }, subtitle: 'Defeat 5 bosses in a row'),
            const SizedBox(height: 10),
            _modeChip('OBSTACLES ONLY', const Color(0xFF34D399), () {
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const GameScreen(mode: GameMode.obstaclesOnly)));
            }, subtitle: 'No coins. Pure dodging with wild physics'),
            const SizedBox(height: 10),
            _modeChip('ZEN', const Color(0xFF10B981), () {
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const GameScreen(mode: GameMode.zen)));
            }, subtitle: 'Relaxing, minimal obstacles, no death'),
            const SizedBox(height: 10),
            _modeChip('GAUNTLET', const Color(0xFFFF6B35), () {
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const GameScreen(mode: GameMode.gauntlet)));
            }, subtitle: '10 escalating challenge waves'),
          ],
        ),
      ),
    );
  }

  Widget _statWidget(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            letterSpacing: 2,
            color: Colors.white38,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
            shadows: [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 12)],
          ),
        ),
      ],
    );
  }

  Widget _holoButton(String label, {bool isPrimary = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPrimary
                ? [const Color(0xFF00D9FF).withValues(alpha: 0.3), const Color(0xFF6B46C1).withValues(alpha: 0.3)]
                : [const Color(0xFF00D9FF).withValues(alpha: 0.12), const Color(0xFF6B46C1).withValues(alpha: 0.12)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFF00D9FF).withValues(alpha: 0.6)
                : const Color(0xFF00D9FF).withValues(alpha: 0.25),
          ),
          boxShadow: isPrimary
              ? [BoxShadow(color: const Color(0xFF00D9FF).withValues(alpha: 0.2), blurRadius: 20)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Colors.white,
              shadows: [Shadow(color: const Color(0xFF00D9FF).withValues(alpha: 0.5), blurRadius: 10)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactButton(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF00D9FF).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00D9FF), size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white54,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double d) {
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(1)} km';
    return '${d.toInt()} m';
  }
}
