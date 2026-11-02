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
/// # Create a new app with the architecture
/// flutter_project_builder create my_app
///
/// # Or generate inside an existing Flutter project
/// flutter_project_builder create
///
/// # Or run via dart
/// dart run flutter_project_builder create
/// ```
///
/// The library exposes the command runner and configuration types so the CLI
/// can be embedded or driven programmatically:
///
/// ```dart
/// final exitCode = await FlutterProjectBuilderCommandRunner(
///   workingDirectory: '/path/to/flutter_app',
/// ).run(['create', '--no-interactive']);
/// ```
///
/// See the [README](https://github.com/nisargratani/flutter_project_builder)
/// for detailed documentation.
library;

export 'src/cli/cli_logger.dart';
export 'src/cli/command_runner.dart';
export 'src/config/constants.dart';
export 'src/config/project_config.dart';
export 'src/generators/project_generator.dart';
export 'src/utils/flutter_cli.dart';
