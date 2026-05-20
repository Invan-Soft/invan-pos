// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'package:flutter/foundation.dart';

class Log {
  const Log._();

  static void d(Object? object, {String name = ''}) {
    if (kDebugMode) {
      name = name.isEmpty ? '' : '[$name]';
      String text =
          '\x1B[94m${_getDate()}: \x1B[93m$name \x1B[92m$object\x1B[0m';
    }
  }

  // print errors
  static void e(Object? object, {String name = ''}) {
    if (kDebugMode) {
      name = name.isEmpty ? '' : '[$name]';
      String text =
          '\x1B[94m${_getDate()}: \x1B[93m$name\x1B[91m$object\x1B[0m';
    }
  }

  // Pretty-print JSON
  static void j(Object? object, {String name = ''}) {
    if (kDebugMode) {
      name = name.isEmpty ? '' : '[$name]';
      JsonEncoder encoder = const JsonEncoder.withIndent(' ');
      String prettyJson = encoder.convert(object);
      String text =
          '\x1B[94m${_getDate()}: \x1B[93m$name\n\n\x1B[96m$prettyJson\x1B[0m';
    }
  }

  static formatJson(String json) {
    json = json.replaceAll(RegExp(r'"[]"'), '');
  }

  static String _getDate() {
    DateTime now = DateTime.now();
    String hour = now.hour.toString().padLeft(2, '0');
    String minute = now.minute.toString().padLeft(2, '0');
    String second = now.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
