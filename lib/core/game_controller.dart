import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ai_player.dart';
import 'audio_service.dart';
import 'dice_service.dart';
import 'local_store.dart';
import 'models.dart';

class GameController extends ChangeNotifier {
  GameController({
    required this.store,
    required this.settings,
    Random? random,
    AiPlayer? ai,
  })  : _dice = DiceService(random: random),
        _ai = ai ?? AiPlayer() {
    if (settings.musicEnabled) {
      unawaited(_runAudio(() => _audio.setMusicEnabled(true)));
    }
  }

  final LocalStore store;
  final DiceService _dice;
  final AiPlayer _ai;
  final _audio = AudioService();
  GameSettings settings;
  GameState? state;
  bool busy = false;
  bool rolling = false;
  int? rolled;
  List<int> legalTokens = const [];
  String? lastMessage;
  Timer? _aiTimer;
  Timer? _aiMoveTimer;
  Map<Team, List<Token>>? visualTokens;
  bool _disposed = false;

  void startNewGame({
    required int players,
    required int humans,
    List<String>? playerNames,
    List<String>? playerAvatars,
  }) {
    if (players < 2 || players > 4 || humans < 1 || humans > players) {
      throw ArgumentError('Choose 2–4 players and at least one human.');
    }
    final teams = Team.values.take(players).toList();
    state = LudoRules.newGame([
      for (var i = 0; i < players; i++)
        Player(
          team: teams[i],
          name: i < humans
              ? ((playerNames != null && i < playerNames.length)
                  ? playerNames[i]
                  : (i == 0 ? settings.playerName : 'Player ${i + 1}'))
              : '${teamNames[teams[i]]} Bot',
          isAi: i >= humans,
          avatar: i >= humans
              ? '🤖'
              : ((playerAvatars != null && i < playerAvatars.length)
                  ? playerAvatars[i]
                  : (i == 0
                      ? settings.avatar
                      : const ['🙂', '😎', '😊', '🧑'][i])),
        ),
    ]);
    rolled = null;
    legalTokens = const [];
    lastMessage = null;
    visualTokens = null;
    rolling = false;
    _aiTimer?.cancel();
    _aiMoveTimer?.cancel();
    busy = false;
    unawaited(store.saveGame(state!));
    notifyListeners();
  }

  Future<void> restoreGame() async {
    state = await store.loadGame();
    if (state != null) {
      state!.isPaused = false;
      rolled = state!.diceValue;
      legalTokens =
          rolled == null ? const [] : LudoRules.legalMoves(state!, rolled!);
      notifyListeners();
    }
  }

  void resumeCurrentTurn() => _scheduleAi();

  void rollDice() {
    final game = state;
    if (game == null ||
        game.isComplete ||
        game.isPaused ||
        busy ||
        rolling ||
        rolled != null ||
        game.currentPlayer.isAi) {
      return;
    }
    unawaited(_rollWithAnimation());
  }

  Future<void> _rollWithAnimation() async {
    final game = state;
    if (game == null ||
        game.isComplete ||
        game.isPaused ||
        busy ||
        rolling ||
        rolled != null) {
      return;
    }
    rolling = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 820));
    if (_disposed || state != game || game.isPaused || game.isComplete) {
      return;
    }
    rolling = false;
    _roll();
  }

  void _roll() {
    final game = state!;
    rolling = false;
    final value = _dice.roll();
    if (LudoRules.registerRoll(game, value,
        penalizeThreeSixes: settings.penalizeThreeSixes)) {
      rolled = null;
      game.diceValue = null;
      lastMessage = 'Three sixes! Your turn is forfeited.';
      unawaited(store.saveGame(game));
      notifyListeners();
      _scheduleAi();
      return;
    }
    rolled = value;
    game.diceValue = value;
    if (settings.soundEnabled) unawaited(_runAudio(_audio.playDice));
    if (settings.vibrationEnabled) unawaited(HapticFeedback.selectionClick());
    legalTokens = LudoRules.legalMoves(game, value);
    if (legalTokens.isEmpty) {
      lastMessage = '${game.currentPlayer.name} has no valid move.';
      LudoRules.applyNoMove(game, value);
      rolled = null;
      unawaited(store.saveGame(game));
      notifyListeners();
      _scheduleAi();
      return;
    }
    lastMessage = value == 6 ? 'Six! Roll again after your move.' : null;
    unawaited(store.saveGame(game));
    notifyListeners();
    _scheduleAi();
  }

  Future<void> moveToken(int tokenIndex) async {
    final game = state;
    if (game == null ||
        busy ||
        rolled == null ||
        !legalTokens.contains(tokenIndex) ||
        game.currentPlayer.isAi ||
        game.isPaused) {
      return;
    }
    busy = true;
    notifyListeners();
    await _animateMove(game, tokenIndex, rolled!);
    if (state != game || game.isPaused) {
      visualTokens = null;
      busy = false;
      notifyListeners();
      return;
    }
    final value = rolled!;
    final captures = LudoRules.applyMove(game, tokenIndex, value);
    rolled = null;
    legalTokens = const [];
    if (captures.isNotEmpty) {
      lastMessage =
          'Captured ${captures.length} token${captures.length == 1 ? '' : 's'}!';
    }
    if (captures.isNotEmpty && settings.vibrationEnabled) {
      unawaited(HapticFeedback.mediumImpact());
    }
    if (settings.soundEnabled) {
      unawaited(
          _runAudio(captures.isEmpty ? _audio.playMove : _audio.playCapture));
    }
    busy = false;
    await _afterMove(game);
  }

  Future<void> _afterMove(GameState game) async {
    if (game.isComplete) {
      lastMessage =
          '${game.players.firstWhere((player) => player.team == game.winner).name} wins!';
      await store.clearGame();
      await store.recordMatch(MatchRecord(
        winnerName: game.players
            .firstWhere((player) => player.team == game.winner)
            .name,
        playedAt: DateTime.now(),
        playerCount: game.players.length,
      ));
      if (settings.vibrationEnabled) unawaited(HapticFeedback.heavyImpact());
      if (settings.soundEnabled) unawaited(_runAudio(_audio.playVictory));
      visualTokens = null;
      notifyListeners();
      return;
    }
    game.diceValue = null;
    visualTokens = null;
    await store.saveGame(game);
    notifyListeners();
    _scheduleAi();
  }

  void _scheduleAi() {
    _aiTimer?.cancel();
    _aiMoveTimer?.cancel();
    final game = state;
    if (game == null ||
        game.isComplete ||
        game.isPaused ||
        !game.currentPlayer.isAi) {
      return;
    }
    _aiTimer = Timer(const Duration(milliseconds: 650), () {
      if (state != game || game.isPaused || game.isComplete) return;
      if (rolled == null) {
        unawaited(_rollWithAnimation());
        return;
      }
      if (legalTokens.isEmpty) return;
      final value = rolled!;
      final index = _ai.chooseMove(game, value, settings.difficulty);
      busy = true;
      notifyListeners();
      _aiMoveTimer = Timer(const Duration(milliseconds: 420), () async {
        await _animateMove(game, index, value);
        if (state != game || game.isPaused) {
          visualTokens = null;
          busy = false;
          notifyListeners();
          return;
        }
        final captures = LudoRules.applyMove(game, index, value);
        rolled = null;
        legalTokens = const [];
        if (captures.isNotEmpty && settings.vibrationEnabled) {
          unawaited(HapticFeedback.mediumImpact());
        }
        if (settings.soundEnabled) {
          unawaited(_runAudio(
              captures.isEmpty ? _audio.playMove : _audio.playCapture));
        }
        busy = false;
        await _afterMove(game);
      });
    });
  }

  void togglePause() {
    if (state == null || state!.isComplete) return;
    state!.isPaused = !state!.isPaused;
    _aiTimer?.cancel();
    _aiMoveTimer?.cancel();
    if (state!.isPaused) {
      rolling = false;
      busy = false;
      visualTokens = null;
    }
    unawaited(store.saveGame(state!));
    notifyListeners();
    if (!state!.isPaused) _scheduleAi();
  }

  Future<void> quitGame() async {
    _aiTimer?.cancel();
    _aiMoveTimer?.cancel();
    state = null;
    busy = false;
    rolling = false;
    visualTokens = null;
    rolled = null;
    legalTokens = const [];
    await store.clearGame();
    notifyListeners();
  }

  Future<void> updateSettings(GameSettings next) async {
    final musicChanged = next.musicEnabled != settings.musicEnabled;
    settings = next;
    await store.saveSettings(next);
    if (musicChanged) {
      await _runAudio(() => _audio.setMusicEnabled(next.musicEnabled));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _aiTimer?.cancel();
    _aiMoveTimer?.cancel();
    unawaited(_audio.dispose());
    super.dispose();
  }

  Future<void> _runAudio(Future<void> Function() play) async {
    try {
      await play();
    } on PlatformException {
      lastMessage = 'Audio is unavailable on this device.';
      notifyListeners();
    }
  }

  Future<void> _animateMove(GameState game, int tokenIndex, int roll) async {
    final team = game.currentPlayer.team;
    final token = game.tokens[team]![tokenIndex];
    final start = token.progress;
    final end = token.isInBase ? 1 : start + roll;
    final firstStep = token.isInBase ? 1 : start + 1;
    for (var progress = firstStep; progress <= end; progress++) {
      if (state != game || game.isPaused) return;
      final display = {
        for (final entry in game.tokens.entries)
          entry.key: List<Token>.from(entry.value),
      };
      display[team]![tokenIndex] = Token(progress: progress);
      visualTokens = display;
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 65));
    }
    visualTokens = null;
    notifyListeners();
  }
}
