# CI Setup Progress - Patrol Integration Tests

## ✅ Phase 1 — Repo Prep (COMPLETED)

### Files Updated

#### `.gitignore`
- ✅ Added `.env.*` pattern to ignore all env variants
- ✅ Added explicit `integration_test/.patrol.env` ignore
- ✅ Added exceptions: `!.env.example` and `!integration_test/.patrol.env.example`
- ✅ Organized with clear "Environment variables" section

#### `README.md`
- ✅ Added comprehensive "CI with Patrol" section
- ✅ Documented Android (ubuntu-latest) and iOS (macos-14) platform support
- ✅ Listed required secrets: `PATROL_EMAIL`, `PATROL_PASSWORD`
- ✅ Documented branch triggers: `main` and `SOL-*` branches
- ✅ Explained environment setup (`.env` vs `.patrol.env`)
- ✅ Added local testing instructions

### Configuration Summary

**Branch Triggers:**
- `main` branch (pushes)
- `SOL-*` pattern branches (pushes)
- Pull requests to above branches

**Required GitHub Secrets:**
- `PATROL_EMAIL` - Test user email
- `PATROL_PASSWORD` - Test user password

**Environment Files:**
- Main `.env` (root) - App config (API_BASE_URL, Firebase, Cognito, etc.)
- Test `.patrol.env` (integration_test/) - Credentials only (EMAIL, PASSWORD)

---

## ✅ Phase 2 — Android Workflow (COMPLETED)

**Tasks:**
- [x] Create `.github/workflows/patrol_ci_android.yml`
- [x] Configure ubuntu-latest runner
- [x] Set up android-emulator-runner action (API 34, Pixel 5)
- [x] Create `.env` and `.patrol.env` from secrets before tests
- [x] Run patrol tests on Android emulator
- [x] Upload test reports as artifacts

**Configuration:**
- Runner: `ubuntu-latest` (timeout: 45min)
- Emulator: API 34, x86_64, Pixel 5 profile
- Flutter: 3.24.x stable
- Java: 17 (Temurin)
- Gradle caching enabled for faster builds
- Triggers: `main`, `SOL-*` branches (push + PR)

---

## ✅ Phase 3 — iOS Workflow (COMPLETED)

**Tasks:**
- [x] Create `.github/workflows/patrol_ci_ios.yml`
- [x] Configure macos-14 runner
- [x] Set up iOS Simulator (iPhone 15 Pro)
- [x] Flutter and Xcode setup
- [x] Create `.env` and `.patrol.env` from secrets before tests
- [x] Run patrol tests on iOS simulator
- [x] Upload test reports as artifacts

**Configuration:**
- Runner: `macos-14` (timeout: 45min)
- Simulator: iPhone 15 Pro
- Flutter: 3.24.x stable
- Xcode: Default for macos-14
- Triggers: `main`, `test_playground`, `SOL-*` branches (push + PR)
- **Note**: macOS minutes are 10x more expensive than Ubuntu

---

## ✅ Phase 4 — Harden + Scale (COMPLETED)

**Tasks:**
- [x] Add manual trigger inputs (test_filter, max_retries)
- [x] Add matrix strategy for Android (API 31, 34)
- [x] Add custom runner documentation
- [x] Add commented retry logic
- [x] Add per-job timeouts
- [x] Update artifact names for matrix runs

**Enhancements Added:**

### Android Workflow
- ✅ Matrix testing: API 31 (Android 12) & API 34 (Android 14)
- ✅ Manual trigger with test filter and retry options
- ✅ Custom runner examples (BuildJet, self-hosted)
- ✅ Commented serial retry logic
- ✅ API-specific artifact names

### iOS Workflow
- ✅ Manual trigger with test filter and retry options
- ✅ Custom runner examples (macos-13-xlarge, self-hosted)
- ✅ Commented serial retry logic
- ✅ Test filtering support

### Manual Workflow Inputs
Both workflows now support:
- `test_filter` - Run specific test file (e.g., `cardCanBeFrozenOrUnfreeze_test.dart`)
- `max_retries` - Number of retry attempts for flaky tests

### Custom Runner Examples
Both workflows include comments on switching to:
- BuildJet runners (faster, paid)
- Self-hosted runners
- GitHub larger runners (macOS xlarge)

---

## 🔜 Next Steps — Testing & Documentation

**Recommended Actions:**
- [ ] Add GitHub secrets (PATROL_EMAIL, PATROL_PASSWORD)
- [ ] Push to test_playground branch to trigger workflows
- [ ] Verify both Android (API 31 & 34) and iOS workflows pass
- [ ] Test manual workflow dispatch with filters
- [ ] Add status badges to README.md
- [ ] Document troubleshooting in README

---

## Notes

- Current CI file `.github/workflows/ci.yml` runs unit tests only
- Patrol workflows will be separate files for easier maintenance
- Both Android and iOS workflows will create `.patrol.env` from GitHub secrets
- Test execution happens on actual emulators/simulators (not mocked)
