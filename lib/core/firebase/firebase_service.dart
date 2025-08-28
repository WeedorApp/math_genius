import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Simplified Firebase Service
class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
  static FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  /// Initialize Firebase services
  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('FirebaseService: Initializing Firebase services...');
      }

      // Configure Analytics
      await analytics.setAnalyticsCollectionEnabled(true);

      if (kDebugMode) {
        print(
          'FirebaseService: All Firebase services initialized successfully',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseService: Error initializing Firebase services: $e');
      }
      rethrow;
    }
  }

  /// Sign out user
  static Future<void> signOut() async {
    try {
      await auth.signOut();
      if (kDebugMode) {
        print('FirebaseService: User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseService: Error signing out: $e');
      }
      rethrow;
    }
  }

  /// Delete user account
  static Future<void> deleteAccount() async {
    try {
      final user = auth.currentUser;
      if (user != null) {
        await user.delete();
        if (kDebugMode) {
          print('FirebaseService: User account deleted successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseService: Error deleting account: $e');
      }
      rethrow;
    }
  }

  /// Log analytics event
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      // Check if analytics is enabled (privacy compliance)
      final isAnalyticsEnabled = await _isAnalyticsEnabled();
      if (!isAnalyticsEnabled) {
        if (kDebugMode) {
          print('FirebaseService: Analytics disabled by user preference');
        }
        return;
      }

      await analytics.logEvent(name: name, parameters: parameters);
      if (kDebugMode) {
        print('FirebaseService: Analytics event logged: $name');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseService: Error logging analytics event: $e');
      }
      // Don't rethrow analytics errors to avoid breaking app functionality
    }
  }

  /// Check if analytics is enabled (privacy compliance)
  static Future<bool> _isAnalyticsEnabled() async {
    try {
      // This would typically check user privacy settings
      // For now, return true as default
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseService: Error checking analytics status: $e');
      }
      return false;
    }
  }

  /// Upload file to Firebase Storage
  static Future<String> uploadFile({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    try {
      final ref = storage.ref().child(path);
      final metadata = contentType != null
          ? SettableMetadata(contentType: contentType)
          : null;

      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        print('FirebaseService: File uploaded successfully: $path');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseService: Error uploading file: $e');
      }
      rethrow;
    }
  }

  /// Delete file from Firebase Storage
  static Future<void> deleteFile(String path) async {
    try {
      final ref = storage.ref().child(path);
      await ref.delete();
      if (kDebugMode) {
        print('FirebaseService: File deleted successfully: $path');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseService: Error deleting file: $e');
      }
      rethrow;
    }
  }
}
