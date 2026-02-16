import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/game_storage.dart';
import '../data/ship_data.dart';
import 'game_screen.dart';

class ShipSelectScreen extends StatefulWidget {
  const ShipSelectScreen({super.key});

  @override
  State<ShipSelectScreen> createState() => _ShipSelectScreenState();
}

class _ShipSelectScreenState extends State<ShipSelectScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = ships.indexWhere((s) => s.id == GameStorage.selectedShip);
    if (_currentIndex < 0) _currentIndex = 0;
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.75,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _purchase(ShipData ship) {
    if (GameStorage.spendCoins(ship.cost)) {
      GameStorage.unlockShip(ship.id);
      GameStorage.selectedShip = ship.id;
      setState(() {});
    }
  }

  void _tryShip(ShipData ship) {
    if (ship.testDriveCost <= 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameScreen(overrideShipId: ship.id)),
      );
      return;
    }
    if (GameStorage.spendCoins(ship.testDriveCost)) {
      setState(() {});
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameScreen(overrideShipId: ship.id)),
      );
    }
  }

  Widget _buildActionsBelowCard(ShipData ship) {
    final isUnlocked = GameStorage.isShipUnlocked(ship.id);
    final isEquipped = GameStorage.selectedShip == ship.id;
    final canBuy = ship.cost > 0 && GameStorage.canAfford(ship.cost);
    final canTry = GameStorage.canAfford(ship.testDriveCost);

    if (isUnlocked && isEquipped) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.6)),
          color: const Color(0xFF34D399).withValues(alpha: 0.12),
        ),
        child: Center(
          child: Text('EQUIPPED',
              style: GoogleFonts.orbitron(
                  color: const Color(0xFF34D399),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3)),
        ),
      );
    }

    if (isUnlocked && !isEquipped) {
      return GestureDetector(
        onTap: () {
          GameStorage.selectedShip = ship.id;
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.6)),
            color: const Color(0xFF00D9FF).withValues(alpha: 0.12),
          ),
          child: Center(
            child: Text('EQUIP',
                style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3)),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: canTry ? () => _tryShip(ship) : null,
            child: Opacity(
              opacity: canTry ? 1 : 0.4,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.6)),
                  color: Colors.orangeAccent.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Text(
                    ship.testDriveCost > 0 ? 'TRY  ${ship.testDriveCost} ✦' : 'TRY',
                    style: GoogleFonts.orbitron(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: canBuy ? () => _purchase(ship) : null,
            child: Opacity(
              opacity: canBuy ? 1 : 0.4,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD93D).withValues(alpha: 0.6)),
                  color: const Color(0xFFFFD93D).withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Text(
                    ship.cost > 0 ? 'BUY  ${ship.cost} ✦' : 'UNLOCK',
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFFFFD93D),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

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
                    Text('SPACECRAFT', style: GoogleFonts.orbitron(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white,
                      shadows: [const Shadow(color: Color(0x6600D9FF), blurRadius: 12)],
                    )),
                    const Spacer(),
                    Row(
                      children: [
                        Container(width: 12, height: 12,
                          decoration: const BoxDecoration(color: Color(0xFFFFD93D), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('${GameStorage.totalCoins}', style: GoogleFonts.orbitron(
                          fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFFFD93D),
                        )),
                      ],
                    ),
                  ],
                ),
              ),

              // Ship carousel
              Expanded(
                flex: 5,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemCount: ships.length,
                  itemBuilder: (context, index) {
                    final ship = ships[index];
                    final isSelected = index == _currentIndex;
                    return AnimatedScale(
                      scale: isSelected ? 1.0 : 0.85,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1929).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: GameStorage.selectedShip == ship.id
                                  ? ship.color.withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.1),
                              width: GameStorage.selectedShip == ship.id ? 2 : 1,
                            ),
                            boxShadow: [BoxShadow(
                              color: ship.color.withValues(alpha: isSelected ? 0.15 : 0),
                              blurRadius: 24,
                            )],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Ship preview
                              Container(
                                width: 80, height: 100,
                                decoration: BoxDecoration(
                                  boxShadow: [BoxShadow(color: ship.color.withValues(alpha: 0.3), blurRadius: 20)],
                                ),
                                child: CustomPaint(
                                  painter: ShipPreviewPainter(ship.color),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(ship.name, style: GoogleFonts.orbitron(
                                fontSize: 16, fontWeight: FontWeight.w700, color: ship.color,
                                shadows: [Shadow(color: ship.color.withValues(alpha: 0.4), blurRadius: 12)],
                              )),
                              const SizedBox(height: 6),
                              Text(ship.description, textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                              ),
                              const SizedBox(height: 12),
                              // Stats
                              _statBar('SPD', ship.speedStat, const Color(0xFF00D9FF)),
                              const SizedBox(height: 4),
                              _statBar('AGI', ship.agilityStat, const Color(0xFF34D399)),
                              const SizedBox(height: 4),
                              _statBar('SHD', ship.shieldStat, const Color(0xFF6B46C1)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: ship.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(ship.abilityDesc, style: GoogleFonts.inter(
                                  fontSize: 10, fontWeight: FontWeight.w600, color: ship.color,
                                )),
                              ),
                            ],
                          ),
                        ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 4),
                child: _buildActionsBelowCard(ships[_currentIndex]),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(width: 32,
          child: Text(label, style: GoogleFonts.orbitron(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white38))),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (value / 10).clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

}

class ShipPreviewPainter extends CustomPainter {
  final Color color;
  ShipPreviewPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final paint = Paint()..color = color;

    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(0, h)
      ..lineTo(w / 4, h * 0.82)
      ..lineTo(w / 2, h * 0.9)
      ..lineTo(w * 0.75, h * 0.82)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    final cockpitPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.35), width: w / 3, height: h / 3),
      cockpitPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
