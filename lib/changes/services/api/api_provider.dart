import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/api.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/log_out_service.dart';

import '../../../alice_service.dart';
import '../log_helper.dart';

class ApiProvider {
  // static const baseUrl = 'https://pos.in1.uz/api/';
  // static const baseUrlDev = 'https://dev.in1.uz/api/';
  // static const baseUrlINVAN2 = 'https://dev.api.7i.uz/';
  // static const baseUrlINVAN2 = 'https://test.7i.uz/';
  // static const baseUrlINVAN2Test = 'https://test.7i.uz/';
  static const imageUrlDev = 'https://dev.cdn.7i.uz/file/';
  static const imageUrlPro = 'https://cdn.7i.uz/file/';

  static const INVAN2DEV = 'https://dev.api.7i.uz/';
  static const INVAN2PRO = 'https://api.7i.uz/';

  // static const baseUrlINVAN2 = INVAN2PRO;
  // static const imageUrl = imageUrlPro;

  static const baseUrlINVAN2 = INVAN2DEV;
  static const imageUrl = imageUrlDev;

  static const Duration _duration = Duration(seconds: 30);

  // static Future<HttpResult> postResponse({
  //   required String path,
  //   dynamic body,
  //   required Map<String, String> headers,
  // }) async {
  //   try {
  //     http.Response response = await http
  //         .post(
  //           _parsedUri(path),
  //           body: body,
  //           headers: headers,
  //         )
  //         .timeout(_duration);
  //
  //     await LogHelper.logRequest(
  //         method: "POST",
  //         path: path,
  //         statusCode: response.statusCode,
  //         body: body,
  //         response: response.body);
  //     alice.onHttpResponse(response);
  //     ReceiptModel4? receiptModel4;
  //     if (body != null) {
  //       receiptModel4 = ReceiptModel4.fromJson(jsonDecode(body));
  //     }
  //     if (response.statusCode < 200 || response.statusCode > 300) {
  //           body: body ?? '', receiptModel4: receiptModel4);
  //     }else{
  //       LogRepository.requestSend(response.toString(), where: "in api provider",body: body,file: "Api Provider");
  //     }
  //     return _result(
  //         res: response, data: body, path: path, receiptModel4: receiptModel4);
  //   } on TimeoutException catch (_) {
  //     return HttpResult(
  //       reBytes: "",
  //       result: "Internet Error (TimeoutException)",
  //       isSuccess: false,
  //       statusCode: -1,
  //     );
  //   } on SocketException catch (_) {
  //     return HttpResult(
  //       reBytes: "",
  //       result: "Internet Error",
  //       isSuccess: false,
  //       statusCode: -1,
  //     );
  //   }
  // }
  static Future<HttpResult> postResponse({
    required String path,
    dynamic body,
    required Map<String, String> headers,
  }) async {
    try {
      print('Api V1orderPos Body ${body}');
      http.Response response = await http
          .post(
            _parsedUri(path),
            body: body,
            headers: headers,
          )
          .timeout(_duration);

      if (response.statusCode != 409) {
        await LogHelper.logRequest(
          method: "POST",
          path: path,
          statusCode: response.statusCode,
          body: body,
          response: response.body,
        );
      }
      alice.onHttpResponse(response);

      ReceiptModel4? receiptModel4;
      if (body != null && body is String) {
        try {
          receiptModel4 = ReceiptModel4.fromJson(jsonDecode(body));
        } catch (_) {}
      }

      if (response.statusCode < 200 || response.statusCode > 300) {
        if (response.statusCode != 409) {
          LogRepository.requestSend(
            "POST xato: ${response.statusCode}",
            where: "ApiProvider.postResponse",
            file: "api_provider.dart",
            method: "POST",
            path: path,
            url: baseUrlINVAN2,
            statusCode: response.statusCode,
            body: body?.toString() ?? "body yo'q",
            createdDate: receiptModel4?.createdDate ?? "",
            checkNo: receiptModel4?.externalId ?? "",
            success: false,
          );
        }
      }

      return _result(
          res: response, data: body, path: path, receiptModel4: receiptModel4);
    } on TimeoutException catch (e, stack) {
      LogRepository.addLog(
        "TimeoutException: $path",
        where: "ApiProvider.postResponse",
        file: "api_provider.dart",
        method: "POST",
        path: path,
        success: false,
      );
      return HttpResult(
        reBytes: "",
        isSuccess: false,
        result: "Internet ulanmadi (Timeout)",
        statusCode: -1,
      );
    } catch (e, stack) {
      LogRepository.requestSend(
        "Kutilmagan xato: $e",
        where: "ApiProvider.postResponse",
        file: "api_provider.dart",
        method: "POST",
        path: path,
        url: baseUrlINVAN2,
        body: body?.toString() ?? "body mavjud emas",
        success: false,
      );

      // Stack trace ham yuborish uchun (juda foydali!)
      LogRepository.addLog(
        "Catch error: $e\nStack: $stack",
        where: "ApiProvider.catch",
        file: "api_provider.dart",
        method: "POST",
        path: path,
        success: false,
      );

      return HttpResult(
        reBytes: "",
        isSuccess: false,
        result: "Xato yuz berdi: $e",
        statusCode: -2,
      );
    }
  }

  static Future<HttpResult> getResponse(
      {required String path,
      required Map<String, String> headers,
      int? seconds}) async {
    try {
      http.Response response = await http.get(
        _parsedUri(path),
        headers: headers,
      );
      await LogHelper.logRequest(
          method: "GET",
          path: path,
          statusCode: response.statusCode,
          response: response.body);

      alice.onHttpResponse(response);
      if (response.statusCode < 200 || response.statusCode > 300) {
        if (response.statusCode != 409) {
          _requestBody(response, path, 'GET');
        }
      }
      return _result(res: response, path: path);
    } on TimeoutException catch (_) {
      return HttpResult(
        reBytes: "",
        result: "Internet Error",
        isSuccess: false,
        statusCode: -1,
      );
    } on SocketException catch (_) {
      return HttpResult(
        reBytes: "",
        result: "Internet Error",
        isSuccess: false,
        statusCode: -1,
      );
    }
  }

  static Future<HttpResult> putResponse({
    required String path,
    dynamic body,
    required Map<String, String> headers,
  }) async {
    try {
      http.Response response = await http
          .put(
            _parsedUri(path),
            body: body,
            headers: headers,
          )
          .timeout(_duration);
      await LogHelper.logRequest(
        method: "PUT",
        path: path,
        statusCode: response.statusCode,
        body: body,
        response: response.body,
      );

      alice.onHttpResponse(response);
      ReceiptModel4? receiptModel4;
      if (body != null) {
        receiptModel4 = ReceiptModel4.fromJson(jsonDecode(body));
      }
      if (response.statusCode < 200 || response.statusCode > 300) {
        if (response.statusCode != 409) {
          _requestBody(response, path, 'PUT',
              body: body, receiptModel4: receiptModel4);
        }
      }
      return _result(
          res: response, data: body, path: path, receiptModel4: receiptModel4);
    } on TimeoutException catch (_) {
      return HttpResult(
        reBytes: "",
        result: "Internet Error",
        isSuccess: false,
        statusCode: -1,
      );
    } on SocketException catch (_) {
      return HttpResult(
        reBytes: "",
        result: "Internet Error",
        isSuccess: false,
        statusCode: -1,
      );
    }
  }

  static HttpResult _result({
    required http.Response res,
    required String path,
    dynamic data,
    ReceiptModel4? receiptModel4,
  }) {
    // res.request?.url.printf('URL');
    if (res.body.startsWith("[") && res.body.endsWith("]")) {
      return HttpResult(
          statusCode: res.statusCode,
          reBytes: res.bodyBytes,
          isSuccess: true,
          result: jsonDecode(utf8.decode(res.bodyBytes))
          // result: jsonDecode(res.body),
          );
    }
    ResHeadModel? resHeadModel = _decoder(res);
    _addLog(res, resHeadModel, path, receiptModel4: receiptModel4);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return HttpResult(
        statusCode: res.statusCode,
        isSuccess: true,
        reBytes: res.bodyBytes,
        result: jsonDecode(utf8.decode(res.bodyBytes)),
      );
    } else if (res.statusCode >= 500 && res.statusCode == 404) {
      return HttpResult(
        statusCode: res.statusCode,
        isSuccess: false,
        reBytes: res.bodyBytes,
        result: jsonDecode(utf8.decode(res.bodyBytes)).toString(),
      );
    } else {
      return HttpResult(
        reBytes: res.bodyBytes,
        statusCode: res.statusCode,
        isSuccess: false,
        result: jsonDecode(utf8.decode(res.bodyBytes)).toString(),
      );
    }
  }

  static _parsedUri(String v) {
    return Uri.parse("$baseUrlINVAN2$v");
  }

  static ResHeadModel? _addLog(
      http.Response res, ResHeadModel? resHeadModel, String path,
      {ReceiptModel4? receiptModel4}) {
    if (!path.contains("goods/sales/desktop/export")) {
      LogRepository.addLog(
        jsonEncode(utf8.decode(res.bodyBytes)),
        file: "ApiProvider",
        method: "POST",
        where: "API PROVIDER",
        path: path,
        statusCode: res.statusCode,
        success: (resHeadModel != null && resHeadModel.message == "Success"),
        url: baseUrlINVAN2,
        createdDate: receiptModel4?.createdDate ?? '',
        checkNo: receiptModel4?.externalId ?? '',
      );
    }
    return resHeadModel;
  }

  static void _requestBody(http.Response res, String path, String method,
      {String body = '', ReceiptModel4? receiptModel4}) {
    LogRepository.requestSend(
      '',
      file: 'ApiProvider',
      method: method,
      where: "API PROVIDER",
      url: baseUrlINVAN2,
      path: path,
      statusCode: res.statusCode,
      body: body,
      createdDate: receiptModel4?.createdDate ?? "",
      checkNo: receiptModel4?.externalId ?? "",
    );
  }

  static ResHeadModel? _decoder(body) {
    try {
      dynamic decoded = json.decode(body);

      return ResHeadModel.fromJson(decoded);
    } catch (e) {
      return null;
    }
  }
}
