import 'package:flutter/material.dart';

import '../core/local_store.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key, required this.store});
  final LocalStore store;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('STATISTICS')),
        body: FutureBuilder(
          future: Future.wait([
            store.loadHistory(),
            store.loadWins(),
            store.loadAchievements()
          ]),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('Could not load stats: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final history = snapshot.data![0] as List;
            final wins = snapshot.data![1] as Map<String, int>;
            final achievements = snapshot.data![2] as Set<String>;
            final total = history.length;
            final best = wins.entries.isEmpty
                ? null
                : wins.entries.reduce((a, b) => a.value >= b.value ? a : b);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _StatCard(
                            label: 'Matches',
                            value: '$total',
                            icon: Icons.sports_esports)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _StatCard(
                            label: 'Top player',
                            value: best?.key ?? '—',
                            icon: Icons.emoji_events)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Achievements',
                    style: Theme.of(context).textTheme.titleLarge),
                if (achievements.isEmpty)
                  const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: Text('Play a match to earn your first milestone.'))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final id in achievements)
                        Chip(
                          avatar: const Icon(Icons.workspace_premium_rounded,
                              size: 18),
                          label: Text(switch (id) {
                            'first_match' => 'First match',
                            'ten_matches' => '10 matches',
                            'four_player_match' => 'Full table',
                            'ten_wins' => '10 wins',
                            _ => id,
                          }),
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                if (best != null)
                  _StatCard(
                      label: 'Most wins',
                      value: '${best.value}',
                      icon: Icons.military_tech),
                const SizedBox(height: 20),
                Text('Win counts',
                    style: Theme.of(context).textTheme.titleLarge),
                if (wins.isEmpty)
                  const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child:
                          Text('Finish a match to start tracking your wins.'))
                else
                  for (final entry
                      in (wins.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value))))
                    ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(entry.key),
                        trailing: Text('${entry.value} wins')),
                const SizedBox(height: 16),
                Text('Recent matches',
                    style: Theme.of(context).textTheme.titleLarge),
                if (history.isEmpty)
                  const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: Text('No matches played yet.'))
                else
                  for (final item in history.take(20))
                    ListTile(
                      leading: const Icon(Icons.flag_rounded),
                      title: Text('${item.winnerName} won'),
                      subtitle:
                          Text('${item.playedAt.toLocal()}'.split('.').first),
                      trailing: Text('${item.playerCount} players'),
                    ),
              ],
            );
          },
        ),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 14),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}
