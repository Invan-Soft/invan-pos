class MxikError {
  bool? error;
  List<NoMxikItem>? message;

  MxikError({this.error, this.message});

  MxikError.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    if (json['message'] != null) {
      message = <NoMxikItem>[];
      json['message'].forEach((v) {
        message!.add(NoMxikItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['error'] = error;
    if (message != null) {
      data['message'] = message!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class NoMxikItem {
  String? name;
  String? barode;
  String? classCode;

  NoMxikItem({this.name, this.barode, this.classCode});

  NoMxikItem.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    barode = json['barcode'];
    classCode = json['classCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['barcode'] = barode;
    data['classCode'] = classCode;
    return data;
  }
}
