#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${ARC_CLEAN_KEYSTORE:?Set ARC_CLEAN_KEYSTORE to your private keystore path}"
: "${SIGNING_KEYSTORE_PASSWORD:?Set SIGNING_KEYSTORE_PASSWORD}"
: "${SIGNING_KEY_ALIAS:?Set SIGNING_KEY_ALIAS}"
: "${SIGNING_KEY_PASSWORD:?Set SIGNING_KEY_PASSWORD}"
export ARC_CLEAN_KEYSTORE SIGNING_KEYSTORE_PASSWORD SIGNING_KEY_ALIAS SIGNING_KEY_PASSWORD
test -f "$ARC_CLEAN_KEYSTORE"
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs --build-filter=test/mocks.mocks.dart
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings \
  lib/flauncher.dart lib/providers/settings_service.dart lib/widgets/category_clean_row.dart \
  lib/widgets/settings/flauncher_about_dialog.dart \
  lib/widgets/settings/appearance_panel_page.dart lib/widgets/settings/settings_panel.dart \
  lib/widgets/settings/favorite_icon_size_page.dart \
  test/widgets/favorite_dock_test.dart test/providers/settings_service_test.dart
flutter test --no-pub test/widgets/favorite_dock_test.dart test/providers/settings_service_test.dart
flutter build apk --no-pub --release --flavor github --split-per-abi --target-platform android-arm,android-arm64 \
  --dart-define=ENABLE_SELF_UPDATER=false --build-name=1.2.0-abf1 --build-number=4130
