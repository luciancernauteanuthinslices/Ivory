# Seon SDK Fix for CI/Test Environment

## Problem Identified

**Root Cause:** Seon fraud detection SDK was blocking login in CI/emulator environments.

### Evidence:
1. **No API calls in logs** - After tapping Continue, no Cognito authentication requests were made
2. **`pumpAndSettle` timeout** - UI stuck in loading animation, never progressing to OTP screen
3. **Seon SDK integration** - Found in `MainActivity.kt` (lines 27-44) calling `SeonBuilder().getFingerprintBase64()`
4. **Hard failure** - If `getDeviceFingerprint()` returns `null`, auth fails with `AuthErrorType.cantCreateFingerprint`

### Login Flow with Seon:
```
User taps Continue
  → AuthMiddleware.InitUserAuthenticationCommandAction
  → Cognito login (success)
  → createDeviceConsent() [API call]
  → getDeviceFingerprint() [Native Seon SDK call] ❌ FAILS IN CI
  → If null → AuthFailedEventAction(cantCreateFingerprint)
  → Login blocked, never reaches OTP screen
```

## Solution Implemented

### 1. **Bypass Seon in Test Environment**
Modified `/lib/infrastructure/device/device_fingerprint_service.dart`:

```dart
// Added at top of file
const bool kIsPatrolTestEnv = bool.fromEnvironment('PATROL_TEST', defaultValue: false);

// Modified getDeviceFingerprint() method
Future<String?> getDeviceFingerprint(String? consentId) async {
  if (consentId == null) return null;

  // In test/CI environment, return a mock fingerprint to bypass Seon SDK
  if (kIsPatrolTestEnv) {
    debugPrint('🧪 PATROL_TEST mode: Using mock device fingerprint');
    return 'mock_device_fingerprint_for_ci_testing_${consentId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  try {
    // Normal Seon SDK call for production
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _platform.invokeMethod(getDeviceFingerprintMethod, {'consentId': consentId});
    }
    // ... iOS handling
  } catch (e) {
    debugPrint('⚠️  Device fingerprint error: $e');
    // Fallback to mock in test mode even on error
    if (kIsPatrolTestEnv) {
      return 'mock_device_fingerprint_error_fallback_${consentId}';
    }
    return null;
  }
}
```

### 2. **How It Works**
- **Production:** Normal Seon SDK fingerprinting (fraud detection active)
- **CI/Tests:** Mock fingerprint returned, bypassing native SDK
- **Flag:** `--dart-define=PATROL_TEST=true` (already passed in Fastlane)

### 3. **Files Modified**
- ✅ `/lib/infrastructure/device/device_fingerprint_service.dart`
- ✅ `/integration_test/auth/loginToApp.dart` (replaced `pumpAndSettle` with iterative `pump`)
- ✅ `/.github/workflows/fastlane-ci.yml` (added all required env vars)

## Testing

### Local Test Command:
```bash
patrol test android --target integration_test/login_test.dart --verbose --dart-define=PATROL_TEST=true
```

### Expected Logs:
```
🧪 PATROL_TEST mode: Using mock device fingerprint
✅ OTP screen detected!
Has access token: true
```

### CI Workflow:
Already configured - Fastlane passes `--dart-define=PATROL_TEST=true` automatically.

## Backend Consideration

**Note:** The backend API still receives the mock fingerprint string. If backend has strict Seon validation:

### Option A: Accept mock fingerprints (recommended for CI)
Backend should allow fingerprints matching pattern `mock_device_fingerprint_*` in test environments.

### Option B: Disable Seon validation for test users
Configure backend to skip Seon checks for specific test accounts.

## Verification Checklist

- [x] Seon SDK identified as blocker
- [x] Mock fingerprint implementation added
- [x] Test environment detection via `PATROL_TEST` flag
- [x] Fallback handling for errors
- [x] Debug logging added
- [ ] Local test passes with mock fingerprint
- [ ] CI test passes with mock fingerprint
- [ ] Backend accepts mock fingerprint OR validation disabled for test users

## GitHub Secrets Required

Ensure these are configured in repo Settings → Secrets:
```
COGNITO_USER_POOL_ID = eu-west-1_qy1q4kreP
COGNITO_CLIENT_ID = 37pa10mkkkbqr62q66916jdma0
API_BASE_URL = jsxhc7emf3.execute-api.eu-west-1.amazonaws.com (NO https://)
GEONAMES_USERNAME = itudor90
PATROL_EMAIL = <valid_test_email>
PATROL_PASSWORD = <valid_test_password>
```

## Next Steps

1. ✅ Run local Patrol test to verify Seon bypass
2. ⏳ Check if backend accepts mock fingerprint
3. ⏳ If backend rejects: Configure backend to allow mock fingerprints for test environment
4. ⏳ Push to CI and verify tests pass
5. ⏳ Monitor logs for "🧪 PATROL_TEST mode: Using mock device fingerprint"
