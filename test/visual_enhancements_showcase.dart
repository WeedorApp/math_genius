import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Game models
import 'package:math_genius/features/game/models/game_model.dart';

void main() {
  group('Visual Enhancements Showcase', () {
    testWidgets('Showcase Visual Elements for PreK-Kindergarten', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: _VisualShowcaseScreen()));

      // Verify the showcase loads
      expect(find.text('Visual Enhancements Showcase'), findsOneWidget);

      // Verify grade selection works
      await tester.tap(find.text('PreK'));
      await tester.pump();

      // Verify topic selection works
      await tester.tap(find.text('Addition'));
      await tester.pump();

      // Verify visual elements are displayed
      expect(find.textContaining('🍎'), findsWidgets);
      expect(find.textContaining('How many apples'), findsWidgets);
    });

    testWidgets('Showcase Grade-Specific Visual Elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: _GradeShowcaseScreen()));

      // Test each grade level
      for (final grade in GradeLevel.values) {
        await tester.tap(find.text('Show ${grade.name}'));
        await tester.pump();

        // Verify grade-appropriate visual elements
        switch (grade) {
          case GradeLevel.preK:
          case GradeLevel.kindergarten:
            expect(find.textContaining('🍎'), findsWidgets);
            break;
          case GradeLevel.grade1:
            expect(find.textContaining('🍬'), findsWidgets);
            break;
          case GradeLevel.grade2:
            expect(find.textContaining('🎈'), findsWidgets);
            break;
          default:
            // Higher grades have more abstract content
            expect(find.textContaining('What is'), findsWidgets);
        }
      }
    });

    testWidgets('Showcase Topic-Specific Visual Elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: _TopicShowcaseScreen()));

      // Test key topics with visual elements
      final topicsWithVisuals = [
        GameCategory.addition,
        GameCategory.subtraction,
        GameCategory.fractions,
        GameCategory.decimals,
        GameCategory.percentages,
        GameCategory.wordProblems,
      ];

      for (final topic in topicsWithVisuals) {
        await tester.tap(find.text('Show ${topic.name}'));
        await tester.pump();

        // Verify topic-specific visual elements
        switch (topic) {
          case GameCategory.addition:
            expect(find.textContaining('+'), findsWidgets);
            break;
          case GameCategory.subtraction:
            expect(find.textContaining('-'), findsWidgets);
            break;
          case GameCategory.fractions:
            expect(find.textContaining('/'), findsWidgets);
            break;
          case GameCategory.decimals:
            expect(find.textContaining('.'), findsWidgets);
            break;
          case GameCategory.percentages:
            expect(find.textContaining('%'), findsWidgets);
            break;
          case GameCategory.wordProblems:
            expect(find.textContaining('How many'), findsWidgets);
            break;
          default:
            expect(find.textContaining('?'), findsWidgets);
        }
      }
    });
  });
}

class _VisualShowcaseScreen extends StatefulWidget {
  @override
  _VisualShowcaseScreenState createState() => _VisualShowcaseScreenState();
}

class _VisualShowcaseScreenState extends State<_VisualShowcaseScreen> {
  GradeLevel selectedGrade = GradeLevel.preK;
  GameCategory selectedTopic = GameCategory.addition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Visual Enhancements Showcase')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visual Enhancements Showcase',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Grade Selection
            Text(
              'Select Grade Level:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
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
                      child: Text(grade.name),
                    ),
                  )
                  .toList(),
            ),

            SizedBox(height: 20),

            // Topic Selection
            Text(
              'Select Topic:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
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
                      child: Text(topic.name),
                    ),
                  )
                  .toList(),
            ),

            SizedBox(height: 20),

            // Sample Questions Display
            Text(
              'Sample Questions with Visual Elements:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _buildSampleQuestions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleQuestions() {
    final questions = _getSampleQuestions(selectedGrade, selectedTopic);

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(question['question']!, style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'Hint: ${question['hint']!}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Learning Objectives: ${question['objectives']!.join(', ')}',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  List<Map<String, dynamic>> _getSampleQuestions(
    GradeLevel grade,
    GameCategory topic,
  ) {
    switch (topic) {
      case GameCategory.addition:
        return _getAdditionQuestions(grade);
      case GameCategory.subtraction:
        return _getSubtractionQuestions(grade);
      case GameCategory.fractions:
        return _getFractionQuestions(grade);
      case GameCategory.decimals:
        return _getDecimalQuestions(grade);
      case GameCategory.percentages:
        return _getPercentageQuestions(grade);
      case GameCategory.wordProblems:
        return _getWordProblemQuestions(grade);
      default:
        return _getAdditionQuestions(grade);
    }
  }

  List<Map<String, dynamic>> _getAdditionQuestions(GradeLevel grade) {
    switch (grade) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return [
          {
            'question': '🍎 + 🍎 = ?\nHow many apples in total?',
            'hint': 'Count the apples together: 1, 2, 3...',
            'objectives': ['Basic counting', 'Number recognition'],
          },
        ];
      case GradeLevel.grade1:
        return [
          {
            'question': '🍬 + 🍬 = ?\nWhat is 5 + 3?',
            'hint': 'Use your fingers to count: 5 + 3',
            'objectives': ['Single-digit addition', 'Counting strategies'],
          },
        ];
      case GradeLevel.grade2:
        return [
          {
            'question': '🎈 + 🎈 = ?\nWhat is 15 + 12?',
            'hint': 'Break it down: 15 = 10 + 5',
            'objectives': ['Two-digit addition', 'Place value'],
          },
        ];
      default:
        return [
          {
            'question': 'What is 125 + 87?',
            'hint': 'Add the ones first, then the tens',
            'objectives': ['Multi-digit addition', 'Regrouping'],
          },
        ];
    }
  }

  List<Map<String, dynamic>> _getSubtractionQuestions(GradeLevel grade) {
    switch (grade) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return [
          {
            'question': '🍎 - 🍎 = ?\nHow many apples are left?',
            'hint': 'Count the apples: 5 - 2 = ?',
            'objectives': ['Basic counting', 'Number recognition'],
          },
        ];
      case GradeLevel.grade1:
        return [
          {
            'question': '🍪 - 🍪 = ?\nWhat is 8 - 3?',
            'hint': 'Use your fingers to count: 8 - 3',
            'objectives': ['Single-digit subtraction', 'Counting strategies'],
          },
        ];
      case GradeLevel.grade2:
        return [
          {
            'question': '🎈 - 🎈 = ?\nWhat is 25 - 12?',
            'hint': 'Break it down: 25 = 20 + 5',
            'objectives': ['Two-digit subtraction', 'Place value'],
          },
        ];
      default:
        return [
          {
            'question': 'What is 125 - 87?',
            'hint': 'Subtract the ones first, then the tens',
            'objectives': ['Multi-digit subtraction', 'Regrouping'],
          },
        ];
    }
  }

  List<Map<String, dynamic>> _getFractionQuestions(GradeLevel grade) {
    switch (grade) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return [
          {
            'question': '🍕 2/4\nHow many pizza slices?',
            'hint': 'Count the colored slices: 2 out of 4',
            'objectives': ['Basic fractions', 'Part-whole relationships'],
          },
        ];
      case GradeLevel.grade1:
        return [
          {
            'question': '🍰 3/6\nWhat is 3/6?',
            'hint': 'Count the parts of the whole cake',
            'objectives': ['Simple fractions', 'Visual representation'],
          },
        ];
      case GradeLevel.grade2:
        return [
          {
            'question': '🍪 5/8\nWhat is 5/8?',
            'hint': 'Divide the numerator by denominator',
            'objectives': ['Fraction concepts', 'Division relationship'],
          },
        ];
      default:
        return [
          {
            'question': 'What is 7/12?',
            'hint': 'Use division: 7 ÷ 12',
            'objectives': ['Fraction operations', 'Decimal conversion'],
          },
        ];
    }
  }

  List<Map<String, dynamic>> _getDecimalQuestions(GradeLevel grade) {
    switch (grade) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return [
          {
            'question': '💰 \$1.50 + \$2.30\nHow much money?',
            'hint': 'Add the cents together: 1.50 + 2.30',
            'objectives': ['Basic decimals', 'Money concepts'],
          },
        ];
      case GradeLevel.grade1:
        return [
          {
            'question': '🪙 2.5 + 1.8\nWhat is 2.5 + 1.8?',
            'hint': 'Add the tenths place first',
            'objectives': ['Decimal addition', 'Place value'],
          },
        ];
      case GradeLevel.grade2:
        return [
          {
            'question': '💵 15.7 + 12.3\nWhat is 15.7 + 12.3?',
            'hint': 'Line up the decimal points',
            'objectives': ['Decimal operations', 'Place value'],
          },
        ];
      default:
        return [
          {
            'question': 'What is 125.75 + 87.25?',
            'hint': 'Add hundredths, then tenths',
            'objectives': ['Hundredths', 'Decimal precision'],
          },
        ];
    }
  }

  List<Map<String, dynamic>> _getPercentageQuestions(GradeLevel grade) {
    switch (grade) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return [
          {
            'question': '🎨 3 out of 5\nHow many are colored?',
            'hint': 'Count the colored items: 3 colored out of 5 total',
            'objectives': ['Basic percentages', 'Part-whole relationships'],
          },
        ];
      case GradeLevel.grade1:
        return [
          {
            'question': '🌈 4 out of 8\nWhat percent is 4 out of 8?',
            'hint': 'Divide part by whole, then multiply by 100',
            'objectives': ['Simple percentages', 'Division'],
          },
        ];
      case GradeLevel.grade2:
        return [
          {
            'question': '🎯 12 out of 25\nWhat percent is 12 out of 25?',
            'hint': 'Use the formula: (part ÷ whole) × 100',
            'objectives': ['Percentage calculation', 'Fractions'],
          },
        ];
      default:
        return [
          {
            'question': 'What percent is 45 out of 60?',
            'hint': 'Convert to decimal first',
            'objectives': ['Decimal percentages', 'Conversion'],
          },
        ];
    }
  }

  List<Map<String, dynamic>> _getWordProblemQuestions(GradeLevel grade) {
    switch (grade) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return [
          {
            'question':
                '🍎 Tom has 3 apples\n🍎 He gets 2 more\n🍎 How many does he have now?',
            'hint': 'Add the numbers together: 3 + 2',
            'objectives': ['Basic word problems', 'Addition'],
          },
        ];
      case GradeLevel.grade1:
        return [
          {
            'question':
                '🍬 Sarah has 5 candies\n🍬 She eats 2\n🍬 How many are left?',
            'hint': 'Subtract the eaten candies: 5 - 2',
            'objectives': ['Simple word problems', 'Subtraction'],
          },
        ];
      case GradeLevel.grade2:
        return [
          {
            'question':
                '👥 A class has 24 students\n👥 They are in groups of 4\n👥 How many groups?',
            'hint': 'Divide total by group size: 24 ÷ 4',
            'objectives': ['Division word problems', 'Grouping'],
          },
        ];
      default:
        return [
          {
            'question':
                'A store has 50 items. Each costs \$3. What is the total cost?',
            'hint': 'Multiply items by price',
            'objectives': ['Multiplication word problems', 'Money'],
          },
        ];
    }
  }
}

class _GradeShowcaseScreen extends StatefulWidget {
  @override
  _GradeShowcaseScreenState createState() => _GradeShowcaseScreenState();
}

class _GradeShowcaseScreenState extends State<_GradeShowcaseScreen> {
  GradeLevel? selectedGrade;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Grade Level Showcase')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grade-Specific Visual Elements Showcase',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

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
                '${selectedGrade!.name} Visual Elements:',
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

class _TopicShowcaseScreen extends StatefulWidget {
  @override
  _TopicShowcaseScreenState createState() => _TopicShowcaseScreenState();
}

class _TopicShowcaseScreenState extends State<_TopicShowcaseScreen> {
  GameCategory? selectedTopic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Topic Showcase')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topic-Specific Visual Elements Showcase',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

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
                '${selectedTopic!.name} Visual Elements:',
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
