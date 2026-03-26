import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
part 'location.g.dart';

Location locationFromJson(String str) => Location.fromJson(json.decode(str));
String locationToJson(Location data) => json.encode(data.toJson());

@HiveType(typeId: 40)
class Location {
  Location({
    double? latitude,
    double? longitude,
  }) {
    _latitude = latitude;
    _longitude = longitude;
  }

  Location.fromJson(dynamic json) { 
    _latitude = json['Latitude'];
    _longitude = json['Longitude'];
  }
  Location.fromJsonApi(dynamic json) {
    _latitude = json['latitude'];
    _longitude = json['longitude'];
  }

  @HiveField(0)
  double? _latitude;
  @HiveField(1)
  double? _longitude;

  Location copyWith({
    double? latitude,
    double? longitude,
  }) =>
      Location(
        latitude: latitude ?? _latitude,
        longitude: longitude ?? _longitude,
      );

  double? get latitude => _latitude;

  double? get longitude => _longitude;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['Latitude'] = _latitude;
    map['Longitude'] = _longitude;
    return map;
  }

  Map<String, dynamic> toJsonSimple() {
    final map = <String, dynamic>{};
    map['latitude'] = _latitude;
    map['longitude'] = _longitude;
    return map;
  }
}
