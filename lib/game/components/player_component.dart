import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../data/ship_data.dart';
import '../../data/game_storage.dart';
import '../../data/powerup_data.dart';
import '../space_escaper_game.dart';

class PlayerComponent extends PositionComponent with HasGameReference<SpaceEscaperGame> {
  final ShipData shipData;
  final SpaceEscaperGame gameRef;

  double vx = 0;
  double vy = 0;
  double speed = 320;
  double friction = 0.88;

  bool alive = true;
  bool invincible = false;
  double invincibleTimer = 0;
  final double invincibleDuration = 1.5;
  bool phasing = false;
  bool bonusShieldReady = false;

  PlayerComponent({required this.shipData, required this.gameRef})
      : super(size: Vector2(36, 44), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = Vector2(gameRef.size.x / 2, gameRef.size.y * 0.75);
    // Evasion Matrix Skill: Smaller hitbox
    final evasionLevel = GameStorage.getSkillLevel('smaller_hitbox', shipId: shipData.id);
    final scale = 1.0 - (evasionLevel * 0.03);

    add(RectangleHitbox(
      size: Vector2(size.x * 0.7 * scale, size.y * 0.7 * scale),
      position: Vector2(size.x * (1 - 0.7*scale)/2, size.y * (1 - 0.7*scale)/2),
    ));
    if (shipData.ability == 'goldenOverdrive') {
      bonusShieldReady = true;
    }
  }

  void applyDragInput(Vector2 delta) {
    double mx = delta.x;
    double my = delta.y;

    switch (gameRef.currentPhysicsMode) {
      case 'reversed':
        my = -my;
        break;
      case 'inverted':
        mx = -mx;
        my = -my;
        break;
      case 'turbulence':
        mx += (Random().nextDouble() - 0.5) * 4;
        my += (Random().nextDouble() - 0.5) * 4;
        break;
      case 'hyperdrive':
        mx *= 0.7;
        break;
      case 'timewarp':
        mx *= 1.3;
        my *= 1.1;
        break;
      default:
        break;
    }

    position.x += mx * 1.2;
    position.y += my * 1.2;

    _clampToScreen();
  }

  Color get _modeColor {
    switch (gameRef.currentPhysicsMode) {
      case 'hyperdrive': return Colors.cyanAccent;
      case 'singularity': return Colors.purpleAccent;
      case 'magnetic': return Colors.yellowAccent;
      case 'zero': return Colors.lightBlueAccent;
      case 'phasing': return Colors.white;
      case 'bouncy': return Colors.orangeAccent;
      case 'turbulence': return Colors.greenAccent;
      case 'dark_matter': return Colors.grey;
      default: return shipData.color;
    }
  }

  double trailTimer = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (!alive) return;

    switch (gameRef.currentPhysicsMode) {
      case 'double':
        position.y += 60 * dt;
        break;
      case 'zero':
        position.x += vx * dt;
        position.y += vy * dt;
        vx *= 0.99;
        vy *= 0.99;
        break;
      case 'turbulence':
        position.x += (Random().nextDouble() - 0.5) * 30 * dt;
        position.y += (Random().nextDouble() - 0.5) * 30 * dt;
        break;
      case 'singularity':
        final cx = gameRef.size.x / 2;
        final cy = gameRef.size.y / 2;
        final dx = cx - position.x;
        final dy = cy - position.y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist > 5) {
          final pull = 80 * dt;
          position.x += dx / dist * pull;
          position.y += dy / dist * pull;
        }
        break;
    }

    _clampToScreen();

    if (invincible) {
      invincibleTimer -= dt;
      if (invincibleTimer <= 0) {
        invincible = false;
      }
    }

    // Spawn trail particles
    trailTimer -= dt;
    if (trailTimer <= 0) {
      trailTimer = 0.05;
      gameRef.add(PlayerTrailParticle(
        position: position.clone() + Vector2(0, size.y / 2),
        color: _modeColor.withValues(alpha: 0.6),
        size: Vector2(size.x * 0.8, size.y * 0.2),
      ));
    }
  }

  void _clampToScreen() {
    final halfW = size.x / 2;
    final halfH = size.y / 2;
    position.x = position.x.clamp(halfW, gameRef.size.x - halfW);
    position.y = position.y.clamp(halfH, gameRef.size.y - halfH);
  }

  void makeInvincible() {
    invincible = true;
    // Shield Extender Skill
    final shieldLevel = GameStorage.getSkillLevel('shield_duration', shipId: shipData.id);
    invincibleTimer = invincibleDuration + (shieldLevel * 0.5);
  }

  bool hit() {
    if (gameRef.activePowerUps.containsKey(PowerUpType.shield)) return false;
    if (invincible || phasing) return false;
    if (bonusShieldReady) {
      bonusShieldReady = false;
      makeInvincible();
      return false;
    }
    alive = false;
    return true;
  }

  @override
  void render(Canvas canvas) {
    if (!alive) return;
    if (invincible && (invincibleTimer * 10).floor() % 2 == 0) return;

    // Mode Aura
    if (gameRef.currentPhysicsMode != 'normal') {
      final auraPaint = Paint()
        ..color = _modeColor.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x, auraPaint);
    }

    // Evolution glow
    if (gameRef.evolved) {
      final evoColor = shipData.evolution?.orbitColor ?? shipData.color;
      final evoPaint = Paint()
        ..color = evoColor.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 1.3, evoPaint);
    }

    // Dispatch to ship-specific render
    _renderShipDesign(canvas);

    // Engine trail glow (dynamic color)
    final trailPaint = Paint()
      ..color = _modeColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(size.x * 0.35, size.y), 5, trailPaint);
    canvas.drawCircle(Offset(size.x * 0.65, size.y), 5, trailPaint);

    // Active Shield Visual
    if (gameRef.activePowerUps.containsKey(PowerUpType.shield)) {
      final shieldPaint = Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      // Pulsing effect
      final pulse = (sin(gameRef.timeSurvived * 5) * 0.1 + 1);
      
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.9 * pulse, shieldPaint);
      
      final shieldGlow = Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.8 * pulse, shieldGlow);
    }
  }

  void _renderShipDesign(Canvas canvas) {
    switch (shipData.id) {
      case 'nova_scout': _renderNovaScout(canvas); break;
      case 'storm_chaser': _renderStormChaser(canvas); break;
      case 'comet_striker': _renderCometStriker(canvas); break;
      case 'stellar_phantom': _renderStellarPhantom(canvas); break;
      case 'meteor_dash': _renderMeteorDash(canvas); break;
      case 'aurora_wing': _renderAuroraWing(canvas); break;
      case 'nebula_spark': _renderNebulaSpark(canvas); break;
      case 'quantum_racer': _renderQuantumRacer(canvas); break;
      case 'nebula_cruiser': _renderNebulaCruiser(canvas); break;
      case 'cosmic_viper': _renderCosmicViper(canvas); break;
      case 'galaxy_titan': _renderGalaxyTitan(canvas); break;
      case 'void_reaper': _renderVoidReaper(canvas); break;
      // Legendary
      case 'star_forge': _renderStarForge(canvas); break;
      case 'diamond_emperor': _renderDiamondEmperor(canvas); break;
      case 'plasma_phoenix': _renderPlasmaPhoenix(canvas); break;
      case 'void_sovereign': _renderVoidSovereign(canvas); break;
      // Mythic
      case 'chrono_destroyer': _renderChronoDestroyer(canvas); break;
      case 'astral_leviathan': _renderAstralLeviathan(canvas); break;
      case 'infinity_colossus': _renderInfinityColossus(canvas); break;
      // Celestial
      case 'celestial_warden': _renderCelestialWarden(canvas); break;
      case 'abyssal_reaver': _renderAbyssalReaver(canvas); break;
      case 'quantum_harbinger': _renderQuantumHarbinger(canvas); break;
      case 'stellar_colossus': _renderStellarColossus(canvas); break;
      case 'eternal_sovereign': _renderEternalSovereign(canvas); break;
      case 'omega_nexus': _renderOmegaNexus(canvas); break;
      default: _renderDefaultShip(canvas); break;
    }
  }

  // ─────────── 1. NOVA SCOUT ───────────
  // Slim triangle, blue cockpit, thin neon accent lines
  void _renderNovaScout(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFF00D9FF);
    final glow = Paint()
      ..color = const Color(0xFF00D9FF).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Glow
    final bodyPath = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.15, h)
      ..lineTo(w * 0.35, h * 0.82)
      ..lineTo(w / 2, h * 0.88)
      ..lineTo(w * 0.65, h * 0.82)
      ..lineTo(w * 0.85, h)
      ..close();
    canvas.drawPath(bodyPath, glow);
    canvas.drawPath(bodyPath, paint);

    // Blue cockpit
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.3), width: w * 0.22, height: h * 0.28),
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    // Thin neon accent lines
    final accentPaint = Paint()
      ..color = const Color(0xFF00D9FF).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.22, h * 0.65), Offset(w * 0.38, h * 0.3), accentPaint);
    canvas.drawLine(Offset(w * 0.78, h * 0.65), Offset(w * 0.62, h * 0.3), accentPaint);
  }

  // ─────────── 2. STORM CHASER ───────────
  // Sharp yellow accents, lightning streaks, sparking engine
  void _renderStormChaser(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFF2979FF);
    final glow = Paint()
      ..color = const Color(0xFF2979FF).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Sharp angular body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(0, h * 0.9)
      ..lineTo(w * 0.3, h * 0.75)
      ..lineTo(w / 2, h)
      ..lineTo(w * 0.7, h * 0.75)
      ..lineTo(w, h * 0.9)
      ..close();
    canvas.drawPath(body, glow);
    canvas.drawPath(body, paint);

    // Yellow lightning streaks
    final lightning = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    // Zigzag left
    canvas.drawLine(Offset(w * 0.25, h * 0.35), Offset(w * 0.3, h * 0.5), lightning);
    canvas.drawLine(Offset(w * 0.3, h * 0.5), Offset(w * 0.2, h * 0.6), lightning);
    canvas.drawLine(Offset(w * 0.2, h * 0.6), Offset(w * 0.28, h * 0.75), lightning);
    // Zigzag right
    canvas.drawLine(Offset(w * 0.75, h * 0.35), Offset(w * 0.7, h * 0.5), lightning);
    canvas.drawLine(Offset(w * 0.7, h * 0.5), Offset(w * 0.8, h * 0.6), lightning);
    canvas.drawLine(Offset(w * 0.8, h * 0.6), Offset(w * 0.72, h * 0.75), lightning);

    // Cockpit
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.3), width: w * 0.2, height: h * 0.22),
      Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: 0.7),
    );
  }

  // ─────────── 3. COMET STRIKER ───────────
  // White/orange body, glowing wing tips
  void _renderCometStriker(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFF00E676);
    final glow = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Streamlined body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.08, h * 0.85)
      ..lineTo(w * 0.3, h * 0.65)
      ..lineTo(w * 0.35, h * 0.9)
      ..lineTo(w / 2, h * 0.75)
      ..lineTo(w * 0.65, h * 0.9)
      ..lineTo(w * 0.7, h * 0.65)
      ..lineTo(w * 0.92, h * 0.85)
      ..close();
    canvas.drawPath(body, glow);
    canvas.drawPath(body, paint);

    // Orange glowing wing tips
    final tipGlow = Paint()
      ..color = const Color(0xFFFF9100).withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(w * 0.08, h * 0.85), 4, tipGlow);
    canvas.drawCircle(Offset(w * 0.92, h * 0.85), 4, tipGlow);

    // White cockpit
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.28), width: w * 0.18, height: h * 0.25),
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  // ─────────── 4. STELLAR PHANTOM ───────────
  // Dark purple, dual exhaust, neon streaks
  void _renderStellarPhantom(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFF7C3AED);
    final glow = Paint()
      ..color = const Color(0xFFA855F7).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Stealth body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.05, h * 0.7)
      ..lineTo(w * 0.2, h * 0.85)
      ..lineTo(w * 0.35, h)
      ..lineTo(w / 2, h * 0.85)
      ..lineTo(w * 0.65, h)
      ..lineTo(w * 0.8, h * 0.85)
      ..lineTo(w * 0.95, h * 0.7)
      ..close();
    canvas.drawPath(body, glow);
    canvas.drawPath(body, paint);

    // Dual exhaust ports
    final exhaustPaint = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(w * 0.35, h), 4, exhaustPaint);
    canvas.drawCircle(Offset(w * 0.65, h), 4, exhaustPaint);

    // Neon streak lines
    final neon = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w * 0.2, h * 0.5), Offset(w * 0.4, h * 0.25), neon);
    canvas.drawLine(Offset(w * 0.8, h * 0.5), Offset(w * 0.6, h * 0.25), neon);

    // Dark cockpit
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.3), width: w * 0.16, height: h * 0.2),
      Paint()..color = const Color(0xFFE040FB).withValues(alpha: 0.5),
    );
  }

  // ─────────── 5. METEOR DASH ───────────
  // Heavy orange, flame cracks, wider wings
  void _renderMeteorDash(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFFFF6D00);
    final glow = Paint()
      ..color = const Color(0xFFFF9100).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Wide aggressive body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(0, h * 0.8)
      ..lineTo(w * 0.15, h)
      ..lineTo(w * 0.4, h * 0.85)
      ..lineTo(w / 2, h * 0.95)
      ..lineTo(w * 0.6, h * 0.85)
      ..lineTo(w * 0.85, h)
      ..lineTo(w, h * 0.8)
      ..close();
    canvas.drawPath(body, glow);
    canvas.drawPath(body, paint);

    // Flame crack lines
    final crack = Paint()
      ..color = const Color(0xFFFFD600).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(w * 0.35, h * 0.4), Offset(w * 0.3, h * 0.7), crack);
    canvas.drawLine(Offset(w * 0.65, h * 0.4), Offset(w * 0.7, h * 0.7), crack);
    canvas.drawLine(Offset(w * 0.5, h * 0.2), Offset(w * 0.5, h * 0.55), crack);

    // Red-hot cockpit
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.3), width: w * 0.25, height: h * 0.2),
      Paint()..color = const Color(0xFFFFD600).withValues(alpha: 0.6),
    );
  }

  // ─────────── 6. AURORA WING ───────────
  // Ice-blue elegant wings, transparent glow, frost accents
  void _renderAuroraWing(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFF18FFFF).withValues(alpha: 0.9);
    final glow = Paint()
      ..color = const Color(0xFF18FFFF).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    // Elegant swept-back wings
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(0, h * 0.6)
      ..lineTo(w * 0.1, h * 0.9)
      ..lineTo(w * 0.35, h * 0.7)
      ..lineTo(w / 2, h * 0.85)
      ..lineTo(w * 0.65, h * 0.7)
      ..lineTo(w * 0.9, h * 0.9)
      ..lineTo(w, h * 0.6)
      ..close();
    canvas.drawPath(body, glow);
    canvas.drawPath(body, paint);

    // Frost crystal cockpit
    final crystalPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final crystal = Path()
      ..moveTo(w / 2, h * 0.18)
      ..lineTo(w * 0.4, h * 0.32)
      ..lineTo(w / 2, h * 0.42)
      ..lineTo(w * 0.6, h * 0.32)
      ..close();
    canvas.drawPath(crystal, crystalPaint);

    // Frost accents
    final frost = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(w * 0.15, h * 0.55), Offset(w * 0.35, h * 0.4), frost);
    canvas.drawLine(Offset(w * 0.85, h * 0.55), Offset(w * 0.65, h * 0.4), frost);
  }

  // ─────────── 7. NEBULA SPARK ───────────
  // Purple core, star particles, curved wings
  void _renderNebulaSpark(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFFFFEA00);
    final glow = Paint()
      ..color = const Color(0xFFFFEA00).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Curved wing body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..quadraticBezierTo(w * 0.1, h * 0.4, 0, h * 0.85)
      ..lineTo(w * 0.3, h * 0.7)
      ..lineTo(w / 2, h * 0.9)
      ..lineTo(w * 0.7, h * 0.7)
      ..quadraticBezierTo(w * 0.9, h * 0.4, w, h * 0.85)
      ..lineTo(w / 2, 0)
      ..close();
    canvas.drawPath(body, glow);
    canvas.drawPath(body, paint);

    // Purple energy core
    final core = Paint()
      ..color = const Color(0xFFAA00FF).withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(w / 2, h * 0.35), w * 0.12, core);

    // White star sparkle at cockpit
    canvas.drawCircle(Offset(w / 2, h * 0.35), 2, Paint()..color = Colors.white);
  }

  // ─────────── 8. QUANTUM RACER ───────────
  // Cyan glitch lines, separated wing layers
  void _renderQuantumRacer(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFF22D3EE);
    final glow = Paint()
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Main body (slim)
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.3, h * 0.6)
      ..lineTo(w * 0.35, h * 0.85)
      ..lineTo(w / 2, h * 0.75)
      ..lineTo(w * 0.65, h * 0.85)
      ..lineTo(w * 0.7, h * 0.6)
      ..close();
    canvas.drawPath(body, glow);
    canvas.drawPath(body, paint);

    // Separated wing pods (left and right)
    final wingPaint = Paint()..color = const Color(0xFF22D3EE).withValues(alpha: 0.7);
    // Left wing pod
    final leftWing = Path()
      ..moveTo(w * 0.25, h * 0.45)
      ..lineTo(0, h * 0.75)
      ..lineTo(w * 0.15, h * 0.9)
      ..lineTo(w * 0.28, h * 0.55)
      ..close();
    canvas.drawPath(leftWing, wingPaint);
    // Right wing pod
    final rightWing = Path()
      ..moveTo(w * 0.75, h * 0.45)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.85, h * 0.9)
      ..lineTo(w * 0.72, h * 0.55)
      ..close();
    canvas.drawPath(rightWing, wingPaint);

    // Glitch lines
    final glitch = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w * 0.3, h * 0.3), Offset(w * 0.5, h * 0.15), glitch);
    canvas.drawLine(Offset(w * 0.7, h * 0.3), Offset(w * 0.5, h * 0.15), glitch);

    // Cockpit
    canvas.drawCircle(
      Offset(w / 2, h * 0.25),
      w * 0.08,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  // ─────────── 9. NEBULA CRUISER ───────────
  // Bulkier body, heavy armor panels, green
  void _renderNebulaCruiser(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFF34D399);
    final glow = Paint()
      ..color = const Color(0xFF34D399).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Heavy bulky body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.1, h * 0.5)
      ..lineTo(0, h * 0.85)
      ..lineTo(w * 0.25, h)
      ..lineTo(w * 0.4, h * 0.88)
      ..lineTo(w / 2, h * 0.95)
      ..lineTo(w * 0.6, h * 0.88)
      ..lineTo(w * 0.75, h)
      ..lineTo(w, h * 0.85)
      ..lineTo(w * 0.9, h * 0.5)
      ..close();
    canvas.drawPath(body, glow);
    canvas.drawPath(body, paint);

    // Armor panel lines
    final armor = Paint()
      ..color = const Color(0xFF059669).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(w * 0.3, h * 0.3), Offset(w * 0.15, h * 0.65), armor);
    canvas.drawLine(Offset(w * 0.7, h * 0.3), Offset(w * 0.85, h * 0.65), armor);
    canvas.drawLine(Offset(w * 0.4, h * 0.5), Offset(w * 0.6, h * 0.5), armor);

    // Heavy cockpit
    canvas.drawRect(
      Rect.fromCenter(center: Offset(w / 2, h * 0.28), width: w * 0.2, height: h * 0.15),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  // ─────────── 10. COSMIC VIPER ───────────
  // Sharp angular wings, electric arcs
  void _renderCosmicViper(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFFD500F9);
    final glow = Paint()
      ..color = const Color(0xFFD500F9).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Sharp V-shaped body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(0, h * 0.65)
      ..lineTo(w * 0.15, h)
      ..lineTo(w * 0.35, h * 0.78)
      ..lineTo(w / 2, h * 0.88)
      ..lineTo(w * 0.65, h * 0.78)
      ..lineTo(w * 0.85, h)
      ..lineTo(w, h * 0.65)
      ..close();
    canvas.drawPath(body, glow);
    canvas.drawPath(body, paint);

    // Electric arcs
    final arc = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    // Left arc zigzag
    canvas.drawLine(Offset(w * 0.2, h * 0.5), Offset(w * 0.28, h * 0.42), arc);
    canvas.drawLine(Offset(w * 0.28, h * 0.42), Offset(w * 0.22, h * 0.35), arc);
    // Right arc zigzag
    canvas.drawLine(Offset(w * 0.8, h * 0.5), Offset(w * 0.72, h * 0.42), arc);
    canvas.drawLine(Offset(w * 0.72, h * 0.42), Offset(w * 0.78, h * 0.35), arc);

    // Glowing cockpit
    canvas.drawCircle(
      Offset(w / 2, h * 0.28),
      w * 0.1,
      Paint()..color = Colors.white.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  // ─────────── 11. GALAXY TITAN ───────────
  // Thick armor, shield ring, pink
  void _renderGalaxyTitan(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFFF472B6);
    final glow = Paint()
      ..color = const Color(0xFFF472B6).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Thick armored body
    final body = Path()
      ..moveTo(w / 2, h * 0.05)
      ..lineTo(w * 0.05, h * 0.55)
      ..lineTo(0, h * 0.85)
      ..lineTo(w * 0.2, h)
      ..lineTo(w * 0.4, h * 0.9)
      ..lineTo(w / 2, h * 0.95)
      ..lineTo(w * 0.6, h * 0.9)
      ..lineTo(w * 0.8, h)
      ..lineTo(w, h * 0.85)
      ..lineTo(w * 0.95, h * 0.55)
      ..close();
    canvas.drawPath(body, glow);
    canvas.drawPath(body, paint);

    // Shield ring around ship
    final ringPaint = Paint()
      ..color = const Color(0xFFF472B6).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.6, ringPaint);

    // Heavy cockpit
    canvas.drawRect(
      Rect.fromCenter(center: Offset(w / 2, h * 0.3), width: w * 0.25, height: h * 0.18),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    // Armor cross-lines
    final armorLines = Paint()
      ..color = const Color(0xFFDB2777).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(w * 0.25, h * 0.45), Offset(w * 0.4, h * 0.75), armorLines);
    canvas.drawLine(Offset(w * 0.75, h * 0.45), Offset(w * 0.6, h * 0.75), armorLines);
  }

  // ─────────── 12. VOID REAPER ───────────
  // Black body, red inner glow, shadow smoke
  void _renderVoidReaper(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFF1A1A2E);
    final innerGlow = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    // Inner red glow
    canvas.drawCircle(Offset(w / 2, h * 0.45), w * 0.4, innerGlow);

    // Dark angular body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(0, h * 0.7)
      ..lineTo(w * 0.12, h)
      ..lineTo(w * 0.35, h * 0.8)
      ..lineTo(w / 2, h * 0.92)
      ..lineTo(w * 0.65, h * 0.8)
      ..lineTo(w * 0.88, h)
      ..lineTo(w, h * 0.7)
      ..close();
    canvas.drawPath(body, paint);

    // Red edge highlights
    final edge = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(body, edge);

    // Red eye cockpit
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.3), width: w * 0.2, height: h * 0.12),
      Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.8),
    );

    // Shadow aura wisps
    final shadow = Paint()
      ..color = const Color(0xFF7F1D1D).withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(w * 0.2, h * 0.6), 6, shadow);
    canvas.drawCircle(Offset(w * 0.8, h * 0.6), 6, shadow);
  }

  // ═══════════════════════════════════════
  //  LEGENDARY SHIPS
  // ═══════════════════════════════════════

  // ─────────── 13. STAR FORGE ───────────
  // Gold body, bright white core, orbiting mini suns, solar flares
  void _renderStarForge(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFFFFB300);
    final glow = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    // Outer solar glow
    canvas.drawCircle(Offset(w / 2, h * 0.4), w * 0.5, glow);

    // Gold body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.1, h * 0.75)
      ..lineTo(w * 0.3, h * 0.85)
      ..lineTo(w / 2, h * 0.92)
      ..lineTo(w * 0.7, h * 0.85)
      ..lineTo(w * 0.9, h * 0.75)
      ..close();
    canvas.drawPath(body, paint);

    // White core
    canvas.drawCircle(
      Offset(w / 2, h * 0.35),
      w * 0.12,
      Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(Offset(w / 2, h * 0.35), w * 0.06, Paint()..color = Colors.white);

    // Solar flare rays
    final flare = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final cx = w / 2 + cos(angle) * w * 0.06;
      final cy = h * 0.35 + sin(angle) * w * 0.06;
      final ex = w / 2 + cos(angle) * w * 0.22;
      final ey = h * 0.35 + sin(angle) * w * 0.22;
      canvas.drawLine(Offset(cx, cy), Offset(ex, ey), flare);
    }
  }

  // ─────────── 14. DIAMOND EMPEROR ───────────
  // Sharp crystal wings, prism light reflections, geometric
  void _renderDiamondEmperor(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFFB9F2FF);
    final glow = Paint()
      ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    // Faceted diamond body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.15, h * 0.4)
      ..lineTo(0, h * 0.7)
      ..lineTo(w * 0.2, h * 0.85)
      ..lineTo(w * 0.4, h * 0.7)
      ..lineTo(w / 2, h * 0.9)
      ..lineTo(w * 0.6, h * 0.7)
      ..lineTo(w * 0.8, h * 0.85)
      ..lineTo(w, h * 0.7)
      ..lineTo(w * 0.85, h * 0.4)
      ..close();
    canvas.drawPath(body, glow);
    canvas.drawPath(body, paint);

    // Prism refraction lines
    final prism = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w * 0.3, h * 0.25), Offset(w * 0.15, h * 0.55), prism);
    canvas.drawLine(Offset(w * 0.7, h * 0.25), Offset(w * 0.85, h * 0.55), prism);
    canvas.drawLine(Offset(w * 0.4, h * 0.4), Offset(w * 0.6, h * 0.4), prism);

    // Diamond core
    final core = Path()
      ..moveTo(w / 2, h * 0.2)
      ..lineTo(w * 0.4, h * 0.35)
      ..lineTo(w / 2, h * 0.45)
      ..lineTo(w * 0.6, h * 0.35)
      ..close();
    canvas.drawPath(core, Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  // ─────────── 15. PLASMA PHOENIX ───────────
  // Flame wings, ember trail, pulsing molten core
  void _renderPlasmaPhoenix(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFFFF3D00);
    final glow = Paint()
      ..color = const Color(0xFFFF6D00).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    // Fire glow
    canvas.drawCircle(Offset(w / 2, h * 0.5), w * 0.5, glow);

    // Flame wing body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..quadraticBezierTo(w * 0.05, h * 0.3, 0, h * 0.8)
      ..lineTo(w * 0.15, h)
      ..lineTo(w * 0.35, h * 0.7)
      ..lineTo(w / 2, h * 0.85)
      ..lineTo(w * 0.65, h * 0.7)
      ..lineTo(w * 0.85, h)
      ..quadraticBezierTo(w * 0.95, h * 0.3, w / 2, 0)
      ..close();
    canvas.drawPath(body, paint);

    // Molten core
    canvas.drawCircle(
      Offset(w / 2, h * 0.35),
      w * 0.12,
      Paint()..color = const Color(0xFFFFD600).withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Ember streaks
    final ember = Paint()
      ..color = const Color(0xFFFFD600).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawLine(Offset(w * 0.2, h * 0.5), Offset(w * 0.1, h * 0.8), ember);
    canvas.drawLine(Offset(w * 0.8, h * 0.5), Offset(w * 0.9, h * 0.8), ember);
  }

  // ─────────── 16. VOID SOVEREIGN ───────────
  // Dark metallic body, purple-black aura, distortion
  void _renderVoidSovereign(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFF1A0040);
    final aura = Paint()
      ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // Purple-black aura
    canvas.drawCircle(Offset(w / 2, h * 0.45), w * 0.55, aura);

    // Dark angular body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.05, h * 0.65)
      ..lineTo(w * 0.15, h * 0.95)
      ..lineTo(w * 0.35, h * 0.8)
      ..lineTo(w / 2, h * 0.9)
      ..lineTo(w * 0.65, h * 0.8)
      ..lineTo(w * 0.85, h * 0.95)
      ..lineTo(w * 0.95, h * 0.65)
      ..close();
    canvas.drawPath(body, paint);

    // Purple edge glow
    final edge = Paint()
      ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(body, edge);

    // Void eye cockpit
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.32), width: w * 0.16, height: h * 0.1),
      Paint()..color = const Color(0xFFB388FF).withValues(alpha: 0.7),
    );
  }

  // ═══════════════════════════════════════
  //  MYTHIC SHIPS
  // ═══════════════════════════════════════

  // ─────────── 17. CHRONO DESTROYER ───────────
  // Cyan clock rings, glitch distortion trail
  void _renderChronoDestroyer(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFF00BFA5);
    final glow = Paint()
      ..color = const Color(0xFF1DE9B6).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.1, h * 0.7)
      ..lineTo(w * 0.25, h * 0.9)
      ..lineTo(w / 2, h * 0.8)
      ..lineTo(w * 0.75, h * 0.9)
      ..lineTo(w * 0.9, h * 0.7)
      ..close();
    canvas.drawPath(body, glow);
    canvas.drawPath(body, paint);

    // Clock ring
    final ring = Paint()
      ..color = const Color(0xFF1DE9B6).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(w / 2, h * 0.35), w * 0.15, ring);

    // Clock hands
    canvas.drawLine(Offset(w / 2, h * 0.35), Offset(w / 2, h * 0.22), ring);
    canvas.drawLine(Offset(w / 2, h * 0.35), Offset(w * 0.58, h * 0.32), ring);

    // Glitch lines
    final glitch = Paint()
      ..color = const Color(0xFF1DE9B6).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(w * 0.2, h * 0.5), Offset(w * 0.35, h * 0.48), glitch);
    canvas.drawLine(Offset(w * 0.8, h * 0.5), Offset(w * 0.65, h * 0.48), glitch);
  }

  // ─────────── 18. ASTRAL LEVIATHAN ───────────
  // Deep blue body, starfield texture, floating wing segments
  void _renderAstralLeviathan(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFF1A237E);
    final glow = Paint()
      ..color = const Color(0xFF304FFE).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    // Massive body
    final body = Path()
      ..moveTo(w / 2, h * 0.05)
      ..lineTo(w * 0.05, h * 0.5)
      ..lineTo(0, h * 0.85)
      ..lineTo(w * 0.2, h)
      ..lineTo(w * 0.4, h * 0.88)
      ..lineTo(w / 2, h * 0.95)
      ..lineTo(w * 0.6, h * 0.88)
      ..lineTo(w * 0.8, h)
      ..lineTo(w, h * 0.85)
      ..lineTo(w * 0.95, h * 0.5)
      ..close();
    canvas.drawPath(body, glow);
    canvas.drawPath(body, paint);

    // Starfield dots
    final star = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(w * 0.3, h * 0.5), 1.5, star);
    canvas.drawCircle(Offset(w * 0.6, h * 0.4), 1, star);
    canvas.drawCircle(Offset(w * 0.45, h * 0.6), 1.3, star);
    canvas.drawCircle(Offset(w * 0.7, h * 0.65), 1, star);
    canvas.drawCircle(Offset(w * 0.25, h * 0.7), 1.5, star);

    // Floating wing segments
    final seg = Paint()..color = const Color(0xFF536DFE).withValues(alpha: 0.6);
    canvas.drawRect(Rect.fromLTWH(w * 0.02, h * 0.55, w * 0.08, h * 0.2), seg);
    canvas.drawRect(Rect.fromLTWH(w * 0.9, h * 0.55, w * 0.08, h * 0.2), seg);
  }

  // ─────────── 19. INFINITY COLOSSUS ───────────
  // White glowing frame, infinity symbol ring, reality ripple
  void _renderInfinityColossus(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final glow = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    // Reality ripple aura
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.6, glow);

    // Body outline (glowing frame)
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.1, h * 0.6)
      ..lineTo(w * 0.2, h * 0.9)
      ..lineTo(w / 2, h * 0.8)
      ..lineTo(w * 0.8, h * 0.9)
      ..lineTo(w * 0.9, h * 0.6)
      ..close();
    canvas.drawPath(body, paint);
    canvas.drawPath(body, Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Infinity symbol
    final inf = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final cx = w / 2, cy = h * 0.4;
    final infPath = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx + 12, cy - 10, cx + 12, cy + 10, cx, cy)
      ..cubicTo(cx - 12, cy - 10, cx - 12, cy + 10, cx, cy);
    canvas.drawPath(infPath, inf);
  }

  // ═══════════════════════════════════════
  //  CELESTIAL (GOD TIER) SHIPS
  // ═══════════════════════════════════════

  // ─────────── 20. CELESTIAL WARDEN ───────────
  // Gold + white, angelic energy wings, radiant glow
  void _renderCelestialWarden(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFFFFD600);
    final divineGlow = Paint()
      ..color = const Color(0xFFFFD600).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // Divine radiant glow
    canvas.drawCircle(Offset(w / 2, h * 0.4), w * 0.6, divineGlow);

    // Angelic body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.1, h * 0.6)
      ..quadraticBezierTo(0, h * 0.4, w * 0.05, h * 0.8)
      ..lineTo(w * 0.3, h * 0.9)
      ..lineTo(w / 2, h * 0.82)
      ..lineTo(w * 0.7, h * 0.9)
      ..lineTo(w * 0.95, h * 0.8)
      ..quadraticBezierTo(w, h * 0.4, w * 0.9, h * 0.6)
      ..close();
    canvas.drawPath(body, paint);

    // White halo
    final halo = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.12), width: w * 0.5, height: h * 0.08),
      halo,
    );

    // Cockpit
    canvas.drawCircle(Offset(w / 2, h * 0.3), w * 0.08, Paint()..color = Colors.white);
  }

  // ─────────── 21. ABYSSAL REAVER ───────────
  // Black-red theme, moving shadow aura
  void _renderAbyssalReaver(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFF1A0000);
    final aura = Paint()
      ..color = const Color(0xFFD50000).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    // Shadow aura
    canvas.drawCircle(Offset(w / 2, h * 0.45), w * 0.5, aura);

    // Jagged dark body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.05, h * 0.6)
      ..lineTo(w * 0.1, h * 0.85)
      ..lineTo(w * 0.25, h * 0.7)
      ..lineTo(w * 0.35, h * 0.95)
      ..lineTo(w / 2, h * 0.82)
      ..lineTo(w * 0.65, h * 0.95)
      ..lineTo(w * 0.75, h * 0.7)
      ..lineTo(w * 0.9, h * 0.85)
      ..lineTo(w * 0.95, h * 0.6)
      ..close();
    canvas.drawPath(body, paint);

    // Red edge
    canvas.drawPath(body, Paint()
      ..color = const Color(0xFFD50000).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Red eye
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.3), width: w * 0.18, height: h * 0.1),
      Paint()..color = const Color(0xFFD50000).withValues(alpha: 0.8),
    );
  }

  // ─────────── 22. QUANTUM HARBINGER ───────────
  // Glitch effect body, cyan energy cracks
  void _renderQuantumHarbinger(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFF4A148C);
    final glow = Paint()
      ..color = const Color(0xFFD500F9).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    // Energy glow
    canvas.drawCircle(Offset(w / 2, h * 0.4), w * 0.5, glow);

    // Angular body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.08, h * 0.55)
      ..lineTo(w * 0.15, h * 0.9)
      ..lineTo(w * 0.4, h * 0.75)
      ..lineTo(w / 2, h * 0.88)
      ..lineTo(w * 0.6, h * 0.75)
      ..lineTo(w * 0.85, h * 0.9)
      ..lineTo(w * 0.92, h * 0.55)
      ..close();
    canvas.drawPath(body, paint);

    // Cyan energy cracks
    final crack = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(w * 0.35, h * 0.2), Offset(w * 0.25, h * 0.5), crack);
    canvas.drawLine(Offset(w * 0.25, h * 0.5), Offset(w * 0.35, h * 0.7), crack);
    canvas.drawLine(Offset(w * 0.65, h * 0.2), Offset(w * 0.75, h * 0.5), crack);
    canvas.drawLine(Offset(w * 0.75, h * 0.5), Offset(w * 0.65, h * 0.7), crack);
    canvas.drawLine(Offset(w * 0.45, h * 0.35), Offset(w * 0.55, h * 0.35), crack);

    // Core
    canvas.drawCircle(Offset(w / 2, h * 0.35), w * 0.08,
      Paint()..color = const Color(0xFF00FFFF).withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  // ─────────── 23. STELLAR COLOSSUS ───────────
  // Giant glowing core, heavy aura, massive presence
  void _renderStellarColossus(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFFE65100);
    final glow = Paint()
      ..color = const Color(0xFFFFAB00).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

    // Massive stellar glow
    canvas.drawCircle(Offset(w / 2, h * 0.4), w * 0.65, glow);

    // Heavy body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.05, h * 0.55)
      ..lineTo(0, h * 0.85)
      ..lineTo(w * 0.2, h)
      ..lineTo(w * 0.4, h * 0.88)
      ..lineTo(w / 2, h * 0.95)
      ..lineTo(w * 0.6, h * 0.88)
      ..lineTo(w * 0.8, h)
      ..lineTo(w, h * 0.85)
      ..lineTo(w * 0.95, h * 0.55)
      ..close();
    canvas.drawPath(body, paint);

    // Giant white-hot core
    canvas.drawCircle(Offset(w / 2, h * 0.38), w * 0.18,
      Paint()..color = const Color(0xFFFFAB00).withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(Offset(w / 2, h * 0.38), w * 0.08, Paint()..color = Colors.white);
  }

  // ─────────── 24. ETERNAL SOVEREIGN ───────────
  // Symmetrical divine design, cosmic blue
  void _renderEternalSovereign(Canvas canvas) {
    final w = size.x, h = size.y;
    final paint = Paint()..color = const Color(0xFF0091EA);
    final glow = Paint()
      ..color = const Color(0xFF40C4FF).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    // Cosmic glow
    canvas.drawCircle(Offset(w / 2, h * 0.4), w * 0.55, glow);

    // Perfectly symmetrical body
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.1, h * 0.4)
      ..lineTo(0, h * 0.7)
      ..lineTo(w * 0.15, h * 0.9)
      ..lineTo(w * 0.35, h * 0.8)
      ..lineTo(w / 2, h * 0.92)
      ..lineTo(w * 0.65, h * 0.8)
      ..lineTo(w * 0.85, h * 0.9)
      ..lineTo(w, h * 0.7)
      ..lineTo(w * 0.9, h * 0.4)
      ..close();
    canvas.drawPath(body, paint);

    // Halo ring
    final halo = Paint()
      ..color = const Color(0xFF40C4FF).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(w / 2, h * 0.35), w * 0.2, halo);

    // Central orb
    canvas.drawCircle(Offset(w / 2, h * 0.35), w * 0.08,
      Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  // ─────────── 25. OMEGA NEXUS ───────────
  // Pure white + black, reality distortion, expanding energy rings
  void _renderOmegaNexus(Canvas canvas) {
    final w = size.x, h = size.y;

    // Reality distortion aura (white + black)
    final outerGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(Offset(w / 2, h * 0.45), w * 0.7, outerGlow);

    // Pure black body
    final paint = Paint()..color = const Color(0xFF0A0A0A);
    final body = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.05, h * 0.6)
      ..lineTo(w * 0.1, h * 0.9)
      ..lineTo(w * 0.35, h * 0.78)
      ..lineTo(w / 2, h * 0.92)
      ..lineTo(w * 0.65, h * 0.78)
      ..lineTo(w * 0.9, h * 0.9)
      ..lineTo(w * 0.95, h * 0.6)
      ..close();
    canvas.drawPath(body, paint);

    // White energy edge
    canvas.drawPath(body, Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Expanding energy rings
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        Offset(w / 2, h * 0.4),
        w * 0.12 * i,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15 / i)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Singularity core (white dot)
    canvas.drawCircle(Offset(w / 2, h * 0.35), w * 0.05,
      Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  // ─────────── DEFAULT SHIP ───────────
  void _renderDefaultShip(Canvas canvas) {
    final paint = Paint()
      ..color = shipData.color
      ..style = PaintingStyle.fill;

    final w = size.x;
    final h = size.y;

    // Glow shadow
    final glowPaint = Paint()
      ..color = shipData.color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final bodyPath = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(0, h)
      ..lineTo(w / 4, h * 0.82)
      ..lineTo(w / 2, h * 0.9)
      ..lineTo(w * 0.75, h * 0.82)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(bodyPath, glowPaint);
    canvas.drawPath(bodyPath, paint);

    // Cockpit
    final cockpitPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.35), width: w / 4, height: h / 3),
      cockpitPaint,
    );

    // Wing accent lines
    final accentPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w * 0.2, h * 0.7), Offset(w * 0.35, h * 0.35), accentPaint);
    canvas.drawLine(Offset(w * 0.8, h * 0.7), Offset(w * 0.65, h * 0.35), accentPaint);
  }
}

class PlayerTrailParticle extends PositionComponent {
  final Color color;
  double lifeTime = 0.5;

  PlayerTrailParticle({
    required Vector2 position,
    required this.color,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    lifeTime -= dt;
    position.y += 100 * dt;
    if (lifeTime <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (lifeTime / 0.5).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(size.toRect(), paint);
  }
}
