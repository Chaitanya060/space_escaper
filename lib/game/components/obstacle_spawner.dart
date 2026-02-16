import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../space_escaper_game.dart';
import 'player_component.dart';
import 'alien_component.dart';

// Base obstacle component
class ObstacleComponent extends PositionComponent
    with HasGameReference<SpaceEscaperGame>, CollisionCallbacks {
  final String type;
  double vx;
  double vy;
  double rotationSpeed;
  double time = 0;
  double extraRadius = 10;
  bool hasCollided = false;

  ObstacleComponent({
    required this.type,
    required Vector2 position,
    required Vector2 size,
    this.vx = 0,
    this.vy = 0,
    this.rotationSpeed = 0,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    if (type == 'blackhole' || type == 'solarflare') {
      add(CircleHitbox(radius: size.x / 2));
    } else {
      add(RectangleHitbox());
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
    angle += rotationSpeed * dt;

    final speed = game.currentSpeed;

    switch (type) {
      case 'asteroid':
        position.y += (speed * 0.5 + vy) * dt;
        position.x += vx * dt;
        break;
      case 'debris':
        position.y += speed * 0.6 * dt;
        position.x += sin(time * 3) * 40 * dt;
        break;
      case 'barrier':
        position.y += speed * 0.4 * dt;
        break;
      case 'blackhole':
        position.y += speed * 0.3 * dt;
        final player = game.player;
        final dx = position.x - player.position.x;
        final dy = position.y - player.position.y;
        final distSq = dx * dx + dy * dy;
        if (distSq > 0) {
          final dist = sqrt(distSq);
          final radius = 180 + min(game.distance / 60, 90);
          if (dist < radius) {
            final strength = (1 - dist / radius) * (80 + game.distance / 80);
            final nx = dx / dist;
            final ny = dy / dist;
            player.position.x += nx * strength * dt;
            player.position.y += ny * strength * dt;
          }
        }
        break;
      case 'solarflare':
        position.y += speed * 0.35 * dt;
        extraRadius += 60 * dt;
        size = Vector2.all(extraRadius * 2);
        if (extraRadius > 150) removeFromParent();
        break;
      case 'meteor':
        position.y += (speed + 100) * dt;
        position.x += vx * dt;
        break;
      case 'wormhole':
        position.y += speed * 0.25 * dt;
        break;
      case 'satellite':
        position.y += speed * 0.55 * dt;
        position.x += sin(time * 2.5) * 50 * dt;
        break;
    }

    // Remove if off screen
    if (position.y > game.size.y + 100 || position.y < -200) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent && !hasCollided) {
      hasCollided = true;
      if (type == 'wormhole') {
        game.teleportPlayer();
      } else {
        if (other.hit()) {
          game.playerHit();
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    switch (type) {
      case 'asteroid':
        _renderAsteroid(canvas, w, h);
        break;
      case 'debris':
        _renderDebris(canvas, w, h);
        break;
      case 'barrier':
        _renderBarrier(canvas, w, h);
        break;
      case 'blackhole':
        _renderBlackHole(canvas, w, h);
        break;
      case 'solarflare':
        _renderSolarFlare(canvas, w, h);
        break;
      case 'meteor':
        _renderMeteor(canvas, w, h);
        break;
      case 'wormhole':
        _renderWormhole(canvas, w, h);
        break;
      case 'satellite':
        _renderSatellite(canvas, w, h);
        break;
    }
  }

  void _renderAsteroid(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFF6B7280)
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path();
    const points = 8;
    for (int i = 0; i < points; i++) {
      final a = (i / points) * pi * 2;
      final r = (w / 2) * (0.7 + sin(i * 3.7) * 0.3);
      final px = w / 2 + cos(a) * r;
      final py = h / 2 + sin(a) * r;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Crater
    canvas.drawCircle(Offset(w * 0.6, h * 0.4), w * 0.12,
        Paint()..color = const Color(0xFF4B5563));
  }

  void _renderDebris(Canvas canvas, double w, double h) {
    final paint = Paint()..color = const Color(0xFF9CA3AF);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
    final strokePaint = Paint()
      ..color = const Color(0xFF6B7280)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), strokePaint);
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), strokePaint);
  }

  void _renderBarrier(Canvas canvas, double w, double h) {
    final pulse = (sin(time * 4) * 0.3 + 1);
    final paint = Paint()
      ..color = Color.fromRGBO(239, 68, 68, 0.6 + pulse * 0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * pulse);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
    final linePaint = Paint()
      ..color = const Color(0xFFFCA5A5)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), linePaint);
  }

  void _renderBlackHole(Canvas canvas, double w, double h) {
    final radius = w / 2;
    final center = Offset(radius, radius);
    final t = game.timeSurvived;

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black,
          const Color(0xFF020617),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.7));
    canvas.drawCircle(center, radius * 0.7, corePaint);

    final ringPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.black.withValues(alpha: 0.0),
          const Color(0xFF111827),
          const Color(0xFF1F2937),
          const Color(0xFF111827),
          Colors.black,
          Colors.black.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.2, 0.4, 0.7, 0.9, 1.0],
        transform: GradientRotation(t * 2.5),
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.1));
    canvas.drawCircle(center, radius * 1.1, ringPaint);

    final lensPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: 0.0),
          const Color(0xFF111827).withValues(alpha: 0.2),
          const Color(0xFF4B5563).withValues(alpha: 0.35),
          Colors.black.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.65, 0.9, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4));
    canvas.drawCircle(center, radius * 1.4, lensPaint);

    final arcPaint = Paint()
      ..color = const Color(0xFF9CA3AF).withValues(alpha: 0.25)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) {
      final start = t * 1.8 + i * (pi * 2 / 3);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 1.25),
        start,
        pi * 0.6,
        false,
        arcPaint,
      );
    }

    final particlePaint = Paint()
      ..color = const Color(0xFFD1D5DB).withValues(alpha: 0.7);
    for (int i = 0; i < 10; i++) {
      final angle = t * 3 + i * (pi / 5);
      final dist = radius * 1.6 + sin(t * 4 + i) * radius * 0.2;
      final dx = center.dx + cos(angle) * dist;
      final dy = center.dy + sin(angle) * dist;
      canvas.drawCircle(Offset(dx, dy), 1.5, particlePaint);
    }
  }

  void _renderSolarFlare(Canvas canvas, double w, double h) {
    final alpha = (1 - extraRadius / 150).clamp(0.0, 1.0);
    final strokePaint = Paint()
      ..color = Color.fromRGBO(255, 107, 53, alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(w / 2, h / 2), extraRadius, strokePaint);
    final innerPaint = Paint()
      ..color = Color.fromRGBO(255, 217, 61, alpha * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(w / 2, h / 2), extraRadius * 0.7, innerPaint);
  }

  void _renderMeteor(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFFB45309)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, paint);
    // fire trail
    final firePaint = Paint()
      ..color = const Color(0x66FF6B35);
    final firePath = Path()
      ..moveTo(w * 0.2, h * 0.2)
      ..lineTo(w / 2, -h * 0.5)
      ..lineTo(w * 0.8, h * 0.2);
    canvas.drawPath(firePath, firePaint);
  }

  void _renderWormhole(Canvas canvas, double w, double h) {
    final cx = w / 2;
    final cy = h / 2;
    final pulse = sin(time * 5) * 0.2 + 1;
    final outerPaint = Paint()
      ..color = const Color(0xFF06B6D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, cy), 20 * pulse, outerPaint);
    final innerPaint = Paint()
      ..color = const Color(0xFF22D3EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int s = 0; s < 3; s++) {
      final startAngle = angle + s * (pi * 2 / 3);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: 12 * pulse),
        startAngle, pi, false, innerPaint,
      );
    }
  }

  void _renderSatellite(Canvas canvas, double w, double h) {
    final bodyPaint = Paint()..color = const Color(0xFF9CA3AF);
    final panelPaint = Paint()..color = const Color(0xFF1F2937);
    final accentPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final cx = w / 2;
    final cy = h / 2;

    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: w * 0.4, height: h * 0.5),
      bodyPaint,
    );

    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx - w * 0.45, cy), width: w * 0.4, height: h * 0.3),
      panelPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx + w * 0.45, cy), width: w * 0.4, height: h * 0.3),
      panelPaint,
    );

    canvas.drawLine(
      Offset(cx, cy - h * 0.3),
      Offset(cx, cy + h * 0.3),
      accentPaint,
    );
    canvas.drawCircle(Offset(cx, cy), 3, accentPaint);
  }
}

class ObstacleSpawner extends Component with HasGameReference<SpaceEscaperGame> {
  final SpaceEscaperGame gameRef;
  double spawnTimer = 2;

  ObstacleSpawner({required this.gameRef});

  @override
  void update(double dt) {
    if (game.gameState != GameState.playing) return;

    spawnTimer -= dt;
    if (spawnTimer <= 0) {
      spawnTimer = game.getSpawnInterval();
      _spawn();
    }
  }

  void _spawn() {
    final rng = Random();
    final types = game.unlockedObstacles.toList();
    String type = types[rng.nextInt(types.length)];
    if (game.unlockedObstacles.contains('alien') && game.distance > 1500) {
      final alienChance = min(0.35, 0.12 + game.distance / 8000);
      if (rng.nextDouble() < alienChance) {
        type = 'alien';
      }
    }
    final x = 40 + rng.nextDouble() * (game.size.x - 80);
    final y = -60.0;

    switch (type) {
      case 'asteroid':
        game.add(ObstacleComponent(
          type: 'asteroid',
          position: Vector2(x, y),
          size: Vector2(30 + rng.nextDouble() * 30, 30 + rng.nextDouble() * 30),
          vx: (rng.nextDouble() - 0.5) * 30,
          vy: 20 + rng.nextDouble() * 40,
          rotationSpeed: (rng.nextDouble() - 0.5) * 2,
        ));
        break;
      case 'debris':
        game.add(ObstacleComponent(
          type: 'debris',
          position: Vector2(x, y),
          size: Vector2(20 + rng.nextDouble() * 20, 15 + rng.nextDouble() * 15),
          rotationSpeed: (rng.nextDouble() - 0.5) * 2,
        ));
        break;
      case 'barrier':
        final bw = 80 + rng.nextDouble() * 160;
        game.add(ObstacleComponent(
          type: 'barrier',
          position: Vector2(game.size.x / 2 + (rng.nextDouble() - 0.5) * (game.size.x - bw), y),
          size: Vector2(bw, 8),
        ));
        break;
      case 'blackhole':
        final double bhSize = 55.0 + min(game.distance / 120.0, 55.0);
        game.add(ObstacleComponent(
          type: 'blackhole',
          position: Vector2(x, y),
          size: Vector2.all(bhSize),
        ));
        break;
      case 'solarflare':
        game.add(ObstacleComponent(
          type: 'solarflare',
          position: Vector2(x, y),
          size: Vector2(20, 20),
        ));
        break;
      case 'meteor':
        for (int i = 0; i < 5; i++) {
          game.add(ObstacleComponent(
            type: 'meteor',
            position: Vector2(x + (rng.nextDouble() - 0.5) * 100, y - i * 30),
            size: Vector2(10 + rng.nextDouble() * 10, 10 + rng.nextDouble() * 10),
            vx: (rng.nextDouble() - 0.5) * 60,
            rotationSpeed: (rng.nextDouble() - 0.5) * 3,
          ));
        }
        break;
      case 'wormhole':
        game.add(ObstacleComponent(
          type: 'wormhole',
          position: Vector2(x, y),
          size: Vector2(40, 40),
        ));
        break;
      case 'satellite':
        game.add(ObstacleComponent(
          type: 'satellite',
          position: Vector2(x, y),
          size: Vector2(26, 18),
          rotationSpeed: (rng.nextDouble() - 0.5) * 1.5,
        ));
        break;
      case 'alien':
        final alienTypes = ['chaser', 'weaver', 'dasher'];
        final alienType = alienTypes[rng.nextInt(alienTypes.length)];
        game.add(AlienComponent(
          position: Vector2(x, y),
          alienType: alienType,
        ));
        break;
    }
  }
}
