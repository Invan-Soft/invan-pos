class ServiceModel {
  String? sId;
  String? typeOfBusiness;
  String? type;
  String? address;
  bool? isShop;
  String? phoneNumber;
  String? description;
  int? serviceValue;
  String? locationName;
  int? count;
  String? imageUrl;
  String? name;
  String? organization;
  int? iV;
  String? updatedAt;
  String? serviceId;

  ServiceModel({
    this.sId,
    this.typeOfBusiness,
    this.type,
    this.address,
    this.isShop,
    this.phoneNumber,
    this.description,
    this.serviceValue,
    this.locationName,
    this.count,
    this.imageUrl,
    this.name,
    this.organization,
    this.iV,
    this.updatedAt,
    this.serviceId,
  });

  ServiceModel.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    // location = json['location'] != null
    //     ? new Location.fromJson(json['location'])
    //     : null;
    typeOfBusiness = json['type_of_business'];
    type = json['type'];
    address = json['address'];
    isShop = json['is_shop'];
    phoneNumber = json['phone_number'];
    description = json['description'];
    serviceValue = json['service_value'];
    locationName = json['location_name'];
    count = json['count'];
    imageUrl = json['image_url'];
    name = json['name'];
    organization = json['organization'];
    iV = json['__v'];
    updatedAt = json['updatedAt'];
    serviceId = json['service_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = sId;
    // if (this.location != null) {
    // data['location'] = this.location!.toJson();
    // }
    data['type_of_business'] = typeOfBusiness;
    data['type'] = type;
    data['address'] = address;
    data['is_shop'] = isShop;
    data['phone_number'] = phoneNumber;
    data['description'] = description;
    data['service_value'] = serviceValue;
    data['location_name'] = locationName;
    data['count'] = count;
    data['image_url'] = imageUrl;
    data['name'] = name;
    data['organization'] = organization;
    data['__v'] = iV;
    data['updatedAt'] = updatedAt;
    data['service_id'] = serviceId;

    return data;
  }
}

// class Location {
//   double? latitude;
//   double? longitude;

//   Location({this.latitude, this.longitude});

//   Location.fromJson(Map<String, dynamic> json) {
//     latitude = json['latitude'];
//     longitude = json['longitude'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['latitude'] = this.latitude;
//     data['longitude'] = this.longitude;
//     return data;
//   }
// }
