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
   dart analyze
   dart format --set-exit-if-changed .
   dart test
   ```
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

1. Create the template function in `lib/src/templates/`.
2. Add the generator logic in `lib/src/generators/`.
3. Register it in the appropriate command.
4. Add tests for the template output.
5. Update the documentation.

## Reporting Issues

Use the [GitHub Issues](https://github.com/user/flutter_project_builder/issues)
page to report bugs or request features. Please use the provided templates.

## Questions?

Feel free to open a discussion or reach out via issues.

Thank you for helping make flutter_project_builder better!
