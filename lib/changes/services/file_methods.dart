import 'dart:io';

// import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/repository/log_repository.dart';

// serrr
class FileMethods {
  // static final _chuckerHttpClient = ChuckerHttpClient(http.Client());
  static Future<File?> downloadFile(
    String url,
    String filePath,
    String fileName,
  ) async {
    try {
      final req = await http.get(Uri.parse(url));

      final bytes = req.bodyBytes;

      final path = await _path(filePath);

      File file = File('$path/$fileName');
      await file.writeAsBytes(bytes);

      return file;
    } catch (e) {
      LogRepository.addLog(
        e.toString(),
        where: "FILE METHODS / CATCH",
        method: "WRITE TO FILE",
        file: "FileMethods / downloadFile",
        url: url,
        path: filePath,
      );
      return null;
    }
  }

  static Future<File?> getFile(String filePath, String fileName) async {
    try {
      final path = await _path(filePath);
      return File(path + fileName);
    } catch (e) {
      return null;
    }
  }

  static Future<void> setFile({
    required String filePath,
    required File fileForSet,
    required String fileName,
  }) async {
    try {
      final path = await _path(filePath);
      File file = File('$path/$fileName');
      final f = await fileForSet.readAsBytes();
      await file.writeAsBytes(f);
    } catch (e) {
      return;
    }
  }

  static Future<String> _path(String filePath) async {
    final directory = await Directory(filePath).create();
    return directory.path;
  }
}
