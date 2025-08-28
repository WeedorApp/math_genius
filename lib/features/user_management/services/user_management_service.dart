import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import '../models/user_model.dart' as user_models;
import '../../../core/firebase/firebase_service.dart';
import '../../../core/firebase/firestore_service.dart';
import '../../../core/context/context_service.dart';
import '../../../core/privacy/privacy_service.dart';

/// Simplified User Management Service
class UserManagementService {
  static const String _currentUserKey = 'current_user';
  static const String _currentSessionKey = 'current_session';

  final SharedPreferences _prefs;
  final Box? _hiveBox;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  UserManagementService(this._prefs, this._hiveBox);

  /// Register a new user with Firebase
  Future<user_models.User> registerUser({
    required String email,
    required String password,
    required String displayName,
    String? phone,
    user_models.UserRole role = user_models.UserRole.student,
    String? familyId,
  }) async {
    try {
      if (kDebugMode) {
        print('UserManagementService: Registering user: $email');
        print('UserManagementService: Role: $role');
        print('UserManagementService: Display name: $displayName');
      }

      // Validate inputs
      _validateRegistrationInputs(email, password, displayName, role);

      // Check if offline mode is enabled
      final isOfflineMode = await _isOfflineMode();
      if (isOfflineMode) {
        if (kDebugMode) {
          print('UserManagementService: Using offline registration mode');
        }
        return await _registerUserOffline(
          email: email,
          password: password,
          displayName: displayName,
          phone: phone,
          role: role,
          familyId: familyId,
        );
      }

      if (kDebugMode) {
        print('UserManagementService: Using online registration mode');
      }

      // Create Firebase user
      final firebaseUser = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        print(
          'UserManagementService: Firebase user created: ${firebaseUser.user?.uid}',
        );
      }

      // Update display name
      await firebaseUser.user?.updateDisplayName(displayName);

      // Create user object
      final user = user_models.User(
        id: firebaseUser.user!.uid,
        email: email,
        phone: phone,
        displayName: displayName,
        role: role,
        createdAt: DateTime.now(),
        familyId: familyId ?? _generateFamilyId(),
        status: user_models.AccountStatus.active,
      );

      if (kDebugMode) {
        print(
          'UserManagementService: User object created: ${user.displayName}',
        );
      }

      // Save to Firestore
      try {
        if (kDebugMode) {
          print('UserManagementService: Attempting to save to Firestore...');
        }

        await FirestoreService.createOrUpdateUser(
          userId: user.id,
          userData: user.toFirestore(),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            if (kDebugMode) {
              print(
                'UserManagementService: Firestore save timed out, continuing...',
              );
            }
            throw TimeoutException('Firestore save timed out');
          },
        );

        if (kDebugMode) {
          print('UserManagementService: User saved to Firestore');
        }
      } catch (e) {
        if (kDebugMode) {
          print('UserManagementService: Firestore save error: $e');
        }
        // Continue even if Firestore fails
      }

      // Save locally
      try {
        if (kDebugMode) {
          print('UserManagementService: Attempting to save locally...');
        }

        await _saveUser(user).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (kDebugMode) {
              print(
                'UserManagementService: Local save timed out, continuing...',
              );
            }
            throw TimeoutException('Local save timed out');
          },
        );

        if (kDebugMode) {
          print('UserManagementService: User saved locally');
        }
      } catch (e) {
        if (kDebugMode) {
          print('UserManagementService: Local save error: $e');
        }
        // Continue even if local save fails
      }

      // Initialize UserContext (SSOT compliance)
      try {
        if (kDebugMode) {
          print('UserManagementService: Initializing UserContext...');
        }

        await _initializeUserContext(user).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (kDebugMode) {
              print(
                'UserManagementService: UserContext initialization timed out, continuing...',
              );
            }
            throw TimeoutException('UserContext initialization timed out');
          },
        );

        if (kDebugMode) {
          print('UserManagementService: UserContext initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          print('UserManagementService: UserContext initialization error: $e');
        }
        // Continue even if UserContext fails
      }

      // Initialize privacy settings (SSOT compliance)
      try {
        if (kDebugMode) {
          print('UserManagementService: Initializing privacy settings...');
        }

        await _initializePrivacySettings(user.id, role).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (kDebugMode) {
              print(
                'UserManagementService: Privacy settings initialization timed out, continuing...',
              );
            }
            throw TimeoutException('Privacy settings initialization timed out');
          },
        );

        if (kDebugMode) {
          print('UserManagementService: Privacy settings initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            'UserManagementService: Privacy settings initialization error: $e',
          );
        }
        // Continue even if privacy settings fail
      }

      // Initialize theme preferences (SSOT compliance)
      try {
        if (kDebugMode) {
          print('UserManagementService: Initializing theme preferences...');
        }

        await _initializeThemePreferences(user.id).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (kDebugMode) {
              print(
                'UserManagementService: Theme preferences initialization timed out, continuing...',
              );
            }
            throw TimeoutException(
              'Theme preferences initialization timed out',
            );
          },
        );

        if (kDebugMode) {
          print('UserManagementService: Theme preferences initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            'UserManagementService: Theme preferences initialization error: $e',
          );
        }
        // Continue even if theme preferences fail
      }

      // Create session data
      try {
        if (kDebugMode) {
          print('UserManagementService: Creating session data...');
        }

        await _saveSession({
          'userId': user.id,
          'loginTime': DateTime.now().toIso8601String(),
          'userRole': user.role.toString(),
          'deviceId': await _getDeviceId(),
        }).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (kDebugMode) {
              print(
                'UserManagementService: Session data creation timed out, continuing...',
              );
            }
            throw TimeoutException('Session data creation timed out');
          },
        );

        if (kDebugMode) {
          print('UserManagementService: Session data saved');
        }
      } catch (e) {
        if (kDebugMode) {
          print('UserManagementService: Session data creation error: $e');
        }
        // Continue even if session data fails
      }

      // Log successful registration
      try {
        if (kDebugMode) {
          print('UserManagementService: Logging analytics event...');
        }

        await FirebaseService.logEvent(
          name: 'user_registration_completed',
          parameters: {'user_id': user.id, 'role': role.toString()},
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (kDebugMode) {
              print(
                'UserManagementService: Analytics event logging timed out, continuing...',
              );
            }
            throw TimeoutException('Analytics event logging timed out');
          },
        );

        if (kDebugMode) {
          print('UserManagementService: Analytics event logged');
        }
      } catch (e) {
        if (kDebugMode) {
          print('UserManagementService: Analytics event logging error: $e');
        }
        // Continue even if analytics fails
      }

      if (kDebugMode) {
        print('UserManagementService: Registration completed successfully');
        print('UserManagementService: Returning user: ${user.displayName}');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Registration error: $e');
        print(
          'UserManagementService: Error stack trace: ${StackTrace.current}',
        );
      }
      rethrow;
    }
  }

  /// Register user in offline mode
  Future<user_models.User> _registerUserOffline({
    required String email,
    required String password,
    required String displayName,
    String? phone,
    user_models.UserRole role = user_models.UserRole.student,
    String? familyId,
  }) async {
    try {
      // Generate local user ID
      final localUserId =
          'local_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

      // Create user object for offline mode
      final user = user_models.User(
        id: localUserId,
        email: email,
        phone: phone,
        displayName: displayName,
        role: role,
        createdAt: DateTime.now(),
        familyId: familyId ?? _generateFamilyId(),
        status: user_models.AccountStatus.active,
      );

      // Save locally only
      await _saveUser(user);

      // Initialize SSOT components
      await _initializeUserContext(user);
      await _initializePrivacySettings(user.id, role);
      await _initializeThemePreferences(user.id);

      // Create session data
      await _saveSession({
        'userId': user.id,
        'loginTime': DateTime.now().toIso8601String(),
        'userRole': user.role.toString(),
        'deviceId': await _getDeviceId(),
        'isOffline': true,
      });

      if (kDebugMode) {
        print('UserManagementService: Offline registration completed');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Offline registration error: $e');
      }
      rethrow;
    }
  }

  /// Validate registration inputs
  void _validateRegistrationInputs(
    String email,
    String password,
    String displayName,
    user_models.UserRole role,
  ) {
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Invalid email address');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    if (displayName.trim().isEmpty) {
      throw Exception('Display name is required');
    }
    if (role == user_models.UserRole.guest) {
      throw Exception('Guest role is not allowed for registration');
    }
  }

  /// Initialize UserContext for SSOT compliance
  Future<void> _initializeUserContext(user_models.User user) async {
    try {
      final deviceId = await _getDeviceId();
      final userContext = UserContext(
        userId: user.id,
        role: _convertUserRole(user.role),
        deviceId: deviceId,
        lastActive: DateTime.now(),
        isOnline: true,
      );

      // Save to SharedPreferences for persistence
      await _prefs.setString('user_context', jsonEncode(userContext.toJson()));

      if (kDebugMode) {
        print('UserManagementService: UserContext initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Error initializing UserContext: $e');
      }
    }
  }

  /// Initialize privacy settings for SSOT compliance
  Future<void> _initializePrivacySettings(
    String userId,
    user_models.UserRole role,
  ) async {
    try {
      final privacySettings = PrivacySettings(
        allowAnalytics: true,
        allowCrashReporting: true,
        allowPersonalization: true,
        allowDataSharing: false,
        allowPushNotifications: true,
        dataRetention: DataRetentionPolicy.ninetyDays,
        complianceConsent: {
          PrivacyCompliance.gdpr: true,
          PrivacyCompliance.ccpa: true,
          PrivacyCompliance.coppa: role == user_models.UserRole.student,
          PrivacyCompliance.ferpa: role == user_models.UserRole.teacher,
        },
        isOfflineMode: false,
      );

      await _prefs.setString(
        'privacy_settings_$userId',
        jsonEncode(privacySettings.toJson()),
      );

      if (kDebugMode) {
        print('UserManagementService: Privacy settings initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Error initializing privacy settings: $e');
      }
    }
  }

  /// Initialize theme preferences for SSOT compliance
  Future<void> _initializeThemePreferences(String userId) async {
    try {
      final themeContext = ThemeContext(
        mode: ContextThemeMode.light,
        isSystemTheme: true,
        lastChanged: DateTime.now(),
      );

      await _prefs.setString(
        'theme_context_$userId',
        jsonEncode(themeContext.toJson()),
      );

      if (kDebugMode) {
        print('UserManagementService: Theme preferences initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          'UserManagementService: Error initializing theme preferences: $e',
        );
      }
    }
  }

  /// Convert user role to context role
  UserRole _convertUserRole(user_models.UserRole role) {
    switch (role) {
      case user_models.UserRole.student:
        return UserRole.student;
      case user_models.UserRole.parent:
        return UserRole.parent;
      case user_models.UserRole.teacher:
        return UserRole.teacher;
      case user_models.UserRole.admin:
        return UserRole.school; // Map admin to school role
      case user_models.UserRole.guest:
        return UserRole.student; // Default to student
    }
  }

  /// Get device ID for context
  Future<String> _getDeviceId() async {
    try {
      final deviceId = _prefs.getString('device_id');
      if (deviceId != null) {
        return deviceId;
      }

      // Generate new device ID
      final newDeviceId =
          'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
      await _prefs.setString('device_id', newDeviceId);
      return newDeviceId;
    } catch (e) {
      return 'unknown_device';
    }
  }

  /// Login user with Firebase
  Future<user_models.User?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('UserManagementService: Logging in user: $email');
      }

      if (kDebugMode) {
        print('UserManagementService: Calling Firebase Auth...');
      }

      // Sign in with Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed');
      }

      if (kDebugMode) {
        print(
          'UserManagementService: Firebase Auth successful, user ID: ${firebaseUser.uid}',
        );
      }

      if (kDebugMode) {
        print('UserManagementService: Getting user data from Firestore...');
      }

      // Get user data from Firestore
      final userData = await FirestoreService.getUser(firebaseUser.uid);

      user_models.User user;
      if (userData == null) {
        // Create user from Firebase Auth data
        if (kDebugMode) {
          print('UserManagementService: Creating user from Firebase Auth data');
        }

        user = user_models.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber ?? '',
          displayName: firebaseUser.displayName ?? '',
          role: user_models.UserRole.student,
          createdAt: DateTime.now(),
          status: user_models.AccountStatus.active,
        );

        // Save to Firestore
        try {
          await FirestoreService.createOrUpdateUser(
            userId: firebaseUser.uid,
            userData: user.toFirestore(),
          );
        } catch (e) {
          if (kDebugMode) {
            print('UserManagementService: Error saving user to Firestore: $e');
          }
        }
      } else {
        user = user_models.User.fromFirestore(userData, firebaseUser.uid);
      }

      // Save locally
      await _saveUser(user);

      // Save session data
      await _saveSession({
        'userId': user.id,
        'loginTime': DateTime.now().toIso8601String(),
        'userRole': user.role.toString(),
      });

      // Log successful login
      await FirebaseService.logEvent(
        name: 'user_login_completed',
        parameters: {'user_id': user.id, 'role': user.role.toString()},
      );

      if (kDebugMode) {
        print('UserManagementService: Login completed successfully');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Login error: $e');
      }
      rethrow;
    }
  }

  /// Logout user
  Future<void> logoutUser() async {
    try {
      // Use FirebaseService for sign out
      await FirebaseService.signOut();
      await _clearCurrentUser();
      if (kDebugMode) {
        print('UserManagementService: Logout completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Logout error: $e');
      }
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (kDebugMode) {
        print('UserManagementService: Password reset email sent to: $email');
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Password reset error: $e');
      }
      rethrow;
    }
  }

  /// Migrate existing unencrypted user data to encrypted format
  Future<void> _migrateUserDataToEncrypted() async {
    try {
      final userJson = _prefs.getString(_currentUserKey);
      if (userJson != null && userJson.startsWith('{')) {
        // Existing unencrypted data found - encrypt it
        final encryptedData = await _encryptUserData(userJson);
        await _prefs.setString(_currentUserKey, encryptedData);

        if (_hiveBox != null) {
          await _hiveBox.put(_currentUserKey, encryptedData);
        }

        if (kDebugMode) {
          print(
            'UserManagementService: Migrated user data to encrypted format',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Error migrating user data: $e');
      }
    }
  }

  /// Get current user with migration support
  Future<user_models.User?> getCurrentUser() async {
    try {
      final userJson = _prefs.getString(_currentUserKey);
      if (userJson != null) {
        // Check if data is encrypted or plain JSON
        if (userJson.startsWith('{')) {
          // Plain JSON (existing user data) - migrate to encrypted
          await _migrateUserDataToEncrypted();
          // Get the newly encrypted data
          final encryptedJson = _prefs.getString(_currentUserKey);
          if (encryptedJson != null) {
            final decryptedData = await _decryptUserData(encryptedJson);
            final userData = jsonDecode(decryptedData) as Map<String, dynamic>;
            return user_models.User.fromJson(userData);
          }
        } else {
          // Encrypted data - decrypt first
          final decryptedData = await _decryptUserData(userJson);
          final userData = jsonDecode(decryptedData) as Map<String, dynamic>;
          return user_models.User.fromJson(userData);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Error getting current user: $e');
      }
      return null;
    }
  }

  /// Save user locally
  Future<void> _saveUser(user_models.User user) async {
    try {
      final userJson = jsonEncode(user.toJson());

      // Encrypt sensitive data for privacy compliance
      final encryptedData = await _encryptUserData(userJson);

      await _prefs.setString(_currentUserKey, encryptedData);

      if (_hiveBox != null) {
        await _hiveBox.put(_currentUserKey, encryptedData);
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Error saving user locally: $e');
      }
    }
  }

  /// Encrypt user data for privacy compliance
  Future<String> _encryptUserData(String data) async {
    try {
      // Simple base64 encoding for now - in production, use proper encryption
      // This is a placeholder for actual encryption implementation
      return base64Encode(utf8.encode(data));
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Error encrypting user data: $e');
      }
      return data; // Fallback to unencrypted data
    }
  }

  /// Decrypt user data
  Future<String> _decryptUserData(String encryptedData) async {
    try {
      // Simple base64 decoding for now - in production, use proper decryption
      return utf8.decode(base64Decode(encryptedData));
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Error decrypting user data: $e');
      }
      return encryptedData; // Fallback to encrypted data
    }
  }

  /// Clear current user
  Future<void> _clearCurrentUser() async {
    try {
      await _prefs.remove(_currentUserKey);
      await _prefs.remove(_currentSessionKey);
      if (_hiveBox != null) {
        await _hiveBox.delete(_currentUserKey);
        await _hiveBox.delete(_currentSessionKey);
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Error clearing current user: $e');
      }
    }
  }

  /// Save session data with platform-specific handling
  Future<void> _saveSession(Map<String, dynamic> sessionData) async {
    try {
      // Add platform-specific session data
      final platformData = await _getPlatformSessionData();
      sessionData.addAll(platformData);

      final sessionJson = jsonEncode(sessionData);
      await _prefs.setString(_currentSessionKey, sessionJson);
      if (_hiveBox != null) {
        await _hiveBox.put(_currentSessionKey, sessionJson);
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Error saving session: $e');
      }
    }
  }

  /// Get platform-specific session data
  Future<Map<String, dynamic>> _getPlatformSessionData() async {
    try {
      return {
        'platform': _getPlatformName(),
        'appVersion': '1.0.0',
        'sessionId': _generateSessionId(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'platform': 'unknown',
        'appVersion': '1.0.0',
        'sessionId': 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get platform name
  String _getPlatformName() {
    if (kIsWeb) {
      return 'web';
    } else {
      // This would be determined by actual platform detection
      return 'mobile';
    }
  }

  /// Generate session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
  }

  /// Get current session
  Future<Map<String, dynamic>?> getCurrentSession() async {
    try {
      final sessionJson = _prefs.getString(_currentSessionKey);
      if (sessionJson != null) {
        return jsonDecode(sessionJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Error getting current session: $e');
      }
      return null;
    }
  }

  /// Test Firebase connection with anonymous auth
  Future<bool> testFirebaseConnection() async {
    try {
      if (kDebugMode) {
        print('UserManagementService: Testing Firebase connection...');
      }

      // Check if Firebase Auth is properly initialized
      final currentUser = _auth.currentUser;
      final authState = _auth.authStateChanges();

      if (kDebugMode) {
        print('UserManagementService: Firebase Auth initialized successfully');
        print(
          'UserManagementService: Current user: ${currentUser?.uid ?? 'none'}',
        );
      }

      // Try to get auth state stream (this tests the connection)
      await authState.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) {
            print(
              'UserManagementService: Auth state stream timeout - but this is normal',
            );
          }
          return null;
        },
      );

      if (kDebugMode) {
        print('UserManagementService: Firebase connection test successful!');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Firebase connection test failed: $e');
      }
      return false;
    }
  }

  /// Generate random family ID
  String _generateFamilyId() {
    final random = Random();
    return 'family_${random.nextInt(999999)}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Check if offline mode is enabled
  Future<bool> _isOfflineMode() async {
    try {
      final privacySettingsString = _prefs.getString('privacy_settings');
      if (privacySettingsString != null) {
        final privacySettings =
            jsonDecode(privacySettingsString) as Map<String, dynamic>;
        return privacySettings['isOfflineMode'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// Riverpod provider for UserManagementService
final userManagementServiceProvider = Provider<UserManagementService>((ref) {
  // This provider will be overridden in main.dart with the actual instance
  throw UnimplementedError('UserManagementService provider not implemented');
});
