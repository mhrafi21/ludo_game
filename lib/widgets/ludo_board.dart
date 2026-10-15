import 'package:flutter/material.dart';

import '../core/models.dart';

const _track = <Offset>[
  Offset(6, 13),
  Offset(6, 12),
  Offset(6, 11),
  Offset(6, 10),
  Offset(6, 9),
  Offset(5, 8),
  Offset(4, 8),
  Offset(3, 8),
  Offset(2, 8),
  Offset(1, 8),
  Offset(0, 8),
  Offset(0, 7),
  Offset(0, 6),
  Offset(1, 6),
  Offset(2, 6),
  Offset(3, 6),
  Offset(4, 6),
  Offset(5, 6),
  Offset(6, 5),
  Offset(6, 4),
  Offset(6, 3),
  Offset(6, 2),
  Offset(6, 1),
  Offset(6, 0),
  Offset(7, 0),
  Offset(8, 0),
  Offset(8, 1),
  Offset(8, 2),
  Offset(8, 3),
  Offset(8, 4),
  Offset(8, 5),
  Offset(9, 6),
  Offset(10, 6),
  Offset(11, 6),
  Offset(12, 6),
  Offset(13, 6),
  Offset(14, 6),
  Offset(14, 7),
  Offset(14, 8),
  Offset(13, 8),
  Offset(12, 8),
  Offset(11, 8),
  Offset(10, 8),
  Offset(9, 8),
  Offset(8, 9),
  Offset(8, 10),
  Offset(8, 11),
  Offset(8, 12),
  Offset(8, 13),
  Offset(8, 14),
  Offset(7, 14),
  Offset(6, 14),
];

class LudoBoard extends StatelessWidget {
  const LudoBoard({
    super.key,
    required this.state,
    required this.legalTokens,
    required this.onTokenTap,
    this.displayTokens,
  });

  final GameState state;
  final List<int> legalTokens;
  final ValueChanged<int> onTokenTap;
  final Map<Team, List<Token>>? displayTokens;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final point = details.localPosition;
                final candidates = legalTokens
                    .map((index) => (
                          index,
                          _displayCenter(displayTokens ?? state.tokens,
                              state.currentPlayer.team, index),
                        ))
                    .toList();
                candidates.sort((a, b) {
                  final da = (a.$2 -
                          Offset(point.dx / size * 15, point.dy / size * 15))
                      .distance;
                  final db = (b.$2 -
                          Offset(point.dx / size * 15, point.dy / size * 15))
                      .distance;
                  return da.compareTo(db);
                });
                if (candidates.isNotEmpty &&
                    (candidates.first.$2 -
                                Offset(
                                    point.dx / size * 15, point.dy / size * 15))
                            .distance <
                        1.2) {
                  onTokenTap(candidates.first.$1);
                }
              },
              child: CustomPaint(
                painter: _BoardPainter(
                  state: state,
                  legalTokens: legalTokens,
                  displayTokens: displayTokens ?? state.tokens,
                ),
                size: Size.square(size),
              ),
            );
          },
        ),
      );
}

Offset _displayCenter(Map<Team, List<Token>> tokens, Team team, int index) {
  final center = _tokenCenter(team, tokens[team]![index], index);
  final stack = <(Team, int)>[];
  for (final otherTeam in Team.values) {
    for (var otherIndex = 0;
        otherIndex < tokens[otherTeam]!.length;
        otherIndex++) {
      if (_tokenCenter(otherTeam, tokens[otherTeam]![otherIndex], otherIndex) ==
          center) {
        stack.add((otherTeam, otherIndex));
      }
    }
  }
  final position = stack.indexOf((team, index));
  if (stack.length < 2) return center;
  const offsets = [
    Offset(-.22, -.22),
    Offset(.22, -.22),
    Offset(-.22, .22),
    Offset(.22, .22),
  ];
  return center + offsets[position % offsets.length];
}

Offset _tokenCenter(Team team, Token token, int index) {
  if (token.isInBase) {
    final places = _baseCenters[team]!;
    return places[index];
  }
  if (token.isHome) {
    return const Offset(7.5, 7.5) +
        Offset((index % 2 == 0 ? -0.25 : 0.25), (index < 2 ? -0.25 : 0.25));
  }
  if (token.progress < 52) {
    return _track[(LudoRules.starts[team]! + token.progress - 1) % 52];
  }
  return _homeLanes[team]![token.progress - 52];
}

const _baseCenters = <Team, List<Offset>>{
  Team.red: [Offset(2, 11), Offset(4, 11), Offset(2, 13), Offset(4, 13)],
  Team.green: [Offset(2, 2), Offset(4, 2), Offset(2, 4), Offset(4, 4)],
  Team.yellow: [Offset(11, 2), Offset(13, 2), Offset(11, 4), Offset(13, 4)],
  Team.blue: [Offset(11, 11), Offset(13, 11), Offset(11, 13), Offset(13, 13)],
};

const _homeLanes = <Team, List<Offset>>{
  Team.red: [
    Offset(7, 13),
    Offset(7, 12),
    Offset(7, 11),
    Offset(7, 10),
    Offset(7, 9),
    Offset(7, 8)
  ],
  Team.green: [
    Offset(1, 7),
    Offset(2, 7),
    Offset(3, 7),
    Offset(4, 7),
    Offset(5, 7),
    Offset(6, 7)
  ],
  Team.yellow: [
    Offset(7, 1),
    Offset(7, 2),
    Offset(7, 3),
    Offset(7, 4),
    Offset(7, 5),
    Offset(7, 6)
  ],
  Team.blue: [
    Offset(13, 7),
    Offset(12, 7),
    Offset(11, 7),
    Offset(10, 7),
    Offset(9, 7),
    Offset(8, 7)
  ],
};

class _BoardPainter extends CustomPainter {
  _BoardPainter(
      {required this.state,
      required this.legalTokens,
      required this.displayTokens});
  final GameState state;
  final List<int> legalTokens;
  final Map<Team, List<Token>> displayTokens;

  Color _color(Team team) => Color(teamColors[team]!.value);

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 15;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)),
        Paint()..color = const Color(0xfffaf7ef));
    for (final team in Team.values) {
      final origin = switch (team) {
        Team.red => const Offset(0, 9),
        Team.green => const Offset(0, 0),
        Team.yellow => const Offset(9, 0),
        Team.blue => const Offset(9, 9),
      };
      final base =
          Rect.fromLTWH(origin.dx * unit, origin.dy * unit, 6 * unit, 6 * unit);
      canvas.drawRect(
          base, Paint()..color = _color(team).withValues(alpha: .88));
      final nest = base.deflate(unit * 0.85);
      canvas.drawRRect(
          RRect.fromRectAndRadius(nest, Radius.circular(unit * .45)),
          Paint()..color = Colors.white);
      for (final center in _baseCenters[team]!) {
        canvas.drawCircle(_px(center, unit), unit * .37,
            Paint()..color = _color(team).withValues(alpha: .24));
      }
    }
    final trackPaint = Paint()..color = const Color(0xfffdfcf8);
    final borderPaint = Paint()
      ..color = const Color(0xff59636d).withValues(alpha: .38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final point in _track) {
      final cell = Rect.fromLTWH(point.dx * unit, point.dy * unit, unit, unit);
      canvas.drawRect(cell, trackPaint);
      canvas.drawRect(cell, borderPaint);
    }
    for (final team in Team.values) {
      final color = _color(team);
      for (final point in _homeLanes[team]!) {
        final cell =
            Rect.fromLTWH(point.dx * unit, point.dy * unit, unit, unit);
        canvas.drawRect(cell, Paint()..color = color.withValues(alpha: .3));
        canvas.drawRect(cell, borderPaint);
      }
      final start = _track[LudoRules.starts[team]!];
      canvas.drawRect(
          Rect.fromLTWH(start.dx * unit, start.dy * unit, unit, unit),
          Paint()..color = color);
    }
    for (final safeCell in const [8, 21, 34, 47]) {
      final painter = TextPainter(
        text: const TextSpan(
            text: '★',
            style: TextStyle(color: Color(0xffd69e16), fontSize: 13)),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
          canvas,
          _px(_track[safeCell], unit) -
              Offset(painter.width / 2, painter.height / 2));
    }
    _drawCenter(canvas, unit);
    for (final team in Team.values) {
      for (var i = 0; i < state.tokens[team]!.length; i++) {
        final center = _displayCenter(displayTokens, team, i);
        final pixel = _px(center, unit);
        final selected =
            team == state.currentPlayer.team && legalTokens.contains(i);
        if (selected) {
          canvas.drawCircle(pixel, unit * .47,
              Paint()..color = Colors.black.withValues(alpha: .17));
          canvas.drawCircle(
              pixel,
              unit * .48,
              Paint()
                ..color = Colors.white
                ..style = PaintingStyle.stroke
                ..strokeWidth = unit * .07);
        }
        canvas.drawCircle(pixel, unit * .35, Paint()..color = _color(team));
        canvas.drawCircle(
            pixel,
            unit * .35,
            Paint()
              ..color = Colors.black.withValues(alpha: .45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = unit * .045);
        canvas.drawCircle(pixel, unit * .2,
            Paint()..color = Colors.white.withValues(alpha: .85));
        final text = TextPainter(
          text: TextSpan(
              text: '${i + 1}',
              style: TextStyle(
                  color: _color(team),
                  fontSize: unit * .25,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(canvas, pixel - Offset(text.width / 2, text.height / 2));
      }
    }
  }

  void _drawCenter(Canvas canvas, double unit) {
    final center = Offset(7.5 * unit, 7.5 * unit);
    final corners = <Team, (Offset, Offset)>{
      Team.red: (Offset(6 * unit, 9 * unit), Offset(9 * unit, 9 * unit)),
      Team.green: (Offset(6 * unit, 6 * unit), Offset(6 * unit, 9 * unit)),
      Team.yellow: (Offset(9 * unit, 6 * unit), Offset(6 * unit, 6 * unit)),
      Team.blue: (Offset(9 * unit, 9 * unit), Offset(9 * unit, 6 * unit)),
    };
    for (final team in Team.values) {
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(corners[team]!.$1.dx, corners[team]!.$1.dy)
        ..lineTo(corners[team]!.$2.dx, corners[team]!.$2.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = _color(team));
    }
    canvas.drawCircle(center, unit * .16, Paint()..color = Colors.white);
  }

  Offset _px(Offset point, double unit) =>
      Offset((point.dx + .5) * unit, (point.dy + .5) * unit);

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.legalTokens != legalTokens ||
      oldDelegate.displayTokens != displayTokens;
}
