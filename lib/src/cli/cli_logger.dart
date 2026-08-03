// ignore_for_file: cascade_invocations, lines_longer_than_80_chars

import 'dart:io';

/// ANSI color and styling utilities for polished CLI output.
///
/// Provides colored text, status indicators, progress tracking,
/// and box drawing for a professional terminal experience.
///
/// Automatically detects terminal color support and falls back
/// to plain text when colors are not available.
class CliLogger {
  /// Creates a new [CliLogger] instance.
  ///
  /// Set [useColors] to `false` to disable ANSI colors.
  /// Defaults to auto-detection based on terminal capabilities.
  CliLogger({bool? useColors})
      : _useColors = useColors ?? stdout.hasTerminal && !Platform.isWindows;

  final bool _useColors;
  int _stepCount = 0;
  int _totalSteps = 0;
  final Stopwatch _stopwatch = Stopwatch();

  // ── ANSI Codes ──────────────────────────────────────────────────────

  static const String _reset = '\x1B[0m';
  static const String _bold = '\x1B[1m';
  static const String _dim = '\x1B[2m';
  static const String _italic = '\x1B[3m';
  static const String _underline = '\x1B[4m';

  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _white = '\x1B[37m';
  static const String _grey = '\x1B[90m';

  // ── Color Helpers ───────────────────────────────────────────────────

  /// Wraps [text] with the given ANSI [code].
  String _style(String text, String code) =>
      _useColors ? '$code$text$_reset' : text;

  /// Returns [text] in red.
  String red(String text) => _style(text, _red);

  /// Returns [text] in green.
  String green(String text) => _style(text, _green);

  /// Returns [text] in yellow.
  String yellow(String text) => _style(text, _yellow);

  /// Returns [text] in blue.
  String blue(String text) => _style(text, _blue);

  /// Returns [text] in magenta.
  String magenta(String text) => _style(text, _magenta);

  /// Returns [text] in cyan.
  String cyan(String text) => _style(text, _cyan);

  /// Returns [text] in white.
  String white(String text) => _style(text, _white);

  /// Returns [text] in grey.
  String grey(String text) => _style(text, _grey);

  /// Returns [text] in bold.
  String bold(String text) => _style(text, _bold);

  /// Returns [text] in dim.
  String dim(String text) => _style(text, _dim);

  /// Returns [text] in italic.
  String italic(String text) => _style(text, _italic);

  /// Returns [text] underlined.
  String underlined(String text) => _style(text, _underline);

  // ── Status Icons ────────────────────────────────────────────────────

  /// Success icon (green checkmark).
  String get successIcon => green('✔');

  /// Error icon (red cross).
  String get errorIcon => red('✘');

  /// Warning icon (yellow triangle).
  String get warningIcon => yellow('⚠');

  /// Info icon (blue circle).
  String get infoIcon => blue('ℹ');

  /// Arrow icon for sub-steps.
  String get arrowIcon => cyan('→');

  /// Bullet icon.
  String get bulletIcon => grey('•');

  // ── Logging Methods ─────────────────────────────────────────────────

  /// Prints a success message with green checkmark.
  void success(String message) {
    stdout.writeln('  $successIcon $message');
  }

  /// Prints an error message with red cross.
  void error(String message) {
    stderr.writeln('  $errorIcon ${red(message)}');
  }

  /// Prints a warning message with yellow triangle.
  void warning(String message) {
    stdout.writeln('  $warningIcon ${yellow(message)}');
  }

  /// Prints an info message with blue circle.
  void info(String message) {
    stdout.writeln('  $infoIcon $message');
  }

  /// Prints a detail/sub-step message.
  void detail(String message) {
    stdout.writeln('    $arrowIcon ${grey(message)}');
  }

  /// Prints a blank line.
  void newLine() {
    stdout.writeln();
  }

  /// Prints raw text without formatting.
  void write(String message) {
    stdout.writeln(message);
  }

  // ── Progress Tracking ───────────────────────────────────────────────

  /// Starts a progress sequence with the given [total] number of steps.
  void startProgress({required int total}) {
    _totalSteps = total;
    _stepCount = 0;
    _stopwatch
      ..reset()
      ..start();
  }

  /// Advances to the next step and prints a success message.
  void step(String message) {
    _stepCount++;
    final prefix = grey('[${_stepCount.toString().padLeft(2)}/$_totalSteps]');
    stdout.writeln('  $successIcon $prefix $message');
  }

  /// Completes the progress sequence and prints the elapsed time.
  void completeProgress() {
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsed;
    final formatted = _formatDuration(elapsed);
    newLine();
    success('Done in ${green(formatted)}');
  }

  // ── Box Drawing ─────────────────────────────────────────────────────

  /// Prints a header box with the given [title] and optional [subtitle].
  void header(String title, {String? subtitle}) {
    const width = 60;
    final topBorder = '╔${'═' * (width - 2)}╗';
    final bottomBorder = '╚${'═' * (width - 2)}╝';
    final emptyLine = '║${' ' * (width - 2)}║';

    newLine();
    stdout.writeln(cyan(topBorder));
    stdout.writeln(cyan(emptyLine));
    stdout.writeln(
      cyan('║') + _centerText(bold(title), width - 2) + cyan('║'),
    );
    if (subtitle != null) {
      stdout.writeln(
        cyan('║') + _centerText(dim(subtitle), width - 2) + cyan('║'),
      );
    }
    stdout.writeln(cyan(emptyLine));
    stdout.writeln(cyan(bottomBorder));
    newLine();
  }

  /// Prints a section divider with the given [title].
  void section(String title) {
    newLine();
    stdout.writeln('  ${bold(cyan('── $title ──'))}');
    newLine();
  }

  /// Prints a summary box with key-value pairs.
  void summaryBox(String title, Map<String, String> items) {
    section(title);
    for (final entry in items.entries) {
      stdout.writeln('    ${bold(entry.key)}: ${entry.value}');
    }
    newLine();
  }

  /// Prints next steps after a successful operation.
  void nextSteps(List<String> steps) {
    section('Next Steps');
    for (var i = 0; i < steps.length; i++) {
      stdout.writeln('    ${bold('${i + 1}.')} ${steps[i]}');
    }
    newLine();
  }

  // ── Private Helpers ─────────────────────────────────────────────────

  String _centerText(String text, int width) {
    // Strip ANSI codes for length calculation.
    final plainLength = text.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '').length;
    final totalPadding = width - plainLength;
    if (totalPadding <= 0) return text;
    final leftPad = totalPadding ~/ 2;
    final rightPad = totalPadding - leftPad;
    return '${' ' * leftPad}$text${' ' * rightPad}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      final seconds = duration.inSeconds % 60;
      return '${duration.inMinutes}m ${seconds}s';
    }
    if (duration.inSeconds > 0) {
      final ms = duration.inMilliseconds % 1000;
      return '${duration.inSeconds}.${ms ~/ 100}s';
    }
    return '${duration.inMilliseconds}ms';
  }
}
