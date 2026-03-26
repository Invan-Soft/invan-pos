import 'dart:math' as math;
class AppFormatter {
  const AppFormatter._();
  static String tiynToSum(num price) {
    num result = price / 100;
    return '$result';
  }

  static DateTime? toDateFromString(String date) {
    date = date.replaceAll(RegExp(r'[^0-9,.]+'), '');
    if (date.length < 14) return null;
    int y = int.parse(date.substring(0, 4));
    int mm = int.parse(date.substring(4, 6));
    int d = int.parse(date.substring(6, 8));
    int h = int.parse(date.substring(8, 10));
    int m = int.parse(date.substring(10, 12));
    int s = int.parse(date.substring(12, 14));
    DateTime dateTime = DateTime(y, mm, d, h, m, s);
    return dateTime;
  }

  static String formatTime(DateTime time, {String? format}) {
    int y = time.year;
    String mm = time.month.toString().padLeft(2, '0');
    String d = time.day.toString().padLeft(2, '0');
    String h = time.hour.toString().padLeft(2, '0');
    String m = time.minute.toString().padLeft(2, '0');
    String s = time.second.toString().padLeft(2, '0');

    switch (format) {
      case 'table':
        return '$d/$mm/$y $h:$m:$s';
      case 'calendar':
        return '$d-$mm-$y $h:$m';
    }

    return '$y-$mm-$d $h:$m:$s';
  }

  static String formatQRUrl(String url) {
    return url.replaceAll('\\u0026', '&');
  }

  static String mapToString(Map? map, {bool withKey = false}) {
    if (map == null) return "";
    if (map.isEmpty) return '';
    var key = map.keys.first;

    return withKey ? '$key: ${map[key] ?? ''}' : '${map[key] ?? ''}';
  }

  static String formatDateFromMills(int mills) =>
      formatTime(DateTime.fromMillisecondsSinceEpoch(mills));

  static int formatDateFromStringToMills(String date) =>
      (toDateFromString(date) ?? DateTime.now()).millisecondsSinceEpoch;

  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static Future<DateTime> getTimeZoneTime() async {
    DateTime now = DateTime.now();
    // DateTime now = await DateService().getDate();
    int timeZoneOffset = now.timeZoneOffset.inHours;
    if (timeZoneOffset != 5) {
      if (timeZoneOffset > 5) {
        now = now.subtract(Duration(hours: timeZoneOffset - 5));
      } else {
        now = now.add(Duration(hours: 5 - timeZoneOffset));
      }
    }
    return now;
  }
}
