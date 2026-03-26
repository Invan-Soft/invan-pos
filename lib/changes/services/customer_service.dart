import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/data/security.dart';
import 'package:invan2/changes/models/feedback_model.dart';
import 'package:invan2/changes/services/app_constants.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';

class CustomerSupportService {
  static sendMessageToTelegram(FeedbackModel message) async {
    String toTelegram = await _messageToTelegram(message);
    try {
      await http
          .get(Uri.parse("${SecureKeys.CUSTOMER_SUPPORT_BOT_LINK}$toTelegram"));
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String> _messageToTelegram(FeedbackModel v) async {
    // 📞🧨🕒📱

    String version = AppConstants.version;

    final String logString = """
<b>🕒 ${v.date}</b>

<b>Message:</b> ${v.message}

<b>Service:</b> ${v.serviceName}
<b>Pos:</b> ${v.posName}
<b>Employee:</b> ${v.employeeName}
<b>Version</b> $version 
""";
    return logString;
  }

  static feedBackToHive(String message) async {
    String date = DateTime.now().toString().substring(0, 16);
    final String posName = Pref.getString(PrefKeys.posName, "not initialized");
    final String orgName =
        Pref.getString(PrefKeys.organizationName, "not initialized");
    final String employeeName =
        Pref.getString(PrefKeys.cashierName, "not initialized");

    Box box = HiveBoxes.getFeedBacks();
    int key = box.length > 0 ? box.length + 1 : 0;
    final FeedbackModel v = FeedbackModel(
        date: date,
        message: message,
        serviceName: orgName,
        posName: posName,
        employeeName: employeeName,
        iV: key);
    bool result = await sendMessageToTelegram(v);
    if (!result) {
      await box.put(key, v);
    }
    sendUnsendMessages();
  }

  static sendUnsendMessages() async {
    Box box = HiveBoxes.getFeedBacks();
    List<FeedbackModel> feedbacks = box.values.cast<FeedbackModel>().toList();
    if (feedbacks.isEmpty) {
      return;
    }
    for (int i = 0; i < feedbacks.length; i++) {
      bool result = await sendMessageToTelegram(feedbacks[i]);
      if (result) {
        box.delete(feedbacks[i].iV);
      }
    }
  }
}
