// ignore_for_file: unused_local_variable

import 'package:flutter/foundation.dart' show kDebugMode;

class DebugPrint {
  static void printf(Object object) {
    if (kDebugMode) print(object);
  }

  static void highlight(String w, Object object) {
      if (kDebugMode) {
      DateTime now = DateTime.now();
      String time = '${now.hour}:${now.minute}:${now.second}';
      String text = '\x1B[95m$time:\x1B[96m$w:\x1B[0m \x1B[95m$object\x1B[0m';
    }
  }
}
