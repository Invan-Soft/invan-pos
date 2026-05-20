import 'dart:io';
import 'package:invan2/changes/services/file_methods.dart';

class FilePrinterImage {
  static Future<File?> downloadPrinterImage(String url) async {
    File? file = await FileMethods.downloadFile(
      url,
      'C:\\ProgramData\\InVanPos2\\cache\\',
      'printing_image.png',
    );

    return file;
  }

  static Future<bool> deletePrinterImage() async {
    try {
      final file =
          File("C:\\ProgramData\\InVanPos2\\cache\\printing_image.png");
      await file.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<File?> getPrinterImage() async {
    try {
      File? file = await FileMethods.getFile(
        'C:\\ProgramData\\InVanPos2\\cache\\',
        'printing_image.png',
      );

      return file;
    } catch (e) {
      return null;
    }
  }
}
