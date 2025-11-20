#!/bin/bash
# Script to grant permissions to the app after installation
# This script waits for the app to be installed and then grants all necessary permissions

PACKAGE_NAME="com.thinslices.solarisdemo"
MAX_WAIT=60  # Maximum seconds to wait for app installation
WAIT_INTERVAL=2  # Check every 2 seconds

echo "🔍 Waiting for $PACKAGE_NAME to be installed..."

# Wait for the app to be installed
elapsed=0
while [ $elapsed -lt $MAX_WAIT ]; do
    if adb shell pm list packages | grep -q "$PACKAGE_NAME"; then
        echo "✅ App detected! Waiting 2 seconds for installation to settle..."
        sleep 2
        break
    fi
    sleep $WAIT_INTERVAL
    elapsed=$((elapsed + WAIT_INTERVAL))
done

# Check if app was found
if ! adb shell pm list packages | grep -q "$PACKAGE_NAME"; then
    echo "❌ App not found after ${MAX_WAIT}s. Permissions will not be granted."
    exit 1
fi

echo "🔓 Granting permissions to $PACKAGE_NAME..."

# Grant all permissions
adb shell pm grant $PACKAGE_NAME android.permission.POST_NOTIFICATIONS 2>/dev/null || echo "  ⚠️ Could not grant POST_NOTIFICATIONS"
adb shell pm grant $PACKAGE_NAME android.permission.ACCESS_FINE_LOCATION 2>/dev/null || echo "  ⚠️ Could not grant ACCESS_FINE_LOCATION"
adb shell pm grant $PACKAGE_NAME android.permission.ACCESS_COARSE_LOCATION 2>/dev/null || echo "  ⚠️ Could not grant ACCESS_COARSE_LOCATION"
adb shell pm grant $PACKAGE_NAME android.permission.CAMERA 2>/dev/null || echo "  ⚠️ Could not grant CAMERA"
adb shell pm grant $PACKAGE_NAME android.permission.MICROPHONE 2>/dev/null || echo "  ⚠️ Could not grant MICROPHONE"
adb shell pm grant $PACKAGE_NAME android.permission.RECORD_AUDIO 2>/dev/null || echo "  ⚠️ Could not grant RECORD_AUDIO"
adb shell pm grant $PACKAGE_NAME android.permission.READ_EXTERNAL_STORAGE 2>/dev/null || echo "  ⚠️ Could not grant READ_EXTERNAL_STORAGE"
adb shell pm grant $PACKAGE_NAME android.permission.WRITE_EXTERNAL_STORAGE 2>/dev/null || echo "  ⚠️ Could not grant WRITE_EXTERNAL_STORAGE"
adb shell pm grant $PACKAGE_NAME android.permission.READ_MEDIA_IMAGES 2>/dev/null || echo "  ⚠️ Could not grant READ_MEDIA_IMAGES"
adb shell pm grant $PACKAGE_NAME android.permission.READ_MEDIA_VIDEO 2>/dev/null || echo "  ⚠️ Could not grant READ_MEDIA_VIDEO"

echo "✅ Permission granting completed!"

# Verify critical permission (POST_NOTIFICATIONS)
if adb shell dumpsys package $PACKAGE_NAME | grep -q "android.permission.POST_NOTIFICATIONS.*granted=true"; then
    echo "✅ POST_NOTIFICATIONS verified as granted"
else
    echo "⚠️ POST_NOTIFICATIONS may not be granted (this is expected on Android < 13)"
fi

exit 0

