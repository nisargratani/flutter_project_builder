# flutter_project_builder: Usage Guide

A walkthrough from installation to working in the generated project. See the
[README](README.md) for the full option reference.

## 1. Install

```bash
dart pub global activate flutter_project_builder
```

The pub cache `bin` directory must be on your `PATH` (`~/.pub-cache/bin` on
macOS/Linux, `%LOCALAPPDATA%\Pub\Cache\bin` on Windows).

## 2. Generate the architecture

The CLI works **inside an existing** Flutter project (Flutter 3.32+):

```bash
flutter create my_awesome_app
cd my_awesome_app
flutter_project_builder create
```

In a terminal, the wizard asks for the template, organization, flavors,
network, storage, localization, the Firebase folder and sample features. To
skip it (for example in CI), pass options:

```bash
flutter_project_builder create --no-interactive
flutter_project_builder create --flavors --firebase --no-sample
```

Then install dependencies (this also generates `lib/l10n/app_localizations.dart`)
and run the generated tests:

```bash
flutter pub get
flutter test
flutter run
```

The options you chose are saved to `flutter_project_builder.yaml`. Commit it,
so teammates and `upgrade` use the same settings.

## 3. Share a configuration with your team

```bash
flutter_project_builder init      # writes flutter_project_builder.yaml
# edit it, commit it; then on any machine:
flutter_project_builder create    # uses the file, no wizard
```

Command-line options override values from the file.

## 4. Add features

```bash
flutter_project_builder generate feature auth
```

```text
lib/features/auth/
├── data/          datasource/  models/  repository/
├── domain/        entities/  repository/  usecases/
└── presentation/  pages/  providers/  widgets/
```

- **Domain:** pure Dart entities and repository interfaces.
- **Data:** models, data sources and repository implementations. Errors are
  converted to `Failure`s with `ErrorMapper`.
- **Presentation:** pages, widgets and Riverpod providers.

Register pages in `lib/router/app_router.dart` and add their names and paths
to `lib/router/route_names.dart`. The Users sample
(`lib/features/users/`) shows every layer wired together.

## 5. Core infrastructure

- **Startup:** `main.dart` → `bootstrap()` (initialises Hive and overrides
  `storageServiceProvider`) → `MyApp` in `app.dart`.
- **Errors:** repositories throw `Failure` subclasses (`NetworkFailure`,
  `CacheFailure`, `ValidationFailure`, `UnknownFailure`).
  `FailureMessageResolver` turns them into UI messages.
- **Networking:** `apiClientProvider` (Dio) with auth and logging interceptors.
  Set your `baseUrl` in `lib/core/network/api_client.dart`.
- **Storage:** `storageServiceProvider` (`HiveStorageService`).
- **Localization:** add strings to `lib/l10n/app_en.arb` and add more
  `app_<locale>.arb` files. `flutter pub get` regenerates the code.

## 6. Flavors

With flavors enabled you get `lib/main_<flavor>.dart` for each flavor:

```bash
flutter run -t lib/main_dev.dart
```

```dart
import 'core/config/flavor_config.dart';

if (FlavorConfig.isDev) {
  // development-only behaviour
}
```

`lib/main.dart` uses the first flavor. Native Android product flavors and iOS
schemes are not generated; set them up yourself if you need
`flutter run --flavor`.

## 7. Upgrade generated core files

```bash
git status                       # start from a clean tree
flutter_project_builder upgrade  # or: upgrade --force in CI
git diff                         # review
```

Only `lib/core/` is regenerated. Your features, routes, entry points and
tests are left alone.

## 8. Maintenance

```bash
flutter_project_builder doctor   # checks flutter, dart and git
flutter_project_builder clean    # removes generated code (asks first)
```

`clean` keeps `lib/main.dart`, your own tests, `pubspec.yaml` and your
translations. Run `create` again to regenerate.
