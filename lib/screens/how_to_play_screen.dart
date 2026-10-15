import 'package:flutter/material.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _sections = <(String, String, IconData)>[
    (
      'Start your journey',
      'Roll a 6 to bring a token out of your base. Your first token lands on your team’s starting square.',
      Icons.rocket_launch_rounded
    ),
    (
      'Move around the track',
      'Tap a highlighted token after rolling. Tokens travel clockwise; roll the exact number needed to reach home.',
      Icons.route_rounded
    ),
    (
      'Safe squares',
      'Star-marked and team starting squares are safe. Tokens on safe squares cannot be captured.',
      Icons.shield_rounded
    ),
    (
      'Capture and extra turns',
      'Land on an unprotected opponent to send their token home. Rolling a 6, capturing, or reaching home earns another turn.',
      Icons.flash_on_rounded
    ),
    (
      'Three sixes',
      'When enabled in settings, rolling three sixes in succession forfeits the third roll and ends your turn.',
      Icons.casino_rounded
    ),
    (
      'Win the match',
      'Be the first player to guide all four tokens into the center home to win.',
      Icons.emoji_events_rounded
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('HOW TO PLAY')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Ludo made simple',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'The classic race home. Play offline with friends or take on the computer.'),
            const SizedBox(height: 18),
            for (final (title, body, icon) in _sections)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(child: Icon(icon)),
                  title: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(body)),
                ),
              ),
          ],
        ),
      );
}
