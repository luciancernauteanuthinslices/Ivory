# Environment for Patrol + Allure runs
# Source automatically by run_patrol_allure.sh if present
# Before running script run in console: chmod +x integration_test/allure_schemathesis_reporting/patrol_env.sh

# Core metadata for Allure environment panel
export APP_VERSION="1.0"
export FLAVOR="prod"
export APP_ENV="prod"
export BASE_URL="jsxhc7emf3.execute-api.eu-west-1.amazonaws.com"
export GIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo '')"

# Optional custom attachments (appear on each test's page)
export PATROL_CONFIG_JSON=""      # e.g. '{"retries":1}'
export FEATURE_FLAGS_TEXT=""      # e.g. $'flagA=true\nflagB=false'

# Platform selection (android|ios|auto)
export PLATFORM="${PLATFORM:-auto}"

# Tag filtering (Patrol supports complex expressions)
# Examples:
#   TAGS="smoke"
#   TAGS="smoke||regression"
#   TAGS="(login && smoke)"
#   EXCLUDE_TAGS="regression"
export TAGS=""
export EXCLUDE_TAGS=""

# iOS converter selection (any one is enough)
# If you installed the binary to PATH you can leave these empty.
export ALLURE_XCRESULT_BIN=""       # e.g. /usr/local/bin/AllureXCResult
export ALLURE_XCRESULT_REPO=""      # e.g. /Users/.../Documents/Repos/allure-xcresult
