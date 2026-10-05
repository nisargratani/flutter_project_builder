// ignore_for_file: public_member_api_docs

/// Template strings for core.
class EnumsTemplate {
  EnumsTemplate._();

  static const String appEnums = r'''
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
