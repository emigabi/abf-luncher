# Install ABF Launcher

## Choose your APK

Get the APK from the [latest GitHub release](https://github.com/emigabi/abf-luncher/releases/latest).

| Android app architecture | Filename ending | Device coverage |
| --- | --- | --- |
| ARMv7 / 32-bit ARM | `armeabi-v7a.apk` | Tested on the Box R 4K Plus running Android TV 14 |
| ARM64 / 64-bit ARM | `arm64-v8a.apk` | Built and checked; physical ARM64 testing is still welcome |

Choose the architecture supported by **Android**, even if your processor is advertised as 64-bit. The Box R 4K Plus used for this project runs 32-bit apps and needs the ARMv7 APK.

If you use ADB, you can check the supported app ABIs:

```bash
adb shell getprop ro.product.cpu.abilist
```

`armeabi-v7a` means 32-bit ARM support. `arm64-v8a` means 64-bit ARM support.

## Install and open

1. Download the matching APK and transfer it to your TV.
2. Open it with your TV's file manager. If Android asks, allow that file manager to install apps from this source.
3. Install **ABF Launcher** and open it from your apps list.
4. Set up your Favourites. Use the **All apps** button beside Settings and Wi-Fi to show the remaining apps; long-press an app for its menu.

For an existing ABF installation, install the new release over it to keep your settings and Favourites. With ADB, use:

```bash
adb install -r abf-launcher-1.0.0-armeabi-v7a.apk
```

Change the filename to the APK you downloaded. Official ABF release updates use the same package and signing key. A build signed with your own key cannot update one signed with the project's private key.

## Make it your Home screen

Press **Home**. If Android offers a launcher chooser, select **ABF Launcher** and choose **Always**. Some devices also expose a Home app choice under Android's default-app settings.

The available Home controls depend on your TV firmware; installing an APK alone does not guarantee a change to the default launcher. Open and test ABF before changing your Home configuration. To return to your previous launcher, select it as Home before removing ABF.

## First-run tips

- **App drawer:** select All apps to expand it; select it again or press Back to close it.
- **Watch Next:** when enabled, it returns after you close All apps. Available programmes depend on the apps supplying them.
- **Favourite size:** Settings → Interface → Appearance → Favourites icon size. Choose 50%, 67%, 75% or 100%.
- **More favourites:** rows fill automatically, with scrolling for additional favourites.
- **Updates:** check GitHub Releases for ABF updates. The inherited upstream self-updater is disabled in ABF release builds.

## Verify a download

Each release includes `SHA256SUMS`. Compare the hash for your APK with that file. On macOS:

```bash
shasum -a 256 abf-launcher-1.0.0-armeabi-v7a.apk
```

## Need help?

[Open a bug report](https://github.com/emigabi/abf-luncher/issues/new?template=bug_report.yml) with your device, Android version, ABF version, selected APK and the steps that reproduce the issue.
