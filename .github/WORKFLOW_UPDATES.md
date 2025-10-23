# Firebase Test Lab Workflow Updates

## Summary

Both Android and iOS workflows have been updated to properly build and reference artifacts for Firebase Test Lab testing.

---

## Android Workflow (`patrol_ci_android.yml`)

### Changes Made

1. **Added `--project` flag**
   - Explicitly specifies the Firebase project ID
   - Format: `--project=${{ secrets.FIREBASE_PROJECT_ID }}`

2. **Added APK validation**
   - Checks that both app and test APKs exist before running tests
   - Provides clear error messages if files are missing
   - Lists directory contents for debugging

3. **Improved artifact paths**
   - Uses variables for clarity: `APP_APK` and `TEST_APK`
   - Properly quoted paths to handle spaces

### Build Artifacts

- **App APK**: `build/app/outputs/apk/debug/app-debug.apk`
- **Test APK**: `build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk`

### Test Devices

- **Virtual**: `MediumPhone.arm` on API 31
- **Physical**: Samsung Galaxy S24 (`e1q`) on API 34

### Command Structure

```bash
gcloud firebase test android run \
  --project=YOUR_PROJECT_ID \
  --type instrumentation \
  --use-orchestrator \
  --app build/app/outputs/apk/debug/app-debug.apk \
  --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=MediumPhone.arm,version=31,locale=en,orientation=portrait \
  --device model=e1q,version=34,locale=en,orientation=portrait \
  --timeout 10m
```

---

## iOS Workflow (`patrol_ci_ios.yml`)

### Changes Made

1. **Renamed build step**
   - Changed from "Build iOS test bundle" to "Build iOS app and test bundle"
   - Now explicitly builds both `.ipa` (app) and test artifacts

2. **Enhanced artifact discovery**
   - Finds and validates both `.ipa` and `.xctestrun` files
   - Provides clear error messages if files are missing
   - Lists all build artifacts for debugging

3. **Improved packaging**
   - Validates `.ipa` file exists before packaging
   - Validates `.xctestrun` file exists before packaging
   - Creates proper zip archive with test bundle
   - Copies `.ipa` to build root for easy access

4. **Updated test execution**
   - Added `--type xctest` flag (required for iOS)
   - Added `--app` parameter pointing to `.ipa` file
   - Dynamically finds `.ipa` file instead of hardcoding path
   - Validates `.ipa` exists before running tests

### Build Artifacts

- **App Bundle (.ipa)**: Located in `build/ios_integ/Build/Products/Release-iphoneos/`
- **Test Bundle (zip)**: `build/ios_integ/Build/Products/ios_tests.zip`
  - Contains `.xctestrun` file and app structure

### Test Devices

- **iPhone 13**: iOS 17
- **iPhone 15 Pro**: iOS 18

### Command Structure

```bash
gcloud firebase test ios run \
  --type xctest \
  --app path/to/app.ipa \
  --test build/ios_integ/Build/Products/ios_tests.zip \
  --device model=iphone13,version=17,locale=en_US,orientation=portrait \
  --device model=iphone15pro,version=18,locale=en_US,orientation=portrait \
  --timeout 10m
```

---

## Key Improvements

### Error Handling
- ✅ Validates all required files exist before running tests
- ✅ Provides clear error messages with file paths
- ✅ Lists directory contents for debugging

### Clarity
- ✅ Uses descriptive variable names
- ✅ Improved step naming
- ✅ Better logging and status messages

### Robustness
- ✅ Properly quoted paths
- ✅ Dynamic file discovery
- ✅ Explicit project ID specification

---

## Testing the Workflows

### Local Testing (Before Pushing)

**Android:**
```bash
# Build APKs locally
patrol build android \
  --target integration_test/cardCanBeFrozenOrUnfreeze_test.dart \
  --dart-define=PATROL_EMAIL="your-email" \
  --dart-define=PATROL_PASSWORD="your-password"

# Verify APKs exist
ls -lh build/app/outputs/apk/debug/app-debug.apk
ls -lh build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
```

**iOS:**
```bash
# Build iOS artifacts
patrol build ios \
  --target integration_test/cardCanBeFrozenOrUnfreeze_test.dart \
  --dart-define=PATROL_EMAIL="your-email" \
  --dart-define=PATROL_PASSWORD="your-password" \
  --release

# Verify artifacts exist
find build/ios_integ/Build/Products/Release-iphoneos -name "*.ipa" -o -name "*.xctestrun"
```

### CI Testing

1. Push to `test_playground` branch
2. Monitor GitHub Actions → "Patrol Android CI" or "Patrol iOS CI"
3. Check logs for validation messages
4. View results in Firebase Console → Test Lab

---

## Troubleshooting

### APK Not Found (Android)
- Ensure `patrol build android` completed successfully
- Check that test credentials are valid
- Verify `integration_test/` directory exists with test files

### IPA Not Found (iOS)
- Ensure `patrol build ios --release` completed successfully
- Check Xcode build logs for errors
- Verify iOS deployment target is compatible

### Firebase Test Lab Errors
- Verify `FIREBASE_SERVICE_ACCOUNT` secret is valid
- Ensure `FIREBASE_PROJECT_ID` is correct
- Check that Test Lab API is enabled in Firebase Console
- Verify service account has `roles/firebase.testLabUser` role

---

## Next Steps

1. ✅ Commit and push these workflow changes
2. ✅ Verify secrets are configured in GitHub
3. ✅ Trigger a test run on `test_playground` branch
4. ✅ Monitor the workflow execution
5. ✅ Check Firebase Console for test results
