import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:convert/convert.dart' as convert;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/alice_service.dart';
import 'package:invan2/changes/models/click_response_model.dart';
import 'package:invan2/changes/models/epay/e_pay_model.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/utils/helpers/e_pay_helper.dart';
import 'package:invan2/utils/utils.dart';

import '../log_helper.dart';

class PaynetService {
  const PaynetService._();

  static int? paymentId;

  static const String _baseUrlTest = 'https://pass-test.paynet.uz/v2/merchant';
  static const String _baseUrlProd = 'https://api.paynet.uz/v2/merchant';
  static const String _baseUrl = _baseUrlTest; // TODO: prod ga o'tkazish

  // 1. To'lovni yaratish (Paynet QR)
  static Future<ClickResponseModel> payment({
    required String otpData,
    required num amount,
    required String receiptNumber,
  }) async {
    Log.d('payment() boshlandi — amount: $amount, receipt: $receiptNumber', name: 'PaynetService');

    EPayModel? ePayModel = EPayHelper.instance.box.get(EPayEnum.paynet.value);
    final serviceId = int.tryParse(ePayModel?.serviceId ?? '') ?? 0;

    var body = {
      "service_id": serviceId,
      "otp_data": otpData,
      "amount": amount,
      "transaction_id": receiptNumber,
    };

    Log.j(body, name: 'PaynetService | payment body');

    ClickResponseModel result = await _post(
      path: '/paynet-pass/payment',
      body: body,
    );

    if (result.errorCode == 0) {
      final pid = result.paymentId;
      paymentId = pid != null ? int.tryParse(pid) : null;
      Log.d('payment() muvaffaqiyatli — payment_id: $paymentId', name: 'PaynetService');
    } else {
      Log.e('payment() xato — error_code: ${result.errorCode}, note: ${result.errorNote}', name: 'PaynetService');
    }

    return result;
  }

  // 2. To'lov statusini tekshirish (payment_id bo'yicha)
  static Future<ClickResponseModel> checkPaymentStatus(int pid) async {
    Log.d('checkPaymentStatus() — payment_id: $pid', name: 'PaynetService');

    EPayModel? ePayModel = EPayHelper.instance.box.get(EPayEnum.paynet.value);
    final serviceId = int.tryParse(ePayModel?.serviceId ?? '') ?? 0;

    final url = '$_baseUrl/payment/status/by-payment-id/$serviceId/$pid';
    final uri = Uri.parse(url);

    try {
      http.Response response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      await LogHelper.logRequest(
        method: "GET",
        path: url,
        statusCode: response.statusCode,
        response: response.body,
      );
      alice.onHttpResponse(response);

      Log.d('checkPaymentStatus() response: ${response.body}', name: 'PaynetService');

      return decodeClickResponseModel(response.body);
    } catch (err) {
      Log.e(err, name: 'PaynetService | checkPaymentStatus');
      return ClickResponseModel(errorCode: -1, errorNote: err.toString());
    }
  }

  // 3. To'lovni bekor qilish (reversal)
  static Future<ClickResponseModel> reversalPayment(int pid) async {
    Log.d('reversalPayment() — payment_id: $pid', name: 'PaynetService');

    EPayModel? ePayModel = EPayHelper.instance.box.get(EPayEnum.paynet.value);
    final serviceId = int.tryParse(ePayModel?.serviceId ?? '') ?? 0;

    final url = '$_baseUrl/paynet-pass/payment/reversal/$serviceId/$pid';
    final uri = Uri.parse(url);

    try {
      http.Response response = await http
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      await LogHelper.logRequest(
        method: "DELETE",
        path: url,
        statusCode: response.statusCode,
        response: response.body,
      );
      alice.onHttpResponse(response);

      Log.d('reversalPayment() response: ${response.body}', name: 'PaynetService');

      return decodeClickResponseModel(response.body);
    } catch (err) {
      Log.e(err, name: 'PaynetService | reversalPayment');
      return ClickResponseModel(errorCode: -1, errorNote: err.toString());
    }
  }

  // 4. To'lovni tasdiqlash (confirm mode)
  static Future<ClickResponseModel> confirm(int pid) async {
    Log.d('confirm() — payment_id: $pid', name: 'PaynetService');

    EPayModel? ePayModel = EPayHelper.instance.box.get(EPayEnum.paynet.value);
    final serviceId = int.tryParse(ePayModel?.serviceId ?? '') ?? 0;

    final url = '$_baseUrl/paynet-pass/payment/confirm';
    final uri = Uri.parse(url);
    final body = {"service_id": serviceId, "payment_id": pid};

    try {
      http.Response response = await http
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      await LogHelper.logRequest(
        method: "POST",
        path: url,
        statusCode: response.statusCode,
        body: body,
        response: response.body,
      );
      alice.onHttpResponse(response);

      Log.d('confirm() response: ${response.body}', name: 'PaynetService');

      return decodeClickResponseModel(response.body);
    } catch (err) {
      Log.e(err, name: 'PaynetService | confirm');
      return ClickResponseModel(errorCode: -1, errorNote: err.toString());
    }
  }

  // 5. Fiskal chekni yuborish (OFD)
  static Future<ClickResponseModel> sendFiscalReceipt({
    required int pid,
    required String qrcode,
    required String salePointAddress,
    double? latitude,
    double? longitude,
  }) async {
    Log.d('sendFiscalReceipt() — payment_id: $pid', name: 'PaynetService');

    EPayModel? ePayModel = EPayHelper.instance.box.get(EPayEnum.paynet.value);
    final serviceId = int.tryParse(ePayModel?.serviceId ?? '') ?? 0;

    final body = <String, dynamic>{
      "service_id": serviceId,
      "payment_id": pid,
      "qrcode": qrcode,
      "salePointAddress": salePointAddress,
      if (latitude != null) "latitude": latitude,
      if (longitude != null) "longitude": longitude,
    };

    final result = await _post(
      path: '/paynet-pass/ofd-data/submit-qrcode',
      body: body,
    );

    if (result.errorCode == 0) {
      Log.d('sendFiscalReceipt() muvaffaqiyatli', name: 'PaynetService');
    } else {
      Log.e('sendFiscalReceipt() xato: ${result.errorCode} — ${result.errorNote}', name: 'PaynetService');
    }

    return result;
  }

  // ==================== ICHKI YORDAMCHI METODLAR ====================

  static Future<ClickResponseModel> _post({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    Log.j(body, name: 'PaynetService | POST $path');
    ClickResponseModel result;

    try {
      final uri = Uri.parse('$_baseUrl$path');
      final headers = _headers;
      final bodyStr = jsonEncode(body);

      Log.d(
        '\n\ncurl -X POST \'$uri\' \\\n'
        '  -H \'Auth: ${headers["Auth"]}\' \\\n'
        '  -H \'Accept: application/json\' \\\n'
        '  -H \'Content-type: application/json\' \\\n'
        '  -d \'$bodyStr\'\n',
        name: 'PaynetService | CURL',
      );

      print('========== PAYNET REQUEST ==========');
      print('URL    : $uri');
      print('Auth   : ${headers["Auth"]}');
      print('Body   : $bodyStr');
      print('=====================================');

      http.Response response = await http
          .post(uri, body: bodyStr, headers: headers)
          .timeout(const Duration(seconds: 30));

      print('========== PAYNET RESPONSE ==========');
      print('Status : ${response.statusCode}');
      print('Body   : ${response.body}');
      print('=====================================');

      await LogHelper.logRequest(
        method: "POST",
        path: uri.toString(),
        statusCode: response.statusCode,
        body: body,
        response: response.body,
      );
      alice.onHttpResponse(response);

      if (response.statusCode == 200) {
        result = decodeClickResponseModel(response.body);
        return result;
      }

      result = ClickResponseModel(
        errorCode: response.statusCode,
        errorNote: response.body,
      );
      return result;
    } catch (err) {
      Log.e(err, name: 'PaynetService | POST $path | ${err.runtimeType}');
      String? message;
      if (err is SocketException) {
        message = err.message;
      } else if (err is TimeoutException) {
        message = err.message;
      } else if (err is HttpException) {
        message = err.message;
      } else {
        message = err.toString();
      }
      result = ClickResponseModel(errorCode: -1, errorNote: message);
      JsonEncoder encoder = const JsonEncoder.withIndent(' ');
      String prettyJson = encoder.convert(result.toJson());
      LogRepository.addLog(
        prettyJson,
        where: 'lib/changes/services/payment/paynet_service.dart',
        file: 'paynet_service.dart',
        url: _baseUrl,
        method: 'POST',
        path: path,
        statusCode: 1200,
      );
      return result;
    }
  }

  static Map<String, String> get _headers {
    EPayModel? ePayModel = EPayHelper.instance.box.get(EPayEnum.paynet.value);

    final merchantUserId = ePayModel?.merchantUserId ?? '';
    final secretKey = ePayModel?.secretKey ?? '';

    print('PAYNET _headers → merchantUserId: "$merchantUserId" | secretKey: "${secretKey.isEmpty ? "BO\'SH!" : secretKey.substring(0, secretKey.length.clamp(0, 8))}..." | model null: ${ePayModel == null}');

    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var chunk = utf8.encode('$now$secretKey');
    var output = convert.AccumulatorSink<Digest>();
    var input = sha1.startChunkedConversion(output);
    input.add(chunk);
    input.close();
    var digest = output.events.single;

    return {
      "Auth": '$merchantUserId:$digest:$now',
      "Accept": "application/json",
      "Content-type": "application/json",
    };
  }
}
