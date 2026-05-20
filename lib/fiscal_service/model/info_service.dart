import 'package:invan2/fiscal_service/fiscal.dart';
import '../../changes/services/api_state.dart';

class InfoService {
  const InfoService._();
  static Future<ApiState> getFactoryId() async {
    var body = {
      "method": ApiMethods.listFiscalDrives,
      "id": 47360,
      "params": {},
      "jsonrpc": "2.0"
    };

    return await BaseService.post(body);
  }

  static Future<ApiState> getInfo() async {
    var body = {
      "method": "Api.GetInfo",
      "id": 47360,
      "params": {
        "FactoryID": await StorageService.getFactoryID(),
      },
      "jsonrpc": "2.0"
    };
    return await BaseService.post(body);
  }

  static Future<ApiState> getStatus() async {
    var body = {
      "method": "Api.Status",
      "id": 9650,
      "params": {},
      "jsonrpc": "2.0"
    };
    return await BaseService.post(body);
  }

  static Future<ApiState> getUnsentCount() async {
    var body = {
      "method": ApiMethods.getUnsentCount,
      "id": 88736,
      "params": {},
      "jsonrpc": "2.0"
    };
    return await BaseService.post(body);
  }

  static Future<ApiState> resendUnsent() async {
    var body = {
      "method": "Api.ResendUnsent",
      "id": 47360,
      "params": {
        "FactoryID": await StorageService.getFactoryID(),
      },
      "jsonrpc": "2.0"
    };
    return await BaseService.post(body);
  }
}
