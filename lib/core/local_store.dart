import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class LocalStore {
  static const _settingsKey = 'ludo.settings.v1';
  static const _gameKey = 'ludo.saved-game.v1';
  static const _historyKey = 'ludo.history.v1';
  static const _winsKey = 'ludo.wins.v1';
  static const _achievementsKey = 'ludo.achievements.v1';

  Future<GameSettings> loadSettings() async {
    final raw = (await SharedPreferences.getInstance()).getString(_settingsKey);
    if (raw == null) return const GameSettings();
    try {
      return GameSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } on FormatException {
      return const GameSettings();
    } on TypeError {
      return const GameSettings();
    } on ArgumentError {
      return const GameSettings();
    }
  }

  Future<void> saveSettings(GameSettings settings) async {
    await (await SharedPreferences.getInstance())
        .setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<GameState?> loadGame() async {
    final raw = (await SharedPreferences.getInstance()).getString(_gameKey);
    if (raw == null) return null;
    try {
      return GameState.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } on FormatException {
      await clearGame();
      return null;
    } on TypeError {
      await clearGame();
      return null;
    } on ArgumentError {
      await clearGame();
      return null;
    }
  }

  Future<void> saveGame(GameState state) async {
    await (await SharedPreferences.getInstance())
        .setString(_gameKey, state.encode());
  }

  Future<void> clearGame() async {
    await (await SharedPreferences.getInstance()).remove(_gameKey);
  }

  Future<List<MatchRecord>> loadHistory() async {
    final raw = (await SharedPreferences.getInstance()).getString(_historyKey);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((item) =>
              MatchRecord.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    } on ArgumentError {
      return const [];
    }
  }

  Future<void> recordMatch(MatchRecord record) async {
    final preferences = await SharedPreferences.getInstance();
    final history = await loadHistory();
    history.insert(0, record);
    if (history.length > 100) history.removeRange(100, history.length);
    await preferences.setString(
        _historyKey, jsonEncode(history.map((item) => item.toJson()).toList()));
    final wins = await loadWins();
    wins[record.winnerName] = (wins[record.winnerName] ?? 0) + 1;
    await preferences.setString(_winsKey, jsonEncode(wins));
    final achievements = await loadAchievements();
    if (history.isNotEmpty) achievements.add('first_match');
    if (history.length >= 10) achievements.add('ten_matches');
    if (record.playerCount == 4) achievements.add('four_player_match');
    if ((wins[record.winnerName] ?? 0) >= 10) achievements.add('ten_wins');
    await preferences.setStringList(_achievementsKey, achievements.toList());
  }

  Future<Set<String>> loadAchievements() async =>
      (await SharedPreferences.getInstance())
          .getStringList(_achievementsKey)
          ?.toSet() ??
      {};

  Future<Map<String, int>> loadWins() async {
    final raw = (await SharedPreferences.getInstance()).getString(_winsKey);
    if (raw == null) return {};
    try {
      return Map<String, int>.from(jsonDecode(raw) as Map);
    } on FormatException {
      return {};
    } on TypeError {
      return {};
    }
  }
}
