# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability within this package, please report it
privately via
[GitHub private vulnerability reporting](https://github.com/nisargratani/flutter_project_builder/security/advisories/new).
All security vulnerabilities will be promptly addressed.

**Please do not report security vulnerabilities through public GitHub issues.**

### What to include

- Type of issue (e.g., path traversal, code injection, etc.)
- Full paths of source file(s) related to the issue
- Location of the affected source code (tag/branch/commit or URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Status Update**: Within 5 business days
- **Resolution**: Dependent on complexity

## Best Practices

This package generates source code files on disk. We take the following
precautions:

- Files are only written inside the current project: `lib/`, `test/`,
  `pubspec.yaml` (new dependencies only), `l10n.yaml`, `ARCHITECTURE.md` and
  `flutter_project_builder.yaml`.
- No network requests are made during generation.
- No secrets or credentials are ever included in generated code.
- Feature names are validated as Dart identifiers, which rejects path
  separators and prevents directory traversal.
- Destructive commands (`clean`, `upgrade`) require confirmation or `--force`.
