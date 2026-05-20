

class LoginResponseData {
  String? sId;
  String? name;

  LoginResponseData({
    this.sId,
    this.name,
  });

  LoginResponseData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['name'] = name;
    return data;
  }
}
