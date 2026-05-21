// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/models/ofd/incom_response_model.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/services/api.dart';
import 'package:invan2/changes/services/api_state.dart';
import 'package:invan2/changes/services/app_constants.dart';
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/changes/services/payment/click_service.dart';
import 'package:invan2/changes/services/payment/payme_service.dart';
import 'package:invan2/changes/services/payment/paynet_service.dart';
import 'package:invan2/changes/services/payment/uzum_service.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import '../../alice_service.dart';
import '../../fiscal_service/fiscal.dart';
import '../../fiscal_service/model/fiscal_receipt_model.dart';
import '../../fiscal_service/model/last_receipt_model.dart/last_receipt_model.dart';
import '../../fiscal_service/model/location/location.dart';
import '../../fiscal_service/model/receipt_data_model.dart';
import '../../fiscal_service/model/request_receipt_model.dart';
import '../models/product/item_model.dart';

class LocalService {
  static int _statusCode = 0;
  static const Duration _duration = Duration(seconds: 30);
  static final Uri _url = Uri.parse(AppConstants.localhost);

  static String errorMessage = '';
  // static String cleanMarkForFiscal(String rawMark) {
  //   if (rawMark.trim().isEmpty) return rawMark;

  //   String clean = rawMark
  //       .replaceAll(RegExp(r'[\x1D\x1E\x1F]'), '')
  //       .replaceAll(RegExp(r'\(\d{2}\)'), '');


  //   final match = RegExp(r'(01\d{14}21[^0-9].*?)(?=\d{2}|$)').firstMatch(clean);
  //   if (match != null) {
  //     final result = match.group(1)!;
  //     return result;
  //   }

  //   return clean;
  // }
static String cleanMarkForFiscal(String rawMark) {
  if (rawMark.trim().isEmpty) return rawMark;

  String clean = rawMark
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
      .replaceAll(RegExp(r'\(\d{2,3}\)'), '');

  // 01+14raqam+21 topamiz, keyin belgilarni 93 kelguncha olamiz
  final match = RegExp(r'(01\d{14}21.*?)(?=93)').firstMatch(clean);
  
  if (match != null) return match.group(1)!;

  return clean;
}
  static Future<CommunicatorRESPONSE> sell({
    required AppLocalizations loc,
    required dynamic receiptData,
  }) async {
    Map<String, dynamic> body;
    if (receiptData is ReceiptModel4) {
      body = ReceiptSingleton4.saleOnOFD(receiptData);
    } else {
      body = receiptData;
    }
    var data;

    try {
      http.Response response = http.Response('Error', 500);
      var decoded = "";
      if (Pref.getBool(PrefKeys.withINCOM, false)) {
        response = await http
            .post(
              _url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(_duration);
        await LogHelper.logRequest(
            method: "POST",
            path:"LocalService sell function $_url.toString()",
            statusCode: response.statusCode,
            body: body,
            response: response.body);
        alice.onHttpResponse(response);
        decoded = utf8.decode(response.bodyBytes);
        _statusCode = response.statusCode;
        data = jsonDecode(decoded);
      } else {
        var saleWithOutIncomBody = await saleWithOutIncom(
          body: body,
        ).timeout(_duration);

        data = saleWithOutIncomBody;

        if (data['error']) {
          errorMessage = data['message'];
        } else {
          errorMessage = '';
        }
      }

      if (!data['error']) {
        CommunicatorRESPONSE res = CommunicatorRESPONSE.fromJson(data);
        // Agar to'lovda CLICK PASSdan foydalanilsa, Receiptni CLICK ka jo'natish kerak
        if (body['params']['receivedClick']) {
          var clickData = ReceiptSingleton4.fromReceipt4ToClick(receipt: body);
          ClickService.sendFiscalReceipt({
            'service_id': clickData['service_id'],
            'payment_id': clickData['payment_id'],
            'qrcode': res.info?.qrCodeUrl,
          });
        }

        // Agar to'lovda Uzum Passdan foydalanilsa, Receiptni Uzumga ka jo'natish kerak
        if (body['params']['receivedUzum']) {
          await UzumService.sendFiscalReceipt({
            'payment_id': UzumService.paymentId.toString(),
            'fiscal_url': res.info?.qrCodeUrl,
          });
        }

        // Agar to'lovda Paynet (Pass yoki QR) dan foydalanilsa, fiskal chekni Paynетга jo'natish kerak
        if (body['params']['receivedPaynet'] == true) {
          final pid = PaynetService.paymentId ?? 0;
          final qrcode = res.info?.qrCodeUrl ?? '';
          final address = Pref.getString(PrefKeys.serviceAddress, "");
          print('======= Paynet sendFiscalReceipt | pid: $pid | qrcode: $qrcode | address: $address =======');
          PaynetService.sendFiscalReceipt(
            pid: pid,
            qrcode: qrcode,
            salePointAddress: address,
          );
          PaynetService.paymentId = null;
        }

        // Agar to'lovda Payme Godan foydalanilsa, Receiptni Paymega ka jo'natish kerak
        if (body['params']['receivedPayme']) {
          PaymeGOService.setFiscalData2(
            info: res.info,
            statusCode: 0,
          );
        }
        LogRepository.addLog(
          """RESPONSE BODY: $decoded
        headers: => {'Content-Type': 'application/json'}, REQUEST BODY: => ", """,
          file: "LocalService / sell",
          method: "POST",
          where: "LOCAL SALING / TRY / SUCCESS",
          path: "LocaleService communicator response",
          statusCode: response.statusCode,
          success: true,
          url: AppConstants.localhost,
        );

        Pref.setInt('epayPay_Id', 0);
        Pref.setString('epay_Id', "");
        Pref.setString('epay_phone', "");

        return res;
      }
      final failedErrorMsg = errorMessage.isNotEmpty
          ? errorMessage
          : (decoded.isNotEmpty ? decoded : 'Unknown error');

      LogRepository.addLog(
        failedErrorMsg,
        method: "POST",
        path: AppConstants.localhost,
        where: "LOCAL SALING / TRY / FAILED",
        statusCode: _statusCode,
        url: AppConstants.localhost,
        file: 'LocalService / sell /',
      );

      LogRepository.requestSend(
        failedErrorMsg,
        method: "POST",
        path: AppConstants.localhost,
        where: "LOCAL SALING / TRY / FAILED",
        file: 'LocalService / sell /',
        statusCode: _statusCode,
        url: AppConstants.localhost,
        body: body['params']['items'].map((e) => e).toList().toString(),
      );

      MxikError? mxikError = _checkForMxikError(response);
      return CommunicatorRESPONSE()
        ..mxikError = mxikError
        ..paycheck = errorMessage.isNotEmpty ? errorMessage : _sintezERROR(decoded)
        ..error = true
        ..info = null;
    } on SocketException catch (_) {
      return CommunicatorRESPONSE()
        ..error = true
        ..info = null
        ..paycheck = loc.komunikator_ishlamaypti;
    } on TimeoutException catch (e) {
      return CommunicatorRESPONSE()
        ..error = true
        ..info = null
        ..paycheck = e.toString();
    } catch (e) {
      Log.e(e, name: 'local_selling_service');
      LogRepository.addLog(
        e.toString(),
        method: "POST",
        path: "Local Saling catch metod",
        where: "LOCAL SALING / CATCH ",
        statusCode: _statusCode,
        url: AppConstants.localhost,
        file: 'LocalService /  / catch',
      );
      return CommunicatorRESPONSE()
        ..error = true
        ..info = null
        ..paycheck = errorMessage.isNotEmpty ? errorMessage : e.toString();
    }
  }

  /// Sale Method
  static Future saleWithOutIncom({var body}) async {
    final RequestSaleModel model = RequestSaleModel.fromJson(body);

    final String factoryID = await StorageService.getFactoryID();
    final terminalID = await BaseService.getTerminalID();
    double lat = Pref.getDouble(PrefKeys.lat, 41);
    double long = Pref.getDouble(PrefKeys.long, 69);

    Location location = Location(
      latitude: lat,
      longitude: long,
    );
    if (Pref.getBool(PrefKeys.locationSwitch, false)) {
      double latLocal = Pref.getDouble(PrefKeys.latLocal, 41);
      double longLocal = Pref.getDouble(PrefKeys.longLocal, 69);
      location = Location(
        latitude: latLocal,
        longitude: longLocal,
      );
    }
    ReceiptDataModel dataModel = ReceiptDataModel(
      factoryID: factoryID,
      terminalID: terminalID,
      location: location,
    );
    DateTime dateTime = await AppFormatter.getTimeZoneTime();
    // var extraInfo = ExtraInfo(
    //   carNumber: "",
    //   phoneNumber: body['params']['externalInfo']['phoneNumber'],
    //   cardType: body['params']['externalInfo']['cardType'],
    //   pinfl: "",
    //   tin: "",
    //   qrPaymentID: body['params']['externalInfo']['qrPaymentID'],
    //   qrPaymentProvider: int.parse(
    //     body['params']['externalInfo']['qrPaymentProvider'] ?? 0,
    //   ),
    // );
    var extraInfo = ExtraInfo(
      carNumber: "",
      phoneNumber: body['params']['externalInfo']['phoneNumber'] ?? '',
      cardType: body['params']['externalInfo']['cardType'],
      pinfl: "",
      tin: "",
      qrPaymentID: body['params']['externalInfo']['qrPaymentID'] ?? '',
      qrPaymentProvider: int.tryParse(
        body['params']['externalInfo']['qrPaymentProvider']?.toString() ?? '0',
      ) ?? 0,

      // ==================== YANGI QO‘SHILGAN MAYDONLAR ====================
      cardNumber: body['params']['externalInfo']['cardNumber'] ?? '',
      pptId: body['params']['externalInfo']['pptId'] ??
          body['params']['externalInfo']['RRN'] ??
          body['params']['externalInfo']['PPTID'] ?? '',                     // RRN / PPTID
      cashedOutFromCard: body['params']['externalInfo']['cashedOutFromCard'] ?? 0,
      // ==================================================================
    );
    FiscalReceiptModel receiptModel = FiscalReceiptModel.fromRequest(
      model,
      dataModel,
      dateTime,
      extraInfo,
    );
    ApiState state = await BaseService.post(
      receiptModel.toJson(),
      orderBody: jsonEncode(body),
    );

    if (state is Success) {
      
      LastReceiptModel returned = LastReceiptModel.fromJson(
        state.decodeResult(),
      );

      var jsonItem = model.params?.items
          ?.map((e) => ItemInfo(
                barcode: e.barcode,
                id: e.id,
                mxikCode: e.classCode,
                packageCode: e.packageCode,
                packageName: e.packageName,
              ))
          .toList();
      return {
        "error": false,
        "paycheck": "JVBERi0xLjcKJeLjz9MKNSAwIG9iago8PC9GaW",
        "info": returned.toJson(),
        "method": receiptModel.method,
        'items': jsonItem,
      };
    }
    state = state as Failure;
    return ReturnFiscalMessage.sendError(state.errorMessage());
  }

/////  SEND ITEMS
  static Future sendUpdateItems(
    List<ItemModel> list, {
    String method = "updateMxikByBarcode",
  }) async {
    List<Map<String, dynamic>> mxiks = [];
    for (var item in list) {
      mxiks.add({
        "mxik": item.mxikCode,
        "barcode": item.barcode,
        "id": item.id,
      });
    }

    try {
      http.Response response = await http
          .post(
            _url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
              {
                'method': method,
                "body": mxiks,
              },
            ),
          )
          .timeout(_duration);

      return jsonDecode(response.body)['info'];
    } catch (e) {
      return Log.d(e);
    }
  }

////  get labels with mxik
  static Future getLabelsItemWithMxik(
    List<ItemModel> list, {
    String method = "getLabelsMxik",
  }) async {
    List<Map<String, dynamic>> mxiks = [];
    for (var item in list) {
      mxiks.add({
        "mxik": item.mxikCode,
        "barcode": item.barcode,
        "id": item.id,
      });
    }

    try {
      http.Response response = await http
          .post(
            _url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
              {
                'method': method,
                "body": mxiks,
              },
            ),
          )
          .timeout(_duration);

      return jsonDecode(response.body)['labes'];
    } catch (e) {
      return Log.d(e);
    }
  }

/////  get labels
  static Future getLabelsItem(
    List<ItemModel> list, {
    String method = "getLabels",
  }) async {
    List<Map<String, dynamic>> mxiks = [];
    for (var item in list) {
      mxiks.add({
        "mxik": item.mxikCode,
        "barcode": item.barcode,
        "id": item.id,
      });
    }

    try {
      http.Response response = await http
          .post(
            _url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
              {
                'method': method,
                "body": mxiks,
              },
            ),
          )
          .timeout(_duration);

      return jsonDecode(response.body)['labes'];
    } catch (e) {
      return Log.d(e);
    }
  }

/////
  static String _sintezERROR(String v) {
    try {
      return jsonDecode(v)['message'];
    } catch (e) {
      return v;
    }
  }

  static MxikError? _checkForMxikError(http.Response res) {
    MxikError? v;
    try {
      v = MxikError.fromJson(jsonDecode(res.body));
    } catch (e) {
      v = null;
    }
    if (v != null) {
      if (v.message != null && v.message!.isNotEmpty) {
        return v;
      }
      return null;
    }
    return v;
  }

  static Future<CommunicatorRESPONSE> checkLocalMxikList(
      {required List<ReceiptModelSoldItem4> list}) async {
    try {
      http.Response response = await http
          .post(
            _url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'method': 'checkMxikList',
              'body': list
                  .map(
                    (e) => {
                      "name": e.productName,
                      "classCode": e.mxik,
                      "barcode": e.barcode,
                    },
                  )
                  .toList()
            }),
          )
          .timeout(_duration);

      final decoded = utf8.decode(response.bodyBytes);

      _statusCode = response.statusCode;
      var data = jsonDecode(decoded);

      if (!data['error']) {
        CommunicatorRESPONSE res = CommunicatorRESPONSE(
          error: false,
          paycheck: 'feko',
        );
        LogRepository.addLog(
          """RESPONSE BODY: $decoded
        headers: => {'Content-Type': 'application/json'}, REQUEST BODY: => ", """,
          file: "LocalService / sell",
          method: "POST",
          where: "LOCAL SALING / TRY / SUCCESS",
          path: "455 LocalService Communicator response",
          statusCode: response.statusCode,
          success: true,
          url: AppConstants.localhost,
        );
        return res;
      }

      MxikError? mxikError = _checkForMxikError(response);

      return CommunicatorRESPONSE()
        ..mxikError = mxikError
        ..paycheck = _sintezERROR(decoded)
        ..error = true
        ..info = null;
    } on TimeoutException catch (e) {
      return CommunicatorRESPONSE()
        ..error = true
        ..info = null
        ..paycheck = e.toString();
    } catch (e) {
      Log.e(e, name: 'local_selling_service');
      LogRepository.addLog(
        e.toString(),
        method: "POST",
        path: "480 communicator response",
        where: "LOCAL SALING / CATCH ",
        statusCode: _statusCode,
        url: AppConstants.localhost,
        file: 'LocalService / sell / catch',
      );
      return CommunicatorRESPONSE()
        ..error = true
        ..info = null
        ..paycheck = e.toString();
    }
  }

  ///// Get Module Info

  static Future<CommunicatorRESPONSE> getModulInfo() async {
    try {
      http.Response response = await http
          .post(
            _url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'method': 'getInfoModul',
              'body': Pref.getString(PrefKeys.terminalID, '')
            }),
          )
          .timeout(_duration);

      final decoded = utf8.decode(response.bodyBytes);

      _statusCode = response.statusCode;
      var data = jsonDecode(decoded);

      if (!data['error']) {
        CommunicatorRESPONSE res = CommunicatorRESPONSE(
          error: false,
          paycheck: 'feko',
        );
        LogRepository.addLog(
          """RESPONSE BODY: $decoded
        headers: => {'Content-Type': 'application/json'}, REQUEST BODY: => ", """,
          file: "LocalService / sell",
          method: "POST",
          where: "LOCAL SALING / TRY / SUCCESS",
          path: "524 communicator response",
          statusCode: response.statusCode,
          success: true,
          url: AppConstants.localhost,
        );

        return res;
      }
      MxikError? mxikError = _checkForMxikError(response);

      return CommunicatorRESPONSE()
        ..mxikError = mxikError
        ..paycheck = _sintezERROR(decoded)
        ..error = true
        ..info = null;
    } on TimeoutException catch (e) {
      return CommunicatorRESPONSE()
        ..error = true
        ..info = null
        ..paycheck = e.toString();
    } catch (e) {
      Log.e(e, name: 'local_selling_service');
      LogRepository.addLog(
        e.toString(),
        method: "POST",
        path: "549 local selling response",
        where: "LOCAL SALING / CATCH ",
        statusCode: _statusCode,
        url: AppConstants.localhost,
        file: 'LocalService / sell / catch',
      );
      return CommunicatorRESPONSE()
        ..error = true
        ..info = null
        ..paycheck = e.toString();
    }
  }
}
