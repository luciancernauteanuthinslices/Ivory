#!/bin/bash
# Verification script to check if permission fix is properly set up

echo "🔍 Verifying Permission Fix Setup"
echo "=================================="
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Please run this script from the project root"
    exit 1
fi

echo "✅ Running from project root"
echo ""

# Check Android setup
echo "📱 Checking Android setup..."
if [ ! -f "android/grant_permissions.sh" ]; then
    echo "❌ Missing: android/grant_permissions.sh"
    exit 1
fi
echo "✅ Found: android/grant_permissions.sh"

if [ ! -x "android/grant_permissions.sh" ]; then
    echo "⚠️  Warning: grant_permissions.sh is not executable"
    echo "   Running: chmod +x android/grant_permissions.sh"
    chmod +x android/grant_permissions.sh
fi
echo "✅ grant_permissions.sh is executable"

if [ ! -f "android/fastlane/Fastfile" ]; then
    echo "❌ Missing: android/fastlane/Fastfile"
    exit 1
fi
echo "✅ Found: android/fastlane/Fastfile"

# Check iOS setup
echo ""
echo "🍎 Checking iOS setup..."
if [ ! -f "ios/fastlane/Fastfile" ]; then
    echo "❌ Missing: ios/fastlane/Fastfile"
    exit 1
fi
echo "✅ Found: ios/fastlane/Fastfile"

# Check test helper files
echo ""
echo "🧪 Checking test helper files..."
if [ ! -f "integration_test/helpers/ciDetection.dart" ]; then
    echo "❌ Missing: integration_test/helpers/ciDetection.dart"
    exit 1
fi
echo "✅ Found: integration_test/helpers/ciDetection.dart"

if [ ! -f "integration_test/helpers/permissionsHelper.dart" ]; then
    echo "❌ Missing: integration_test/helpers/permissionsHelper.dart"
    exit 1
fi
echo "✅ Found: integration_test/helpers/permissionsHelper.dart"

if [ ! -f "integration_test/auth/loginToApp.dart" ]; then
    echo "❌ Missing: integration_test/auth/loginToApp.dart"
    exit 1
fi
echo "✅ Found: integration_test/auth/loginToApp.dart"

# Check documentation
echo ""
echo "📚 Checking documentation..."
if [ ! -f "integration_test/CI_PERMISSION_HANDLING.md" ]; then
    echo "⚠️  Warning: Missing CI_PERMISSION_HANDLING.md"
else
    echo "✅ Found: CI_PERMISSION_HANDLING.md"
fi

if [ ! -f "PERMISSION_FIX_SUMMARY.md" ]; then
    echo "⚠️  Warning: Missing PERMISSION_FIX_SUMMARY.md"
else
    echo "✅ Found: PERMISSION_FIX_SUMMARY.md"
fi

# Check for required tools
echo ""
echo "🛠️  Checking required tools..."

if command -v flutter &> /dev/null; then
    echo "✅ Flutter installed: $(flutter --version | head -n 1)"
else
    echo "❌ Flutter not found in PATH"
    exit 1
fi

if command -v patrol &> /dev/null; then
    echo "✅ Patrol CLI installed"
else
    echo "⚠️  Patrol CLI not found - install with: dart pub global activate patrol_cli"
fi

if command -v bundle &> /dev/null; then
    echo "✅ Bundler installed"
else
    echo "⚠️  Bundler not found - install with: gem install bundler"
fi

# Android specific checks
echo ""
echo "🤖 Checking Android tools..."
if command -v adb &> /dev/null; then
    echo "✅ adb installed"
    if adb devices | grep -q "device$"; then
        echo "✅ Android device/emulator connected"
    else
        echo "⚠️  No Android device/emulator detected"
    fi
else
    echo "⚠️  adb not found in PATH"
fi

# iOS specific checks (only on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo "🍏 Checking iOS tools (macOS only)..."
    if command -v xcrun &> /dev/null; then
        echo "✅ xcrun installed"
    else
        echo "❌ xcrun not found (Xcode not installed?)"
    fi
    
    if command -v pod &> /dev/null; then
        echo "✅ CocoaPods installed"
    else
        echo "⚠️  CocoaPods not found - install with: sudo gem install cocoapods"
    fi
fi

# Summary
echo ""
echo "=================================="
echo "✅ Verification Complete!"
echo ""
echo "Next steps:"
echo "1. Review changes: git diff"
echo "2. Test locally:"
echo "   - Android: cd android && bundle exec fastlane test"
echo "   - iOS: cd ios && bundle exec fastlane test"
echo "3. Commit changes: git add . && git commit -m 'Fix: Resolve CI permission dialog hangs'"
echo "4. Push and test in CI"
echo ""
echo "📖 Documentation:"
echo "   - PERMISSION_FIX_SUMMARY.md - Quick overview"
echo "   - integration_test/CI_PERMISSION_HANDLING.md - Detailed guide"
echo "   - BEFORE_AFTER_FLOW.md - Visual flow comparison"

