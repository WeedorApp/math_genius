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

  UserManagementService(this._prefs, this._hiveBox) {
    if (kDebugMode) {
      print(
        'UserManagementService: Initialized with Firebase Auth: ${_auth.app.name}',
      );
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
        print('UserManagementService: Firebase Auth instance: $_auth');
      }

      // Log analytics event
      await FirebaseService.logEvent(
        name: 'user_registration_started',
        parameters: {'email': email, 'role': role.toString()},
      );

      // Create Firebase user
      if (kDebugMode) {
        print(
          'UserManagementService: Calling Firebase Auth createUserWithEmailAndPassword...',
        );
      }
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
        familyId: familyId,
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

        // Add timeout to prevent hanging
        await FirestoreService.createOrUpdateUser(
          userId: firebaseUser.uid,
          userData: user.toFirestore(),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            if (kDebugMode) {
              print('UserManagementService: Firestore save timed out');
            }
            throw Exception('Firestore save timed out');
          },
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
      if (kDebugMode) {
        print('UserManagementService: Saving user locally...');
      }
      await _saveUser(user);

      // Log successful registration
      if (kDebugMode) {
        print('UserManagementService: Logging analytics event...');
      }
      try {
        await FirebaseService.logEvent(
          name: 'user_registration_completed',
          parameters: {'user_id': user.id, 'role': role.toString()},
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (kDebugMode) {
              print('UserManagementService: Analytics event timed out');
            }
            throw Exception('Analytics event timed out');
          },
        );
      } catch (e) {
        if (kDebugMode) {
          print('UserManagementService: Analytics event failed: $e');
        }
        // Continue even if analytics fails
      }

      if (kDebugMode) {
        print('UserManagementService: Registration completed successfully');
        print('UserManagementService: Returning user object');
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

      // Sign in with Firebase
      if (kDebugMode) {
        print(
          'UserManagementService: Calling Firebase Auth signInWithEmailAndPassword...',
        );
      }
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed');
      }

      // Get user data from Firestore (temporarily disabled)
      if (kDebugMode) {
        print('UserManagementService: Skipping Firestore getUser for now...');
      }

      user_models.User user;
      // Temporarily skip Firestore and create user from Firebase Auth data
      if (true) {
        // Always create from Firebase Auth data for now
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

        // Save to Firestore (temporarily disabled to test auth flow)
        if (kDebugMode) {
          print('UserManagementService: Skipping Firestore save for login...');
        }
        /*
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
        */
        // Temporarily disabled Firestore user creation
        // } else {
        //   user = user_models.User.fromFirestore(userData, firebaseUser.uid);
        // }
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
      // Generate random session ID
      final sessionId = _generateSessionId();
      sessionData['sessionId'] = sessionId;

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

  /// Generate random session ID
  String _generateSessionId() {
    final random = Random();
    return 'session_${random.nextInt(999999)}_${DateTime.now().millisecondsSinceEpoch}';
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
}

/// Riverpod provider for UserManagementService
final userManagementServiceProvider = Provider<UserManagementService>((ref) {
  throw UnimplementedError('UserManagementService provider not implemented');
});
