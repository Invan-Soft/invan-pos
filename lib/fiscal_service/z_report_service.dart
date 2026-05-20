import 'package:invan2/fiscal_service/fiscal.dart';
import '../changes/services/api_state.dart';

class ZReportService {
  const ZReportService._();
  // 10.1.1
  static Future<ApiState> getZReportCount() async {
    var body = {
      "method": ApiMethods.zReportCount,
      "id": 68934,
      "params": {"FactoryID": await StorageService.getFactoryID()},
      "jsonrpc": "2.0"
    };
    return await BaseService.post(body);
  }

  // 10.1.2
  static Future<ApiState> getZReportInfo({required int number}) async {
    var body = {
      "method": "Api.GetZReportInfo",
      "id": 70076,
      "jsonrpc": "2.0",
      "params": {
        "FactoryID": await StorageService.getFactoryID(),
        "Number": number
      },
    };
    return BaseService.post(body);
  }

  // 10.1.3
  static Future<ApiState> getZReportByNo({required int number}) async {
    var body = {
      "method": ApiMethods.getZReportByNo,
      "id": 70076,
      "jsonrpc": "2.0",
      "params": {
        "FactoryID": await StorageService.getFactoryID(),
        "Number": number
      },
    };
    return BaseService.post(body);
  }

  // 10.1.4
  static Future<ApiState> getZReportsStats() async {
    var body = {
      "method": ApiMethods.getZReportStats,
      "id": 68934,
      "params": {"FactoryID": await StorageService.getFactoryID()},
      "jsonrpc": "2.0"
    };

    return await BaseService.post(body);
  }

  static Future<ApiState> sendZReportByNo(int no) async {
    var body = {
      "method": ApiMethods.sendZReportByNo,
      "id": 99550,
      "params": {
        "FactoryID": await StorageService.getFactoryID(),
        "Number": no
      },
      "jsonrpc": "2.0"
    };
    return await BaseService.post(body);
  }

  static Future<ApiState> sendZReport(int no) async {
    var body = {
      "method": ApiMethods.sendZReport,
      "id": 99550,
      "params": {
        "FactoryID": await StorageService.getFactoryID(),
        "Number": no
      },
      "jsonrpc": "2.0"
    };
    return await BaseService.post(body);
  }
}
