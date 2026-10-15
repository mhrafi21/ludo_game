import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/game_controller.dart';
import '../core/models.dart';
import '../widgets/ludo_board.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final state = controller.state;
          if (state == null) {
            return const Scaffold(
                body: Center(child: Text('No active match.')));
          }
          return Scaffold(
            appBar: AppBar(
              title: const Text('LUDO'),
              leading: IconButton(
                tooltip: 'Pause game',
                icon: Icon(state.isPaused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded),
                onPressed: controller.busy ? null : controller.togglePause,
              ),
              actions: [
                PopupMenuButton<String>(
                  tooltip: 'Game options',
                  enabled: !controller.busy,
                  onSelected: (choice) {
                    if (choice == 'restart') _confirmRestart(context);
                    if (choice == 'quit') _confirmQuit(context);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                        value: 'restart',
                        child: ListTile(
                            leading: Icon(Icons.restart_alt),
                            title: Text('Restart match'))),
                    PopupMenuItem(
                        value: 'quit',
                        child: ListTile(
                            leading: Icon(Icons.close),
                            title: Text('Quit match'))),
                  ],
                ),
              ],
            ),
            body: state.isComplete
                ? _WinnerPanel(
                    state: state,
                    onReplay: () => controller.startNewGame(
                      players: state.players.length,
                      humans:
                          state.players.where((player) => !player.isAi).length,
                      playerNames: state.players
                          .where((player) => !player.isAi)
                          .map((player) => player.name)
                          .toList(),
                      playerAvatars: state.players
                          .where((player) => !player.isAi)
                          .map((player) => player.avatar)
                          .toList(),
                    ),
                    onHome: () async {
                      await controller.quitGame();
                      if (context.mounted) Navigator.pop(context);
                    },
                  )
                : SafeArea(
                    child: LayoutBuilder(builder: (context, constraints) {
                      return Column(
                        children: [
                          _PlayerCorners(
                            state: state,
                            controller: controller,
                            teams: const [Team.green, Team.yellow],
                          ),
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxWidth: 600,
                                    maxHeight: constraints.maxHeight),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant
                                            .withValues(alpha: .55),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: .12),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: LudoBoard(
                                        state: state,
                                        legalTokens: controller.legalTokens,
                                        displayTokens:
                                            controller.visualTokens,
                                        onTokenTap: controller.moveToken,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _TurnMessage(
                              state: state, controller: controller),
                          _PlayerCorners(
                            state: state,
                            controller: controller,
                            teams: const [Team.red, Team.blue],
                          ),
                        ],
                      );
                    }),
                  ),
            bottomNavigationBar: state.isPaused
                ? Material(
                    color: Colors.black.withValues(alpha: .7),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Match paused',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 18),
                            FilledButton(
                                onPressed: controller.togglePause,
                                child: const Text('Resume')),
                          ],
                        ),
                      ),
                    ),
                  )
                : null,
            floatingActionButton: state.isComplete
                ? FloatingActionButton.extended(
                    onPressed: () {
                      final players = state.players.length;
                      final humans =
                          state.players.where((player) => !player.isAi).length;
                      controller.startNewGame(
                        players: players,
                        humans: humans,
                        playerNames: state.players
                            .where((player) => !player.isAi)
                            .map((player) => player.name)
                            .toList(),
                        playerAvatars: state.players
                            .where((player) => !player.isAi)
                            .map((player) => player.avatar)
                            .toList(),
                      );
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('New match'),
                  )
                : null,
          );
        },
      );

  Future<void> _confirmQuit(BuildContext context) async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit this match?'),
        content: const Text('Your current match will be discarded.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep playing')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Quit')),
        ],
      ),
    );
    if (quit == true && context.mounted) {
      await controller.quitGame();
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _confirmRestart(BuildContext context) async {
    final restart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart this match?'),
        content:
            const Text('The current match will be replaced with a new one.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restart')),
        ],
      ),
    );
    final state = controller.state;
    if (restart == true && state != null && context.mounted) {
      controller.startNewGame(
        players: state.players.length,
        humans: state.players.where((player) => !player.isAi).length,
        playerNames: state.players
            .where((player) => !player.isAi)
            .map((player) => player.name)
            .toList(),
        playerAvatars: state.players
            .where((player) => !player.isAi)
            .map((player) => player.avatar)
            .toList(),
      );
    }
  }
}

class _PlayerCorners extends StatelessWidget {
  const _PlayerCorners({
    required this.state,
    required this.controller,
    required this.teams,
  });

  final GameState state;
  final GameController controller;
  final List<Team> teams;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 3),
        child: Row(
          children: [
            for (var i = 0; i < teams.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _PlayerCorner(
                  key: ValueKey(teams[i]),
                  player: state.players
                      .where((player) => player.team == teams[i])
                      .firstOrNull,
                  state: state,
                  controller: controller,
                ),
              ),
            ],
          ],
        ),
      );
}

class _PlayerCorner extends StatefulWidget {
  const _PlayerCorner({
    super.key,
    required this.player,
    required this.state,
    required this.controller,
  });

  final Player? player;
  final GameState state;
  final GameController controller;

  @override
  State<_PlayerCorner> createState() => _PlayerCornerState();
}

class _PlayerCornerState extends State<_PlayerCorner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );

  @override
  void didUpdateWidget(covariant _PlayerCorner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSpin();
  }

  void _syncSpin() {
    final player = widget.player;
    final shouldSpin = player != null &&
        player.team == widget.state.currentPlayer.team &&
        widget.controller.rolling;
    if (shouldSpin && !_spin.isAnimating) {
      _spin.forward(from: 0);
    } else if (!shouldSpin && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncSpin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    if (player == null) return const SizedBox(height: 64);

    final color = Color(teamColors[player.team]!.value);
    final isCurrent = player.team == widget.state.currentPlayer.team;
    final canRoll = isCurrent &&
        !player.isAi &&
        !widget.state.isPaused &&
        !widget.controller.busy &&
        !widget.controller.rolling &&
        widget.controller.rolled == null &&
        !widget.state.isComplete;
    final face = isCurrent ? widget.controller.rolled : null;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: isCurrent
            ? color.withValues(alpha: scheme.brightness == Brightness.dark
                ? .22
                : .12)
            : scheme.surfaceContainerHighest.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: isCurrent ? .95 : .35),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: color.withValues(alpha: .16),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Text(player.avatar, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCurrent
                      ? (widget.controller.rolling
                          ? 'ROLLING'
                          : face != null
                              ? 'MOVE A TOKEN'
                              : 'YOUR TURN')
                      : player.isAi
                          ? 'COMPUTER'
                          : teamNames[player.team]!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isCurrent ? color : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .7,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Semantics(
            button: canRoll,
            label: face == null ? '${player.name} dice, roll' : 'Dice shows $face',
            child: GestureDetector(
              onTap: canRoll ? widget.controller.rollDice : null,
              child: AnimatedBuilder(
                animation: _spin,
                builder: (context, _) {
                  final rollingFace = widget.controller.rolling && isCurrent
                      ? (_spin.value * 18).floor() % 6 + 1
                      : face ?? 1;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, .0015)
                      ..rotateY(_spin.value * math.pi * 8)
                      ..rotateZ(_spin.value * math.pi * 4),
                    child: Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: color.withValues(alpha: .65),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: .18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _DiceFacePainter(
                          face: rollingFace,
                          pipColor: color,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }
}

class _DiceFacePainter extends CustomPainter {
  const _DiceFacePainter({required this.face, required this.pipColor});

  final int face;
  final Color pipColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = pipColor;
    final radius = size.width * .075;
    final left = size.width * .27;
    final middle = size.width * .5;
    final right = size.width * .73;
    final top = size.height * .27;
    final center = size.height * .5;
    final bottom = size.height * .73;
    final pips = switch (face) {
      1 => [(middle, center)],
      2 => [(left, top), (right, bottom)],
      3 => [(left, top), (middle, center), (right, bottom)],
      4 => [(left, top), (right, top), (left, bottom), (right, bottom)],
      5 => [
          (left, top),
          (right, top),
          (middle, center),
          (left, bottom),
          (right, bottom),
        ],
      _ => [
          (left, top),
          (right, top),
          (left, center),
          (right, center),
          (left, bottom),
          (right, bottom),
        ],
    };
    for (final (x, y) in pips) {
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiceFacePainter oldDelegate) =>
      oldDelegate.face != face || oldDelegate.pipColor != pipColor;
}

class _TurnMessage extends StatelessWidget {
  const _TurnMessage({required this.state, required this.controller});

  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final message = controller.lastMessage ??
        (state.currentPlayer.isAi
            ? 'The computer is taking its turn'
            : controller.rolling
                ? 'Rolling the dice…'
                : controller.rolled != null
                    ? 'Tap one of your glowing tokens'
                    : 'Tap your dice to roll');
    final color = Color(teamColors[state.currentPlayer.team]!.value);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Container(
          key: ValueKey(message),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                controller.rolling ? Icons.casino_rounded : Icons.touch_app,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinnerPanel extends StatelessWidget {
  const _WinnerPanel({
    required this.state,
    required this.onReplay,
    required this.onHome,
  });

  final GameState state;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final winner =
        state.players.firstWhere((player) => player.team == state.winner);
    final color = Color(teamColors[winner.team]!.value);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: .2),
            Theme.of(context).colorScheme.surface
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Wrap(
                  spacing: 24,
                  alignment: WrapAlignment.center,
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 32)),
                    Text('🎊', style: TextStyle(fontSize: 32)),
                    Text('🏆', style: TextStyle(fontSize: 76)),
                    Text('🎊', style: TextStyle(fontSize: 32)),
                    Text('🎉', style: TextStyle(fontSize: 32)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'VICTORY!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                ),
                const SizedBox(height: 18),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: .4, end: 1),
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: color,
                    child: Text(winner.avatar,
                        style: const TextStyle(fontSize: 46)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${winner.name} wins!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text('All four tokens made it home. Great game!'),
                const SizedBox(height: 28),
                SizedBox(
                  width: 240,
                  child: FilledButton.icon(
                    onPressed: onReplay,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Play again'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 240,
                  child: OutlinedButton.icon(
                    onPressed: onHome,
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
