import 'package:hive/hive.dart';

part 'printer_model.g.dart';

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
