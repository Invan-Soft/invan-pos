import 'package:hive_flutter/hive_flutter.dart';
part 'feedback_model.g.dart';

@HiveType(typeId: 34)
class FeedbackModel extends HiveObject {
  @override
  get key => iV;
  @HiveField(0)
  String? message;
  @HiveField(1)
  String? date;
  @HiveField(2)
  String? serviceName;
  @HiveField(3)
  String? posName;
  @HiveField(4)
  String? employeeName;
  @HiveField(5)
  int? iV;
  FeedbackModel({
    this.date,
    this.employeeName,
    this.message,
    this.posName,
    this.serviceName,
    this.iV,
  });
}
