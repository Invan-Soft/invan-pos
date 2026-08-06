/*
    @author Suxrob Sattorov, 2/11/2025, 9:11 PM
*/

class TasnifResponseModel {
  bool? success;
  int? code;
  dynamic reason;
  List<MxikResponse>? data;
  int? recordTotal;
  dynamic errors;
  bool? permitted;

  TasnifResponseModel(
      {this.success,
      this.code,
      this.reason,
      this.data,
      this.recordTotal,
      this.errors,
      this.permitted});

  TasnifResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    code = json['code'];
    reason = json['reason'];
    if (json['data'] != null) {
      data = <MxikResponse>[];
      json['data'].forEach((v) {
        data!.add(MxikResponse.fromJson(v));
      });
    }
    recordTotal = json['recordTotal'];
    errors = json['errors'];
    permitted = json['permitted'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['code'] = code;
    data['reason'] = reason;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['recordTotal'] = recordTotal;
    data['errors'] = errors;
    data['permitted'] = permitted;
    return data;
  }
}

class MxikResponse {
  String? mxik;
  String? name;
  dynamic description;
  dynamic internalCode;
  int? label;
  int? usePackage;
  int? createdAt;
  int? updateAt;
  List<Packages>? packages;

  MxikResponse(
      {this.mxik,
      this.name,
      this.description,
      this.internalCode,
      this.label,
      this.usePackage,
      this.createdAt,
      this.updateAt,
      this.packages});

  MxikResponse.fromJson(Map<String, dynamic> json) {
    mxik = json['mxik'];
    name = json['name'];
    description = json['description'];
    internalCode = json['internalCode'];
    label = json['label'];
    usePackage = json['usePackage'];
    createdAt = json['createdAt'];
    updateAt = json['updateAt'];
    if (json['packages'] != null) {
      packages = <Packages>[];
      json['packages'].forEach((v) {
        packages!.add(Packages.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mxik'] = mxik;
    data['name'] = name;
    data['description'] = description;
    data['internalCode'] = internalCode;
    data['label'] = label;
    data['usePackage'] = usePackage;
    data['createdAt'] = createdAt;
    data['updateAt'] = updateAt;
    if (packages != null) {
      data['packages'] = packages!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Packages {
  int? code;
  String? mxikCode;
  String? nameUz;
  String? packageType;
  String? nameRu;
  String? nameLat;

  Packages(
      {this.code,
      this.mxikCode,
      this.nameUz,
      this.packageType,
      this.nameRu,
      this.nameLat});

  Packages.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    mxikCode = json['mxikCode'];
    nameUz = json['nameUz'];
    packageType = json['packageType'];
    nameRu = json['nameRu'];
    nameLat = json['nameLat'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['mxikCode'] = mxikCode;
    data['nameUz'] = nameUz;
    data['packageType'] = packageType;
    data['nameRu'] = nameRu;
    data['nameLat'] = nameLat;
    return data;
  }
}
