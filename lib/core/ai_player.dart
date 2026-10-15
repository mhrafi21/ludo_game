import 'dart:math';

import 'models.dart';

class AiPlayer {
  AiPlayer({Random? random}) : _random = random ?? Random();
  final Random _random;

  int chooseMove(GameState state, int roll, Difficulty difficulty) {
    final moves = LudoRules.legalMoves(state, roll);
    if (moves.isEmpty) {
      throw StateError('AI was asked to move with no legal choices.');
    }
    if (difficulty == Difficulty.easy || moves.length == 1) {
      return moves[_random.nextInt(moves.length)];
    }
    final scored = <int, double>{
      for (final index in moves)
        index: _score(state, index, roll, difficulty == Difficulty.hard),
    };
    final bestScore = scored.values.reduce(max);
    final best = scored.entries
        .where((entry) => entry.value == bestScore)
        .map((entry) => entry.key)
        .toList();
    return best[_random.nextInt(best.length)];
  }

  double _score(GameState state, int index, int roll, bool hard) {
    final team = state.currentPlayer.team;
    final token = state.tokens[team]![index];
    final nextProgress = token.isInBase ? 1 : token.progress + roll;
    var score = token.isInBase ? 8.0 : roll * 1.4;
    if (nextProgress == LudoRules.finishProgress) score += hard ? 120 : 45;
    if (nextProgress >= 52) score += 12 + (nextProgress - 52);
    final landing = LudoRules.trackCell(team, nextProgress);
    if (landing != null) {
      if (LudoRules.safeTrackCells.contains(landing)) score += hard ? 15 : 7;
      for (final opponent
          in state.players.where((player) => player.team != team)) {
        for (final enemy in state.tokens[opponent.team]!) {
          if (LudoRules.trackCell(opponent.team, enemy.progress) == landing) {
            score += hard ? 100 : 38;
          }
          if (hard && enemy.progress > 0 && enemy.progress < 52) {
            final enemyCell =
                LudoRules.trackCell(opponent.team, enemy.progress)!;
            final distance = (landing - enemyCell + 52) % 52;
            if (distance >= 1 && distance <= 6) score -= (7 - distance) * 2.0;
          }
        }
      }
      if (hard && !LudoRules.safeTrackCells.contains(landing)) {
        for (final opponent
            in state.players.where((player) => player.team != team)) {
          for (final enemy in state.tokens[opponent.team]!) {
            final enemyCell =
                LudoRules.trackCell(opponent.team, enemy.progress);
            if (enemyCell != null && (landing - enemyCell + 52) % 52 <= 6) {
              score -= 2.5;
            }
          }
        }
      }
    }
    return score;
  }
}
