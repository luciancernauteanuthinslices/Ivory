# Suggested Commit Message

```
Fix: Resolve CI permission dialog hangs on iOS and Android

## Problem
- Tests were hanging in CI during login flow due to notification permission dialogs
- Permissions were being granted BEFORE app installation (no effect)
- Both iOS and Android affected
- 100% failure rate in CI, works fine locally

## Solution
Implemented 3-layer fix:

### 1. Pre-Grant Permissions (After Installation)
- **Android**: Background script monitors for app installation, grants immediately
- **iOS**: Install app first, grant permissions via xcrun simctl, then test
- Key: Permissions granted AFTER app exists

### 2. CI Detection
- New CIDetection utility auto-detects CI environments
- Tests use fast timeouts in CI, patient timeouts locally
- Adapts behavior based on environment

### 3. Smart Dialog Handling  
- Improved timeout logic in login flow
- Multiple fallback strategies
- Never blocks - continues even if uncertain about dialog state

## Files Changed
- android/fastlane/Fastfile - Fixed permission timing
- android/grant_permissions.sh - NEW: Background permission granter
- ios/fastlane/Fastfile - Fixed permission timing
- integration_test/auth/loginToApp.dart - Smarter permission handling
- integration_test/helpers/permissionsHelper.dart - CI-aware behavior
- integration_test/helpers/ciDetection.dart - NEW: CI detection
- .gitignore - Ignore test log files

## Testing
- ✅ Verified all files present
- ✅ Scripts executable
- ✅ No linter errors
- Ready for CI testing

## Documentation
- CI_PERMISSION_HANDLING.md - Complete technical guide
- PERMISSION_FIX_SUMMARY.md - Quick reference
- BEFORE_AFTER_FLOW.md - Visual flow comparison

Closes: #[issue-number]
```

# Alternative Short Commit Message

```
Fix: Grant permissions after app installation in CI

Previously permissions were granted before app installation, which had no
effect. Now permissions are granted immediately after installation for both
Android (via background script) and iOS (via xcrun simctl), preventing
permission dialogs from blocking test execution.

Adds CI detection to optimize timeout behavior.
```

# Git Commands

```bash
# Review changes
git diff

# Stage all changes
git add android/fastlane/Fastfile \
        android/grant_permissions.sh \
        ios/fastlane/Fastfile \
        integration_test/auth/loginToApp.dart \
        integration_test/helpers/permissionsHelper.dart \
        integration_test/helpers/ciDetection.dart \
        integration_test/CI_PERMISSION_HANDLING.md \
        PERMISSION_FIX_SUMMARY.md \
        BEFORE_AFTER_FLOW.md \
        verify_permission_fix.sh \
        .gitignore

# Commit
git commit -m "Fix: Resolve CI permission dialog hangs on iOS and Android"

# Push to branch
git push origin patrol_allure_ST
```

