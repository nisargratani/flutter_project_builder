// ignore_for_file: public_member_api_docs

import 'package:path/path.dart' as p;

import '../cli/cli_logger.dart';
import '../config/project_config.dart';
import '../templates/features/feature_template.dart';
import '../utils/file_utils.dart';
import '../utils/string_utils.dart';

/// Scaffolds Clean Architecture features.
class FeatureGenerator {
  FeatureGenerator({
    required this.projectPath,
    required this.config,
    this.logger,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  /// The CLI logger.
  final CliLogger? logger;

  static const List<List<String>> _layerFolders = [
    ['data', 'datasource'],
    ['data', 'models'],
    ['data', 'repository'],
    ['domain', 'entities'],
    ['domain', 'repository'],
    ['domain', 'usecases'],
    ['presentation', 'pages'],
    ['presentation', 'widgets'],
    ['presentation', 'providers'],
  ];

  /// Converts [input] (e.g. `UserProfile`, `user-profile`) to the snake_case
  /// folder name used for a feature.
  ///
  /// Throws a [FormatException] if the result is not a valid lowercase Dart
  /// identifier (this also rejects path separators such as `../`) or is a
  /// reserved word.
  static String normalizeName(String input) {
    final name = StringUtils.toSnakeCase(input);
    if (name.isEmpty ||
        name != name.toLowerCase() ||
        !StringUtils.isValidIdentifier(name)) {
      throw FormatException(
        'Invalid feature name "$input". Use letters, digits and underscores, '
        'starting with a letter (e.g. "user_profile"), and avoid Dart '
        'reserved words.',
      );
    }
    return name;
  }

  /// Returns the folder of feature [name] (already normalized).
  String featurePath(String name) =>
      p.join(projectPath, 'lib', 'features', name);

  /// Scaffolds a new empty feature with Clean Architecture structure.
  ///
  /// Existing files are never modified; missing folders are added. Throws a
  /// [FormatException] for invalid names (see [normalizeName]).
  Future<void> generateFeature(String name) async {
    final basePath = featurePath(normalizeName(name));
    for (final segments in _layerFolders) {
      final dir = p.joinAll([basePath, ...segments]);
      if (FileUtils.directoryExists(dir)) continue;
      FileUtils.createGitKeep(dir);
    }
  }

  /// Generates the home page used as the router's initial route.
  Future<void> generateHome() async {
    FileUtils.createFile(
      p.join(featurePath('home'), 'presentation', 'pages', 'home_page.dart'),
      FeatureTemplate.homePage(samples: config.sampleFeatures),
    );
  }

  /// Generates the Counter sample feature (synchronous `Notifier`).
  Future<void> generateCounterSample() async {
    final base = featurePath('counter');
    FileUtils.createFile(
      p.join(base, 'domain', 'entities', 'counter.dart'),
      FeatureTemplate.counterEntity,
    );
    FileUtils.createFile(
      p.join(base, 'presentation', 'providers', 'counter_provider.dart'),
      FeatureTemplate.counterProvider,
    );
    FileUtils.createFile(
      p.join(base, 'presentation', 'pages', 'counter_page.dart'),
      FeatureTemplate.counterPage,
    );
  }

  /// Generates the Users sample feature (all layers, `AsyncNotifier`).
  Future<void> generateUsersSample() async {
    final base = featurePath('users');
    final files = {
      p.join('domain', 'entities', 'user.dart'): FeatureTemplate.userEntity,
      p.join('domain', 'repository', 'user_repository.dart'):
          FeatureTemplate.userRepository,
      p.join('data', 'models', 'user_model.dart'): FeatureTemplate.userModel,
      p.join('data', 'datasource', 'user_remote_data_source.dart'):
          FeatureTemplate.userRemoteDataSource(dio: config.dio),
      p.join('data', 'repository', 'user_repository_impl.dart'):
          FeatureTemplate.userRepositoryImpl,
      p.join('presentation', 'providers', 'users_provider.dart'):
          FeatureTemplate.usersProvider,
      p.join('presentation', 'pages', 'users_page.dart'):
          FeatureTemplate.usersPage,
    };
    for (final entry in files.entries) {
      FileUtils.createFile(p.join(base, entry.key), entry.value);
    }
  }
}
