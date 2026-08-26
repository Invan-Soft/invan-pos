// O'chirilgan mahsulot haqida Telegram kanaliga xabarnoma.
//
// Do'kon egasi kassirlar qanday mahsulotlarni savatdan o'chirayotganini
// kuzatishi uchun. Sotuv oqimiga ta'sir qilmasligi shart: tarmoq xatosi
// yutiladi, javob 200 bo'lmasa faqat log yoziladi.
//
// `OrderingProvider4` dan ko'chirildi (Faza 9.4) — tana o'zgarmagan.

import 'package:http/http.dart' as http;
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class TelegramNotifier {
  const TelegramNotifier._();

  static const String _botToken = '8534579686:AAHuob2SA0ZdnV_emG0kSKmOOoDLdNbvrKQ';
  static const String _channelId = '-1003834151006';

  /// O'chirilgan mahsulot haqida Telegram kanaliga xabar yuboradi.
  /// Xato bo'lsa yutiladi — xabarnoma sotuvni to'xtatmasligi kerak.
  static Future<void> productDeleted({
    required String productName,
    required String productId,
    required String posName,
    required String employeeName,
    required String deleteTime,
    required String productQuantity,
  }) async {
    const String botToken = '8534579686:AAHuob2SA0ZdnV_emG0kSKmOOoDLdNbvrKQ';
    const String channelId = '-1003834151006';
    final String orgName = Pref.getString(PrefKeys.organizationName, "");

    final String message = """
  <b>🚨 Mahsulot o'chirildi!</b>

  <b>Org Name:</b> $orgName
  <b>Product:</b> $productName
  <b>Quantity:</b> $productQuantity
  <b>Pos Name:</b> $posName
  <b>Employee:</b> $employeeName
  <b>Time:</b> $deleteTime
  """
        .trim();

    final Uri url = Uri.parse(
      'https://api.telegram.org/bot$botToken/sendMessage?'
      'chat_id=$channelId'
      '&text=${Uri.encodeComponent(message)}'
      '&parse_mode=HTML',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        await LogHelper.logRequest(
          method: "Sent DeletedProduct To Telegram",
          path: "Ordering4Provider sendToTelegram",
          statusCode: response.statusCode,
          body: '',
          response: response.body,
        );
      }
    } catch (e) {}
  }

  /// Butun chek (savat) bekor qilinganda kanalga xabar yuboradi.
  static Future<void> cartCancelled({
    required String posName,
    required String employeeName,
    required String deleteTime,
    required List<String> productLines,
  }) async {
    final String orgName = Pref.getString(PrefKeys.organizationName, "");

    final String message = """
<b>🚨 Chek o'chirildi!</b>

<b>Org Name:</b> $orgName
<b>Pos Name:</b> $posName
<b>Employee:</b> $employeeName
<b>Time:</b> $deleteTime

<b>Mahsulotlar:</b>
${productLines.join('\n').trim()}
    """
        .trim();

    await _send(message);
  }

  /// Xabarni kanalga yuboradi. Xato yutiladi — xabarnoma sotuvni
  /// to'xtatmasligi kerak.
  static Future<void> _send(String message) async {
    final Uri url = Uri.parse(
      'https://api.telegram.org/bot$_botToken/sendMessage?'
      'chat_id=$_channelId'
      '&text=${Uri.encodeComponent(message)}'
      '&parse_mode=HTML',
    );
    try {
      await http.get(url);
    } catch (e) {}
  }
}
