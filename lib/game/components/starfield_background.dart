import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../space_escaper_game.dart';

// ═══════════════════════════════════════
//  BIOME DEFINITIONS
// ═══════════════════════════════════════

class Biome {
  final String name;
  final Color bgTop;
  final Color bgMid;
  final Color bgBottom;
  final List<Color> starColors;
  final List<Color> nebulaColors;
  final double nebulaAlpha;
  final double starDensityMult;

  const Biome({
    required this.name,
    required this.bgTop,
    required this.bgMid,
    required this.bgBottom,
    required this.starColors,
    required this.nebulaColors,
    this.nebulaAlpha = 0.04,
    this.starDensityMult = 1.0,
  });
}

const List<Biome> biomes = [
  Biome(
    name: 'DEEP SPACE',
    bgTop: Color(0xFF050D1A),
    bgMid: Color(0xFF0A1929),
    bgBottom: Color(0xFF0D0D2B),
    starColors: [Colors.white, Color(0xFFAADDFF), Color(0xFFFFDDAA), Color(0xFFDDAAFF)],
    nebulaColors: [Color(0xFF6B46C1), Color(0xFF00D9FF), Color(0xFFFF6B35)],
  ),
  Biome(
    name: 'NEBULA ZONE',
    bgTop: Color(0xFF0D0825),
    bgMid: Color(0xFF1A0A3E),
    bgBottom: Color(0xFF2D1B69),
    starColors: [Color(0xFFFF99CC), Color(0xFFCC99FF), Color(0xFF99CCFF), Colors.white],
    nebulaColors: [Color(0xFFE040FB), Color(0xFF7C4DFF), Color(0xFF448AFF)],
    nebulaAlpha: 0.07,
  ),
  Biome(
    name: 'ASTEROID BELT',
    bgTop: Color(0xFF1A0F00),
    bgMid: Color(0xFF2D1A00),
    bgBottom: Color(0xFF3D2400),
    starColors: [Color(0xFFFFCC88), Color(0xFFFF9944), Color(0xFFFFDDAA), Colors.white],
    nebulaColors: [Color(0xFFFF6B35), Color(0xFFFF9800), Color(0xFF795548)],
    nebulaAlpha: 0.05,
    starDensityMult: 0.7,
  ),
  Biome(
    name: 'DARK VOID',
    bgTop: Color(0xFF000000),
    bgMid: Color(0xFF050505),
    bgBottom: Color(0xFF0A0A0A),
    starColors: [Color(0xFF444444), Color(0xFF666666), Color(0xFF333333)],
    nebulaColors: [Color(0xFF1A1A1A), Color(0xFF222222)],
    nebulaAlpha: 0.02,
    starDensityMult: 0.4,
  ),
  Biome(
    name: 'GALACTIC CORE',
    bgTop: Color(0xFF1A100A),
    bgMid: Color(0xFF2D1A0A),
    bgBottom: Color(0xFF3D2A1A),
    starColors: [Colors.white, Color(0xFFFFD700), Color(0xFFFFF176), Color(0xFFFFE0B2)],
    nebulaColors: [Color(0xFFFFD700), Color(0xFFFFF176), Color(0xFFFFAB40)],
    nebulaAlpha: 0.08,
    starDensityMult: 1.5,
  ),
];

Biome getBiomeForDistance(double distance) {
  if (distance < 2000) return biomes[0];
  if (distance < 4000) return biomes[1];
  if (distance < 6000) return biomes[2];
  if (distance < 8000) return biomes[3];
  return biomes[4];
}

double getBiomeTransition(double distance) {
  final thresholds = [0.0, 2000.0, 4000.0, 6000.0, 8000.0];
  for (int i = thresholds.length - 1; i >= 1; i--) {
    if (distance >= thresholds[i]) {
      final progress = ((distance - thresholds[i]) / 500).clamp(0.0, 1.0);
      return progress;
    }
  }
  return 1.0;
}

// ═══════════════════════════════════════
//  STAR / NEBULA CLASSES
// ═══════════════════════════════════════

class Star {
  double x, y;
  final int layer;
  final double starSize;
  final double twinkleSpeed;
  final double twinkleOffset;
  final double baseAlpha;
  Color color;

  Star(double w, double h, this.layer)
      : x = Random().nextDouble() * w,
        y = Random().nextDouble() * h,
        starSize = layer == 0
            ? 0.5 + Random().nextDouble()
            : layer == 1
                ? 1 + Random().nextDouble() * 1.5
                : 1.5 + Random().nextDouble() * 2,
        twinkleSpeed = 1 + Random().nextDouble() * 3,
        twinkleOffset = Random().nextDouble() * pi * 2,
        baseAlpha = layer == 0
            ? 0.3 + Random().nextDouble() * 0.3
            : layer == 1
                ? 0.4 + Random().nextDouble() * 0.3
                : 0.5 + Random().nextDouble() * 0.4,
        color = Colors.white;

  void updateColor(List<Color> palette) {
    color = palette[x.toInt() % palette.length];
  }
}

class NebulaSplash {
  double x, y;
  final double radius;
  Color color;
  double alpha;
  final double speed;

  NebulaSplash(double w, double h)
      : x = Random().nextDouble() * w,
        y = Random().nextDouble() * h,
        radius = 100 + Random().nextDouble() * 200,
        color = const Color(0xFF6B46C1),
        alpha = 0.04,
        speed = 0.1 + Random().nextDouble() * 0.2;

  void updateBiome(List<Color> palette, double nebulaAlpha) {
    color = palette[x.toInt() % palette.length];
    alpha = nebulaAlpha;
  }
}

// ═══════════════════════════════════════
//  STARFIELD BACKGROUND COMPONENT
// ═══════════════════════════════════════

class StarfieldBackground extends Component
    with HasGameReference<SpaceEscaperGame> {
  final List<Star> stars = [];
  final List<NebulaSplash> nebulae = [];
  double time = 0;
  bool _initialized = false;
  String _lastBiomeName = '';
  String currentBiomeName = 'DEEP SPACE';
  double biomeTransitionTimer = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_initialized) {
      _generate(size.x, size.y);
      _initialized = true;
    }
  }

  void _generate(double w, double h) {
    stars.clear();
    nebulae.clear();
    final area = w * h;
    final c0 = (area / 3000).floor();
    final c1 = (area / 6000).floor();
    final c2 = (area / 10000).floor();
    for (int i = 0; i < c0; i++) { stars.add(Star(w, h, 0)); }
    for (int i = 0; i < c1; i++) { stars.add(Star(w, h, 1)); }
    for (int i = 0; i < c2; i++) { stars.add(Star(w, h, 2)); }
    for (int i = 0; i < 5; i++) { nebulae.add(NebulaSplash(w, h)); }
  }

  @override
  void update(double dt) {
    time += dt;
    final gameSpeed = game.gameState == GameState.playing
        ? game.speedMultiplier
        : 0.3;
    final speeds = [0.3, 0.7, 1.2];

    // Update biome
    final biome = getBiomeForDistance(game.distance);
    currentBiomeName = biome.name;
    if (_lastBiomeName != biome.name) {
      _lastBiomeName = biome.name;
      biomeTransitionTimer = 3.0; // Show biome name for 3s
      // Update star/nebula colors
      for (final star in stars) { star.updateColor(biome.starColors); }
      for (final n in nebulae) { n.updateBiome(biome.nebulaColors, biome.nebulaAlpha); }
    }

    if (biomeTransitionTimer > 0) biomeTransitionTimer -= dt;

    for (final star in stars) {
      star.y += speeds[star.layer] * gameSpeed * 60 * dt;
      if (star.y > game.size.y + 10) {
        star.y = -10;
        star.x = Random().nextDouble() * game.size.x;
      }
    }

    for (final n in nebulae) {
      n.y += n.speed * gameSpeed * 60 * dt;
      if (n.y > game.size.y + n.radius * 2) {
        n.y = -n.radius * 2;
        n.x = Random().nextDouble() * game.size.x;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;

    // Biome-based gradient
    final biome = getBiomeForDistance(game.distance);
    final gradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [biome.bgTop, biome.bgMid, biome.bgBottom],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), gradient);

    // Nebulae
    for (final n in nebulae) {
      final nebPaint = Paint()
        ..shader = RadialGradient(
          colors: [n.color.withValues(alpha: n.alpha), n.color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset(n.x, n.y), radius: n.radius));
      canvas.drawCircle(Offset(n.x, n.y), n.radius, nebPaint);
    }

    // Stars
    for (final star in stars) {
      final twinkle = sin(time * star.twinkleSpeed + star.twinkleOffset) * 0.3 + 0.7;
      final paint = Paint()
        ..color = star.color.withValues(alpha: star.baseAlpha * twinkle);
      canvas.drawCircle(Offset(star.x, star.y), star.starSize, paint);
    }
  }
}
