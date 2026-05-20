// ignore_for_file: use_build_context_synchronously
import '../changes/repository/log_repository.dart';
import '../changes/services/api_state.dart';
import 'fiscal.dart';

class PostMethods {
  const PostMethods._();
  static Future openZReport() async {
    ApiState s = await ZReportService.getZReportCount();
    if (s is Success) {
      int count = s.decodeResult()['Count'];
      if (count >= 800) {
        LogRepository.addLog('Z Report limit is over',
            where: 'fiscal open z report');
        return ReturnFiscalMessage.sendError('Z Report limit is over');
      }
    } else if (s is Failure) {
      return ReturnFiscalMessage.sendError(s.errorMessage());
    }
    var body = {
      "id": 7530,
      "method": ApiMethods.openZReport,
      "jsonrpc": "2.0",
      "params": {
        "FactoryID": await StorageService.getFactoryID(),
        "Time": AppFormatter.formatTime(await AppFormatter.getTimeZoneTime()),
      }
    };
    ApiState state = await BaseService.post(body);
    if (state is Success) {
      return ReturnFiscalMessage.sendSuccess();
    }
    state = state as Failure;
    return ReturnFiscalMessage.sendError(state.errorMessage());
  }

  static Future closeZReport() async {
    var body = {
      "id": 7530,
      "method": ApiMethods.closeZReport,
      "jsonrpc": "2.0",
      "params": {
        "FactoryID": await StorageService.getFactoryID(),
        "Time": AppFormatter.formatTime(await AppFormatter.getTimeZoneTime()),
      }
    };
    ApiState state = await BaseService.post(body);
    if (state is Success) {
      return ReturnFiscalMessage.sendSuccess();
    }
    state = state as Failure;
    return ReturnFiscalMessage.sendError(state.errorMessage());
  }



  // static Future sale({var body}) async {
  //   final RequestSaleModel model = RequestSaleModel.fromJson(body);
  // ApiState localState = await InfoService.getInfo();
  // if (localState is Success) {
  //   FiscalInfoModel moduleResult = FiscalInfoModel.fromJson(
  //     localState.decodeResult(),
  //   );
  //   if (moduleResult.terminalID != model.otherInfo?.terminalID) {
  //     return ReturnFiscalMessage.sendError(
  //         'Пожалуйста, используйте модуль, прикрепленный к вам');
  //   }
  // }
  //   if (localState is Failure) {
  //     return ReturnFiscalMessage.sendError(localState.errorMessage());
  //   }
  //   // List<MxikModel> mxikList =
  //   //     model.params!.items!.map((e) => MxikModel.fromPOS(e.toJson())).toList();
  //   // List<MxikModel> checkedMxik = MxikHelper.checkMxikList(mxikList);
  //   // final Box<MxikModel> box = HiveBoxes.mxikBox;
  //   // if (checkedMxik.isNotEmpty) {
  //   //   List<Map<String, dynamic>> mxiks =
  //   //       checkedMxik.map((e) => e.toJson()).toList();
  //   //   if (AppPref.getMxikMode() == true) {
  //   //     for (var i in checkedMxik) {
  //   //       for (var j in box.values) {
  //   //         if (i.getBarcode == j.getBarcode) {
  //   //           for (int k = 0; k < model.params!.items!.length; k++) {
  //   //             if (model.params!.items![k].barcode == j.getBarcode) {
  //   //               model.params!.items![k].setClassCode = j.getMxik;
  //   //               mxiks.removeWhere((map) =>
  //   //                   map['barcode'] == model.params!.items![k].barcode);
  //   //             }
  //   //           }
  //   //         }
  //   //       }
  //   //     }
  //   //   }
  //   //   if (mxiks.isNotEmpty) {
  //   //     LogRepository.addLog(
  //   //       'Undefined MXIK codes $mxiks',
  //   //       file: 'post methods',
  //   //       path: '',
  //   //     );
  //   //     return ReturnFiscalMessage.sendError(mxiks, mxikError: true);
  //   //   }
  //   // }
  //   // for (var j in box.values) {
  //   //   for (int k = 0; k < model.params!.items!.length; k++) {
  //   //     if (j.getMxik == model.params!.items![k].classCode) {
  //   //       model.params!.items![k].setPackageCode =
  //   //           j.packages?.first.code.toString();
  //   //       model.params!.items![k].setPackageName =
  //   //           j.packages?.first.nameUz.toString();
  //   //     }
  //   //   }
  //   // }
  //   final String factoryID = await StorageService.getFactoryID();
  //   final terminalID = await BaseService.getTerminalID();
  //   final Location? location = AppPref.posDevice?.service?.location;
  //   ReceiptDataModel dataModel = ReceiptDataModel(
  //     factoryID: factoryID,
  //     terminalID: terminalID,
  //     location: location,
  //   );

  //   DateTime dateTime = await AppFormatter.getTimeZoneTime();

  //   var extraInfo = ExtraInfo(
  //     carNumber: "",
  //     phoneNumber: body['params']['externalInfo']['phoneNumber'],
  //     pinfl: "",
  //     tin: "",
  //     qrPaymentID: body['params']['externalInfo']['qrPaymentID'],
  //     qrPaymentProvider: int.parse(
  //       body['params']['externalInfo']['qrPaymentProvider'] ?? 0,
  //     ),
  //   );

  //   ReceiptModel receiptModel = ReceiptModel.fromRequest(
  //     model,
  //     dataModel,
  //     dateTime,
  //     extraInfo,
  //   );

  //   ApiState state = await BaseService.post(receiptModel.toJson());

  //   if (state is Success) {
  //     LastReceiptModel returned = LastReceiptModel.fromJson(
  //       state.decodeResult(),
  //     );
  //     PrintingReceiptModel printing = PrintingReceiptModel(
  //       items: receiptModel.params?.receipt?.items ?? [],
  //       receipt: returned,
  //       totalCard: model.params?.receivedCard ?? 0.0,
  //       totalCash: model.params?.receivedCash ?? 0.0,
  //     );

  //     if (AppPref.shop != null) {
  //       if (AppPref.shop?.isAuto ?? false) {
  //         PrintingService(printing: printing).printReceipt();
  //       }
  //     }

  //     var jsonItem = model.params?.items
  //         ?.map((e) => ReturnedItem(
  //               barcode: e.barcode,
  //               id: e.id,
  //               mxikcode: e.classCode,
  //               packageCode: e.packageCode,
  //               packageName: e.packageName,
  //             ))
  //         .toList();

  //     return {
  //       "error": false,
  //       "paycheck": "JVBERi0xLjcKJeLjz9MKNSAwIG9iago8PC9GaW",
  //       "info": returned.toJson(),
  //       "method": receiptModel.method,
  //       'items': jsonItem,
  //     };
  //   }

  //   state = state as Failure;

  //   return ReturnFiscalMessage.sendError(state.errorMessage());
  // }

  // static Future<Map> getCheckMxikList(var body) async {
  //   List<MxikModel> mxiks =
  //       (body['body'] as List).map((e) => MxikModel.fromPOS(e)).toList();
  //   List<MxikModel> checkedMxik = MxikHelper.checkMxikList(mxiks);

  //   List<Map<String, dynamic>> mxikList =
  //       checkedMxik.map((e) => e.toJson()).toList();

  //   final Box<MxikModel> box = HiveBoxes.mxikBox;
  //   if (checkedMxik.isNotEmpty) {
  //     if (AppPref.getMxikMode() == true) {
  //       for (var i in checkedMxik) {
  //         for (var j in box.values) {
  //           if (j.getLabel != 0) {}
  //           if (i.getBarcode == j.getBarcode && i.getBarcode != '') {
  //             for (int k = 0; k < mxiks.length; k++) {
  //               if (mxiks[k].getBarcode == j.getBarcode) {
  //                 mxiks[k].setMxik = j.getMxik;
  //                 mxikList.removeWhere(
  //                     (map) => map['barcode'] == mxiks[k].getBarcode);
  //               }
  //             }
  //           }
  //         }
  //       }
  //     }

  //     if (mxikList.isNotEmpty) {
  //       LogRepository.addLog(
  //         'Undefined MXIK codes $mxikList',
  //         file: 'post methods',
  //         path: '',
  //       );

  //       return ReturnFiscalMessage.sendError(mxikList, mxikError: true);
  //     } else {
  //       return ReturnFiscalMessage.sendSuccess();
  //     }
  //   }
  //   if (mxikList.isNotEmpty) {
  //     LogRepository.addLog(
  //       'Undefined MXIK codes $mxikList',
  //       file: 'post methods',
  //       path: '',
  //     );

  //     return ReturnFiscalMessage.sendError(mxikList, mxikError: true);
  //   }
  //   return ReturnFiscalMessage.sendSuccess();
  // }

  // static Future getZReportStatus() async {
  //   ApiState state = await ZReportService.getZReportInfo(number: 0);
  //   if (state is Success) {
  //     ZReportInfoModel info = zReportInfoFromJson(state.response.toString());

  //     if (info.result!.openTime!.isNotEmpty) {
  //       return ReturnFiscalMessage.sendSuccess();
  //     }
  //     return ReturnFiscalMessage.sendError('not opened');
  //   }
  //   state = state as Failure;
  //   return ReturnFiscalMessage.sendError(state.errorMessage());
  // }

  // static Future<Map> checkMxikList(dynamic body) async {
  //   ApiState state;

  //   if (body['method'] == 'updateMxikByBarcode') {
  //     state = await MxikService.getMxikByBarcode(body['body']);
  //   } else {
  //     state = await MxikService.checkMxikList(
  //       mxiks: (body['body'] as List).map((e) => e['mxik'].toString()).toList(),
  //     );
  //   }

  //   bool isList = state.response is List;

  //   return {
  //     "error": state is Failure,
  //     "info": isList ? state.response : [],
  //   };
  // }

  // static Future<Map> getInfo(dynamic terId) async {
  //   ApiState state;
  //   state = await InfoService.getInfo();
  //   bool isList = state.response is List;
  //   if (state is Success) {
  //     FiscalInfoModel moduleRes = FiscalInfoModel.fromJson(
  //       state.decodeResult(),
  //     );
  //     if (moduleRes.terminalID != terId['body']) {
  //       return {
  //         "error": true,
  //         "info": [],
  //       };
  //     }
  //   }
  //   return {
  //     "error": state is Failure,
  //     "info": isList ? state.response : [],
  //   };
  // }

  // static Future<Map> getLabes(dynamic body) async {
  //   List<dynamic> body2 = body['body'];
  //   final Box<MxikModel> box = HiveBoxes.mxikBox;
  //   List<Map<String, dynamic>> maped = [];
  //   for (var barcode in body2) {
  //     for (var item in box.values) {
  //       if (item.getBarcode == barcode['barcode'] && barcode['barcode'] != "") {
  //         maped.add({'barcode': item.getBarcode, 'label': item.getLabel});
  //       }
  //     }
  //   }

  //   return {
  //     "error": false,
  //     "labes": maped,
  //   };
  // }

  // static Future<Map> getLabesWithMxik(dynamic body) async {
  //   ApiState state;
  //   List<dynamic> body2 = body['body'];
  //   List<Map<String, dynamic>> maped2 = [];
  //   for (var barcode in body2) {
  //     state = await MxikService.getEditigOnceMxiks(barcode['mxik']);

  //     MxikLabel label =
  //         MxikLabel.fromJson(state.response as Map<String, dynamic>);

  //     if (label.success == true) {
  //       maped2.add({'mxik': label.data?.mxikCode, 'label': label.data?.label});
  //     }
  //   }

  //   return {
  //     "error": false,
  //     "labes": maped2,
  //   };
  // }
}
