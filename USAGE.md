# flutter_project_builder: Usage Guide

A walkthrough from installation to day-to-day work in the generated project.
See the [README](README.md) for the full option reference.

## 1. Install

```bash
dart pub global activate flutter_project_builder
```

The pub cache `bin` directory must be on your `PATH` (`~/.pub-cache/bin` on
macOS/Linux, `%LOCALAPPDATA%\Pub\Cache\bin` on Windows).

## 2. Create an app

One command runs `flutter create`, generates the architecture and installs
dependencies (Flutter 3.32+ must be on your `PATH`):

```bash
flutter_project_builder create my_app --template=enterprise --org=com.mycompany
cd my_app
flutter test
flutter run --flavor dev
```

Useful options for new projects: `--project-name shop` (when the folder name
is not a valid package name), `--platforms=android,ios`, `--no-pub`. Add
`--dry-run` to see the `flutter create` command that would run.

For an **existing** Flutter project, run `create` inside it without a
directory. Preview first: it replaces `lib/main.dart`, and
`test/widget_test.dart` while that is still the counter test from
`flutter create`.

```bash
cd existing_app
flutter_project_builder create --dry-run --template=enterprise --org=com.mycompany
flutter_project_builder create --template=enterprise --org=com.mycompany
flutter pub get
```

If `create` would overwrite any other file you already have (say your own
`lib/app.dart` or `lib/router/app_router.dart`), it lists those files, writes
nothing and exits 1. Move or rename them, or re-run with `--force` to
overwrite them. If your `pubspec.yaml` pins a dependency to a version the
generated code can't use (for example `flutter_riverpod: ^2.6.1`), `create`
keeps it but warns and prints the `flutter pub add` command that fixes it.

Pick a template:

- `basic`: core layer, theme, router and home page. A starting point for
  small apps.
- `clean` (default): adds Dio, Hive CE, localization and the Counter/Users
  samples.
- `enterprise`: `clean` plus dev/stage/prod flavors, configured natively for
  Android and iOS/macOS.

Any option overrides the template, e.g. `--template=enterprise --no-hive`.
Without options in a terminal, a short wizard asks instead.

The options are saved to `flutter_project_builder.yaml`. Options equal to the
template preset are commented out, so changing `template:` later takes
effect; uncomment an option to pin it. Commit the file so your team and
`upgrade` use the same settings.

## 3. Run flavors

```bash
flutter run --flavor dev         # Android/iOS/macOS flavor + Dart config
flutter run                      # default-flavor (the first one)
flutter build apk --flavor prod
```

- `dev` installs next to `prod` (app ID suffix `.dev`, name "My App Dev").
- Set each flavor's API URL and app name in
  `lib/core/config/flavor_config.dart`.
- Override the URL for one build with
  `--dart-define=BASE_URL=https://staging.example.com/`.
- In code, use `ref.watch(appConfigProvider)` or `FlavorConfig.isDev`.

Custom flavor names go in the config file (`flavors: [dev, qa, prod]`) before
running `create`. Flavors named `prod` or `production` keep the base app ID.
If you customised the app name (`android:label`, `CFBundleDisplayName`),
flavors build on it: `Shop Pro` and `Shop Pro Dev`.

Adding a flavor later: add it to the config and run `upgrade`. It adds the
native configuration and tells you what to add on the Dart side (the `Flavor`
value, its `AppConfig` case in `flavor_config.dart`, and
`lib/main_<flavor>.dart`); until then that flavor runs with the first
flavor's settings.

## 4. Add code

```bash
flutter_project_builder generate feature product --fields "id:int,title:String,price:double?"
```

This creates a working, tested feature:

```text
lib/features/product/
├── data/
│   ├── datasource/product_remote_data_source.dart   # Mock + Dio
│   ├── models/product_model.dart                    # fromJson / toJson
│   └── repository/product_repository_impl.dart      # errors → Failure
├── domain/
│   ├── entities/product_entity.dart
│   └── repository/product_repository.dart
└── presentation/
    ├── pages/product_page.dart                      # loading/error/empty/retry
    └── providers/product_provider.dart              # AsyncNotifier
test/features/product/product_notifier_test.dart
```

It also registers a route: `context.goNamed(RouteNames.product)`. The feature
uses mock data until you switch `productRemoteDataSourceProvider` to the Dio
data source (see the comment in the provider file).

Smaller building blocks:

```bash
flutter_project_builder generate page settings
flutter_project_builder generate widget info_card
flutter_project_builder generate provider cart --type async
flutter_project_builder generate model address --fields "street:String,zip:int?" --feature profile
```

Add `--dry-run` to preview. Existing files are never overwritten, and no test
is written for a file that already existed (you get a warning instead).
`generate` only works in a project set up with `create`. The new files are
formatted with `dart format`. Quote `--fields`, because zsh treats `?` as a
wildcard.

## 5. Firebase

```bash
flutter_project_builder create --firebase
dart pub global activate flutterfire_cli
flutterfire configure            # replaces lib/firebase_options.dart
```

Until then, the app starts normally and logs that Firebase is not configured.

## 6. Upgrade generated core files

```bash
git status                                 # start from a clean tree
flutter_project_builder upgrade --dry-run  # see what changes
flutter_project_builder upgrade            # or --force in CI
git diff
```

Only `lib/core/` is regenerated, and your `AppConfig`/`FlavorConfig` values
are kept. `upgrade` also reports dependency constraints the generated code
can't use, and flavors in the config that the Dart side doesn't have yet.

## 7. Maintenance

```bash
flutter_project_builder doctor   # checks flutter, dart and git
flutter_project_builder clean    # removes generated code (asks first)
```

`clean` deletes only the files flutter_project_builder generated: they are
listed in `lib/.flutter_project_builder`, which `create`, `upgrade` and
`generate` keep up to date. Files you added are kept, even inside
`lib/core/` or `lib/features/`, and `clean` lists them. It never deletes
`lib/main.dart`, translations, `firebase_options.dart`, `pubspec.yaml` or
native changes; revert native changes with git if you need to. Projects
generated by version 0.0.1 have no file list, so `clean` deletes nothing
there.
