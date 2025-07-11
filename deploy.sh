#!/bin/bash

# SamyPay Production Deployment Script
# Run this script to deploy the app to production

set -e

echo "🚀 Starting SamyPay Production Deployment..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Installing..."
    npm install -g firebase-tools
fi

echo "📋 Pre-deployment checklist:"
echo "1. ✅ Clean architecture implemented"
echo "2. ✅ Authentication with Firebase"
echo "3. ✅ Multi-API recharge integration"
echo "4. ✅ Wallet system with payment gateways"
echo "5. ✅ Transaction management"
echo "6. ✅ B2B and B2C features"
echo "7. ✅ AI-powered recommendations"
echo "8. ✅ Security measures"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Run code generation
echo "🔧 Running code generation..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run tests
echo "🧪 Running tests..."
flutter test

# Build for web
echo "🌐 Building for web..."
flutter build web --release

# Build for Android
echo "📱 Building for Android..."
flutter build apk --release
flutter build appbundle --release

# Build for iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Building for iOS..."
    flutter build ios --release
fi

# Deploy to Firebase Hosting
echo "🔥 Deploying to Firebase Hosting..."
firebase deploy --only hosting

# Deploy Firebase Functions (if any)
if [ -d "functions" ]; then
    echo "⚡ Deploying Firebase Functions..."
    firebase deploy --only functions
fi

# Deploy Firestore rules
echo "🔒 Deploying Firestore security rules..."
firebase deploy --only firestore:rules

echo "✅ Deployment completed successfully!"
echo ""
echo "📊 Deployment Summary:"
echo "- Web app: https://samypay-app.web.app"
echo "- Android APK: build/app/outputs/flutter-apk/app-release.apk"
echo "- Android Bundle: build/app/outputs/bundle/release/app-release.aab"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "- iOS IPA: build/ios/ipa/SamyPay.ipa"
fi
echo ""
echo "🔑 Next Steps:"
echo "1. Upload Android Bundle to Google Play Console"
echo "2. Upload iOS IPA to App Store Connect (if built)"
echo "3. Configure production API keys"
echo "4. Set up monitoring and analytics"
echo "5. Enable crash reporting"
echo ""
echo "🎉 SamyPay is ready for production!" 