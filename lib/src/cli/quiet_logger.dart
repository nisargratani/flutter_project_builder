import 'cli_logger.dart';

/// A logger that hides generation progress, for internal previews (the dry
/// run `create` uses to detect files it would overwrite).
class QuietLogger extends CliLogger {
  /// Creates a quiet logger.
  QuietLogger() : super(useColors: false);

  @override
  void startProgress({required int total}) {}

  @override
  void step(String message) {}

  @override
  void completeProgress() {}
}
