# Firebase Setup Guide for Real OTP Authentication

## 🔥 Enable Real Firebase Phone Authentication

You've disabled the development OTP bypass. Now you need to configure Firebase for real OTP authentication.

## 📋 Step-by-Step Setup

### 1. Create/Configure Firebase Project

1. **Go to [Firebase Console](https://console.firebase.google.com/)**
2. **Create a new project** or select existing `SamyPay` project
3. **Add your Android/iOS apps** to the project

### 2. Enable Phone Authentication

1. In Firebase Console → **Authentication**
2. Go to **Sign-in method** tab
3. **Enable Phone** authentication
4. **Configure sign-in providers**

### 3. Set Test Phone Numbers (for Development)

1. In Authentication → **Settings** → **Phone numbers for testing**
2. Add test numbers:
   ```
   Phone Number: +919876543210
   OTP Code: 123456
   
   Phone Number: +919999999999  
   OTP Code: 654321
   ```

### 4. Configure Firebase for Android

1. **Download `google-services.json`** from Firebase Console
2. **Place it in** `android/app/` directory
3. **Update SHA-1 fingerprints** in Firebase Console:

```bash
# Get debug SHA-1
cd android
./gradlew signingReport

# Get release SHA-1 (for production)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey
```

### 5. Configure Firebase for iOS

1. **Download `GoogleService-Info.plist`** from Firebase Console
2. **Add it to** `ios/Runner/` directory in Xcode
3. **Enable Push Notifications** in Xcode project capabilities

### 6. Update Firebase Configuration Files

#### Update `firebase_options.dart`:
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Configure Firebase for your project
flutterfire configure
```

### 7. Firestore Security Rules

Update your Firestore rules for production:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Wallets collection  
    match /wallets/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      // Prevent direct balance manipulation
      allow update: if request.auth != null && 
        request.auth.uid == userId &&
        !request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['balance', 'outstandingBalance']);
    }
    
    // Transactions collection
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         request.auth.uid == request.resource.data.userId);
    }
  }
}
```

### 8. App Check (Recommended for Production)

Enable App Check for additional security:

1. In Firebase Console → **App Check**
2. **Register your app**
3. **Configure reCAPTCHA** for web
4. **Configure Play Integrity** for Android
5. **Configure App Attest** for iOS

## 🧪 Testing Real Firebase OTP

### Testing with Test Phone Numbers:
1. **Use test numbers** from step 3 above
2. **Enter the test number** in your app
3. **Use the configured test OTP** (e.g., `123456`)

### Testing with Real Phone Numbers:
1. **Use your actual phone number**
2. **Wait for real SMS** from Firebase
3. **Enter the received OTP** in the app

## 🚀 Production Deployment

### 1. Update Build Configuration

#### Android (`android/app/build.gradle.kts`):
```kotlin
android {
    // ... existing configuration
    
    signingConfigs {
        release {
            // Add your release signing configuration
            keyAlias = project.findProperty("keyAlias") as String?
            keyPassword = project.findProperty("keyPassword") as String?
            storeFile = file(project.findProperty("storeFile") as String? ?: "")
            storePassword = project.findProperty("storePassword") as String?
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // ... other release configuration
        }
    }
}
```

#### iOS:
1. **Configure code signing** in Xcode
2. **Add production certificates**
3. **Configure push notification certificates**

### 2. Quota and Billing

1. **Monitor SMS quota** in Firebase Console
2. **Set up billing** for production usage
3. **Configure usage alerts**

## 🔧 Troubleshooting

### Common Issues:

#### "SMS quota exceeded"
- **Solution**: Check Firebase Console quotas, upgrade plan if needed

#### "Invalid phone number"
- **Solution**: Ensure phone number includes country code (+91 for India)

#### "reCAPTCHA verification failed" (Web)
- **Solution**: Check App Check configuration and domain allowlist

#### "Play Integrity API error" (Android)
- **Solution**: Configure proper SHA fingerprints and App Check

### Debug Commands:
```bash
# Check Firebase configuration
flutter packages pub run build_runner build

# Test Firebase connection
flutter run --verbose

# Check Firebase auth state
flutter logs
```

## 📱 Platform-Specific Notes

### Android:
- Requires **Google Play Services**
- **Auto-read SMS** works on devices with Google Play
- **Manual OTP entry** fallback available

### iOS:
- Requires **iOS 9.0+**
- **Manual OTP entry** required
- **No auto-read** capability

### Web:
- **reCAPTCHA verification** required
- **Manual OTP entry** only
- **HTTPS required** for production

## ✅ Final Checklist

- [ ] Firebase project created/configured
- [ ] Phone authentication enabled
- [ ] Test phone numbers added (optional)
- [ ] `google-services.json` added (Android)
- [ ] `GoogleService-Info.plist` added (iOS)
- [ ] SHA fingerprints configured (Android)
- [ ] `firebase_options.dart` updated
- [ ] Firestore security rules updated
- [ ] App Check configured (production)
- [ ] Billing configured (production)

## 🎉 You're Ready!

Your SamyPay app is now configured for **real Firebase phone authentication**. Users will receive actual SMS OTP codes from Firebase!

### Test the complete flow:
1. **Enter a real phone number** or test number
2. **Wait for SMS OTP** from Firebase
3. **Enter the received OTP**
4. **Complete authentication**

**No more development bypass - you're using production-ready Firebase authentication!** 🚀 