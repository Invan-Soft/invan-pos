import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';

class LogOutService {
  static int statusCode = -1;
  static Future<bool> logOut() async {
    final acceptId = Pref.getString(PrefKeys.acceptService, "not initialized");
    Map<String, String> header = {
      "accept-id": acceptId,
      'Accept-Version': '1.0.0',
    };
    HttpResult httpResult =
        await ApiProvider.getResponse(path: "logging/out", headers: header);

    return httpResult.isSuccess;
  }
}

class ResHeadModel {
  int? statusCode;
  String? error;
  String? message;
  ResHeadModel({this.error, this.message, this.statusCode});
  ResHeadModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['code'];
    message = json['data'];
    error = json['error'];
  }
}
