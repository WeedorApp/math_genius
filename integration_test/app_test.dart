import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:math_genius/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Math Genius App Integration Tests', () {
    testWidgets('App launches and shows home screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app launches successfully
      expect(find.text('Math Genius'), findsOneWidget);
    });

    testWidgets('Navigation between screens works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test navigation to different screens
      // This will be expanded as the UI stabilizes
    });

    testWidgets('Game functionality works end-to-end', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test complete game flow
      // This will be expanded with specific game tests
    });

    testWidgets('User authentication flow works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test authentication flow
      // This will be expanded with auth tests
    });
  });
}
