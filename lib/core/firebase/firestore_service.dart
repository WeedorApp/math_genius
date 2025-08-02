import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Simplified Firestore Service
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');

  static CollectionReference<Map<String, dynamic>> get userProfiles =>
      _firestore.collection('user_profiles');

  static CollectionReference<Map<String, dynamic>> get userSessions =>
      _firestore.collection('user_sessions');

  static CollectionReference<Map<String, dynamic>> get learningProgress =>
      _firestore.collection('learning_progress');

  /// Create or update user document
  static Future<void> createOrUpdateUser({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await users.doc(userId).set(userData, SetOptions(merge: true));
      if (kDebugMode) {
        print('FirestoreService: User document created/updated: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreService: Error creating/updating user: $e');
      }
      rethrow;
    }
  }

  /// Get user document
  static Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final doc = await users.doc(userId).get();
      if (kDebugMode) {
        print('FirestoreService: Retrieved user document: $userId');
      }
      return doc.data();
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreService: Error getting user: $e');
      }
      return null;
    }
  }

  /// Create or update user profile
  static Future<void> createOrUpdateUserProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      await userProfiles.doc(userId).set(profileData, SetOptions(merge: true));
      if (kDebugMode) {
        print('FirestoreService: User profile created/updated: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreService: Error creating/updating user profile: $e');
      }
      rethrow;
    }
  }

  /// Create user session
  static Future<void> createUserSession({
    required String sessionId,
    required Map<String, dynamic> sessionData,
  }) async {
    try {
      await userSessions.doc(sessionId).set(sessionData);
      if (kDebugMode) {
        print('FirestoreService: User session created: $sessionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreService: Error creating user session: $e');
      }
      rethrow;
    }
  }

  /// Create or update learning progress
  static Future<void> createOrUpdateLearningProgress({
    required String userId,
    required Map<String, dynamic> progressData,
  }) async {
    try {
      await learningProgress
          .doc(userId)
          .set(progressData, SetOptions(merge: true));
      if (kDebugMode) {
        print('FirestoreService: Learning progress created/updated: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          'FirestoreService: Error creating/updating learning progress: $e',
        );
      }
      rethrow;
    }
  }

  /// Delete user data
  static Future<void> deleteUserData(String userId) async {
    try {
      // Delete user document
      await users.doc(userId).delete();

      // Delete user profile
      await userProfiles.doc(userId).delete();

      // Delete user sessions
      final sessionsQuery = await userSessions
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in sessionsQuery.docs) {
        await doc.reference.delete();
      }

      // Delete learning progress
      await learningProgress.doc(userId).delete();

      if (kDebugMode) {
        print('FirestoreService: User data deleted: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreService: Error deleting user data: $e');
      }
      rethrow;
    }
  }

  /// Get user sessions
  static Future<List<Map<String, dynamic>>> getUserSessions(
    String userId,
  ) async {
    try {
      final querySnapshot = await userSessions
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final sessions = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      if (kDebugMode) {
        print(
          'FirestoreService: Retrieved ${sessions.length} sessions for user: $userId',
        );
      }

      return sessions;
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreService: Error getting user sessions: $e');
      }
      return [];
    }
  }

  /// Batch write operations
  static Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        final collection = operation['collection'] as String;
        final documentId = operation['documentId'] as String;
        final data = operation['data'] as Map<String, dynamic>;
        final action = operation['action'] as String;

        final docRef = _firestore.collection(collection).doc(documentId);

        switch (action) {
          case 'set':
            batch.set(docRef, data, SetOptions(merge: true));
            break;
          case 'update':
            batch.update(docRef, data);
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
      if (kDebugMode) {
        print(
          'FirestoreService: Batch write completed: ${operations.length} operations',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreService: Error in batch write: $e');
      }
      rethrow;
    }
  }
}
