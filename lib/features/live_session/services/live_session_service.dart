import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';

// Models
import '../models/live_session_model.dart';

/// Live Session Service for Math Genius
class LiveSessionService {
  static const String _liveSessionsKey = 'live_sessions';
  static const String _liveQuestionsKey = 'live_questions';
  static const String _liveParticipantsKey = 'live_participants';
  static const String _liveResultsKey = 'live_results';

  final SharedPreferences _prefs;
  final Box? _hiveBox;

  LiveSessionService(this._prefs, this._hiveBox);

  /// Create a new live session
  Future<LiveSession> createLiveSession({
    required String hostId,
    required String hostName,
    required String title,
    required String description,
    SessionAccessType accessType = SessionAccessType.public,
    String? password,
    int maxParticipants = 50,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final session = LiveSession(
        id: _generateId(),
        hostId: hostId,
        hostName: hostName,
        title: title,
        description: description,
        accessType: accessType,
        password: password,
        qrCode: _generateQRCode(),
        createdAt: DateTime.now(),
        maxParticipants: maxParticipants,
        settings: settings ?? {},
      );

      await _saveLiveSession(session);
      return session;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating live session: $e');
      }
      rethrow;
    }
  }

  /// Join a live session
  Future<LiveParticipant?> joinLiveSession({
    required String sessionId,
    required String participantName,
    String? avatar,
    String? password,
  }) async {
    try {
      final session = await getLiveSession(sessionId);
      if (session == null) return null;

      // Check access restrictions
      if (session.accessType == SessionAccessType.passwordProtected) {
        if (password != session.password) {
          throw Exception('Incorrect password');
        }
      }

      // Check if session is full
      if (session.currentParticipants >= session.maxParticipants) {
        throw Exception('Session is full');
      }

      // Check if session is active
      if (session.status != LiveSessionStatus.waiting &&
          session.status != LiveSessionStatus.active) {
        throw Exception('Session is not available for joining');
      }

      final participant = LiveParticipant(
        id: _generateId(),
        sessionId: sessionId,
        name: participantName,
        avatar: avatar,
        joinedAt: DateTime.now(),
      );

      await _saveLiveParticipant(participant);

      // Update session participant count
      final updatedSession = session.copyWith(
        currentParticipants: session.currentParticipants + 1,
        participantIds: [...session.participantIds, participant.id],
      );
      await _saveLiveSession(updatedSession);

      return participant;
    } catch (e) {
      if (kDebugMode) {
        print('Error joining live session: $e');
      }
      rethrow;
    }
  }

  /// Start a live session
  Future<LiveSession?> startLiveSession(String sessionId) async {
    try {
      final session = await getLiveSession(sessionId);
      if (session == null) return null;

      final updatedSession = session.copyWith(
        status: LiveSessionStatus.active,
        startedAt: DateTime.now(),
      );

      await _saveLiveSession(updatedSession);
      return updatedSession;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting live session: $e');
      }
      return null;
    }
  }

  /// Pause a live session
  Future<LiveSession?> pauseLiveSession(String sessionId) async {
    try {
      final session = await getLiveSession(sessionId);
      if (session == null) return null;

      final updatedSession = session.copyWith(status: LiveSessionStatus.paused);

      await _saveLiveSession(updatedSession);
      return updatedSession;
    } catch (e) {
      if (kDebugMode) {
        print('Error pausing live session: $e');
      }
      return null;
    }
  }

  /// End a live session
  Future<LiveSession?> endLiveSession(String sessionId) async {
    try {
      final session = await getLiveSession(sessionId);
      if (session == null) return null;

      final updatedSession = session.copyWith(
        status: LiveSessionStatus.completed,
        endedAt: DateTime.now(),
      );

      await _saveLiveSession(updatedSession);
      return updatedSession;
    } catch (e) {
      if (kDebugMode) {
        print('Error ending live session: $e');
      }
      return null;
    }
  }

  /// Add a question to a live session
  Future<LiveQuestion> addQuestion({
    required String sessionId,
    required String question,
    required List<String> options,
    required int correctAnswer,
    String? explanation,
    int timeLimit = 30,
  }) async {
    try {
      final liveQuestion = LiveQuestion(
        id: _generateId(),
        sessionId: sessionId,
        question: question,
        options: options,
        correctAnswer: correctAnswer,
        explanation: explanation,
        timeLimit: timeLimit,
      );

      await _saveLiveQuestion(liveQuestion);

      // Update session with new question
      final session = await getLiveSession(sessionId);
      if (session != null) {
        final updatedQuestions = [...session.questions, liveQuestion];
        final updatedSession = session.copyWith(questions: updatedQuestions);
        await _saveLiveSession(updatedSession);
      }

      return liveQuestion;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding question: $e');
      }
      rethrow;
    }
  }

  /// Display a question in the session
  Future<LiveQuestion?> displayQuestion(String questionId) async {
    try {
      final question = await getLiveQuestion(questionId);
      if (question == null) return null;

      final updatedQuestion = question.copyWith(displayedAt: DateTime.now());

      await _saveLiveQuestion(updatedQuestion);
      return updatedQuestion;
    } catch (e) {
      if (kDebugMode) {
        print('Error displaying question: $e');
      }
      return null;
    }
  }

  /// Submit an answer for a question
  Future<bool> submitAnswer({
    required String questionId,
    required String participantId,
    required int answerIndex,
  }) async {
    try {
      final question = await getLiveQuestion(questionId);
      if (question == null) return false;

      final updatedAnswers = Map<String, int>.from(question.participantAnswers);
      updatedAnswers[participantId] = answerIndex;

      final updatedQuestion = question.copyWith(
        participantAnswers: updatedAnswers,
        answeredAt: DateTime.now(),
      );

      await _saveLiveQuestion(updatedQuestion);

      // Update participant score
      await _updateParticipantScore(participantId, question, answerIndex);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting answer: $e');
      }
      return false;
    }
  }

  /// Get live session by ID
  Future<LiveSession?> getLiveSession(String sessionId) async {
    try {
      final sessions = await getAllLiveSessions();
      return sessions.firstWhere((session) => session.id == sessionId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting live session: $e');
      }
      return null;
    }
  }

  /// Get live question by ID
  Future<LiveQuestion?> getLiveQuestion(String questionId) async {
    try {
      final questions = await getAllLiveQuestions();
      return questions.firstWhere((question) => question.id == questionId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting live question: $e');
      }
      return null;
    }
  }

  /// Get all participants for a session
  Future<List<LiveParticipant>> getSessionParticipants(String sessionId) async {
    try {
      final participants = await getAllLiveParticipants();
      return participants.where((p) => p.sessionId == sessionId).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting session participants: $e');
      }
      return [];
    }
  }

  /// Get session leaderboard
  Future<List<LiveParticipant>> getSessionLeaderboard(String sessionId) async {
    try {
      final participants = await getSessionParticipants(sessionId);
      participants.sort((a, b) => b.score.compareTo(a.score));
      return participants;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting session leaderboard: $e');
      }
      return [];
    }
  }

  /// Leave a live session
  Future<bool> leaveSession({
    required String sessionId,
    required String participantId,
  }) async {
    try {
      final participant = await getLiveParticipant(participantId);
      if (participant == null) return false;

      final updatedParticipant = participant.copyWith(
        leftAt: DateTime.now(),
        isActive: false,
      );

      await _saveLiveParticipant(updatedParticipant);

      // Update session participant count
      final session = await getLiveSession(sessionId);
      if (session != null) {
        final updatedSession = session.copyWith(
          currentParticipants: session.currentParticipants - 1,
        );
        await _saveLiveSession(updatedSession);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error leaving session: $e');
      }
      return false;
    }
  }

  /// Get live session results
  Future<List<LiveSessionResult>> getSessionResults(String sessionId) async {
    try {
      final results = await getAllLiveResults();
      return results.where((result) => result.sessionId == sessionId).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting session results: $e');
      }
      return [];
    }
  }

  /// Save session results
  Future<void> saveSessionResults(String sessionId) async {
    try {
      final participants = await getSessionParticipants(sessionId);
      final session = await getLiveSession(sessionId);

      if (session == null) return;

      for (final participant in participants) {
        final result = LiveSessionResult(
          id: _generateId(),
          sessionId: sessionId,
          participantId: participant.id,
          participantName: participant.name,
          finalScore: participant.score,
          correctAnswers: participant.correctAnswers,
          totalQuestions: participant.totalQuestions,
          accuracy: participant.totalQuestions > 0
              ? participant.correctAnswers / participant.totalQuestions
              : 0.0,
          totalTime: session.startedAt != null && session.endedAt != null
              ? session.endedAt!.difference(session.startedAt!)
              : Duration.zero,
          completedAt: DateTime.now(),
        );

        await _saveLiveResult(result);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving session results: $e');
      }
    }
  }

  /// Get all live sessions
  Future<List<LiveSession>> getAllLiveSessions() async {
    try {
      // Try Hive first for better performance
      if (_hiveBox != null) {
        final sessionsData = _hiveBox.get(_liveSessionsKey);
        if (sessionsData != null) {
          final sessionsList = jsonDecode(sessionsData as String) as List;
          return sessionsList
              .map(
                (session) =>
                    LiveSession.fromJson(session as Map<String, dynamic>),
              )
              .toList();
        }
      }

      // Fallback to SharedPreferences
      final sessionsString = _prefs.getString(_liveSessionsKey);
      if (sessionsString == null) return [];

      final sessionsList = jsonDecode(sessionsString) as List;
      return sessionsList
          .map(
            (session) => LiveSession.fromJson(session as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all live sessions: $e');
      }
      return [];
    }
  }

  /// Get all live questions
  Future<List<LiveQuestion>> getAllLiveQuestions() async {
    try {
      final questionsString = _prefs.getString(_liveQuestionsKey);
      if (questionsString == null) return [];

      final questionsList = jsonDecode(questionsString) as List;
      return questionsList
          .map(
            (question) =>
                LiveQuestion.fromJson(question as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all live questions: $e');
      }
      return [];
    }
  }

  /// Get all live participants
  Future<List<LiveParticipant>> getAllLiveParticipants() async {
    try {
      final participantsString = _prefs.getString(_liveParticipantsKey);
      if (participantsString == null) return [];

      final participantsList = jsonDecode(participantsString) as List;
      return participantsList
          .map(
            (participant) =>
                LiveParticipant.fromJson(participant as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all live participants: $e');
      }
      return [];
    }
  }

  /// Get all live results
  Future<List<LiveSessionResult>> getAllLiveResults() async {
    try {
      final resultsString = _prefs.getString(_liveResultsKey);
      if (resultsString == null) return [];

      final resultsList = jsonDecode(resultsString) as List;
      return resultsList
          .map(
            (result) =>
                LiveSessionResult.fromJson(result as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all live results: $e');
      }
      return [];
    }
  }

  /// Get live participant by ID
  Future<LiveParticipant?> getLiveParticipant(String participantId) async {
    try {
      final participants = await getAllLiveParticipants();
      return participants.firstWhere((p) => p.id == participantId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting live participant: $e');
      }
      return null;
    }
  }

  /// Save live session
  Future<void> _saveLiveSession(LiveSession session) async {
    try {
      final sessions = await getAllLiveSessions();
      final existingIndex = sessions.indexWhere((s) => s.id == session.id);

      if (existingIndex >= 0) {
        sessions[existingIndex] = session;
      } else {
        sessions.add(session);
      }

      final sessionsJson = jsonEncode(sessions.map((s) => s.toJson()).toList());

      // Save to both Hive and SharedPreferences
      if (_hiveBox != null) {
        await _hiveBox.put(_liveSessionsKey, sessionsJson);
      }
      await _prefs.setString(_liveSessionsKey, sessionsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving live session: $e');
      }
    }
  }

  /// Save live question
  Future<void> _saveLiveQuestion(LiveQuestion question) async {
    try {
      final questions = await getAllLiveQuestions();
      final existingIndex = questions.indexWhere((q) => q.id == question.id);

      if (existingIndex >= 0) {
        questions[existingIndex] = question;
      } else {
        questions.add(question);
      }

      final questionsJson = jsonEncode(
        questions.map((q) => q.toJson()).toList(),
      );
      await _prefs.setString(_liveQuestionsKey, questionsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving live question: $e');
      }
    }
  }

  /// Save live participant
  Future<void> _saveLiveParticipant(LiveParticipant participant) async {
    try {
      final participants = await getAllLiveParticipants();
      final existingIndex = participants.indexWhere(
        (p) => p.id == participant.id,
      );

      if (existingIndex >= 0) {
        participants[existingIndex] = participant;
      } else {
        participants.add(participant);
      }

      final participantsJson = jsonEncode(
        participants.map((p) => p.toJson()).toList(),
      );
      await _prefs.setString(_liveParticipantsKey, participantsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving live participant: $e');
      }
    }
  }

  /// Save live result
  Future<void> _saveLiveResult(LiveSessionResult result) async {
    try {
      final results = await getAllLiveResults();
      results.add(result);

      final resultsJson = jsonEncode(results.map((r) => r.toJson()).toList());
      await _prefs.setString(_liveResultsKey, resultsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving live result: $e');
      }
    }
  }

  /// Update participant score
  Future<void> _updateParticipantScore(
    String participantId,
    LiveQuestion question,
    int answerIndex,
  ) async {
    try {
      final participant = await getLiveParticipant(participantId);
      if (participant == null) return;

      final isCorrect = answerIndex == question.correctAnswer;
      final points = isCorrect ? 10 : 0;

      final updatedParticipant = participant.copyWith(
        score: participant.score + points,
        correctAnswers: participant.correctAnswers + (isCorrect ? 1 : 0),
        totalQuestions: participant.totalQuestions + 1,
      );

      await _saveLiveParticipant(updatedParticipant);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating participant score: $e');
      }
    }
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  /// Generate QR code
  String _generateQRCode() {
    return 'MATH_GENIUS_${_generateId()}';
  }
}

/// Riverpod providers for live session management
final liveSessionServiceProvider = Provider<LiveSessionService>((ref) {
  throw UnimplementedError('LiveSessionService must be initialized');
});

final liveSessionsProvider = FutureProvider<List<LiveSession>>((ref) async {
  final liveSessionService = ref.read(liveSessionServiceProvider);
  return liveSessionService.getAllLiveSessions();
});

final liveSessionProvider = FutureProvider.family<LiveSession?, String>((
  ref,
  sessionId,
) async {
  final liveSessionService = ref.read(liveSessionServiceProvider);
  return liveSessionService.getLiveSession(sessionId);
});

final sessionParticipantsProvider =
    FutureProvider.family<List<LiveParticipant>, String>((
      ref,
      sessionId,
    ) async {
      final liveSessionService = ref.read(liveSessionServiceProvider);
      return liveSessionService.getSessionParticipants(sessionId);
    });

final sessionLeaderboardProvider =
    FutureProvider.family<List<LiveParticipant>, String>((
      ref,
      sessionId,
    ) async {
      final liveSessionService = ref.read(liveSessionServiceProvider);
      return liveSessionService.getSessionLeaderboard(sessionId);
    });

final sessionResultsProvider =
    FutureProvider.family<List<LiveSessionResult>, String>((
      ref,
      sessionId,
    ) async {
      final liveSessionService = ref.read(liveSessionServiceProvider);
      return liveSessionService.getSessionResults(sessionId);
    });
