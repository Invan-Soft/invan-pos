import 'package:hive_flutter/hive_flutter.dart';

part 'organization_model.g.dart';

@HiveType(typeId: 35)
class OrganizationModel {
  @HiveField(0)
  String? ibt;
  @HiveField(1)
  String? id;
  @HiveField(2)
  String? legalAddress;
  @HiveField(3)
  String? legalName;
  @HiveField(4)
  String? name;
  @HiveField(5)
  String? taxPayerId;
  @HiveField(6)
  String? zipCode;
  @HiveField(7)
  bool? autoGenerate;
  @HiveField(8)
  bool? soliqValidation;
  @HiveField(9)
  bool? companyActive;

  // Not stored in Hive — parsed fresh from API response each login/sync
  bool? appsApp;

  OrganizationModel({
    this.ibt,
    this.id,
    this.legalAddress,
    this.legalName,
    this.name,
    this.taxPayerId,
    this.zipCode,
    this.autoGenerate,
    this.soliqValidation,
    this.companyActive,
    this.appsApp,
  });

  OrganizationModel.fromJson(Map<String, dynamic> json) {
    ibt = json['ibt'];
    id = json['id'];
    legalAddress = json['legal_address'];
    legalName = json['legal_name'];
    name = json['name'];
    taxPayerId = json['tax_payer_id'];
    zipCode = json['zip_code'];
    autoGenerate = json['auto_generate'];
    soliqValidation = json['apps_soliq_validation'];
    companyActive = json['is_company_active'];
    appsApp = json['apps_soliq_app'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['ibt'] = ibt;
    data['id'] = id;
    data['legal_address'] = legalAddress;
    data['legal_name'] = legalName;
    data['name'] = name;
    data['tax_payer_id'] = taxPayerId;
    data['zip_code'] = zipCode;
    data['auto_generate'] = autoGenerate;
    data['apps_soliq_validation'] = soliqValidation;
    data['is_company_active'] = companyActive;
    return data;
  }
}

// @HiveType(typeId: 35)
// class OrganizationModel {
//   OrganizationModel({
//     this.inn,
//     this.services,
//     this.language,
//     this.loyaltyBonus,
//     this.ndsValue,
//     this.address,
//     this.isServiceCreated,
//     this.isVerify,
//     this.payments,
//     // this.cashBack,
//     this.isOfd,
//     this.directorName,
//     this.accaunter,
//     this.orgPhoneNumber,
//     this.taxesPairCode,
//     this.id,
//     this.name,
//     this.updatedAt,
//   });

//   @HiveField(0)
//   String? inn;

//   @HiveField(1)
//   List<String>? services;

//   @HiveField(2)
//   String? language;

//   @HiveField(3)
//   num? loyaltyBonus;

//   @HiveField(4)
//   num? ndsValue;

//   @HiveField(5)
//   String? address;

//   @HiveField(6)
//   bool? isServiceCreated;

//   @HiveField(7)
//   bool? isVerify;

//   @HiveField(8)
//   List<Payment>? payments;

//   // @HiveField(9)
//   // List<dynamic>? workgroupComments;

//   // @HiveField(10)
//   // List<CashBack>? cashBack;

//   @HiveField(11)
//   bool? isOfd;

//   @HiveField(12)
//   String? directorName;

//   @HiveField(13)
//   String? accaunter;

//   @HiveField(14)
//   String? orgPhoneNumber;

//   @HiveField(15)
//   String? taxesPairCode;

//   @HiveField(16)
//   String? id;

//   @HiveField(17)
//   String? name;

//   @HiveField(18)
//   DateTime? updatedAt;

//   factory OrganizationModel.fromJson(Map<String, dynamic> json) =>
//       OrganizationModel(
//         inn: json["inn"],
//         services: List<String>.from(json["services"].map((x) => x)),
//         language: json["language"],
//         loyaltyBonus: json["loyalty_bonus"],
//         ndsValue: json["nds_value"],
//         address: json["address"],
//         isServiceCreated: json["is_service_created"],
//         isVerify: json["is_verify"],
//         payments: List<Payment>.from(
//             json["payments"].map((x) => Payment.fromJson(x))),
//         // workgroupComments:
//         //     List<dynamic>.from(json["workgroup_comments"].map((x) => x)),
//         // cashBack: List<CashBack>.from(
//         //     json["cash_back"].map((x) => CashBack.fromJson(x))),
//         isOfd: json["is_ofd"],
//         directorName: json["director_name"],
//         accaunter: json["accaunter"],
//         orgPhoneNumber: json["org_phone_number"],
//         taxesPairCode: json["taxes_pair_code"],
//         id: json["_id"],
//         name: json["name"],
//         updatedAt: updatedAtFromJson(json["updatedAt"]),
//       );

//   Map<String, dynamic> toJson() => {
//         "inn": inn,
//         "services": List<dynamic>.from(services!.map((x) => x)),
//         "language": language,
//         "loyalty_bonus": loyaltyBonus,
//         "nds_value": ndsValue,
//         "address": address,
//         "is_service_created": isServiceCreated,
//         "is_verify": isVerify,
//         "payments": List<dynamic>.from(payments!.map((x) => x.toJson())),
//         // "workgroup_comments":
//         //     List<dynamic>.from(workgroupComments!.map((x) => x)),
//         // "cash_back": List<dynamic>.from(cashBack!.map((x) => x.toJson())),
//         "is_ofd": isOfd,
//         "director_name": directorName,
//         "accaunter": accaunter,
//         "org_phone_number": orgPhoneNumber,
//         "taxes_pair_code": taxesPairCode,
//         "_id": id,
//         "name": name,
//         "updatedAt": updatedAt?.toIso8601String(),
//       };
//   static DateTime? updatedAtFromJson(String? v) {
//     DateTime? d;
//     try {
//       d = DateTime.parse(v!);
//     } catch (e) {
//       d = null;
//     }
//     return d;
//   }
// }

@HiveType(typeId: 37)
class Payment {
  Payment({
    this.name,
    this.id,
    this.title,
    this.enable,
    this.isAdded,
    this.merchantId,
    this.merchantUserId,
    this.password,
    this.secretKey,
    this.serviceId,
    this.type,
    this.value,
  });

  @HiveField(0)
  String? name;
  @HiveField(1)
  String? title;
  @HiveField(2)
  bool? enable;
  @HiveField(3)
  bool? isAdded;
  @HiveField(4)
  String? id;
  @HiveField(5)
  String? merchantId;
  @HiveField(6)
  String? merchantUserId;
  @HiveField(7)
  String? secretKey;
  @HiveField(8)
  int? serviceId;
  @HiveField(9)
  String? password;
  @HiveField(10)
  int? type;
  @HiveField(11)
  double? value;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        name: json["name"],
        title: json["title"],
        enable: json["enable"],
        isAdded: json["is_added"],
        id: json["id"],
        password: json["password"],
        merchantId: json["merchant_id"],
        merchantUserId: json["merchant_user_id"],
        secretKey: json["secret_key"],
        serviceId: json["service_id"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "title": title,
        "enable": enable,
        "id": id,
        "is_added": isAdded,
        "password": password,
        "merchant_id": merchantId,
        "merchant_user_id": merchantUserId,
        "secret_key": secretKey,
        "service_id": serviceId,
      };
}
