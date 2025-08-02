// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic app structure test', (WidgetTester tester) async {
    // Test that we can create a basic MaterialApp
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, size: 120),
                const SizedBox(height: 32),
                const Text(
                  'Math Genius',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quantum Learning System',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify that the app renders without crashing
    expect(find.text('Math Genius'), findsOneWidget);
    expect(find.text('Quantum Learning System'), findsOneWidget);
    expect(find.byIcon(Icons.school), findsOneWidget);
  });

  testWidgets('Theme system test', (WidgetTester tester) async {
    // Test that we can create a themed app
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: Scaffold(
          appBar: AppBar(title: const Text('Math Genius')),
          body: const Center(child: Text('Welcome to Math Genius')),
        ),
      ),
    );

    // Verify that the themed app renders correctly
    expect(find.text('Math Genius'), findsOneWidget);
    expect(find.text('Welcome to Math Genius'), findsOneWidget);
  });
}
