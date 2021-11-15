part of parseserver_openid_flutter;

/// A class, that represents exceptions, that occurred.
class ParseOpenIDException {
  static const int ErrorParseNotInitialized = 1;
  static const int ErrorParseOpenIDNotInitialized = 2;

  final int errorCode;
  final String message;

  ParseOpenIDException({
    this.errorCode = -1,
    required this.message,
  });

  @override
  String toString() {
    return "ParseOpenIDException {$errorCode, $message}";
  }
}
