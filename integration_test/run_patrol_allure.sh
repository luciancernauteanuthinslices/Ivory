#!/usr/bin/env bash
# run one-time before in console: chmod +x integration_test/run_patrol_allure.sh

set -euo pipefail

# --- INPUTS / DEFAULTS -------------------------------------------------------
TARGET="${1:-${TARGET:-integration_test}}"   # allow arg, $TARGET, or default directory
RUN_DIR="build/reports/allure-results/$(date +%Y%m%d-%H%M%S)-$$"
REPORT_DIR="build/allure-report"
PLATFORM="${PLATFORM:-auto}"   # android|ios|auto
ALLURE_XCRESULT_BIN="${ALLURE_XCRESULT_BIN:-}"
ALLURE_XCRESULT_REPO="${ALLURE_XCRESULT_REPO:-}"
ENV_FILE="integration_test/patrol_env.sh"
TAGS="${TAGS:-}"
EXCLUDE_TAGS="${EXCLUDE_TAGS:-}"

# --- SANITY CHECKS (common) --------------------------------------------------
if ! command -v patrol >/dev/null; then
  echo "ERROR: Patrol CLI not found in PATH."; exit 4
fi
if ! command -v allure >/dev/null; then
  echo "ERROR: Allure CLI not found in PATH."; exit 3
fi
# Optional: load environment exports
if [ -f "$ENV_FILE" ]; then . "$ENV_FILE"; fi

if [ ! -f "$TARGET" ] && [ ! -d "$TARGET" ]; then
  echo "Usage: $0 integration_test/your_test.dart | integration_test/"
  echo "Tip: pass a file, a directory, or set \$TARGET. Current: '$TARGET' not found."
  exit 1
fi

# --- DETECT PLATFORM ---------------------------------------------------------
detect_platform() {
  if [ "$PLATFORM" = "android" ]; then echo android; return; fi
  if [ "$PLATFORM" = "ios" ]; then echo ios; return; fi
  if adb get-state >/dev/null 2>&1; then echo android; return; fi
  if command -v xcrun >/dev/null; then echo ios; return; fi
  echo android
}

PLAT=$(detect_platform)

# --- HELPERS -----------------------------------------------------------------
convert_xcresult() {
  local input="$1"; shift
  local output="$1"; shift
  if [ -n "$ALLURE_XCRESULT_BIN" ] && [ -x "$ALLURE_XCRESULT_BIN" ]; then
    echo ">> Using converter: $ALLURE_XCRESULT_BIN"
    "$ALLURE_XCRESULT_BIN" --input "$input" --output "$output"
    return
  fi
  if command -v allure-xcresult >/dev/null 2>&1; then
    echo ">> Using converter binary in PATH: allure-xcresult"
    allure-xcresult --input "$input" --output "$output"
    return
  fi
  if command -v AllureXCResult >/dev/null 2>&1; then
    echo ">> Using converter binary in PATH: AllureXCResult"
    AllureXCResult --input "$input" --output "$output"
    return
  fi
  if [ -n "$ALLURE_XCRESULT_REPO" ] && [ -d "$ALLURE_XCRESULT_REPO" ]; then
    echo ">> Using swift run from repo: $ALLURE_XCRESULT_REPO"
    (cd "$ALLURE_XCRESULT_REPO" && swift run -c release AllureXCResult --input "$input" --output "$output")
    return
  fi
  echo "ERROR: No allure-xcresult converter found. Set ALLURE_XCRESULT_BIN to the built binary path or ALLURE_XCRESULT_REPO to the cloned repo." >&2
  exit 5
}

# --- RUN TESTS ---------------------------------------------------------------
PATROL_ARGS=()
if [ -n "$TAGS" ]; then PATROL_ARGS+=(--tags "$TAGS"); fi
if [ -n "$EXCLUDE_TAGS" ]; then PATROL_ARGS+=(--exclude-tags "$EXCLUDE_TAGS"); fi

ANY_FAIL=0
MULTI=0
if [ "$#" -gt 1 ]; then MULTI=1; fi

if [ "$MULTI" -eq 1 ]; then
  # Run each provided test file sequentially, aggregate results, continue on failures
  mkdir -p "$(dirname "$RUN_DIR")"
  for TEST_FILE in "$@"; do
    if [ ! -f "$TEST_FILE" ]; then
      echo ">> Skipping non-file argument: $TEST_FILE"
      continue
    fi
    echo ">> Running Patrol on: $TEST_FILE (platform: $PLAT)"
    set +e
    patrol test --target "$TEST_FILE" ${PATROL_ARGS[@]+"${PATROL_ARGS[@]}"}
    RC=$?
    set -e

    if [ "$PLAT" = "android" ]; then
      mkdir -p "$RUN_DIR"
      if ! adb get-state >/dev/null 2>&1; then
        echo "ERROR: No Android device/emulator detected (adb)."; exit 2
      fi
      echo ">> Pulling Allure results from Android device..."
      adb exec-out sh -c 'cd /sdcard/googletest/test_outputfiles && tar cf - allure-results' \
      | tar xvf - -C "$RUN_DIR" --strip-components=1
    else
      echo ">> Locating latest .xcresult..."
      LATEST_XCRESULT=$(find build -maxdepth 3 -name "*.xcresult" -type d -print0 2>/dev/null | xargs -0 ls -1td 2>/dev/null | head -n1)
      if [ -z "${LATEST_XCRESULT:-}" ] || [ ! -d "$LATEST_XCRESULT" ]; then
        echo "ERROR: Could not find .xcresult bundle under ./build. Set $XCRESULT_PATH explicitly."; exit 6
      fi
      # Populate iOS device info for Allure environment if not provided
      if [ -z "${DEVICE_NAME:-}" ] || [ -z "${API_LEVEL:-}" ]; then
        if command -v python3 >/dev/null 2>&1; then
          IOS_INFO="$(python3 - <<'PY'
import json, subprocess, re
data=json.loads(subprocess.check_output(["xcrun","simctl","list","devices","-j"]))
boot=None; rt=""
for runtime, devices in data.get("devices",{}).items():
    for d in devices:
        if d.get("state")=="Booted":
            boot=d; rt=runtime; break
    if boot: break
name=boot.get("name","") if boot else ""
ver=""
m=re.search(r"iOS-(\\d+)-(\\d+)", rt)
if m: ver=f"{m.group(1)}.{m.group(2)}"
print(name)
print(ver)
PY
)"
          IOS_NAME="$(printf "%s" "$IOS_INFO" | sed -n '1p')"
          IOS_VER="$(printf "%s" "$IOS_INFO" | sed -n '2p')"
          DEVICE_NAME=${DEVICE_NAME:-"${IOS_NAME:-iOS Simulator}"}
          API_LEVEL=${API_LEVEL:-"${IOS_VER:-}"}
        else
          BOOTED_LINE=$(xcrun simctl list devices | grep -m1 '(Booted)' || true)
          if [ -z "${DEVICE_NAME:-}" ] && [ -n "$BOOTED_LINE" ]; then
            DEVICE_NAME=$(echo "$BOOTED_LINE" | sed -E 's/^[[:space:]]*([^()]+) \(.*/\1/' | xargs)
          fi
          # API_LEVEL left empty if not detected
        fi
      fi
      # Convert each run into a unique output dir, then merge into RUN_DIR
      PART_DIR="${RUN_DIR}-part-$(basename "$TEST_FILE" .dart)-$(date +%H%M%S)-$$"
      mkdir -p "$(dirname "$PART_DIR")"
      convert_xcresult "$LATEST_XCRESULT" "$PART_DIR"
      mkdir -p "$RUN_DIR"
      cp -a "$PART_DIR"/* "$RUN_DIR"/ || true
    fi

    if [ "$RC" -ne 0 ]; then ANY_FAIL=1; fi
  done
else
  echo ">> Running Patrol on: $TARGET (platform: $PLAT)"
  if [ -f "$TARGET" ]; then
    set +e
    patrol test --target "$TARGET" ${PATROL_ARGS[@]+"${PATROL_ARGS[@]}"}
    RC=$?
    set -e
  elif [ -d "$TARGET" ]; then
    # If it's the default integration_test directory, let Patrol discover tests itself
    if [ "$(basename "$TARGET")" = "integration_test" ]; then
      set +e
      patrol test ${PATROL_ARGS[@]+"${PATROL_ARGS[@]}"}
      RC=$?
      set -e
    else
      echo "ERROR: Directory targets other than 'integration_test' are not supported by this script."
      echo "Run a loop externally, e.g.: find $TARGET -name '*_test.dart' -print0 | xargs -0 -n1 $0"
      exit 7
    fi
  fi

  if [ "$PLAT" = "android" ]; then
    mkdir -p "$RUN_DIR"
    # --- ANDROID: COLLECT FROM TEST STORAGE ------------------------------------
    if ! adb get-state >/dev/null 2>&1; then
      echo "ERROR: No Android device/emulator detected (adb)."; exit 2
    fi
    echo ">> Pulling Allure results from Android device..."
    adb exec-out sh -c 'cd /sdcard/googletest/test_outputfiles && tar cf - allure-results' \
    | tar xvf - -C "$RUN_DIR" --strip-components=1
  else
    # --- IOS: CONVERT XCRESULT WITH allure-xcresult ----------------------------
    echo ">> Locating latest .xcresult..."
    XCRESULT_PATH=${XCRESULT_PATH:-$(find build -maxdepth 3 -name "*.xcresult" -type d -print0 2>/dev/null | xargs -0 ls -1td 2>/dev/null | head -n1)}
    if [ -z "${XCRESULT_PATH:-}" ] || [ ! -d "$XCRESULT_PATH" ]; then
      echo "ERROR: Could not find .xcresult bundle under ./build. Set $XCRESULT_PATH explicitly."; exit 6
    fi
    echo ">> Converting xcresult to Allure results: $XCRESULT_PATH"
    # Populate iOS device info for Allure environment if not provided
    if [ -z "${DEVICE_NAME:-}" ] || [ -z "${API_LEVEL:-}" ]; then
      if command -v python3 >/dev/null 2>&1; then
        IOS_INFO="$(python3 - <<'PY'
import json, subprocess, re
data=json.loads(subprocess.check_output(["xcrun","simctl","list","devices","-j"]))
boot=None; rt=""
for runtime, devices in data.get("devices",{}).items():
    for d in devices:
        if d.get("state")=="Booted":
            boot=d; rt=runtime; break
    if boot: break
name=boot.get("name","" ) if boot else ""
ver=""
m=re.search(r"iOS-(\\d+)-(\\d+)", rt)
if m: ver=f"{m.group(1)}.{m.group(2)}"
print(name)
print(ver)
PY
)"
        IOS_NAME="$(printf "%s" "$IOS_INFO" | sed -n '1p')"
        IOS_VER="$(printf "%s" "$IOS_INFO" | sed -n '2p')"
        DEVICE_NAME=${DEVICE_NAME:-"${IOS_NAME:-iOS Simulator}"}
        API_LEVEL=${API_LEVEL:-"${IOS_VER:-}"}
      else
        BOOTED_LINE=$(xcrun simctl list devices | grep -m1 '(Booted)' || true)
        if [ -z "${DEVICE_NAME:-}" ] && [ -n "$BOOTED_LINE" ]; then
          DEVICE_NAME=$(echo "$BOOTED_LINE" | sed -E 's/^[[:space:]]*([^()]+) \(.*/\1/' | xargs)
        fi
        # API_LEVEL left empty if not detected
      fi
    fi
    # Ensure parent exists, but do NOT pre-create the output directory itself
    mkdir -p "$(dirname "$RUN_DIR")"
    convert_xcresult "$XCRESULT_PATH" "$RUN_DIR"
  fi

  if [ "${RC:-0}" -ne 0 ]; then ANY_FAIL=1; fi
fi

# --- VERIFY WE HAVE RESULTS --------------------------------------------------
shopt -s nullglob
RESULT_FILES=("$RUN_DIR"/*-result.json)
if [ ${#RESULT_FILES[@]} -eq 0 ]; then
  echo "ERROR: No Allure results found in run dir."
  echo "Searched: $RUN_DIR"
  exit 10
fi

# --- ADD ENVIRONMENT PANEL ---------------------------------------------------
echo ">> Writing environment.properties..."
APP_VERSION=${APP_VERSION:-""}
FLAVOR=${FLAVOR:-""}
DEVICE_NAME=${DEVICE_NAME:-""}
API_LEVEL=${API_LEVEL:-""}
GIT_SHA=${GIT_SHA:-$(git rev-parse --short HEAD 2>/dev/null || echo "")}
BASE_URL=${BASE_URL:-""}

if [ "$PLAT" = "android" ]; then
  DEVICE_NAME=${DEVICE_NAME:-"$(adb shell getprop ro.product.manufacturer | tr -d '\r') $(adb shell getprop ro.product.model | tr -d '\r')"}
  API_LEVEL=${API_LEVEL:-"$(adb shell getprop ro.build.version.sdk | tr -d '\r')"}
fi

cat > "$RUN_DIR/environment.properties" <<EOF
appVersion=${APP_VERSION}
flavor=${FLAVOR}
device=${DEVICE_NAME}
apiLevel=${API_LEVEL}
gitSha=${GIT_SHA}
baseUrl=${BASE_URL}
EOF

# --- ADD CATEGORIES (FAILURE BUCKETS) ---------------------------------------
cat > "$RUN_DIR/categories.json" <<'EOF'
[
  {"name":"App crashes","matchedStatuses":["failed"],"messageRegex":".*Fatal Exception.*"},
  {"name":"UI not found","matchedStatuses":["failed"],"messageRegex":".*findsOneWidget.*"},
  {"name":"Network/timeout","matchedStatuses":["failed"],"messageRegex":".*(Timeout|SocketException).*"}
]
EOF

# --- PRESERVE HISTORY --------------------------------------------------------
if [ -d "$REPORT_DIR/history" ]; then
  echo ">> Preserving history from previous report..."
  cp -r "$REPORT_DIR/history" "$RUN_DIR/" || true
fi

# --- GENERATE & SERVE REPORT -------------------------------------------------
echo ">> Generating Allure report..."
allure generate "$RUN_DIR" -o "$REPORT_DIR" --clean

echo ">> Serving Allure report (Ctrl+C to stop)..."
allure serve "$RUN_DIR"
