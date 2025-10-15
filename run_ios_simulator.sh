#!/bin/bash

# Script to build and run the iOS app on simulator
# Usage: ./run_ios_simulator.sh [CLIENT_NAME]

CLIENT=${1:-default}

echo "🚀 Building and running iOS app for simulator (CLIENT=$CLIENT)..."
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode first."
    exit 1
fi

# List available simulators
echo "📱 Available iOS Simulators:"
xcrun simctl list devices available | grep "iPhone" | head -5
echo ""

# Build and run
echo "🔨 Building and launching app..."
flutter run -d iPhone --dart-define=CLIENT=$CLIENT

echo ""
echo "✅ Done!"
