import 'package:hive/hive.dart';

part 'printer_model.g.dart';

/// macOS'da "PDF faylga saqlash" soxta (virtual) printeri uchun maxsus url.
/// Bu real OS printeri emas — tanlansa, chek PDF fayl sifatida papkaga saqlanadi.
/// Faqat macOS'da ko'rsatiladi, Windows va boshqa platformalarga ta'sir qilmaydi.
const String kPdfExportPrinterUrl = 'invan-pdf-export';

@HiveType(typeId: 5)
class PrinterModel extends HiveObject {
  @HiveField(0)
  final String? name;

  @HiveField(1)
  final String? url;

  @HiveField(2)
  final String? model;

  @HiveField(3)
  final String? location;

  @HiveField(4)
  final String? comment;

  @HiveField(5)
  final int? paperSize;

  PrinterModel({
    this.name,
    this.url,
    this.model,
    this.location,
    this.comment,
    this.paperSize,
  });
}
