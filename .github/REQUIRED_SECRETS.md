# Required GitHub Secrets for CI

This document lists all GitHub secrets required for the Patrol CI workflows to run successfully.

## How to Add Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret below with its corresponding value

---

## Required Secrets

### App Configuration (.env)

These secrets are used to create the main `.env` file that the app needs to run:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `COGNITO_USER_POOL_ID` | AWS Cognito User Pool ID | `us-east-1_ABC123DEF` |
| `COGNITO_CLIENT_ID` | AWS Cognito Client ID | `1a2b3c4d5e6f7g8h9i0j` |
| `API_BASE_URL` | Backend API base URL | `https://api.example.com` |
| `GEONAMES_USERNAME` | GeoNames API username | `your_geonames_username` |

### Test Credentials (.patrol.env)

These secrets are used to create the `integration_test/.patrol.env` file for test login:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `PATROL_EMAIL` | Test user email for login | `test@example.com` |
| `PATROL_PASSWORD` | Test user password | `SecureP@ssw0rd` |

---

## Workflows Using These Secrets

- **patrol_ci_android.yml** - Android integration tests
- **patrol_ci_ios.yml** - iOS integration tests

Both workflows create **TWO files**:
1. `.env` - App configuration (Cognito, API URL, etc.)
2. `integration_test/.patrol.env` - Test credentials (Email, Password)

---

## Verification

After adding secrets, the CI workflows will:

1. ✅ Create `.env` with app configuration
2. ✅ Create `.patrol.env` with test credentials  
3. ✅ Build the app successfully
4. ✅ Run integration tests with valid credentials

---

## Troubleshooting

### Login fails with "Verify login" not found
- **Cause**: Invalid credentials or API connection issues
- **Fix**: Verify `PATROL_EMAIL` and `PATROL_PASSWORD` secrets are correct and the user exists in your system

### App crashes on startup
- **Cause**: Missing or invalid app configuration
- **Fix**: Verify `API_BASE_URL`, `COGNITO_USER_POOL_ID`, and `COGNITO_CLIENT_ID` secrets are correct

### Build fails with environment variable errors
- **Cause**: Secrets not set in GitHub
- **Fix**: Add all 6 required secrets listed above

---

## Local Testing

To test locally with the same configuration:

```bash
# Create .env file (copy values from GitHub secrets)
cat > .env << EOF
COGNITO_USER_POOL_ID=your_pool_id
COGNITO_CLIENT_ID=your_client_id
API_BASE_URL=https://api.example.com
GEONAMES_USERNAME=your_username
EOF

# Create .patrol.env file
cat > integration_test/.patrol.env << EOF
EMAIL=test@example.com
PASSWORD=SecureP@ssw0rd
EOF

# Run tests
patrol test integration_test/
```
