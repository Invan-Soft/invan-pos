/*
    @author Suxrob Sattorov, 9/19/2025, 1:31 PM
*/

class Scales {
  List<ScalesTemplates>? scalesTemplates;
  int? total;

  Scales({this.scalesTemplates, this.total});

  Scales.fromJson(Map<String, dynamic> json) {
    if (json['scales_templates'] != null) {
      scalesTemplates = <ScalesTemplates>[];
      json['scales_templates'].forEach((v) {
        scalesTemplates!.add(ScalesTemplates.fromJson(v));
      });
    }
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (scalesTemplates != null) {
      data['scales_templates'] =
          scalesTemplates!.map((v) => v.toJson()).toList();
    }
    data['total'] = total;
    return data;
  }
}

class ScalesTemplates {
  String? name;
  List<String>? measurementUnitId;
  String? values;
  String? url;
  String? id;

  ScalesTemplates(
      {this.name, this.measurementUnitId, this.values, this.url, this.id});

  ScalesTemplates.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    measurementUnitId = json['measurement_unit_id'].cast<String>();
    values = json['values'];
    url = json['url'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['measurement_unit_id'] = measurementUnitId;
    data['values'] = values;
    data['url'] = url;
    data['id'] = id;
    return data;
  }
}
