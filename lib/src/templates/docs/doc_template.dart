// ignore_for_file: public_member_api_docs

/// Template strings for generated documentation.
class DocTemplate {
  DocTemplate._();

  /// `ARCHITECTURE.md` in the project root.
  ///
  /// Written only if the file does not exist, so it never overwrites your
  /// own documentation.
  static const String architecture = r'''
# Architecture

This project was scaffolded by
[flutter_project_builder](https://pub.dev/packages/flutter_project_builder).

## Layers

Code is grouped by feature (`lib/features/<feature>/`), and each feature is
split into three layers:

- **domain/** – entities and repository interfaces. Pure Dart; no Flutter,
  no packages from the data layer.
- **data/** – models (JSON), data sources (API, cache) and repository
  implementations. Errors are converted to `Failure`s with `ErrorMapper`.
- **presentation/** – pages, widgets and Riverpod providers/notifiers.

Shared infrastructure lives in `lib/core/` (theme, widgets, network, storage,
logger, errors, utils) and routing in `lib/router/`.

## Startup

`lib/main.dart` (and `lib/main_<flavor>.dart` when flavors are enabled) call
`bootstrap()` in `lib/bootstrap.dart`, which initialises services and runs
`MyApp` (`lib/app.dart`) inside a `ProviderScope`.

## Adding a feature

```bash
flutter_project_builder generate feature profile
```

Then add a route in `lib/router/app_router.dart` and its name/path in
`lib/router/route_names.dart`.

## Errors

Repositories throw `Failure` subclasses (`NetworkFailure`, `CacheFailure`,
`ValidationFailure`, `UnknownFailure`). `FailureMessageResolver` turns them
into user-facing messages.

## Commands

```bash
flutter pub get   # also generates lib/l10n/app_localizations.dart
flutter analyze
flutter test
flutter run       # or: flutter run -t lib/main_<flavor>.dart
```
''';
}
