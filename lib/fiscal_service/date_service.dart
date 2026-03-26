import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class DateService {
  Future<DateTime> getDate() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.name == 'none') {
      return DateTime.now();
    }
    try {
      Uri url = Uri.parse('http://worldtimeapi.org/api/timezone/Asia/Tashkent');
      const timeLimit = Duration(seconds: 2);
      http.Response response = await http.get(url).timeout(timeLimit);
      pragma(response.body);
      var decodedData = jsonDecode(response.body);
      return DateTime.parse(decodedData['utc_datetime']);
    } catch (err) {
      return DateTime.now();
    }
  }
}
