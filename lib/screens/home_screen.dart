import 'package:flutter/material.dart';

import '../core/game_controller.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.hasSavedGame,
    required this.onGameStarted,
    required this.onContinue,
    required this.onSettings,
    required this.onStatistics,
  });

  final GameController controller;
  final bool hasSavedGame;
  final VoidCallback onGameStarted;
  final VoidCallback onContinue;
  final VoidCallback onSettings;
  final VoidCallback onStatistics;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton.filledTonal(
                        tooltip: 'Settings',
                        onPressed: onSettings,
                        icon: const Icon(Icons.settings_rounded),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _LudoLogo(),
                    const SizedBox(height: 8),
                    Text('Your favorite board game, wherever you are.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 28),
                    if (hasSavedGame)
                      _MenuButton(
                        title: 'Continue game',
                        subtitle: 'Pick up where you left off',
                        icon: Icons.play_circle_fill_rounded,
                        color: const Color(0xff27ae60),
                        onPressed: onContinue,
                      ),
                    _MenuButton(
                      title: 'Play vs AI',
                      subtitle: 'You vs clever computer opponents',
                      icon: Icons.smart_toy_rounded,
                      color: const Color(0xff4267b2),
                      onPressed: () async {
                        await _start(context, players: 2, humans: 1);
                      },
                    ),
                    _MenuButton(
                      title: 'Local multiplayer',
                      subtitle: 'Pass the device and play together',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xffe67e22),
                      onPressed: () => _chooseLocal(context),
                    ),
                    _MenuButton(
                      title: 'New game',
                      subtitle: 'Choose players and opponents',
                      icon: Icons.add_circle_rounded,
                      color: const Color(0xff9b59b6),
                      onPressed: () => _chooseNew(context),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _SmallAction(
                                icon: Icons.bar_chart_rounded,
                                label: 'Statistics',
                                onTap: onStatistics)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SmallAction(
                            icon: Icons.menu_book_rounded,
                            label: 'How to play',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                    builder: (_) => const HowToPlayScreen())),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('100% offline · No ads · Just fun',
                        style: TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> _start(
    BuildContext context, {
    required int players,
    required int humans,
    List<String>? names,
    List<String>? avatars,
  }) async {
    if (names != null && avatars != null) {
      await controller.updateSettings(controller.settings.copyWith(
        playerNames: names,
        playerAvatars: avatars,
      ));
    }
    if (!context.mounted) return;
    controller.startNewGame(
      players: players,
      humans: humans,
      playerNames: names,
      playerAvatars: avatars,
    );
    onGameStarted();
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => GameScreen(controller: controller)));
  }

  Future<void> _chooseLocal(BuildContext context) async {
    final setup = await _setupDialog(context, localOnly: true);
    if (setup != null && context.mounted) {
      await _start(context,
          players: setup.players,
          humans: setup.humans,
          names: setup.names,
          avatars: setup.avatars);
    }
  }

  Future<void> _chooseNew(BuildContext context) async {
    final setup = await _setupDialog(context, localOnly: false);
    if (setup != null && context.mounted) {
      await _start(context,
          players: setup.players,
          humans: setup.humans,
          names: setup.names,
          avatars: setup.avatars);
    }
  }

  Future<_GameSetup?> _setupDialog(
    BuildContext context, {
    required bool localOnly,
  }) async {
    final names = List.generate(4, (index) {
      final saved = controller.settings.playerNames;
      final initial = index == 0
          ? controller.settings.playerName
          : (index < saved.length ? saved[index] : 'Player ${index + 1}');
      return TextEditingController(text: initial);
    });
    final savedAvatars = controller.settings.playerAvatars;
    final avatars = List.generate(
      4,
      (index) => index == 0
          ? controller.settings.avatar
          : (index < savedAvatars.length
              ? savedAvatars[index]
              : const ['🙂', '😎', '😊', '🧑'][index]),
    );
    final setup = await showDialog<_GameSetup>(
      context: context,
      builder: (context) {
        var players = localOnly ? 2 : 4;
        var humans = localOnly ? 2 : 1;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(localOnly ? 'Local multiplayer' : 'New game'),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: players,
                      decoration: const InputDecoration(labelText: 'Players'),
                      items: [2, 3, 4]
                          .map((value) => DropdownMenuItem(
                              value: value, child: Text('$value players')))
                          .toList(),
                      onChanged: (value) => setState(() {
                        players = value ?? players;
                        humans = localOnly
                            ? players
                            : humans.clamp(1, players).toInt();
                      }),
                    ),
                    if (!localOnly)
                      DropdownButtonFormField<int>(
                        initialValue: humans,
                        decoration:
                            const InputDecoration(labelText: 'Human players'),
                        items: List.generate(players, (i) => i + 1)
                            .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                    '$value human${value == 1 ? '' : 's'}')))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => humans = value ?? humans),
                      ),
                    const SizedBox(height: 12),
                    for (var index = 0; index < humans; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: names[index],
                                maxLength: 20,
                                decoration: InputDecoration(
                                  labelText: 'Player ${index + 1} name',
                                  counterText: '',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: avatars[index],
                              items: const [
                                '🙂',
                                '😎',
                                '😊',
                                '🧑',
                                '🐱',
                                '🐼',
                                '🦊',
                                '🐸'
                              ]
                                  .map((avatar) => DropdownMenuItem(
                                      value: avatar,
                                      child: Text(avatar,
                                          style:
                                              const TextStyle(fontSize: 22))))
                                  .toList(),
                              onChanged: (avatar) => setState(() =>
                                  avatars[index] = avatar ?? avatars[index]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  _GameSetup(
                    players: players,
                    humans: humans,
                    names: [
                      for (var i = 0; i < humans; i++)
                        names[i].text.trim().isEmpty
                            ? 'Player ${i + 1}'
                            : names[i].text.trim(),
                    ],
                    avatars: avatars.take(humans).toList(),
                  ),
                ),
                child: const Text('Start'),
              ),
            ],
          ),
        );
      },
    );
    for (final name in names) {
      name.dispose();
    }
    return setup;
  }
}

class _GameSetup {
  const _GameSetup({
    required this.players,
    required this.humans,
    required this.names,
    required this.avatars,
  });

  final int players;
  final int humans;
  final List<String> names;
  final List<String> avatars;
}

class _LudoLogo extends StatelessWidget {
  const _LudoLogo();
  @override
  Widget build(BuildContext context) => Column(
        children: [
          SizedBox(
            width: 176,
            height: 176,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(38),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 18,
                          offset: Offset(0, 8))
                    ],
                  ),
                ),
                const Positioned(
                    left: 27, top: 27, child: _Pip(color: Color(0xffe74c3c))),
                const Positioned(
                    right: 27, top: 27, child: _Pip(color: Color(0xff27ae60))),
                const Positioned(
                    left: 27,
                    bottom: 27,
                    child: _Pip(color: Color(0xff3498db))),
                const Positioned(
                    right: 27,
                    bottom: 27,
                    child: _Pip(color: Color(0xfff1c40f))),
                const Text('L',
                    style:
                        TextStyle(fontSize: 77, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('LUDO',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 10)),
        ],
      );
}

class _Pip extends StatelessWidget {
  const _Pip({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
            ]),
      );
}

class _MenuButton extends StatelessWidget {
  const _MenuButton(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.color,
      required this.onPressed});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 24,
                      backgroundColor: color.withValues(alpha: .15),
                      child: Icon(icon, color: color)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(subtitle,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      );
}

class _SmallAction extends StatelessWidget {
  const _SmallAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      );
}
