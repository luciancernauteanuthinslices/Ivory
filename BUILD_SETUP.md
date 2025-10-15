# Build Configuration

This document outlines the build configuration changes made to support the current Flutter environment while keeping dependencies as close as possible to their original versions.

## Changes Made

### 1. Flutter Dependencies
- Installed all dependencies from `pubspec.yaml` using `flutter pub get`
- All dependencies maintained at their specified versions
- No dependency upgrades were performed

### 2. Environment Configuration
- Created `.env` file from `.env.example` template
- Required environment variables:
  - `COGNITO_USER_POOL_ID`
  - `COGNITO_CLIENT_ID`
  - `API_BASE_URL`
  - `GEONAMES_USERNAME`

### 3. Gradle Configuration Updates

#### Gradle Wrapper (`android/gradle/wrapper/gradle-wrapper.properties`)
- **Updated:** Gradle version from `8.3` to `8.7`
- **Reason:** Minimum required version for Flutter compatibility

#### Android Settings (`android/settings.gradle`)
- **Updated:** Android Gradle Plugin from `8.1.0` to `8.2.1`
- **Reason:** Required for Java 21 compatibility and modern Flutter support
- **Note:** Kotlin version kept at `1.9.0` (warnings present but functional)

#### App Build Configuration (`android/app/build.gradle`)
- **Added:** Core library desugaring support
  ```gradle
  compileOptions {
      coreLibraryDesugaringEnabled true
      sourceCompatibility JavaVersion.VERSION_1_8
      targetCompatibility JavaVersion.VERSION_1_8
  }
  ```
- **Added:** Desugaring dependency
  ```gradle
  coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
  ```
- **Reason:** Required by `flutter_local_notifications` package

#### Gradle Properties (`android/gradle.properties`)
- **Updated:** JVM heap size from `-Xmx1536M` to `-Xmx4096M`
- **Reason:** Prevent Java heap space errors during build

### 4. iOS Configuration

#### Podfile (`ios/Podfile`)
- **Platform:** iOS 15.6 minimum deployment target
- **Pods configured:**
  - `SeonSDK 4.0.0` - Device fingerprinting
  - `JOSESwift` - JWT encryption
  - Custom bitcode stripping for SeonSDK framework

#### Runner Configuration
- **No changes required** - iOS project builds successfully for simulator
- **Note:** Deprecation warning present in `AppDelegate.swift` for `rootViewController` access
  - This is a known Flutter migration path issue
  - Does not prevent builds or functionality
  - Will be addressed when migrating to UISceneDelegate in the future

#### Prerequisites for iOS Build
1. Xcode installed (tested with latest version)
2. CocoaPods installed: `sudo gem install cocoapods`
3. iOS Simulator available (comes with Xcode)
4. Run `pod install` in `ios` directory (done automatically by Flutter)

## Build Commands

### Android Debug Build
```bash
flutter build apk --debug --dart-define=CLIENT=default
```

### Android Release Build
```bash
flutter build appbundle --dart-define=CLIENT=default
```

### iOS Simulator Build
```bash
flutter build ios --simulator --debug --dart-define=CLIENT=default
```

### iOS Device Build
```bash
flutter build ipa --dart-define=CLIENT=default
```

### Run on iOS Simulator
```bash
# List available simulators
xcrun simctl list devices available

# Build and run on a specific simulator
flutter run -d <device-id> --dart-define=CLIENT=default

# Build and run on any available iPhone simulator
flutter run -d iPhone --dart-define=CLIENT=default
```

### Using Makefile
The project includes a Makefile with convenient commands:

```bash
# Clean build
make clean

# Install dependencies
make install

# Run tests
make unit-test

# Build Android
make build-android CLIENT=default

# Build iOS
make build-ios CLIENT=default

# Full release (clean, install, test, build)
make release CLIENT=default
```

## Known Warnings

The following warnings appear during build but do not prevent successful compilation:

### Android Warnings
1. **Android Gradle Plugin version warning**: AGP 8.2.1 is functional but Flutter recommends 8.6.0+
2. **Kotlin version warning**: Kotlin 1.9.0 is functional but Flutter recommends 2.1.0+
3. **SDK processing warning**: Version mismatch between Android Studio and command-line tools (cosmetic)
4. **Java version warnings**: Source/target value 8 is obsolete (but required for compatibility)

### iOS Warnings
1. **Flutter deprecation warning**: `rootViewController` access in `application:didFinishLaunchingWithOptions:`
   - This is related to UISceneDelegate migration
   - Does not affect functionality
   - Will be addressed in future Flutter migrations

These warnings are intentionally kept as-is to maintain compatibility with the existing codebase and dependencies.

## Version Summary

### Android
| Component | Original | Updated | Notes |
|-----------|----------|---------|-------|
| Gradle | 8.3 | 8.7 | Minimum required |
| Android Gradle Plugin | 8.1.0 | 8.2.1 | Java 21 compatibility |
| JVM Heap Size | 1536M | 4096M | Prevent build errors |
| Core Desugaring | Not enabled | Enabled | Required by dependencies |

### iOS
| Component | Version | Notes |
|-----------|---------|-------|
| Minimum iOS Target | 15.6 | As configured in Podfile |
| SeonSDK | 4.0.0 | Device fingerprinting |
| JOSESwift | Latest | JWT encryption |
| CocoaPods | Required | Dependency manager |

## Troubleshooting

### Build fails with heap space error
Increase the heap size in `android/gradle.properties`:
```
org.gradle.jvmargs=-Xmx4096M
```

### Missing environment variables
Copy `.env.example` to `.env` and fill in the required values.

### iOS Pod Installation Issues
If you encounter CocoaPods errors:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

### iOS Simulator Not Found
List available simulators:
```bash
xcrun simctl list devices available
```

If no simulators are available, open Xcode and install iOS Simulator from:
**Xcode → Settings → Platforms → iOS**

### Clean build
If you encounter persistent build issues:

**Android:**
```bash
flutter clean
flutter pub get
flutter build apk --debug --dart-define=CLIENT=default
```

**iOS:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
flutter build ios --simulator --debug --dart-define=CLIENT=default
```
