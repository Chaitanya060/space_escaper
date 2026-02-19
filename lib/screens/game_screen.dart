import 'dart:async';
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/game_storage.dart';
import '../data/powerup_data.dart';
import '../data/progression_data.dart';
import '../data/ship_data.dart';
import '../game/space_escaper_game.dart';
import 'main_menu_screen.dart';

class GameScreen extends StatefulWidget {
  final String? overrideShipId;
  final GameMode? mode;
  const GameScreen({super.key, this.overrideShipId, this.mode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late SpaceEscaperGame _game;
  bool _showPause = false;
  bool _showGameOver = false;
  bool _continueUsed = false;
  Timer? _hudTimer;

  @override
  void initState() {
    super.initState();
    _game = SpaceEscaperGame(
      overrideShipId: widget.overrideShipId,
      mode: widget.mode,
    );
    _game.onGameOver = () {
      setState(() { _showGameOver = true; });
    };
    _game.onPauseRequest = () {
      setState(() { _showPause = true; });
    };
    // Periodic HUD refresh
    _hudTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && _game.gameState == GameState.playing) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _hudTimer?.cancel();
    super.dispose();
  }

  void _resume() {
    setState(() { _showPause = false; });
    _game.resumeGame();
  }

  void _restart() {
    setState(() {
      _showPause = false;
      _showGameOver = false;
      _continueUsed = false;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  void _goToMenu() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  void _continueGame() {
    if (GameStorage.canAfford(300)) {
      GameStorage.spendCoins(300);
      setState(() {
        _showGameOver = false;
        // _continueUsed = true; // Allow multiple continues
      });
      _game.gameState = GameState.playing;
      _game.player.alive = true;
      _game.player.makeInvincible();
      _game.player.position.y = _game.size.y * 0.75;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game
          GameWidget(game: _game),

          // HUD (Stats)
          if (!_showPause && !_showGameOver) ...[
            _buildHUD(),
            _buildConsumableBar(),
            _buildControls(),
            _buildPauseButton(),
            if (_game.isLoaded && _game.currentShip.activeType != ActiveAbilityType.none)
              _buildActiveAbilityButton(),
          ],

          // Pause overlay
          if (_showPause)
            _buildPauseOverlay(),

          // Game over overlay
          if (_showGameOver)
            _buildGameOverOverlay(),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Top row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Distance
                Text(
                  _game.distanceFormatted,
                  style: GoogleFonts.orbitron(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      const Shadow(color: Color(0x8000D9FF), blurRadius: 20),
                    ],
                  ),
                ),
                // Currency (Coins + Stardust)
                Row(
                  children: [
                    // Coins
                    Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD93D),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_game.runCoins}',
                      style: GoogleFonts.orbitron(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFD93D),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${GameStorage.stardust}',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Biome name (fades when transition completes)
            if (_game.isLoaded && _game.starfield.biomeTransitionTimer > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _game.starfield.currentBiomeName,
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00D9FF),
                    letterSpacing: 3,
                  ),
                ),
              ),

            // Physics mode
            if (_game.currentPhysicsMode != 'normal')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _game.getPhysicsModeColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _game.getPhysicsModeColor().withValues(alpha: 0.4)),
                ),
                child: Text(
                  _game.getPhysicsModeLabel(),
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _game.getPhysicsModeColor(),
                  ),
                ),
              ),

            // Boss banner
            if (_game.showBanner)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: _game.bannerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _game.bannerColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _game.bannerText,
                  style: GoogleFonts.orbitron(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _game.bannerColor,
                  ),
                ),
              ),

            // Boss name badge (health bar is now inside the boss)
            if (_game.bossActive && _game.currentBoss != null)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _game.currentBoss!.config.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _game.currentBoss!.config.color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${_game.currentBoss!.config.emoji} ${_game.currentBoss!.config.name.toUpperCase()}',
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _game.currentBoss!.config.color,
                  ),
                ),
              ),

            // Combo
            if (_game.combo >= 3)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD93D).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'COMBO x${_game.combo}${_game.multiplier > 1 ? " (${_game.multiplier}x)" : ""}',
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFD93D),
                  ),
                ),
            ),

            // Active power-ups
            if (_game.activePowerUps.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  children: _game.activePowerUps.entries.map((e) {
                    final info = getPowerUpInfo(e.key);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: info.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: info.color.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(info.icon, color: info.color, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${e.value.toInt()}s',
                            style: TextStyle(color: info.color, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            const Spacer(),
            // Speed bar
            Container(
              height: 4,
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ((_game.speedMultiplier - 1) / 2).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D9FF), Color(0xFFFF6B35)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: const Color(0xFF00D9FF).withValues(alpha: 0.5), blurRadius: 6)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => _game.fireBullet(),
          child: Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF0000).withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF0000).withValues(alpha: 0.6), width: 3),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFF0000).withValues(alpha: 0.4), blurRadius: 20),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 40),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveAbilityButton() {
    return Positioned(
      bottom: 40,
      right: 20,
      child: GestureDetector(
        onTap: () {
          if (_game.activeAbilityCooldownTimer <= 0) {
            _game.triggerActiveAbility();
          }
        },
        child: SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cooldown ring
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: _game.activeAbilityCooldownTimer > 0
                      ? 1.0 - (_game.activeAbilityCooldownTimer / _game.currentShip.activeCooldown)
                      : 1.0,
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _game.activeAbilityCooldownTimer <= 0
                        ? _game.currentShip.color
                        : Colors.grey,
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              // Button background
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _game.activeAbilityCooldownTimer <= 0
                      ? _game.currentShip.color.withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.2),
                  border: Border.all(
                    color: _game.activeAbilityCooldownTimer <= 0
                        ? _game.currentShip.color.withValues(alpha: 0.8)
                        : Colors.grey.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: _game.activeAbilityCooldownTimer <= 0
                      ? [BoxShadow(color: _game.currentShip.color.withValues(alpha: 0.4), blurRadius: 12)]
                      : [],
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: _game.activeAbilityCooldownTimer <= 0
                      ? Colors.white
                      : Colors.grey,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsumableBar() {
    return Positioned(
      left: 8,
      bottom: 140,
      child: Column(
        children: allConsumables.map((c) {
          final owned = GameStorage.getConsumableCount(c.type.name);
          final isUsable = owned > 0 && _game.gameState == GameState.playing;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: isUsable ? () => _useConsumableInGame(c) : null,
              child: Opacity(
                opacity: isUsable ? 1.0 : 0.35,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.color.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      Center(child: Icon(c.icon, color: c.color, size: 24)),
                      Positioned(
                        right: 4,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'x$owned',
                            style: GoogleFonts.orbitron(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _useConsumableInGame(ConsumableInfo c) {
    if (c.type == ConsumableType.shieldCharge && _game.activePowerUps.containsKey(PowerUpType.shield)) {
      return;
    }
    if (!GameStorage.useConsumable(c.type.name)) return;

    setState(() {});

    switch (c.type) {
      case ConsumableType.headStart:
        _game.distance += 2000;
        _game.currentSpeed = _game.baseSpeed * 1.5;
        _game.player.makeInvincible();
        _game.activePowerUps[PowerUpType.invincibility] = 5.0;
        _game.screenEffects.triggerSpeedBurst();
        break;
      case ConsumableType.shieldCharge:
        _game.activePowerUps[PowerUpType.shield] = 20.0;
        break;
      case ConsumableType.damageCore:
        _game.activePowerUps[PowerUpType.damageBoost] = getPowerUpInfo(PowerUpType.damageBoost).duration;
        break;
      case ConsumableType.xpBooster:
        _game.xpBoosterActive = true;
        break;
    }

    // Show banner in game
    _game.showBanner = true;
    _game.bannerTimer = 1.5;
    _game.bannerText = '${c.name.toUpperCase()} ACTIVATED!';
    _game.bannerColor = c.color;
  }

  Widget _buildPauseButton() {
    return Positioned(
      top: 84, // slightly below coins
      right: 16,
      child: GestureDetector(
        onTap: () => _game.pauseGame(),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: const Icon(Icons.pause, color: Colors.white54, size: 24),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black54,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: _glassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('PAUSED', style: GoogleFonts.orbitron(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  color: const Color(0xFF00D9FF),
                  shadows: [const Shadow(color: Color(0x6600D9FF), blurRadius: 20)],
                )),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _pauseStat('Distance', _game.distanceFormatted),
                    _pauseStat('Crystals', '${_game.runCoins}'),
                    _pauseStat('Time', '${_game.timeSurvived.toInt()}s'),
                  ],
                ),
                const SizedBox(height: 24),
                _overlayButton('▶  RESUME', isPrimary: true, onTap: _resume),
                const SizedBox(height: 10),
                _overlayButton('↻  RESTART', onTap: _restart),
                const SizedBox(height: 10),
                _overlayButton('◂  MAIN MENU', onTap: _goToMenu),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    final isNewBest = _game.distance >= GameStorage.bestDistance;
    final level = levelFromXp(GameStorage.playerXp);
    final progress = xpProgress(GameStorage.playerXp);

    return Container(
      color: Colors.black54,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: SingleChildScrollView(
            child: _glassPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('MISSION FAILED', style: GoogleFonts.orbitron(
                    fontSize: 28, fontWeight: FontWeight.w900,
                    color: const Color(0xFFEF4444),
                    shadows: [const Shadow(color: Color(0x80EF4444), blurRadius: 25)],
                  )),
                  if (isNewBest) ...[
                    const SizedBox(height: 8),
                    Text('★ NEW BEST DISTANCE! ★', style: GoogleFonts.orbitron(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: const Color(0xFFFFD93D),
                      shadows: [const Shadow(color: Color(0x80FFD93D), blurRadius: 15)],
                    )),
                  ],
                  const SizedBox(height: 16),
                  _resultRow('Distance', _game.distanceFormatted, const Color(0xFF00D9FF)),
                  const SizedBox(height: 6),
                  _resultRow('Crystals', '${_game.runCoins}', const Color(0xFFFFD93D)),
                  const SizedBox(height: 6),
                  _resultRow('Max Combo', '${_game.maxCombo}', const Color(0xFFFF6B35)),
                  const SizedBox(height: 6),
                  _resultRow('Aliens', '${_game.aliensKilledThisRun}', const Color(0xFFEF4444)),
                  const SizedBox(height: 6),
                  _resultRow('Bosses', '${_game.bossesKilledThisRun}', const Color(0xFFA855F7)),
                  const SizedBox(height: 12),

                  // XP bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9FF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('LV $level', style: GoogleFonts.orbitron(
                              fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF00D9FF),
                            )),
                            Text('LV ${level + 1}', style: GoogleFonts.orbitron(
                              fontSize: 12, color: Colors.white38,
                            )),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFF1E293B),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  _overlayButton(
                    'CONTINUE (300 ✦)',
                    onTap: GameStorage.canAfford(300) ? _continueGame : null,
                    isDisabled: !GameStorage.canAfford(300),
                  ),
                  const SizedBox(height: 10),
                  _overlayButton('↻  RESTART', isPrimary: true, onTap: _restart),
                  const SizedBox(height: 10),
                  _overlayButton('◂  MAIN MENU', onTap: _goToMenu),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassPanel({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1929).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 32)],
      ),
      child: child,
    );
  }

  Widget _pauseStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 9, letterSpacing: 1.5, color: Colors.white38)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }

  Widget _resultRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, letterSpacing: 1.5, color: Colors.white38)),
          Text(value, style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _overlayButton(String label, {bool isPrimary = false, VoidCallback? onTap, bool isDisabled = false}) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPrimary
                  ? [const Color(0xFF00D9FF).withValues(alpha: 0.3), const Color(0xFF6B46C1).withValues(alpha: 0.3)]
                  : [const Color(0xFF00D9FF).withValues(alpha: 0.1), const Color(0xFF6B46C1).withValues(alpha: 0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary
                  ? const Color(0xFF00D9FF).withValues(alpha: 0.5)
                  : const Color(0xFF00D9FF).withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Text(label, style: GoogleFonts.orbitron(
              fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2,
              color: Colors.white,
            )),
          ),
        ),
      ),
    );
  }
}
