# GitHub Secrets Setup for Patrol CI

## Required Secrets

Configure these in your GitHub repository before running CI workflows.

### Location
`Settings` → `Secrets and variables` → `Actions` → `Repository secrets`

### Required Secrets for Patrol Tests

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `PATROL_EMAIL` | Test account email for integration tests | `lifebloom77@yahoo.com` |
| `PATROL_PASSWORD` | Test account password for integration tests | `TestPass1` |

### Optional Secrets (for complete app config)

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `API_BASE_URL` | Backend API endpoint | `https://api.yourapp.com` |
| `COGNITO_USER_POOL_ID` | AWS Cognito user pool ID | `us-east-1_ABC123` |
| `FIREBASE_CONFIG` | Firebase configuration JSON | `{...}` |

## How to Add Secrets

### Step 1: Navigate to Repository Settings
1. Go to your GitHub repository
2. Click **Settings** (top menu)
3. In left sidebar, click **Secrets and variables** → **Actions**

### Step 2: Add New Secret
1. Click **New repository secret**
2. Enter the **Name** (e.g., `PATROL_EMAIL`)
3. Enter the **Value** (e.g., `lifebloom77@yahoo.com`)
4. Click **Add secret**

### Step 3: Verify Secrets
After adding, you should see:
- ✅ `PATROL_EMAIL`
- ✅ `PATROL_PASSWORD`

## How Secrets Are Used in CI

### Android Workflow (`patrol_ci_android.yml`)

```yaml
# Create .patrol.env with test credentials from GitHub secrets
- name: Create .patrol.env with test credentials
  run: |
    cat > integration_test/.patrol.env << EOF
    EMAIL=${{ secrets.PATROL_EMAIL }}
    PASSWORD=${{ secrets.PATROL_PASSWORD }}
    EOF
```

### iOS Workflow (`patrol_ci_ios.yml`)

Same approach - secrets are injected into `.patrol.env` before tests run.

## Security Notes

- ✅ Secrets are **encrypted** and never exposed in logs
- ✅ `.patrol.env` is **gitignored** (never committed)
- ✅ Secrets are only available during workflow execution
- ✅ Use **separate test accounts** for CI (not production accounts)

## Testing Locally

For local testing, create your own `.patrol.env`:

```bash
# Copy example file
cp integration_test/.patrol.env.example integration_test/.patrol.env

# Edit with your test credentials
# This file is gitignored and stays private
```

## Troubleshooting

### Tests fail with empty credentials
- **Cause**: Secrets not set in GitHub repository
- **Solution**: Add `PATROL_EMAIL` and `PATROL_PASSWORD` secrets

### Tests fail with wrong credentials
- **Cause**: Incorrect secret values
- **Solution**: Update secret values in GitHub settings

### Secrets not updating
- **Cause**: GitHub caches workflow files
- **Solution**: Re-run workflow or push a new commit

## Current Status

- ✅ Android workflow ready: `.github/workflows/patrol_ci_android.yml`
- 🔜 iOS workflow: Coming in Phase 3
- 🔜 Status badges: Coming in Phase 4

---

**Next Step**: Add the required secrets to your GitHub repository, then push this branch to trigger the workflow!
