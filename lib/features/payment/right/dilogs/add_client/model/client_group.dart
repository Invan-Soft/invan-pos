class ClientGroupType {
  String? id;
  String? name;
  bool? setAsDef;
  ClientGroupType({this.id, this.name, this.setAsDef});

  ClientGroupType.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['group_name'];
    setAsDef = json['is_default'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['group_name'] = name;
    data['is_default'] = setAsDef;
    return data;
  }
}
