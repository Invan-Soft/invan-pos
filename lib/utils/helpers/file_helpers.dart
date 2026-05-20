/*
    @author Suxrob Sattorov, 9/19/2025, 1:10 PM
*/

import 'dart:io';

import 'package:flutter/foundation.dart';

class FileHelpers {
  static Future<bool> saveFileFromUrl({
    required String url,
    required String dirPath,
    required String fileName,
  }) async {
    try {
      final dir = Directory(dirPath);

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final filePath = '$dirPath\\$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();

      final sink = file.openWrite();
      await response.forEach((chunk) {
        sink.add(chunk);
      });
      await sink.close();

      return true;
    } catch (e) {
      debugPrint("Fayl saqlashda xato: $e");
      return false;
    }
  }
}
