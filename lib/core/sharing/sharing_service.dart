import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

/// Sharing types
enum SharingType { qr, deepLink, shareIntent, email, sms }

/// Share content types
enum ShareContentType {
  gameSession,
  quizResult,
  achievement,
  familyInvite,
  liveSession,
  progressReport,
  custom,
}

/// Share content model
class ShareContent {
  final String id;
  final ShareContentType type;
  final String title;
  final String description;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final String? userId;
  final String? sessionId;

  const ShareContent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.imageUrl,
    this.data = const {},
    required this.createdAt,
    this.userId,
    this.sessionId,
  });

  ShareContent copyWith({
    String? id,
    ShareContentType? type,
    String? title,
    String? description,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    String? userId,
    String? sessionId,
  }) {
    return ShareContent(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'sessionId': sessionId,
    };
  }

  factory ShareContent.fromJson(Map<String, dynamic> json) {
    return ShareContent(
      id: json['id'] as String,
      type: ShareContentType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      userId: json['userId'] as String?,
      sessionId: json['sessionId'] as String?,
    );
  }
}

/// Sharing service for Math Genius
class SharingService {
  static const String _shareHistoryKey = 'share_history';
  static const String _qrCodesKey = 'qr_codes';

  final SharedPreferences _prefs;

  SharingService(this._prefs);

  /// Generate QR code for content
  Future<String> generateQRCode(ShareContent content) async {
    try {
      final qrData = {
        'type': content.type.name,
        'id': content.id,
        'title': content.title,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final qrCode = _encodeQRData(qrData);
      await _saveQRCode(content.id, qrCode);

      return qrCode;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating QR code: $e');
      }
      rethrow;
    }
  }

  /// Generate deep link for content
  Future<String> generateDeepLink(ShareContent content) async {
    try {
      final baseUrl = 'mathgenius://share';
      final params = {
        'type': content.type.name,
        'id': content.id,
        'title': Uri.encodeComponent(content.title),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final queryString = params.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      return '$baseUrl?$queryString';
    } catch (e) {
      if (kDebugMode) {
        print('Error generating deep link: $e');
      }
      rethrow;
    }
  }

  /// Create share content for game session
  Future<ShareContent> createGameSessionShare({
    required String sessionId,
    required String gameType,
    required int score,
    required Duration timeSpent,
    String? userId,
  }) async {
    return ShareContent(
      id: _generateId(),
      type: ShareContentType.gameSession,
      title: 'Math Genius Game Session',
      description:
          'I scored $score points in $gameType! Can you beat my score?',
      data: {
        'gameType': gameType,
        'score': score,
        'timeSpent': timeSpent.inMilliseconds,
        'sessionId': sessionId,
      },
      createdAt: DateTime.now(),
      userId: userId,
      sessionId: sessionId,
    );
  }

  /// Create share content for quiz result
  Future<ShareContent> createQuizResultShare({
    required String quizId,
    required int correctAnswers,
    required int totalQuestions,
    required Duration timeSpent,
    String? userId,
  }) async {
    final accuracy = (correctAnswers / totalQuestions * 100).round();
    return ShareContent(
      id: _generateId(),
      type: ShareContentType.quizResult,
      title: 'Math Genius Quiz Result',
      description:
          'I got $correctAnswers out of $totalQuestions correct ($accuracy%)!',
      data: {
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'accuracy': accuracy,
        'timeSpent': timeSpent.inMilliseconds,
        'quizId': quizId,
      },
      createdAt: DateTime.now(),
      userId: userId,
      sessionId: quizId,
    );
  }

  /// Create share content for achievement
  Future<ShareContent> createAchievementShare({
    required String achievementId,
    required String achievementName,
    required String achievementDescription,
    int? points,
    String? userId,
  }) async {
    return ShareContent(
      id: _generateId(),
      type: ShareContentType.achievement,
      title: 'Math Genius Achievement Unlocked!',
      description: 'I earned the "$achievementName" achievement!',
      data: {
        'achievementId': achievementId,
        'achievementName': achievementName,
        'achievementDescription': achievementDescription,
        'points': points,
      },
      createdAt: DateTime.now(),
      userId: userId,
    );
  }

  /// Create share content for family invite
  Future<ShareContent> createFamilyInviteShare({
    required String familyId,
    required String familyName,
    String? inviteCode,
    String? userId,
  }) async {
    return ShareContent(
      id: _generateId(),
      type: ShareContentType.familyInvite,
      title: 'Join My Math Genius Family!',
      description:
          'Join the $familyName family on Math Genius and learn together!',
      data: {
        'familyId': familyId,
        'familyName': familyName,
        'inviteCode': inviteCode,
      },
      createdAt: DateTime.now(),
      userId: userId,
    );
  }

  /// Create share content for live session
  Future<ShareContent> createLiveSessionShare({
    required String sessionId,
    required String sessionTitle,
    required String hostName,
    String? password,
    String? userId,
  }) async {
    return ShareContent(
      id: _generateId(),
      type: ShareContentType.liveSession,
      title: 'Join My Live Math Session!',
      description: 'Join $hostName\'s live session: "$sessionTitle"',
      data: {
        'sessionId': sessionId,
        'sessionTitle': sessionTitle,
        'hostName': hostName,
        'password': password,
      },
      createdAt: DateTime.now(),
      userId: userId,
      sessionId: sessionId,
    );
  }

  /// Create share content for progress report
  Future<ShareContent> createProgressReportShare({
    required String userId,
    required Map<String, dynamic> progressData,
    String? reportTitle,
  }) async {
    return ShareContent(
      id: _generateId(),
      type: ShareContentType.progressReport,
      title: reportTitle ?? 'My Math Genius Progress Report',
      description: 'Check out my learning progress on Math Genius!',
      data: progressData,
      createdAt: DateTime.now(),
      userId: userId,
    );
  }

  /// Create custom share content
  Future<ShareContent> createCustomShare({
    required String title,
    required String description,
    Map<String, dynamic>? data,
    String? userId,
  }) async {
    return ShareContent(
      id: _generateId(),
      type: ShareContentType.custom,
      title: title,
      description: description,
      data: data ?? {},
      createdAt: DateTime.now(),
      userId: userId,
    );
  }

  /// Get share history
  Future<List<ShareContent>> getShareHistory({String? userId}) async {
    try {
      final historyString = _prefs.getString(_shareHistoryKey);
      if (historyString == null) return [];

      final historyList = jsonDecode(historyString) as List;
      final allContent = historyList
          .map((item) => ShareContent.fromJson(item as Map<String, dynamic>))
          .toList();

      if (userId != null) {
        return allContent.where((content) => content.userId == userId).toList();
      }

      return allContent;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting share history: $e');
      }
      return [];
    }
  }

  /// Save share content to history
  Future<void> saveToHistory(ShareContent content) async {
    try {
      final history = await getShareHistory();
      history.add(content);

      // Keep only last 100 items
      if (history.length > 100) {
        history.removeRange(0, history.length - 100);
      }

      final historyJson = jsonEncode(history.map((c) => c.toJson()).toList());
      await _prefs.setString(_shareHistoryKey, historyJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving to history: $e');
      }
    }
  }

  /// Get QR code for content
  Future<String?> getQRCode(String contentId) async {
    try {
      final qrCodesString = _prefs.getString(_qrCodesKey);
      if (qrCodesString == null) return null;

      final qrCodes = jsonDecode(qrCodesString) as Map<String, dynamic>;
      return qrCodes[contentId] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting QR code: $e');
      }
      return null;
    }
  }

  /// Save QR code
  Future<void> _saveQRCode(String contentId, String qrCode) async {
    try {
      final qrCodesString = _prefs.getString(_qrCodesKey);
      final qrCodes = qrCodesString != null
          ? Map<String, dynamic>.from(jsonDecode(qrCodesString) as Map)
          : <String, dynamic>{};

      qrCodes[contentId] = qrCode;

      final qrCodesJson = jsonEncode(qrCodes);
      await _prefs.setString(_qrCodesKey, qrCodesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving QR code: $e');
      }
    }
  }

  /// Encode data for QR code
  String _encodeQRData(Map<String, dynamic> data) {
    // Simple base64-like encoding for demo
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    return base64.encode(bytes);
  }

  /// Decode QR code data
  Map<String, dynamic>? decodeQRData(String qrCode) {
    try {
      final bytes = base64.decode(qrCode);
      final jsonString = utf8.decode(bytes);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding QR data: $e');
      }
      return null;
    }
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  /// Clear share history
  Future<void> clearHistory() async {
    try {
      await _prefs.remove(_shareHistoryKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing history: $e');
      }
    }
  }

  /// Clear QR codes
  Future<void> clearQRCodes() async {
    try {
      await _prefs.remove(_qrCodesKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing QR codes: $e');
      }
    }
  }
}

/// Riverpod providers for sharing
final sharingServiceProvider = Provider<SharingService>((ref) {
  throw UnimplementedError('SharingService must be initialized');
});

final shareHistoryProvider = FutureProvider.family<List<ShareContent>, String?>(
  (ref, userId) async {
    final sharingService = ref.read(sharingServiceProvider);
    return sharingService.getShareHistory(userId: userId);
  },
);
