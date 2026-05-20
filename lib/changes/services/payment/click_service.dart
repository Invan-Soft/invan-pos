import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:convert/convert.dart' as convert;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/alice_service.dart';
import 'package:invan2/changes/models/click_response_model.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/utils/helpers/click_helper.dart';
import 'package:invan2/utils/utils.dart';

import '../log_helper.dart';

class ClickService {
  const ClickService._();

  static String? paymentId;

  static const String _baseUrl = 'https://api.click.uz/v2/merchant';

  // Оплата с помощью CLICK Pass
  static Future<ClickResponseModel> payment({
    required String otpData,
    required num amount,
    required String receiptNumber,
  }) async {
    // OTP DATA: SCANER'DAN OLINADI
    var body = {
      "service_id": Pref.getInt(PrefKeys.serviceId, -1),
      "otp_data": otpData,
      "amount": amount,
      "transaction_id": receiptNumber, //receipt_number
      "cashbox_code": Pref.getString(
        PrefKeys.posName,
        "not initialized",
      ), //pos_device
    };

    ClickResponseModel clickResponse = await post(
      path: '/click_pass/payment',
      body: body,
    );

    if (clickResponse.errorCode == 0) {
      paymentId = clickResponse.paymentId;
    }

    Pref.setString('epayPaymentId', clickResponse.paymentId ?? "");
    Pref.setInt('epayId', 0064);
    return clickResponse;
  }


  static Future checkPayment(String otpData, int paymentId) async {
    const serviceID = 48951;

    Uri uri = Uri.parse('$_baseUrl/payment/$serviceID/$paymentId');
    http.Response response = await http.get(uri, headers: _headers);
    await LogHelper.logRequest(
        method: "GET",
        path: uri.toString(),
        statusCode: response.statusCode,
        response: response.body);

    alice.onHttpResponse(response);
    ClickResponseModel click = decodeClickResponseModel(response.body);

    // ignore: unrelated_type_equality_checks
    if (click.errorCode == 0) {
      // return SUCCESS
    }
    // return FAILURE
  }

  static Future reversalPayment(String otpData, int paymentId) async {
    // OTP DATA: SCANER'DAN OLINADI
    const serviceID = 48951;

    Uri uri = Uri.parse('$_baseUrl/payment/$serviceID/$paymentId');
    http.Response response = await http.delete(uri, headers: _headers);
    await LogHelper.logRequest(method: "DELETE", path: uri.toString(), statusCode: response.statusCode,response: response.body);

    alice.onHttpResponse(response);
    ClickResponseModel click = decodeClickResponseModel(response.body);

    // ignore: unrelated_type_equality_checks
    if (click.errorCode == 0) {
      // return SUCCESS
    }
    // return FAILURE
  }

  // Подтверждение оплаты

  static Future confirm(String otpData, int paymentId) async {
    // OTP DATA: SCANER'DAN OLINADI
    const serviceID = 48951;

    Uri uri = Uri.parse('$_baseUrl/click_pass/confirm');

    var body = {"service_id": serviceID, "payment_id": paymentId};

    http.Response response = await http.delete(
      uri,
      headers: _headers,
      body: body,
    );
    await LogHelper.logRequest(
        method: "DELETE",
        path: uri.toString(),
        statusCode: response.statusCode,
        body: body,
        response: response.body);

    alice.onHttpResponse(response);

    ClickResponseModel click = decodeClickResponseModel(response.body);

    // ignore: unrelated_type_equality_checks
    if (click.errorCode == 0) {
      // return SUCCESS
    }
    // return FAILURE
  }

  // Включение режима подтверждения
  static Future inclusation() async {
    // OTP DATA: SCANER'DAN OLINADI
    const serviceID = 48951;

    const url = '$_baseUrl/click_pass/confirmation/$serviceID';

    Uri uri = Uri.parse(url);

    http.Response response = await http.put(uri, headers: _headers);
    await LogHelper.logRequest(
        method: "PUT",
        path: uri.toString(),
        statusCode: response.statusCode,
        response: response.body);

    alice.onHttpResponse(response);

    ClickResponseModel click = decodeClickResponseModel(response.body);

    // ignore: unrelated_type_equality_checks
    if (click.errorCode == 0) {
      // return SUCCESS
    }
    // return FAILURE
  }

  // Отключение режима подтверждения
  static Future deleteConfirmation() async {
    // OTP DATA: SCANER'DAN OLINADI
    const serviceID = 48951;

    const url = '$_baseUrl/merchant/click_pass/confirmation/$serviceID';

    Uri uri = Uri.parse(url);

    http.Response response = await http.delete(uri, headers: _headers);
    await LogHelper.logRequest(method: "DELETE", path: url.toString(), statusCode: response.statusCode,response: response.body);

    alice.onHttpResponse(response);

    ClickResponseModel click = decodeClickResponseModel(response.body);

    // ignore: unrelated_type_equality_checks
    if (click.errorCode == 0) {
      // return SUCCESS
    }
    // return FAILURE
  }

  /// Submit items OFD
  static Future<ClickResponseModel> submitItems(
    Map<String, dynamic> clickData,
  ) async {
    String path = '/payment/ofd_data/submit_items';
    return await post(path: path, body: clickData);
  }

  /// Send Fiscal receipt
  static Future<ClickResponseModel> sendFiscalReceipt(
    Map<String, dynamic> clickData,
  ) async {
    String path = '/payment/ofd_data/submit_qrcode';
    return await post(path: path, body: clickData);
  }

  static Future<ClickResponseModel> post({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    Log.j(body, name: path);
    ClickResponseModel clickResponse;

    try {
      Uri url = Uri.parse('$_baseUrl$path');
      http.Response response = await http
          .post(
            url,
            body: jsonEncode(body),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));
      await LogHelper.logRequest(method: "POST", path: url.toString(), statusCode: response.statusCode,body: body,response: response.body);

      alice.onHttpResponse(response);

      clickResponse = decodeClickResponseModel(response.body);

      Log.j(clickResponse.toJson(), name: 'Response $path');
      await Pref.setString('epay_Id', clickResponse.paymentId ?? "");
      await Pref.setInt('epayPay_Id', 0064);
      await Pref.setString('epay_phone', clickResponse.phoneNumber ?? "");
      if (clickResponse.errorCode != 0) {
        JsonEncoder encoder = const JsonEncoder.withIndent(' ');
        String prettyJson = encoder.convert(clickResponse.toJson());
        LogRepository.addLog(
          prettyJson,
          where: 'lib/changes/services/payment/click_service.dart',
          file: 'click_service.dart',
          url: _baseUrl,
          method: 'POST',
          path: path,
          statusCode: response.statusCode,
        );
      }

      return clickResponse;
    } catch (err) {
      Log.e(err, name: 'ClickService | ${err.runtimeType}');
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
      clickResponse = ClickResponseModel(
        errorCode: -1,
        errorNote: message,
      );
      JsonEncoder encoder = const JsonEncoder.withIndent(' ');
      String prettyJson = encoder.convert(clickResponse.toJson());
      LogRepository.addLog(
        prettyJson,
        where: '/lib/changes/services/payment/click_service.dart',
        file: 'click_service.dart',
        url: _baseUrl,
        method: 'POST',
        path: path,
        statusCode: 1200,
      );
      return clickResponse;
    }
  }

  static Future<void> sendUnsentReceipts() async {
    List<Map<String, dynamic>> receipts = ClickHelper.clickList;
    if (receipts.isEmpty) return;
    for (var receipt in receipts) {
      ClickResponseModel res = await sendFiscalReceipt(receipt);
      if (res.errorCode == 0) {
        await ClickHelper.deleteItem(receipt['payment_id']);
      }
    }
  }

  // SHA1 GENERATOR
  static Map<String, String> get _headers {
    // MERCHANT USER ID
    final merchantUserId = Pref.getInt(PrefKeys.merchantUserId, -1);

    // DATE TIME NOW
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // SECRET KEY
    final String secretKey = Pref.getString(
      PrefKeys.secretKeyOfClick,
      "not initialized",
    );

    var firstChunk = utf8.encode("$now$secretKey");

    var output = convert.AccumulatorSink<Digest>();
    var input = sha1.startChunkedConversion(output);
    input.add(firstChunk); // call `add` for every chunk of input data
    input.close();

    // GENERATED SHA1
    var digest = output.events.single;

    var headers = {
      "Auth": '$merchantUserId:$digest:$now',
      "Accept": "application/json",
      "Content-type": "application/json"
    };
    return headers;
  }
}
