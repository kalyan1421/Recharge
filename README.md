# SamyPay - Flutter Recharge & Payment App

A complete Flutter application for mobile recharge, bill payments, and financial transactions with a modern UI design.

## 🚀 Features

### 🏠 Home Screen
- **Custom App Bar** with SamyPay branding and navigation icons
- **Service Grid** with Add Money, My QR, Transaction Report, and Wallet Summary
- **Promotional Banners** with gradient backgrounds
- **Service Icons Section** with clean card layouts
- **Wallet Balance Cards** showing current and outstanding amounts
- **Recharge Options** with category icons (Mobile, DTH, Playstore, Gas)
- **Bottom Navigation** with floating action button

### 📱 Recharge Screen
- **Tab Navigation** (Prepaid, Postpaid, DTH)
- **Promotional Cards** for VI and Jio operators
- **Form Fields** with proper validation styling
- **Network Selection** with dropdown indicator
- **Amount Input** with currency symbol
- **Action Buttons** (Check Offer, Plan Sheet)
- **Wallet Balance Display**
- **Recent Recharge History** with repeat options

### 💳 Plan Selection Screen
- **Plan Categories** with tab navigation (Unlimited, Data, Talktime, Roaming, Ratecutter)
- **Featured Plan Card** with gradient design
- **Plan Details** (Validity, Data, Unlimited features)
- **Bookmark Feature** with yellow star
- **Call-to-Action button** for recharge

### 📊 Transaction Report Screen
- **Search & Filter** functionality with date pickers
- **Transaction Cards** with status indicators
- **Detailed Transaction Info** (Reference ID, Transaction ID)
- **Balance Breakdown** (Opening, Cashback, Current)
- **Action Buttons** (Dispute, Share)
- **Status-based Color Coding** (Success=Green, Failed=Red, Pending=Orange)

## 🎨 Design System

### Color Palette
- **Primary**: Purple (`Colors.purple`)
- **Secondary**: Pink, Cyan, Yellow accents
- **Status Colors**: 
  - Success: Green
  - Failed: Red
  - Pending: Orange
- **Background**: Light purple (`Color(0xFFF5F3FF)`)

### Typography
- **Headers**: Bold, 18px
- **Body Text**: Regular, 14-16px
- **Metadata**: Small, 12px, grey

### Layout Principles
- **Consistent Spacing**: 16px padding, 12px element spacing
- **Rounded Corners**: 8-12px radius throughout
- **Card-based Design**: Subtle shadows and elevated surfaces
- **Responsive Grid**: Flexible layouts for different screen sizes

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code
- Android SDK for Android development
- Xcode for iOS development (macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd samypay
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Platform-specific Setup

#### Android
- Ensure Android SDK is installed and configured
- Connect an Android device or start an emulator
- Run `flutter devices` to verify device connection

#### iOS (macOS only)
- Install Xcode from App Store
- Install iOS Simulator
- Run `flutter devices` to verify simulator availability

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point and main screens
├── screens/
│   ├── home_screen.dart     # Home screen implementation
│   ├── recharge_screen.dart # Recharge functionality
│   ├── plan_screen.dart     # Plan selection screen
│   └── transaction_screen.dart # Transaction reports
├── widgets/
│   ├── service_card.dart    # Reusable service cards
│   ├── balance_card.dart    # Balance display widgets
│   └── transaction_item.dart # Transaction list items
└── utils/
    ├── colors.dart          # App color constants
    ├── styles.dart          # Text styles and themes
    └── navigation.dart      # Navigation helpers
```

## 🔧 Configuration

### App Theming
The app uses a custom purple theme with Material Design 3 principles:

```dart
theme: ThemeData(
  primarySwatch: Colors.purple,
  fontFamily: 'Roboto',
),
```

### Navigation
Navigation is handled through the `AppNavigator` class:

```dart
// Navigate to recharge screen
AppNavigator.navigateToRecharge(context);

// Navigate to transaction report
AppNavigator.navigateToTransactionReport(context);
```

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Widget Testing
```bash
flutter test test/widget_test.dart
```

### Integration Testing
```bash
flutter drive --target=test_driver/app.dart
```

## 🚀 Deployment

### Android APK
```bash
flutter build apk --release
```

### iOS IPA
```bash
flutter build ios --release
```

### App Bundle (Google Play)
```bash
flutter build appbundle --release
```

## 🔮 Future Enhancements

- [ ] **Payment Gateway Integration** (Razorpay, Paytm, etc.)
- [ ] **User Authentication** (OTP, Biometric)
- [ ] **Push Notifications** for transaction updates
- [ ] **QR Code Scanner** for payments
- [ ] **Bill Reminders** and notifications
- [ ] **Wallet Top-up** functionality
- [ ] **Transaction History** with advanced filters
- [ ] **Multi-language Support**
- [ ] **Dark Mode** theme support
- [ ] **Offline Mode** for transaction history

## 📱 Screenshots

The app includes the following main screens:
1. **Home Screen** - Main dashboard with services
2. **Recharge Screen** - Mobile/DTH recharge interface
3. **Plan Selection** - Browse and select recharge plans
4. **Transaction Report** - View transaction history

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Known Issues

- Custom fonts require manual font file addition
- Some placeholder functionality needs backend integration
- iOS build requires macOS environment for testing

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation for common solutions

---

**Made with ❤️ using Flutter**
