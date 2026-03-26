import 'package:http/http.dart' as http;
class CreatReceiptResponse {
  http.Response? res;
  final String error;
  CreatReceiptResponse({required this.error, required this.res});
}