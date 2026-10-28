# Contributing to ArcLauncher

Thank you for your interest in contributing to ArcLauncher! We welcome contributions from everyone.

Please review this guide before submitting an issue or pull request.

---

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

---

## Getting Started

### Development Setup

1. **Prerequisites**:
   - [Flutter](https://docs.flutter.dev/get-started/install) (or [FVM](https://fvm.app/) using the version specified in `.fvmrc`)
   - Android Studio / Android SDK configured for Android TV development

2. **Clone the repository**:
   ```bash
   git clone https://github.com/meddouribadis/arclauncher.git
   cd arclauncher
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   # or with fvm:
   fvm flutter pub get
   ```

4. **Run analysis and tests**:
   ```bash
   flutter analyze
   flutter test
   ```

---

## Commit & PR Title Guidelines

This project strictly follows the **[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)** specification. Both commit messages and Pull Request titles are automatically checked in CI using `commitlint` and GitHub Actions.

### Format

```text
<type>(<optional scope>): <description>

[optional body]

[optional footer(s)]
```

### Allowed Types

| Type | Description |
| :--- | :--- |
| `feat` | A new feature |
| `fix` | A bug fix |
| `improvement` | An improvement to an existing feature |
| `perf` | A code change that improves performance |
| `refactor` | A code change that neither fixes a bug nor adds a feature |
| `docs` | Documentation changes only |
| `style` | Formatting, whitespace, missing semicolons, etc. (no production code logic change) |
| `test` | Adding missing tests or correcting existing tests |
| `build` | Changes that affect the build system or external dependencies |
| `ci` | Changes to CI configuration files and scripts |
| `chore` | Other changes that don't modify `src` or test files |
| `revert` | Reverts a previous commit |

### Scopes (Optional)

Scopes describe the section of the codebase affected, for example:
- `(ui)`
- `(settings)`
- `(apps)`
- `(wallpaper)`
- `(deps)`

### Examples

**Good Examples:**
- `feat(ui): add support for custom grid spacing`
- `fix(apps): resolve crash when launching uninstalled package`
- `docs: add installation instructions for Android TV 12+`
- `perf(database): optimize query performance when loading app list`
- `chore(deps): bump intl from 0.18.0 to 0.19.0`

**Bad Examples:**
- `updated styles` *(Missing type and format)*
- `Fix bug` *(Capitalized, no type format)*
- `WIP: working on settings` *(Not a valid conventional commit)*

### Breaking Changes

Indicate breaking changes by adding an exclamation mark `!` after the type/scope or by adding `BREAKING CHANGE:` in the commit footer:

```text
feat(settings)!: redesign settings schema requiring database migration
```

---

## Pull Request Process

1. **Fork the repo** and create your branch from `main`:
   ```bash
   git checkout -b feat/my-new-feature
   ```
2. **Make your changes** following the project's formatting and analysis rules (`flutter analyze`).
3. **Commit your changes** using Conventional Commits.
4. **Push to your fork** and open a Pull Request.
5. **Ensure your PR title** follows the Conventional Commits format (e.g. `feat(ui): add grid layout options`).
6. **Verify CI checks pass** before requesting review.
