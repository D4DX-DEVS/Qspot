# QSpot Release Setup Guide

This guide covers the complete setup process for releasing QSpot to Google Play Store and Apple App Store.

## ✅ Completed Configurations

### App Information
- **App Name**: QSpot
- **Package Name**: `co.d4dx.qspot`
- **Version**: 1.0.0+1
- **Description**: "QSpot - Your Space for Quran Vibes. Discover inspiring Islamic content from renowned speakers and scholars."

### Android Configuration ✅
- Application ID: `co.d4dx.qspot`
- Min SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Compile SDK: 34
- ProGuard rules configured
- App icons generated
- Native splash screen configured
- Permissions added

### iOS Configuration ✅
- Bundle Identifier: `co.d4dx.qspot`
- App icons generated
- Info.plist updated
- Privacy permissions added
- Launch screen configured

## 🔧 Manual Steps Required

### Android Release Setup

#### 1. Generate Release Keystore
```bash
keytool -genkey -v -keystore ~/keystore/qspot-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias qspot-key
```

#### 2. Configure Signing
1. Copy `android/key.properties.template` to `android/key.properties`
2. Fill in your keystore details:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=qspot-key
storeFile=../keystore/qspot-release-key.jks
```

#### 3. Update build.gradle.kts for Signing
Add this to `android/app/build.gradle.kts` before android block:
```kotlin
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ... existing config ...
        }
    }
}
```

#### 4. Build Release APK/AAB
```bash
# For AAB (recommended for Play Store)
flutter build appbundle --release

# For APK
flutter build apk --release
```

### iOS Release Setup

#### 1. Xcode Configuration
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Update Team and Bundle Identifier:
   - Team: Select your Apple Developer Team
   - Bundle Identifier: `co.d4dx.qspot`

#### 2. App Store Connect Setup
1. Create app in App Store Connect
2. Set Bundle ID: `co.d4dx.qspot`
3. Configure app information, screenshots, and description

#### 3. Build and Archive
```bash
# Build iOS release
flutter build ios --release

# Or use Xcode:
# Product > Archive in Xcode
```

## 📱 Store Listing Information

### App Store & Play Store Details

**App Name**: QSpot

**Short Description**: Your Space for Quran Vibes

**Full Description**:
Discover inspiring Islamic content with QSpot - your dedicated platform for Quran videos and Islamic knowledge. Access content from renowned speakers and scholars, featuring:

✨ **Features:**
- High-quality Islamic video content
- Intuitive dark theme interface
- Progress tracking for videos
- Content from respected Islamic scholars
- Smooth video playback experience
- Offline-friendly progress saving

🎯 **Categories:**
- Quranic studies and recitations
- Islamic lectures and talks
- Educational content from scholars
- Spiritual guidance and inspiration

📚 **Content by Subject:**
- Quran studies and interpretation
- Hadith teachings and explanations
- Islamic knowledge and guidance

🔧 **Technical Features:**
- Beautiful, modern UI with dark theme
- Seamless YouTube video integration
- Local progress tracking
- Network-optimized streaming
- Cross-platform compatibility

Perfect for anyone seeking authentic Islamic knowledge and Quranic wisdom in a modern, accessible format.

**Keywords**: Islam, Quran, Islamic videos, Muslim app, Quran recitation, Islamic education, Islamic scholars, Islamic knowledge, Muslim community

**Category**: Education / Religion & Spirituality

**Age Rating**: 4+ (Everyone)

## 🖼️ Required Assets

### App Icons ✅
- Generated for all platforms using `flutter_launcher_icons`
- Source: `assets/icons/Icon.png`

### Screenshots Needed
Create screenshots for:

**Android (Play Store)**:
- Phone: 1080x1920, 1080x2340, 1440x2560, 1440x2960
- Tablet: 1200x1920, 1600x2560
- 10-inch tablet: 1920x1200, 2560x1600

**iOS (App Store)**:
- iPhone 6.7": 1290x2796
- iPhone 6.5": 1242x2688  
- iPhone 5.5": 1242x2208
- iPad Pro 12.9": 2048x2732
- iPad Pro 11": 1668x2388

### Feature Graphic
- Android: 1024x500 px
- iOS: Not required

## 🚀 Build Commands

### Development Build
```bash
flutter run --debug
```

### Release Build
```bash
# Android
flutter build appbundle --release
flutter build apk --release

# iOS
flutter build ios --release
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

## 📋 Pre-Release Checklist

### Testing
- [ ] Test on multiple Android devices/emulators
- [ ] Test on multiple iOS devices/simulators
- [ ] Test video playback functionality
- [ ] Test progress tracking
- [ ] Test navigation and UI
- [ ] Test network connectivity scenarios
- [ ] Verify app performance
- [ ] Test app icons and splash screen

### Store Requirements
- [ ] App signed with release certificate
- [ ] Privacy policy accessible
- [ ] App description and metadata ready
- [ ] Screenshots prepared
- [ ] App tested on target OS versions
- [ ] Content rating completed
- [ ] Store listing optimized

### Security
- [ ] No debug code in release
- [ ] API keys properly configured
- [ ] Network security implemented
- [ ] User data protection verified

## 🔐 Security Notes

1. **Never commit** `key.properties` to version control
2. **Secure your keystore** - back it up safely
3. **Use environment variables** for sensitive data in CI/CD
4. **Enable ProGuard** for Android release builds
5. **Test thoroughly** before store submission

## 📞 Support Information

**Developer**: D4DX Innovations LLP
**Website**: https://d4dx.co
**Contact**: mail@d4dx.co
**Privacy Policy**: https://d4dx.co/privacy-policy/

---

For questions or support during the release process, contact the D4DX development team. 