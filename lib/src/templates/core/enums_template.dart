// ignore_for_file: public_member_api_docs, use_raw_strings, unnecessary_string_escapes

/// Template strings for core.
class EnumsTemplate {
  EnumsTemplate._();

  static const String appEnums = '''
enum Environment {
  dev,
  stage,
  prod,
}

enum LoadingState {
  initial,
  loading,
  success,
  error,
}
''';
}
