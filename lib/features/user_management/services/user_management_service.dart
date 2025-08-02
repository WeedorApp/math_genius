import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:math';
import '../models/user_model.dart' as user_models;
import '../../../core/firebase/firebase_service.dart';
import '../../../core/firebase/firestore_service.dart';

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
      }

      // Create Firebase user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create Firebase user');
      }

      // Update display name
      await firebaseUser.updateDisplayName(displayName);

      // Create user object
      final user = user_models.User(
        id: firebaseUser.uid,
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
        await FirestoreService.createOrUpdateUser(
          userId: firebaseUser.uid,
          userData: user.toFirestore(),
        );
        if (kDebugMode) {
          print('UserManagementService: User saved to Firestore');
        }
      } catch (e) {
        if (kDebugMode) {
          print('UserManagementService: Error saving to Firestore: $e');
        }
        // Continue even if Firestore fails
      }

      // Save locally
      await _saveUser(user);

      // Log successful registration
      await FirebaseService.logEvent(
        name: 'user_registration_completed',
        parameters: {'user_id': user.id, 'role': role.toString()},
      );

      if (kDebugMode) {
        print('UserManagementService: Registration completed successfully');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Registration error: $e');
      }
      rethrow;
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

  /// Get current user
  Future<user_models.User?> getCurrentUser() async {
    try {
      final userJson = _prefs.getString(_currentUserKey);
      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        return user_models.User.fromJson(userData);
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
      await _prefs.setString(_currentUserKey, userJson);

      if (_hiveBox != null) {
        await _hiveBox.put(_currentUserKey, userJson);
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserManagementService: Error saving user locally: $e');
      }
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

  /// Save session data
  Future<void> _saveSession(Map<String, dynamic> sessionData) async {
    try {
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

  /// Generate random family ID
  String _generateFamilyId() {
    final random = Random();
    return 'family_${random.nextInt(999999)}_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Riverpod provider for UserManagementService
final userManagementServiceProvider = Provider<UserManagementService>((ref) {
  throw UnimplementedError('UserManagementService provider not implemented');
});
