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
`bootstrap()` in `lib/bootstrap.dart`, which initialises services (Firebase,
Hive) and runs `MyApp` (`lib/app.dart`) inside a `ProviderScope`.

## Environments and flavors

`lib/core/config/app_config.dart` holds per-environment settings (API base
URL, app name, network logging), read through `appConfigProvider`; the Dio
client uses it. With flavors, edit the values per flavor in
`lib/core/config/flavor_config.dart`.

```bash
flutter run --flavor dev          # native flavor + matching Dart config
flutter run -t lib/main_prod.dart # Dart-only alternative
flutter build apk --flavor prod --dart-define=BASE_URL=https://staging.example.com/
```

`--dart-define=BASE_URL=...` overrides the base URL at build time.

## Adding code

```bash
flutter_project_builder generate feature profile --fields "id:int,name:String"
flutter_project_builder generate page settings
flutter_project_builder generate widget info_card
flutter_project_builder generate provider cart --type async
flutter_project_builder generate model address --fields "street:String,zip:int?"
```

Features and pages are registered in `lib/router/app_router.dart` (keep the
`// flutter_project_builder:` marker comments there and in
`route_names.dart`). Navigate with `context.goNamed(RouteNames.profile)`.

## Errors

Repositories throw `Failure` subclasses (`NetworkFailure`, `CacheFailure`,
`ValidationFailure`, `UnknownFailure`). `FailureMessageResolver` turns them
into user-facing messages.

## Commands

```bash
flutter pub get   # also generates lib/l10n/app_localizations.dart
flutterfire configure  # only if Firebase is enabled
flutter analyze
flutter test
flutter run       # with flavors: flutter run --flavor <name>
```
''';
}
