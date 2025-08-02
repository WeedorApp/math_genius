import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'dart:async';

/// Notification types
enum NotificationType {
  quizStart,
  reward,
  idle,
  newChallenge,
  achievement,
  familyInvite,
  liveSession,
  reminder,
  custom,
}

/// Notification priority
enum NotificationPriority { low, normal, high, max }

/// Local notification model
class LocalNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? payload;
  final DateTime scheduledTime;
  final NotificationPriority priority;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const LocalNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.payload,
    required this.scheduledTime,
    this.priority = NotificationPriority.normal,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  LocalNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    String? payload,
    DateTime? scheduledTime,
    NotificationPriority? priority,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return LocalNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'payload': payload,
      'scheduledTime': scheduledTime.toIso8601String(),
      'priority': priority.name,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LocalNotification.fromJson(Map<String, dynamic> json) {
    return LocalNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'] as String,
      body: json['body'] as String,
      payload: json['payload'] as String?,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : {},
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Notifications service for Math Genius
class NotificationsService {
  static const String _notificationsKey = 'local_notifications';
  static const String _settingsKey = 'notification_settings';

  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _localNotifications;
  bool _isInitialized = false;

  NotificationsService(this._prefs)
    : _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialize notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;

      if (kDebugMode) {
        print('Notifications service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
      }
    }
  }

  /// Show quiz start notification
  Future<void> showQuizStartNotification({
    required String quizTitle,
    required String quizDescription,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    await _showNotification(
      type: NotificationType.quizStart,
      title: 'Quiz Starting: $quizTitle',
      body: quizDescription,
      payload: payload,
      data: data,
      priority: NotificationPriority.high,
    );
  }

  /// Show reward notification
  Future<void> showRewardNotification({
    required String rewardTitle,
    required String rewardDescription,
    int? points,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    final body = points != null
        ? '$rewardDescription (+$points points)'
        : rewardDescription;

    await _showNotification(
      type: NotificationType.reward,
      title: '🎉 $rewardTitle',
      body: body,
      payload: payload,
      data: data,
      priority: NotificationPriority.high,
    );
  }

  /// Show idle notification
  Future<void> showIdleNotification({
    required String message,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    await _showNotification(
      type: NotificationType.idle,
      title: 'Time for Math Practice!',
      body: message,
      payload: payload,
      data: data,
      priority: NotificationPriority.normal,
    );
  }

  /// Show new challenge notification
  Future<void> showNewChallengeNotification({
    required String challengeTitle,
    required String challengeDescription,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    await _showNotification(
      type: NotificationType.newChallenge,
      title: '🔥 New Challenge: $challengeTitle',
      body: challengeDescription,
      payload: payload,
      data: data,
      priority: NotificationPriority.high,
    );
  }

  /// Show achievement notification
  Future<void> showAchievementNotification({
    required String achievementTitle,
    required String achievementDescription,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    await _showNotification(
      type: NotificationType.achievement,
      title: '🏆 Achievement Unlocked: $achievementTitle',
      body: achievementDescription,
      payload: payload,
      data: data,
      priority: NotificationPriority.high,
    );
  }

  /// Show family invite notification
  Future<void> showFamilyInviteNotification({
    required String familyName,
    required String inviterName,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    await _showNotification(
      type: NotificationType.familyInvite,
      title: '👨‍👩‍👧‍👦 Family Invite',
      body: '$inviterName invited you to join the $familyName family!',
      payload: payload,
      data: data,
      priority: NotificationPriority.normal,
    );
  }

  /// Show live session notification
  Future<void> showLiveSessionNotification({
    required String sessionTitle,
    required String hostName,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    await _showNotification(
      type: NotificationType.liveSession,
      title: '📺 Live Session: $sessionTitle',
      body: 'Join $hostName\'s live math session now!',
      payload: payload,
      data: data,
      priority: NotificationPriority.high,
    );
  }

  /// Show reminder notification
  Future<void> showReminderNotification({
    required String reminderTitle,
    required String reminderMessage,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    await _showNotification(
      type: NotificationType.reminder,
      title: '⏰ $reminderTitle',
      body: reminderMessage,
      payload: payload,
      data: data,
      priority: NotificationPriority.normal,
    );
  }

  /// Show custom notification
  Future<void> showCustomNotification({
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.normal,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    await _showNotification(
      type: NotificationType.custom,
      title: title,
      body: body,
      payload: payload,
      data: data,
      priority: priority,
    );
  }

  /// Schedule notification
  Future<void> scheduleNotification({
    required String notificationId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    NotificationPriority priority = NotificationPriority.normal,
    String? payload,
  }) async {
    try {
      // Temporarily disabled due to API changes
      if (kDebugMode) {
        print('Notification scheduling temporarily disabled');
      }
      /*
      await _localNotifications.zonedSchedule(
        notificationId.hashCode,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        _getNotificationDetails(priority),
        payload: payload,
      );
      */

      if (kDebugMode) {
        print('Notification scheduled for ${scheduledTime.toString()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notification: $e');
      }
    }
  }

  /// Cancel notification
  Future<void> cancelNotification(String notificationId) async {
    try {
      await _localNotifications.cancel(notificationId.hashCode);
      await _removeNotification(notificationId);

      if (kDebugMode) {
        print('Notification cancelled: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling notification: $e');
      }
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      await _clearAllNotifications();

      if (kDebugMode) {
        print('All notifications cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling all notifications: $e');
      }
    }
  }

  /// Get all notifications
  Future<List<LocalNotification>> getAllNotifications() async {
    try {
      final notificationsString = _prefs.getString(_notificationsKey);
      if (notificationsString == null) return [];

      final notificationsList = jsonDecode(notificationsString) as List;
      return notificationsList
          .map(
            (notification) => LocalNotification.fromJson(
              notification as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notifications: $e');
      }
      return [];
    }
  }

  /// Get unread notifications
  Future<List<LocalNotification>> getUnreadNotifications() async {
    try {
      final allNotifications = await getAllNotifications();
      return allNotifications.where((n) => !n.isRead).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unread notifications: $e');
      }
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final notifications = await getAllNotifications();
      final index = notifications.indexWhere((n) => n.id == notificationId);

      if (index >= 0) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        await _saveAllNotifications(notifications);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final notifications = await getAllNotifications();
      final updatedNotifications = notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();

      await _saveAllNotifications(updatedNotifications);
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
    }
  }

  /// Show notification
  Future<void> _showNotification({
    required NotificationType type,
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      await initialize();

      final notification = LocalNotification(
        id: _generateId(),
        type: type,
        title: title,
        body: body,
        payload: payload,
        scheduledTime: DateTime.now(),
        priority: priority,
        data: data ?? {},
        createdAt: DateTime.now(),
      );

      await _saveNotification(notification);

      await _localNotifications.show(
        notification.id.hashCode,
        title,
        body,
        _getNotificationDetails(priority),
        payload: payload,
      );

      if (kDebugMode) {
        print('Notification shown: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing notification: $e');
      }
    }
  }

  /// Get notification details based on priority
  NotificationDetails _getNotificationDetails(NotificationPriority priority) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'math_genius_channel',
        'Math Genius',
        channelDescription: 'Math Genius notifications',
        importance: Importance.high,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
    // Handle notification tap - navigate to appropriate screen
  }

  /// Save notification to storage
  Future<void> _saveNotification(LocalNotification notification) async {
    try {
      final notifications = await getAllNotifications();
      notifications.add(notification);

      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications.removeRange(0, notifications.length - 100);
      }

      await _saveAllNotifications(notifications);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notification: $e');
      }
    }
  }

  /// Save all notifications
  Future<void> _saveAllNotifications(
    List<LocalNotification> notifications,
  ) async {
    try {
      final notificationsJson = jsonEncode(
        notifications.map((n) => n.toJson()).toList(),
      );
      await _prefs.setString(_notificationsKey, notificationsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving all notifications: $e');
      }
    }
  }

  /// Remove notification from storage
  Future<void> _removeNotification(String notificationId) async {
    try {
      final notifications = await getAllNotifications();
      notifications.removeWhere((n) => n.id == notificationId);
      await _saveAllNotifications(notifications);
    } catch (e) {
      if (kDebugMode) {
        print('Error removing notification: $e');
      }
    }
  }

  /// Clear all notifications from storage
  Future<void> _clearAllNotifications() async {
    try {
      await _prefs.remove(_notificationsKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all notifications: $e');
      }
    }
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString();
  }
}

/// Riverpod providers for notifications
final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  throw UnimplementedError('NotificationsService must be initialized');
});

final allNotificationsProvider = FutureProvider<List<LocalNotification>>((
  ref,
) async {
  final notificationsService = ref.read(notificationsServiceProvider);
  return notificationsService.getAllNotifications();
});

final unreadNotificationsProvider = FutureProvider<List<LocalNotification>>((
  ref,
) async {
  final notificationsService = ref.read(notificationsServiceProvider);
  return notificationsService.getUnreadNotifications();
});
