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
        mxikCodes!.add(new MxikCodes.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.mxikCodes != null) {
      data['mxik_codes'] = this.mxikCodes!.map((v) => v.toJson()).toList();
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
        json['package'] != null ? new Package.fromJson(json['package']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['new_mxik'] = this.newMxik;
    data['old_mxik'] = this.oldMxik;
    if (this.package != null) {
      data['package'] = this.package!.toJson();
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['package_code'] = this.packageCode;
    data['package_name'] = this.packageName;
    data['package_type'] = this.packageType;
    return data;
  }
}
