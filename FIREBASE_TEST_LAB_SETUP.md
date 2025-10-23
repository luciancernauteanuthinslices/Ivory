# Firebase Test Lab Setup Guide

This guide walks you through setting up Firebase Test Lab for running Patrol integration tests in the cloud.

## Benefits of Firebase Test Lab

- **Fast & Reliable**: Tests run on real physical devices in Google's data centers
- **Cost Effective**: Reduces expensive macOS CI minutes and eliminates unreliable GitHub-hosted Android emulators
- **Parallel Testing**: Run tests on multiple devices simultaneously
- **Better Debugging**: Access to detailed logs, videos, and screenshots from real devices

## Prerequisites

1. A Google Cloud/Firebase account
2. A Firebase project (free Spark plan includes daily test quota)
3. Billing enabled on your Google Cloud project (required for Test Lab, but free tier available)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** or select an existing project
3. Follow the setup wizard
4. Note your **Project ID** (you'll need this later)

## Step 2: Enable Firebase Test Lab API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Navigate to **APIs & Services** → **Library**
4. Search for "**Firebase Test Lab API**"
5. Click **Enable**

## Step 3: Create Service Account

A service account allows GitHub Actions to authenticate with Firebase Test Lab.

1. In Google Cloud Console, go to **IAM & Admin** → **Service Accounts**
2. Click **Create Service Account**
3. Fill in details:
   - **Name**: `github-actions-firebase-testlab` (or any name you prefer)
   - **Description**: `Service account for running Firebase Test Lab from GitHub Actions`
4. Click **Create and Continue**
5. Grant the following roles:
   - **Editor** (for full Firebase Test Lab access)
   - Or more restrictively: **Firebase Test Lab Admin** + **Storage Object Admin**
6. Click **Continue** → **Done**

## Step 4: Create Service Account Key

1. Find your newly created service account in the list
2. Click the **Actions** menu (three dots) → **Manage keys**
3. Click **Add Key** → **Create new key**
4. Select **JSON** format
5. Click **Create**
6. A JSON file will be downloaded to your computer
7. **Keep this file secure!** It contains credentials to your Google Cloud project

## Step 5: Encode Service Account Key

GitHub Secrets don't handle JSON well, so we need to base64 encode it.

### On macOS/Linux:

```bash
base64 -i path/to/your-service-account-key.json | pbcopy
```

This copies the encoded string to your clipboard.

### On Windows (PowerShell):

```powershell
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("path\to\your-service-account-key.json")) | Set-Clipboard
```

### Alternative (Online):

Visit [https://www.base64encode.org/](https://www.base64encode.org/) and paste the JSON file contents.

## Step 6: Add GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

### Required Secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `FIREBASE_SERVICE_ACCOUNT` | Base64-encoded JSON from Step 5 | Authentication for Firebase Test Lab |
| `FIREBASE_PROJECT_ID` | Your Firebase project ID (e.g., `my-app-123456`) | Firebase project identifier |

### Existing Secrets (should already be set):

| Secret Name | Description |
|-------------|-------------|
| `PATROL_EMAIL` | Test account email for login tests |
| `PATROL_PASSWORD` | Test account password for login tests |
| `COGNITO_USER_POOL_ID` | AWS Cognito configuration |
| `COGNITO_CLIENT_ID` | AWS Cognito configuration |
| `API_BASE_URL` | Backend API URL |
| `GEONAMES_USERNAME` | GeoNames API username |

## Step 7: Create Storage Bucket (Optional but Recommended)

Firebase Test Lab stores test results in Google Cloud Storage. By default, it uses a bucket, but you can create a dedicated one.

1. In Google Cloud Console, go to **Cloud Storage** → **Buckets**
2. Click **Create Bucket**
3. Name it: `<your-project-id>_test_results` (match the pattern in workflows)
4. Choose a location close to your team
5. Select **Standard** storage class
6. Click **Create**

## Step 8: Test Your Setup

1. Push a commit to trigger the workflow
2. Go to **Actions** tab in your GitHub repository
3. Watch the workflow run
4. Check Firebase Test Lab results:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Navigate to **Test Lab** in left sidebar
   - View detailed test results, logs, and videos

## Available Devices

### Android Devices (via Firebase Test Lab)

- Pixel 2 (API 31 - Android 12)
- Pixel 2 (API 34 - Android 14)

To see all available devices:

```bash
gcloud firebase test android models list
```

### iOS Devices (via Firebase Test Lab)

- iPhone 13 (iOS 16.6)
- iPhone 14 Pro (iOS 17.4)

To see all available devices:

```bash
gcloud firebase test ios models list
```

## Customizing Device Matrix

Edit the workflows to test on different devices:

### Android (`patrol_ci_android.yml`):

```yaml
--device model=Pixel2,version=31,locale=en,orientation=portrait \
--device model=Pixel5,version=33,locale=en,orientation=portrait
```

### iOS (`patrol_ci_ios.yml`):

```yaml
--device model=iphone13,version=16.6,locale=en_US,orientation=portrait \
--device model=iphone14pro,version=17.4,locale=en_US,orientation=portrait
```

## Pricing

Firebase Test Lab offers:
- **Free tier**: 5 virtual device tests/day + 10 physical device tests/day
- **Blaze plan** (pay-as-you-go): See [pricing details](https://firebase.google.com/pricing)

Physical devices provide more accurate results but consume your quota faster.

## Troubleshooting

### Error: "Permission denied" or "403 Forbidden"

- Verify your service account has the correct roles (Editor or Firebase Test Lab Admin)
- Check that Firebase Test Lab API is enabled
- Ensure the service account key is correctly base64 encoded

### Error: "Test quota exceeded"

- You've hit the daily free tier limit
- Upgrade to Blaze plan or wait 24 hours for quota reset

### Tests timeout or hang

- Increase timeout in workflow: `--timeout 15m`
- Check Firebase Console for actual test logs
- Verify test credentials (`PATROL_EMAIL`, `PATROL_PASSWORD`) are correct

### iOS build fails

- Ensure you're on macOS runner (`runs-on: macos-14`)
- Clean build artifacts might be cached incorrectly
- Check Xcode version compatibility

### Can't find test results

- Check the Cloud Storage bucket: `gs://<your-project-id>_test_results`
- Results are organized by date/time: `patrol-android-YYYYMMDD_HHMMSS/`
- View directly in Firebase Console → Test Lab

## Advanced Configuration

### Running specific test files

Use workflow dispatch with `test_filter` input:

```bash
# In GitHub Actions UI, trigger workflow manually with:
test_filter: cardCanBeFrozenOrUnfreeze_test.dart
```

### Enabling video recording

Edit the workflow and remove `--no-record-video`:

```yaml
gcloud firebase test android run \
  --record-video \  # Enable video recording
  ...
```

Note: Videos consume more storage and quota.

### Adding test sharding

For faster execution, split tests across multiple devices:

```yaml
--num-uniform-shards=3  # Split tests into 3 parallel shards
```

## Resources

- [Firebase Test Lab Documentation](https://firebase.google.com/docs/test-lab)
- [Patrol Firebase Test Lab Guide](https://patrol.leancode.co/documentation/ci/firebase-test-lab)
- [gcloud firebase test reference](https://cloud.google.com/sdk/gcloud/reference/firebase/test)
- [GitHub Actions: google-github-actions/auth](https://github.com/google-github-actions/auth)

## Next Steps

1. ✅ Complete this setup
2. ✅ Push a commit to trigger the workflows
3. ✅ Monitor test results in Firebase Console
4. 🎯 Expand device coverage as needed
5. 🎯 Integrate with your deployment pipeline

---

**Need Help?** Check the [Firebase Support](https://firebase.google.com/support) or [Stack Overflow](https://stackoverflow.com/questions/tagged/firebase-test-lab).
