# Authentication Test Guide

## 🔧 **Testing Steps**

### **Step 1: Create a New Account**
1. Open the app in Chrome
2. Click "Sign Up" to switch to registration mode
3. Fill in the form:
   - **First Name**: `Test`
   - **Last Name**: `User`
   - **Email**: `test@example.com` (use a unique email)
   - **Password**: `password123`
   - **Role**: `Student`
4. Click "Create Account"

### **Step 2: Verify in Firebase Console**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `weedor-math-genius`
3. Go to **Authentication** → **Users**
4. You should see the new user created

### **Step 3: Test Login**
1. Use the same credentials to login
2. Email: `test@example.com`
3. Password: `password123`
4. Click "Sign In"

### **Step 4: Verify Firestore Data**
1. In Firebase Console, go to **Firestore Database**
2. Check the `users` collection
3. You should see the user data

## 🐛 **Troubleshooting**

### **If Registration Fails:**
- Check Firebase Console for errors
- Verify email is unique
- Check password strength (minimum 6 characters)

### **If Login Fails:**
- Verify the user was created in Firebase Console
- Check the password is correct
- Try password reset if needed

### **If No Data in Firestore:**
- Check Firestore security rules
- Verify the app has write permissions
- Check network connectivity

## 📊 **Expected Results**

### **Successful Registration:**
- ✅ User appears in Firebase Auth
- ✅ User data appears in Firestore
- ✅ App navigates to home screen
- ✅ No error messages

### **Successful Login:**
- ✅ User can access the app
- ✅ User data is loaded
- ✅ Session is created
- ✅ App shows user information

---

*Test this with a fresh email address that doesn't exist in your Firebase project.* 