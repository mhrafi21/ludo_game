import 'package:flutter/material.dart';

import '../core/game_controller.dart';
import '../core/models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final GameController controller;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.controller.settings.playerName);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final settings = widget.controller.settings;
          return Scaffold(
            appBar: AppBar(title: const Text('SETTINGS')),
            body: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text('Your profile',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Player name',
                      prefixIcon: Icon(Icons.person_outline)),
                  onChanged: (name) => widget.controller.updateSettings(
                      settings.copyWith(
                          playerName:
                              name.trim().isEmpty ? 'Player' : name.trim())),
                ),
                const SizedBox(height: 16),
                Text('Look and feel',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<GameTheme>(
                  initialValue: settings.theme,
                  decoration:
                      const InputDecoration(labelText: 'Board and app theme'),
                  items: GameTheme.values
                      .map((theme) => DropdownMenuItem(
                          value: theme, child: Text(_label(theme.name))))
                      .toList(),
                  onChanged: (theme) {
                    if (theme != null) {
                      widget.controller
                          .updateSettings(settings.copyWith(theme: theme));
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: settings.avatar,
                  decoration: const InputDecoration(labelText: 'Avatar'),
                  items: const ['🙂', '😎', '😊', '🧑', '🐱', '🐼', '🦊', '🐸']
                      .map((avatar) => DropdownMenuItem(
                          value: avatar,
                          child: Text(avatar,
                              style: const TextStyle(fontSize: 22))))
                      .toList(),
                  onChanged: (avatar) {
                    if (avatar != null) {
                      widget.controller
                          .updateSettings(settings.copyWith(avatar: avatar));
                    }
                  },
                ),
                const SizedBox(height: 20),
                Text('Game options',
                    style: Theme.of(context).textTheme.titleLarge),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Penalize three consecutive sixes'),
                  subtitle: const Text('The third six forfeits the turn.'),
                  value: settings.penalizeThreeSixes,
                  onChanged: (value) => widget.controller.updateSettings(
                      settings.copyWith(penalizeThreeSixes: value)),
                ),
                DropdownButtonFormField<Difficulty>(
                  initialValue: settings.difficulty,
                  decoration:
                      const InputDecoration(labelText: 'Computer difficulty'),
                  items: Difficulty.values
                      .map((d) => DropdownMenuItem(
                          value: d, child: Text(_label(d.name))))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      widget.controller
                          .updateSettings(settings.copyWith(difficulty: value));
                    }
                  },
                ),
                const SizedBox(height: 20),
                Text('Feedback', style: Theme.of(context).textTheme.titleLarge),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sound effects'),
                  subtitle: const Text(
                      'Use the device’s built-in click sound for dice rolls.'),
                  value: settings.soundEnabled,
                  onChanged: (value) => widget.controller
                      .updateSettings(settings.copyWith(soundEnabled: value)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Background music'),
                  subtitle: const Text('Locally generated instrumental loop.'),
                  value: settings.musicEnabled,
                  onChanged: (value) => widget.controller
                      .updateSettings(settings.copyWith(musicEnabled: value)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vibration'),
                  value: settings.vibrationEnabled,
                  onChanged: (value) => widget.controller.updateSettings(
                      settings.copyWith(vibrationEnabled: value)),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                      'Everything is stored on this device. No account or network connection is needed.'),
                ),
              ],
            ),
          );
        },
      );

  String _label(String text) => '${text[0].toUpperCase()}${text.substring(1)}';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }
}
