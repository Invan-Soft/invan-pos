/*
    @author Suxrob Sattorov, 3/18/2025, 9:10 AM
*/

class MxikUpdates {
  List<MxikCodes>? mxikCodes;

  MxikUpdates({this.mxikCodes});

  MxikUpdates.fromJson(Map<String, dynamic> json) {
    if (json['mxik_codes'] != null) {
      mxikCodes = <MxikCodes>[];
      json['mxik_codes'].forEach((v) {
        mxikCodes!.add(MxikCodes.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (mxikCodes != null) {
      data['mxik_codes'] = mxikCodes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MxikCodes {
  String? newMxik;
  String? oldMxik;
  Package? package;

  MxikCodes({this.newMxik, this.oldMxik, this.package});

  MxikCodes.fromJson(Map<String, dynamic> json) {
    newMxik = json['new_mxik'];
    oldMxik = json['old_mxik'];
    package =
        json['package'] != null ? Package.fromJson(json['package']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['new_mxik'] = newMxik;
    data['old_mxik'] = oldMxik;
    if (package != null) {
      data['package'] = package!.toJson();
    }
    return data;
  }
}

class Package {
  String? packageCode;
  String? packageName;
  String? packageType;

  Package({this.packageCode, this.packageName, this.packageType});

  Package.fromJson(Map<String, dynamic> json) {
    packageCode = json['package_code'];
    packageName = json['package_name'];
    packageType = json['package_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['package_code'] = packageCode;
    data['package_name'] = packageName;
    data['package_type'] = packageType;
    return data;
  }
}
