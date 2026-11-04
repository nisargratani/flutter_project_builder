# flutter_project_builder

[![pub package](https://img.shields.io/pub/v/flutter_project_builder.svg)](https://pub.dev/packages/flutter_project_builder)
[![CI](https://github.com/nisargratani/flutter_project_builder/actions/workflows/ci.yml/badge.svg)](https://github.com/nisargratani/flutter_project_builder/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A command-line tool that creates a Flutter app (or upgrades an existing
one) with a feature-first Clean Architecture: Riverpod, GoRouter, Dio,
Hive CE, localization and Firebase. It configures **native flavors and app
IDs**, and keeps generating **features, pages, widgets, providers and
models** as you build.

```bash
flutter_project_builder create my_app --template=enterprise --org=com.mycompany
```

Everything it generates passes `flutter analyze` and `flutter test`.

## Requirements

- **CLI:** Dart SDK 3.4 or newer.
- **Generated project:** Flutter 3.32 or newer (Dart 3.8). This floor comes
  from `flutter_riverpod` 3; 3.32 is also the first release that writes
  localizations into `lib/l10n/`.

## Installation

```bash
dart pub global activate flutter_project_builder
```

Make sure the pub cache `bin` directory is on your `PATH`
(`~/.pub-cache/bin` on macOS/Linux, `%LOCALAPPDATA%\Pub\Cache\bin` on
Windows), or run commands as `dart pub global run flutter_project_builder ...`.

## Quick start

One command creates the Flutter project (it runs `flutter create` for you),
generates the architecture and installs dependencies:

```bash
flutter_project_builder create my_app --template=enterprise --org=com.mycompany
cd my_app
flutter test
flutter run --flavor dev
```

Already have a Flutter project? Run `create` inside it without a directory:

```bash
cd existing_app
flutter_project_builder create --dry-run    # preview what would change
flutter_project_builder create
flutter pub get
```

`create` never overwrites your own files silently. It replaces `lib/main.dart`
and `test/widget_test.dart` only while they are unchanged since
`flutter create`; if any other existing file would be overwritten, it lists
them, writes nothing and exits 1. See [Existing projects](#existing-projects).

## Templates

`--template` picks a preset; any option you pass explicitly overrides it.

| Template | Network | Storage | Localization | Samples | Flavors |
| --- | --- | --- | --- | --- | --- |
| `basic` | – | – | – | – | – |
| `clean` (default) | Dio | Hive CE | gen-l10n | Counter, Users | – |
| `enterprise` | Dio | Hive CE | gen-l10n | Counter, Users | dev, stage, prod (Dart and native) |

All templates include the core layer (theme, widgets, logger, errors,
extensions, validators), the router, a home page, the environment config and
tests.

## `create` options

`flutter_project_builder create [directory] [options]`

- **With a directory** that does not exist (or is empty): runs
  `flutter create` (passing `--org`, `--project-name`, `--platforms`),
  generates the architecture inside it and runs `flutter pub get`.
- **With a directory** that is an existing Flutter project: generates inside
  it. Any other existing directory is refused.
- **Without a directory:** generates in the current Flutter project.

| Option | Default | Description |
| --- | --- | --- |
| `--project-name` | directory name | Package name for a new project; required when the directory name isn't a valid one, e.g. `my-app`. |
| `--platforms` | all | Platforms for a new project, e.g. `--platforms=android,ios`. |
| `--[no-]pub` | on for new projects and native flavors | Run `flutter pub get` at the end. |
| `--template`, `-t` | `clean` | Preset, see above. |
| `--org`, `-o` | `com.example` | Sets the Android `applicationId`, the iOS/macOS bundle IDs and the Linux application ID to `<org>.<package>` (Windows: company name). The default leaves IDs unchanged. |
| `--[no-]flavors`, `-f` | off | `dev`, `stage`, `prod` flavors (use the config file for other names). |
| `--[no-]native-flavors` | on | With flavors, also configure Android product flavors and Xcode schemes so `flutter run --flavor <name>` works. |
| `--[no-]firebase` | off | Adds `firebase_core` and initialises Firebase on startup. |
| `--[no-]dio` | on | Dio network layer. |
| `--[no-]hive` | on | Hive CE storage layer. |
| `--[no-]localization` | on | `l10n.yaml`, `lib/l10n/app_en.arb`, delegates wired into `MaterialApp`. |
| `--[no-]sample`, `-s` | on | Counter and Users sample features with routes and tests. |
| `--dry-run` | | List files that would be created or overwritten; write nothing. |
| `--force` | | Regenerate an already generated project, and overwrite existing files that the architecture replaces (see below). |
| `--[no-]interactive`, `-i` | on | Use the wizard when no options and no config file are given. |

The effective options are saved to `flutter_project_builder.yaml`, so
`upgrade` and `generate` reuse them. `create` refuses to run twice unless you
pass `--force`. Generated Dart files are formatted with `dart format`.

### Existing projects

Before writing anything in an existing project, `create` checks which files it
would overwrite:

- `pubspec.yaml` and the native projects (`android/`, `ios/`, `macos/`,
  `linux/`, `windows/`) are edited in place; the rest of each file is kept.
- `lib/main.dart` and `test/widget_test.dart` are replaced only while they
  are unchanged since `flutter create` (compared with the templates of your
  Flutter SDK; `--empty` projects too). A `lib/main.dart` that an earlier
  `create` wrote (`clean` keeps it) is replaced as well.
- Any other existing file that would be overwritten (your own
  `lib/main.dart`, `lib/app.dart`, `lib/core/theme/app_theme.dart`,
  `lib/router/app_router.dart`, ...) stops `create`: it lists the files,
  writes nothing and exits 1. Move or rename them, or pass `--force` to
  overwrite them. Files with exactly the generated content don't count.
  A project created by another Flutter version may need `--force` for an
  untouched `lib/main.dart`, because that template changes between
  versions.

Existing dependency constraints are kept. If one excludes the version the
generated code is written for (for example `flutter_riverpod: ^2.6.1` when it
needs `^3.0.0`), `create` warns and prints the command that fixes it
(`flutter pub add "flutter_riverpod:^3.0.0"`). An existing `l10n.yaml` and
your translations are kept too, and `lib/app.dart` uses the class, file and
`appTitle` message they define.

## Generating code

Every target writes the code **and a test**, never overwrites existing files,
and supports `--dry-run`. When a source file already exists, it is kept and no
test is written for it (you get a warning instead), because the generated test
would not match your code. `generate` needs the architecture: run `create`
first.

```bash
# A complete feature: entity, repository contract, model, data source
# (mock + Dio), repository implementation, AsyncNotifier provider, page with
# loading/error/empty/retry states, test, and a route.
flutter_project_builder generate feature product --fields "id:int,title:String,price:double?,releasedAt:DateTime"

flutter_project_builder generate page settings                   # page + route
flutter_project_builder generate page edit_profile --feature profile
flutter_project_builder generate widget info_card                # lib/core/widgets
flutter_project_builder generate widget price_tag --feature product
flutter_project_builder generate provider cart                   # Notifier + state class
flutter_project_builder generate provider session --type async   # AsyncNotifier
flutter_project_builder generate model address --fields "street:String,zip:int?"
```

- **Names** are converted to snake_case for files and PascalCase for classes
  (`UserProfile` → `user_profile.dart`, `UserProfilePage`). Invalid
  identifiers, Dart keywords, paths like `../x`, and names that clash with a
  `dart:core` type or a type visible through `package:flutter/material.dart`
  (e.g. `String`, `Badge`, `EdgeInsets`) are rejected.
- **`--fields`** accepts `String`, `int`, `double`, `num`, `bool` and
  `DateTime`, each optionally nullable (`?`). The default is `id:int,name:String`.
  Quote the value: shells such as zsh treat `?` as a wildcard. Field names
  are lowerCamelCase identifiers; built-in identifiers such as `type`, `get`
  or `on` are fine, while reserved words (`class`, `new`, ...), `Object`
  members and the names the generated code uses (`int`, `double`, `num`,
  `bool`, `dynamic`, `identical`) are rejected.
- **Routes:** features and pages are added as child routes of the home route,
  with `RouteNames`/`RoutePaths` constants (`context.goNamed(RouteNames.product)`).
  This relies on the `// flutter_project_builder:` marker comments in
  `lib/router/`; if they are missing you get the snippet to paste instead.
  Pass `--no-route` to skip.
- `--feature` puts the file in that feature's folder (it defaults to the
  name; for widgets the default is `lib/core/widgets/`).

## Flavors and environments

With flavors, each flavor gets:

| | dev (example) | prod |
| --- | --- | --- |
| Entry point | `lib/main_dev.dart` | `lib/main_prod.dart` |
| Android `applicationId` | `<id>.dev` | `<id>` |
| iOS/macOS bundle ID | `<id>.dev` | `<id>` |
| App name (Android label, iOS display name)¹ | `My App Dev` | `My App` |
| `AppConfig.baseUrl` | `https://dev.api.example.com/` | `https://api.example.com/` |
| Network logs | on | off |

¹ Based on the app's current name when you customised it (`android:label`,
`CFBundleDisplayName`), e.g. `Shop Pro` and `Shop Pro Dev`; otherwise on the
package name. Each platform keeps its own name.

```bash
flutter run --flavor dev                 # native flavor + matching Dart config
flutter run                              # uses `default-flavor` (the first flavor)
flutter build apk --flavor prod
flutter build ipa --flavor prod
flutter run -t lib/main_stage.dart       # Dart-only alternative
flutter run --flavor dev --dart-define=BASE_URL=http://localhost:8080/
```

- `lib/main.dart` reads Flutter's `appFlavor`, so the Dart `FlavorConfig`
  always matches the native flavor.
- Edit URLs and names in `lib/core/config/flavor_config.dart`; the Dio client
  reads them through `appConfigProvider` (override it in tests).
- Native setup: Android `productFlavors` in `android/app/build.gradle(.kts)`,
  iOS/macOS `Debug-<flavor>`/`Profile-<flavor>`/`Release-<flavor>` build
  configurations and a `<flavor>` scheme. Flavors named `prod`/`production`
  keep the base IDs.
- iOS/macOS dependencies: with Swift Package Manager (Flutter's default) no
  Podfile is needed. If the project uses CocoaPods, `create` runs
  `flutter pub get` so Flutter creates the Podfile, then maps the flavor
  configurations in it. If Flutter creates a Podfile later (for example
  after adding a CocoaPods-only plugin), run `flutter_project_builder upgrade`
  to add the mappings.
- Without flavors you still get `AppConfig` with a single base URL.
- Use `--no-native-flavors` for Dart-only flavors.

## Firebase

`--firebase` adds `firebase_core` (`^5.1.0`), `lib/core/firebase/firebase_initializer.dart`
and a placeholder `lib/firebase_options.dart`, and calls
`FirebaseInitializer.initialize()` in `bootstrap.dart`. Because
`firebase_core` requires iOS 15 and macOS 10.15, lower deployment targets are
raised in the Xcode project and `AppFrameworkInfo.plist` (projects created
by older Flutter versions, such as 3.41 and 3.44, target iOS 13). Then
connect your project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Until you do, the app starts normally and logs
`Firebase is not configured`. The placeholder is never overwritten once
`flutterfire configure` has replaced it. Per-flavor Firebase projects are not
configured automatically.

## Other commands

| Command | Description |
| --- | --- |
| `upgrade` | Regenerates `lib/core/` with the current templates using your saved options. Features, routes, entry points, tests and your `AppConfig` values are kept. With native flavors, missing flavor configurations and Podfile mappings are added; a flavor that the Dart side doesn't have yet (`enum Flavor`, `lib/main_<flavor>.dart`) is reported with what to add. `--force` skips the prompt (required in CI), `--dry-run` previews. |
| `init` | Writes a default `flutter_project_builder.yaml`. |
| `clean` | Deletes only the files flutter_project_builder generated, as listed in `lib/.flutter_project_builder` (generated code in `lib/core`, `lib/features`, `lib/router`, the entry points and generated tests), then the folders left empty. Files you added are kept, even inside those folders, and listed. Never deletes `lib/main.dart`, translations, `firebase_options.dart`, `pubspec.yaml` or native changes. Asks first; `--force` in CI. |
| `doctor` | Checks `flutter`, `dart` and `git`; exits 1 if Flutter or Dart is missing. |

Global options: `--version` (`-v`) and `--verbose` (stack traces on errors).
Every command exits with a non-zero code on failure.

## Configuration file

```yaml
organization: com.mycompany
template: enterprise        # preset for the options not set here
flavors: [dev, qa, prod]    # any lowercase Dart identifiers
firebase: true
# hive: true                # commented out: the preset's value applies
# dio: true
# localization: true
# native_flavors: true
# sample_features: true
# riverpod: true
```

`init` and `create` write every option, but options whose value equals the
template preset are commented out. Changing `template:` later therefore
selects that preset's values; uncomment an option to pin it. See
[`example/flutter_project_builder.yaml`](example/flutter_project_builder.yaml).

Options resolve in this order: command-line options, the config file, the
wizard, then the template preset. Invalid values (unknown template, bad
organization, wrong types, invalid flavor names) produce a clear error.

## Generated structure

```text
lib/
├── app.dart                 # MyApp (MaterialApp.router, light/dark theme)
├── bootstrap.dart           # Firebase, Hive, ProviderScope, runApp
├── main.dart                # (+ main_<flavor>.dart)
├── firebase_options.dart    # with --firebase
├── core/
│   ├── config/              # AppConfig (+ FlavorConfig)
│   ├── constants/  enums/  errors/  exceptions/  extensions/  firebase/
│   ├── logger/  network/  services/  storage/  theme/  utils/  widgets/
├── features/
│   ├── home/  counter/  users/
│   └── <your features>/{data,domain,presentation}/
├── l10n/app_en.arb
└── router/                  # app_router.dart, route_names.dart
test/
├── widget_test.dart
├── core/…
└── features/…
```

## Verified platforms

Checked with the `enterprise` template and `--org`, locally (macOS host) and
in CI on GitHub-hosted runners:

| Check | Result |
| --- | --- |
| Generated code (`analyze`, `test`) on Flutter 3.32 and latest stable | ✅ CI, all templates |
| Android (`--flavor dev/prod`) | ✅ built; IDs and labels checked |
| iOS simulator (`--flavor dev`) | ✅ built and run, with Swift Package Manager and with CocoaPods |
| macOS (`--flavor dev`) | ✅ built and run, with Swift Package Manager and with CocoaPods |
| Linux, Windows, web | ✅ built in CI |
| Flutter 3.41 / 3.44 | ✅ analyze, test and Android flavor build (iOS not buildable with Xcode 27 on those versions, for any plugin app) |

## Limitations

- `generate` does not remove routes or files; delete them by hand.
- Re-running `create` with a new flavor adds its Xcode configuration, but an
  existing Android `productFlavors` block is not rewritten (you get a
  warning).
- `upgrade` with a new flavor in the config adds its native configuration but
  not its Dart side, because `flavor_config.dart` holds your settings: add the
  `Flavor` value, its `AppConfig` case and `lib/main_<flavor>.dart` yourself
  (`upgrade` lists what is missing).
- `clean` relies on the file list in `lib/.flutter_project_builder`. Projects
  generated by 0.0.1 have no list, so `clean` refuses to delete anything
  there.
- `--no-riverpod` only omits the `AsyncValue` UI helpers; the generated code
  always uses Riverpod.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
