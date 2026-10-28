# Build ABF Launcher

The release source is built with **Flutter 3.41.9**, **JDK 17**, Android SDK platform **36**, and build-tools **36.0.0**. Keep the versions in `pubspec.lock`.

## Development setup

```bash
git clone https://github.com/emigabi/abf-luncher.git
cd abf-luncher
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs --build-filter=test/mocks.mocks.dart
```

The focused suite used for version 1.0.0 contains 46 tests:

```bash
flutter test --no-pub test/widgets/favorite_dock_test.dart test/widgets/focus_aware_app_bar_test.dart test/providers/settings_service_test.dart
```

Run additional analysis and tests relevant to your changes. The release script lists the focused analyzer targets and runs these tests before compiling.

## Signed release APKs

Install the Android SDK command-line tools, accept their licences, and put Flutter and JDK 17 on your PATH. Set `ANDROID_HOME` to your SDK installation.

Supply your own signing key outside the repository using these environment variables:

- `ARC_CLEAN_KEYSTORE`: absolute path to your keystore.
- `SIGNING_KEYSTORE_PASSWORD`: keystore password.
- `SIGNING_KEY_ALIAS`: key alias.
- `SIGNING_KEY_PASSWORD`: key password.

Then run:

```bash
bash scripts/build-release.sh
```

This generates localisations and mocks, runs the focused checks, and builds separate ARMv7 and ARM64 APKs with the upstream self-updater disabled.

Version 1.0.0 uses base build number **4134**, producing Android version codes **5134** for ARMv7 and **6134** for ARM64. Increase the base build number for a future app update.

Outputs:

```text
build/app/outputs/apk/github/release/abf-launcher-armeabi-v7a-release.apk
build/app/outputs/apk/github/release/abf-launcher-arm64-v8a-release.apk
```

The package ID is `com.omeda.arc.clean`. The project's release signing key is private; a locally signed APK cannot update an existing release signed with that key. Keep keys and passwords out of commits.

## Release verification

The published 1.0.0 APKs passed package, label, release-signature, native ABI and Flutter ELF architecture checks. The ARMv7 build was installed and checked on a Box R 4K Plus running Android TV 14. ARM64 has not been tested on a physical ARM64 device.

Build and release publishing are currently performed locally; this repository does not claim an automated CI or publishing pipeline.
