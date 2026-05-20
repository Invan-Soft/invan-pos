class FromSoliq {
  String? mxik;
  String? name;
  String? description;
  String? internalCode;
  int? label;
  int? usePackage;
  int? createdAt;
  int? updateAt;
  List<Packages>? packages;

  FromSoliq(
      {this.mxik,
      this.name,
      this.description,
      this.internalCode,
      this.label,
      this.usePackage,
      this.createdAt,
      this.updateAt,
      this.packages});

  FromSoliq.fromJson(Map<String, dynamic> json) {
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
    final Map<String, dynamic> data = {};
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
    final Map<String, dynamic> data = {};
    data['code'] = code;
    data['mxikCode'] = mxikCode;
    data['nameUz'] = nameUz;
    data['packageType'] = packageType;
    data['nameRu'] = nameRu;
    data['nameLat'] = nameLat;
    return data;
  }
}
