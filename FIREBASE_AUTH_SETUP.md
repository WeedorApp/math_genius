# Firebase Authentication Setup Guide

## 🔐 **Current Issue: Authentication Not Enabled**

The error `[firebase_auth/configuration-not-found]` indicates that Firebase Authentication is not enabled in your Firebase project.

## 📋 **Step-by-Step Solution:**

### **Step 1: Enable Authentication in Firebase Console**

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/project/weedor-math-genius/overview

2. **Navigate to Authentication**
   - Click "Authentication" in the left sidebar
   - Click "Get started" if prompted

3. **Enable Email/Password Authentication**
   - Click "Sign-in method" tab
   - Click on "Email/Password"
   - Toggle "Enable" to turn it ON
   - Click "Save"

4. **Configure Authorized Domains**
   - Go to "Settings" tab in Authentication
   - Scroll to "Authorized domains"
   - Add `localhost` to the list
   - This allows testing on localhost

### **Step 2: Verify Authentication is Enabled**

After enabling Authentication, you should see:
- ✅ Email/Password provider enabled
- ✅ `localhost` in authorized domains
- ✅ Authentication service active

### **Step 3: Test Authentication**

Once Authentication is enabled:

1. **Run the application:**
   ```bash
   flutter run -d chrome
   ```

2. **Navigate to the auth screen:**
   - The app should redirect to `/auth`
   - You should see the login/register form

3. **Test user registration:**
   - Click "Sign Up" to switch to registration mode
   - Fill in the form with test data
   - Click "Create Account"

4. **Test user login:**
   - Use the credentials you just created
   - Click "Sign In"

### **Step 4: Verify in Firebase Console**

After successful registration/login:

1. **Check Authentication Users:**
   - Go to Firebase Console → Authentication → Users
   - You should see the user you created

2. **Check Firestore Data:**
   - Go to Firebase Console → Firestore Database
   - Check the `users` collection for user data

## 🔧 **Troubleshooting:**

### **If Authentication Still Fails:**

1. **Check Project Configuration:**
   ```bash
   firebase use weedor-math-genius
   firebase projects:list
   ```

2. **Verify Firebase Options:**
   - Ensure `firebase_options.dart` has correct project ID
   - Check that API key is valid

3. **Clear Browser Cache:**
   - Hard refresh the browser (Ctrl+Shift+R)
   - Clear browser cache and cookies

4. **Check Network Tab:**
   - Open browser DevTools
   - Check Network tab for Firebase API calls
   - Look for authentication-related errors

### **Common Issues:**

1. **"configuration-not-found"**
   - ✅ **Solution**: Enable Authentication in Firebase Console

2. **"unauthorized-domain"**
   - ✅ **Solution**: Add `localhost` to authorized domains

3. **"invalid-api-key"**
   - ✅ **Solution**: Check API key in `firebase_options.dart`

4. **"network-error"**
   - ✅ **Solution**: Check internet connection and Firebase status

## 🎯 **Expected Results:**

After enabling Authentication, you should see:

1. **Successful Registration:**
   ```
   User registered successfully
   Navigate to home screen
   ```

2. **Successful Login:**
   ```
   User logged in successfully
   Navigate to home screen
   ```

3. **Firebase Console Data:**
   - User appears in Authentication → Users
   - User data appears in Firestore → users collection

## 🚀 **Next Steps:**

Once Authentication is working:

1. **Test all authentication flows**
2. **Deploy to Firebase Hosting**
3. **Enable additional Firebase services**
4. **Configure production environment**

---

**Status: Waiting for Authentication to be enabled in Firebase Console** ⏳

**Action Required: Enable Email/Password Authentication in Firebase Console** 