# flutter_project_builder example

`flutter_project_builder` is a command-line tool, so the example is a terminal
session. Every step below is run in CI against a fresh `flutter create`
project.

```bash
# 1. Install the CLI
dart pub global activate flutter_project_builder

# 2. Create a Flutter app and generate the architecture
flutter create my_app
cd my_app
flutter_project_builder create --no-interactive --flavors

# 3. Install dependencies, then verify the generated code
flutter pub get
flutter analyze
flutter test

# 4. Run a flavor
flutter run -t lib/main_dev.dart

# 5. Add a feature
flutter_project_builder generate feature user_profile
```

## Variations

```bash
# Interactive wizard
flutter_project_builder create

# Lightweight setup: no samples, network, storage or localization
flutter_project_builder create --no-sample --no-dio --no-hive --no-localization

# Use a shared configuration file
flutter_project_builder init
flutter_project_builder create

# Refresh lib/core after upgrading the CLI
flutter_project_builder upgrade --force
```

## Configuration

[`flutter_project_builder.yaml`](flutter_project_builder.yaml) in this
folder is a complete configuration example. Copy it to your project root to
use it.
