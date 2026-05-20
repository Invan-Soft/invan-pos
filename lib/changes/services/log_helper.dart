import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

enum LogLevel { trace, debug, info, warn, error }

class LogHelper {
  static Future<void> write(LogLevel level, String message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/request_logs_of_invan_pos.txt');

      if (await file.exists()) {
        final fileStats = await file.stat();
        final lastModified = fileStats.modified;
        final now = DateTime.now();
        final difference = now.difference(lastModified).inDays;

        if (difference >= 1) {
          await file.writeAsString('', mode: FileMode.write);
        }
      }

      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
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
