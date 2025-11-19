# Allure + Schemathesis Integration Package

> Drop-in package for integrating Patrol (Flutter), Allure, and Schemathesis into another project.
>
> This folder contains **copies** of the key helpers and scripts. Adjust package names, bundle IDs, and URLs for your app.

---

## 1. Files included

### Dart helper

- `lib/testing/token_export.dart`
  - Exports a JWT access token from your app to `.schemathesis_token` when built with `--dart-define=EXPORT_TOKEN=true`.

### Android test helpers

- `android/app/src/androidTest/resources/allure.properties`
  - Enables TestStorage-based Allure results:
    ```properties
    allure.results.useTestStorage=true
    ```
- `android/app/src/androidTest/java/com/thinslices/solarisdemo/AllureEnrichmentRule.kt`
- `android/app/src/androidTest/java/com/thinslices/solarisdemo/FilteredLogcatRule.kt`
- `android/app/src/androidTest/java/com/thinslices/solarisdemo/AllureStepHandler.kt`

> **Important**: Update the package name (`com.thinslices.solarisdemo`) to match your project.

**MainActivityTest rules for Allure overview**

In your instrumentation test entry point (e.g. `android/app/src/androidTest/java/.../MainActivityTest.java`) you should register the Allure-related JUnit rules so that the Allure overview gets populated with screenshots, UI hierarchy and enriched metadata:

```java
@RunWith(Parameterized.class)
public class MainActivityTest {
    @Rule
    public ScreenshotRule screenshotRule = new ScreenshotRule(ScreenshotRule.Mode.END, "ss_end");

    @Rule
    public WindowHierarchyRule windowHierarchyRule = new WindowHierarchyRule();

    @Rule
    public AllureEnrichmentRule allureEnrichmentRule = new AllureEnrichmentRule();

    @Rule
    public FilteredLogcatRule filteredLogcatRule = new FilteredLogcatRule();
    // ...
}
```

- `ScreenshotRule` / `WindowHierarchyRule` → attach end-of-test screenshots and the view hierarchy, visible in the test details and contributing to the overview.
- `AllureEnrichmentRule` → enriches tests with device, app and scenario metadata that appears in Allure labels and the overview widgets.
- `FilteredLogcatRule` → attaches filtered logcat output as an artifact so failures are diagnosable directly from Allure.

### Integration scripts

- `integration_test/allure_schemathesis_reporting/run_patrol_allure.sh`
- `integration_test/allure_schemathesis_reporting/run_schemathesis.sh`
- `integration_test/allure_schemathesis_reporting/run_schemathesis_allure.sh`
- `integration_test/allure_schemathesis_reporting/st_aggregate_to_allure.py`
- `integration_test/allure_schemathesis_reporting/patrol_env.sh`
- `integration_test/allure_schemathesis_reporting/sct_auth/get_schemathesis_token.sh`
- `integration_test/allure_schemathesis_reporting/sct_auth/ios_pull_token.sh`
- `integration_test/allure_schemathesis_reporting/schemathesis_severity.json` (template)

> The `run_patrol_allure.sh` here is the Patrol + Allure wrapper. In the current kit, it **does not** start Schemathesis or import its results by itself; you run Schemathesis explicitly via `run_schemathesis_allure.sh` as a separate step. You typically only need to adjust environment variables (e.g. `BASE_URL`, `PKG`, `BUNDLE_ID`) and, if desired, trim options you don't use.

---

## 2. Gradle changes (Android)

In your **app module** `android/app/build.gradle`:

1. **Instrumentation runner**

   ```groovy
   android {
       defaultConfig {
           testInstrumentationRunner "com.thinslices.solarisdemo.AllurePatrolJUnitRunner"
       }
   }
   ```

   - If your package is different, change `com.thinslices.solarisdemo` accordingly.

2. **Allure dependencies (androidTest)**

   ```groovy
   dependencies {
       androidTestImplementation "io.qameta.allure:allure-kotlin-model:2.4.0"
       androidTestImplementation "io.qameta.allure:allure-kotlin-commons:2.4.0"
       androidTestImplementation "io.qameta.allure:allure-kotlin-junit4:2.4.0"
       androidTestImplementation "io.qameta.allure:allure-kotlin-android:2.4.0"

       androidTestImplementation "androidx.test.uiautomator:uiautomator:2.2.0"
       androidTestUtil "androidx.test:orchestrator:1.5.1" // optional but recommended
   }
   ```

3. Ensure `allure.properties` is placed under:

   ```
   android/app/src/androidTest/resources/allure.properties
   ```

---

## 3. Flutter / Dart changes

In `pubspec.yaml` add (if not present):

```yaml
dependencies:
  path_provider: ^2.1.0  # or compatible version
```

Then add the helper file:

- Copy `lib/testing/token_export.dart` into your project.
- Wire it into your auth flow after a successful login, e.g.:

  ```dart
  import 'package:your_app/testing/token_export.dart';

  // After you obtain the access token
  if (kExportForSchemathesis) {
    await TokenExport.save(accessToken);
  }
  ```

Build tests with:

```bash
patrol test --dart-define=EXPORT_TOKEN=true ...
```

---

## 4. Tool installation (Allure, Schemathesis, Patrol)

Install these tools locally (and/or in CI) before using the scripts.

### 4.1 Allure CLI

Allure requires Java 8+ on the system.

- **macOS (Homebrew)**

  ```bash
  brew install qameta/allure/allure
  ```

- **Manual (any OS with Java)**

  1. Download the latest Allure commandline zip from: https://github.com/allure-framework/allure2/releases
  2. Unzip it to a stable location, e.g. `/opt/allure`.
  3. Add the `bin` folder to `PATH`, e.g. on macOS/Linux:

     ```bash
     export PATH="/opt/allure/bin:$PATH"
     ```

- **Verify**

  ```bash
  allure --version
  ```

### 4.2 Schemathesis

You can either install Schemathesis **globally** or let the scripts manage a **project-local venv**.

- **Global install (simple for local usage)**

  ```bash
  pip install --upgrade schemathesis
  # or, if you prefer pipx:
  # pipx install schemathesis
  ```

- **Project venv (matches the scripts’ default)**

  The scripts default to:

  ```text
  integration_test/allure_schemathesis_reporting/myenv/bin/schemathesis
  ```

  To create it manually:

  ```bash
  python3 -m venv integration_test/allure_schemathesis_reporting/myenv
  integration_test/allure_schemathesis_reporting/myenv/bin/pip install --upgrade pip
  integration_test/allure_schemathesis_reporting/myenv/bin/pip install schemathesis
  ```

  Or let the scripts do this automatically by setting:

  ```bash
  AUTO_VENV=1 ./integration_test/allure_schemathesis_reporting/run_schemathesis_allure.sh
  ```

### 4.3 Patrol CLI

Install the Patrol CLI globally with `dart pub`:

```bash
dart pub global activate patrol_cli
```

Ensure `~/.pub-cache/bin` (or the equivalent on your OS) is on your `PATH` so `patrol` is available:

```bash
export PATH="$HOME/.pub-cache/bin:$PATH"
```

Verify:

```bash
patrol --help
```

### 4.4 allure-xcresult (iOS converter)

Use this tool if you run Patrol + Allure on **iOS** and want to convert `.xcresult` bundles into Allure results.

```bash
git clone https://github.com/kvld/allure-xcresult.git
cd allure-xcresult
swift build -c release

# Optionally expose the binary on PATH as `allure-xcresult`
ln -s "$(pwd)/.build/release/AllureXCResult" /usr/local/bin/allure-xcresult
```

Then either:

- Let `run_patrol_allure.sh` find `allure-xcresult` on `PATH`, or
- Point it directly at the built binary via:

  ```bash
  ALLURE_XCRESULT_BIN=/usr/local/bin/allure-xcresult
  ```

---

## 5. Basic usage

> **Note (current kit behavior)**: The `run_patrol_allure.sh` script in this kit no longer starts Schemathesis or imports its results automatically. Schemathesis runs as a **separate step** via `run_schemathesis_allure.sh`. Toggles like `RUN_ST` and `IMPORT_ST_INTO_PATROL` are documented for backward compatibility with the original repo; in this kit's default scripts they are no-ops unless you re-introduce the corresponding logic.

### Toggle reference (env vars)

- **PLATFORM**  
  `android` | `ios` | `auto` (default).  
  `PLATFORM=android` → force Android; `auto` → auto-detect based on `adb` / `xcrun`.

- **SERVE_REPORT**  
  `0` (default in this kit) → generate an Allure report and keep it as static HTML only (no `allure serve`).  
  `SERVE_REPORT=1` → also run `allure serve` to open the report in a browser at the end of the run.

- **RUN_ST**  
  Legacy toggle from the original script. In this kit's default `run_patrol_allure.sh` it is **ignored**; Schemathesis is not started from the Patrol wrapper.  
  If you re-enable the background Schemathesis logic, `RUN_ST=1` would start the wrapper during the Patrol run and `RUN_ST=0` would skip it.

- **IMPORT_ST_INTO_PATROL**  
  Legacy toggle from the original script. In this kit's default `run_patrol_allure.sh` it is **ignored**; Schemathesis results are not imported into the Patrol Allure run.  
  If you re-enable the import logic, `IMPORT_ST_INTO_PATROL=1` would call `import_schemathesis_into_allure` and `IMPORT_ST_INTO_PATROL=0` would skip it.

- **EXPORT_TOKEN**  
  When set to a truthy value (`1`, `true`, etc.), adds `--dart-define=EXPORT_TOKEN=true` to `patrol test` so your app can export a token into `.schemathesis_token`.

- **GET_TOKEN_MODE** (Schemathesis)  
  `export_token` (default) → read token from `.schemathesis_token` created by the app.  
  `direct_api` → call `sct_auth/get_schemathesis_token.sh` to obtain a token via OAuth2 / API.

- **AUTO_VENV** (Schemathesis)  
  `1` → if `SCHEMATHESIS_BIN` is missing or broken, create `integration_test/allure_schemathesis_reporting/myenv` and install Schemathesis there before running.

- **ST_URL**  
  Base API URL for Schemathesis (required whenever Schemathesis runs).

- **ST_SCHEMA**, **ST_PHASES**, **ST_MODE**, **ST_WORKERS**, **ST_WEIGHT**  
  Fine-tune Schemathesis behaviour; see the headers of `run_schemathesis_allure.sh` / `run_schemathesis.sh` for defaults.

### Patrol + Allure only (no Schemathesis)

```bash
PLATFORM=android RUN_ST=0 SERVE_REPORT=1 \
  ./integration_test/allure_schemathesis_reporting/run_patrol_allure.sh integration_test
```

- **PLATFORM=android** → run tests on the Android device/emulator; skip iOS `.xcresult` handling.  
- **RUN_ST=0** → don't start Schemathesis; Patrol + Allure only (no effect in the default kit script, but shown here for compatibility with the original flow).  
- **SERVE_REPORT=1** → at the end, run `allure serve` to open the report in a browser.

> **Note:** The multi-step patterns below come from the original repo where the Patrol wrapper could start Schemathesis and import its results. With the current kit, you typically run Schemathesis separately via `run_schemathesis_allure.sh`, and `RUN_ST` / `IMPORT_ST_INTO_PATROL` have no effect unless you customize the script.

### Patrol + Schemathesis without app token export

1. **Patrol + Allure (no token export, no Schemathesis yet)**

   ```bash
   PLATFORM=android RUN_ST=0 IMPORT_ST_INTO_PATROL=0 SERVE_REPORT=0 \
     ./integration_test/allure_schemathesis_reporting/run_patrol_allure.sh integration_test
   ```

2. **Schemathesis + Allure (direct_api mode; token from auth script instead of the app)**

   ```bash
   AUTO_VENV=1 GET_TOKEN_MODE=direct_api \
   ST_URL="https://your-api.example.com" \
   ST_AUTH_URL="https://your-auth.example.com/oauth2/token" \
   ST_AUTH_CLIENT_ID="your-client-id" \
     ./integration_test/allure_schemathesis_reporting/run_schemathesis_allure.sh
   ```

3. **Patrol again to attach Schemathesis deeplink into the Patrol report**

   ```bash
   PLATFORM=android RUN_ST=0 IMPORT_ST_INTO_PATROL=1 SERVE_REPORT=0 \
     ./integration_test/allure_schemathesis_reporting/run_patrol_allure.sh integration_test
   ```

- **RUN_ST=0** → Schemathesis is never started from the Patrol wrapper; you run it explicitly in step 2.  
- **IMPORT_ST_INTO_PATROL=0** in step 1 → don’t import anything yet.  
- **IMPORT_ST_INTO_PATROL=1** in step 3 → call `import_schemathesis_into_allure` to add the aggregated Schemathesis test to the existing Patrol run.  
- **GET_TOKEN_MODE=direct_api** → Schemathesis calls your auth script instead of using `.schemathesis_token` from the app.

### Patrol + token export + Schemathesis (export_token mode)

1. **Patrol login + token export**

   ```bash
   PLATFORM=android EXPORT_TOKEN=1 RUN_ST=0 IMPORT_ST_INTO_PATROL=0 SERVE_REPORT=0 \
     ./integration_test/allure_schemathesis_reporting/run_patrol_allure.sh integration_test/login_test.dart
   ```

2. **Schemathesis + Allure (token exported by the app)**

   ```bash
   AUTO_VENV=1 GET_TOKEN_MODE=export_token ST_URL="https://your-api.example.com" \
     ./integration_test/allure_schemathesis_reporting/run_schemathesis_allure.sh
   ```

3. **Patrol again to attach Schemathesis deeplink**

   ```bash
   PLATFORM=android RUN_ST=0 IMPORT_ST_INTO_PATROL=1 SERVE_REPORT=0 \
     ./integration_test/allure_schemathesis_reporting/run_patrol_allure.sh integration_test/login_test.dart
   ```

- **EXPORT_TOKEN=1** → app saves a token to `.schemathesis_token` during the login test.  
- **GET_TOKEN_MODE=export_token** → Schemathesis reads the token from `.schemathesis_token`.  
- Other toggles behave as described in the toggle reference above.

---

## 6. Schemathesis direct_api mode

Instead of pulling tokens from the device, you can obtain them via OAuth2:

```bash
AUTO_VENV=1 GET_TOKEN_MODE=direct_api \
ST_URL="https://your-api.example.com" \
ST_AUTH_URL="https://your-auth.example.com/oauth2/token" \
ST_AUTH_CLIENT_ID="your-client-id" \
ST_AUTH_CLIENT_SECRET="..." \  # if your auth script expects it
ST_AUTH_USERNAME="..." \       # for password grant, if used
ST_AUTH_PASSWORD="..." \       # for password grant, if used
./integration_test/allure_schemathesis_reporting/run_schemathesis_allure.sh
```

See `integration_test/allure_schemathesis_reporting/sct_auth/get_schemathesis_token.sh` for details.

---

## 7. Git ignore suggestions

In your new project, ignore:

```gitignore
/integration_test/allure_schemathesis_reporting/myenv/
/integration_test/schemathesis-report/
/build/allure-report/
/build/allure-report-schemathesis/
/build/schemathesis-allure/
.schemathesis_token
```

These keep venvs, local reports, and tokens out of version control.

---

This package is a starting point; adapt paths, package names, and URLs to fit your project structure.
