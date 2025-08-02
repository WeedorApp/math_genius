# Firebase Setup Guide for Math Genius

## Overview
This guide will help you set up Firebase for the Math Genius Quantum Learning System with full authentication and database integration.

## Prerequisites
- Google account
- Flutter project set up
- Firebase CLI installed (`npm install -g firebase-tools`)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `math-genius-quantum`
4. Enable Google Analytics (optional but recommended)
5. Click "Create project"

## Step 2: Enable Authentication

1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Enable "Email/Password" authentication
3. Optionally enable other providers (Google, Apple, etc.)

## Step 3: Set up Cloud Firestore

1. Go to "Firestore Database" → "Create database"
2. Choose "Start in test mode" (for development)
3. Select a location close to your users
4. Click "Done"

### Firestore Security Rules
Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // User profiles
    match /user_profiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // User sessions
    match /user_sessions/{sessionId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Learning progress
    match /learning_progress/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Math problems (read-only for users)
    match /math_problems/{problemId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.token.role == 'teacher' || request.auth.token.role == 'admin';
    }
    
    // Family groups
    match /family_groups/{groupId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.members;
    }
    
    // Analytics (write-only for users)
    match /analytics/{eventId} {
      allow write: if request.auth != null;
      allow read: if request.auth != null && 
        request.auth.token.role == 'admin';
    }
  }
}
```

## Step 4: Configure Web App

1. In Firebase Console, click the web icon (</>)
2. Register app with nickname: `math-genius-web`
3. Copy the Firebase config object

## Step 5: Update Firebase Configuration

Replace the placeholder values in `lib/firebase_options.dart`:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY',
  appId: 'YOUR_ACTUAL_APP_ID',
  messagingSenderId: 'YOUR_ACTUAL_SENDER_ID',
  projectId: 'math-genius-quantum',
  authDomain: 'math-genius-quantum.firebaseapp.com',
  storageBucket: 'math-genius-quantum.appspot.com',
  measurementId: 'YOUR_ACTUAL_MEASUREMENT_ID',
);
```

## Step 6: Enable Additional Services (Optional)

### Firebase Storage
1. Go to "Storage" → "Get started"
2. Choose "Start in test mode"
3. Update security rules for file uploads

### Firebase Messaging
1. Go to "Project settings" → "Cloud Messaging"
2. Generate server key for push notifications

### Firebase Analytics
1. Go to "Analytics" → "Get started"
2. Configure events and user properties

## Step 7: Test the Integration

1. Run the app: `flutter run -d chrome`
2. Navigate to the auth screen
3. Try creating an account
4. Check Firestore for user data

## Database Collections Structure

### Users Collection
```json
{
  "id": "user_id",
  "email": "user@example.com",
  "displayName": "John Doe",
  "role": "student",
  "status": "active",
  "createdAt": "timestamp",
  "lastLoginAt": "timestamp",
  "lastActiveAt": "timestamp"
}
```

### User Profiles Collection
```json
{
  "userId": "user_id",
  "firstName": "John",
  "lastName": "Doe",
  "avatar": "url",
  "grade": "5",
  "school": "Elementary School",
  "preferences": {
    "theme": "dark",
    "notifications": true,
    "language": "en"
  }
}
```

### Learning Progress Collection
```json
{
  "userId": "user_id",
  "currentLevel": 3,
  "totalPoints": 1250,
  "completedLessons": ["lesson1", "lesson2"],
  "streakDays": 7,
  "lastActivity": "timestamp",
  "achievements": ["first_lesson", "week_streak"]
}
```

### Math Problems Collection
```json
{
  "id": "problem_id",
  "category": "addition",
  "difficulty": "easy",
  "question": "What is 5 + 3?",
  "answer": 8,
  "hints": ["Count on your fingers", "Use number line"],
  "explanation": "5 + 3 = 8 because...",
  "createdBy": "teacher_id",
  "createdAt": "timestamp"
}
```

### Family Groups Collection
```json
{
  "id": "group_id",
  "name": "Smith Family",
  "members": ["parent_id", "child1_id", "child2_id"],
  "createdBy": "parent_id",
  "createdAt": "timestamp",
  "settings": {
    "allowProgressSharing": true,
    "notifications": true
  }
}
```

## Security Best Practices

1. **Authentication**: Always verify user authentication before database operations
2. **Authorization**: Use role-based access control
3. **Data Validation**: Validate all input data
4. **Rate Limiting**: Implement rate limiting for API calls
5. **Error Handling**: Log errors but don't expose sensitive information
6. **Backup**: Set up regular database backups

## Production Deployment

1. **Environment Variables**: Use environment variables for sensitive config
2. **Domain Verification**: Add your domain to Firebase Auth
3. **SSL Certificate**: Ensure HTTPS is enabled
4. **Monitoring**: Set up Firebase Performance Monitoring
5. **Crash Reporting**: Enable Firebase Crashlytics

## Troubleshooting

### Common Issues

1. **API Key Invalid**: Ensure you're using the correct API key from Firebase Console
2. **CORS Errors**: Add your domain to Firebase Auth authorized domains
3. **Permission Denied**: Check Firestore security rules
4. **Network Errors**: Verify internet connection and Firebase project status

### Debug Commands

```bash
# Check Firebase configuration
flutter doctor

# Clear cache
flutter clean
flutter pub get

# Test Firebase connection
flutter run -d chrome --verbose
```

## Next Steps

1. Set up real Firebase project with valid credentials
2. Configure production environment
3. Implement advanced features (push notifications, analytics)
4. Set up CI/CD pipeline
5. Monitor and optimize performance

## Support

For Firebase-specific issues:
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Support](https://firebase.google.com/support)
- [Flutter Firebase Plugin](https://pub.dev/packages/firebase_core) 