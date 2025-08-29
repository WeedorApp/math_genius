import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:math_genius/main.dart' as app;
// Integration tests for Math Genius

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Math Genius Integration Tests', () {
    testWidgets('App launches and shows welcome screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app launches successfully
      expect(find.text('Math Genius'), findsOneWidget);
    });

    testWidgets('User can navigate through authentication flow', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to auth screen
      final authButton = find.text('Get Started');
      if (authButton.evaluate().isNotEmpty) {
        await tester.tap(authButton);
        await tester.pumpAndSettle();
      }

      // Verify auth screen elements
      expect(find.text('Login'), findsWidgets);
      expect(find.text('Register'), findsWidgets);
    });

    testWidgets('Game selection screen loads correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to game selection (assuming user is logged in)
      // This would need to be adapted based on your actual navigation flow
      final gameButton = find.text('Games');
      if (gameButton.evaluate().isNotEmpty) {
        await tester.tap(gameButton);
        await tester.pumpAndSettle();

        // Verify game options are available
        expect(find.text('Classic Quiz'), findsWidgets);
        expect(find.text('AI Native'), findsWidgets);
        expect(find.text('ChatGPT Enhanced'), findsWidgets);
      }
    });

    testWidgets('AI Tutor functionality works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test AI tutor interaction
      // This would need to be implemented based on your AI tutor UI
    });

    testWidgets('Settings screen loads and saves preferences', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to settings
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        // Test theme switching
        final themeToggle = find.text('Dark Mode');
        if (themeToggle.evaluate().isNotEmpty) {
          await tester.tap(themeToggle);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Performance monitoring works correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test that the app doesn't crash under normal usage
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Verify app is still responsive
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Monetization Integration Tests', () {
    testWidgets('Subscription screen displays correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to subscription screen
      // This would need to be implemented based on your subscription UI
    });

    testWidgets('Ad loading and display works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test ad loading (in test environment)
      // This would need to be mocked for testing
    });
  });

  group('Content Management Tests', () {
    testWidgets('Math problems load correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test that math problems are loaded and displayed
      // This would need to be implemented based on your content display
    });

    testWidgets('Offline content works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test offline functionality
      // This would need network mocking
    });
  });
}
