# flutter_project_builder: Complete Usage Guide

`flutter_project_builder` is a powerful CLI designed to eliminate boilerplate by generating an enterprise-ready, Clean Architecture Flutter codebase in seconds. 

This guide will walk you through everything from installation to working with the generated project.

---

## 1. Installation

You can install the CLI globally via Dart:

```bash
dart pub global activate flutter_project_builder
```

> **Note:** Make sure your system PATH includes the Dart global packages directory (`~/.pub-cache/bin` on Mac/Linux or `%LOCALAPPDATA%\Pub\Cache\bin` on Windows).

---

## 2. Generating a New Project Architecture

The CLI is designed to scaffold an architecture *inside an existing* Flutter project.

**Step 1:** Create a standard Flutter project.
```bash
flutter create my_awesome_app
cd my_awesome_app
```

**Step 2:** Run the builder.
```bash
flutter_project_builder create
```

### Interactive Mode
By default, the `create` command launches an interactive wizard that will ask you:
1. Which template you want to use (`basic`, `clean`, `enterprise`)
2. Whether to generate environment flavors (`dev`, `stage`, `prod`)
3. Whether to set up Firebase scaffolding
4. Whether to include sample features (Counter and Users API examples)

### Headless Mode (Flags)
For CI/CD or fast scaffolding, you can bypass the prompts using flags:
```bash
flutter_project_builder create --template=clean --flavors --firebase --sample --org=com.example
```

---

## 3. Adding New Features

The generated project strictly follows **Feature-First Clean Architecture**. When you need to build a new feature (e.g., an Authentication flow or a Profile page), use the CLI to scaffold the module automatically.

```bash
flutter_project_builder generate feature auth
```

This will automatically create the following directory structure inside `lib/features/auth/`:

```text
auth/
├── data/
│   ├── datasource/
│   ├── models/
│   └── repository/
├── domain/
│   ├── entities/
│   ├── repository/
│   └── usecases/
└── presentation/
    ├── pages/
    ├── providers/
    └── widgets/
```

**Why this structure?**
- **Domain:** Contains pure Dart logic (Entities and UseCases). It knows nothing about Flutter or external APIs.
- **Data:** Implements the Domain repositories. It communicates with APIs (via Dio) or Local Storage (via Hive).
- **Presentation:** Contains Flutter UI code and Riverpod State Notifiers. It only depends on the Domain layer.

---

## 4. Understanding the Core Infrastructure

When you run `flutter_project_builder create`, it also generates a `lib/core/` folder. This is the backbone of your application.

### Error Handling (`core/errors/` & `core/exceptions/`)
All errors in the app are mapped to a sealed `Failure` class. 
When a network call fails, it throws an `AppException`, which the `ErrorMapper` turns into a specific `Failure` (e.g., `NetworkFailure`). The `FailureMessageResolver` then converts this into a user-friendly String for the UI.

### Networking (`core/network/`)
The app uses `Dio`. The `api_client.dart` file exposes a `dio` provider with interceptors pre-configured for:
- Logging network requests and responses (`AppLogger`).
- Injecting Authentication tokens.

### Local Storage (`core/storage/`)
The app uses `Hive CE`. Use the `StorageService` interface to save, read, and delete local data synchronously or asynchronously.

### Routing (`router/`)
The app uses `GoRouter`. Add your new feature pages to `lib/router/app_router.dart` and define route name strings in `route_names.dart`.

---

## 5. Working with Flavors (Environments)

If you chose to generate flavors, your `lib/` directory will contain:
- `main_dev.dart`
- `main_stage.dart`
- `main_prod.dart`

**To run a specific flavor:**
```bash
flutter run -t lib/main_dev.dart
```

You can access the current environment anywhere in the app using the `FlavorConfig` class:
```dart
if (FlavorConfig.isDev) {
  // do something specific to development
}
```

---

## 6. Upgrading the Architecture

As `flutter_project_builder` evolves, new best practices and core infrastructure updates will be released. You can upgrade your existing project's core files without overwriting your custom features.

```bash
flutter_project_builder upgrade
```

> **Warning:** This command will overwrite the files inside `lib/core/`. Make sure your git working tree is clean before running this command so you can review the diffs. It will **not** touch your `lib/features/` or `lib/router/` directories.

---

## 7. Project Initialization & Configuration

If you want to share the CLI configuration with your team, use the `init` command.

```bash
flutter_project_builder init
```

This creates a `flutter_project_builder.yaml` file in your project root. When other developers run `flutter_project_builder create`, the CLI will automatically read this file instead of asking interactive questions.

```yaml
template: clean
flavors: true
routing: go_router
state_management: riverpod
network: dio
storage: hive
localization: false
```

---

## 8. CLI Maintenance

### Checking your environment
To ensure your system is ready for the builder (checks for Dart, Flutter, and Git):
```bash
flutter_project_builder doctor
```

### Removing generated code
If you want to start over and remove all generated architecture folders (core, features, router, etc.):
```bash
flutter_project_builder clean
```
*(Note: Use with caution! This deletes directories.)*
