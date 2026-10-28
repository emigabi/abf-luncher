# ABF Launcher

Current ABF Launcher version: **1.0.0**.

A personal customization of [Arc Launcher](https://github.com/meddouribadis/arclauncher), based on the upstream Arc Launcher release 1.2.0, commit `58fca01519b5884ad6aa3c550019d6eb60818be4`.

## Acknowledgements

[Arc Launcher — original repository](https://github.com/meddouribadis/arclauncher)

Thank you to **meddouribadis** for creating and sharing Arc Launcher, the open-source foundation of this customized launcher.

[CleanYourTV — original repository](https://github.com/Gathin23/cleanyourtv)

Thank you to **Gathin23** for creating and sharing CleanYourTV, which helped guide this Android TV cleanup and launcher setup.

## Changes

- Adjustable favourite card size: 50%, 67%, 75%, or 100%; default 67% of the original width and height.
- Fill each row before wrapping, with up to three visible rows and scrolling for additional favourites.
- Remote navigation and reordering follow the selected column count.
- Wallpaper rotation stays enabled while the wallpaper source line is hidden.
- Favourites sit directly below the status bar, above Watch Next.
- An All apps tab button beside Settings and Wi-Fi shows or hides non-favourite apps.
- Other apps appear in a bottom-aligned, lazy scrolling grid while Favourites stay at the top.
- Opening All apps temporarily hides Watch Next; closing it or pressing Back restores Watch Next if enabled.
- Watch Next tiles show the source app name at the top.
- Date format presets include `E MMMd, y` (for example, `Sat Jan17, 2026`).
- Separate app package `com.omeda.arc.clean`, labelled ABF Launcher. The upstream self-updater is disabled in the release build command.

Change size in **Settings → Interface → Appearance → Favourites icon size**.

## Downloads

[Latest release](https://github.com/emigabi/abf-luncher/releases/latest)

- **ARMv7 (`armeabi-v7a`)**: use this for the Box R 4K Plus used in this project.
- **ARM64 (`arm64-v8a`)**: for devices whose Android installation supports 64-bit apps.

Choose the APK matching the Android app ABI, rather than the processor marketing specification.

## Device verification

The ARMv7 (`armeabi-v7a`) build was installed and launched on a Homatics Box R 4K Plus running Android TV 14, preserving existing favourites and wallpaper settings. This device uses 32-bit Android app ABIs despite its 64-bit processor. ARM64 builds are provided for compatible devices; they have not been tested on a physical ARM64 device.

All 46 focused layout/navigation/settings tests passed, including an 80-app grid traversed by remote keys. Screenshots pulled from the TV verified the All apps button, expanded grid, remote scrolling to the final app, Favourites staying fixed at the top, and Back closing the grid with Watch Next restored. Both APKs passed package, app-label, signature, native ABI and Flutter ELF architecture checks. The corrected ABF banner was extracted from both APKs and visually verified. A screenshot pulled from the TV also confirmed that the installed shortcut displays the corrected ABF launcher artwork. Three-row favourite layouts are covered by widget tests.

## Build

Use Flutter **3.41.9**, JDK **17**, Android SDK platform **36**, and build-tools **36.0.0**. Install the SDK command-line tools, accept their licences and put Flutter on PATH. Keep the dependency versions in `pubspec.lock`.

Supply your own release signing key outside this repository through these environment variables:

- `ARC_CLEAN_KEYSTORE`: absolute path to the keystore.
- `SIGNING_KEYSTORE_PASSWORD`, `SIGNING_KEY_ALIAS`, `SIGNING_KEY_PASSWORD`.

The original signing key is private. A build signed with a different key cannot update an existing installation signed by the original key. Preserve app data before changing installations.

Run `bash scripts/build-release.sh`. The script generates localisations and mocks, runs the focused checks and builds `1.0.0` / base build number `4134`, ARMv7 and ARM64, with the upstream updater disabled. Flutter assigns ABI-specific version codes: **5134 for ARMv7** and **6134 for ARM64**. To release a future update, increase the base build number.

APK outputs:

- `build/app/outputs/apk/github/release/abf-launcher-armeabi-v7a-release.apk`
- `build/app/outputs/apk/github/release/abf-launcher-arm64-v8a-release.apk`

The package ID stays `com.omeda.arc.clean` so a release signed with the original key updates Arc Clean in place, preserving its settings and favourites.

## Provenance and licence

This modification retains the upstream GPL-3.0-or-later licence and copyright notices; see [LICENSE](LICENSE). Arc Launcher derives from LTvLauncher and FLauncher. Upstream acknowledgements and historical documentation are preserved in [README.upstream.md](README.upstream.md).

This is an independent customization. The original project's Play Store links, downloader codes and releases refer to upstream Arc Launcher. Its release and Play publishing workflows are omitted from this snapshot; builds are local.
