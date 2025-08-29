import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import '../models/class_model.dart' as class_models;
import '../models/user_model.dart' as user_models;
import '../barrel.dart' as user_management;
import '../../../core/barrel.dart';
import '../../game/models/game_model.dart' as game;

class ClassSelectionScreen extends ConsumerStatefulWidget {
  final user_models.UserRole userRole;
  final String email;
  final String password;
  final String displayName;

  const ClassSelectionScreen({
    super.key,
    required this.userRole,
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  ConsumerState<ClassSelectionScreen> createState() =>
      _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends ConsumerState<ClassSelectionScreen> {
  class_models.ClassLevel? _selectedClass;
  List<class_models.MathClass> _availableClasses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableClasses();
  }

  Future<void> _loadAvailableClasses() async {
    try {
      // Create all available classes from PreK to 12th grade
      _availableClasses = [
        class_models.MathClass(
          id: 'prek_math',
          level: class_models.ClassLevel.preK,
          name: 'Pre-K Mathematics',
          description: 'Introduction to basic counting and number recognition',
          displayName: 'Pre-K',
          minAge: 3,
          maxAge: 5,
          availableCategories: [
            class_models.ClassContentCategory.arithmetic,
            class_models.ClassContentCategory.mentalMath,
          ],
          learningObjectives: {
            class_models.ClassContentCategory.arithmetic: [
              'Count to 10',
              'Number recognition',
              'Basic addition',
            ],
            class_models.ClassContentCategory.mentalMath: [
              'Quick counting',
              'Number patterns',
            ],
          },
          questionCounts: {
            class_models.ClassContentCategory.arithmetic: 10,
            class_models.ClassContentCategory.mentalMath: 8,
          },
          difficultyLevels: {
            class_models.ClassContentCategory.arithmetic:
                game.GameDifficulty.easy,
            class_models.ClassContentCategory.mentalMath:
                game.GameDifficulty.easy,
          },
        ),
        class_models.MathClass(
          id: 'kindergarten_math',
          level: class_models.ClassLevel.kindergarten,
          name: 'Kindergarten Mathematics',
          description: 'Basic arithmetic and number sense development',
          displayName: 'Kindergarten',
          minAge: 5,
          maxAge: 6,
          availableCategories: [
            class_models.ClassContentCategory.arithmetic,
            class_models.ClassContentCategory.wordProblems,
          ],
          learningObjectives: {
            class_models.ClassContentCategory.arithmetic: [
              'Addition and subtraction',
              'Number bonds',
              'Place value',
            ],
            class_models.ClassContentCategory.wordProblems: [
              'Simple word problems',
              'Real-world applications',
            ],
          },
          questionCounts: {
            class_models.ClassContentCategory.arithmetic: 15,
            class_models.ClassContentCategory.wordProblems: 10,
          },
          difficultyLevels: {
            class_models.ClassContentCategory.arithmetic:
                game.GameDifficulty.easy,
            class_models.ClassContentCategory.wordProblems:
                game.GameDifficulty.easy,
          },
        ),
        class_models.MathClass(
          id: 'grade1_math',
          level: class_models.ClassLevel.grade1,
          name: 'Grade 1 Mathematics',
          description: 'First grade math concepts and problem solving',
          displayName: 'Grade 1',
          minAge: 6,
          maxAge: 7,
          availableCategories: [
            class_models.ClassContentCategory.arithmetic,
            class_models.ClassContentCategory.geometry,
            class_models.ClassContentCategory.wordProblems,
          ],
          learningObjectives: {
            class_models.ClassContentCategory.arithmetic: [
              'Two-digit addition',
              'Subtraction strategies',
              'Number patterns',
            ],
            class_models.ClassContentCategory.geometry: [
              'Basic shapes',
              'Measurement',
              'Spatial awareness',
            ],
            class_models.ClassContentCategory.wordProblems: [
              'Multi-step problems',
              'Critical thinking',
            ],
          },
          questionCounts: {
            class_models.ClassContentCategory.arithmetic: 20,
            class_models.ClassContentCategory.geometry: 15,
            class_models.ClassContentCategory.wordProblems: 12,
          },
          difficultyLevels: {
            class_models.ClassContentCategory.arithmetic:
                game.GameDifficulty.normal,
            class_models.ClassContentCategory.geometry:
                game.GameDifficulty.easy,
            class_models.ClassContentCategory.wordProblems:
                game.GameDifficulty.normal,
          },
        ),
        class_models.MathClass(
          id: 'grade2_math',
          level: class_models.ClassLevel.grade2,
          name: 'Grade 2 Mathematics',
          description: 'Second grade math with advanced concepts',
          displayName: 'Grade 2',
          minAge: 7,
          maxAge: 8,
          availableCategories: [
            class_models.ClassContentCategory.arithmetic,
            class_models.ClassContentCategory.geometry,
            class_models.ClassContentCategory.wordProblems,
          ],
          learningObjectives: {
            class_models.ClassContentCategory.arithmetic: [
              'Three-digit addition',
              'Subtraction with regrouping',
              'Multiplication basics',
            ],
            class_models.ClassContentCategory.geometry: [
              '2D and 3D shapes',
              'Perimeter and area',
              'Symmetry',
            ],
            class_models.ClassContentCategory.wordProblems: [
              'Complex word problems',
              'Multi-step reasoning',
            ],
          },
          questionCounts: {
            class_models.ClassContentCategory.arithmetic: 25,
            class_models.ClassContentCategory.geometry: 18,
            class_models.ClassContentCategory.wordProblems: 15,
          },
          difficultyLevels: {
            class_models.ClassContentCategory.arithmetic:
                game.GameDifficulty.normal,
            class_models.ClassContentCategory.geometry:
                game.GameDifficulty.normal,
            class_models.ClassContentCategory.wordProblems:
                game.GameDifficulty.normal,
          },
        ),
        class_models.MathClass(
          id: 'grade3_math',
          level: class_models.ClassLevel.grade3,
          name: 'Grade 3 Mathematics',
          description: 'Third grade math with multiplication and division',
          displayName: 'Grade 3',
          minAge: 8,
          maxAge: 9,
          availableCategories: [
            class_models.ClassContentCategory.arithmetic,
            class_models.ClassContentCategory.geometry,
            class_models.ClassContentCategory.wordProblems,
          ],
          learningObjectives: {
            class_models.ClassContentCategory.arithmetic: [
              'Multiplication tables',
              'Division concepts',
              'Fractions basics',
            ],
            class_models.ClassContentCategory.geometry: [
              'Area and perimeter',
              'Angles and lines',
              'Geometric patterns',
            ],
            class_models.ClassContentCategory.wordProblems: [
              'Complex problem solving',
              'Mathematical reasoning',
            ],
          },
          questionCounts: {
            class_models.ClassContentCategory.arithmetic: 30,
            class_models.ClassContentCategory.geometry: 20,
            class_models.ClassContentCategory.wordProblems: 18,
          },
          difficultyLevels: {
            class_models.ClassContentCategory.arithmetic:
                game.GameDifficulty.normal,
            class_models.ClassContentCategory.geometry:
                game.GameDifficulty.normal,
            class_models.ClassContentCategory.wordProblems:
                game.GameDifficulty.normal,
          },
        ),
        class_models.MathClass(
          id: 'grade4_math',
          level: class_models.ClassLevel.grade4,
          name: 'Grade 4 Mathematics',
          description: 'Fourth grade math with advanced operations',
          displayName: 'Grade 4',
          minAge: 9,
          maxAge: 10,
          availableCategories: [
            class_models.ClassContentCategory.arithmetic,
            class_models.ClassContentCategory.geometry,
            class_models.ClassContentCategory.wordProblems,
          ],
          learningObjectives: {
            class_models.ClassContentCategory.arithmetic: [
              'Multi-digit multiplication',
              'Long division',
              'Fractions and decimals',
            ],
            class_models.ClassContentCategory.geometry: [
              'Angles and measurements',
              'Area and volume',
              'Geometric transformations',
            ],
            class_models.ClassContentCategory.wordProblems: [
              'Advanced problem solving',
              'Mathematical modeling',
            ],
          },
          questionCounts: {
            class_models.ClassContentCategory.arithmetic: 35,
            class_models.ClassContentCategory.geometry: 25,
            class_models.ClassContentCategory.wordProblems: 20,
          },
          difficultyLevels: {
            class_models.ClassContentCategory.arithmetic:
                game.GameDifficulty.normal,
            class_models.ClassContentCategory.geometry:
                game.GameDifficulty.normal,
            class_models.ClassContentCategory.wordProblems:
                game.GameDifficulty.normal,
          },
        ),
        class_models.MathClass(
          id: 'grade5_math',
          level: class_models.ClassLevel.grade5,
          name: 'Grade 5 Mathematics',
          description: 'Fifth grade math with complex operations',
          displayName: 'Grade 5',
          minAge: 10,
          maxAge: 11,
          availableCategories: [
            class_models.ClassContentCategory.arithmetic,
            class_models.ClassContentCategory.geometry,
            class_models.ClassContentCategory.wordProblems,
          ],
          learningObjectives: {
            class_models.ClassContentCategory.arithmetic: [
              'Advanced fractions',
              'Decimals and percentages',
              'Order of operations',
            ],
            class_models.ClassContentCategory.geometry: [
              'Coordinate geometry',
              'Volume and surface area',
              'Geometric proofs',
            ],
            class_models.ClassContentCategory.wordProblems: [
              'Complex mathematical reasoning',
              'Real-world applications',
            ],
          },
          questionCounts: {
            class_models.ClassContentCategory.arithmetic: 40,
            class_models.ClassContentCategory.geometry: 30,
            class_models.ClassContentCategory.wordProblems: 25,
          },
          difficultyLevels: {
            class_models.ClassContentCategory.arithmetic:
                game.GameDifficulty.normal,
            class_models.ClassContentCategory.geometry:
                game.GameDifficulty.normal,
            class_models.ClassContentCategory.wordProblems:
                game.GameDifficulty.normal,
          },
        ),
        class_models.MathClass(
          id: 'grade6_math',
          level: class_models.ClassLevel.grade6,
          name: 'Grade 6 Mathematics',
          description: 'Sixth grade math with pre-algebra concepts',
          displayName: 'Grade 6',
          minAge: 11,
          maxAge: 12,
          availableCategories: [
            class_models.ClassContentCategory.arithmetic,
            class_models.ClassContentCategory.algebra,
            class_models.ClassContentCategory.geometry,
          ],
          learningObjectives: {
            class_models.ClassContentCategory.arithmetic: [
              'Ratios and proportions',
              'Percentages and rates',
              'Number theory',
            ],
            class_models.ClassContentCategory.algebra: [
              'Variables and expressions',
              'Simple equations',
              'Patterns and sequences',
            ],
            class_models.ClassContentCategory.geometry: [
              'Area and perimeter',
              'Volume calculations',
              'Geometric relationships',
            ],
          },
          questionCounts: {
            class_models.ClassContentCategory.arithmetic: 45,
            class_models.ClassContentCategory.algebra: 35,
            class_models.ClassContentCategory.geometry: 30,
          },
          difficultyLevels: {
            class_models.ClassContentCategory.arithmetic:
                game.GameDifficulty.normal,
            class_models.ClassContentCategory.algebra:
                game.GameDifficulty.normal,
            class_models.ClassContentCategory.geometry:
                game.GameDifficulty.normal,
          },
        ),
        class_models.MathClass(
          id: 'grade7_math',
          level: class_models.ClassLevel.grade7,
          name: 'Grade 7 Mathematics',
          description: 'Seventh grade math with algebra foundations',
          displayName: 'Grade 7',
          minAge: 12,
          maxAge: 13,
          availableCategories: [
            class_models.ClassContentCategory.algebra,
            class_models.ClassContentCategory.geometry,
            class_models.ClassContentCategory.statistics,
          ],
          learningObjectives: {
            class_models.ClassContentCategory.algebra: [
              'Linear equations',
              'Inequalities',
              'Graphing functions',
            ],
            class_models.ClassContentCategory.geometry: [
              'Angles and triangles',
              'Pythagorean theorem',
              'Geometric transformations',
            ],
            class_models.ClassContentCategory.statistics: [
              'Data analysis',
              'Probability basics',
              'Statistical measures',
            ],
          },
          questionCounts: {
            class_models.ClassContentCategory.algebra: 40,
            class_models.ClassContentCategory.geometry: 35,
            class_models.ClassContentCategory.statistics: 25,
          },
          difficultyLevels: {
            class_models.ClassContentCategory.algebra:
                game.GameDifficulty.normal,
            class_models.ClassContentCategory.geometry:
                game.GameDifficulty.normal,
            class_models.ClassContentCategory.statistics:
                game.GameDifficulty.normal,
          },
        ),
        class_models.MathClass(
          id: 'grade8_math',
          level: class_models.ClassLevel.grade8,
          name: 'Grade 8 Mathematics',
          description: 'Eighth grade math with advanced algebra',
          displayName: 'Grade 8',
          minAge: 13,
          maxAge: 14,
          availableCategories: [
            class_models.ClassContentCategory.algebra,
            class_models.ClassContentCategory.geometry,
            class_models.ClassContentCategory.statistics,
          ],
          learningObjectives: {
            class_models.ClassContentCategory.algebra: [
              'Systems of equations',
              'Quadratic functions',
              'Polynomial expressions',
            ],
            class_models.ClassContentCategory.geometry: [
              'Similarity and congruence',
              'Volume and surface area',
              'Geometric proofs',
            ],
            class_models.ClassContentCategory.statistics: [
              'Advanced data analysis',
              'Probability theory',
              'Statistical inference',
            ],
          },
          questionCounts: {
            class_models.ClassContentCategory.algebra: 45,
            class_models.ClassContentCategory.geometry: 40,
            class_models.ClassContentCategory.statistics: 30,
          },
          difficultyLevels: {
            class_models.ClassContentCategory.algebra:
                game.GameDifficulty.genius,
            class_models.ClassContentCategory.geometry:
                game.GameDifficulty.normal,
            class_models.ClassContentCategory.statistics:
                game.GameDifficulty.normal,
          },
        ),
        class_models.MathClass(
          id: 'grade9_math',
          level: class_models.ClassLevel.grade9,
          name: 'Grade 9 Mathematics',
          description: 'Ninth grade math with advanced algebra',
          displayName: 'Grade 9',
          minAge: 14,
          maxAge: 15,
          availableCategories: [
            class_models.ClassContentCategory.algebra,
            class_models.ClassContentCategory.geometry,
            class_models.ClassContentCategory.calculus,
          ],
          learningObjectives: {
            class_models.ClassContentCategory.algebra: [
              'Advanced algebra',
              'Functions and graphs',
              'Complex equations',
            ],
            class_models.ClassContentCategory.geometry: [
              'Coordinate geometry',
              'Trigonometry basics',
              'Geometric proofs',
            ],
            class_models.ClassContentCategory.calculus: [
              'Limits and continuity',
              'Derivatives basics',
              'Function analysis',
            ],
          },
          questionCounts: {
            class_models.ClassContentCategory.algebra: 50,
            class_models.ClassContentCategory.geometry: 45,
            class_models.ClassContentCategory.calculus: 35,
          },
          difficultyLevels: {
            class_models.ClassContentCategory.algebra:
                game.GameDifficulty.genius,
            class_models.ClassContentCategory.geometry:
                game.GameDifficulty.genius,
            class_models.ClassContentCategory.calculus:
                game.GameDifficulty.genius,
          },
        ),
        class_models.MathClass(
          id: 'grade10_math',
          level: class_models.ClassLevel.grade10,
          name: 'Grade 10 Mathematics',
          description: 'Tenth grade math with trigonometry',
          displayName: 'Grade 10',
          minAge: 15,
          maxAge: 16,
          availableCategories: [
            class_models.ClassContentCategory.algebra,
            class_models.ClassContentCategory.geometry,
            class_models.ClassContentCategory.calculus,
          ],
          learningObjectives: {
            class_models.ClassContentCategory.algebra: [
              'Advanced functions',
              'Complex numbers',
              'Polynomial theory',
            ],
            class_models.ClassContentCategory.geometry: [
              'Trigonometry',
              'Analytic geometry',
              'Geometric proofs',
            ],
            class_models.ClassContentCategory.calculus: [
              'Derivatives',
              'Applications of calculus',
              'Function optimization',
            ],
          },
          questionCounts: {
            class_models.ClassContentCategory.algebra: 55,
            class_models.ClassContentCategory.geometry: 50,
            class_models.ClassContentCategory.calculus: 40,
          },
          difficultyLevels: {
            class_models.ClassContentCategory.algebra:
                game.GameDifficulty.genius,
            class_models.ClassContentCategory.geometry:
                game.GameDifficulty.genius,
            class_models.ClassContentCategory.calculus:
                game.GameDifficulty.genius,
          },
        ),
        class_models.MathClass(
          id: 'grade11_math',
          level: class_models.ClassLevel.grade11,
          name: 'Grade 11 Mathematics',
          description: 'Eleventh grade math with advanced calculus',
          displayName: 'Grade 11',
          minAge: 16,
          maxAge: 17,
          availableCategories: [
            class_models.ClassContentCategory.algebra,
            class_models.ClassContentCategory.calculus,
            class_models.ClassContentCategory.statistics,
          ],
          learningObjectives: {
            class_models.ClassContentCategory.algebra: [
              'Advanced algebra',
              'Linear algebra basics',
              'Complex analysis',
            ],
            class_models.ClassContentCategory.calculus: [
              'Integral calculus',
              'Applications of integration',
              'Differential equations',
            ],
            class_models.ClassContentCategory.statistics: [
              'Advanced statistics',
              'Probability theory',
              'Statistical inference',
            ],
          },
          questionCounts: {
            class_models.ClassContentCategory.algebra: 60,
            class_models.ClassContentCategory.calculus: 50,
            class_models.ClassContentCategory.statistics: 45,
          },
          difficultyLevels: {
            class_models.ClassContentCategory.algebra:
                game.GameDifficulty.quantum,
            class_models.ClassContentCategory.calculus:
                game.GameDifficulty.genius,
            class_models.ClassContentCategory.statistics:
                game.GameDifficulty.genius,
          },
        ),
        class_models.MathClass(
          id: 'grade12_math',
          level: class_models.ClassLevel.grade12,
          name: 'Grade 12 Mathematics',
          description: 'Twelfth grade math with advanced topics',
          displayName: 'Grade 12',
          minAge: 17,
          maxAge: 18,
          availableCategories: [
            class_models.ClassContentCategory.algebra,
            class_models.ClassContentCategory.calculus,
            class_models.ClassContentCategory.statistics,
          ],
          learningObjectives: {
            class_models.ClassContentCategory.algebra: [
              'Linear algebra',
              'Abstract algebra',
              'Number theory',
            ],
            class_models.ClassContentCategory.calculus: [
              'Multivariable calculus',
              'Vector calculus',
              'Advanced applications',
            ],
            class_models.ClassContentCategory.statistics: [
              'Advanced probability',
              'Mathematical statistics',
              'Data science applications',
            ],
          },
          questionCounts: {
            class_models.ClassContentCategory.algebra: 65,
            class_models.ClassContentCategory.calculus: 60,
            class_models.ClassContentCategory.statistics: 50,
          },
          difficultyLevels: {
            class_models.ClassContentCategory.algebra:
                game.GameDifficulty.quantum,
            class_models.ClassContentCategory.calculus:
                game.GameDifficulty.quantum,
            class_models.ClassContentCategory.statistics:
                game.GameDifficulty.quantum,
          },
        ),
      ];

      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print('ClassSelectionScreen: Error loading classes: $e');
      }
    }
  }

  Future<void> _createAccount() async {
    if (_selectedClass == null) {
      AdaptiveUISystem.showAdaptiveSnackBar(
        context: context,
        message: 'Please select a grade level to continue',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = ref.read(
        user_management.userManagementServiceProvider,
      );

      if (kDebugMode) {
        print('ClassSelectionScreen: Creating user account...');
        print('ClassSelectionScreen: Email: ${widget.email}');
        print('ClassSelectionScreen: Role: ${widget.userRole}');
        print('ClassSelectionScreen: Selected Class: ${_selectedClass!.name}');
      }

      // Create the user account with timeout
      final user = await userService
          .registerUser(
            email: widget.email,
            password: widget.password,
            displayName: widget.displayName,
            role: widget.userRole,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              if (kDebugMode) {
                print('ClassSelectionScreen: User registration timed out');
              }
              throw TimeoutException('User registration timed out');
            },
          );

      if (kDebugMode) {
        print(
          'ClassSelectionScreen: User created successfully: ${user.displayName}',
        );
        print('ClassSelectionScreen: User ID: ${user.id}');
      }

      // Initialize class access with selected class as active, others locked
      final classService = ref.read(
        user_management.classManagementServiceProvider,
      );

      try {
        if (kDebugMode) {
          print('ClassSelectionScreen: Initializing class access...');
        }

        await classService
            .initializeUserClassAccess(user.id, _selectedClass!)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                if (kDebugMode) {
                  print(
                    'ClassSelectionScreen: Class access initialization timed out',
                  );
                }
                throw TimeoutException('Class access initialization timed out');
              },
            );

        if (kDebugMode) {
          print('ClassSelectionScreen: Class access initialized successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('ClassSelectionScreen: Class access initialization error: $e');
        }
        // Continue even if class access fails
      }

      // Initialize additional SSOT components
      try {
        await _initializeSSOTComponents(user).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            if (kDebugMode) {
              print(
                'ClassSelectionScreen: SSOT components initialization timed out',
              );
            }
            throw TimeoutException('SSOT components initialization timed out');
          },
        );

        if (kDebugMode) {
          print('ClassSelectionScreen: SSOT components initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            'ClassSelectionScreen: SSOT components initialization error: $e',
          );
        }
        // Continue even if SSOT components fail
      }

      if (kDebugMode) {
        print('ClassSelectionScreen: About to navigate to home...');
      }

      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message:
              'Account created successfully! Welcome to ${_getClassDisplayName(_selectedClass!)}',
        );

        // Add a small delay to ensure all async operations complete
        await Future.delayed(const Duration(milliseconds: 500));

        if (kDebugMode) {
          print('ClassSelectionScreen: Navigating to /home');
        }

        // Test navigation with a simple approach
        try {
          if (!mounted) return;
          context.go('/home');
          if (kDebugMode) {
            print('ClassSelectionScreen: Navigation command sent successfully');
          }
        } catch (e) {
          if (kDebugMode) {
            print('ClassSelectionScreen: Navigation error: $e');
          }
          // Try alternative navigation method
          try {
            if (!mounted) return;
            context.go('/home');
            if (kDebugMode) {
              print('ClassSelectionScreen: Alternative navigation successful');
            }
          } catch (e2) {
            if (kDebugMode) {
              print(
                'ClassSelectionScreen: Alternative navigation also failed: $e2',
              );
            }
          }
        }
      } else {
        if (kDebugMode) {
          print('ClassSelectionScreen: Widget not mounted, cannot navigate');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ClassSelectionScreen: Error creating account: $e');
        print('ClassSelectionScreen: Error stack trace: ${StackTrace.current}');
      }
      if (mounted) {
        _showErrorDialog('Account Creation Error', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Initialize SSOT components after account creation
  Future<void> _initializeSSOTComponents(user_models.User user) async {
    try {
      // Initialize analytics
      await FirebaseService.logEvent(
        name: 'student_registration_completed',
        parameters: {
          'user_id': user.id,
          'class_level': _selectedClass!.name,
          'role': user.role.toString(),
        },
      );

      // Initialize device context
      final deviceContext = await _getDeviceContext();
      await _saveDeviceContext(deviceContext);

      if (kDebugMode) {
        print('ClassSelectionScreen: SSOT components initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ClassSelectionScreen: Error initializing SSOT components: $e');
      }
    }
  }

  /// Get device context for SSOT compliance
  Future<Map<String, dynamic>> _getDeviceContext() async {
    try {
      final mediaQuery = MediaQuery.of(context);
      return {
        'platform': Theme.of(context).platform.name,
        'screenWidth': mediaQuery.size.width,
        'screenHeight': mediaQuery.size.height,
        'pixelRatio': mediaQuery.devicePixelRatio,
        'isTablet': mediaQuery.size.width > 600,
        'isLandscape': mediaQuery.orientation == Orientation.landscape,
      };
    } catch (e) {
      return {
        'platform': 'unknown',
        'screenWidth': 0,
        'screenHeight': 0,
        'pixelRatio': 1.0,
        'isTablet': false,
        'isLandscape': false,
      };
    }
  }

  /// Save device context
  Future<void> _saveDeviceContext(Map<String, dynamic> context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_context', jsonEncode(context));
    } catch (e) {
      if (kDebugMode) {
        print('ClassSelectionScreen: Error saving device context: $e');
      }
    }
  }

  /// Show error dialog with detailed information
  void _showErrorDialog(String title, String message) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    AdaptiveUISystem.showAdaptiveDialog(
      context: context,
      child: AlertDialog(
        title: Text(
          title,
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please try again or contact support if the problem persists.',
              style: themeData.typography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: themeData.typography.labelLarge.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getClassDisplayName(class_models.ClassLevel level) {
    switch (level) {
      case class_models.ClassLevel.preK:
        return 'Pre-K';
      case class_models.ClassLevel.kindergarten:
        return 'Kindergarten';
      case class_models.ClassLevel.grade1:
        return 'Grade 1';
      case class_models.ClassLevel.grade2:
        return 'Grade 2';
      case class_models.ClassLevel.grade3:
        return 'Grade 3';
      case class_models.ClassLevel.grade4:
        return 'Grade 4';
      case class_models.ClassLevel.grade5:
        return 'Grade 5';
      case class_models.ClassLevel.grade6:
        return 'Grade 6';
      case class_models.ClassLevel.grade7:
        return 'Grade 7';
      case class_models.ClassLevel.grade8:
        return 'Grade 8';
      case class_models.ClassLevel.grade9:
        return 'Grade 9';
      case class_models.ClassLevel.grade10:
        return 'Grade 10';
      case class_models.ClassLevel.grade11:
        return 'Grade 11';
      case class_models.ClassLevel.grade12:
        return 'Grade 12';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Icon(Icons.school, size: 48, color: colorScheme.primary),
                      const SizedBox(height: 10),
                      Text(
                        'Math Genius',
                        style: themeData.typography.headlineMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose your learning level',
                        style: themeData.typography.bodyMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Class Selection Dropdown
                      Text(
                        'Grade Level',
                        style: themeData.typography.labelLarge.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<class_models.ClassLevel>(
                        value: _selectedClass,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        hint: Text(
                          'Select your grade level',
                          style: themeData.typography.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        items: _availableClasses.map((mathClass) {
                          return DropdownMenuItem<class_models.ClassLevel>(
                            value: mathClass.level,
                            child: Text(
                              mathClass.displayName,
                              style: themeData.typography.bodyMedium.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (class_models.ClassLevel? value) {
                          setState(() {
                            _selectedClass = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Selected Class Details
                      if (_selectedClass != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Class Details',
                                style: themeData.typography.labelLarge.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildClassDetails(
                                _availableClasses.firstWhere(
                                  (mathClass) =>
                                      mathClass.level == _selectedClass,
                                ),
                                themeData,
                                colorScheme,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Create Account',
                                  style: themeData.typography.labelLarge
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Back to Auth
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Want to change your details? ',
                            style: themeData.typography.bodyMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/auth'),
                            child: Text(
                              'Go Back',
                              style: themeData.typography.labelLarge.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassDetails(
    class_models.MathClass mathClass,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.school, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              mathClass.name,
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          mathClass.description,
          style: themeData.typography.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Learning Areas:',
          style: themeData.typography.labelLarge.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: mathClass.availableCategories.map((category) {
            return Chip(
              label: Text(
                _getCategoryDisplayName(category),
                style: themeData.typography.bodySmall.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
              backgroundColor: colorScheme.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.person, color: colorScheme.primary, size: 16),
            const SizedBox(width: 8),
            Text(
              'Ages ${mathClass.minAge}-${mathClass.maxAge}',
              style: themeData.typography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getCategoryDisplayName(class_models.ClassContentCategory category) {
    switch (category) {
      case class_models.ClassContentCategory.arithmetic:
        return 'Arithmetic';
      case class_models.ClassContentCategory.algebra:
        return 'Algebra';
      case class_models.ClassContentCategory.geometry:
        return 'Geometry';
      case class_models.ClassContentCategory.calculus:
        return 'Calculus';
      case class_models.ClassContentCategory.statistics:
        return 'Statistics';
      case class_models.ClassContentCategory.wordProblems:
        return 'Word Problems';
      case class_models.ClassContentCategory.mentalMath:
        return 'Mental Math';
      case class_models.ClassContentCategory.logicPuzzles:
        return 'Logic Puzzles';
    }
  }
}
