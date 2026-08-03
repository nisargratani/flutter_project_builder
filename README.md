# flutter_project_builder

[![pub package](https://img.shields.io/pub/v/flutter_project_builder.svg)](https://pub.dev/packages/flutter_project_builder)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Generate enterprise-grade Flutter project architectures in seconds. `flutter_project_builder` scaffolds a complete, production-ready codebase based on Clean Architecture, Riverpod, GoRouter, Dio, and Hive CE.

This is not a demo package. The generated architecture is modular, extensible, and designed for medium-to-large Flutter applications.

## Features

- **Interactive CLI Wizard**: Easily configure your architecture with prompts.
- **Clean Architecture**: Domain, Data, and Presentation layers clearly separated.
- **State Management**: Pre-configured with Riverpod (`AsyncNotifier` and `Notifier`).
- **Routing**: Type-safe navigation using GoRouter.
- **Networking**: Configured Dio client with interceptors (Auth, Logging, Retry).
- **Local Storage**: Fast NoSQL database using Hive CE.
- **Theming**: Material 3 light/dark mode setup.
- **Localization**: Ready-to-use ARB setup.
- **UI Kit**: 17+ reusable widgets (buttons, fields, loaders, etc.).
- **Flavors**: Development, Staging, and Production environment configs.
- **Sample Features**: Includes fully working Counter and Users API features to learn the architecture.

## Installation

Activate the CLI globally:

```bash
dart pub global activate flutter_project_builder
```

## Quick Start

1. Create a new Flutter project:
```bash
flutter create my_app
cd my_app
```

2. Generate the architecture:
```bash
flutter_project_builder create
```

3. Follow the interactive prompts, or use flags directly:
```bash
flutter_project_builder create --template=clean --flavors --sample --org=com.mycompany
```

## Commands

### `create`
Scaffolds the architecture in the current directory.
- `--template`: Choose `basic`, `clean`, or `enterprise` (default: `clean`).
- `--flavors`: Generate `dev`, `stage`, and `prod` configurations.
- `--firebase`: Scaffold Firebase initialization folders.
- `--sample`: Include sample features (Counter/Users).

### `generate feature <name>`
Scaffolds a new Clean Architecture feature module.
```bash
flutter_project_builder generate feature auth
```

### `doctor`
Checks your environment for required tools (Flutter, Dart, Git).

### `clean`
Removes generated architecture files (useful for starting over).

## Generated Folder Structure

```text
lib/
├── core/
│   ├── constants/
│   ├── enums/
│   ├── errors/
│   ├── exceptions/
│   ├── extensions/
│   ├── logger/
│   ├── network/
│   ├── storage/
│   ├── theme/
│   ├── utils/
│   ├── widgets/
│   └── services/
├── features/
│   ├── counter/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── users/
├── router/
├── localization/
├── main.dart
```

## Why this architecture?

The generated code follows strict principles:
- **SOLID**: Interfaces and dependency inversion are used heavily.
- **Feature-First**: Code is grouped by feature rather than layer (e.g. `features/auth/` rather than `screens/`).
- **Minimal Dependencies**: We use only battle-tested, standard packages.
- **No Magic**: We avoid excessive code generation where plain Dart works better.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to add new templates or features to the CLI.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
