import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/game_storage.dart';
import '../data/ship_data.dart';

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

  void _purchase() {
    final ship = ships[_currentIndex];
    if (GameStorage.spendCoins(ship.cost)) {
      GameStorage.unlockShip(ship.id);
      GameStorage.selectedShip = ship.id;
      setState(() {});
    }
  }

  void _equip() {
    GameStorage.selectedShip = ships[_currentIndex].id;
    setState(() {});
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

              // Action button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                child: _buildActionButton(),
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

  Widget _buildActionButton() {
    final ship = ships[_currentIndex];
    final isUnlocked = GameStorage.isShipUnlocked(ship.id);
    final isEquipped = GameStorage.selectedShip == ship.id;
    final canBuy = GameStorage.canAfford(ship.cost);

    if (isEquipped) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF34D399).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Text('EQUIPPED', style: GoogleFonts.orbitron(
            fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2, color: const Color(0xFF34D399),
          )),
        ),
      );
    }

    if (isUnlocked) {
      return GestureDetector(
        onTap: _equip,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF00D9FF).withValues(alpha: 0.25), const Color(0xFF6B46C1).withValues(alpha: 0.25)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text('EQUIP', style: GoogleFonts.orbitron(
              fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2, color: Colors.white,
            )),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: canBuy ? _purchase : null,
      child: Opacity(
        opacity: canBuy ? 1 : 0.4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFFFD93D).withValues(alpha: 0.25), const Color(0xFFFF6B35).withValues(alpha: 0.25)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD93D).withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text('BUY  ${ship.cost} ✦', style: GoogleFonts.orbitron(
              fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2, color: const Color(0xFFFFD93D),
            )),
          ),
        ),
      ),
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
