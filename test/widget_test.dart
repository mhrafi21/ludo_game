import 'package:flutter_test/flutter_test.dart';
import 'package:offline_ludo/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('launches to an offline playable home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LudoApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('LUDO'), findsOneWidget);
    expect(find.text('Play vs AI'), findsOneWidget);
    expect(find.text('Local multiplayer'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
  });
}
