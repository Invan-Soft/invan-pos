import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/fiscal_service/fiscal.dart';
import '../alice_service.dart';
import '../changes/services/api_state.dart';

class BaseService {
  const BaseService._();

  static final Uri _url = Uri.parse(AppLinks.baseUrl);
  static const _headers = {'Content-Type': 'application/json'};

  static Future<ApiState> post(
    Map<String, dynamic> body, {
    String? orderBody,
  }) async {
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
      // ===== OFD 10.2.1 DIAGNOSTIKA (vaqtinchalik) — faqat xatoda, qisqa, Telegramga =====
      final String diag = _build1021Diag(body);
      final String logBody = (orderBody != null && orderBody.isNotEmpty)
          ? "$diag\n\nOrder Body == $orderBody\n\nBaseService Body== $body"
          : "$diag\n\nBaseService Body== $body";
      LogRepository.requestSend(failure.errorMessage(),
          file: 'baseservice.dart',
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

  /// OFD §10.2.1 diagnostikasi — fiskal body'dan balansni hisoblab, qisqa
  /// xulosa qaytaradi. Faqat xato log'iga qo'shiladi (Telegram), to'liq body
  /// kesilsa ham bu qisqa qism ko'rinadi. Hech narsani o'zgartirmaydi.
  static String _build1021Diag(Map<String, dynamic> body) {
    try {
      final receipt = body['params']?['Receipt'];
      if (receipt == null) return '⚠️ 10.2.1 DIAG: Receipt yo\'q (method=${body['method']})';
      final items = (receipt['Items'] as List?) ?? const [];
      final num cash = (receipt['ReceivedCash'] as num?) ?? 0;
      final num card = (receipt['ReceivedCard'] as num?) ?? 0;

      num sumPrice = 0, sumOther = 0, sumDiscount = 0, sumVat = 0;
      final problems = StringBuffer();
      int idx = 0;
      for (final it in items) {
        idx++;
        final num price = (it['Price'] as num?) ?? 0;
        final num other = (it['Other'] as num?) ?? 0;
        final num disc = (it['Discount'] as num?) ?? 0;
        final num vat = (it['VAT'] as num?) ?? 0;
        final num vatP = (it['VATPercent'] as num?) ?? 0;
        final num amount = (it['Amount'] as num?) ?? 0;
        sumPrice += price;
        sumOther += other;
        sumDiscount += disc;
        sumVat += vat;

        // 1) PER-ITEM invariant: Other + Discount ≤ Price. Buzilsa modul
        //    chekni "ошибочные параметры" bilan rad etadi — ASOSIY signal.
        if (other + disc - price > 1) {
          problems.writeln(
              '  #$idx ${it['Name']}: ❗OTHER+DISC>PRICE (price=$price, other=$other, disc=$disc)');
        }
        // 2) НДС tekshiruvi: app formulasi vat = (price - other) * vatP/(100+vatP).
        //    (price - disc) EMAS — 100% elektronda other=price bo'lib VAT=0
        //    to'g'ri hisoblanadi, uni bayroqlash false positive edi.
        final num expVat =
            vatP == 0 ? 0 : ((price - other) * vatP / (100 + vatP));
        if ((expVat - vat).abs() > 1) {
          problems.writeln(
              '  #$idx ${it['Name']}: VAT=$vat lekin kut~${expVat.round()} (vatP=$vatP, price=$price, other=$other, disc=$disc)');
        }
        // 3) Kasrli/og'irlik tekshiruvi: price (tiyin) amount ulushiga bo'linmasa
        //    (amount=miqdor*1000). price * 1000 / amount → butun bo'lmasa shubhali.
        if (amount > 0) {
          final double unit = price * 1000 / amount;
          if ((unit - unit.roundToDouble()).abs() > 0.001) {
            problems.writeln(
                '  #$idx ${it['Name']}: KASRLI? price=$price amount=$amount → unit=${unit.toStringAsFixed(3)}');
          }
        }
      }

      final num paid = cash + card + sumOther;
      final num balans = (sumPrice - sumDiscount) - paid;

      final sb = StringBuffer();
      sb.writeln('===== OFD 10.2.1 DIAG =====');
      sb.writeln('items=${items.length}  cash=$cash card=$card');
      sb.writeln(
          'Σprice=$sumPrice Σother=$sumOther Σdisc=$sumDiscount Σvat=$sumVat');
      sb.writeln('Σ(price-disc)=${sumPrice - sumDiscount}  cash+card+Σother=$paid');
      sb.writeln(
          '>>> BALANS_FARQI=$balans ${balans == 0 ? "(OK)" : "❗NOL EMAS — §10.2.1 sababi shu bo'lishi mumkin"}');
      if (problems.isNotEmpty) {
        sb.writeln('Shubhali itemlar:');
        sb.write(problems.toString());
      } else {
        sb.writeln('(itemlar darajasida muammo topilmadi)');
      }
      sb.write('===========================');
      return sb.toString();
    } catch (e) {
      return '⚠️ 10.2.1 DIAG xato: $e';
    }
  }

  static void _addLog(
    String message, {
    String method = '',
    String type = 'FAIL',
  }) {
    LogRepository.addLog(
      message,
      file: 'BaseService eror',
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
