import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_habitual_life/app/app.dart';
import 'package:focus_habitual_life/core/local_db/database.dart';

void main() {
  setUp(() async {
    await AppDatabase.init();
  });

  testWidgets('FocusHabitualApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FocusHabitualApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Initial load: launcher / dashboard should be visible
    expect(find.text('FocusHabitual'), findsOneWidget);
    expect(find.text('Panel'), findsOneWidget);
    expect(find.text('Hábitos'), findsOneWidget);
    expect(find.text('Enfoque'), findsOneWidget);
  });
}
