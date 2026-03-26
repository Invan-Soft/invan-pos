import 'package:invan2/fiscal_service/fiscal.dart';
import '../changes/services/api_state.dart';
import 'model/fiscal_receipt_model.dart';

class ReceiptService {
  // 10.2.2
  const ReceiptService._();

  static Future<Object> sendSaleReceipt(FiscalReceiptModel receipt) async {
    return BaseService.post(receipt.toJson());
  }

  static Future<ApiState> sendCredit() async {
    return await BaseService.post({});
  }

  static Future<ApiState> sendReceipt() async {
    var body = {
      "method": ApiMethods.sendReceipt,
      "id": 25528,
      "params": {"FactoryID": await StorageService.getFactoryID()},
      "jsonrpc": "2.0"
    };
    return await BaseService.post(body);
  }

  static Future<ApiState> getLastRegistered() async {
    var body = {
      "method": ApiMethods.getLastReceipt,
      "id": 455,
      "params": {"FactoryID": await StorageService.getFactoryID()},
      "jsonrpc": "2.0"
    };
    return await BaseService.post(body);
  }

  static Future<ApiState> reScanReceipts() async {
    var body = {
      "method": ApiMethods.reScanReceipts,
      "id": 11772,
      "params": {"FactoryID": await StorageService.getFactoryID()},
      "jsonrpc": "2.0"
    };
    return await BaseService.post(body);
  }

  static Future<ApiState> getReceiptCount() async {
    var body = {
      "id": 62959,
      "jsonrpc": "2.0",
      "method": ApiMethods.getReceiptCount,
      "params": {"FactorID": await StorageService.getFactoryID()},
    };
    return await BaseService.post(body);
  }
}
