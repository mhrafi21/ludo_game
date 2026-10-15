import 'dart:math';

class DiceService {
  DiceService({Random? random}) : _random = random ?? Random();

  final Random _random;

  int roll() => _random.nextInt(6) + 1;
}
