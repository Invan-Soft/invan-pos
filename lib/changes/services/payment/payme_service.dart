import 'dart:convert';

import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/api_state.dart';
import 'package:invan2/changes/services/payment/payme/models/item_payme_model.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:http/http.dart' as http;

import '../../../alice_service.dart';
import '../log_helper.dart';

class PaymeGOService {
  static int _statusCode = 0;
  static String _id = '';

  static Future<ApiState> _post({
    required String api,
    required String method,
    required Map<String, dynamic> params,
  }) async {
    const String baseUrl = 'https://checkout.paycom.uz/api';
    Uri url = Uri.parse('$baseUrl$api');

    final String merchantId =
        Pref.getString(PrefKeys.paymeGoMerchantId, "not initialized");
    final String kassaPassword =
        Pref.getString(PrefKeys.paymeGoPassword, "not initialized");

    var headers = {
      "X-Auth": "$merchantId:$kassaPassword",
      "Content-Type": "application/json",
      "Cache-Control": "no-cache"
    };

    int id = Pref.getInt('payme_id', 0);

    var body = {
      "id": id,
      "method": method,
      "params": params,
    };

    try {
      http.Response response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      await LogHelper.logRequest(method: "POST", path: url.toString(), statusCode: response.statusCode,body: body,response: response.body);

      alice.onHttpResponse(response);
      _statusCode = response.statusCode;

      var data = jsonDecode(response.body);
      if (data['result'] != null) {
        var res = data['result'];
        await Pref.setString('p_id', res['receipt']['_id']);
        await Pref.setInt('payme_id', id + 1);
        _addLog(err: res.toString(), success: true, title: "TRY / SUCCESS");
        if (method == "receipts.pay") {
          await Pref.setString('epay_Id', res['receipt']['_id']);
          await Pref.setInt('epayPay_Id', 0141);
          await Pref.setString('epay_phone', res['receipt']['payer']['phone']);
        }
        return Success(
          200,
          res,
        );
      }

      final String errorMessage = data['error']['message'];

      _addLog(err: errorMessage, success: false, title: "TRY / FAILED");

      return Failure(200, errorMessage);
    } catch (err) {
      _addLog(err: err.toString(), success: false, title: "CATCH");
      return Failure(-1, err);
    }
  }

  static Future receiptsCreate(int amount, List<PaymeItem> items) async {
    final String posName = Pref.getString(PrefKeys.posName, "not initialized");
    const String mETHOD = 'receipts.create';
    var params = {
      "amount": amount,
      "description": posName,
      "account": {"order_id": "test"},
      "detail": {
        "discount": {"title": "Скидка 5%", "price": 10000},
        "shipping": {"title": "Доставка до ттз-4 28/23", "price": 500000},
        "items": items.map((e) => e.toJson()).toList()
      }
    };

    return await _post(
      method: mETHOD,
      params: params,
      api: "",
    );
  }

  static Future receiptsPay(String token) async {
    const String method = 'receipts.pay';
    var params = {"id": Pref.getString('p_id', ""), "token": token};
    return await _post(
      method: method,
      params: params,
      api: "",
    );
  }

  static Future setFiscalData({
    int statusCode = 0,
    Info? info,
  }) async {
    return await _post(
      api: "",
      method: "SetFiscalData",
      params: {
        "id": _id,
        "type": "PERFORM",
        "fiscal_data": {
          "receipt_id": info?.id,
          "status_code": statusCode,
          "message": "accepted",
          "terminal_id": info?.terminalId,
          "fiscal_sign": info?.fiscalSign,
          "qr_code_url": info?.qrCodeUrl,
          "date": info?.dateTime,
        }
      },
    );
  }

  static Future setFiscalData2({
    int statusCode = 0,
    Info? info,
  }) async {
    return await _post(
      api: "/api HTTP/1.1",
      method: "receipts.set_fiscal_data",
      params: {
        "id": Pref.getString('p_id', ""),
        "fiscal_data": {
          "receipt_id": int.parse(info?.receiptSeq ?? "0"),
          "qr_code_url": info?.qrCodeUrl,
        }
      },
    );
  }

  static void _addLog({
    required String err,
    required bool success,
    required String title,
  }) {
    LogRepository.addLog(
      err,
      file: 'PAYME',
      success: true,
      method: "POST",
      where: "PAYME SERVICE / $title",
      path: "PAYME",
      statusCode: _statusCode,
    );
  }
}
