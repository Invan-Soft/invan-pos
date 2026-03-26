// class ServiceGetResponse {
//   // int? statusCode;
//   // String? error;
//   // String? message;
//   ServiceGetResponseData? data;

//   ServiceGetResponse({
//     // this.statusCode,
//     // this.error,
//     // this.message,
//     this.data,
//   });

//   ServiceGetResponse.fromJson(Map<String, dynamic> json) {
//     // statusCode = json['statusCode'];
//     // error = json['error'];
//     // message = json['message'];
//     data = json['data'] != null
//         ? ServiceGetResponseData.fromJson(json['data'])
//         : null;
//   }
// }

// // class ServiceGetResponseData {
// //   ServiceGetResponseLocation? location;
// //   String? typeOfBusiness;
// //   String? type;
// //   String? address;
// //   bool? isShop;
// //   String? phoneNumber;
// //   String? description;
// //   int? serviceValue;
// //   String? locationName;
// //   int? count;
// //   String? imageUrl;
// //   String? sId;
// //   String? name;
// //   String? organization;
// //   int? iV;
// //   ServiceGetResponseReceipt? receipt;

// //   ServiceGetResponseData({
// //     this.location,
// //     this.typeOfBusiness,
// //     this.type,
// //     this.address,
// //     this.isShop,
// //     this.phoneNumber,
// //     this.description,
// //     this.serviceValue,
// //     this.locationName,
// //     this.count,
// //     this.imageUrl,
// //     this.sId,
// //     this.name,
// //     this.organization,
// //     this.iV,
// //     this.receipt,
// //   });

// //   ServiceGetResponseData.fromJson(Map<String, dynamic> json) {
// //     location = json['location'] != null
// //         ? ServiceGetResponseLocation.fromJson(json['location'])
// //         : null;
// //     typeOfBusiness = json['type_of_business'];
// //     type = json['type'];
// //     address = json['address'];
// //     isShop = json['is_shop'];
// //     phoneNumber = json['phone_number'];
// //     description = json['description'];
// //     serviceValue = json['service_value'];
// //     locationName = json['location_name'];
// //     count = json['count'];
// //     imageUrl = json['image_url'];
// //     sId = json['_id'];
// //     name = json['name'];
// //     organization = json['organization'];
// //     iV = json['__v'];
// //     receipt = json['receipt'] != null
// //         ? ServiceGetResponseReceipt.fromJson(json['receipt'])
// //         : null;
// //   }
// // }

// // class ServiceGetResponseReceipt {
// //   String? emailedReceipt;
// //   String? printedReceipt;
// //   String? header;
// //   String? footer;
// //   bool? showCustomerInfo;
// //   bool? showComments;
// //   String? sId;
// //   String? service;
// //   int? iV;

// //   ServiceGetResponseReceipt({
// //     this.emailedReceipt,
// //     this.printedReceipt,
// //     this.header,
// //     this.footer,
// //     this.showCustomerInfo,
// //     this.showComments,
// //     this.sId,
// //     this.service,
// //     this.iV,
// //   });

// //   ServiceGetResponseReceipt.fromJson(Map<String, dynamic> json) {
// //     emailedReceipt = json['emailed_receipt'];
// //     printedReceipt = json['printed_receipt'];
// //     header = json['header'];
// //     footer = json['footer'];
// //     showCustomerInfo = json['show_customer_info'];
// //     showComments = json['show_comments'];
// //     sId = json['_id'];
// //     service = json['service'];
// //     iV = json['__v'];
// //   }
// // }

// //////////////////////////////////////////////////////////////////////////
// class ServiceGetResponseData {
//   String? id;
//   String? name;
//   String? legalName;
//   String? email;
//   String? legalAddress;
//   String? country;
//   String? zipCode;
//   String? taxPayerId;
//   Owner? owner;
//   String? size;
//   String? sizeId;
//   String? createdAt;
//   String? ibt;
//   ServiceGetResponseLocation? location;

//   ServiceGetResponseData(
//       {this.id,
//       this.name,
//       this.legalName,
//       this.email,
//       this.legalAddress,
//       this.country,
//       this.location,
//       this.zipCode,
//       this.taxPayerId,
//       this.owner,
//       this.size,
//       this.sizeId,
//       this.createdAt,
//       this.ibt});

//   ServiceGetResponseData.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     location = json['location'] != null
//         ? ServiceGetResponseLocation.fromJson(json['location'])
//         : null;
//     name = json['name'];
//     legalName = json['legal_name'];
//     email = json['email'];
//     legalAddress = json['legal_address'];
//     country = json['country'];
//     zipCode = json['zip_code'];
//     taxPayerId = json['tax_payer_id'];
//     owner = json['owner'] != null ? Owner.fromJson(json['owner']) : null;
//     size = json['size'];
//     sizeId = json['size_id'];
//     createdAt = json['created_at'];
//     ibt = json['ibt'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = {};
//     data['id'] = id;
//     data['name'] = name;
//     data['legal_name'] = legalName;
//     data['email'] = email;
//     data['legal_address'] = legalAddress;
//     data['country'] = country;
//     data['zip_code'] = zipCode;
//     data['tax_payer_id'] = taxPayerId;
//     if (owner != null) {
//       data['owner'] = owner!.toJson();
//     }
//     data['size'] = size;
//     data['size_id'] = sizeId;
//     data['created_at'] = createdAt;
//     data['ibt'] = ibt;
//     return data;
//   }
// }

// class Owner {
//   String? id;
//   String? firstName;
//   String? lastName;
//   String? image;
//   String? color;
//   String? phoneNumber;
//   String? passCode;

//   Owner(
//       {this.id,
//       this.firstName,
//       this.lastName,
//       this.image,
//       this.color,
//       this.phoneNumber,
//       this.passCode});

//   Owner.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     firstName = json['first_name'];
//     lastName = json['last_name'];
//     image = json['image'];
//     color = json['color'];
//     phoneNumber = json['phone_number'];
//     passCode = json['pass_code'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = {};
//     data['id'] = id;
//     data['first_name'] = firstName;
//     data['last_name'] = lastName;
//     data['image'] = image;
//     data['color'] = color;
//     data['phone_number'] = phoneNumber;
//     data['pass_code'] = passCode;
//     return data;
//   }
// }

// class ServiceGetResponseLocation {
//   double? latitude;
//   double? longitude;

//   ServiceGetResponseLocation({
//     this.latitude,
//     this.longitude,
//   });

//   ServiceGetResponseLocation.fromJson(Map<String, dynamic> json) {
//     latitude = json['latitude'];
//     longitude = json['longitude'];
//   }
// }

class ServiceGetResponseData {
  String? id;
  String? name;
  String? message;
  Logo? logo;
  List<Blocks>? blocks;

  ServiceGetResponseData({
    this.id,
    this.name,
    this.message,
    this.logo,
    this.blocks,
  });

  ServiceGetResponseData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    message = json['message'];
    logo = json['logo'] != null ? Logo.fromJson(json['logo']) : null;
    if (json['blocks'] != null) {
      blocks = <Blocks>[];
      json['blocks'].forEach((v) {
        blocks!.add(Blocks.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['message'] = message;
    if (logo != null) {
      data['logo'] = logo!.toJson();
    }
    if (blocks != null) {
      data['blocks'] = blocks!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Logo {
  String? image;
  int? left;
  int? right;
  int? top;
  int? bottom;

  Logo({
    this.image,
    this.left,
    this.right,
    this.top,
    this.bottom,
  });

  Logo.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    left = json['left'];
    right = json['right'];
    top = json['top'];
    bottom = json['bottom'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['image'] = image;
    data['left'] = left;
    data['right'] = right;
    data['top'] = top;
    data['bottom'] = bottom;
    return data;
  }
}

class Blocks {
  String? id;
  String? name;
  List<RecFields>? fields;
  NameTranslation? nameTranslation;

  Blocks({
    this.id,
    this.name,
    this.fields,
    this.nameTranslation,
  });

  Blocks.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['fields'] != null) {
      fields = <RecFields>[];
      json['fields'].forEach((v) {
        fields!.add(RecFields.fromJson(v));
      });
    }
    nameTranslation = json['name_translation'] != null
        ? NameTranslation.fromJson(json['name_translation'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    if (fields != null) {
      data['fields'] = fields!.map((v) => v.toJson()).toList();
    }
    if (nameTranslation != null) {
      data['name_translation'] = nameTranslation!.toJson();
    }
    return data;
  }
}

class RecFields {
  String? id;
  String? name;
  bool? isAdded;
  NameTranslation? nameTranslation;

  RecFields({
    this.id,
    this.name,
    this.isAdded,
    this.nameTranslation,
  });

  RecFields.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    isAdded = json['is_added'];
    nameTranslation = json['name_translation'] != null
        ? NameTranslation.fromJson(json['name_translation'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['is_added'] = isAdded;
    if (nameTranslation != null) {
      data['name_translation'] = nameTranslation!.toJson();
    }
    return data;
  }
}

class NameTranslation {
  String? en;
  String? ru;
  String? uz;

  NameTranslation({
    this.en,
    this.ru,
    this.uz,
  });

  NameTranslation.fromJson(Map<String, dynamic> json) {
    en = json['en'];
    ru = json['ru'];
    uz = json['uz'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['en'] = en;
    data['ru'] = ru;
    data['uz'] = uz;
    return data;
  }
}
