# flutter_project_builder example

`flutter_project_builder` is a command-line tool, so the example is a terminal
session. Each step is run in CI against a fresh `flutter create` project.

```bash
# 1. Install the CLI
dart pub global activate flutter_project_builder

# 2. Create an app and generate an enterprise setup
flutter create my_app
cd my_app
flutter_project_builder create --template=enterprise --org=com.mycompany --dry-run
flutter_project_builder create --template=enterprise --org=com.mycompany

# 3. Install dependencies and verify the generated code
flutter pub get
flutter analyze
flutter test

# 4. Run a flavor (separate app ID and name per flavor)
flutter run --flavor dev

# 5. Keep building
flutter_project_builder generate feature product --fields "id:int,title:String,price:double?"
flutter_project_builder generate page settings
flutter_project_builder generate widget info_card
flutter_project_builder generate provider cart --type async
flutter_project_builder generate model address --fields "street:String,zip:int?"
```

## Variations

```bash
flutter_project_builder create                          # interactive wizard
flutter_project_builder create --template=basic         # minimal setup
flutter_project_builder create --flavors --no-native-flavors  # Dart-only flavors
flutter_project_builder create --firebase               # then: flutterfire configure
flutter_project_builder upgrade --dry-run               # preview a core refresh
```

## Configuration

[`flutter_project_builder.yaml`](flutter_project_builder.yaml) in this
folder is a complete configuration example. Copy it to your project root
before running `create`.
