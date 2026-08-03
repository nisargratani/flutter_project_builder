# flutter_project_builder Example

## Quick Start

```bash
# Install the package globally
dart pub global activate flutter_project_builder

# Navigate to your Flutter project
cd my_flutter_app

# Generate the architecture (interactive wizard)
flutter_project_builder create

# Or use flags directly
flutter_project_builder create --template=clean --flavors --sample --org=com.mycompany
```

## Commands

### Create Architecture

```bash
# Interactive mode (asks questions)
flutter_project_builder create

# Full enterprise setup
flutter_project_builder create \
  --template=enterprise \
  --flavors \
  --firebase \
  --sample \
  --org=com.mycompany

# Basic setup without samples
flutter_project_builder create --template=basic --no-interactive
```

### Generate a New Feature

```bash
# Scaffold a complete clean architecture feature
flutter_project_builder generate feature auth

# This creates:
# lib/features/auth/
#   ├── data/
#   │   ├── datasource/
#   │   ├── repository/
#   │   └── models/
#   ├── domain/
#   │   ├── entities/
#   │   ├── repository/
#   │   └── usecases/
#   └── presentation/
#       ├── pages/
#       ├── widgets/
#       └── providers/
```

### Check Environment

```bash
flutter_project_builder doctor
# ✔ Flutter 3.22.0
# ✔ Dart 3.4.0
# ✔ Git 2.42.0
# ✔ flutter_project_builder 0.0.1
```

### Other Commands

```bash
# Initialize configuration
flutter_project_builder init

# Clean generated files
flutter_project_builder clean

# Upgrade architecture
flutter_project_builder upgrade
```

## Configuration

Create a `flutter_project_builder.yaml` in your project root:

```yaml
organization: com.mycompany
template: clean
flavors:
  - dev
  - stage
  - prod
riverpod: true
firebase: false
hive: true
dio: true
localization: true
sample_features: true
```
