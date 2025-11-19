fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android test

```sh
[bundle exec] fastlane android test
```

Run Patrol integration tests on Android

### android build_release

```sh
[bundle exec] fastlane android build_release
```

Build Android release APK

### android build_apks

```sh
[bundle exec] fastlane android build_apks
```

Build APKs only (without running tests)

### android deploy_internal

```sh
[bundle exec] fastlane android deploy_internal
```

Build and deploy to internal testing

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
