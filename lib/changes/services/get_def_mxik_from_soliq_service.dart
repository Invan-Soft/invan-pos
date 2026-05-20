import 'package:http/http.dart' as http;

class GetFromSoliqService {
  static Future<http.Response> getFromSoliq(String event) async {
    final headers = {'content-type': 'application/json'};
    http.Response response = await http.get(
      Uri.parse(
        "https://tasnif.soliq.uz/api/cl-api/integration-mxik/get/information?shtrixCode=$event",
      ),
      headers: headers,
    );

    return response;
  }

  static Future<http.Response> getFromSoliqWithMxik(String mxik) async {
    final headers = {'content-type': 'application/json'};
    http.Response response = await http.get(
      Uri.parse(
        "https://tasnif.soliq.uz/api/cl-api/integration-mxik/get/information?mxikCode=$mxik",
      ),
      headers: headers,
    );

    return response;
  }
}
