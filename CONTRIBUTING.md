# Contributing to flutter_project_builder

Thank you for your interest in contributing! This document provides guidelines
and information for contributors.

## Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

## Getting Started

1. Fork the repository.
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/flutter_project_builder.git
   ```
3. Install dependencies:
   ```bash
   dart pub get
   ```
4. Run tests to ensure everything works:
   ```bash
   dart test
   ```

## Development Workflow

### Branch Naming

- `feature/description` — New features
- `fix/description` — Bug fixes
- `docs/description` — Documentation updates
- `refactor/description` — Code refactoring
- `test/description` — Test additions or updates

### Making Changes

1. Create a new branch from `main`.
2. Make your changes following the code style guidelines below.
3. Write or update tests as needed.
4. Run the full test suite and analysis:
   ```bash
   dart analyze --fatal-infos
   dart format --output=none --set-exit-if-changed .
   dart test
   ```
   If you changed a template, also verify a real generated project (see
   "Verifying templates" below).
5. Commit your changes with a descriptive commit message.
6. Push your branch and create a Pull Request.

### Code Style

- Follow the rules in `analysis_options.yaml`.
- All public APIs must have documentation comments.
- Keep classes under 300 lines when possible.
- Prefer composition over inheritance.
- Use `final` and `const` wherever possible.
- No `print()` statements — use the package logger.

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new feature generator
fix: correct path resolution on Windows
docs: update README with new examples
test: add unit tests for create command
refactor: extract template helpers
chore: update dependencies
```

### Testing

- Every new feature should include tests.
- Run tests with: `dart test`
- Check coverage with: `dart test --coverage`

## Adding New Templates

When adding new generated file templates:

1. Create the template in `lib/src/templates/`. Use raw strings (`r'''...'''`)
   for static templates so backslashes (e.g. in regular expressions) and `$`
   are emitted exactly as written. Templates are excluded from analysis, so
   only a generated project can catch mistakes in them.
2. Add the generator logic in `lib/src/generators/`.
3. Register it in `ProjectGenerator` (or the appropriate command).
4. Add tests for the template output in `test/project_generator_test.dart`.
5. Update the documentation.

### Verifying templates

`dart test` checks what is written, not whether it compiles. Before opening a
PR that touches templates, generate a real project:

```bash
dart pub global activate --source path .
flutter create /tmp/fpb_app && cd /tmp/fpb_app
flutter_project_builder create --no-interactive
flutter pub get && flutter analyze && flutter test
```

CI runs this for several option combinations.

## Reporting Issues

Use the [GitHub Issues](https://github.com/nisargratani/flutter_project_builder/issues)
page to report bugs or request features. Please use the provided templates.

## Questions?

Feel free to open a discussion or reach out via issues.

Thank you for helping make flutter_project_builder better!
