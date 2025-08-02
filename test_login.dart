import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

void main() async {
  // Test login functionality
  await testLogin();
}

Future<void> testLogin() async {
  try {
    print('Testing login functionality...');

    // Test with a known user
    final email = 'testmode@mode.org';
    final password = 'password123';

    print('Attempting to login with: $email');

    // Sign in with Firebase
    final userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    final user = userCredential.user;
    if (user != null) {
      print('✅ Login successful! User ID: ${user.uid}');
      print('User email: ${user.email}');
      print('User display name: ${user.displayName}');

      // Test Firestore access
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        print('✅ User data found in Firestore');
        print('User data: ${userData.data()}');
      } else {
        print('⚠️ No user data found in Firestore');
      }
    } else {
      print('❌ Login failed - no user returned');
    }
  } catch (e) {
    print('❌ Login error: $e');
  }
}
