import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/game_storage.dart';
import '../data/progression_data.dart';
import '../data/powerup_data.dart';
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

    // DEBUG: Grant consumables for testing
    // GameStorage.debugGrantConsumables();

    // Check daily login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (GameStorage.checkDailyLogin()) {
        showDialog(
          context: context,
          builder: (_) => const DailyRewardScreen(),
        ).then((_) {
          if (mounted) setState(() {});
        });
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
                        isScrollControlled: true, // Allow taller sheet
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => StatefulBuilder( // Use StatefulBuilder to rebuild the sheet
                          builder: (context, setSheetState) {
                            return _buildLaunchSheet(setSheetState);
                          }
                        ),
                      ).then((_) {
                        // Refresh main menu when returning from sheet (in case consumables changed)
                        if (mounted) setState(() {});
                      });
                    }),
                    const SizedBox(height: 12),
                    _holoButton('✦  SPACECRAFT', onTap: () {
                      Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ShipSelectScreen())
                      ).then((_) {
                        if (mounted) setState(() {});
                      });
                    }),
                    const SizedBox(height: 12),

                    // Feature row (Missions, Profile, Shop)
                    Row(
                      children: [
                        Expanded(
                          child: _compactButton(Icons.assignment, 'MISSIONS', onTap: () {
                            Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MissionsScreen())
                            ).then((_) {
                              if (mounted) setState(() {});
                            });
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _compactButton(Icons.person, 'PROFILE', onTap: () {
                            Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen())
                            ).then((_) {
                              if (mounted) setState(() {});
                            });
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _compactButton(Icons.store, 'SHOP', onTap: () {
                            Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ShopScreen())
                            ).then((_) {
                              if (mounted) setState(() {});
                            });
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

  Widget _buildLaunchSheet(StateSetter setSheetState) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.75, // Taller for loadout
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MISSION PREP', style: GoogleFonts.orbitron(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Text('LOADOUT', style: GoogleFonts.orbitron(
            color: const Color(0xFF00D9FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 10),
          
          // Loadout Selector
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allConsumables.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final c = allConsumables[index];
                final owned = GameStorage.getConsumableCount(c.type.name);
                final isActive = GameStorage.isConsumableActive(c.type.name);
                
                return GestureDetector(
                  onTap: () {
                    if (owned > 0 || isActive) {
                      GameStorage.toggleActiveConsumable(c.type.name);
                      setSheetState(() {}); // Rebuild sheet to show toggle
                    } else {
                       // Quick Buy Dialog logic could go here
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                           content: Text('Buy more ${c.name} in the Shop!'),
                           backgroundColor: Colors.red,
                           duration: const Duration(seconds: 1),
                         )
                       );
                    }
                  },
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: isActive 
                          ? c.color.withValues(alpha: 0.2)
                          : const Color(0xFF0A1929),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? c.color : Colors.white12,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(c.icon, color: owned > 0 || isActive ? c.color : Colors.white24, size: 28),
                        const SizedBox(height: 6),
                        Text('x$owned', style: GoogleFonts.orbitron(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(c.name.split(' ').first, style: TextStyle( // Short name
                          color: Colors.white54, fontSize: 9), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),

          Text('SELECT MODE', style: GoogleFonts.orbitron(
            color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
          const SizedBox(height: 12),
          
          Expanded(
            child: ListView(
              children: [
                _modeChip('CLASSIC', const Color(0xFF00D9FF), () {
                  _startGame(GameMode.endless);
                }, subtitle: 'Endless survival, increasing difficulty'),
                const SizedBox(height: 10),
                _modeChip('SURVIVAL HELL', const Color(0xFFEF4444), () {
                  _startGame(GameMode.survivalHell);
                }, subtitle: 'One hit death, dense obstacles, stardust rewards'),
                const SizedBox(height: 10),
                _modeChip('BOSS RUSH', const Color(0xFFA855F7), () {
                  _startGame(GameMode.bossRush);
                }, subtitle: 'Defeat 5 bosses in a row'),
                const SizedBox(height: 10),
                _modeChip('GAUNTLET', const Color(0xFFFF6B35), () {
                  _startGame(GameMode.gauntlet);
                }, subtitle: '10 escalating challenge waves'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _startGame(GameMode mode) {
    Navigator.pop(context);
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => GameScreen(mode: mode)));
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
    // ... existing _holoButton implementation ...
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
    // ... existing _compactButton implementation ...
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
