# Fastlane + Patrol Setup Guide for Flutter Integration Testing

This guide documents how to set up Fastlane with Patrol for automated Flutter
integration testing on iOS and Android, both locally and in CI/CD.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Install Patrol CLI](#install-patrol-cli)
- [iOS Setup](#ios-setup)
  - [1. Ruby Environment Setup (macOS)](#1-ruby-environment-setup-macos)
  - [2. Install Bundler and Dependencies](#2-install-bundler-and-dependencies)
  - [3. Install CocoaPods Dependencies](#3-install-cocoapods-dependencies)
  - [4. iOS Gemfile](#4-ios-gemfile)
  - [5. iOS Fastfile Configuration](#5-ios-fastfile-configuration)
  - [6. Key iOS Implementation Details](#6-key-ios-implementation-details)
- [Android Setup](#android-setup)
  - [1. Android Gemfile](#1-android-gemfile)
  - [2. Install Android Dependencies](#2-install-android-dependencies)
  - [3. Android Fastfile Configuration](#3-android-fastfile-configuration)
- [CI/CD Configuration](#cicd-configuration)
  - [GitHub Actions Workflow](#github-actions-workflow)
  - [Key CI/CD Configuration Points](#key-cicd-configuration-points)
- [Troubleshooting & Common Issues](#troubleshooting--common-issues)
  - [Common iOS Issues](#common-ios-issues)
  - [Common Android Issues](#common-android-issues)
  - [Environment Issues](#environment-issues)
- [Testing Locally](#testing-locally)
- [Best Practices](#best-practices)
- [Resources](#resources)
- [Summary](#summary)

## Overview

This setup enables automated integration testing for Flutter apps using:

- Patrol: Flutter integration testing framework with native automation
- Fastlane: Build automation tool for iOS and Android
- GitHub Actions: CI/CD pipeline

### Why This Stack?

- ✅ Patrol provides better native interaction than `flutter_driver`
- ✅ Fastlane handles platform-specific build complexities
- ✅ Automated – Works locally and in CI/CD
- ✅ Reliable – Handles simulator/emulator state management

## Prerequisites

### Required Tools

1. Flutter SDK (3.35.7 or compatible)
2. Ruby (3.2.9 recommended)
3. Bundler (2.5.23+)
4. Xcode (16.1+) – for iOS
5. Android Studio – for Android
6. Patrol CLI (3.6.0+)

## Install Patrol CLI

Install Patrol CLI globally:

```sh
dart pub global activate patrol_cli
```

Ensure `~/.pub-cache/bin` is in your `PATH`.

## iOS Setup

### 1. Ruby Environment Setup (macOS)

The macOS system Ruby (2.6) is too old for modern Bundler versions. Use `rbenv`:

```sh
# Install rbenv
brew install rbenv ruby-build

# Add to ~/.zshrc
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc

# Reload shell
source ~/.zshrc

# Install Ruby 3.2.9
rbenv install 3.2.9

# Set as project Ruby version
cd /path/to/your/project
rbenv local 3.2.9
```

### 2. Install Bundler and Dependencies

```sh
# Install Bundler 2.5.23
gem install bundler:2.5.23

# Install iOS dependencies
cd ios
bundle install
```

### 3. Install CocoaPods Dependencies

```sh
cd ios
pod install --repo-update
```

### 4. iOS Gemfile

Create `ios/Gemfile`:

```ruby
source "https://rubygems.org"

gem "fastlane", "2.228.0"
gem "cocoapods", "1.10.2"
```

### 5. iOS Fastfile Configuration

Create `ios/fastlane/Fastfile` with the following key features:

```ruby
# Fastfile for iOS
# This file contains the fastlane.tools configuration

require "timeout"

default_platform(:ios)

platform :ios do
  desc "Run Patrol integration tests on iOS"
  lane :test do
    # Install dependencies
    sh("cd ../.. && flutter pub get")

    UI.message("Finding an available iPhone simulator...")

    # Clean build artifacts
    sh("cd ../.. && flutter clean")
    sh("cd ../.. && flutter pub get")

    # Build the iOS app first for simulator
    sh("cd ../.. && flutter build ios --debug --simulator")

    # FASTLANE PATROL SETUP 3

    # Run pod install to ensure CocoaPods dependencies are up to date
    # Use direct pod command instead of bundle exec to avoid bundler gem issues
    sh("pod install --repo-update")

    # Get or boot the simulator
    # Try to find an available iPhone simulator, preferring newer models
    UI.message("Searching for available iPhone simulators...")

    # List of preferred simulators in order of preference
    preferred_simulators = [
      "iPhone 16 Pro",
      "iPhone 16",
      "iPhone 15 Pro",
      "iPhone 15",
      "iPhone 14 Pro",
      "iPhone 14",
      "iPhone SE (3rd generation)",
      "iPhone 13"
    ]

    device_id = nil
    device_name = nil

    # First, try to find a preferred simulator
    preferred_simulators.each do |sim_name|
      result = sh(
        "xcrun simctl list devices available | grep '#{sim_name}' | head -n 1 | grep -oE '\\([A-F0-9-]+\\)' | tr -d '()'",
        log: false
      ).strip rescue ""

      if !result.empty?
        device_id = result
        device_name = sim_name

        # FASTLANE PATROL SETUP 4

        break
      end
    end

    # If no preferred simulator found, get any available iPhone
    if device_id.nil? || device_id.empty?
      UI.message("No preferred simulator found, searching for any available iPhone...")

      device_id = sh(
        "xcrun simctl list devices available | grep 'iPhone' | grep -v 'unavailable' | head -n 1 | grep -oE '\\([A-F0-9-]+\\)' | tr -d '()'",
        log: false
      ).strip rescue ""
    end

    if device_id.nil? || device_id.empty?
      UI.error("No iPhone simulator found!")
      UI.message("Available devices:")
      sh("xcrun simctl list devices")
      raise "No suitable iPhone simulator found. Please install an iPhone simulator in Xcode."
    end

    # Get the full simulator name if we don't have it yet
    if device_name.nil?
      device_name = sh(
        "xcrun simctl list devices | grep '#{device_id}' | sed 's/ (.*//' | xargs",
        log: false
      ).strip
    end

    UI.message("Using simulator: #{device_name} (#{device_id})")

    # Shutdown simulator if it's running, then erase it for clean state
    UI.message("Shutting down simulator if running...")
    sh("xcrun simctl shutdown #{device_id} 2>&1 || true", log: false)

    # FASTLANE PATROL SETUP 5

    UI.message("Erasing simulator to ensure clean state...")
    sh("xcrun simctl erase #{device_id}")

    # Boot the simulator
    UI.message("Booting simulator...")
    boot_result = sh("xcrun simctl boot #{device_id} 2>&1 || true", log: false)

    if boot_result.include?("Unable to boot device in current state: Booted")
      UI.message("Simulator already booted")
    elsif boot_result.include?("Booted")
      UI.message("Simulator boot initiated")
    end

    # Wait for boot to complete with timeout (max 60 seconds)
    UI.message("Waiting for simulator to boot (timeout: 60s)...")

    begin
      Timeout.timeout(60) do
        sh("xcrun simctl bootstatus #{device_id} -b")
      end
    rescue Timeout::Error
      UI.important("⚠ Boot status check timed out after 60s, but continuing anyway...")
      UI.message("The simulator may still be usable even if boot status didn't complete")
    end

    # Give extra time for all services to be ready
    UI.message("Waiting for simulator services to stabilize...")
    sleep(10)

    # Verify simulator is actually ready
    UI.message("Verifying simulator state...")
    device_state = sh(
      "xcrun simctl list devices booted | grep '#{device_id}' || echo 'not found'",
      log: false
    ).strip

    # FASTLANE PATROL SETUP 6

    if device_state.include?("not found")
      UI.error("Simulator #{device_id} is not in booted state!")
      sh("xcrun simctl list devices")
      raise "Failed to boot simulator"
    end

    UI.success("Simulator is ready!")

    # Build the test bundle using patrol
    UI.message("Building Patrol test bundle for simulator...")
    sh("cd ../.. && patrol build ios --simulator --verbose")

    # Find the .xctestrun file created by patrol build
    xctestrun_file = Dir.glob("../../build/ios_integ/Build/Products/*.xctestrun").first

    if xctestrun_file.nil?
      UI.user_error!("Could not find .xctestrun file after patrol build")
    end

    UI.message("Found xctestrun file: #{xctestrun_file}")

    # Run tests using the xctestrun file with the exact device ID
    UI.message("Running Patrol tests on #{device_name} (#{device_id})...")

    begin
      sh(
        "xcodebuild test-without-building " \
        "-xctestrun '#{xctestrun_file}' " \
        "-destination 'platform=iOS Simulator,id=#{device_id}' " \
        "-destination-timeout 30 " \
        "-only-testing:RunnerUITests"
      )
    rescue => ex
      UI.error("❌ Patrol test failed!")
      UI.error("Error: #{ex.message}")

      # Capture additional debug info
      UI.message("Checking simulator logs...")

      # FASTLANE PATROL SETUP 7

      sh(
        "xcrun simctl spawn #{device_id} log show --predicate 'process == \\\"Runner\\\"' --last 5m || true"
      )

      raise ex
    end

    UI.success("✅ iOS Patrol tests completed!")
  end

  desc "Build iOS test bundle only (without running tests)"
  lane :build_tests do
    # Install dependencies
    sh("cd ../.. && flutter pub get")

    # Build iOS test bundle for simulator with Patrol
    sh("cd ../.. && patrol build ios --simulator --verbose")

    UI.success("✅ iOS test bundle built successfully!")
  end

  desc "Build iOS release"
  lane :build_release do
    sh("cd ../.. && flutter clean")
    sh("cd ../.. && flutter pub get")
    sh("cd ../.. && flutter build ios --release --no-codesign")

    UI.success("✅ iOS build complete!")
    UI.message("Note: This build is not code-signed. For App Store distribution, you'll need to set up code signing.")
  end

  desc "Deploy to TestFlight"
  lane :deploy_testflight do
    # TODO: Add code signing and TestFlight upload
    # Example when ready:
    # get_certificates # invokes cert
    # get_provisioning_profile # invokes sigh

    # FASTLANE PATROL SETUP 8

    # build_app(scheme: "Runner")
    # upload_to_testflight

    UI.message("📱 TestFlight deployment - requires code signing setup")
    UI.message("See: https://docs.fastlane.tools/codesigning/getting-started/")
  end
end
```

### 6. Key iOS Implementation Details

- **Critical: `--simulator` flag** – always use `--simulator` when building for iOS Simulator:

  ```sh
  cd ios
  patrol build ios --simulator --verbose
  ```

  Without this flag, Patrol defaults to building for physical devices (release
  mode), which causes:

  - "physical iOS devices only in release mode" errors
  - Build failures in CI/CD

- **Using `.xctestrun` file** – instead of running `xcodebuild` with workspace and scheme directly:

  ```sh
  # ❌ DON'T DO THIS - causes path issues
  xcodebuild test-without-building \
    -workspace Runner.xcworkspace \
    -scheme Runner ...
  ```

  ```ruby
  # ✅ DO THIS - use xctestrun file
  xctestrun_file = Dir.glob("../../build/ios_integ/Build/Products/*.xctestrun").first
  sh("xcodebuild test-without-building -xctestrun '#{xctestrun_file}' ...")
  ```

- **Exact device ID** – always use the exact device ID, never `OS=latest`:

  ```sh
  # ✅ DO THIS
  -destination 'platform=iOS Simulator,id=#{device_id}'

  # ❌ DON'T DO THIS - causes ambiguity
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16'
  ```

- **Simulator clean state** – always shutdown and erase simulator before tests:

  ```sh
  xcrun simctl shutdown #{device_id} 2>&1 || true
  xcrun simctl erase #{device_id}
  ```

  This prevents boot hangs and data migration issues.

## Android Setup

### 1. Android Gemfile

Create `android/Gemfile`:

```ruby
source "https://rubygems.org"

gem "fastlane"
```

### 2. Install Android Dependencies

```sh
cd android
bundle install
```

### 3. Android Fastfile Configuration

Create `android/fastlane/Fastfile`:

```ruby
# Fastfile for Android
# This file contains the fastlane.tools configuration

default_platform(:android)

platform :android do
  desc "Run Patrol integration tests on Android"
  lane :test do
    # Install dependencies
    sh("cd ../.. && flutter pub get")

    # Run Patrol tests - uses default test_bundle.dart
    # This will build the APKs and execute the tests on connected device/emulator
    sh("cd ../.. && patrol test android --verbose")

    UI.success("✅ Android Patrol tests completed!")
  end

  desc "Build Android release APK"
  lane :build_release do
    sh("cd ../.. && flutter clean")
    sh("cd ../.. && flutter pub get")
    sh("cd ../.. && flutter build apk --release")

    UI.success("✅ Release APK built!")
    UI.message("APK: build/app/outputs/flutter-apk/app-release.apk")
  end

  desc "Build APKs only (without running tests)"
  lane :build_apks do
    # Install dependencies
    sh("cd ../.. && flutter pub get")

    # Build APKs with Patrol (for uploading to Firebase Test Lab, etc.)
    sh("cd ../.. && patrol build android --verbose")

    UI.success("✅ Android test APKs built successfully!")
    UI.message("App APK: build/app/outputs/apk/debug/app-debug.apk")
    UI.message("Test APK: build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk")

    # FASTLANE PATROL SETUP 11
  end

  desc "Build and deploy to internal testing"
  lane :deploy_internal do
    build_release

    # TODO: Add Play Store upload when ready
    # upload_to_play_store(
    #   track: 'internal',
    #   apk: '../build/app/outputs/flutter-apk/app-release.apk'
    # )

    UI.success("✅ Ready for internal deployment!")
  end
end
```

## CI/CD Configuration

### GitHub Actions Workflow

Create `.github/workflows/fastlane-ci.yml`:

```yaml
name: Fastlane CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  workflow_dispatch: # Allows manual trigger from GitHub UI

env:
  FLUTTER_VERSION: "3.35.7"

jobs:
  # Android - Build and Test
  android:
    name: Android - Build & Test
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Free up disk space
        run: |
          echo "Disk space before cleanup:"
          df -h
          sudo rm -rf /usr/share/dotnet
          sudo rm -rf /opt/ghc
          sudo rm -rf /usr/local/share/boost
          sudo rm -rf "$AGENT_TOOLSDIRECTORY"
          echo "Disk space after cleanup:"
          df -h

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: "temurin"
          java-version: "17"

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
          cache: true

      - name: Setup Ruby for Fastlane
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.2.9"
          bundler-cache: true
          working-directory: android

      - name: Install Patrol CLI
        run: dart pub global activate patrol_cli

      # NOTE: patrol test requires a running emulator or connected device
      # For CI, we need to start an Android emulator first
      - name: Enable KVM group perms
        run: |
          echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' | sudo tee /etc/udev/rules.d/99-kvm4all.rules
          sudo udevadm control --reload-rules
          sudo udevadm trigger --name-match=kvm

      - name: AVD cache
        uses: actions/cache@v4
        id: avd-cache
        with:
          path: |
            ~/.android/avd/*
            ~/.android/adb*
          key: avd-33

      - name: Create AVD and generate snapshot for caching
        if: steps.avd-cache.outputs.cache-hit != 'true'
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 33
          arch: x86_64
          force-avd-creation: false
          emulator-options: -no-window -gpu swiftshader_indirect -noaudio -no-boot-anim -camera-back none
          disable-animations: false
          script: echo "Generated AVD snapshot for caching."

      - name: Run Fastlane test lane (with emulator)
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 33
          arch: x86_64
          force-avd-creation: false
          emulator-options: -no-snapshot-save -no-window -gpu swiftshader_indirect -noaudio -no-boot-anim -camera-back none
          disable-animations: true
          script: |
            cd android
            export PATH="$HOME/.pub-cache/bin:$PATH"
            bundle exec fastlane test

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: android-test-results
          path: |
            build/app/outputs/
          retention-days: 7

  # iOS - Build and Test
  ios:
    name: iOS - Build & Test
    runs-on: macos-14
    timeout-minutes: 45 # Increased timeout for iOS simulator startup

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Select Xcode version
        run: sudo xcode-select -s /Applications/Xcode_16.1.app/Contents/Developer

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
          cache: true

      - name: Setup Ruby for Fastlane
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.2.9"
          bundler-cache: true
          working-directory: ios

      - name: Install Patrol CLI
        run: dart pub global activate patrol_cli

      - name: Get Flutter dependencies
        run: flutter pub get

      - name: List available simulators
        run: xcrun simctl list devices available

      # NOTE: Fastlane will handle the full build process
      - name: Run Fastlane test lane
        run: |
          cd ios
          export PATH="$HOME/.pub-cache/bin:$PATH"
          bundle exec fastlane test

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: ios-test-results
          path: |
            build/ios/
          retention-days: 7
```

### Key CI/CD Configuration Points

#### iOS CI/CD Requirements

1. **Xcode Version** – Select Xcode 16.1+ to support modern project format:

   ```sh
   sudo xcode-select -s /Applications/Xcode_16.1.app/Contents/Developer
   ```

2. **Ruby Setup** – Use `ruby/setup-ruby@v1` with `bundler-cache: true` and `working-directory: ios`.

3. **Bundler Version** – Ensure `BUNDLED WITH 2.5.23` in `Gemfile.lock`.

#### Android CI/CD Requirements

1. **KVM Acceleration** – Enable for faster emulator performance.
2. **AVD Caching** – Cache Android Virtual Device for faster CI runs.
3. **Emulator Runner** – Use `reactivecircus/android-emulator-runner@v2`.

## Troubleshooting & Common Issues

### Common iOS Issues

1. **"Could not find 'bundler' (2.5.23)"**

   - **Cause:** Ruby version mismatch or Bundler not installed.
   - **Solution:**

     ```sh
     # Check Ruby version
     ruby --version  # Should be 3.2.9

     # Install correct Bundler
     gem install bundler:2.5.23

     # Update Gemfile.lock
     bundle update --bundler
     ```

2. **"Unable to erase contents and settings in current state: Booted"**

   - **Cause:** Simulator already running.
   - **Solution:** Shutdown before erasing (already handled in Fastfile):

     ```sh
     xcrun simctl shutdown #{device_id} 2>&1 || true
     xcrun simctl erase #{device_id}
     ```

3. **"FirebaseCore requires CocoaPods version >= 1.12.0"**

   - **Cause:** CocoaPods version in `Gemfile` is too old (e.g., 1.10.2).
   - **Solution:** Update CocoaPods in `ios/Gemfile`:

     ```ruby
     source "https://rubygems.org"
     gem "fastlane", "2.228.0"
     gem "cocoapods", "~> 1.15.0"  # Update to 1.15+
     ```
     
     Then run `bundle update cocoapods` to update `Gemfile.lock`.

4. **"No file or variants found for asset: .env"**

   - **Cause:** The `.env` file is referenced in `pubspec.yaml` under assets but doesn't exist (usually in `.gitignore`).
   - **Solution:** Create a placeholder `.env` file in the project root:

     ```bash
     echo "# Environment variables placeholder" > .env
     ```
     
     Or add it as a CI workflow step:
     
     ```yaml
     - name: Create .env file
       run: echo "# Environment variables placeholder" > .env
     ```

5. **"physical iOS devices only in release mode"**

   - **Cause:** Missing `--simulator` flag in `patrol build`.
   - **Solution:** Always use:

     ```sh
     cd ios
     patrol build ios --simulator --verbose
     ```

6. **Simulator boot timeout / data migration hang**

   - **Cause:** Simulator corruption or slow migration.
   - **Solution:** Erase simulator before boot (already handled in Fastfile).

7. **"Using the first of multiple matching destinations"**

   - **Cause:** Using `OS=latest` which matches multiple iOS versions.
   - **Solution:** Use exact device ID:

     ```sh
     -destination 'platform=iOS Simulator,id=#{device_id}'
     ```

6. **Bundle identifier couldn't be read / DerivedData path issues**

   - **Cause:** Using workspace/scheme instead of `.xctestrun` file.
   - **Solution:** Use `.xctestrun` file from `patrol build`:

     ```ruby
     xctestrun_file = Dir.glob("../../build/ios_integ/Build/Products/*.xctestrun").first
     sh("xcodebuild test-without-building -xctestrun '#{xctestrun_file}' ...")
     ```

### Common Android Issues

1. **"Could not locate Gemfile or .bundle/ directory" in CI**

   - **Cause:** The emulator runner executes each line of the script in a separate shell context, so `cd` commands don't persist across lines.
   - **Solution:** Chain all commands on a single line using `&&` to ensure they run in the same shell context:

     ```yaml
     - name: Run Fastlane test lane (with emulator)
       uses: reactivecircus/android-emulator-runner@v2
       with:
         script: |
           export PATH="$HOME/.ruby/ruby/3.2.0/bin:$HOME/.pub-cache/bin:$PATH" && cd "$GITHUB_WORKSPACE/android" && bundle exec fastlane test
     ```
     
     **Important:** All commands must be chained with `&&` on the same line, otherwise each command runs in a separate shell and the working directory resets.

2. **Emulator not starting in CI**

   - **Solution:** Enable KVM and use hardware acceleration:

     ```sh
     echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666"' | sudo tee /etc/udev/rules.d/99-kvm4all.rules
     sudo udevadm control --reload-rules
     sudo udevadm trigger --name-match=kvm
     ```

3. **Patrol CLI version incompatibility**

   - **Cause:** Mismatch between `patrol` package version in `pubspec.yaml` and `patrol_cli` version installed in CI.
   - **Solution:** Pin `patrol_cli` to a compatible version in the workflow:

     ```yaml
     - name: Install Patrol CLI
       run: dart pub global activate patrol_cli 3.10.0  # Compatible with patrol 3.19.0
     ```
     
     Check the [Patrol compatibility table](https://patrol.leancode.co/documentation/compatibility-table) for the correct version.

4. **Permission dialogs causing test timeouts**

   - **Cause:** Native permission dialogs (notifications, location, camera) appear during tests, blocking UI and causing `pumpAndSettle` to timeout.
   - **Solution:** Pre-grant permissions before tests run in Fastfile:

     **Android (`android/fastlane/Fastfile`):**
     ```ruby
     # Before running tests
     package_name = "com.thinslices.solarisdemo"
     sh("adb shell pm grant #{package_name} android.permission.POST_NOTIFICATIONS || true")
     sh("adb shell pm grant #{package_name} android.permission.ACCESS_FINE_LOCATION || true")
     # ... other permissions
     ```

     **iOS (`ios/fastlane/Fastfile`):**
     ```ruby
     # After booting simulator, before running tests
     bundle_id = "com.thinslices.solarisdemo"
     sh("xcrun simctl privacy #{device_id} grant notification #{bundle_id} || true")
     sh("xcrun simctl privacy #{device_id} grant location #{bundle_id} || true")
     # ... other permissions
     ```
     
   - **Additional handling in test code:** Implement retry logic with timeout handling in `loginToApp.dart` to gracefully handle any remaining dialogs.

5. **Tests timing out**

   - **Solution:** Increase timeout in workflow:

     ```yaml
     timeout-minutes: 60
     ```

### Environment Issues

#### macOS System Ruby Incompatibility

- ❌ Problem: macOS ships with Ruby 2.6, but Bundler 2.5.23 requires Ruby 3.0+.
- ✅ Solution: Use `rbenv` to manage Ruby versions (see iOS Setup).

#### PATH Issues

- ❌ Problem: Patrol CLI or `rbenv` not in `PATH`.
- ✅ Solution: Add the following to `~/.zshrc`:

  ```sh
  export PATH="$HOME/.rbenv/shims:$PATH"
  export PATH="$HOME/.pub-cache/bin:$PATH"
  ```

#### Build Issues

- **Xcode Version Mismatch**

  - ❌ Problem: Project uses Xcode 16 format, but CI uses Xcode 15.4.
  - ✅ Solution: Select Xcode 16.1 in CI (see CI/CD Configuration).

- **CocoaPods Installation**

  - ❌ Problem: Pods not installed or outdated.
  - ✅ Solution:

    ```sh
    cd ios
    pod install --repo-update
    ```

## Testing Locally

### Test iOS Locally

```sh
# Ensure rbenv is initialized
eval "$(rbenv init - zsh)"

cd ios
bundle exec fastlane test
```

### Test Android Locally

```sh
# Start emulator first
emulator -avd Pixel_6_API_34

cd android
bundle exec fastlane test
```

## Best Practices

1. ✅ Always use `--simulator` flag for iOS simulator builds.
2. ✅ Clean simulator state before tests (shutdown + erase).
3. ✅ Use exact device IDs instead of `OS=latest`.
4. ✅ Use `.xctestrun` files for `xcodebuild`.
5. ✅ Set appropriate timeouts for boot and test execution.
6. ✅ Cache dependencies in CI (Ruby gems, AVD, etc.).
7. ✅ Upload test results as artifacts for debugging.
8. ✅ Use Ruby version manager (`rbenv`) instead of system Ruby.

## Resources

- Patrol Documentation
- Fastlane Documentation
- Flutter Integration Testing
- GitHub Actions Documentation

## Summary

This setup provides:

- ✅ Reliable local and CI/CD testing
- ✅ Automated simulator/emulator management
- ✅ Platform-specific optimizations
- ✅ Comprehensive error handling
- ✅ Clear debugging information

The key to success is:

1. Using the correct flags (`--simulator` for iOS)
2. Proper simulator state management (shutdown + erase)
3. Using exact device IDs and `.xctestrun` files
4. Matching Ruby/Bundler versions between local and CI

---

**Created:** November 13, 2025  
**Last Updated:** November 13, 2025

**Tested With:**

- Flutter 3.35.7
- Patrol CLI 3.6.0
- Xcode 16.1
- Ruby 3.2.9
- Bundler 2.5.23
- Fastlane 2.228.0


2. Install Android Dependencies
cd android
bundle install
3. Android Fastfile Configuration
Create android/fastlane/Fastfile :
# Fastfile for Android
# This file contains the fastlane.tools configuration
default_platform(:android)
FASTLANE PATROL SETUP 10
platform :android do
desc "Run Patrol integration tests on Android"
lane :test do

# Install dependencies
sh("cd ../.. && flutter pub get")
# Run Patrol tests - uses default test_bundle.dart
# This will build the APKs and execute the tests on connected device/emulator
sh("cd ../.. && patrol test android --verbose")
UI.success("✅ Android Patrol tests completed!")
end
desc "Build Android release APK"
lane :build_release do
sh("cd ../.. && flutter clean")
sh("cd ../.. && flutter pub get")
sh("cd ../.. && flutter build apk --release")
UI.success("✅ Release APK built!")
UI.message("APK: build/app/outputs/flutter-apk/app-release.apk")
end
desc "Build APKs only (without running tests)"
lane :build_apks do
# Install dependencies
sh("cd ../.. && flutter pub get")
# Build APKs with Patrol (for uploading to Firebase Test Lab, etc.)
sh("cd ../.. && patrol build android --verbose")
UI.success("✅ Android test APKs built successfully!")
UI.message("App APK: build/app/outputs/apk/debug/app-debug.apk")
UI.message("Test APK: build/app/outputs/apk/androidTest/debug/app-deb
ug-androidTest.apk")
FASTLANE PATROL SETUP 11
end
desc "Build and deploy to internal testing"
lane :deploy_internal do
build_release
# TODO: Add Play Store upload when ready
# upload_to_play_store(
# track: 'internal',
# apk: '../build/app/outputs/flutter-apk/app-release.apk'
# )
UI.success("✅ Ready for internal deployment!")
end
end

# CI/CD Configuration
# GitHub Actions Workflow
Create .github/workflows/fastlane-ci.yml :
name: Fastlane CI/CD
on:
push:
branches: [main, develop]
pull_request:
branches: [main, develop]
workflow_dispatch: # Allows manual trigger from GitHub UI
env:
FLUTTER_VERSION: "3.35.7"
jobs:
# Android - Build and Test
android:
name: Android - Build & Test
runs-on: ubuntu-latest
timeout-minutes: 30
steps:
- name: Checkout code
uses: actions/checkout@v4
- name: Free up disk space
run: |
echo "Disk space before cleanup:"
df -h
sudo rm -rf /usr/share/dotnet
sudo rm -rf /opt/ghc
sudo rm -rf /usr/local/share/boost
sudo rm -rf "$AGENT_TOOLSDIRECTORY"
echo "Disk space after cleanup:"
df -h
- name: Setup Java
uses: actions/setup-java@v4
with:
distribution: "temurin"
java-version: "17"
- name: Setup Flutter
uses: subosito/flutter-action@v2
with:
flutter-version: ${{ env.FLUTTER_VERSION }}
channel: "stable"
cache: true
- name: Setup Ruby for Fastlane
uses: ruby/setup-ruby@v1
FASTLANE PATROL SETUP 13
with:
ruby-version: '3.2'
bundler-cache: true
working-directory: android
- name: Install Patrol CLI
run: dart pub global activate patrol_cli
# NOTE: patrol test requires a running emulator or connected device
# For CI, we need to start an Android emulator first
- name: Enable KVM group perms
run: |
echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="st
atic_node=kvm"' | sudo tee /etc/udev/rules.d/99-kvm4all.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --name-match=kvm
- name: AVD cache
uses: actions/cache@v4
id: avd-cache
with:
path: |
~/.android/avd/*
~/.android/adb*
key: avd-33
- name: Create AVD and generate snapshot for caching
if: steps.avd-cache.outputs.cache-hit != 'true'
uses: reactivecircus/android-emulator-runner@v2
with:
api-level: 33
arch: x86_64
force-avd-creation: false
emulator-options: -no-window -gpu swiftshader_indirect -noaudio -no-
boot-anim -camera-back none
disable-animations: false
FASTLANE PATROL SETUP 14
script: echo "Generated AVD snapshot for caching."
- name: Run Fastlane test lane (with emulator)
uses: reactivecircus/android-emulator-runner@v2
with:
api-level: 33
arch: x86_64
force-avd-creation: false
emulator-options: -no-snapshot-save -no-window -gpu swiftshader_ind
irect -noaudio -no-boot-anim -camera-back none
disable-animations: true
working-directory: android
script: |
export PATH="$HOME/.pub-cache/bin:$PATH"
bundle exec fastlane test
- name: Upload test results
if: always()
uses: actions/upload-artifact@v4
with:
name: android-test-results
path: |
build/app/outputs/
retention-days: 7
# iOS - Build and Test
ios:
name: iOS - Build & Test
runs-on: macos-14
timeout-minutes: 45 # Increased timeout for iOS simulator startup
steps:
- name: Checkout code
uses: actions/checkout@v4
- name: Select Xcode version
FASTLANE PATROL SETUP 15
run: sudo xcode-select -s /Applications/Xcode_16.1.app/Contents/Develo
per
- name: Setup Flutter
uses: subosito/flutter-action@v2
with:
flutter-version: ${{ env.FLUTTER_VERSION }}
channel: "stable"
cache: true
- name: Setup Ruby for Fastlane
uses: ruby/setup-ruby@v1
with:
ruby-version: '3.2'
bundler-cache: true
working-directory: ios
- name: Install Patrol CLI
run: dart pub global activate patrol_cli
- name: Get Flutter dependencies
run: flutter pub get
- name: List available simulators
run: xcrun simctl list devices available
# NOTE: Fastlane will handle the full build process
- name: Run Fastlane test lane
working-directory: ios
run: |
export PATH="$HOME/.pub-cache/bin:$PATH"
bundle exec fastlane test
- name: Upload test results
if: always()
uses: actions/upload-artifact@v4
FASTLANE PATROL SETUP 16
with:
name: ios-test-results
path: |
build/ios/
retention-days: 7

# Key CI/CD Configuration Points

iOS CI/CD Requirements
1. Xcode Version: Select Xcode 16.1+ to support modern project format
- name: Select Xcode 16.1 run: sudo xcode-select -s /Applications/Xcode_
16.1.app/Contents/Developer
2. Ruby Setup: Use ruby/setup-ruby@v1 with bundler-cache: true
- uses: ruby/setup-ruby@v1 with: ruby-version: '3.2.9' bundler-cache:
true working-directory: ios
3. Bundler Version: Ensure BUNDLED WITH 2.5.23 in Gemfile.lock

Android CI/CD Requirements
1. KVM Acceleration: Enable for faster emulator performance
2. AVD Caching: Cache Android Virtual Device for faster CI runs
3. Emulator Runner: Use reactivecircus/android-emulator-runner@v2


# Troubleshooting

## Common iOS Issues

1.“Could not find ‘bundler’ (2.5.23)”
Cause: Ruby version mismatch or Bundler not installed
Solution:
FASTLANE PATROL SETUP 17
# Check Ruby versionruby --version # Should be 3.2.9# Install correct Bundle
rgem install bundler:2.5.23
# Update Gemfile.lockbundle update --bundler

# 2.“Unable to erase contents and settings in current state: Booted”
Cause: Simulator already running
Solution: Shutdown before erasing (already handled in Fastfile)
sh("xcrun simctl shutdown #{device_id} 2>&1 || true", log: false)
sh("xcrun simctl erase #{device_id}")

# 3.“physical iOS devices only in release mode”
Cause: Missing --simulator flag in patrol build
Solution: Always use:
sh("cd ../.. && patrol build ios --simulator --verbose")

# 4. Simulator boot timeout / data migration hang
Cause: Simulator corruption or slow migration
Solution: Erase simulator before boot (already handled in Fastfile)

# 5.“Using the first of multiple matching destinations”
Cause: Using OS=latest which matches multiple iOS versions
Solution: Use exact device ID:
-destination 'platform=iOS Simulator,id=#{device_id}'

# 6. Bundle identifier couldn’t be read / DerivedData path issues
Cause: Using workspace/scheme instead of xctestrun file
FASTLANE PATROL SETUP 18
Solution: Use .xctestrun file from patrol build:
xctestrun_file = Dir.glob("../../build/ios_integ/Build/Products/* .xctestrun").firsts
h("xcodebuild test-without-building -xctestrun '#{xctestrun_file}' ...")

## Common Android Issues

1. Emulator not starting in CI
Solution: Enable KVM and use hardware acceleration
- name: Enable KVM run: | echo 'KERNEL=="kvm", GROUP="kvm", MODE
="0666"' | sudo tee /etc/udev/rules.d/99-kvm4all.rules

sudo udevadm control --reload-rules

2. Tests timing out
Solution: Increase timeout in workflow:
timeout-minutes: 60

## Common Issues
# Environment Issues

# macOS System Ruby Incompatibility
❌ Problem: macOS ships with Ruby 2.6, but Bundler 2.5.23 requires Ruby 3.0+
✅ Solution: Use rbenv to manage Ruby versions (see iOS Setup)

# PATH Issues
❌ Problem: Patrol CLI or rbenv not in PATH
✅ Solution:

# Add to ~/.zshrcexport PATH="$HOME/.rbenv/shims:$PATH"export PATH
="$HOME/.pub-cache/bin:$PATH"
Build Issues
Xcode Version Mismatch
❌ Problem: Project uses Xcode 16 format, but CI uses Xcode 15.4
✅ Solution: Select Xcode 16.1 in CI (see CI/CD Configuration)
CocoaPods Installation
❌ Problem: Pods not installed or outdated
✅ Solution:
cd ios
pod install --repo-update

## Testing Locally

### Test iOS Locally

# Ensure rbenv is initializedeval "$(rbenv init - zsh)"# Run testscd ios
bundle exec fastlane test

### Test Android Locally

# Start emulator firstemulator -avd Pixel_6_API_34

# Run tests 
cd android && bundle exec fastlane test

## Best Practices

1. ✅ Always use -simulator flag for iOS simulator builds
2. ✅ Clean simulator state before tests (shutdown + erase)
3. ✅ Use exact device IDs instead of OS=latest
4. ✅ Use .xctestrun files for xcodebuild
5. ✅ Set appropriate timeouts for boot and test execution
6. ✅ Cache dependencies in CI (Ruby gems, AVD, etc.)
7. ✅ Upload test results as artifacts for debugging
8. ✅ Use Ruby version manager (rbenv) instead of system Ruby

## Resources

### Patrol Documentation

### Fastlane Documentation

### Flutter Integration Testing

### GitHub Actions Documentation

## Summary
This setup provides:
- ✅ Reliable local and CI/CD testing
- ✅ Automated simulator/emulator management
- ✅ Platform-specific optimizations
- ✅ Comprehensive error handling
- ✅ Clear debugging information

The key to success is:
1. Using the correct flags (--simulator for iOS)
2. Proper simulator state management (shutdown + erase)
3. Using exact device IDs and xctestrun files
4. Matching Ruby/Bundler versions between local and CI
Created: November 13, 2025
Last Updated: November 13, 2025

Tested With:
- Flutter 3.35.7
- Patrol CLI 3.6.0
- Xcode 16.1
- Ruby 3.2.9
- Bundler 2.5.23
- Fastlane 2.228.0
