import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Game models
import 'package:math_genius/features/game/models/game_model.dart';

void main() {
  group('Visual Enhancements Demo', () {
    testWidgets('Demo Visual Elements for Different Grades', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: _VisualEnhancementDemo()));

      // Test that the demo screen loads
      expect(find.text('Visual Enhancement Demo'), findsOneWidget);

      // Test grade selection
      await tester.tap(find.text('PreK'));
      await tester.pump();

      // Test topic selection
      await tester.tap(find.text('Addition'));
      await tester.pump();

      // Verify visual elements are present
      expect(find.textContaining('🍎'), findsOneWidget);
    });

    testWidgets('Demo All Grade Levels', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: _GradeLevelDemo()));

      // Test all grade levels
      for (final grade in GradeLevel.values) {
        await tester.tap(find.text('Show ${grade.name}'));
        await tester.pump();

        // Verify grade-appropriate content
        if (grade == GradeLevel.preK || grade == GradeLevel.kindergarten) {
          expect(find.textContaining('🍎'), findsOneWidget);
        } else if (grade == GradeLevel.grade1) {
          expect(find.textContaining('🍬'), findsOneWidget);
        } else if (grade == GradeLevel.grade2) {
          expect(find.textContaining('🎈'), findsOneWidget);
        }
      }
    });

    testWidgets('Demo All Topics', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: _TopicDemo()));

      // Test all topics
      for (final topic in GameCategory.values) {
        await tester.tap(find.text('Show ${topic.name}'));
        await tester.pump();

        // Verify topic-specific content
        switch (topic) {
          case GameCategory.addition:
            expect(find.textContaining('+'), findsOneWidget);
            break;
          case GameCategory.subtraction:
            expect(find.textContaining('-'), findsOneWidget);
            break;
          case GameCategory.multiplication:
            expect(find.textContaining('×'), findsOneWidget);
            break;
          case GameCategory.division:
            expect(find.textContaining('÷'), findsOneWidget);
            break;
          case GameCategory.fractions:
            expect(find.textContaining('/'), findsOneWidget);
            break;
          case GameCategory.decimals:
            expect(find.textContaining('.'), findsOneWidget);
            break;
          case GameCategory.percentages:
            expect(find.textContaining('%'), findsOneWidget);
            break;
          default:
            expect(find.textContaining('?'), findsOneWidget);
        }
      }
    });
  });
}

class _VisualEnhancementDemo extends StatefulWidget {
  @override
  _VisualEnhancementDemoState createState() => _VisualEnhancementDemoState();
}

class _VisualEnhancementDemoState extends State<_VisualEnhancementDemo> {
  GradeLevel selectedGrade = GradeLevel.preK;
  GameCategory selectedTopic = GameCategory.addition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Visual Enhancement Demo')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visual Enhancement Demo',
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
              'Sample Questions:',
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
      case GameCategory.multiplication:
        return _getMultiplicationQuestions(grade);
      case GameCategory.division:
        return _getDivisionQuestions(grade);
      case GameCategory.fractions:
        return _getFractionQuestions(grade);
      case GameCategory.decimals:
        return _getDecimalQuestions(grade);
      case GameCategory.percentages:
        return _getPercentageQuestions(grade);
      case GameCategory.wordProblems:
        return _getWordProblemQuestions(grade);
      case GameCategory.patterns:
        return _getPatternQuestions(grade);
      case GameCategory.measurement:
        return _getMeasurementQuestions(grade);
      case GameCategory.dataAnalysis:
        return _getDataAnalysisQuestions(grade);
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
          {
            'question': '🍎 + 🍎 = ?\nWhat is 3 + 2?',
            'hint': 'Count the apples: 3 + 2 = 5',
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
          {
            'question': '🍬 + 🍬 = ?\nWhat is 7 + 4?',
            'hint': 'Use your fingers to count: 7 + 4',
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
          {
            'question': '🎈 + 🎈 = ?\nWhat is 23 + 18?',
            'hint': 'Break it down: 23 = 20 + 3',
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

  List<Map<String, dynamic>> _getMultiplicationQuestions(GradeLevel grade) {
    switch (grade) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return [
          {
            'question': '🍎 × 🍎 = ?\nHow many apples in groups?',
            'hint': 'Count the apples in groups: 3 groups of 2',
            'objectives': ['Basic counting', 'Number recognition'],
          },
        ];
      case GradeLevel.grade1:
        return [
          {
            'question': '🍬 × 🍬 = ?\nWhat is 4 × 3?',
            'hint': 'Use your fingers to count: 4 groups of 3',
            'objectives': [
              'Single-digit multiplication',
              'Counting strategies',
            ],
          },
        ];
      case GradeLevel.grade2:
        return [
          {
            'question': '🎈 × 🎈 = ?\nWhat is 6 × 5?',
            'hint': 'Break it down: 6 = 5 + 1',
            'objectives': ['Two-digit multiplication', 'Place value'],
          },
        ];
      default:
        return [
          {
            'question': 'What is 12 × 8?',
            'hint': 'Add the ones first, then the tens',
            'objectives': ['Multi-digit multiplication', 'Regrouping'],
          },
        ];
    }
  }

  List<Map<String, dynamic>> _getDivisionQuestions(GradeLevel grade) {
    switch (grade) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return [
          {
            'question': '🍎 ÷ 🍎 = ?\nHow many apples in each group?',
            'hint': 'Share the apples equally: 6 apples ÷ 2 groups',
            'objectives': ['Basic counting', 'Number recognition'],
          },
        ];
      case GradeLevel.grade1:
        return [
          {
            'question': '🍪 ÷ 🍪 = ?\nWhat is 8 ÷ 2?',
            'hint': 'Use your fingers to count: 8 ÷ 2',
            'objectives': ['Single-digit division', 'Counting strategies'],
          },
        ];
      case GradeLevel.grade2:
        return [
          {
            'question': '🎈 ÷ 🎈 = ?\nWhat is 15 ÷ 3?',
            'hint': 'Break it down: 15 = 10 + 5',
            'objectives': ['Two-digit division', 'Place value'],
          },
        ];
      default:
        return [
          {
            'question': 'What is 125 ÷ 5?',
            'hint': 'Subtract the ones first, then the tens',
            'objectives': ['Multi-digit division', 'Regrouping'],
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

  List<Map<String, dynamic>> _getPatternQuestions(GradeLevel grade) {
    switch (grade) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return [
          {
            'question': '🔢 1, 2, 3, ?, 5\nWhat comes next?',
            'hint': 'Count the numbers: 1, 2, 3, 4, 5',
            'objectives': ['Number patterns', 'Sequencing'],
          },
        ];
      case GradeLevel.grade1:
        return [
          {
            'question': '🔢 2, 4, 6, ?, 10\nWhat comes next?',
            'hint': 'Add 2 each time: 2, 4, 6, 8, 10',
            'objectives': ['Skip counting', 'Addition patterns'],
          },
        ];
      case GradeLevel.grade2:
        return [
          {
            'question': '🔢 5, 10, 15, ?, 25\nWhat comes next?',
            'hint': 'Add 5 each time: 5, 10, 15, 20, 25',
            'objectives': ['Multiples', 'Multiplication patterns'],
          },
        ];
      default:
        return [
          {
            'question': 'What comes next? 3, 6, 12, ?, 48',
            'hint': 'Multiply by 2 each time',
            'objectives': ['Geometric sequences', 'Multiplication'],
          },
        ];
    }
  }

  List<Map<String, dynamic>> _getMeasurementQuestions(GradeLevel grade) {
    switch (grade) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return [
          {
            'question': '📏 3 units\nHow long is the pencil?',
            'hint': 'Count the units: 3 units long',
            'objectives': ['Basic measurement', 'Length'],
          },
        ];
      case GradeLevel.grade1:
        return [
          {
            'question': '📏 5 cm + 3 cm\nWhat is 5 cm + 3 cm?',
            'hint': 'Add the centimeters: 5 + 3',
            'objectives': ['Centimeter addition', 'Length measurement'],
          },
        ];
      case GradeLevel.grade2:
        return [
          {
            'question': '📏 15 m + 12 m\nWhat is 15 m + 12 m?',
            'hint': 'Add the meters: 15 + 12',
            'objectives': ['Meter measurement', 'Length addition'],
          },
        ];
      default:
        return [
          {
            'question': 'What is 125 cm × 87 cm?',
            'hint': 'Multiply length by width',
            'objectives': ['Area calculation', 'Multiplication'],
          },
        ];
    }
  }

  List<Map<String, dynamic>> _getDataAnalysisQuestions(GradeLevel grade) {
    switch (grade) {
      case GradeLevel.preK:
      case GradeLevel.kindergarten:
        return [
          {
            'question': '🔴 2, 3, 1\nHow many red balls?',
            'hint': 'Count the red ones: 2 + 3 + 1',
            'objectives': ['Basic data', 'Counting'],
          },
        ];
      case GradeLevel.grade1:
        return [
          {
            'question': '📊 7, 9, 4\nWhat is the highest number?',
            'hint': 'Find the biggest number: 7, 9, or 4?',
            'objectives': ['Data comparison', 'Number ordering'],
          },
        ];
      case GradeLevel.grade2:
        return [
          {
            'question': '📈 18, 22, 15\nWhat is the average?',
            'hint': 'Add all numbers, then divide by 3: (18 + 22 + 15) ÷ 3',
            'objectives': ['Averages', 'Division'],
          },
        ];
      default:
        return [
          {
            'question': 'What is the range? 45, 67, 23, 89',
            'hint': 'Subtract smallest from largest',
            'objectives': ['Range calculation', 'Data spread'],
          },
        ];
    }
  }
}

class _GradeLevelDemo extends StatefulWidget {
  @override
  _GradeLevelDemoState createState() => _GradeLevelDemoState();
}

class _GradeLevelDemoState extends State<_GradeLevelDemo> {
  GradeLevel? selectedGrade;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Grade Level Demo')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grade Level Visual Elements Demo',
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
                '${selectedGrade!.name} Sample Questions:',
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

class _TopicDemo extends StatefulWidget {
  @override
  _TopicDemoState createState() => _TopicDemoState();
}

class _TopicDemoState extends State<_TopicDemo> {
  GameCategory? selectedTopic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Topic Demo')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topic-Specific Visual Elements Demo',
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
                '${selectedTopic!.name} Sample Questions:',
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
      case GameCategory.multiplication:
        return [
          '🍎 × 🍎 = ?\nHow many apples in groups?',
          '🍬 × 🍬 = ?\nWhat is 4 × 3?',
          '🎈 × 🎈 = ?\nWhat is 6 × 5?',
          'What is 12 × 8?',
        ];
      case GameCategory.division:
        return [
          '🍎 ÷ 🍎 = ?\nHow many apples in each group?',
          '🍪 ÷ 🍪 = ?\nWhat is 8 ÷ 2?',
          '🎈 ÷ 🎈 = ?\nWhat is 15 ÷ 3?',
          'What is 125 ÷ 5?',
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
      case GameCategory.patterns:
        return [
          '🔢 1, 2, 3, ?, 5\nWhat comes next?',
          '🔢 2, 4, 6, ?, 10\nWhat comes next?',
          '🔢 5, 10, 15, ?, 25\nWhat comes next?',
          'What comes next? 3, 6, 12, ?, 48',
        ];
      case GameCategory.measurement:
        return [
          '📏 3 units\nHow long is the pencil?',
          '📏 5 cm + 3 cm\nWhat is 5 cm + 3 cm?',
          '📏 15 m + 12 m\nWhat is 15 m + 12 m?',
          'What is 125 cm × 87 cm?',
        ];
      case GameCategory.dataAnalysis:
        return [
          '🔴 2, 3, 1\nHow many red balls?',
          '📊 7, 9, 4\nWhat is the highest number?',
          '📈 18, 22, 15\nWhat is the average?',
          'What is the range? 45, 67, 23, 89',
        ];
      default:
        return [
          'Sample question for ${topic.name}',
          'Another sample question for ${topic.name}',
        ];
    }
  }
}
