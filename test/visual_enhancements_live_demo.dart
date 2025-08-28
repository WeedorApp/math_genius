import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Game models
import 'package:math_genius/features/game/models/game_model.dart';

void main() {
  group('Visual Enhancements Live Demo', () {
    testWidgets('Live Demo of All Grade Levels and Topics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: _LiveDemoScreen()));

      // Verify the demo loads
      expect(find.text('Visual Enhancements Live Demo'), findsOneWidget);

      // Test all grade levels
      for (final grade in GradeLevel.values) {
        await tester.tap(find.text('Show ${grade.name}'));
        await tester.pump();

        // Verify grade-appropriate content is displayed
        expect(find.textContaining('Sample Questions'), findsOneWidget);
      }
    });

    testWidgets('Live Demo of All Topics', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: _TopicLiveDemoScreen()));

      // Test key topics
      final topicsToTest = [
        GameCategory.addition,
        GameCategory.subtraction,
        GameCategory.fractions,
        GameCategory.decimals,
        GameCategory.percentages,
        GameCategory.wordProblems,
      ];

      for (final topic in topicsToTest) {
        await tester.tap(find.text('Show ${topic.name}'));
        await tester.pump();

        // Verify topic-specific content is displayed
        expect(find.textContaining('Visual Elements'), findsOneWidget);
      }
    });
  });
}

class _LiveDemoScreen extends StatefulWidget {
  @override
  _LiveDemoScreenState createState() => _LiveDemoScreenState();
}

class _LiveDemoScreenState extends State<_LiveDemoScreen> {
  GradeLevel? selectedGrade;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Visual Enhancements Live Demo')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visual Enhancements Live Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            Text(
              'Select a Grade Level to See Visual Elements:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Grade Selection Buttons
            Wrap(
              spacing: 8,
              children: GradeLevel.values
                  .map(
                    (grade) => ElevatedButton(
                      onPressed: () => setState(() => selectedGrade = grade),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedGrade == grade
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      child: Text('Show ${grade.name}'),
                    ),
                  )
                  .toList(),
            ),

            SizedBox(height: 20),

            // Display Grade-Specific Content
            if (selectedGrade != null) ...[
              Text(
                'Sample Questions for ${selectedGrade!.name}:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildGradeSpecificContent(selectedGrade!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGradeSpecificContent(GradeLevel grade) {
    final questions = _getGradeSpecificQuestions(grade);

    return Column(
      children: questions
          .map(
            (question) => Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Text(question, style: TextStyle(fontSize: 16)),
            ),
          )
          .toList(),
    );
  }

  List<String> _getGradeSpecificQuestions(GradeLevel grade) {
    switch (grade) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return [
          '🍎 + 🍎 = ?\nHow many apples in total?',
          '🍎 - 🍎 = ?\nHow many apples are left?',
          '🍕 2/4\nHow many pizza slices?',
          '💰 \$1.50 + \$2.30\nHow much money?',
          '🎨 3 out of 5\nHow many are colored?',
          '🍎 Tom has 3 apples\n🍎 He gets 2 more\n🍎 How many does he have now?',
          '🔢 1, 2, 3, ?, 5\nWhat comes next?',
          '📏 3 units\nHow long is the pencil?',
          '🔴 2, 3, 1\nHow many red balls?',
        ];
      case GradeLevel.grade1:
        return [
          '🍬 + 🍬 = ?\nWhat is 5 + 3?',
          '🍪 - 🍪 = ?\nWhat is 8 - 3?',
          '🍰 3/6\nWhat is 3/6?',
          '🪙 2.5 + 1.8\nWhat is 2.5 + 1.8?',
          '🌈 4 out of 8\nWhat percent is 4 out of 8?',
          '🍬 Sarah has 5 candies\n🍬 She eats 2\n🍬 How many are left?',
          '🔢 2, 4, 6, ?, 10\nWhat comes next?',
          '📏 5 cm + 3 cm\nWhat is 5 cm + 3 cm?',
          '📊 7, 9, 4\nWhat is the highest number?',
        ];
      case GradeLevel.grade2:
        return [
          '🎈 + 🎈 = ?\nWhat is 15 + 12?',
          '🎈 - 🎈 = ?\nWhat is 25 - 12?',
          '🍪 5/8\nWhat is 5/8?',
          '💵 15.7 + 12.3\nWhat is 15.7 + 12.3?',
          '🎯 12 out of 25\nWhat percent is 12 out of 25?',
          '👥 A class has 24 students\n👥 They are in groups of 4\n👥 How many groups?',
          '🔢 5, 10, 15, ?, 25\nWhat comes next?',
          '📏 15 m + 12 m\nWhat is 15 m + 12 m?',
          '📈 18, 22, 15\nWhat is the average?',
        ];
      default:
        return [
          'What is 125 + 87?',
          'What is 125 - 87?',
          'What is 12 × 8?',
          'What is 125 ÷ 5?',
          'What is 7/12?',
          'What is 125.75 + 87.25?',
          'What percent is 45 out of 60?',
          'What comes next? 3, 6, 12, ?, 48',
          'What is 125 cm × 87 cm?',
          'What is the range? 45, 67, 23, 89',
        ];
    }
  }
}

class _TopicLiveDemoScreen extends StatefulWidget {
  @override
  _TopicLiveDemoScreenState createState() => _TopicLiveDemoScreenState();
}

class _TopicLiveDemoScreenState extends State<_TopicLiveDemoScreen> {
  GameCategory? selectedTopic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Topic Live Demo')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topic-Specific Visual Elements Live Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            Text(
              'Select a Topic to See Visual Elements:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Topic Selection Buttons
            Wrap(
              spacing: 8,
              children: GameCategory.values
                  .map(
                    (topic) => ElevatedButton(
                      onPressed: () => setState(() => selectedTopic = topic),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedTopic == topic
                            ? Colors.green
                            : Colors.grey,
                      ),
                      child: Text('Show ${topic.name}'),
                    ),
                  )
                  .toList(),
            ),

            SizedBox(height: 20),

            // Display Topic-Specific Content
            if (selectedTopic != null) ...[
              Text(
                'Visual Elements for ${selectedTopic!.name}:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildTopicSpecificContent(selectedTopic!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSpecificContent(GameCategory topic) {
    final questions = _getTopicSpecificQuestions(topic);

    return Column(
      children: questions
          .map(
            (question) => Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Text(question, style: TextStyle(fontSize: 16)),
            ),
          )
          .toList(),
    );
  }

  List<String> _getTopicSpecificQuestions(GameCategory topic) {
    switch (topic) {
      case GameCategory.addition:
        return [
          '🍎 + 🍎 = ?\nHow many apples in total?',
          '🍬 + 🍬 = ?\nWhat is 5 + 3?',
          '🎈 + 🎈 = ?\nWhat is 15 + 12?',
          'What is 125 + 87?',
        ];
      case GameCategory.subtraction:
        return [
          '🍎 - 🍎 = ?\nHow many apples are left?',
          '🍪 - 🍪 = ?\nWhat is 8 - 3?',
          '🎈 - 🎈 = ?\nWhat is 25 - 12?',
          'What is 125 - 87?',
        ];
      case GameCategory.fractions:
        return [
          '🍕 2/4\nHow many pizza slices?',
          '🍰 3/6\nWhat is 3/6?',
          '🍪 5/8\nWhat is 5/8?',
          'What is 7/12?',
        ];
      case GameCategory.decimals:
        return [
          '💰 \$1.50 + \$2.30\nHow much money?',
          '🪙 2.5 + 1.8\nWhat is 2.5 + 1.8?',
          '💵 15.7 + 12.3\nWhat is 15.7 + 12.3?',
          'What is 125.75 + 87.25?',
        ];
      case GameCategory.percentages:
        return [
          '🎨 3 out of 5\nHow many are colored?',
          '🌈 4 out of 8\nWhat percent is 4 out of 8?',
          '🎯 12 out of 25\nWhat percent is 12 out of 25?',
          'What percent is 45 out of 60?',
        ];
      case GameCategory.wordProblems:
        return [
          '🍎 Tom has 3 apples\n🍎 He gets 2 more\n🍎 How many does he have now?',
          '🍬 Sarah has 5 candies\n🍬 She eats 2\n🍬 How many are left?',
          '👥 A class has 24 students\n👥 They are in groups of 4\n👥 How many groups?',
          'A store has 50 items. Each costs \$3. What is the total cost?',
        ];
      default:
        return [
          'Sample question for ${topic.name}',
          'Another sample question for ${topic.name}',
        ];
    }
  }
}
