// ignore_for_file: public_member_api_docs, require_trailing_commas, directives_ordering, cascade_invocations, lines_longer_than_80_chars

import 'package:path/path.dart' as p;

import '../config/project_config.dart';
import '../utils/file_utils.dart';

import '../templates/core/constants_template.dart';
import '../templates/core/enums_template.dart';
import '../templates/core/errors_template.dart';
import '../templates/core/exceptions_template.dart';
import '../templates/core/extensions_template.dart';
import '../templates/core/logger_template.dart';
import '../templates/core/utils_template.dart';

/// Scaffolds core architecture files (constants, errors, extensions, utils).
class CoreGenerator {
  CoreGenerator({
    required this.projectPath,
    required this.config,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  Future<void> generate() async {
    final corePath = p.join(projectPath, 'lib', 'core');

    // Core directories
    FileUtils.createGitKeep(p.join(corePath, 'constants'));
    FileUtils.createGitKeep(p.join(corePath, 'enums'));
    FileUtils.createGitKeep(p.join(corePath, 'errors'));
    FileUtils.createGitKeep(p.join(corePath, 'exceptions'));
    FileUtils.createGitKeep(p.join(corePath, 'extensions'));
    FileUtils.createGitKeep(p.join(corePath, 'logger'));
    FileUtils.createGitKeep(p.join(corePath, 'utils'));

    // Constants
    FileUtils.createFile(p.join(corePath, 'constants', 'app_strings.dart'),
        ConstantsTemplate.appStrings);
    FileUtils.createFile(p.join(corePath, 'constants', 'app_assets.dart'),
        ConstantsTemplate.appAssets);
    FileUtils.createFile(p.join(corePath, 'constants', 'app_colors.dart'),
        ConstantsTemplate.appColors);
    FileUtils.createFile(p.join(corePath, 'constants', 'app_dimensions.dart'),
        ConstantsTemplate.appDimensions);
    FileUtils.createFile(p.join(corePath, 'constants', 'app_durations.dart'),
        ConstantsTemplate.appDurations);
    FileUtils.createFile(p.join(corePath, 'constants', 'app_icons.dart'),
        ConstantsTemplate.appIcons);
    FileUtils.createFile(p.join(corePath, 'constants', 'app_images.dart'),
        ConstantsTemplate.appImages);

    // Enums
    FileUtils.createFile(
        p.join(corePath, 'enums', 'app_enums.dart'), EnumsTemplate.appEnums);

    // Errors
    FileUtils.createFile(p.join(corePath, 'errors', 'app_exception.dart'),
        ErrorsTemplate.appException);
    FileUtils.createFile(
        p.join(corePath, 'errors', 'failure.dart'), ErrorsTemplate.failure);

    // Exceptions
    FileUtils.createFile(p.join(corePath, 'exceptions', 'network_failure.dart'),
        ExceptionsTemplate.networkFailure);
    FileUtils.createFile(p.join(corePath, 'exceptions', 'cache_failure.dart'),
        ExceptionsTemplate.cacheFailure);
    FileUtils.createFile(p.join(corePath, 'exceptions', 'unknown_failure.dart'),
        ExceptionsTemplate.unknownFailure);
    FileUtils.createFile(
        p.join(corePath, 'exceptions', 'validation_failure.dart'),
        ExceptionsTemplate.validationFailure);
    FileUtils.createFile(p.join(corePath, 'exceptions', 'error_mapper.dart'),
        ExceptionsTemplate.errorMapper);
    FileUtils.createFile(
        p.join(corePath, 'exceptions', 'failure_message_resolver.dart'),
        ExceptionsTemplate.failureMessageResolver);

    // Extensions
    FileUtils.createFile(
        p.join(corePath, 'extensions', 'context_extensions.dart'),
        ExtensionsTemplate.contextExtensions);
    FileUtils.createFile(
        p.join(corePath, 'extensions', 'string_extensions.dart'),
        ExtensionsTemplate.stringExtensions);
    FileUtils.createFile(p.join(corePath, 'extensions', 'date_extensions.dart'),
        ExtensionsTemplate.dateExtensions);
    if (config.riverpod) {
      FileUtils.createFile(
          p.join(corePath, 'extensions', 'async_value_extensions.dart'),
          ExtensionsTemplate.asyncValueExtensions);
    }

    // Logger
    FileUtils.createFile(
        p.join(corePath, 'logger', 'log_level.dart'), LoggerTemplate.logLevel);
    FileUtils.createFile(p.join(corePath, 'logger', 'app_logger.dart'),
        LoggerTemplate.appLogger);

    // Utils
    FileUtils.createFile(
        p.join(corePath, 'utils', 'debouncer.dart'), UtilsTemplate.debouncer);
    FileUtils.createFile(
        p.join(corePath, 'utils', 'validators.dart'), UtilsTemplate.validators);
  }
}
