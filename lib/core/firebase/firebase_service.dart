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
      await analytics.logEvent(name: name, parameters: parameters);
      if (kDebugMode) {
        print('FirebaseService: Analytics event logged: $name');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseService: Error logging analytics event: $e');
      }
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
