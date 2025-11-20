#!/bin/bash
# Script to grant permissions to the app after installation
# This script waits for the app to be installed and then grants all necessary permissions

set -e  # Exit on error

PACKAGE_NAME="com.thinslices.solarisdemo"
MAX_WAIT=60  # Maximum seconds to wait for app installation
WAIT_INTERVAL=1  # Check every 1 second

echo "🔍 [$(date +%H:%M:%S)] Waiting for $PACKAGE_NAME to be installed..."

# Wait for the app to be installed
elapsed=0
while [ $elapsed -lt $MAX_WAIT ]; do
    if adb shell pm list packages 2>/dev/null | grep -q "$PACKAGE_NAME"; then
        echo "✅ [$(date +%H:%M:%S)] App detected! Waiting 3 seconds for installation to settle..."
        sleep 3
        break
    fi
    echo "   [$(date +%H:%M:%S)] Still waiting... ($elapsed/$MAX_WAIT seconds)"
    sleep $WAIT_INTERVAL
    elapsed=$((elapsed + WAIT_INTERVAL))
done

# Check if app was found
if ! adb shell pm list packages 2>/dev/null | grep -q "$PACKAGE_NAME"; then
    echo "❌ [$(date +%H:%M:%S)] App not found after ${MAX_WAIT}s. Permissions will not be granted."
    exit 1
fi

echo "🔓 [$(date +%H:%M:%S)] Granting permissions to $PACKAGE_NAME..."

# Function to grant permission with retry
grant_permission() {
    local perm=$1
    local perm_name=$2
    local max_retries=3
    
    for i in $(seq 1 $max_retries); do
        if adb shell pm grant $PACKAGE_NAME $perm 2>/dev/null; then
            echo "  ✅ Granted $perm_name"
            return 0
        fi
        sleep 1
    done
    echo "  ⚠️  Could not grant $perm_name (may not exist on this Android version)"
    return 1
}

# Grant all permissions with retries
echo "  📱 Granting notification permission (critical for login)..."
grant_permission "android.permission.POST_NOTIFICATIONS" "POST_NOTIFICATIONS"

echo "  📍 Granting location permissions..."
grant_permission "android.permission.ACCESS_FINE_LOCATION" "ACCESS_FINE_LOCATION"
grant_permission "android.permission.ACCESS_COARSE_LOCATION" "ACCESS_COARSE_LOCATION"

echo "  📷 Granting camera/microphone permissions..."
grant_permission "android.permission.CAMERA" "CAMERA"
grant_permission "android.permission.MICROPHONE" "MICROPHONE"
grant_permission "android.permission.RECORD_AUDIO" "RECORD_AUDIO"

echo "  💾 Granting storage permissions..."
grant_permission "android.permission.READ_EXTERNAL_STORAGE" "READ_EXTERNAL_STORAGE"
grant_permission "android.permission.WRITE_EXTERNAL_STORAGE" "WRITE_EXTERNAL_STORAGE"
grant_permission "android.permission.READ_MEDIA_IMAGES" "READ_MEDIA_IMAGES"
grant_permission "android.permission.READ_MEDIA_VIDEO" "READ_MEDIA_VIDEO"

echo "✅ [$(date +%H:%M:%S)] Permission granting completed!"

# Verify critical permissions
echo "🔍 [$(date +%H:%M:%S)] Verifying permissions..."
if adb shell dumpsys package $PACKAGE_NAME 2>/dev/null | grep -q "android.permission.POST_NOTIFICATIONS.*granted=true"; then
    echo "✅ POST_NOTIFICATIONS verified as granted"
elif adb shell dumpsys package $PACKAGE_NAME 2>/dev/null | grep -q "android.permission.POST_NOTIFICATIONS"; then
    echo "ℹ️  POST_NOTIFICATIONS exists but status unclear"
else
    echo "ℹ️  POST_NOTIFICATIONS not in manifest or Android < 13"
fi

# Show all granted runtime permissions
echo "📋 [$(date +%H:%M:%S)] Granted runtime permissions:"
adb shell dumpsys package $PACKAGE_NAME 2>/dev/null | grep "granted=true" | head -n 10 || echo "  (Could not list permissions)"

echo "🏁 [$(date +%H:%M:%S)] Permission script finished successfully"
exit 0

