import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';

// Models
import '../models/family_model.dart';

/// Family Service for Math Genius
class FamilyService {
  static const String _parentAccountsKey = 'parent_accounts';
  static const String _studentProfilesKey = 'student_profiles';

  static const String _deviceSessionsKey = 'device_sessions';
  static const String _familyActivitiesKey = 'family_activities';

  final SharedPreferences _prefs;
  final Box? _hiveBox;
  final DeviceInfoPlugin _deviceInfo;

  FamilyService(this._prefs, this._hiveBox) : _deviceInfo = DeviceInfoPlugin();

  /// Create a new parent account
  Future<ParentAccount> createParentAccount({
    required String email,
    required String name,
    String? avatar,
    String? deviceId,
  }) async {
    try {
      final deviceId = await _getDeviceId();

      final parentAccount = ParentAccount(
        id: _generateId(),
        email: email,
        name: name,
        avatar: avatar,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        deviceId: deviceId,
      );

      await _saveParentAccount(parentAccount);
      await _logActivity(
        familyId: parentAccount.id,
        userId: parentAccount.id,
        activityType: 'parent_account_created',
      );

      return parentAccount;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating parent account: $e');
      }
      rethrow;
    }
  }

  /// Create a new student profile
  Future<StudentProfile> createStudentProfile({
    required String name,
    required int grade,
    required String parentId,
    String? avatar,
    String? pin,
    String? qrCode,
  }) async {
    try {
      final deviceId = await _getDeviceId();

      final studentProfile = StudentProfile(
        id: _generateId(),
        name: name,
        avatar: avatar,
        grade: grade,
        parentId: parentId,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        deviceId: deviceId,
        pin: pin ?? _generatePin(),
        qrCode: qrCode ?? _generateQRCode(),
      );

      await _saveStudentProfile(studentProfile);

      // Update parent account to include this student
      await _addStudentToParent(parentId, studentProfile.id);

      await _logActivity(
        familyId: parentId,
        userId: studentProfile.id,
        activityType: 'student_profile_created',
      );

      return studentProfile;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating student profile: $e');
      }
      rethrow;
    }
  }

  /// Get parent account by ID
  Future<ParentAccount?> getParentAccount(String parentId) async {
    try {
      final accounts = await getAllParentAccounts();
      return accounts.firstWhere((account) => account.id == parentId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting parent account: $e');
      }
      return null;
    }
  }

  /// Get student profile by ID
  Future<StudentProfile?> getStudentProfile(String studentId) async {
    try {
      final profiles = await getAllStudentProfiles();
      return profiles.firstWhere((profile) => profile.id == studentId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting student profile: $e');
      }
      return null;
    }
  }

  /// Get all students for a parent
  Future<List<StudentProfile>> getStudentsForParent(String parentId) async {
    try {
      final profiles = await getAllStudentProfiles();
      return profiles.where((profile) => profile.parentId == parentId).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting students for parent: $e');
      }
      return [];
    }
  }

  /// Update user status
  Future<void> updateUserStatus(String userId, UserStatus status) async {
    try {
      // Update parent account if exists
      final parentAccount = await getParentAccount(userId);
      if (parentAccount != null) {
        final updatedAccount = parentAccount.copyWith(
          status: status,
          lastActive: DateTime.now(),
        );
        await _saveParentAccount(updatedAccount);
      }

      // Update student profile if exists
      final studentProfile = await getStudentProfile(userId);
      if (studentProfile != null) {
        final updatedProfile = studentProfile.copyWith(
          status: status,
          lastActive: DateTime.now(),
        );
        await _saveStudentProfile(updatedProfile);
      }

      await _logActivity(
        familyId: parentAccount?.id ?? studentProfile?.parentId ?? userId,
        userId: userId,
        activityType: 'status_updated',
        metadata: {'status': status.name},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user status: $e');
      }
    }
  }

  /// Authenticate user
  Future<({bool success, String? userId, UserRole? role})> authenticateUser({
    String? email,
    String? pin,
    String? qrCode,
  }) async {
    try {
      if (email != null) {
        // Parent authentication
        final accounts = await getAllParentAccounts();
        final account = accounts.firstWhere(
          (acc) => acc.email.toLowerCase() == email.toLowerCase(),
        );

        await updateUserStatus(account.id, UserStatus.online);
        return (success: true, userId: account.id, role: account.role);
      } else if (pin != null) {
        // Student PIN authentication
        final profiles = await getAllStudentProfiles();
        final profile = profiles.firstWhere((prof) => prof.pin == pin);

        await updateUserStatus(profile.id, UserStatus.online);
        return (success: true, userId: profile.id, role: profile.role);
      } else if (qrCode != null) {
        // Student QR authentication
        final profiles = await getAllStudentProfiles();
        final profile = profiles.firstWhere((prof) => prof.qrCode == qrCode);

        await updateUserStatus(profile.id, UserStatus.online);
        return (success: true, userId: profile.id, role: profile.role);
      }

      return (success: false, userId: null, role: null);
    } catch (e) {
      if (kDebugMode) {
        print('Error authenticating user: $e');
      }
      return (success: false, userId: null, role: null);
    }
  }

  /// Check device lock (one device per user)
  Future<bool> isDeviceLocked(String userId) async {
    try {
      final deviceId = await _getDeviceId();

      // Check if user is already logged in on another device
      final sessions = await getDeviceSessionsForUser(userId);
      final activeSession = sessions.firstWhere(
        (session) => session.isActive && session.deviceId != deviceId,
        orElse: () => DeviceSession(
          id: '',
          userId: '',
          deviceId: '',
          deviceName: '',
          platform: '',
          loginTime: DateTime.now(),
        ),
      );

      return activeSession.id.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking device lock: $e');
      }
      return false;
    }
  }

  /// Create device session
  Future<DeviceSession> createDeviceSession(String userId) async {
    try {
      final deviceId = await _getDeviceId();
      final deviceName = await _getDeviceName();
      final platform = await _getPlatform();

      final session = DeviceSession(
        id: _generateId(),
        userId: userId,
        deviceId: deviceId,
        deviceName: deviceName,
        platform: platform,
        loginTime: DateTime.now(),
      );

      await _saveDeviceSession(session);
      return session;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating device session: $e');
      }
      rethrow;
    }
  }

  /// End device session
  Future<void> endDeviceSession(String sessionId) async {
    try {
      final sessions = await getAllDeviceSessions();
      final sessionIndex = sessions.indexWhere((s) => s.id == sessionId);

      if (sessionIndex >= 0) {
        final session = sessions[sessionIndex];
        final updatedSession = session.copyWith(
          logoutTime: DateTime.now(),
          isActive: false,
        );

        sessions[sessionIndex] = updatedSession;
        await _saveAllDeviceSessions(sessions);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error ending device session: $e');
      }
    }
  }

  /// Get device sessions for user
  Future<List<DeviceSession>> getDeviceSessionsForUser(String userId) async {
    try {
      final sessions = await getAllDeviceSessions();
      return sessions.where((session) => session.userId == userId).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device sessions for user: $e');
      }
      return [];
    }
  }

  /// Update student progress
  Future<void> updateStudentProgress(
    String studentId,
    String subject,
    int progress,
  ) async {
    try {
      final profile = await getStudentProfile(studentId);
      if (profile == null) return;

      final updatedProgress = Map<String, int>.from(profile.subjectProgress);
      updatedProgress[subject] = progress;

      final updatedProfile = profile.copyWith(
        subjectProgress: updatedProgress,
        lastActive: DateTime.now(),
      );

      await _saveStudentProfile(updatedProfile);

      await _logActivity(
        familyId: profile.parentId,
        userId: studentId,
        activityType: 'progress_updated',
        metadata: {'subject': subject, 'progress': progress},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating student progress: $e');
      }
    }
  }

  /// Get family activities
  Future<List<FamilyActivity>> getFamilyActivities(String familyId) async {
    try {
      final activitiesString = _prefs.getString(_familyActivitiesKey);
      if (activitiesString == null) return [];

      final activitiesList = jsonDecode(activitiesString) as List;
      final allActivities = activitiesList
          .map(
            (activity) =>
                FamilyActivity.fromJson(activity as Map<String, dynamic>),
          )
          .toList();

      return allActivities
          .where((activity) => activity.familyId == familyId)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting family activities: $e');
      }
      return [];
    }
  }

  /// Get all parent accounts
  Future<List<ParentAccount>> getAllParentAccounts() async {
    try {
      // Try Hive first for better performance
      if (_hiveBox != null) {
        final accountsData = _hiveBox.get(_parentAccountsKey);
        if (accountsData != null) {
          final accountsList = jsonDecode(accountsData as String) as List;
          return accountsList
              .map(
                (account) =>
                    ParentAccount.fromJson(account as Map<String, dynamic>),
              )
              .toList();
        }
      }

      // Fallback to SharedPreferences
      final accountsString = _prefs.getString(_parentAccountsKey);
      if (accountsString == null) return [];

      final accountsList = jsonDecode(accountsString) as List;
      return accountsList
          .map(
            (account) =>
                ParentAccount.fromJson(account as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all parent accounts: $e');
      }
      return [];
    }
  }

  /// Get all student profiles
  Future<List<StudentProfile>> getAllStudentProfiles() async {
    try {
      // Try Hive first for better performance
      if (_hiveBox != null) {
        final profilesData = _hiveBox.get(_studentProfilesKey);
        if (profilesData != null) {
          final profilesList = jsonDecode(profilesData as String) as List;
          return profilesList
              .map(
                (profile) =>
                    StudentProfile.fromJson(profile as Map<String, dynamic>),
              )
              .toList();
        }
      }

      // Fallback to SharedPreferences
      final profilesString = _prefs.getString(_studentProfilesKey);
      if (profilesString == null) return [];

      final profilesList = jsonDecode(profilesString) as List;
      return profilesList
          .map(
            (profile) =>
                StudentProfile.fromJson(profile as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all student profiles: $e');
      }
      return [];
    }
  }

  /// Get all device sessions
  Future<List<DeviceSession>> getAllDeviceSessions() async {
    try {
      final sessionsString = _prefs.getString(_deviceSessionsKey);
      if (sessionsString == null) return [];

      final sessionsList = jsonDecode(sessionsString) as List;
      return sessionsList
          .map(
            (session) =>
                DeviceSession.fromJson(session as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all device sessions: $e');
      }
      return [];
    }
  }

  /// Save parent account
  Future<void> _saveParentAccount(ParentAccount account) async {
    try {
      final accounts = await getAllParentAccounts();
      final existingIndex = accounts.indexWhere((acc) => acc.id == account.id);

      if (existingIndex >= 0) {
        accounts[existingIndex] = account;
      } else {
        accounts.add(account);
      }

      final accountsJson = jsonEncode(
        accounts.map((acc) => acc.toJson()).toList(),
      );

      // Save to both Hive and SharedPreferences
      if (_hiveBox != null) {
        await _hiveBox.put(_parentAccountsKey, accountsJson);
      }
      await _prefs.setString(_parentAccountsKey, accountsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving parent account: $e');
      }
    }
  }

  /// Save student profile
  Future<void> _saveStudentProfile(StudentProfile profile) async {
    try {
      final profiles = await getAllStudentProfiles();
      final existingIndex = profiles.indexWhere(
        (prof) => prof.id == profile.id,
      );

      if (existingIndex >= 0) {
        profiles[existingIndex] = profile;
      } else {
        profiles.add(profile);
      }

      final profilesJson = jsonEncode(
        profiles.map((prof) => prof.toJson()).toList(),
      );

      // Save to both Hive and SharedPreferences
      if (_hiveBox != null) {
        await _hiveBox.put(_studentProfilesKey, profilesJson);
      }
      await _prefs.setString(_studentProfilesKey, profilesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving student profile: $e');
      }
    }
  }

  /// Save device session
  Future<void> _saveDeviceSession(DeviceSession session) async {
    try {
      final sessions = await getAllDeviceSessions();
      final existingIndex = sessions.indexWhere((s) => s.id == session.id);

      if (existingIndex >= 0) {
        sessions[existingIndex] = session;
      } else {
        sessions.add(session);
      }

      await _saveAllDeviceSessions(sessions);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving device session: $e');
      }
    }
  }

  /// Save all device sessions
  Future<void> _saveAllDeviceSessions(List<DeviceSession> sessions) async {
    try {
      final sessionsJson = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await _prefs.setString(_deviceSessionsKey, sessionsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving all device sessions: $e');
      }
    }
  }

  /// Add student to parent
  Future<void> _addStudentToParent(String parentId, String studentId) async {
    try {
      final parent = await getParentAccount(parentId);
      if (parent == null) return;

      final updatedStudentIds = List<String>.from(parent.studentIds);
      if (!updatedStudentIds.contains(studentId)) {
        updatedStudentIds.add(studentId);
      }

      final updatedParent = parent.copyWith(studentIds: updatedStudentIds);
      await _saveParentAccount(updatedParent);
    } catch (e) {
      if (kDebugMode) {
        print('Error adding student to parent: $e');
      }
    }
  }

  /// Log family activity
  Future<void> _logActivity({
    required String familyId,
    required String userId,
    required String activityType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activity = FamilyActivity(
        id: _generateId(),
        familyId: familyId,
        userId: userId,
        activityType: activityType,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
      );

      final activities = await _getAllFamilyActivities();
      activities.add(activity);

      final activitiesJson = jsonEncode(
        activities.map((a) => a.toJson()).toList(),
      );
      await _prefs.setString(_familyActivitiesKey, activitiesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error logging family activity: $e');
      }
    }
  }

  /// Get all family activities
  Future<List<FamilyActivity>> _getAllFamilyActivities() async {
    try {
      final activitiesString = _prefs.getString(_familyActivitiesKey);
      if (activitiesString == null) return [];

      final activitiesList = jsonDecode(activitiesString) as List;
      return activitiesList
          .map(
            (activity) =>
                FamilyActivity.fromJson(activity as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all family activities: $e');
      }
      return [];
    }
  }

  /// Get device ID
  Future<String> _getDeviceId() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      } else {
        return 'web_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get device name
  Future<String> _getDeviceName() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model}';
      } else {
        return 'Web Browser';
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Get platform
  Future<String> _getPlatform() async {
    return defaultTargetPlatform.name;
  }

  /// Generate PIN
  String _generatePin() {
    return (Random().nextInt(9000) + 1000).toString();
  }

  /// Generate QR code
  String _generateQRCode() {
    return 'QR_${_generateId()}';
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }
}

/// Riverpod providers for family management
final familyServiceProvider = Provider<FamilyService>((ref) {
  throw UnimplementedError('FamilyService must be initialized');
});

final parentAccountsProvider = FutureProvider<List<ParentAccount>>((ref) async {
  final familyService = ref.read(familyServiceProvider);
  return familyService.getAllParentAccounts();
});

final studentProfilesProvider = FutureProvider<List<StudentProfile>>((
  ref,
) async {
  final familyService = ref.read(familyServiceProvider);
  return familyService.getAllStudentProfiles();
});

final studentsForParentProvider =
    FutureProvider.family<List<StudentProfile>, String>((ref, parentId) async {
      final familyService = ref.read(familyServiceProvider);
      return familyService.getStudentsForParent(parentId);
    });

final familyActivitiesProvider =
    FutureProvider.family<List<FamilyActivity>, String>((ref, familyId) async {
      final familyService = ref.read(familyServiceProvider);
      return familyService.getFamilyActivities(familyId);
    });

final deviceSessionsProvider =
    FutureProvider.family<List<DeviceSession>, String>((ref, userId) async {
      final familyService = ref.read(familyServiceProvider);
      return familyService.getDeviceSessionsForUser(userId);
    });
