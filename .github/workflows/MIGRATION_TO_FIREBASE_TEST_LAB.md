# Migration to Firebase Test Lab - Summary

## What Changed

Your Patrol CI workflows have been migrated from GitHub-hosted runners to Firebase Test Lab for better performance, reliability, and cost efficiency.

### Before (Old Approach)
- **Android**: Slow, unreliable GitHub-hosted Ubuntu emulators
- **iOS**: Expensive macOS runners with local iOS simulators
- **Issues**: Flaky tests, long execution times, high CI costs

### After (New Approach)
- **Android**: Fast cloud-based Firebase Test Lab physical devices
- **iOS**: Reduced macOS build time + Firebase Test Lab physical devices
- **Benefits**: Faster, more reliable, better debugging, parallel testing

## Files Modified

1. **`.github/workflows/patrol_ci_android.yml`**
   - Now builds APKs with `patrol build android`
   - Authenticates with Google Cloud
   - Runs tests on Firebase Test Lab devices
   - Tests on Android 12 (API 31) and Android 14 (API 34)

2. **`.github/workflows/patrol_ci_ios.yml`**
   - Builds iOS test bundle on macOS
   - Packages files for Firebase Test Lab
   - Runs tests on cloud iOS devices
   - Tests on iPhone 13 (iOS 16.6) and iPhone 14 Pro (iOS 17.4)

3. **`FIREBASE_TEST_LAB_SETUP.md`** (NEW)
   - Complete setup guide for Firebase Test Lab
   - Step-by-step instructions for service account creation
   - GitHub Secrets configuration
   - Troubleshooting guide

## Required Actions

### 1. Configure GitHub Secrets

You must add these secrets to your GitHub repository:

| Secret Name | How to Get It |
|-------------|---------------|
| `FIREBASE_SERVICE_ACCOUNT` | Follow steps in `FIREBASE_TEST_LAB_SETUP.md` (base64-encoded JSON) |
| `FIREBASE_PROJECT_ID` | Your Firebase project ID (e.g., `ivory-app-123456`) |

**Note**: You mentioned you have `EW_API_TOKEN` stored - that was for emulator.wtf. You can safely remove it as it's no longer needed.

### 2. Existing Secrets (Already Set)

These should already be configured in your repo:
- `PATROL_EMAIL`
- `PATROL_PASSWORD`
- `COGNITO_USER_POOL_ID`
- `COGNITO_CLIENT_ID`
- `API_BASE_URL`
- `GEONAMES_USERNAME`

## Setup Steps (Quick Start)

1. **Create Firebase Project**
   ```
   → Go to https://console.firebase.google.com/
   → Create or select a project
   → Note the Project ID
   ```

2. **Enable Firebase Test Lab API**
   ```
   → Go to https://console.cloud.google.com/
   → APIs & Services → Library
   → Search "Firebase Test Lab API" → Enable
   ```

3. **Create Service Account**
   ```
   → IAM & Admin → Service Accounts → Create
   → Grant "Editor" role
   → Create JSON key
   → Base64 encode it
   ```

4. **Add GitHub Secrets**
   ```
   → GitHub repo → Settings → Secrets → Actions
   → Add FIREBASE_SERVICE_ACCOUNT (base64 string)
   → Add FIREBASE_PROJECT_ID (your project ID)
   ```

5. **Test It**
   ```
   → Push a commit or manually trigger workflow
   → Check GitHub Actions tab
   → View results in Firebase Console → Test Lab
   ```

**Full detailed instructions**: See `FIREBASE_TEST_LAB_SETUP.md`

## Key Differences

### Android Workflow

**Old**:
```yaml
- name: Start Android emulator and run Patrol
  uses: reactivecircus/android-emulator-runner@v2
  with:
    api-level: 31
    script: patrol test integration_test/ --verbose
```

**New**:
```yaml
- name: Build APKs with Patrol
  run: patrol build android --target integration_test/test.dart --verbose

- name: Run tests on Firebase Test Lab
  run: gcloud firebase test android run \
    --app build/app/outputs/apk/debug/app-debug.apk \
    --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
```

### iOS Workflow

**Old**:
```yaml
- name: Boot iOS Simulator
  uses: futureware-tech/simulator-action@v3

- name: Run Patrol on iOS
  run: patrol test integration_test/ --verbose
```

**New**:
```yaml
- name: Build iOS test bundle with Patrol
  run: patrol build ios --target integration_test/test.dart --release

- name: Package iOS test bundle
  run: zip -r ios_tests.zip Release-iphoneos *.xctestrun

- name: Run tests on Firebase Test Lab
  run: gcloud firebase test ios run --test ios_tests.zip
```

## Workflow Features

### Both workflows support:

✅ **Manual test filtering** - Run specific test files via workflow dispatch
```yaml
test_filter: cardCanBeFrozenOrUnfreeze_test.dart
```

✅ **Multiple device testing** - Tests run on 2 devices per platform automatically

✅ **Secure credential passing** - Test credentials passed via `--dart-define`

✅ **Detailed logging** - Verbose output for debugging

✅ **Artifact uploads** - Test APKs/bundles uploaded for inspection

## Cost Comparison

### Old Approach (GitHub-hosted)
- Android: Free but slow/unreliable
- iOS: ~$0.08/minute on macOS runners = expensive!
- Total: High cost for iOS, poor quality for Android

### New Approach (Firebase Test Lab)
- **Free tier**: 5 virtual tests/day + 10 physical tests/day
- **Paid**: ~$1-5 per test hour (if exceeding free tier)
- **macOS time**: Only for building (5-10 min vs 30+ min)
- Total: Lower cost, better quality, more devices

## Testing the Migration

### Option 1: Manual Trigger
1. Go to **Actions** tab in GitHub
2. Select **Patrol Android CI - Firebase Test Lab** or **Patrol iOS CI - Firebase Test Lab**
3. Click **Run workflow**
4. Optionally specify `test_filter` for a single test file
5. Click **Run workflow**

### Option 2: Push Commit
Push any commit to `main`, `test_playground`, or `SOL-*` branches and workflows will run automatically.

### Option 3: Open PR
Create a PR targeting `main` or `test_playground` and workflows will run on the PR.

## Viewing Results

### GitHub Actions
- Real-time logs in GitHub Actions tab
- Shows build progress and gcloud command output

### Firebase Console
1. Go to https://console.firebase.google.com/
2. Select your project
3. Navigate to **Test Lab** (left sidebar)
4. View detailed results:
   - Test execution videos
   - Device logs
   - Screenshots
   - Performance metrics
   - Test status per device

### Cloud Storage
Results are stored in Google Cloud Storage:
- Bucket: `gs://<your-project-id>_test_results`
- Directory structure: `patrol-android-YYYYMMDD_HHMMSS/`

## Troubleshooting

### "Permission denied" errors
→ Verify service account has "Editor" or "Firebase Test Lab Admin" role
→ Check Firebase Test Lab API is enabled

### "Test quota exceeded"
→ Free tier limit reached (10 physical device tests/day)
→ Upgrade to Blaze plan or wait 24h

### iOS build fails
→ Ensure running on macOS (workflow uses `macos-14`)
→ Check CocoaPods installation

### Tests timeout
→ Increase `--timeout` in workflow (default: 10m)
→ Check Firebase Console for actual test execution logs

**Full troubleshooting guide**: See `FIREBASE_TEST_LAB_SETUP.md`

## Rollback Plan

If you need to temporarily revert to the old approach:

1. Check out the previous commit before this migration
2. Restore the old workflow files
3. Or keep both workflows and disable the new ones

Git history preserves the old workflows if needed.

## Next Steps

1. ✅ **Complete Firebase setup** (see `FIREBASE_TEST_LAB_SETUP.md`)
2. ✅ **Add GitHub Secrets** (`FIREBASE_SERVICE_ACCOUNT`, `FIREBASE_PROJECT_ID`)
3. ✅ **Test the workflows** (push a commit or manual trigger)
4. 🎯 **Monitor first runs** in Firebase Console
5. 🎯 **Adjust device matrix** as needed
6. 🎯 **Remove old secrets** (like `EW_API_TOKEN` if no longer needed)

## Questions?

- **Setup help**: Read `FIREBASE_TEST_LAB_SETUP.md`
- **Firebase docs**: https://firebase.google.com/docs/test-lab
- **Patrol docs**: https://patrol.leancode.co/documentation/ci/firebase-test-lab
- **Issues**: Check GitHub Actions logs and Firebase Console

---

**Migration completed!** 🎉 Your workflows are now ready for faster, more reliable testing with Firebase Test Lab.
