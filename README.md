# Arc Clean

A personal customization of [Arc Launcher](https://github.com/meddouribadis/arclauncher), based on upstream commit `58fca01519b5884ad6aa3c550019d6eb60818be4` (1.2.0).

## Changes

- Adjustable favourite card size: 50%, 67%, 75%, or 100%; default 67% of the original width and height.
- Fill each row before wrapping, with up to three visible rows and scrolling for additional favourites.
- Remote navigation and reordering follow the selected column count.
- Wallpaper rotation stays enabled while the wallpaper source line is hidden.
- Separate app package `com.omeda.arc.clean`, labelled Arc Clean. The upstream self-updater is disabled in the release build command.

Change size in **Settings → Interface → Appearance → Favourites icon size**.

## Release 1.2.0-clean3 (4129)

The ARMv7 (`armeabi-v7a`) APK was built and installed on a Homatics Box R 4K Plus running Android TV 14. This device uses 32-bit Android app ABIs despite its 64-bit processor. Other devices and ABIs have not been verified.

All 33 focused layout/navigation/settings tests passed. The TV screenshot confirmed that the nine existing favourites fit in one row at 67%, with their order preserved. Three-row behaviour was checked by widget tests.

## Build

Use Flutter **3.41.9**, JDK **17**, Android SDK platform **36**, and build-tools **36.0.0**. Install the SDK command-line tools, accept their licences and put Flutter on PATH. Keep the dependency versions in `pubspec.lock`.

Supply your own release signing key outside this repository through these environment variables:

- `ARC_CLEAN_KEYSTORE`: absolute path to the keystore.
- `SIGNING_KEYSTORE_PASSWORD`, `SIGNING_KEY_ALIAS`, `SIGNING_KEY_PASSWORD`.

The original signing key is private. A build signed with a different key cannot update an existing installation signed by the original key. Preserve app data before changing installations.

Run `bash scripts/build-release.sh`. The script generates localisations and mocks, runs the focused checks and builds `1.2.0-clean3` / version code `4129`, ARMv7, with the upstream updater disabled. To release a future update, increase the version code.

The APK output is `build/app/outputs/apk/github/release/arc-launcher-armeabi-v7a-release.apk`.

## Provenance and licence

This modification retains the upstream GPL-3.0-or-later licence and copyright notices; see [LICENSE](LICENSE). Arc Launcher derives from LTvLauncher and FLauncher. Upstream acknowledgements and historical documentation are preserved in [README.upstream.md](README.upstream.md).

This is an independent customization. The original project's Play Store links, downloader codes and releases refer to upstream Arc Launcher. Its release and Play publishing workflows are omitted from this snapshot; builds are local.
