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
                      final compact = constraints.maxHeight < 660;
                      return Column(
                        children: [
                          _PlayerStrip(state: state),
                          if (controller.lastMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(controller.lastMessage!,
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                            ),
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxWidth: compact ? 520 : 600,
                                    maxHeight: constraints.maxHeight),
                                child: Padding(
                                  padding: EdgeInsets.all(compact ? 8 : 14),
                                  child: LudoBoard(
                                    state: state,
                                    legalTokens: controller.legalTokens,
                                    displayTokens: controller.visualTokens,
                                    onTokenTap: controller.moveToken,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _DicePanel(controller: controller, compact: compact),
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

class _PlayerStrip extends StatelessWidget {
  const _PlayerStrip({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            for (var i = 0; i < state.players.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Color(teamColors[state.players[i].team]!.value)
                      .withValues(
                          alpha: i == state.currentPlayerIndex ? .2 : .08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Color(teamColors[state.players[i].team]!.value),
                    width: i == state.currentPlayerIndex ? 2 : 1,
                  ),
                ),
                child:
                    Text('${state.players[i].avatar} ${state.players[i].name}'),
              ),
          ],
        ),
      );
}

class _DicePanel extends StatelessWidget {
  const _DicePanel({required this.controller, required this.compact});
  final GameController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = controller.state!;
    final teamColor = Color(teamColors[state.currentPlayer.team]!.value);
    final hasRolled = controller.rolled != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, compact ? 12 : 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${state.currentPlayer.name}'s turn",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(state.currentPlayer.isAi
                    ? 'Thinking…'
                    : (hasRolled
                        ? 'Choose a highlighted token'
                        : 'Roll the dice')),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: hasRolled ? 'Dice shows ${controller.rolled}' : 'Roll dice',
            child: InkWell(
              onTap: controller.rollDice,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: compact ? 54 : 62,
                height: compact ? 54 : 62,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: teamColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: teamColor.withValues(alpha: .18),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, animation) => RotationTransition(
                      turns:
                          Tween<double>(begin: -.12, end: 0).animate(animation),
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: Text(
                      hasRolled ? '${controller.rolled}' : '🎲',
                      key: ValueKey(controller.rolled),
                      style: TextStyle(
                          fontSize: hasRolled ? 30 : 27,
                          fontWeight: FontWeight.bold,
                          color: teamColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
          FilledButton(
            onPressed: controller.busy ||
                    state.currentPlayer.isAi ||
                    state.isPaused ||
                    hasRolled
                ? null
                : controller.rollDice,
            style: FilledButton.styleFrom(
                backgroundColor: teamColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
            child: const Text('ROLL'),
          ),
        ],
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
