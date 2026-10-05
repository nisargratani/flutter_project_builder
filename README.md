# flutter_project_builder

[![pub package](https://img.shields.io/pub/v/flutter_project_builder.svg)](https://pub.dev/packages/flutter_project_builder)
[![CI](https://github.com/nisargratani/flutter_project_builder/actions/workflows/ci.yml/badge.svg)](https://github.com/nisargratani/flutter_project_builder/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A command-line tool that scaffolds a feature-first Clean Architecture setup
into an **existing** Flutter project: Riverpod, GoRouter, Dio, Hive CE,
`gen-l10n` localization, flavors, two working sample features and tests.

The generated project passes `flutter analyze` and `flutter test` immediately
after `flutter pub get`.

## What gets generated

| Area | Generated code |
| --- | --- |
| Entry points | `lib/main.dart`, `lib/app.dart` (`MyApp`), `lib/bootstrap.dart` (initialises services), optional `lib/main_<flavor>.dart` |
| State management | Riverpod 3 (`Notifier`, `AsyncNotifier`, `Provider`) |
| Routing | GoRouter provider with named routes and a navigation logger |
| Networking (`dio`) | Dio client provider, auth and logging interceptors, `DioException` → `NetworkFailure` mapping |
| Storage (`hive`) | `StorageService` interface + Hive CE implementation, initialised in `bootstrap.dart` |
| Localization (`localization`) | `l10n.yaml`, `lib/l10n/app_en.arb`, delegates wired into `MaterialApp` |
| Errors | `Failure` hierarchy, `AppException`, `ErrorMapper`, `FailureMessageResolver` |
| Core | Theme (Material 3 light/dark), constants, logger, extensions, validators, debouncer, connectivity service, widgets (`AppButton`, `Gap`, `EmptyWidget`) |
| Samples (`sample`) | **Counter** (synchronous `Notifier`) and **Users** (entity → model → data source → repository → `AsyncNotifier` → page with loading, error, retry and empty states) |
| Tests | App smoke test, widget test, validator tests, and sample-feature tests |
| Docs | `ARCHITECTURE.md` (only if it does not exist) |

## Requirements

- **CLI:** Dart SDK 3.4 or newer.
- **Generated project:** Flutter 3.32 / Dart 3.8 or newer. This floor comes
  from `flutter_riverpod` 3, and 3.32 is also the first release that writes
  localizations into `lib/l10n/`.

## Installation

```bash
dart pub global activate flutter_project_builder
```

Make sure the pub cache `bin` directory is on your `PATH`
(`~/.pub-cache/bin` on macOS/Linux, `%LOCALAPPDATA%\Pub\Cache\bin` on
Windows). Alternatively, run it with
`dart pub global run flutter_project_builder <command>`.

## Quick start

```bash
flutter create my_app
cd my_app
flutter_project_builder create
flutter pub get
flutter test
flutter run
```

In a terminal, `create` starts a short wizard. Passing any option skips the
wizard:

```bash
flutter_project_builder create --flavors --no-hive --org=com.mycompany
```

`create` never runs twice by accident. If the project was already generated,
it stops and suggests `upgrade`, or `--force` to regenerate (which overwrites
generated files, including `lib/main.dart` and `lib/router/`).

## Commands

### `create`

Generates the architecture in the current Flutter project and adds the
required dependencies to `pubspec.yaml`. Existing dependency constraints are
never changed.

| Option | Default | Description |
| --- | --- | --- |
| `--[no-]sample`, `-s` | on | Counter and Users sample features (plus their routes and tests). |
| `--[no-]dio` | on | Dio network layer. |
| `--[no-]hive` | on | Hive CE storage layer. |
| `--[no-]localization` | on | `gen-l10n` setup. |
| `--[no-]flavors`, `-f` | off | `lib/main_dev.dart`, `main_stage.dart`, `main_prod.dart` and `FlavorConfig`. |
| `--[no-]firebase` | off | Creates the `lib/core/firebase/` folder. Does not add Firebase packages. |
| `--template`, `-t` | `clean` | `basic`, `clean` or `enterprise`. Recorded in the config; in this release all three generate the same layout. |
| `--org`, `-o` | `com.example` | Recorded in the config. Does not change bundle identifiers (use `flutter create --org` for that). |
| `--[no-]interactive`, `-i` | on | Use the wizard when no options and no config file are given. |
| `--force` | | Regenerate an already generated project. |

After a successful run without a config file, the effective options are saved
to `flutter_project_builder.yaml`, so `upgrade` regenerates exactly the same
layers.

### `generate feature <name>`

```bash
flutter_project_builder generate feature UserProfile
```

Creates `lib/features/user_profile/` with empty `data/` (datasource, models,
repository), `domain/` (entities, repository, usecases) and `presentation/`
(pages, providers, widgets) folders. Names are converted to snake_case.
Invalid identifiers, Dart reserved words and paths such as `../x` are
rejected. Running it again only adds missing folders.

### `upgrade`

Regenerates `lib/core/` with the current templates, using
`flutter_project_builder.yaml`. Features, routes, entry points and tests are
not touched. Commit first so you can review the diff. Pass `--force` (`-f`)
to skip the prompt, which is required in non-interactive shells such as CI.

### `init`

Writes a default `flutter_project_builder.yaml` you can edit and share with
your team.

### `clean`

Deletes generated code: `lib/core`, `lib/features`, `lib/router`,
`lib/app.dart`, `lib/bootstrap.dart`, `lib/main_<flavor>.dart` and tests
starting with `// Generated by flutter_project_builder.`. Your own tests,
`lib/main.dart`, `pubspec.yaml`, `l10n.yaml` and `lib/l10n/` are kept. It asks
for confirmation, refuses to run on a project without the generation marker,
and requires `--force` in non-interactive shells.

### `doctor`

Prints the versions of `flutter`, `dart` and `git`. Exits with code 1 if
`flutter` or `dart` is missing.

### Global options

`--version` (`-v`) prints the version, and `--verbose` prints stack traces
for errors. Every command exits with a non-zero code on failure.

## Configuration file

`flutter_project_builder.yaml` in the project root:

```yaml
organization: com.mycompany
template: clean
flavors: [dev, qa, prod]   # any lowercase Dart identifiers
riverpod: true
firebase: false
hive: true
dio: true
localization: true
sample_features: true
```

Options are resolved in this order: command-line options, then the config
file, then the wizard, then defaults. Invalid files (unknown template, wrong
value types, invalid flavor names) are reported with a clear message.

## Generated structure

```text
lib/
├── app.dart                 # MyApp (MaterialApp.router)
├── bootstrap.dart           # service initialisation + runApp
├── main.dart                # (+ main_<flavor>.dart with flavors)
├── core/
│   ├── config/              # FlavorConfig (with flavors)
│   ├── constants/  enums/  errors/  exceptions/  extensions/
│   ├── logger/  network/  services/  storage/  theme/  utils/  widgets/
├── features/
│   ├── home/presentation/pages/home_page.dart
│   ├── counter/             # sample
│   └── users/               # sample
├── l10n/app_en.arb
└── router/                  # app_router.dart, route_names.dart
test/
├── widget_test.dart
├── core/…
└── features/…
```

Read the generated `ARCHITECTURE.md` for how the layers fit together.

## Using the generated project

- **Flavors:** `flutter run -t lib/main_dev.dart`. The tool does not configure
  native Android product flavors or iOS schemes, so don't pass `--flavor`
  unless you set those up yourself.
- **Real API for the Users sample:** override `userRemoteDataSourceProvider`
  with `DioUserRemoteDataSource(ref.watch(apiClientProvider))` and set
  `baseUrl` in `lib/core/network/api_client.dart`.
- **Storage:** read `storageServiceProvider`. It is initialised in
  `bootstrap.dart`, and reading it in a test without an override throws a
  descriptive error.

## Limitations

- `--template` and `--org` are recorded only (see the options table above).
- `--no-riverpod` only omits the `AsyncValue` UI helpers. The generated code
  always uses Riverpod.
- `generate feature` creates folders only, not starter classes or routes.
- The generated project has been verified on Flutter 3.47 (macOS, web and
  Android builds). Older Flutter versions within the supported range have not
  been tested directly.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
