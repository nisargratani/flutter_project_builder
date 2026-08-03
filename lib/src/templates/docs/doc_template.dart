// ignore_for_file: public_member_api_docs, use_raw_strings, unnecessary_string_escapes

/// Template strings for docs.
class DocTemplate {
  DocTemplate._();

  static const String readme = '''
# App Name

This project was generated using `flutter_project_builder`.

## Architecture

This project follows Clean Architecture principles:

- **Presentation Layer**: UI, State Management (Riverpod).
- **Domain Layer**: Entities, Use Cases, Repositories (Interfaces).
- **Data Layer**: Models, Data Sources, Repositories (Implementations).

## Getting Started

1.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

2.  **Run code generation (if applicable):**
    ```bash
    dart run build_runner build -d
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```
''';
}
