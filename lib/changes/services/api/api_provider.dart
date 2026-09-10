import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/api.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/health/backend_health.dart';
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

  static const baseUrlINVAN2 = INVAN2PRO;
  static const imageUrl = imageUrlPro;

  static const String envPro = 'pro';
  static const String envDev = 'dev';

  /// Build qaysi API muhitiga ulanayotgani. dev↔pro almashganda eski token
  /// boshqa muhitga tegishli bo'lgani uchun yaroqsiz — buni [AuthReset]
  /// startup'da tekshiradi.
  static String get currentEnv =>
      baseUrlINVAN2 == INVAN2PRO ? envPro : envDev;

  static const Duration _duration = Duration(seconds: 30);

  /// GET so'rovlari uchun timeout.
  ///
  /// Ilgari GET'da timeout UMUMAN yo'q edi: server TCP ulanishni qabul
  /// qilib, javob bermay qo'ysa (yiqilgan serverda odatiy hol) Future hech
  /// qachon tugamasdi va ilova startup'da splash ekranda muzlab qolardi.
  /// POST/PUT dan qisqaroq: GET'lar odatda ma'lumot o'qish uchun va ular
  /// kutilishi kassirni to'g'ridan-to'g'ri to'sib qo'yadi.
  static const Duration _getDuration = Duration(seconds: 15);

  /// Server yiqilgani aniqlangani uchun tarmoqqa umuman chiqarilmagan so'rov.
  ///
  /// Bu javob darhol qaytadi — kassir 15-30 soniya kutib o'tirmaydi va
  /// chaqiruvchi kod mavjud oflayn shoxiga tushadi.
  static HttpResult _serverDownResult(String path) {
    LogHelper.logRequest(
      method: "GATE",
      path: path,
      statusCode: BackendHealth.serverDownStatusCode,
      response: "So'rov yuborilmadi: server yiqilgan (BackendHealth)",
    );
    return HttpResult(
      reBytes: "",
      isSuccess: false,
      result: "Server bilan aloqa yo'q",
      statusCode: BackendHealth.serverDownStatusCode,
    );
  }

  static Future<HttpResult> postResponse({
    required String path,
    dynamic body,
    required Map<String, String> headers,
    bool force = false,
  }) async {
    if (!BackendHealth.allowRequest(force: force)) {
      return _serverDownResult(path);
    }
    try {
      http.Response response = await http
          .post(
            _parsedUri(path),
            body: body,
            headers: headers,
          )
          .timeout(_duration);
      BackendHealth.recordStatusCode(response.statusCode, path: path);

      // 409 ham yoziladi. Ilgari u o'tkazib yuborilardi va natijada
      // "server chekni allaqachon qabul qilgan" degan MUHIM holat na
      // jurnalda, na tashxisda ko'rinmasdi — 2026-09-03 da cheklar serverda
      // turgani holda kassada qizil (!) bo'lib qolganini aniqlash shu sabab
      // qiyin bo'ldi. Telegramga esa baribir ketmaydi (LogRepository 409 ni
      // filtrlaydi) — u yerda shovqin bo'lardi.
      await LogHelper.logRequest(
        method: "POST",
        path: path,
        statusCode: response.statusCode,
        body: body,
        response: response.body,
      );

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
            path: "120 line in api provider $path",
            url: baseUrlINVAN2,
            statusCode: response.statusCode,
            body: "So'rov (request):\n${body?.toString() ?? "body yo'q"}"
                "\n\nServer javobi (response):\n${response.body}",
            createdDate: receiptModel4?.createdDate ?? "",
            checkNo: receiptModel4?.externalId ?? "",
            success: false,
          );
        }
      }

      return _result(
          res: response, data: body, path: path, receiptModel4: receiptModel4);
    } on TimeoutException {
      BackendHealth.recordFailure(path: path);
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
      if (BackendHealth.isNetworkFailure(e)) {
        BackendHealth.recordFailure(path: path);
      }
      LogRepository.requestSend(
        "Kutilmagan xato: $e",
        where: "ApiProvider.postResponse",
        file: "api_provider.dart",
        method: "POST",
        path: "154 lin in api provider $path",
        url: baseUrlINVAN2,
        body: body?.toString() ?? "body mavjud emas",
        success: false,
      );
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
      int? seconds,
      bool force = false}) async {
    if (!BackendHealth.allowRequest(force: force)) {
      return _serverDownResult(path);
    }
    try {
      http.Response response = await http
          .get(
            _parsedUri(path),
            headers: headers,
          )
          .timeout(seconds != null ? Duration(seconds: seconds) : _getDuration);
      BackendHealth.recordStatusCode(response.statusCode, path: path);
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
      BackendHealth.recordFailure(path: path);
      return HttpResult(
        reBytes: "",
        result: "Internet Error",
        isSuccess: false,
        statusCode: -1,
      );
    } on SocketException catch (_) {
      BackendHealth.recordFailure(path: path);
      return HttpResult(
        reBytes: "",
        result: "Internet Error",
        isSuccess: false,
        statusCode: -1,
      );
    } catch (e) {
      if (BackendHealth.isNetworkFailure(e)) {
        BackendHealth.recordFailure(path: path);
      }
      return HttpResult(
        reBytes: "",
        result: "Xato yuz berdi: $e",
        isSuccess: false,
        statusCode: -2,
      );
    }
  }

  static Future<HttpResult> putResponse({
    required String path,
    dynamic body,
    required Map<String, String> headers,
    bool force = false,
  }) async {
    if (!BackendHealth.allowRequest(force: force)) {
      return _serverDownResult(path);
    }
    try {
      http.Response response = await http
          .put(
            _parsedUri(path),
            body: body,
            headers: headers,
          )
          .timeout(_duration);
      BackendHealth.recordStatusCode(response.statusCode, path: path);
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
      BackendHealth.recordFailure(path: path);
      return HttpResult(
        reBytes: "",
        result: "Internet Error",
        isSuccess: false,
        statusCode: -1,
      );
    } on SocketException catch (_) {
      BackendHealth.recordFailure(path: path);
      return HttpResult(
        reBytes: "",
        result: "Internet Error",
        isSuccess: false,
        statusCode: -1,
      );
    } catch (e) {
      if (BackendHealth.isNetworkFailure(e)) {
        BackendHealth.recordFailure(path: path);
      }
      return HttpResult(
        reBytes: "",
        result: "Xato yuz berdi: $e",
        isSuccess: false,
        statusCode: -2,
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
      path: "343 in api $path",
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
