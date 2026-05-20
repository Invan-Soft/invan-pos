import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:invan2/changes/models/log/loc_res_model.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/app_constants.dart';
import 'package:invan2/utils/constants/secrets.dart';

class ShiftingSerivce {
  static int _statusCode = 0;
  static String token = Secrets.fiscalApiToken;
  static Future<LocalResModel> isShiftOpenedd() async {
    try {
      Uri url = Uri.parse(AppConstants.localhost);
      http.Response res = await http.post(
        url,
        body: jsonEncode({
          "method": "zReportInfo",
          "token": token,
        }),
      );
      final decoded = utf8.decode(res.bodyBytes);
      _statusCode = res.statusCode;
      final body = jsonDecode(decoded);
      LogRepository.addLog(
        """ 
 RESPONSE BODY:  => $decoded,  REQUEST BODY: => ${jsonEncode({
              "method": "zReportInfo",
              "token": token,
            })} """,
        file: "ShiftingSerivce / isShiftOpened",
        method: "POST",
        statusCode: res.statusCode,
        where: "IS SHIFT OPENED / SUCCESS ",
        success: true,
        url: AppConstants.localhost,
      );

      return LocalResModel.fromJson(body);
    } catch (e) {
      LogRepository.addLog(e.toString(),
          file: 'ShiftingSerivce / isShiftOpened',
          method: "POST",
          path: "Shifting_service.dart",
          statusCode: _statusCode,
          where: "IS SHIFT OPENED / CATCH ",
          url: AppConstants.localhost);
      return LocalResModel()..error = true;
    }
  }

  static Future<LocalResModel> closeZReport() async {
    try {
      Uri url = Uri.parse(AppConstants.localhost);
      http.Response res = await http.post(
        url,
        body: jsonEncode({
          "method": "closeZreport",
          "token": token,
        }),
      );
      final decoded = utf8.decode(res.bodyBytes);
      _statusCode = res.statusCode;
      final body = jsonDecode(decoded);
      LogRepository.addLog(
        """ 
 RESPONSE BODY:  => $decoded,  REQUEST BODY: => ${jsonEncode({
              "method": "closeZreport",
              "token": token,
            })} """,
        file: "ShiftingSerivce / isShiftOpened",
        method: "POST",
        statusCode: res.statusCode,
        where: "CLOSE Z REPORT / SUCCESS ",
        success: true,
        url: AppConstants.localhost,
      );

      return LocalResModel.fromJson(body);
    } catch (e) {
      LogRepository.addLog(
        e.toString(),
        file: 'ShiftingSerivce / closeZReport ',
        method: "POST",
        path: "COMUNICATOR",
        statusCode: _statusCode,
        where: "CLOSE Z REPORT / CATCH ",
        url: AppConstants.localhost,
      );
      return LocalResModel()
        ..error = true
        ..message = e.toString();
    }
  }

  static Future<LocalResModel> openeZetReport() async {
    try {
      Uri url = Uri.parse(AppConstants.localhost);
      http.Response res = await http.post(
        url,
        body: jsonEncode({
          "method": "openZreport",
          "token": token,
        }),
      );
      final decoded = utf8.decode(res.bodyBytes);
      _statusCode = res.statusCode;
      final body = jsonDecode(decoded);
      LogRepository.addLog(
        """ 
 RESPONSE BODY:  => $decoded,  REQUEST BODY: => ${jsonEncode({
              "method": "openZreport",
              "token": token,
            })} """,
        file: "ShiftingSerivce / openeZetReport",
        where: "OPEN Z REPORT / SUCCESS ",
        method: "POST",
        statusCode: res.statusCode,
        success: true,
        url: AppConstants.localhost,
      );
      
      return LocalResModel.fromJson(body);
    } catch (e) {
      LogRepository.addLog(
        e.toString(),
        file: 'ShiftingSerivce / openeZetReport',
        method: "POST",
        path: "shifting_service.dart",
        statusCode: _statusCode,
        where: "OPEN Z REPORT / CATCH ",
        url: AppConstants.localhost,
      );
      return LocalResModel()
        ..isFromServer = false
        ..error = true
        ..message = e.toString();
    }
  }
}
