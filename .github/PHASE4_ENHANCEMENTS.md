# Phase 4 Enhancements — Harden + Scale

## Overview

Phase 4 adds production-ready features to both Android and iOS CI workflows:
- **Matrix testing** (Android API levels)
- **Manual triggers** with test filtering
- **Retry logic** for flaky tests
- **Custom runner** support
- **Flexible test execution**

---

## 🎯 Manual Workflow Dispatch

Both workflows now support manual execution with custom inputs:

### How to Use

1. Go to: `Actions` → `Patrol Android CI` or `Patrol iOS CI`
2. Click `Run workflow`
3. Configure inputs:
   - **Branch**: Select branch to test
   - **Test filter**: Enter specific test file (or leave empty for all)
   - **Max retries**: Number of retry attempts (default: 1)

### Input Examples

| Use Case | test_filter | max_retries |
|----------|-------------|-------------|
| Run all tests | _(empty)_ | 1 |
| Run specific test | `cardCanBeFrozenOrUnfreeze_test.dart` | 1 |
| Run with retries | _(empty)_ | 3 |
| Run specific test with retries | `repaymentRateIsSaved_test.dart` | 2 |

### Example Output

```bash
# Without filter
🎯 Running all tests in: integration_test/

# With filter
🎯 Running filtered tests: integration_test/cardCanBeFrozenOrUnfreeze_test.dart
```

---

## 📊 Matrix Strategy (Android Only)

Android workflow now tests on **2 API levels** in parallel:

| API Level | Android Version | Use Case |
|-----------|-----------------|----------|
| **31** | Android 12 | Compatibility testing |
| **34** | Android 14 | Latest stable version |

### Benefits

- ✅ **Catch API-level bugs** early
- ✅ **Parallel execution** (both run simultaneously)
- ✅ **Separate artifacts** for each API level
- ✅ **fail-fast: false** - Both complete even if one fails

### Configuration

```yaml
strategy:
  fail-fast: false
  matrix:
    api: [31, 34]  # Test on Android 12 and Android 14
```

### Artifact Names

Artifacts now include API level:
- `patrol-android-api31-results`
- `patrol-android-api34-results`

---

## 🔄 Retry Logic (Optional)

Both workflows include **commented retry logic** for handling flaky tests.

### How to Enable

Uncomment the retry step in either workflow:

```yaml
# OPTIONAL: Serial retries for flaky tests
# Uncomment to enable retry logic
- name: Patrol retries (serial)
  if: failure() && github.event.inputs.max_retries > 1
  run: |
    # ... retry logic ...
```

### How It Works

1. Initial test run fails
2. If `max_retries > 1`, retry up to N times
3. Stop on first success
4. Report pass/fail counts

### Example Output

```bash
=== RETRY 2/3 ===
patrol test integration_test/ -r expanded --concurrency=1
=== RETRY 3/3 ===
patrol test integration_test/ -r expanded --concurrency=1
PASS:1  FAIL:2
```

---

## 🚀 Custom Runner Support

Both workflows include documentation for switching to custom runners.

### Why Use Custom Runners?

| Problem | Solution |
|---------|----------|
| Slow emulator startup | BuildJet (4x faster) |
| Expensive macOS minutes | Self-hosted Mac |
| Unstable emulators | Dedicated hardware |
| Heavy test suites | More CPU/RAM |

### Available Options

#### Android

```yaml
# Default (free, slow)
runs-on: ubuntu-latest

# BuildJet (paid, faster)
runs-on: buildjet-4vcpu-ubuntu-2204

# Self-hosted
runs-on: [self-hosted, linux]
```

#### iOS

```yaml
# Default (expensive, standard)
runs-on: macos-14

# GitHub larger runner (paid, faster)
runs-on: macos-13-xlarge

# Self-hosted
runs-on: [self-hosted, macOS]
```

### How to Switch

1. **Find the `runs-on` line** in workflow YAML
2. **Replace with custom runner label**
3. **Commit and push**

Example:
```yaml
# Before
runs-on: ubuntu-latest

# After
runs-on: buildjet-4vcpu-ubuntu-2204
```

### Cost Comparison

| Runner | Speed | Cost (relative) |
|--------|-------|-----------------|
| ubuntu-latest | 1x | 1x |
| macos-14 | 2x | 10x |
| buildjet-4vcpu | 4x | 3x |
| macos-13-xlarge | 3x | 20x |
| self-hosted | 5x+ | Setup cost only |

---

## 🎛️ Per-Job Timeouts

Both workflows have **45-minute timeouts** to prevent runaway jobs:

```yaml
jobs:
  patrol-android:
    timeout-minutes: 45  # Job kills after 45min
```

### Why This Matters

- ✅ **Prevents billing surprises** (stuck jobs)
- ✅ **Faster feedback** on hangs
- ✅ **Resource management**

### Adjusting Timeouts

For larger test suites:
```yaml
timeout-minutes: 60  # For heavier suites
```

For quick smoke tests:
```yaml
timeout-minutes: 30  # For lightweight suites
```

---

## 📋 Complete Workflow Features

### Android (`patrol_ci_android.yml`)

| Feature | Status |
|---------|--------|
| Matrix testing (API 31, 34) | ✅ |
| Manual trigger with inputs | ✅ |
| Test filtering | ✅ |
| Retry logic (commented) | ✅ |
| Custom runner docs | ✅ |
| Gradle caching | ✅ |
| Java 17 | ✅ |
| Flutter 3.24.x | ✅ |
| Per-API artifacts | ✅ |

### iOS (`patrol_ci_ios.yml`)

| Feature | Status |
|---------|--------|
| Manual trigger with inputs | ✅ |
| Test filtering | ✅ |
| Retry logic (commented) | ✅ |
| Custom runner docs | ✅ |
| iPhone 15 Pro simulator | ✅ |
| Flutter 3.24.x | ✅ |
| Xcode selection | ✅ |

---

## 🧪 Testing the Workflows

### 1. Add GitHub Secrets

```
Settings → Secrets and variables → Actions → New repository secret
```

Add:
- `PATROL_EMAIL`
- `PATROL_PASSWORD`

### 2. Test Automatic Trigger

```bash
git add .github/workflows/patrol_ci_android.yml .github/workflows/patrol_ci_ios.yml
git commit -m "Add Phase 4 CI enhancements"
git push origin test_playground
```

Expected:
- ✅ Android workflow triggers (2 jobs: API 31, API 34)
- ✅ iOS workflow triggers (1 job)

### 3. Test Manual Trigger

1. Go to `Actions` tab
2. Select `Patrol Android CI`
3. Click `Run workflow`
4. Enter inputs:
   - test_filter: `cardCanBeFrozenOrUnfreeze_test.dart`
   - max_retries: `2`
5. Click `Run workflow`

### 4. Test Matrix Results

Check artifacts:
- `patrol-android-api31-results` (API 31 output)
- `patrol-android-api34-results` (API 34 output)
- `patrol-ios-results` (iOS output)

---

## 🔍 Monitoring & Debugging

### View Workflow Runs

```
Actions → Select workflow → Select run → Expand job
```

### Check Matrix Results

For Android:
- `patrol-android (31)` - API 31 results
- `patrol-android (34)` - API 34 results

### Download Artifacts

1. Go to workflow run
2. Scroll to bottom: "Artifacts"
3. Download `patrol-android-api31-results` or `patrol-ios-results`

### Common Issues

| Issue | Solution |
|-------|----------|
| Secrets not working | Verify secrets are set in repo settings |
| Matrix jobs both fail | Check common setup issue (env file, secrets) |
| Timeout on emulator | Increase timeout or use custom runner |
| Flaky tests | Enable retry logic, increase max_retries |

---

## 📝 Next Steps

1. ✅ **Test workflows** on `test_playground` branch
2. ⬜ **Verify matrix runs** complete successfully
3. ⬜ **Test manual dispatch** with different filters
4. ⬜ **Add status badges** to README.md
5. ⬜ **Consider custom runners** if default runners are too slow
6. ⬜ **Enable retries** if tests are flaky
7. ⬜ **Expand matrix** (add more API levels if needed)

---

## 🎉 Summary

Phase 4 transforms basic CI into a **production-ready testing infrastructure**:

- ✅ **2x Android coverage** (API 31 + 34)
- ✅ **Flexible execution** (manual triggers, filters)
- ✅ **Resilience** (retry logic, timeouts)
- ✅ **Scalability** (custom runner support)
- ✅ **Debuggability** (separate artifacts, detailed logs)

**Your CI is now ready for production! 🚀**
