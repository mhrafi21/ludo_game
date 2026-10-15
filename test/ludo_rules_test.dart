import 'package:flutter_test/flutter_test.dart';
import 'package:offline_ludo/core/ai_player.dart';
import 'package:offline_ludo/core/dice_service.dart';
import 'package:offline_ludo/core/models.dart';

GameState game() => LudoRules.newGame(const [
      Player(team: Team.red, name: 'Red', isAi: false),
      Player(team: Team.green, name: 'Green', isAi: false),
    ]);

void main() {
  test('dice rolls always produce outcomes from one through six', () {
    final dice = DiceService();
    for (var i = 0; i < 200; i++) {
      expect(dice.roll(), inInclusiveRange(1, 6));
    }
  });

  group('Ludo rules', () {
    test('only a six can leave base', () {
      final state = game();
      expect(LudoRules.legalMoves(state, 5), isEmpty);
      expect(LudoRules.legalMoves(state, 6), [0, 1, 2, 3]);
    });

    test('a six brings a token onto its starting square and keeps the turn',
        () {
      final state = game();
      LudoRules.applyMove(state, 0, 6);
      expect(state.tokens[Team.red]![0].progress, 1);
      expect(state.currentPlayer.team, Team.red);
    });

    test('track positions wrap around and safe cells are identified', () {
      expect(LudoRules.trackCell(Team.red, 1), 0);
      expect(LudoRules.trackCell(Team.red, 51), 50);
      expect(LudoRules.isSafeProgress(Team.red, 9), isTrue);
      expect(LudoRules.isSafeProgress(Team.red, 2), isFalse);
    });

    test('captures an opponent on a non-safe landing cell', () {
      final state = game();
      state.tokens[Team.red]![0] = const Token(progress: 1);
      state.tokens[Team.green]![0] = const Token(progress: 41);
      final captured = LudoRules.applyMove(state, 0, 1);
      expect(captured, [Team.green]);
      expect(state.tokens[Team.green]![0].isInBase, isTrue);
      expect(state.currentPlayer.team, Team.red);
    });

    test('does not capture on a safe cell', () {
      final state = game();
      state.tokens[Team.red]![0] = const Token(progress: 8);
      state.tokens[Team.green]![0] = const Token(progress: 48);
      final captured = LudoRules.applyMove(state, 0, 1);
      expect(captured, isEmpty);
      expect(state.tokens[Team.green]![0].progress, 48);
      expect(state.currentPlayer.team, Team.green);
    });

    test('a normal move advances the turn, while a six grants an extra turn',
        () {
      final state = game();
      state.tokens[Team.red]![0] = const Token(progress: 2);
      LudoRules.applyMove(state, 0, 2);
      expect(state.currentPlayer.team, Team.green);
      state.currentPlayerIndex = 0;
      state.tokens[Team.red]![0] = const Token(progress: 2);
      LudoRules.applyMove(state, 0, 6);
      expect(state.currentPlayer.team, Team.red);
    });

    test('requires an exact roll to finish and detects the winner', () {
      final state = game();
      state.tokens[Team.red]![0] = const Token(progress: 57);
      expect(LudoRules.legalMoves(state, 2), isEmpty);
      LudoRules.applyMove(state, 0, 1);
      expect(state.tokens[Team.red]![0].isHome, isTrue);
      expect(state.currentPlayer.team, Team.red);
      for (var i = 1; i < 4; i++) {
        state.tokens[Team.red]![i] = const Token(progress: 58);
      }
      state.tokens[Team.red]![0] = const Token(progress: 57);
      state.currentPlayerIndex = 0;
      LudoRules.applyMove(state, 0, 1);
      expect(state.winner, Team.red);
      expect(state.isComplete, isTrue);
    });

    test('a six without a legal move keeps the current player', () {
      final state = game();
      LudoRules.applyNoMove(state, 6);
      expect(state.currentPlayerIndex, 0);
      LudoRules.applyNoMove(state, 4);
      expect(state.currentPlayerIndex, 1);
    });

    test('penalizes the third consecutive six when that rule is enabled', () {
      final state = game();
      expect(
          LudoRules.registerRoll(state, 6, penalizeThreeSixes: true), isFalse);
      expect(
          LudoRules.registerRoll(state, 6, penalizeThreeSixes: true), isFalse);
      expect(
          LudoRules.registerRoll(state, 6, penalizeThreeSixes: true), isTrue);
      expect(state.currentPlayerIndex, 1);
      expect(state.consecutiveSixes, 0);
    });

    test('saved game state is validated and round trips', () {
      final state = game();
      state.diceValue = 6;
      final restored = GameState.fromJson(state.toJson());
      expect(restored.players.length, 2);
      expect(restored.tokens[Team.blue]!.length, 4);
      expect(restored.diceValue, 6);
      final invalid = state.toJson()..['currentPlayerIndex'] = 8;
      expect(() => GameState.fromJson(invalid), throwsFormatException);
    });

    test('rejects an illegal move without changing token positions', () {
      final state = game();
      expect(() => LudoRules.applyMove(state, 0, 4), throwsArgumentError);
      expect(state.tokens[Team.red]![0].progress, 0);
    });
  });

  group('AI', () {
    test('every difficulty returns a legal move', () {
      final state = game();
      state.tokens[Team.red]![0] = const Token(progress: 6);
      for (final difficulty in Difficulty.values) {
        final move = AiPlayer().chooseMove(state, 3, difficulty);
        expect(LudoRules.legalMoves(state, 3), contains(move));
      }
    });
  });
}
