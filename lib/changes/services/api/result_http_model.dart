class HttpResult {
  int statusCode;
  bool isSuccess;
  dynamic result;
  dynamic reBytes;

  HttpResult({
    required this.statusCode,
    required this.isSuccess,
    required this.result,
    required this.reBytes,
  });

  String get getError {
    if (result.runtimeType.toString() == 'String') return result;
    try {
      return result['message'];
    } catch (e) {
      return result.toString();
    }
  }
}
