import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../space_escaper_game.dart';
import 'alien_component.dart';
import 'obstacle_spawner.dart';

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
  int gauntletWave = 0;
  final int gauntletTotal = 10;
  bool gauntletWaitingBoss = false;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.gameState != GameState.playing) return;

    if (game.gameMode == GameMode.gauntlet && gauntletWaitingBoss) {
      if (!game.bossActive) {
        gauntletWaitingBoss = false;
        _onWaveCleared();
      }
      return;
    }

    if (!waveActive) {
      waveTimer += dt;
      if (game.gameMode == GameMode.gauntlet) {
        if (waveTimer >= (wavesSpawned == 0 ? 2.0 : 3.0) && gauntletWave < gauntletTotal) {
          _startWave();
        }
      } else {
        if (waveTimer >= nextWaveAt && game.distance > 1000) {
          _startWave();
        }
      }
    }
  }

  void _startWave() {
    waveActive = true;
    wavesSpawned++;
    gauntletWave = wavesSpawned;

    // Show warning
    game.showBanner = true;
    game.bannerTimer = 2.0;
    if (game.gameMode == GameMode.gauntlet) {
      game.bannerText = 'GAUNTLET WAVE $gauntletWave/$gauntletTotal';
      game.bannerColor = const Color(0xFFFF6B35);
    } else {
      game.bannerText = 'SWARM INCOMING!';
      game.bannerColor = const Color(0xFFEF4444);
    }

    // Pick formation
    final formations = ['v_shape', 'line', 'circle', 'grid'];
    final rng = Random();
    if (game.gameMode == GameMode.gauntlet) {
      final idx = gauntletWave % formations.length;
      waveFormation = formations[idx];
    } else {
      waveFormation = formations[rng.nextInt(formations.length)];
    }

    // Determine enemy count (scales with distance)
    int baseCount = (8 + min((game.distance / 2000).floor(), 7)).toInt();
    if (game.gameMode == GameMode.gauntlet) {
      baseCount = 8 + gauntletWave * 2;
      if (gauntletWave == 3) baseCount += 6; // Alien swarm
      if (gauntletWave == 9) baseCount += 10; // Heavy push
    }

    // Pick alien types
    final types = ['chaser', 'weaver', 'dasher'];
    if (game.distance > 3000 || game.gameMode == GameMode.gauntlet) types.add('shielder');
    if (game.distance > 5000 || (game.gameMode == GameMode.gauntlet && gauntletWave >= 4)) types.add('bomber');
    if (game.distance > 7000 || (game.gameMode == GameMode.gauntlet && gauntletWave >= 6)) types.add('splitter');

    // Special Gauntlet scripting
    if (game.gameMode == GameMode.gauntlet) {
      switch (gauntletWave) {
        case 2: // Zero gravity
          game.currentPhysicsMode = 'zero';
          game.physicsTimer = 6.0;
          break;
        case 4: // Asteroid storm hazards
          for (int i = 0; i < 18; i++) {
            final x = 40 + rng.nextDouble() * (game.size.x - 80);
            game.add(ObstacleComponent(
              type: 'meteor',
              position: Vector2(x, -40 - i * 20),
              size: Vector2(12 + rng.nextDouble() * 10, 12 + rng.nextDouble() * 10),
              vx: (rng.nextDouble() - 0.5) * 80,
              rotationSpeed: (rng.nextDouble() - 0.5) * 3,
            ));
          }
          game.add(ObstacleComponent(
            type: 'solarflare',
            position: Vector2(game.size.x / 2, -40),
            size: Vector2(20, 20),
          ));
          break;
        case 5: // Boss fight
          game.startGauntletBoss();
          gauntletWaitingBoss = true;
          waveEnemiesRemaining = 1;
          return;
        case 6: // Time warp slow
          game.currentPhysicsMode = 'timewarp';
          game.physicsTimer = 6.0;
          break;
        case 8: // Black hole hazard + satellites
          game.add(ObstacleComponent(
            type: 'blackhole',
            position: Vector2(game.size.x * 0.3, -60),
            size: Vector2.all(70),
          ));
          game.add(ObstacleComponent(
            type: 'satellite',
            position: Vector2(game.size.x * 0.7, -90),
            size: Vector2(26, 18),
            rotationSpeed: (rng.nextDouble() - 0.5) * 1.5,
          ));
          break;
        case 10: // Final boss
          game.startGauntletBoss();
          gauntletWaitingBoss = true;
          waveEnemiesRemaining = 1;
          return;
      }
    }

    // Spawn in formation
    _spawnFormation(waveFormation!, baseCount, types, rng);

    waveEnemiesRemaining = baseCount;

    // Reset timer for next wave
    waveTimer = 0;
    nextWaveAt = 50 + rng.nextDouble() * 30; // 50-80 seconds between waves
    if (game.gameMode == GameMode.gauntlet) {
      nextWaveAt = 3 + rng.nextDouble() * 2; // fast waves
      // physics/hazard pulses handled above
    }
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
    if (game.gameMode == GameMode.gauntlet) {
      game.bannerText = 'GAUNTLET CLEARED $gauntletWave/$gauntletTotal';
      game.bannerColor = const Color(0xFFFFD700);
      if (gauntletWave >= gauntletTotal) {
        game.endRun();
      }
    } else {
      game.bannerText = 'WAVE CLEARED! +${20 + wavesSpawned * 10} COINS';
      game.bannerColor = const Color(0xFF22C55E);
    }
  }
}
