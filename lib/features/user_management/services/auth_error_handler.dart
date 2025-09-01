import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Comprehensive authentication error handler
class AuthErrorHandler {
  /// Handle Firebase authentication errors with user-friendly messages
  static String handleFirebaseAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Please try logging in instead, or use a different email address.';

        case 'invalid-credential':
          return 'Invalid email or password. Please check your credentials and try again.';

        case 'user-not-found':
          return 'No account found with this email. Please check your email or create a new account.';

        case 'wrong-password':
          return 'Incorrect password. Please try again or reset your password.';

        case 'weak-password':
          return 'Password is too weak. Please use at least 8 characters with letters and numbers.';

        case 'invalid-email':
          return 'Please enter a valid email address.';

        case 'user-disabled':
          return 'This account has been disabled. Please contact support for assistance.';

        case 'too-many-requests':
          return 'Too many failed attempts. Please wait a few minutes before trying again.';

        case 'operation-not-allowed':
          return 'Email/password authentication is not enabled. Please contact support.';

        case 'network-request-failed':
          return 'Network error. Please check your internet connection and try again.';

        case 'requires-recent-login':
          return 'For security, please log in again to complete this action.';

        case 'credential-already-in-use':
          return 'This credential is already associated with another account.';

        case 'invalid-verification-code':
          return 'Invalid verification code. Please check and try again.';

        case 'invalid-verification-id':
          return 'Invalid verification ID. Please restart the verification process.';

        case 'session-cookie-expired':
          return 'Your session has expired. Please log in again.';

        case 'uid-already-exists':
          return 'An account with this identifier already exists.';

        case 'email-change-needs-verification':
          return 'Email change requires verification. Please check your email.';

        case 'invalid-continue-uri':
          return 'Invalid continue URL provided.';

        case 'missing-continue-uri':
          return 'Missing continue URL in the request.';

        case 'unauthorized-continue-uri':
          return 'Unauthorized continue URL domain.';

        default:
          if (kDebugMode) {
            debugPrint(
              'Unhandled Firebase Auth error: ${error.code} - ${error.message}',
            );
          }
          return 'Authentication error: ${error.message ?? 'Unknown error'}';
      }
    }

    // Handle other types of errors
    return 'Authentication failed: ${error.toString()}';
  }

  /// Get recovery action for specific error codes
  static AuthRecoveryAction getRecoveryAction(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return AuthRecoveryAction.switchToLogin;

      case 'user-not-found':
        return AuthRecoveryAction.switchToRegister;

      case 'wrong-password':
      case 'invalid-credential':
        return AuthRecoveryAction.resetPassword;

      case 'weak-password':
        return AuthRecoveryAction.strengthenPassword;

      case 'too-many-requests':
        return AuthRecoveryAction.waitAndRetry;

      case 'network-request-failed':
        return AuthRecoveryAction.checkConnection;

      case 'requires-recent-login':
        return AuthRecoveryAction.reauthenticate;

      default:
        return AuthRecoveryAction.contactSupport;
    }
  }

  /// Check if error is recoverable by user action
  static bool isRecoverableError(String errorCode) {
    const recoverableErrors = {
      'email-already-in-use',
      'user-not-found',
      'wrong-password',
      'invalid-credential',
      'weak-password',
      'invalid-email',
      'network-request-failed',
    };

    return recoverableErrors.contains(errorCode);
  }

  /// Check if error requires immediate action
  static bool requiresImmediateAction(String errorCode) {
    const immediateActionErrors = {
      'user-disabled',
      'too-many-requests',
      'requires-recent-login',
    };

    return immediateActionErrors.contains(errorCode);
  }

  /// Get user-friendly error category
  static AuthErrorCategory getErrorCategory(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
      case 'user-not-found':
      case 'credential-already-in-use':
        return AuthErrorCategory.accountConflict;

      case 'wrong-password':
      case 'invalid-credential':
        return AuthErrorCategory.credentialError;

      case 'weak-password':
      case 'invalid-email':
        return AuthErrorCategory.inputValidation;

      case 'network-request-failed':
        return AuthErrorCategory.networkError;

      case 'too-many-requests':
        return AuthErrorCategory.rateLimited;

      case 'user-disabled':
        return AuthErrorCategory.accountDisabled;

      default:
        return AuthErrorCategory.unknown;
    }
  }
}

/// Authentication recovery actions
enum AuthRecoveryAction {
  switchToLogin,
  switchToRegister,
  resetPassword,
  strengthenPassword,
  waitAndRetry,
  checkConnection,
  reauthenticate,
  contactSupport,
}

/// Authentication error categories
enum AuthErrorCategory {
  accountConflict,
  credentialError,
  inputValidation,
  networkError,
  rateLimited,
  accountDisabled,
  unknown,
}

/// Authentication state management
class AuthStateManager {
  static const String _authStateKey = 'auth_state';
  static const String _lastErrorKey = 'last_auth_error';

  /// Save authentication state
  static Future<void> saveAuthState({
    required String state,
    required String? userId,
    required DateTime timestamp,
  }) async {
    try {
      // Save using the _authStateKey constant
      final stateData = {
        'state': state,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authStateKey, jsonEncode(stateData));

      if (kDebugMode) {
        debugPrint(
          'Auth state saved with key $_authStateKey: $state for user: $userId',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving auth state: $e');
      }
    }
  }

  /// Clear authentication state
  static Future<void> clearAuthState() async {
    try {
      // Clear using the _authStateKey constant
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authStateKey);

      if (kDebugMode) {
        debugPrint('Auth state cleared from key $_authStateKey');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing auth state: $e');
      }
    }
  }

  /// Save last authentication error for debugging
  static Future<void> saveLastError({
    required String errorCode,
    required String errorMessage,
  }) async {
    try {
      // Save error using the _lastErrorKey constant
      final errorData = {
        'errorCode': errorCode,
        'errorMessage': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastErrorKey, jsonEncode(errorData));

      if (kDebugMode) {
        debugPrint('Last error saved with key $_lastErrorKey: $errorCode');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving last error: $e');
      }
    }
  }
}
