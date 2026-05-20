class ReturnedItem {
  String? id;
  String? barcode;
  String? mxikcode;
  String? packageCode;
  String? packageName;
  

  ReturnedItem({
    this.id,
    this.barcode,
    this.mxikcode,
    this.packageCode,
    this.packageName,
  });

  ReturnedItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    barcode = json['barcode'];
    mxikcode = json['mxikcode'];
    packageCode = json['packageCode'];
    packageName = json['packageName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['barcode'] = barcode;
    data['mxikCode'] = mxikcode;
    data['packageCode'] = packageCode;
    data['packageName'] = packageName;

    return data;
  }
}
