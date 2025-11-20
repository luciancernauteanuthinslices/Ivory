# CI Permission Handling Guide

## Problem
Permission dialogs (especially notification permissions on Android 13+ and iOS) were blocking test execution in CI environments, causing tests to hang or timeout.

## Solution Overview

We've implemented a multi-layered approach to handle permissions in CI:

### 1. **Pre-Grant Permissions (iOS & Android)**

#### Android (`android/fastlane/Fastfile`)
- Uninstalls any existing app version
- Starts a background script (`android/grant_permissions.sh`) that monitors for app installation
- When the app is detected, automatically grants all necessary permissions
- Runs Patrol tests normally
- The script grants permissions including:
  - POST_NOTIFICATIONS (Android 13+)
  - Location permissions
  - Camera, Microphone
  - Storage/Media permissions

#### iOS (`ios/fastlane/Fastfile`)
- Builds the app and test bundle
- Installs the app on the simulator BEFORE running tests
- Resets all permissions to clean state
- Grants all necessary permissions using `xcrun simctl privacy`
- Then runs the tests with permissions already granted

### 2. **Intelligent Permission Dialog Handling**

#### CI Detection (`integration_test/helpers/ciDetection.dart`)
New utility that detects if tests are running in a CI environment by checking common CI environment variables:
- GITHUB_ACTIONS
- GITLAB_CI
- CIRCLECI
- TRAVIS
- And many others

Returns:
- `CIDetection.isCI` - boolean indicating if running in CI
- `CIDetection.ciPlatform` - name of the CI platform

#### Improved Permission Helper (`integration_test/helpers/permissionsHelper.dart`)
- Accepts `isCI` parameter to adjust behavior
- In CI mode:
  - Uses shorter timeouts (300ms vs 2s)
  - Fewer retry attempts (2 vs 3)
  - Assumes permissions are pre-granted and fails fast
- In local mode:
  - More patient with longer timeouts
  - More retry attempts
  - Better UX for manual testing

#### Updated Login Flow (`integration_test/auth/loginToApp.dart`)
- Detects CI environment automatically
- Uses CI-appropriate timeouts and retry logic
- Logs CI platform information for debugging
- Has fallback strategies if permission dialogs still appear
- Never blocks execution - continues even if dialog handling uncertain

### 3. **Key Improvements**

1. **Timing**: Permissions are granted AFTER app installation (not before)
2. **Verification**: Both platforms verify permissions were granted
3. **Logging**: Enhanced logging to help debug permission issues
4. **Resilience**: Multiple fallback strategies
5. **Speed**: CI mode uses fast-fail approach since permissions should be pre-granted

## Usage

### Local Testing
No changes needed - the code automatically detects local environment and uses patient, user-friendly permission handling.

### CI Testing

#### Android (GitHub Actions)
```yaml
- name: Run Android Tests
  run: |
    cd android
    bundle exec fastlane test
```

The Fastfile will:
1. Clean existing installations
2. Start background permission granting
3. Run tests with `patrol test`
4. Permissions are granted automatically when app is installed

#### iOS (GitHub Actions)
```yaml
- name: Run iOS Tests
  run: |
    cd ios
    bundle exec fastlane test
```

The Fastfile will:
1. Build app and test bundle
2. Install app on simulator
3. Grant permissions
4. Run tests

## Environment Variables

Tests can detect CI environment automatically, but you can also force CI mode by setting:
```bash
export CI=true
```

## Troubleshooting

### Android
If tests still hang on permissions:

1. Check logs to see if permissions were granted:
```bash
adb shell dumpsys package com.thinslices.solarisdemo | grep permission
```

2. Manually grant permissions:
```bash
adb shell pm grant com.thinslices.solarisdemo android.permission.POST_NOTIFICATIONS
```

3. Check Android version - POST_NOTIFICATIONS only exists on Android 13+ (API 33+)

### iOS
If tests still hang on permissions:

1. Check if permissions were granted:
```bash
xcrun simctl privacy <device_id> list
```

2. Manually grant notification permission:
```bash
xcrun simctl privacy <device_id> grant notification com.thinslices.solarisdemo
```

3. Reset simulator to clean state:
```bash
xcrun simctl erase <device_id>
```

## Technical Details

### Why Grant After Installation?
Permissions can only be granted to installed apps. Previous implementation tried to grant before installation, which had no effect.

### Why Background Script for Android?
Patrol's `patrol test` command handles build, install, and test execution as one atomic operation. We can't easily inject permission granting between install and test start. The background script solves this by monitoring for app installation and immediately granting permissions.

### Why Direct Install for iOS?
iOS simulators allow more granular control through `xcrun simctl`. We can build, install, grant permissions, then run tests as separate steps.

## Files Modified

1. `android/fastlane/Fastfile` - Updated test lane
2. `android/grant_permissions.sh` - New background script
3. `ios/fastlane/Fastfile` - Updated test lane
4. `integration_test/auth/loginToApp.dart` - Improved permission handling
5. `integration_test/helpers/permissionsHelper.dart` - Added CI mode support
6. `integration_test/helpers/ciDetection.dart` - New CI detection utility

## Testing

### Test Locally
```bash
# Android
cd android
bundle exec fastlane test

# iOS
cd ios
bundle exec fastlane test
```

### Test in CI
Push changes to a branch that triggers your CI workflow. Check the logs for:
- "Running in CI environment: [Platform]"
- "Permissions granted successfully"
- No timeout errors during login

## Notes

- Permission granting is logged for debugging
- Scripts use `|| true` to continue even if some permissions can't be granted (e.g., on older OS versions)
- CI mode prioritizes speed and assumes pre-granted permissions
- Local mode prioritizes reliability and user experience

