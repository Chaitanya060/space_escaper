import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../space_escaper_game.dart';

/// Renders physics warning overlays and active mode banners on the game canvas.
class PhysicsSystemComponent extends Component
    with HasGameReference<SpaceEscaperGame> {

  @override
  int get priority => 100; // Render on top

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;

    // Warning border flash
    if (game.physicsWarning && game.pendingPhysicsMode != null) {
      final warnColor = _getPhysicsColor(game.pendingPhysicsMode!);
      final alpha = (0.3 + sin(DateTime.now().millisecondsSinceEpoch / 150) * 0.3)
          .clamp(0.0, 1.0);

      final borderPaint = Paint()
        ..color = warnColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      canvas.drawRect(Rect.fromLTWH(3, 3, w - 6, h - 6), borderPaint);

      // Countdown number
      final countdown = game.warningTimer.ceil();
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$countdown',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w900,
            color: warnColor,
            shadows: [Shadow(color: warnColor, blurRadius: 30)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(w / 2 - textPainter.width / 2, h / 2 - 60),
      );

      // Mode name preview
      final labelPainter = TextPainter(
        text: TextSpan(
          text: _getPhysicsLabel(game.pendingPhysicsMode!),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: warnColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(w / 2 - labelPainter.width / 2, h / 2 + 20),
      );
    }

    // Active mode banner
    if (game.showBanner) {
      final t = game.bannerTimer / 2.0;
      final alpha = min(1.0, t * 3);
      final bannerPainter = TextPainter(
        text: TextSpan(
          text: game.bannerText,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: game.bannerColor.withValues(alpha: alpha),
            shadows: [
              Shadow(
                color: game.bannerColor.withValues(alpha: alpha * 0.5),
                blurRadius: 25,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      bannerPainter.paint(
        canvas,
        Offset(w / 2 - bannerPainter.width / 2, h / 2 - 18),
      );
    }

    // Milestone alert
    if (game.milestoneAlert != null) {
      final mPainter = TextPainter(
        text: TextSpan(
          text: game.milestoneAlert,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFD93D),
            shadows: [Shadow(color: Color(0xFFFFD93D), blurRadius: 15)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      mPainter.paint(
        canvas,
        Offset(w / 2 - mPainter.width / 2, h * 0.3),
      );
    }
  }

  Color _getPhysicsColor(String mode) {
    return {
      'reversed': const Color(0xFFEF4444),
      'zero': const Color(0xFFA855F7),
      'double': const Color(0xFFFF6B35),
      'inverted': const Color(0xFFFBBF24),
      'magnetic': const Color(0xFF3B82F6),
      'turbulence': const Color(0xFF06B6D4),
      'hyperdrive': const Color(0xFF00D9FF),
      'timewarp': const Color(0xFF22C55E),
      'singularity': const Color(0xFF8B5CF6),
    }[mode] ?? Colors.white;
  }

  String _getPhysicsLabel(String mode) {
    return {
      'reversed': 'GRAVITY REVERSED!',
      'zero': 'ZERO GRAVITY!',
      'double': 'DOUBLE GRAVITY!',
      'inverted': 'CONTROLS INVERTED!',
      'magnetic': 'MAGNETIC MODE!',
      'turbulence': 'TURBULENCE!',
      'hyperdrive': 'HYPERDRIVE!',
      'timewarp': 'TIME WARP!',
      'singularity': 'SINGULARITY FIELD!',
    }[mode] ?? '';
  }
}
