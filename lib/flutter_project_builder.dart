/// flutter_project_builder — Generate enterprise-grade Flutter project
/// architectures in seconds.
///
/// This package provides a CLI tool that scaffolds complete Flutter application
/// architectures following Clean Architecture principles with Riverpod,
/// GoRouter, Dio, and Hive CE.
///
/// ## Usage
///
/// ```bash
/// # Install globally
/// dart pub global activate flutter_project_builder
///
/// # Generate architecture
/// flutter_project_builder create
///
/// # Or run via dart
/// dart run flutter_project_builder create
/// ```
///
/// See the [README](https://github.com/user/flutter_project_builder) for
/// detailed documentation.
library;

export 'src/cli/cli_logger.dart';
export 'src/cli/command_runner.dart';
export 'src/config/constants.dart';
export 'src/config/project_config.dart';
export 'src/generators/project_generator.dart';
