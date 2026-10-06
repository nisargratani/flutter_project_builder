# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2026-10-06

Initial release.

### `create`

- Generates a feature-first Clean Architecture setup in an existing Flutter
  project: Riverpod 3, GoRouter, Dio, Hive CE, gen-l10n localization,
  Material 3 light and dark themes built from `AppColors`, error handling
  (`Failure`, `ErrorMapper`, `FailureMessageResolver`), logger, extensions,
  validators, widgets, a home page, and tests.
- Templates are presets: `basic` (core, router and home page only), `clean`
  (adds network, storage, localization and samples) and `enterprise` (clean
  plus dev/stage/prod flavors). Explicit options override the preset.
- `--org` sets the Android application ID, the iOS/macOS bundle IDs, the
  Linux application ID and the Windows company name.
- Flavors: `lib/main_<flavor>.dart`, `FlavorConfig`, and native
  configuration (`--native-flavors`, on by default). This covers Android
  product flavors with per-flavor application ID suffix and app name;
  iOS/macOS build configurations, schemes, bundle IDs and display names;
  and CocoaPods configuration mappings. `default-flavor` is set in the
  pubspec, and `lib/main.dart` follows `appFlavor`.
- Per-environment `AppConfig` (base URL, app name, network logging), exposed
  through `appConfigProvider` and used by the Dio client.
  `--dart-define=BASE_URL=...` overrides the base URL.
- `--firebase`: adds `firebase_core`, a `FirebaseInitializer` called in
  `bootstrap.dart`, and a placeholder `firebase_options.dart` that
  `flutterfire configure` replaces. The app runs normally until Firebase is
  configured.
- Sample features: Counter (`Notifier`) and Users (all layers,
  `AsyncNotifier`, loading, error, retry and empty states).
- `--dry-run` lists the files that would be created or overwritten.
- Saves the effective options to `flutter_project_builder.yaml` and refuses
  to run twice without `--force`.

### `generate`

- `feature <name>`: entity, repository contract, model, data source (mock,
  plus Dio when enabled), repository implementation, `AsyncNotifier`
  provider, page, test and route registration. `--fields` defines the
  entity fields (`String`, `int`, `double`, `num`, `bool`, `DateTime`,
  optionally nullable).
- `page`, `widget`, `provider` (`--type notifier|async`) and `model`
  (`--fields`), each with a test. `--feature` chooses the folder.
- Never overwrites files. Rejects invalid names, Dart keywords, path
  traversal, and class names that clash with Flutter. Supports `--dry-run`
  and `--no-route`.

### Other commands

- `upgrade` regenerates `lib/core` while keeping your `AppConfig` values
  (`--force`, `--dry-run`).
- `init` writes a default configuration file.
- `clean` removes generated code and keeps your own files.
- `doctor` checks `flutter`, `dart` and `git`.
- `--version` and `--verbose` global options.
