# Changelog

## 1.0.0 — 2026-10-28

### Home screen

- Keep Favourites directly below the status bar.
- Add an All apps tab beside Settings and Wi-Fi to show and hide non-favourite apps.
- Keep Favourites fixed while the lower app grid scrolls, with no fixed app or row limit.
- Hide Watch Next while All apps is expanded; restore it when closing the drawer or pressing Back, if enabled.
- Show source app names at the top of Watch Next tiles.

### Customization and identity

- Offer 50%, 67%, 75% and 100% favourite icon sizes; default to 67%.
- Wrap favourites automatically, with scrolling for additional rows.
- Keep wallpaper rotation while hiding the wallpaper source line.
- Add the exact `E MMMd, y` Date format preset.
- Use ABF Launcher in the app label, banner and About screen.

### Release and verification

- Provide ARMv7 and ARM64 APKs, a source ZIP and SHA-256 checksums.
- Keep the package and release key compatible with existing ABF installations.
- Use Android version codes 5134 (ARMv7) and 6134 (ARM64), base build 4134.
- Pass 46 focused tests, including remote traversal of an 80-app grid.
- Verify the ARMv7 build on a Box R 4K Plus running Android TV 14 using TV screenshots. Physical ARM64 testing remains open.

## Upstream history

The previous inherited changelog is preserved in [docs/CHANGELOG.upstream.md](docs/CHANGELOG.upstream.md). See [README.upstream.md](README.upstream.md) for the original project's documentation and credits.
