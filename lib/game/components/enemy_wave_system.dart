import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../space_escaper_game.dart';
import 'alien_component.dart';

// ═══════════════════════════════════════
//  ENEMY WAVE SYSTEM
// ═══════════════════════════════════════

class EnemyWaveSystem extends Component with HasGameReference<SpaceEscaperGame> {
  double waveTimer = 0;
  double nextWaveAt = 60; // seconds until first wave
  int wavesSpawned = 0;
  bool waveActive = false;
  int waveEnemiesRemaining = 0;
  String? waveFormation;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.gameState != GameState.playing) return;

    if (!waveActive) {
      waveTimer += dt;
      if (waveTimer >= nextWaveAt && game.distance > 1000) {
        _startWave();
      }
    }
  }

  void _startWave() {
    waveActive = true;
    wavesSpawned++;

    // Show warning
    game.showBanner = true;
    game.bannerTimer = 2.0;
    game.bannerText = 'SWARM INCOMING!';
    game.bannerColor = const Color(0xFFEF4444);

    // Pick formation
    final formations = ['v_shape', 'line', 'circle', 'grid'];
    final rng = Random();
    waveFormation = formations[rng.nextInt(formations.length)];

    // Determine enemy count (scales with distance)
    final int baseCount = (8 + min((game.distance / 2000).floor(), 7)).toInt();

    // Pick alien types
    final types = ['chaser', 'weaver', 'dasher'];
    if (game.distance > 3000) types.add('shielder');
    if (game.distance > 5000) types.add('bomber');
    if (game.distance > 7000) types.add('splitter');

    // Spawn in formation
    _spawnFormation(waveFormation!, baseCount, types, rng);

    waveEnemiesRemaining = baseCount;

    // Reset timer for next wave
    waveTimer = 0;
    nextWaveAt = 50 + rng.nextDouble() * 30; // 50-80 seconds between waves
  }

  void _spawnFormation(String formation, int count, List<String> types, Random rng) {
    final centerX = game.size.x / 2;
    final startY = -60.0;

    for (int i = 0; i < count; i++) {
      double x, y;
      switch (formation) {
        case 'v_shape':
          final row = i ~/ 2;
          final side = i % 2 == 0 ? -1.0 : 1.0;
          x = centerX + side * (row + 1) * 35;
          y = startY - row * 40;
          break;
        case 'line':
          x = 40 + (i / (count - 1)) * (game.size.x - 80);
          y = startY;
          break;
        case 'circle':
          final angle = (i / count) * pi * 2;
          x = centerX + cos(angle) * 80;
          y = startY - 40 + sin(angle) * 40;
          break;
        case 'grid':
          final cols = (sqrt(count)).ceil();
          x = 40 + (i % cols) * 45;
          y = startY - (i ~/ cols) * 40;
          break;
        default:
          x = 40 + rng.nextDouble() * (game.size.x - 80);
          y = startY - rng.nextDouble() * 100;
      }

      final type = types[rng.nextInt(types.length)];
      game.add(AlienComponent(
        position: Vector2(x, y),
        alienType: type,
      ));
    }
  }

  void onEnemyDestroyed() {
    if (!waveActive) return;
    waveEnemiesRemaining--;
    if (waveEnemiesRemaining <= 0) {
      _onWaveCleared();
    }
  }

  void _onWaveCleared() {
    waveActive = false;

    // Bonus reward
    game.runCoins += 20 + wavesSpawned * 10;

    game.showBanner = true;
    game.bannerTimer = 2.0;
    game.bannerText = 'WAVE CLEARED! +${20 + wavesSpawned * 10} COINS';
    game.bannerColor = const Color(0xFF22C55E);
  }
}
