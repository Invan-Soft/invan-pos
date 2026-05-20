import 'package:hive/hive.dart';

import '../../../features/hive_repository/hive_types.dart';

part 'soliq_mxik_model.g.dart';

@HiveType(typeId: HiveTypes.markingProducts)
class SoliqMxikModel extends HiveObject {
  @HiveField(0)
  final String mxik;

  @HiveField(1)
  final String mxikNameUz;

  @HiveField(2)
  final String mxikNameRu;

  @HiveField(3)
  final String mxikNameLat;

  @HiveField(4)
  final String internationalCode;

  @HiveField(5)
  final int usePackage;

  @HiveField(6)
  final List<dynamic> packages;

  SoliqMxikModel({
    required this.mxik,
    required this.mxikNameUz,
    required this.mxikNameRu,
    required this.mxikNameLat,
    required this.internationalCode,
    required this.usePackage,
    required this.packages,
  });

  factory SoliqMxikModel.fromMap(Map<String, dynamic> item) {
    return SoliqMxikModel(
      mxik: (item['mxik'] as String?)?.trim() ?? '',
      mxikNameUz: item['mxikNameUz'] ?? '',
      mxikNameRu: item['mxikNameRu'] ?? '',
      mxikNameLat: item['mxikNameLat'] ?? '',
      internationalCode: item['internationalCode'] ?? '',
      usePackage: item['usePackage'] ?? 0,
      packages: item['packages'] ?? [],
    );
  }
}