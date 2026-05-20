import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/models/log/log_model.dart';
import 'package:invan2/changes/services/api_state.dart';
import 'package:invan2/changes/services/app_constants.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LogService {
  static Future<ApiState> sendToTelegramm(LogModel log, String? botLink,
      {bool withBody = false}) async {
    try {
      List<String> messages =
          withBody ? await logToString2(log) : [await logToString(log)];

      for (String message in messages) {
        Uri url = Uri.parse("$botLink${Uri.encodeComponent(message)}");

        http.Response response = await http.get(url);
        if (response.statusCode != 200) {
          return Failure(101, response.body);
        }
      }
      return Success(200, "All messages sent");
    } catch (err) {
      return Failure(100, err.toString());
    }
  }

  static Future<String> logToString(LogModel log) async {
    // 📞🧨🕒📱

    const String mode = kDebugMode ? 'debug' : 'release';
    String approach = Pref.getBool(PrefKeys.withOFD, false) ? "OFD" : "SIMPLE";
    final String posName = Pref.getString(PrefKeys.posName, "not initialized");
    final String orgName =
        Pref.getString(PrefKeys.organizationName, "not initialized");

    String? path = log.path?.replaceAll(RegExp(r'[#&+<]'), '-');

    String version = await getAppVersion() ?? '1.1.1';

    final String logString = """
<b>${log.dateTime.toString().substring(0, 19)} Version: $version $mode</b>

<b>Approach:</b> $approach
<b>Employee:</b> ${_r(log.userName)}
<b>URL:</b> ${_r(log.url)}
<b>Path:</b> $path
<b>METHOD:</b> ${log.method}
<b>Status Code:</b> ${_r((log.statusCode ?? 0).toString())}
<b>File:</b> ${_r(log.file)}
<b>Error:</b> ${_r(log.message)}
<b>Device:</b> ${_r(log.phone)}
<b>Pos Name:</b> $posName
<b>Org Name:</b> $orgName
<b>Type:</b> ${log.type! ? "SUCCESS" : "FAIL"}

<b>Check number:</b> ${log.checkNo ?? ''}
<b>Created date:</b> ${log.createdDate ?? ''}
""";

    return logString;
  }

  static Future<List<String>> logToString2(LogModel log) async {
    String formattedBody;
    try {
      formattedBody = jsonEncode(jsonDecode(log.body ?? ''));
    } catch (e) {
      formattedBody = log.body ?? '';
    }

    formattedBody =
        "${log.checkNo ?? ''}\n${log.createdDate ?? ''}\n\n$formattedBody";

    List<String> messages = [await logToString(log)];

    if (formattedBody.length > 4000) {
      for (int i = 0; i < formattedBody.length; i += 4000) {
        messages.add(
            "<pre>${formattedBody.substring(i, i + 4000 > formattedBody.length ? formattedBody.length : i + 4000)}</pre>");
      }
    } else {
      messages.add("<pre>$formattedBody</pre>");
    }

    return messages;
  }

  static String _r(String? v) {
    return v?.replaceAll("<", "^").replaceAll("&", "^") ?? "-";
  }

  static Future<String?> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      if (kDebugMode) {
        print('Error reading version: $e');
      }
    }
    return null;
  }
}
