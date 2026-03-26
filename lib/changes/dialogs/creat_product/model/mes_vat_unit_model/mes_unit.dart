import 'package:hive/hive.dart';
import '../../../../../features/hive_repository/hive_types.dart';

part 'mes_unit.g.dart';

@HiveType(typeId: HiveTypes.vatUnitAdapter)
class VatUnitModel extends HiveObject {
  @override
  get key => id;
  @HiveField(0)
  String? id;
  @HiveField(1)
  bool? isDefault;
  @HiveField(2)
  String? name;
  @HiveField(3)
  int? percentage;

  VatUnitModel({
    this.id,
    this.isDefault,
    this.name,
    this.percentage,
  });

  VatUnitModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    isDefault = json['is_default'];
    name = json['name'];
    percentage = json['percentage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['is_default'] = isDefault;
    data['name'] = name;
    data['percentage'] = percentage;
    return data;
  }
}

@HiveType(typeId: HiveTypes.mesUnitModel)
class MesUnitModel extends HiveObject {
  @override
  get key => id;
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? shortName;
  @HiveField(2)
  String? longName;
  @HiveField(3)
  int? percentage;

  MesUnitModel({
    this.id,
    this.shortName,
    this.longName,
    this.percentage,
  });

  MesUnitModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    shortName = json['short_name'];
    longName = json['long_name'];
    percentage = json['percentage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['percentage'] = percentage;
    return data;
  }
}
