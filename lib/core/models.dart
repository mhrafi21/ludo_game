import 'dart:convert';

enum Team { red, green, yellow, blue }

enum Difficulty { easy, medium, hard }

enum GameTheme { classic, dark, neon, wooden }

const teamColors = <Team, ColorValue>{
  Team.red: ColorValue(0xffe74c3c),
  Team.green: ColorValue(0xff27ae60),
  Team.yellow: ColorValue(0xfff1c40f),
  Team.blue: ColorValue(0xff3498db),
};

const teamNames = <Team, String>{
  Team.red: 'Ruby',
  Team.green: 'Jade',
  Team.yellow: 'Gold',
  Team.blue: 'Sapphire',
};

class ColorValue {
  const ColorValue(this.value);
  final int value;
}

class Player {
  const Player({
    required this.team,
    required this.name,
    required this.isAi,
    this.avatar = '🙂',
  });

  final Team team;
  final String name;
  final bool isAi;
  final String avatar;

  Map<String, Object?> toJson() => {
        'team': team.name,
        'name': name,
        'isAi': isAi,
        'avatar': avatar,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        team: Team.values.byName(json['team'] as String),
        name: json['name'] as String,
        isAi: json['isAi'] as bool,
        avatar: json['avatar'] as String? ?? '🙂',
      );
}

class Token {
  const Token({required this.progress});
  final int progress;
  bool get isInBase => progress == 0;
  bool get isHome => progress == LudoRules.finishProgress;

  Map<String, Object?> toJson() => {'progress': progress};
}

class GameState {
  GameState({
    required this.players,
    required this.tokens,
    this.currentPlayerIndex = 0,
    this.diceValue,
    this.winner,
    this.consecutiveSixes = 0,
    this.isPaused = false,
  });

  final List<Player> players;
  final Map<Team, List<Token>> tokens;
  int currentPlayerIndex;
  int? diceValue;
  Team? winner;
  int consecutiveSixes;
  bool isPaused;

  Player get currentPlayer => players[currentPlayerIndex];
  bool get isComplete => winner != null;

  Map<String, Object?> toJson() => {
        'players': players.map((p) => p.toJson()).toList(),
        'tokens': tokens
            .map((k, v) => MapEntry(k.name, v.map((t) => t.toJson()).toList())),
        'currentPlayerIndex': currentPlayerIndex,
        'diceValue': diceValue,
        'winner': winner?.name,
        'consecutiveSixes': consecutiveSixes,
        'isPaused': isPaused,
      };

  String encode() => jsonEncode(toJson());

  factory GameState.fromJson(Map<String, dynamic> json) {
    final players = (json['players'] as List<dynamic>)
        .map((p) => Player.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
    final rawTokens = Map<String, dynamic>.from(json['tokens'] as Map);
    final tokens = <Team, List<Token>>{
      for (final team in Team.values)
        team: (rawTokens[team.name] as List<dynamic>)
            .map((t) => Token(progress: (t as Map)['progress'] as int))
            .toList(),
    };
    final state = GameState(
      players: players,
      tokens: tokens,
      currentPlayerIndex: json['currentPlayerIndex'] as int,
      diceValue: json['diceValue'] as int?,
      winner: (json['winner'] as String?) == null
          ? null
          : Team.values.byName(json['winner'] as String),
      consecutiveSixes: json['consecutiveSixes'] as int? ?? 0,
      isPaused: json['isPaused'] as bool? ?? false,
    );
    if (!LudoRules.isValidState(state)) {
      throw const FormatException('Saved game state is invalid.');
    }
    return state;
  }
}

class GameSettings {
  const GameSettings({
    this.soundEnabled = true,
    this.musicEnabled = false,
    this.vibrationEnabled = true,
    this.theme = GameTheme.classic,
    this.difficulty = Difficulty.medium,
    this.penalizeThreeSixes = true,
    this.playerName = 'Player',
    this.avatar = '🙂',
    this.playerNames = const [],
    this.playerAvatars = const [],
  });

  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrationEnabled;
  final GameTheme theme;
  final Difficulty difficulty;
  final bool penalizeThreeSixes;
  final String playerName;
  final String avatar;
  final List<String> playerNames;
  final List<String> playerAvatars;

  GameSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrationEnabled,
    GameTheme? theme,
    Difficulty? difficulty,
    bool? penalizeThreeSixes,
    String? playerName,
    String? avatar,
    List<String>? playerNames,
    List<String>? playerAvatars,
  }) =>
      GameSettings(
        soundEnabled: soundEnabled ?? this.soundEnabled,
        musicEnabled: musicEnabled ?? this.musicEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        theme: theme ?? this.theme,
        difficulty: difficulty ?? this.difficulty,
        penalizeThreeSixes: penalizeThreeSixes ?? this.penalizeThreeSixes,
        playerName: playerName ?? this.playerName,
        avatar: avatar ?? this.avatar,
        playerNames: playerNames ?? this.playerNames,
        playerAvatars: playerAvatars ?? this.playerAvatars,
      );

  Map<String, Object?> toJson() => {
        'soundEnabled': soundEnabled,
        'musicEnabled': musicEnabled,
        'vibrationEnabled': vibrationEnabled,
        'theme': theme.name,
        'difficulty': difficulty.name,
        'penalizeThreeSixes': penalizeThreeSixes,
        'playerName': playerName,
        'avatar': avatar,
        'playerNames': playerNames,
        'playerAvatars': playerAvatars,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        musicEnabled: json['musicEnabled'] as bool? ?? false,
        vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
        theme: GameTheme.values.byName(json['theme'] as String? ?? 'classic'),
        difficulty:
            Difficulty.values.byName(json['difficulty'] as String? ?? 'medium'),
        penalizeThreeSixes: json['penalizeThreeSixes'] as bool? ?? true,
        playerName: json['playerName'] as String? ?? 'Player',
        avatar: json['avatar'] as String? ?? '🙂',
        playerNames:
            (json['playerNames'] as List<dynamic>?)?.cast<String>() ?? const [],
        playerAvatars:
            (json['playerAvatars'] as List<dynamic>?)?.cast<String>() ??
                const [],
      );
}

class MatchRecord {
  const MatchRecord(
      {required this.winnerName,
      required this.playedAt,
      required this.playerCount});
  final String winnerName;
  final DateTime playedAt;
  final int playerCount;

  Map<String, Object?> toJson() => {
        'winnerName': winnerName,
        'playedAt': playedAt.toIso8601String(),
        'playerCount': playerCount,
      };

  factory MatchRecord.fromJson(Map<String, dynamic> json) => MatchRecord(
        winnerName: json['winnerName'] as String,
        playedAt: DateTime.parse(json['playedAt'] as String),
        playerCount: json['playerCount'] as int,
      );
}

class LudoRules {
  static const finishProgress = 58;
  static const trackLength = 52;
  static const starts = <Team, int>{
    Team.red: 0,
    Team.green: 13,
    Team.yellow: 26,
    Team.blue: 39,
  };
  static const safeTrackCells = <int>{0, 8, 13, 21, 26, 34, 39, 47};

  static GameState newGame(List<Player> players) {
    if (players.length < 2 ||
        players.length > 4 ||
        players.map((p) => p.team).toSet().length != players.length) {
      throw ArgumentError('A game needs 2–4 players with different teams.');
    }
    return GameState(
      players: List.unmodifiable(players),
      tokens: {
        for (final team in Team.values)
          team: List.generate(4, (_) => const Token(progress: 0))
      },
    );
  }

  static int? trackCell(Team team, int progress) {
    if (progress < 1 || progress > 51) return null;
    return (starts[team]! + progress - 1) % trackLength;
  }

  static bool isSafeProgress(Team team, int progress) {
    final cell = trackCell(team, progress);
    return cell != null && safeTrackCells.contains(cell);
  }

  static List<int> legalMoves(GameState state, int roll) {
    if (roll < 1 || roll > 6 || state.isComplete) return const [];
    final tokens = state.tokens[state.currentPlayer.team]!;
    return [
      for (var i = 0; i < tokens.length; i++)
        if (_canMove(tokens[i], roll)) i,
    ];
  }

  static bool _canMove(Token token, int roll) =>
      token.isInBase ? roll == 6 : token.progress + roll <= finishProgress;

  static List<Team> applyMove(GameState state, int tokenIndex, int roll) {
    final moves = legalMoves(state, roll);
    if (!moves.contains(tokenIndex)) throw ArgumentError('Illegal token move.');
    final team = state.currentPlayer.team;
    final current = state.tokens[team]!;
    final old = current[tokenIndex];
    final nextProgress = old.isInBase ? 1 : old.progress + roll;
    current[tokenIndex] = Token(progress: nextProgress);
    final captured = <Team>[];
    final landing = trackCell(team, nextProgress);
    if (landing != null && !safeTrackCells.contains(landing)) {
      for (final opponent in state.players.where((p) => p.team != team)) {
        final opponentTokens = state.tokens[opponent.team]!;
        for (var i = 0; i < opponentTokens.length; i++) {
          if (trackCell(opponent.team, opponentTokens[i].progress) == landing) {
            opponentTokens[i] = const Token(progress: 0);
            captured.add(opponent.team);
          }
        }
      }
    }
    if (current.every((token) => token.isHome)) state.winner = team;
    final keepsTurn =
        roll == 6 || captured.isNotEmpty || nextProgress == finishProgress;
    if (!keepsTurn && !state.isComplete) _advance(state);
    return captured;
  }

  static void applyNoMove(GameState state, int roll) {
    if (roll < 1 || roll > 6) throw ArgumentError.value(roll, 'roll');
    state.diceValue = null;
    if (roll != 6) _advance(state);
  }

  static void _advance(GameState state) {
    state.currentPlayerIndex =
        (state.currentPlayerIndex + 1) % state.players.length;
    state.diceValue = null;
    state.consecutiveSixes = 0;
  }

  static void skipTurn(GameState state) => _advance(state);

  static bool registerRoll(GameState state, int roll,
      {required bool penalizeThreeSixes}) {
    if (roll < 1 || roll > 6) throw ArgumentError.value(roll, 'roll');
    if (!penalizeThreeSixes || roll != 6) {
      state.consecutiveSixes = 0;
      return false;
    }
    state.consecutiveSixes++;
    if (state.consecutiveSixes < 3) return false;
    skipTurn(state);
    return true;
  }

  static bool isValidState(GameState state) {
    if (state.players.length < 2 ||
        state.players.length > 4 ||
        state.currentPlayerIndex < 0 ||
        state.currentPlayerIndex >= state.players.length ||
        state.players.map((p) => p.team).toSet().length !=
            state.players.length ||
        state.tokens.length != Team.values.length ||
        state.tokens.values.any((tokens) =>
            tokens.length != 4 ||
            tokens.any((token) =>
                token.progress < 0 || token.progress > finishProgress)) ||
        (state.diceValue != null &&
            (state.diceValue! < 1 || state.diceValue! > 6)) ||
        state.consecutiveSixes < 0 ||
        state.consecutiveSixes > 2) {
      return false;
    }
    return state.winner == null ||
        state.tokens[state.winner]!.every((token) => token.isHome);
  }
}
