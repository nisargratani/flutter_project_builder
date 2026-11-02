# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-11-02

This release changes how `create`, `generate`, `clean` and the configuration
file behave (see below), so scripts and CI jobs may need updating.

### Changed (behaviour)

- `create` in an existing project no longer overwrites your files silently.
  If it would overwrite any existing file other than `pubspec.yaml`, the
  native projects (edited in place), `lib/main.dart` and an unmodified
  `flutter create` `test/widget_test.dart`, it lists those files, writes
  nothing and exits 1. `--force` overwrites them.
- `generate` requires a project set up with `create` and exits 1 otherwise,
  with a message to run `create` first.
- `clean` deletes only the files flutter_project_builder generated. They are
  listed in `lib/.flutter_project_builder`, which `create`, `upgrade` and
  `generate` now keep up to date. Files you added are kept (and listed),
  even inside `lib/core`, `lib/features` or `lib/router`. `clean` exits 1
  without deleting anything when the project has no marker, or a marker
  written by 0.0.1 (which has no file list).
- `init` and the saved options comment out the values that equal the
  template preset, so changing `template:` later takes effect.

### Fixed

- `create` warns when an existing dependency constraint excludes the
  version the generated code is written for (for example
  `flutter_riverpod: ^2.6.1`), and prints the `flutter pub add` command that
  fixes it. `upgrade` prints these warnings too.
- Native flavors build on a customised app name (`android:label`,
  `CFBundleDisplayName`) instead of replacing it with one derived from the
  package name.
- `lib/app.dart` follows an existing `l10n.yaml` (output file and class,
  nullable getter, `appTitle` message), so it compiles with the setup from
  the Flutter documentation.
- `generate` no longer writes a test for a source file that already existed
  and was kept; it warns instead.
- `upgrade` warns about configured flavors that the Dart side does not have
  yet (`enum Flavor`, `lib/main_<flavor>.dart`), instead of letting them run
  silently with the first flavor's settings.
- A model or entity field named `other` no longer breaks `==`.
- Built-in identifiers such as `type`, `get`, `set`, `on` or `show` are
  accepted as field names. Field names that would hide a type or function
  the generated code uses (`int`, `double`, `num`, `bool`, `dynamic`,
  `identical`) are rejected instead of producing code that does not compile.
- Names that clash with `dart:core` types or with any type visible through
  `package:flutter/material.dart` (for example `String`, `EdgeInsets`,
  `VoidCallback`, or `FormState` for `generate provider form`) are rejected.
- `clean` and `upgrade` without `--force` exit 1 when no answer can be read
  (stdin at end of file, e.g. `< /dev/null`) instead of reporting success.
- Generated Dart files are formatted with `dart format` after `create`,
  `upgrade` and `generate`.
- `--firebase` adds `firebase_core: ^5.1.0`, so current FlutterFire plugins
  can be added.
- `--version` prints the bare version number.

## [0.0.1] - 2026-11-02

Initial release.

### `create`

- `create <directory>` runs `flutter create` (with `--org`,
  `--project-name` and `--platforms`), generates the architecture and runs
  `flutter pub get`, all in one command. Without a directory it generates
  in the current Flutter project.
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
  and, for projects that use CocoaPods, flavor mappings in the Podfile
  Flutter creates. No Podfile is created, so Swift Package Manager projects
  build as-is. `default-flavor` is set in the
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

- `upgrade` regenerates `lib/core` while keeping your `AppConfig` values,
  and adds missing native flavor configurations and Podfile mappings
  (`--force`, `--dry-run`).
- `init` writes a default configuration file.
- `clean` removes generated code and keeps your own files.
- `doctor` checks `flutter`, `dart` and `git`.
- `--version` and `--verbose` global options.
