import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:math';

// Models
import '../models/enhanced_tutor_model.dart';

/// Enhanced AI tutor service with advanced conversation and learning features
/// Provides personalized tutoring with emotional intelligence and adaptive responses
class EnhancedAITutorService {
  static const String _studentProfilesKey = 'student_profiles';
  static const String _tutorSessionsKey = 'enhanced_tutor_sessions';
  static const String _learningProgressKey = 'learning_progress';
  static const String _conversationHistoryKey = 'conversation_history';

  final SharedPreferences _prefs;
  final Box? _hiveBox;
  final Random _random = Random();

  EnhancedAITutorService(this._prefs, this._hiveBox);

  /// Get or create student profile
  Future<StudentProfile> getStudentProfile(String studentId) async {
    try {
      // Try Hive first
      if (_hiveBox != null) {
        final profileData = _hiveBox.get('${_studentProfilesKey}_$studentId');
        if (profileData != null) {
          return StudentProfile.fromJson(jsonDecode(profileData as String));
        }
      }

      // Fallback to SharedPreferences
      final profileString = _prefs.getString(
        '${_studentProfilesKey}_$studentId',
      );
      if (profileString == null) {
        // Create default profile
        return StudentProfile(
          studentId: studentId,
          name: 'Student',
          lastActive: DateTime.now(),
        );
      }

      return StudentProfile.fromJson(jsonDecode(profileString));
    } catch (e) {
      if (kDebugMode) {
        print('Error getting student profile: $e');
      }
      return StudentProfile(
        studentId: studentId,
        name: 'Student',
        lastActive: DateTime.now(),
      );
    }
  }

  /// Update student profile
  Future<void> updateStudentProfile(StudentProfile profile) async {
    try {
      final profileJson = jsonEncode(profile.toJson());

      // Save to Hive first
      if (_hiveBox != null) {
        await _hiveBox.put(
          '${_studentProfilesKey}_${profile.studentId}',
          profileJson,
        );
      }

      // Fallback to SharedPreferences
      await _prefs.setString(
        '${_studentProfilesKey}_${profile.studentId}',
        profileJson,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating student profile: $e');
      }
    }
  }

  /// Get available tutor personalities
  List<TutorPersonality> getAvailableTutorPersonalities() {
    return [
      const TutorPersonality(
        name: 'Maya',
        description:
            'Enthusiastic and encouraging math tutor who loves making learning fun!',
        traits: {
          'enthusiasm': 0.9,
          'patience': 0.8,
          'friendliness': 0.95,
          'formality': 0.2,
        },
        preferredStyle: LearningStyle.visual,
        strategies: [
          TutoringStrategy.gamification,
          TutoringStrategy.storytelling,
          TutoringStrategy.guidedDiscovery,
        ],
        responses: {
          'greeting':
              'Hi there! I\'m Maya, and I\'m super excited to learn math with you today! 🌟',
          'encouragement': 'You\'re doing amazing! Keep going! 💪',
          'explanation': 'Let me show you a fun way to think about this...',
          'challenge':
              'Ready for something a bit trickier? I know you can do it!',
        },
      ),
      const TutorPersonality(
        name: 'Professor Chen',
        description:
            'Wise and methodical tutor who believes in building strong foundations.',
        traits: {
          'enthusiasm': 0.6,
          'patience': 0.95,
          'friendliness': 0.7,
          'formality': 0.8,
        },
        preferredStyle: LearningStyle.readingWriting,
        strategies: [
          TutoringStrategy.scaffolding,
          TutoringStrategy.directInstruction,
          TutoringStrategy.socraticMethod,
        ],
        responses: {
          'greeting':
              'Good day, student. I am Professor Chen. Let us begin our mathematical journey.',
          'encouragement':
              'Excellent work. Your understanding is developing well.',
          'explanation': 'Allow me to explain the underlying principles...',
          'challenge':
              'Now, let us apply this knowledge to a more complex problem.',
        },
      ),
      const TutorPersonality(
        name: 'Alex',
        description:
            'Cool and relatable tutor who connects math to real-world applications.',
        traits: {
          'enthusiasm': 0.7,
          'patience': 0.8,
          'friendliness': 0.85,
          'formality': 0.3,
        },
        preferredStyle: LearningStyle.kinesthetic,
        strategies: [
          TutoringStrategy.realWorldApplication,
          TutoringStrategy.collaborative,
          TutoringStrategy.guidedDiscovery,
        ],
        responses: {
          'greeting':
              'Hey! I\'m Alex. Ready to see how math works in the real world?',
          'encouragement': 'Nice! You\'re getting the hang of this!',
          'explanation': 'Think about it like this - imagine you\'re...',
          'challenge': 'Here\'s a real situation where you\'d use this math...',
        },
      ),
    ];
  }

  /// Create enhanced tutor session
  Future<EnhancedTutorSession> createTutorSession({
    required String studentId,
    String? tutorPersonalityName,
    String subject = 'Math',
    List<String>? learningObjectives,
  }) async {
    try {
      final studentProfile = await getStudentProfile(studentId);
      final tutorPersonalities = getAvailableTutorPersonalities();

      // Select tutor personality based on preference or default
      TutorPersonality tutorPersonality;
      if (tutorPersonalityName != null) {
        tutorPersonality = tutorPersonalities.firstWhere(
          (t) => t.name == tutorPersonalityName,
          orElse: () => tutorPersonalities.first,
        );
      } else {
        // Select based on student's learning style
        tutorPersonality = _selectOptimalTutor(
          studentProfile,
          tutorPersonalities,
        );
      }

      final sessionId = 'enhanced_${DateTime.now().millisecondsSinceEpoch}';
      final session = EnhancedTutorSession(
        id: sessionId,
        studentId: studentId,
        tutorId: tutorPersonality.name,
        startTime: DateTime.now(),
        subject: subject,
        studentProfile: studentProfile,
        tutorPersonality: tutorPersonality,
        learningObjectives:
            learningObjectives ?? _generateLearningObjectives(studentProfile),
      );

      // Add initial greeting message
      final greetingMessage = await _generateGreetingMessage(session);
      final sessionWithGreeting = session.copyWith(
        messages: [greetingMessage],
        currentContext: ConversationContext.greeting,
      );

      await _saveTutorSession(sessionWithGreeting);
      return sessionWithGreeting;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating tutor session: $e');
      }
      rethrow;
    }
  }

  /// Generate AI response to student message
  Future<ConversationMessage> generateResponse({
    required EnhancedTutorSession session,
    required String studentMessage,
    ConversationContext? context,
  }) async {
    try {
      // Analyze student message for context and emotion
      final messageAnalysis = _analyzeStudentMessage(studentMessage, session);
      final responseContext =
          context ?? messageAnalysis['context'] as ConversationContext;

      // Select appropriate tutoring strategy
      final strategy = _selectTutoringStrategy(
        session,
        responseContext,
        messageAnalysis,
      );

      // Generate personalized response
      final responseContent = await _generatePersonalizedResponse(
        session,
        studentMessage,
        responseContext,
        strategy,
        messageAnalysis,
      );

      // Create response message
      final responseId = 'response_${DateTime.now().millisecondsSinceEpoch}';
      final response = ConversationMessage(
        id: responseId,
        content: responseContent,
        isFromTutor: true,
        timestamp: DateTime.now(),
        context: responseContext,
        confidence: messageAnalysis['confidence'] as double,
        suggestedResponses: _generateSuggestedResponses(
          responseContext,
          session,
        ),
        metadata: {'strategy': strategy.name, 'analysis': messageAnalysis},
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating response: $e');
      }

      // Fallback response
      return ConversationMessage(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        content:
            'I\'m here to help! Could you tell me more about what you\'re working on?',
        isFromTutor: true,
        timestamp: DateTime.now(),
        context: ConversationContext.problemSolving,
      );
    }
  }

  /// Update session with new message
  Future<EnhancedTutorSession> addMessageToSession({
    required EnhancedTutorSession session,
    required ConversationMessage message,
  }) async {
    try {
      final updatedMessages = [...session.messages, message];

      // Update session analytics
      final updatedAnalytics = _updateSessionAnalytics(session, message);

      // Update conversation context if needed
      final newContext = _determineNewContext(session, message);

      final updatedSession = session.copyWith(
        messages: updatedMessages,
        currentContext: newContext,
        sessionAnalytics: updatedAnalytics,
        studentEngagement: _calculateEngagement(updatedMessages),
      );

      await _saveTutorSession(updatedSession);
      return updatedSession;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding message to session: $e');
      }
      return session;
    }
  }

  /// Select optimal tutor personality for student
  TutorPersonality _selectOptimalTutor(
    StudentProfile student,
    List<TutorPersonality> tutors,
  ) {
    // Match based on learning style and proficiency
    final mathProficiency = student.getMathProficiency();

    if (mathProficiency < 0.3) {
      // Struggling students need more encouragement and patience
      return tutors
              .where((t) => t.patience > 0.8 && t.friendliness > 0.8)
              .isNotEmpty
          ? tutors.firstWhere((t) => t.patience > 0.8 && t.friendliness > 0.8)
          : tutors.first;
    } else if (mathProficiency > 0.7) {
      // Advanced students can handle more challenge and formality
      return tutors.where((t) => t.formality > 0.5).isNotEmpty
          ? tutors.firstWhere((t) => t.formality > 0.5)
          : tutors.first;
    } else {
      // Average students - balanced approach
      return tutors.firstWhere(
        (t) => t.preferredStyle == student.preferredLearningStyle,
        orElse: () => tutors.first,
      );
    }
  }

  /// Generate learning objectives based on student profile
  List<String> _generateLearningObjectives(StudentProfile student) {
    final objectives = <String>[];

    // Based on grade level
    switch (student.gradeLevel) {
      case 1:
      case 2:
        objectives.addAll([
          'Master single-digit addition and subtraction',
          'Understand number patterns',
          'Learn basic shapes and measurements',
        ]);
        break;
      case 3:
      case 4:
        objectives.addAll([
          'Master multiplication tables',
          'Understand fractions basics',
          'Solve word problems',
        ]);
        break;
      case 5:
      case 6:
        objectives.addAll([
          'Work with decimals and percentages',
          'Understand basic geometry',
          'Solve multi-step problems',
        ]);
        break;
      default:
        objectives.addAll([
          'Strengthen mathematical reasoning',
          'Apply math to real-world situations',
          'Build problem-solving skills',
        ]);
    }

    // Add personalized objectives based on struggling topics
    for (final topic in student.strugglingTopics) {
      objectives.add('Improve understanding of $topic');
    }

    return objectives.take(3).toList(); // Limit to 3 main objectives
  }

  /// Generate greeting message
  Future<ConversationMessage> _generateGreetingMessage(
    EnhancedTutorSession session,
  ) async {
    final tutor = session.tutorPersonality;
    final student = session.studentProfile;

    String greeting =
        tutor.responses['greeting'] ??
        'Hello! I\'m ${tutor.name}, and I\'m here to help you with math!';

    // Personalize greeting
    if (student.totalSessions > 0) {
      greeting = greeting.replaceAll('Hello!', 'Welcome back!');
      greeting += ' I\'m excited to continue our math journey together.';
    } else {
      greeting += ' This is going to be fun!';
    }

    return ConversationMessage(
      id: 'greeting_${DateTime.now().millisecondsSinceEpoch}',
      content: greeting,
      isFromTutor: true,
      timestamp: DateTime.now(),
      context: ConversationContext.greeting,
      suggestedResponses: [
        'Hi! I\'m ready to learn!',
        'What are we going to work on today?',
        'I need help with math homework',
      ],
    );
  }

  /// Analyze student message for context and emotion
  Map<String, dynamic> _analyzeStudentMessage(
    String message,
    EnhancedTutorSession session,
  ) {
    final lowerMessage = message.toLowerCase();
    ConversationContext context = ConversationContext.problemSolving;
    String emotion = 'neutral';
    double confidence = 0.8;

    // Context analysis
    if (lowerMessage.contains(RegExp(r'\b(hi|hello|hey)\b'))) {
      context = ConversationContext.greeting;
    } else if (lowerMessage.contains(RegExp(r'\b(help|stuck|understand)\b'))) {
      context = ConversationContext.explanation;
      emotion = 'confused';
    } else if (lowerMessage.contains(
      RegExp(r'\b(thanks|got it|understand)\b'),
    )) {
      context = ConversationContext.encouragement;
      emotion = 'positive';
    } else if (lowerMessage.contains(
      RegExp(r'\b(hard|difficult|frustrated)\b'),
    )) {
      context = ConversationContext.encouragement;
      emotion = 'frustrated';
    } else if (lowerMessage.contains(RegExp(r'\b(more|challenge|harder)\b'))) {
      context = ConversationContext.challenge;
      emotion = 'confident';
    } else if (lowerMessage.contains('?')) {
      context = ConversationContext.assessment;
    }

    // Adjust confidence based on message clarity
    if (message.length < 5) {
      confidence = 0.5;
    } else if (message.length > 50) {
      confidence = 0.9;
    }

    return {
      'context': context,
      'emotion': emotion,
      'confidence': confidence,
      'messageLength': message.length,
      'hasQuestion': message.contains('?'),
    };
  }

  /// Select appropriate tutoring strategy
  TutoringStrategy _selectTutoringStrategy(
    EnhancedTutorSession session,
    ConversationContext context,
    Map<String, dynamic> analysis,
  ) {
    final tutor = session.tutorPersonality;
    final student = session.studentProfile;
    final emotion = analysis['emotion'] as String;

    // Strategy selection based on context and student state
    switch (context) {
      case ConversationContext.explanation:
        if (emotion == 'frustrated') {
          return TutoringStrategy.scaffolding; // Break it down
        } else if (student.preferredLearningStyle == LearningStyle.visual) {
          return TutoringStrategy.storytelling;
        } else {
          return TutoringStrategy.directInstruction;
        }

      case ConversationContext.encouragement:
        return TutoringStrategy.gamification;

      case ConversationContext.challenge:
        return TutoringStrategy.socraticMethod;

      case ConversationContext.assessment:
        return TutoringStrategy.guidedDiscovery;

      default:
        // Use tutor's preferred strategies
        return tutor.strategies.isNotEmpty
            ? tutor.strategies.first
            : TutoringStrategy.directInstruction;
    }
  }

  /// Generate personalized response content
  Future<String> _generatePersonalizedResponse(
    EnhancedTutorSession session,
    String studentMessage,
    ConversationContext context,
    TutoringStrategy strategy,
    Map<String, dynamic> analysis,
  ) async {
    final tutor = session.tutorPersonality;
    final student = session.studentProfile;
    final emotion = analysis['emotion'] as String;

    // Base response from tutor personality
    String baseResponse =
        tutor.responses[context.name] ?? _getDefaultResponse(context, strategy);

    // Personalize based on strategy
    String response = _applyTutoringStrategy(
      baseResponse,
      strategy,
      studentMessage,
      session,
    );

    // Adjust tone based on tutor personality
    response = _adjustToneForPersonality(response, tutor);

    // Add emotional support if needed
    if (emotion == 'frustrated') {
      response = _addEmotionalSupport(response, tutor);
    } else if (emotion == 'confident') {
      response = _addChallenge(response, tutor);
    }

    // Add student name for personalization
    if (student.name != 'Student') {
      response = response.replaceFirst('you', student.name);
    }

    return response;
  }

  /// Get default response for context
  String _getDefaultResponse(
    ConversationContext context,
    TutoringStrategy strategy,
  ) {
    switch (context) {
      case ConversationContext.greeting:
        return 'Hello! I\'m here to help you with math. What would you like to work on?';
      case ConversationContext.explanation:
        return 'Let me help you understand this better. ';
      case ConversationContext.encouragement:
        return 'You\'re doing great! Keep up the good work!';
      case ConversationContext.challenge:
        return 'Ready for something more challenging?';
      case ConversationContext.assessment:
        return 'Let me see how well you understand this...';
      default:
        return 'I\'m here to help! What can I explain for you?';
    }
  }

  /// Apply tutoring strategy to response
  String _applyTutoringStrategy(
    String baseResponse,
    TutoringStrategy strategy,
    String studentMessage,
    EnhancedTutorSession session,
  ) {
    switch (strategy) {
      case TutoringStrategy.scaffolding:
        return '$baseResponse Let\'s break this down into smaller steps. First, ';
      case TutoringStrategy.socraticMethod:
        return '$baseResponse What do you think would happen if...?';
      case TutoringStrategy.storytelling:
        return '$baseResponse Imagine you\'re on a treasure hunt and ';
      case TutoringStrategy.realWorldApplication:
        return '$baseResponse Think about when you might use this in real life - ';
      case TutoringStrategy.gamification:
        return '$baseResponse Let\'s turn this into a fun challenge! ';
      case TutoringStrategy.guidedDiscovery:
        return '$baseResponse Let\'s explore this together. What patterns do you notice?';
      default:
        return baseResponse;
    }
  }

  /// Adjust tone for tutor personality
  String _adjustToneForPersonality(String response, TutorPersonality tutor) {
    if (tutor.enthusiasm > 0.8) {
      // Add enthusiasm
      response = response.replaceAll('.', '!');
      if (!response.contains('!')) response += '!';
    }

    if (tutor.friendliness > 0.8) {
      // Add friendly elements
      if (!response.contains('😊') && _random.nextDouble() < 0.3) {
        response += ' 😊';
      }
    }

    if (tutor.formality > 0.7) {
      // Make more formal
      response = response.replaceAll('Let\'s', 'Let us');
      response = response.replaceAll('you\'re', 'you are');
    }

    return response;
  }

  /// Add emotional support
  String _addEmotionalSupport(String response, TutorPersonality tutor) {
    final supportPhrases = [
      'Don\'t worry, this is tricky for everyone at first.',
      'It\'s okay to feel confused - that means you\'re learning!',
      'Take your time, there\'s no rush.',
      'You\'ve got this!',
    ];

    final supportPhrase =
        supportPhrases[_random.nextInt(supportPhrases.length)];
    return '$supportPhrase $response';
  }

  /// Add challenge
  String _addChallenge(String response, TutorPersonality tutor) {
    final challengePhrases = [
      'Since you\'re doing so well, ',
      'I can see you\'re ready for more, ',
      'You\'re really getting the hang of this! ',
    ];

    final challengePhrase =
        challengePhrases[_random.nextInt(challengePhrases.length)];
    return '$challengePhrase$response';
  }

  /// Generate suggested responses for student
  List<String> _generateSuggestedResponses(
    ConversationContext context,
    EnhancedTutorSession session,
  ) {
    switch (context) {
      case ConversationContext.greeting:
        return [
          'I need help with homework',
          'Can we practice multiplication?',
          'I want to learn something new',
        ];
      case ConversationContext.explanation:
        return [
          'I think I understand',
          'Can you show me another example?',
          'This is still confusing',
        ];
      case ConversationContext.encouragement:
        return [
          'Thank you!',
          'Can we try another one?',
          'I feel more confident now',
        ];
      case ConversationContext.challenge:
        return [
          'Yes, I\'m ready!',
          'Maybe something easier first?',
          'What kind of challenge?',
        ];
      default:
        return ['Yes', 'I need more help', 'Let\'s try something else'];
    }
  }

  /// Update session analytics
  Map<String, dynamic> _updateSessionAnalytics(
    EnhancedTutorSession session,
    ConversationMessage message,
  ) {
    final analytics = Map<String, dynamic>.from(session.sessionAnalytics);

    // Update message counts
    analytics['totalMessages'] = (analytics['totalMessages'] ?? 0) + 1;
    if (message.isFromTutor) {
      analytics['tutorMessages'] = (analytics['tutorMessages'] ?? 0) + 1;
    } else {
      analytics['studentMessages'] = (analytics['studentMessages'] ?? 0) + 1;
    }

    // Update context tracking
    final contextKey = 'context_${message.context.name}';
    analytics[contextKey] = (analytics[contextKey] ?? 0) + 1;

    // Update response time if applicable
    if (!message.isFromTutor && session.messages.isNotEmpty) {
      final lastTutorMessage = session.messages.lastWhere(
        (m) => m.isFromTutor,
        orElse: () => session.messages.last,
      );
      final responseTime = message.timestamp.difference(
        lastTutorMessage.timestamp,
      );
      analytics['averageResponseTime'] =
          ((analytics['averageResponseTime'] ?? 0.0) + responseTime.inSeconds) /
          2;
    }

    return analytics;
  }

  /// Determine new conversation context
  ConversationContext _determineNewContext(
    EnhancedTutorSession session,
    ConversationMessage message,
  ) {
    if (message.isFromTutor) {
      return message.context;
    }

    // Analyze student message to determine context
    final analysis = _analyzeStudentMessage(message.content, session);
    return analysis['context'] as ConversationContext;
  }

  /// Calculate student engagement score
  double _calculateEngagement(List<ConversationMessage> messages) {
    if (messages.length < 2) return 0.5;

    final studentMessages = messages.where((m) => !m.isFromTutor).toList();
    if (studentMessages.isEmpty) return 0.0;

    double engagement = 0.0;

    // Factor in response frequency
    engagement += (studentMessages.length / messages.length) * 0.4;

    // Factor in message length (engagement indicator)
    final avgLength =
        studentMessages.map((m) => m.content.length).reduce((a, b) => a + b) /
        studentMessages.length;
    engagement += (avgLength / 100).clamp(0.0, 0.3);

    // Factor in question asking (curiosity indicator)
    final questionsAsked = studentMessages
        .where((m) => m.content.contains('?'))
        .length;
    engagement += (questionsAsked / studentMessages.length) * 0.3;

    return engagement.clamp(0.0, 1.0);
  }

  /// Save tutor session
  Future<void> _saveTutorSession(EnhancedTutorSession session) async {
    try {
      final sessionJson = jsonEncode(session.toJson());

      // Save to Hive first
      if (_hiveBox != null) {
        await _hiveBox.put('${_tutorSessionsKey}_${session.id}', sessionJson);
      }

      // Fallback to SharedPreferences
      await _prefs.setString('${_tutorSessionsKey}_${session.id}', sessionJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving tutor session: $e');
      }
    }
  }

  /// Get tutor session by ID
  Future<EnhancedTutorSession?> getTutorSession(String sessionId) async {
    try {
      // Try Hive first
      if (_hiveBox != null) {
        final sessionData = _hiveBox.get('${_tutorSessionsKey}_$sessionId');
        if (sessionData != null) {
          return EnhancedTutorSession.fromJson(
            jsonDecode(sessionData as String),
          );
        }
      }

      // Fallback to SharedPreferences
      final sessionString = _prefs.getString('${_tutorSessionsKey}_$sessionId');
      if (sessionString == null) return null;

      return EnhancedTutorSession.fromJson(jsonDecode(sessionString));
    } catch (e) {
      if (kDebugMode) {
        print('Error getting tutor session: $e');
      }
      return null;
    }
  }

  /// End tutor session
  Future<EnhancedTutorSession?> endTutorSession(String sessionId) async {
    try {
      final session = await getTutorSession(sessionId);
      if (session == null) return null;

      final endedSession = session.copyWith(
        endTime: DateTime.now(),
        status: EnhancedSessionStatus.completed,
      );

      await _saveTutorSession(endedSession);

      // Update student profile with session data
      await _updateStudentProfileFromSession(endedSession);

      return endedSession;
    } catch (e) {
      if (kDebugMode) {
        print('Error ending tutor session: $e');
      }
      return null;
    }
  }

  /// Update student profile based on completed session
  Future<void> _updateStudentProfileFromSession(
    EnhancedTutorSession session,
  ) async {
    try {
      final updatedProfile = session.studentProfile.copyWith(
        lastActive: DateTime.now(),
        totalSessions: session.studentProfile.totalSessions + 1,
        averageEngagement:
            (session.studentProfile.averageEngagement +
                session.studentEngagement) /
            2,
      );

      await updateStudentProfile(updatedProfile);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating student profile from session: $e');
      }
    }
  }
}

/// Provider for enhanced AI tutor service
final enhancedAITutorServiceProvider = Provider<EnhancedAITutorService>((ref) {
  // This would be properly injected in a real app
  throw UnimplementedError(
    'EnhancedAITutorService provider needs to be configured',
  );
});
