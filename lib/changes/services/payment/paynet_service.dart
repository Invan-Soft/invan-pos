import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:convert/convert.dart' as convert;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/alice_service.dart';
import 'package:invan2/changes/models/paynet_response_model.dart';
import 'package:invan2/changes/models/epay/e_pay_model.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/utils/helpers/e_pay_helper.dart';
import 'package:invan2/utils/utils.dart';

import '../log_helper.dart';

// =============================================================================
// CHANGELOG (API v1.07):
//
// 1. Base URL o'zgardi:
//    ESKI: https://pass-test.paynet.uz/v2/merchant
//    YANGI: https://pass-test.paynet.uz (test) / https://api.paynet.uz (prod)
//    Endpointlarga /api prefiksi qo'shildi.
//
// 2. Auth header nomi o'zgardi:
//    ESKI: "Auth"
//    YANGI: "AUTH"
//
// 3. Yangi xato kodi qo'shildi:
//    -29: TRANSACTION_ID_ALREADY_EXISTS
//
// 4. merchant_user_id — kassa identifikatori sifatida aniqroq belgilandi.
// =============================================================================

class PaynetService {
  const PaynetService._();

  static int? paymentId;

  // v1.07: Base URL — /v2/merchant olib tashlandi, /api endpoint ichida
  static const String _baseUrlTest = 'https://pass-test.paynet.uz';
  static const String _baseUrlProd = 'https://api.paynet.uz';
  static const String _baseUrl = _baseUrlTest;

  // 1. To'lovni yaratish (Paynet QR)
  // POST /api/paynet-pass/payment
  static Future<PaynetResponseModel> payment({
    required String otpData,
    required num amount,
    required String receiptNumber,
  }) async {
    Log.d('payment() boshlandi — amount: $amount, receipt: $receiptNumber',
        name: 'PaynetService');

    EPayModel? ePayModel = EPayHelper.instance.box.get(EPayEnum.paynet.value);
    final serviceId = int.tryParse(ePayModel?.serviceId ?? '') ?? 0;

    var body = {
      "service_id": serviceId,
      "otp_data": otpData,
      "amount": amount,
      // "transaction_id": receiptNumber,
    };

    Log.j(body, name: 'PaynetService | payment body');

    PaynetResponseModel result = await _post(
      path: '/api/paynet-pass/payment',
      body: body,
    );

    if (result.errorCode == 0) {
      paymentId = result.paymentId;
      Log.d('payment() muvaffaqiyatli — payment_id: $paymentId',
          name: 'PaynetService');
    } else if (result.errorCode == -29) {
      // v1.07: Yangi xato — transaction_id allaqachon mavjud
      Log.e(
          'payment() — TRANSACTION_ID_ALREADY_EXISTS: receiptNumber=$receiptNumber',
          name: 'PaynetService');
    } else {
      Log.e(
          'payment() xato — error_code: ${result.errorCode}, note: ${result.errorNote}',
          name: 'PaynetService');
    }

    return result;
  }

  // 2. To'lov statusini tekshirish (payment_id bo'yicha)
  // GET /api/paynet-pass/payment/status/by-payment-id/{service_id}/{payment_id}
  static Future<PaynetResponseModel> checkPaymentStatus(int pid) async {
    Log.d('checkPaymentStatus() — payment_id: $pid', name: 'PaynetService');

    EPayModel? ePayModel = EPayHelper.instance.box.get(EPayEnum.paynet.value);
    final serviceId = int.tryParse(ePayModel?.serviceId ?? '') ?? 0;

    // v1.07: /api prefiksi qo'shildi
    final url =
        '$_baseUrl/api/paynet-pass/payment/status/by-payment-id/$serviceId/$pid';
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

      Log.d('checkPaymentStatus() response: ${response.body}',
          name: 'PaynetService');

      return decodePaynetResponseModel(response.body);
    } catch (err) {
      Log.e(err, name: 'PaynetService | checkPaymentStatus');
      return PaynetResponseModel(errorCode: -1, errorNote: err.toString());
    }
  }

  // 3. To'lov statusini tekshirish (transaction_id bo'yicha) — YANGI ENDPOINT
  // GET /api/payment/status/by-transaction-id/{service_id}/{transaction_id}
  static Future<PaynetResponseModel> checkPaymentStatusByTransactionId(
      String transactionId) async {
    Log.d('checkPaymentStatusByTransactionId() — transaction_id: $transactionId',
        name: 'PaynetService');

    EPayModel? ePayModel = EPayHelper.instance.box.get(EPayEnum.paynet.value);
    final serviceId = int.tryParse(ePayModel?.serviceId ?? '') ?? 0;

    final url =
        '$_baseUrl/api/payment/status/by-transaction-id/$serviceId/$transactionId';
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

      Log.d('checkPaymentStatusByTransactionId() response: ${response.body}',
          name: 'PaynetService');

      return decodePaynetResponseModel(response.body);
    } catch (err) {
      Log.e(err, name: 'PaynetService | checkPaymentStatusByTransactionId');
      return PaynetResponseModel(errorCode: -1, errorNote: err.toString());
    }
  }

  // 4. To'lovni bekor qilish (reversal)
  // DELETE /api/paynet-pass/payment/reversal/{service_id}/{payment_id}
  static Future<PaynetResponseModel> reversalPayment(int pid) async {
    Log.d('reversalPayment() — payment_id: $pid', name: 'PaynetService');

    EPayModel? ePayModel = EPayHelper.instance.box.get(EPayEnum.paynet.value);
    final serviceId = int.tryParse(ePayModel?.serviceId ?? '') ?? 0;

    // v1.07: /api prefiksi qo'shildi
    final url =
        '$_baseUrl/api/paynet-pass/payment/reversal/$serviceId/$pid';
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

      Log.d('reversalPayment() response: ${response.body}',
          name: 'PaynetService');

      return decodePaynetResponseModel(response.body);
    } catch (err) {
      Log.e(err, name: 'PaynetService | reversalPayment');
      return PaynetResponseModel(errorCode: -1, errorNote: err.toString());
    }
  }

  // 5. To'lovni tasdiqlash (confirm mode)
  // POST /api/paynet-pass/payment/confirm
  static Future<PaynetResponseModel> confirm(int pid) async {
    Log.d('confirm() — payment_id: $pid', name: 'PaynetService');

    EPayModel? ePayModel = EPayHelper.instance.box.get(EPayEnum.paynet.value);
    final serviceId = int.tryParse(ePayModel?.serviceId ?? '') ?? 0;

    final body = {"service_id": serviceId, "payment_id": pid};

    return _post(
      path: '/api/paynet-pass/payment/confirm',
      body: body,
    );
  }

  // 5.2. Confirm rejimini yoqish
  // PUT /api/paynet-pass/confirmation/{service_id}
  static Future<PaynetResponseModel> enableConfirmMode() async {
    EPayModel? ePayModel = EPayHelper.instance.box.get(EPayEnum.paynet.value);
    final serviceId = int.tryParse(ePayModel?.serviceId ?? '') ?? 0;

    final url = '$_baseUrl/api/paynet-pass/confirmation/$serviceId';
    final uri = Uri.parse(url);

    try {
      http.Response response = await http
          .put(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      await LogHelper.logRequest(
        method: "PUT",
        path: url,
        statusCode: response.statusCode,
        response: response.body,
      );
      alice.onHttpResponse(response);

      return decodePaynetResponseModel(response.body);
    } catch (err) {
      Log.e(err, name: 'PaynetService | enableConfirmMode');
      return PaynetResponseModel(errorCode: -1, errorNote: err.toString());
    }
  }

  // 5.2. Confirm rejimini o'chirish
  // DELETE /api/paynet-pass/confirmation/{service_id}
  static Future<PaynetResponseModel> disableConfirmMode() async {
    EPayModel? ePayModel = EPayHelper.instance.box.get(EPayEnum.paynet.value);
    final serviceId = int.tryParse(ePayModel?.serviceId ?? '') ?? 0;

    final url = '$_baseUrl/api/paynet-pass/confirmation/$serviceId';
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

      return decodePaynetResponseModel(response.body);
    } catch (err) {
      Log.e(err, name: 'PaynetService | disableConfirmMode');
      return PaynetResponseModel(errorCode: -1, errorNote: err.toString());
    }
  }

  // 6. Fiskal chekni yuborish (OFD)
  // POST /api/paynet-pass/ofd-data/submit-qrcode
  static Future<PaynetResponseModel> sendFiscalReceipt({
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
      path: '/api/paynet-pass/ofd-data/submit-qrcode',
      body: body,
    );

    if (result.errorCode == 0) {
      Log.d('sendFiscalReceipt() muvaffaqiyatli', name: 'PaynetService');
    } else {
      Log.e(
          'sendFiscalReceipt() xato: ${result.errorCode} — ${result.errorNote}',
          name: 'PaynetService');
    }

    return result;
  }

  // ==================== ICHKI YORDAMCHI METODLAR ====================

  static Future<PaynetResponseModel> _post({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    Log.j(body, name: 'PaynetService | POST $path');
    PaynetResponseModel result;

    try {
      final uri = Uri.parse('$_baseUrl$path');
      final headers = _headers;
      final bodyStr = jsonEncode(body);

      Log.d(
        '\n\ncurl -X POST \'$uri\' \\\n'
        '  -H \'AUTH: ${headers["AUTH"]}\' \\\n'
        '  -H \'Accept: application/json\' \\\n'
        '  -H \'Content-type: application/json\' \\\n'
        '  -d \'$bodyStr\'\n',
        name: 'PaynetService | CURL',
      );

      print('========== PAYNET REQUEST ==========');
      print('URL    : $uri');
      print('AUTH   : ${headers["AUTH"]}');
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
        result = decodePaynetResponseModel(response.body);
        return result;
      }

      result = PaynetResponseModel(
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
      result = PaynetResponseModel(errorCode: -1, errorNote: message);
      LogRepository.addLog(
        '{"error_code": -1, "error_note": "$message"}',
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

  // v1.07: Auth → AUTH (katta harf)
  // Format: merchant_user_id:sha1(timestamp+secret_key):timestamp
  static Map<String, String> get _headers {
    EPayModel? ePayModel = EPayHelper.instance.box.get(EPayEnum.paynet.value);

    final merchantUserId = ePayModel?.merchantUserId ?? '';
    final secretKey = ePayModel?.secretKey ?? '';

    print(
        'PAYNET _headers → merchantUserId: "$merchantUserId" | secretKey: "${secretKey.isEmpty ? "BO\'SH!" : secretKey.substring(0, secretKey.length.clamp(0, 8))}..." | model null: ${ePayModel == null}');

    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var chunk = utf8.encode('$now$secretKey');
    var output = convert.AccumulatorSink<Digest>();
    var input = sha1.startChunkedConversion(output);
    input.add(chunk);
    input.close();
    var digest = output.events.single;

    return {
      // v1.07: "Auth" → "AUTH"
      "AUTH": '$merchantUserId:$digest:$now',
      "Accept": "application/json",
      "Content-type": "application/json",
    };
  }
}

// =============================================================================
// Xato kodlari (v1.07 — to'liq ro'yxat)
// =============================================================================
// payment_status | error_code | Konstanta              | Tavsif
// ---------------------------------------------------------------------------
//  0             |  0         | —                      | To'lov yaratildi
//  1             |  0         | —                      | Jarayonda
//  2             |  0         | —                      | Muvaffaqiyatli
// -2             | -2         | INVALID_REQUEST        | Noto'g'ri so'rov
// -3             | -3         | OTP_DATA_VERIFY_ERROR  | OTP xato/eskirgan
// -4             | -4         | USER_NOT_FOUND         | Foydalanuvchi topilmadi
// -5             | -5         | CARD_NOT_FOUND         | Karta topilmadi
// -6             | -6         | TRANSACTION_NOT_FOUND  | Tranzaksiya topilmadi
// -7             | -7         | TRANSACTION_NOT_VALID  | Tranzaksiya yaroqsiz
// -8             | -8         | CARD_TYPE_NOT_ALLOWED  | Karta turi qo'llab-quvvatlanmaydi
// -9             | -9         | MERCHANT_NOT_FOUND     | Merchant topilmadi
// -10            | -10        | DEBIT_ERROR            | Hisobdan yechish xatosi
// -11            | -11        | PAYMENT_ERROR          | Umumiy to'lov xatosi
// -12            | -12        | AUTHORIZE_CONFIRM_ERROR| Tasdiqlash xatosi
// -13            | -13        | PTS_INFO_ERROR         | PTS ma'lumot xatosi
// -14            | -14        | TOO_MANY_REQUEST       | So'rovlar limiti oshdi
// -15            | -15        | USED_OTP_DATA          | OTP allaqachon ishlatilgan
// -16            | -16        | OFD_ERROR              | Fiskalizatsiya xatosi
// -17            | -17        | REVERSE_ERROR          | Bekor qilish xatosi
// -18            | -18        | REVERSE_OK             | Ilgari bekor qilingan
// -19            | -19        | ACCESS_DENIED          | Kirish taqiqlangan
// -20            | -20        | UNAUTHORIZED           | Autentifikatsiya xatosi
// -21            | -21        | BIND_ERROR             | Validatsiya xatosi
// -22            | -22        | METHOD_ARGUMENT_NOT_VALID | Argument validatsiya xatosi
// -23            | -23        | USER_NOT_ACTIVE        | Foydalanuvchi faol emas
// -24            | -24        | INVALID_TIMESTAMP      | Noto'g'ri vaqt belgisi
// -25            | -25        | API_NOT_FOUND          | API topilmadi
// -26            | -26        | METHOD_NOT_ALLOWED     | Metod qo'llab-quvvatlanmaydi
// -27            | -27        | POS_NOT_FOUND          | POS terminal topilmadi
// -28            | -28        | POS_NOT_ACTIVE         | POS terminal faol emas
// -29            | -29        | TRANSACTION_ID_ALREADY_EXISTS | (YANGI v1.07) transaction_id allaqachon mavjud
// =============================================================================