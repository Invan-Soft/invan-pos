import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

enum LogLevel { trace, debug, info, warn, error }

class LogHelper {
  static Future<void> write(LogLevel level, String message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/request_logs_of_invan_pos.txt');
      // Rolling 24 soatlik oyna boshlangan vaqtni saqlaydigan kichik marker fayl.
      final marker = File('${dir.path}/request_logs_window_start.txt');
      final now = DateTime.now();

      // Oyna boshlanish vaqtini marker fayldan o'qiymiz (fayl kattaligiga bog'liq emas).
      DateTime? windowStart;
      if (await marker.exists()) {
        windowStart = DateTime.tryParse((await marker.readAsString()).trim());
      }

      if (windowStart == null || !await file.exists()) {
        // Yangi oyna: birinchi yozuv yoki marker yo'q.
        windowStart = now;
        await marker.writeAsString(now.toIso8601String());
      } else if (now.difference(windowStart).inHours >= 24) {
        // Oxirgi 24 soatdan ko'p vaqt o'tdi -> tozalab, yangi kunni boshlaymiz.
        await file.writeAsString('', mode: FileMode.write);
        windowStart = now;
        await marker.writeAsString(now.toIso8601String());
      }

      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      final levelStr = level.name.toUpperCase();

      final logLine = 'time="$time" level=$levelStr msg="$message"\n';
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/log_errors.txt');
        await file.writeAsString('Error writing log: $e\n',
            mode: FileMode.append);
      } catch (_) {}
    }
  }

  /// UI / biznes harakatlarini yozish uchun umumiy metod.
  /// Masalan: LogHelper.activity('CART_ADD', {'name': 'Coca', 'qty': 2});
  static Future<void> activity(String action,
      [Map<String, dynamic>? details]) async {
    final buffer = StringBuffer('[ACTIVITY] $action');
    if (details != null && details.isNotEmpty) {
      final parts = details.entries
          .map((e) => '${e.key}=${_short(e.value)}')
          .join(', ');
      buffer.write(' | $parts');
    }
    debugPrint(buffer.toString());
    await write(LogLevel.info, buffer.toString());
  }

  /// Log ichida juda uzun qiymatlarni qisqartirib beradi.
  static String _short(dynamic value, {int max = 300}) {
    final s = value?.toString() ?? 'null';
    if (s.length <= max) return s;
    return '${s.substring(0, max)}…(${s.length})';
  }

  static String truncateWithPadding(String text, int maxLength) {
    if (text.length > maxLength) {
      return text.substring(0, maxLength - 3) + '...';
    } else {
      return text.padRight(maxLength);
    }
  }

  static Future<void> logRequest({
    required String method,
    required String path,
    required int statusCode,
    dynamic body,
    dynamic response,
  }) async {
    if (path.contains("api/v1/category_for_product?limit=500&page=1") ||
        path.contains(
            "api/v1/role_with_permissions?limit=1000&search=&page=1")) {
      return;
    }
    if (path.contains('api/v1/order_pos') && body != null) {
      try {
        final data = body is String ? jsonDecode(body) : body;
        final orderItems = data['order']?[0]['items'] ?? [];

        if (orderItems is List && orderItems.isNotEmpty) {
          String table = '''
+----------+------------------------------------------+------------------+---------+--------------+-----------+
| Number   | Name                                     | Barcode          | Units   | Price        | Discount  |
+----------+------------------------------------------+------------------+---------+--------------+-----------+
''';

          String rows = '';
          int number = 1;
          double totalPrice = 0;
          double totalDiscount = 0;

          for (var item in orderItems) {
            final nameValue =
                truncateWithPadding(item['product_name'] ?? '', 40);
            final barcodeValue =
                truncateWithPadding(item['product_barcode'] ?? '', 16);
            final unitsValue =
                truncateWithPadding(item['value']?.toString() ?? '0', 7);
            final price = (item['price'] ?? 0.0).toDouble();
            final discount = (item['total_discount_price'] ?? 0.0).toDouble();

            totalPrice += price;
            totalDiscount += discount;

            final numberStr = (' ' + number.toString()).padRight(10);
            final nameStr = (' ' + nameValue).padRight(42);
            final barcodeStr = (' ' + barcodeValue).padRight(18);
            final unitsStr = (' ' + unitsValue).padRight(9);
            final priceStr = price.toStringAsFixed(2).padLeft(13) + ' ';
            final discountStr = discount.toStringAsFixed(2).padLeft(10) + ' ';

            rows +=
                '|${numberStr}|${nameStr}|${barcodeStr}|${unitsStr}|${priceStr}|${discountStr}|\n';
            number++;
          }

          rows +=
              '+----------+------------------------------------------+------------------+---------+--------------+-----------+\n';

          final totalsNumberStr = (' ' + "").padRight(10);
          final totalsNameStr = (' ' + "Totals").padRight(42);
          final totalsBarcodeStr = (' ' + "").padRight(18);
          final totalsUnitsStr = (' ' + "").padRight(9);
          final totalsPriceStr =
              totalPrice.toStringAsFixed(2).padLeft(13) + ' ';
          final totalsDiscountStr =
              totalDiscount.toStringAsFixed(2).padLeft(10) + ' ';

          rows +=
              '|${totalsNumberStr}|${totalsNameStr}|${totalsBarcodeStr}|${totalsUnitsStr}|${totalsPriceStr}|${totalsDiscountStr}|\n';

          rows +=
              '+----------+------------------------------------------+------------------+---------+--------------+-----------+\n';

          await write(
              LogLevel.info,
              '[$method] $path\nStatus: $statusCode\n$table$rows'
              'Response: $response');
          return;
        }
      } catch (e) {
        await write(LogLevel.info,
            '[$method] $path\nStatus: $statusCode\nBody: $body\nResponse: $response');
        return;
      }
    }

    final shortLog = '''
[$method] $path
Status: $statusCode
Body: $body
Response: $response
''';
    await write(LogLevel.info, shortLog);
  }
}
