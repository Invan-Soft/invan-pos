import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/fiscal_service/fiscal.dart';
import '../alice_service.dart';
import '../changes/services/api_state.dart';
import '../utils/helpers/prefs.dart';

class BaseService {
  const BaseService._();

  static final Uri _url = Uri.parse(AppLinks.baseUrl);
  static const _headers = {'Content-Type': 'application/json'};

  static Future<ApiState> post(Map<String, dynamic> body) async {
    final String method = body['method'];
    try {
      http.Response response = await http.post(
        _url,
        headers: _headers,
        body: jsonEncode(body),
      );
      await LogHelper.logRequest(
          method: "POST",
          path: _url.toString(),
          statusCode: response.statusCode,
          response: response.body);
      alice.onHttpResponse(response);

      if (response.body.contains('result')) {
        return Success(200, response.body);
      }
      Failure failure = Failure(200, response.body);
      final bool isSaleMethod = method.contains('Sale') || method.contains('Receipt');
      final String orderBody = isSaleMethod ? Pref.getString("bodyForDiscountError", "") : "";
      final String logBody = orderBody.isNotEmpty
          ? "Order Body == $orderBody\n\nBaseService Body== $body"
          : "BaseService Body== $body";
      if (orderBody.isNotEmpty) Pref.removeWithKey("bodyForDiscountError");
      LogRepository.requestSend(failure.errorMessage(),
      file: 'baseservice.dart 39 line',
      method: 'Post Method',
      path: '41 line in baseservice.dart',
          where: "",
          body: logBody);
      _requestSend(
        path: '42 line in baseservice',
        failure.errorMessage(),
        method: method,
        url: _url.toString(),
        statusCode: response.statusCode,
        body: body.toString(),
      );
      return failure;
    } on SocketException {
      _addLog(ApiErrorResponses.fiscalModuleIstConnected,
          method: method.toString());
      return Failure(100, ApiErrorResponses.fiscalModuleIstConnected);
    } on FormatException {
      _addLog(ApiErrorResponses.invalidFormat, method: method.toString());

      return Failure(101, ApiErrorResponses.invalidFormat);
    } on HttpException {
      _addLog(ApiErrorResponses.noInternet, method: method.toString());

      return Failure(102, ApiErrorResponses.noInternet);
    } catch (err) {
      LogRepository.requestSend(
        method: "POSt Method",
        
      " Error berdi ${err.toString()}",
        where: "",
        file: "BaseService 65",
        path: "lib/fiscal_service/base_service.dart 68 line",
        body: body.toString(),
      );
      _addLog(
        err.toString(),
        method: method.toString(),
      );
      return Failure(104, err.toString());
    }
  }

  static Future<String> getTerminalID() async {
    var body = {
      "jsonrpc": "2.0",
      "method": "Api.GetInfo",
      "id": 47360,
      "params": {
        "FactoryID": await StorageService.getFactoryID(),
      }
    };
    try {
      http.Response response = await http.post(
        _url,
        body: jsonEncode(body),
        headers: _headers,
      );

      if (response.body.contains('result')) {
        var result = jsonDecode(response.body);
        return result['result']['TerminalID'];
      }
      return 'no result';
    } catch (err) {
      return 'Unauthorized catch';
    }
  }

  static Future<ApiState> getFactoryId() async {
    var body = {
      "method": ApiMethods.listFiscalDrives,
      "id": 47360,
      "params": {},
      "jsonrpc": "2.0"
    };

    try {
      http.Response response = await http.post(
        _url,
        body: jsonEncode(body),
        headers: _headers,
      );

      if (response.body.contains('result')) {
        return Success(200, response.body);
      }
    } catch (err) {
      return Failure(100, err.toString());
    }

    return Failure(100, ApiErrorResponses.unknownError.toString());
  }

  static void _addLog(
    String message, {
    String method = '',
    String type = 'FAIL',
  }) {
    LogRepository.addLog(
      message,
      file: 'BaseService eror 135',
      method: method,
      where: "",

      // type: type,
    );
  }

  static void _requestSend(
    String message, {
    String method = '',
    String body = '',
    String url = '',
    String path = '',
    int statusCode = 0,
  }) {
    LogRepository.requestSend(
      message,
      file: 'BaseServiceda request sentda errorrrrrr',
      method: method,
      where: "",
      url: url,
      path: path,
      statusCode: statusCode,
      body: body,
    );
  }
}
