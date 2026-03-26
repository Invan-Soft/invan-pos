import 'package:invan2/changes/models/shift/shifting_model.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'dart:convert';
import 'package:invan2/utils/utils.dart';

class ShiftApi4 {
  static int _statusCode = 0;
  static final _activatedPosId =
      Pref.getString(PrefKeys.activatedPosId, "not initialized");
  static final _acceptService =
      Pref.getString(PrefKeys.acceptService, "not initialized");

  /////////////////////////////////////////////////////////////
  /////                                                   /////
  /////                   OPEN CASHBOX                     /////
  /////                                                   /////
  /////////////////////////////////////////////////////////////

  static Future<HttpResult> openCashBox() async {
    final token = Pref.getString(PrefKeys.token, "not initialized");
    var headers = {
      'Accept-version': '2.0.0',
      'Accept-user': 'employee',
      'Authorization': "Bearer $token",
      'timezone': "-300",
      'Content-Type': 'application/json'
    };
    String cashBoxId = Pref.getString(PrefKeys.activatedPosId, "");

    var body = {
      "status": true,
      "cashbox_id": cashBoxId,
    };
    return ApiProvider.putResponse(
      path:
          "api/v1/cashbox_pos?version=${Pref.getString(PrefKeys.version, '')}",
      headers: headers,
      body: jsonEncode(body),
      // body: body,
    );
  }

  static Future<HttpResult> versionUpdate() async {
    final token = Pref.getString(PrefKeys.token, "not initialized");
    var headers = {
      'Accept-version': '2.0.0',
      'Accept-user': 'employee',
      'Authorization': "Bearer $token",
      'timezone': "-300",
      'Content-Type': 'application/json'
    };
    String cashBoxId = Pref.getString(PrefKeys.activatedPosId, "");

    var body = {
      "version": Pref.getString(PrefKeys.version, ''),
    };
    return ApiProvider.putResponse(
      path: "api/v1/cashbox_version/$cashBoxId",
      headers: headers,
      body: jsonEncode(body),
      // body: body,
    );
  }

  /////////////////////////////////////////////////////////////
  /////                                                   /////
  /////                   CLOSE CASHBOX                     /////
  /////                                                   /////
  /////////////////////////////////////////////////////////////

  static Future<HttpResult> closeCashBox() async {
    final token = Pref.getString(PrefKeys.token, "not initialized");
    var headers = {
      'Accept-version': '2.0.0',
      'Accept-user': 'employee',
      'Authorization': "Bearer $token",
      'timezone': "-300",
      'Content-Type': 'application/json'
    };
    String cashBoxId = Pref.getString(PrefKeys.activatedPosId, "");

    var body = {
      "status": false,
      "cashbox_id": cashBoxId,
    };

    return ApiProvider.putResponse(
      path:
          "api/v1/cashbox_pos?version=${Pref.getString(PrefKeys.version, '')}",
      headers: headers,
      body: jsonEncode(body),
    );
  }

  /////////////////////////////////////////////////////////////
  /////                                                   /////
  /////                   OPEN SHIFT                     /////
  /////                                                   /////
  /////////////////////////////////////////////////////////////
  static Future<HttpResult> openShift() async {
    final token = Pref.getString(PrefKeys.token, "not initialized");
    final headers = <String, String>{
      'Accept-Version': '2.0.0',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-EmptyShow': '0',
      'Accept-User': 'employee',
      'Authorization': "Bearer $token",
      'Accept-Id': _activatedPosId,
      'timezone': "-300",
      'Accept-Service': _acceptService,
    };
    String cashBoxId = Pref.getString(PrefKeys.activatedPosId, "");

    var body = {
      "opened_at": Pref.getString(PrefKeys.openedDate, ""),
      "closed_at": "",
      "method": "open",
      "opened_by_pos": true,
      "opened_by_web": false,
      "cashbox_id": cashBoxId,
      "user_id": Pref.getString(PrefKeys.userId, "")
    };

    return ApiProvider.postResponse(
      path: "api/v1/shift_pos",
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<HttpResult> shiftStatusInvan2() async {
    final token = Pref.getString(PrefKeys.token, "not initialized");
    final headers = <String, String>{
      'Authorization': "Bearer $token",
      'timezone': "-300",
    };
    return ApiProvider.getResponse(
      path: "api/v1/shift_statuses",
      headers: headers,
    );
  }

  /////////////////////////////////////////////////////////////
  /////                                                   /////
  /////                   CLOSE SHIFT                     /////
  /////                                                   /////
  /////////////////////////////////////////////////////////////

  static Future<ShiftingModel> closeShift() async {
    final token = Pref.getString(PrefKeys.token, "not initialized");
    ShiftingModel result = ShiftingModel();
    var headers = {
      'Accept-version': '2.0.0',
      'Accept-user': 'employee',
      'Authorization': "Bearer $token",
      'timezone': "-300",
      'Content-Type': 'application/json'
    };
    String cashId = Pref.getString(PrefKeys.activatedPosId, "");
    final body = {
      "opened_at": '',
      "closed_at": Pref.getString(PrefKeys.closedDate, ""),
      "cashbox_id": cashId,
      "opened_by_pos": false,
      "opened_by_web": false,
      "method": "close",
      "user_id": Pref.getString(PrefKeys.userId, "")
    };
    try {
      var response = await ApiProvider.postResponse(
        path: "api/v1/shift_pos",
        body: jsonEncode(body),
        headers: headers,
      );
      _statusCode = response.statusCode;
      if (response.statusCode == 200) {
        result.statusCode = response.statusCode;
        result.message = response.result['message'];

        LogRepository.addLog(
          """ HEADERS: => $headers, 
 RESPONSE BODY:  => ${response.result},  REQUEST BODY: => $body """,
          file: "ShiftApi4 / closeShift",
          method: "PATCH",
          path: "api/v1/shift_pos",
          statusCode: response.statusCode,
          where: "SHIFT API / SUCCESS ",
          success: true,
          url: ApiProvider.baseUrlINVAN2,
        );

        return result;
      } else {
        LogRepository.addLog(
          response.result.toString(),
          file: 'ShiftApi4 / try / closeShift',
          method: "PATCH",
          path: "api/v1/shift_pos",
          where: "ORGANIZATION SERVICE / FAILED ",
          url: ApiProvider.baseUrlINVAN2,
          statusCode: _statusCode,
        );
        return ShiftingModel()..message = "Failed";
      }
    } catch (e) {
      Log.e(e, name: 'shift_api_4.dart');
      LogRepository.addLog(
        e.toString(),
        file: 'ShiftApi4 / catch / closeShift',
        method: "PATCH",
        path: "api/v1/shift_pos",
        where: "ORGANIZATION SERVICE / CATCH ",
        url: ApiProvider.baseUrlINVAN2,
        statusCode: _statusCode,
      );
      return ShiftingModel()..message = "Failed";
    }
  }
}
