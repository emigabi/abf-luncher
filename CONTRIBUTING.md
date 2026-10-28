# Contributing to ABF Launcher

Device reports, reproducible bug reports, translations and focused code changes are welcome.

## Report a problem

Use the [bug report form](https://github.com/emigabi/abf-luncher/issues/new?template=bug_report.yml). Include your TV model, Android version, ABF version, APK architecture, relevant settings and the remote buttons needed to reproduce it. Describe what you expected and what happened instead.

Check existing issues first. For a proposed feature, explain the problem it solves and how it would work with a TV remote.

## Work on the code

1. Fork `emigabi/abf-luncher` and create a branch for your change.
2. Follow the [build and development guide](docs/BUILDING.md) using Flutter 3.41.9 and the checked-in dependency lockfile.
3. Keep the change focused and preserve upstream copyright and licence notices.
4. Run the focused tests and any additional checks relevant to your change.
5. For UI changes, check D-pad navigation and include a screenshot or recording. State whether you used a real TV or an emulator.
6. Open a pull request explaining the problem, resulting behaviour and validation.

We use descriptive commit and pull-request titles. Conventional Commit prefixes such as `fix:`, `feat:` and `docs:` are welcome, but this repository currently has no automated commit-title or release-publishing workflow.

## Useful checks

After generating localisations and mocks as described in the build guide:

```bash
flutter test --no-pub test/widgets/favorite_dock_test.dart test/widgets/focus_aware_app_bar_test.dart test/providers/settings_service_test.dart
```

The release script lists the focused analyzer targets. Run relevant analysis when changing other code too. A passing widget test does not replace checking TV remote focus and scrolling on a device or emulator.

## Signing and compatibility

Keep signing keys, passwords, local device backups and private account information out of commits. Release signing keys are held outside the repository. A build signed with your own key cannot update a release signed with the project's key.

Please discuss package-ID changes, data migrations and default-Home behaviour in an issue before implementing them, because they affect existing installations.

## Attribution

ABF Launcher builds on [Arc Launcher](https://github.com/meddouribadis/arclauncher), which derives from LTvLauncher and FLauncher. [CleanYourTV](https://github.com/Gathin23/cleanyourtv) helped guide the original device setup. Preserve their credits when contributing or redistributing.
