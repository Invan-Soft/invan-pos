class GetAvailablePosResponse {
  int? statusCode;
  String? error;
  String? message;
  List<GetAvailablePosResponseData>? data;

  GetAvailablePosResponse({
    this.statusCode,
    this.error,
    this.message,
    this.data,
  });

  GetAvailablePosResponse.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    error = json['error'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(GetAvailablePosResponseData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['error'] = error;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class GetAvailablePosResponseData {
  // bool? isActive;
  // String? checkId;
  // bool? status;
  // int? receiptNo;
  // bool? backOffice;
  String? sId;
  String? storesId;
  String? name;
  String? prefix;
  bool? isActive;
  // String? service;
  // String? organization;
  // String? serviceId;
  // int? iV;
  // String? imei;

  GetAvailablePosResponseData({
    // this.isActive,
    // this.checkId,
    // this.status,
    // this.receiptNo,
    // this.backOffice,
    this.sId,
    this.storesId,
    this.name,
    this.isActive,
    this.prefix,
    // this.service,
    // this.organization,
    // this.serviceId,
    // this.iV,
    // this.imei,
  });

  GetAvailablePosResponseData.fromJson(Map<String, dynamic> json) {
    // isActive = json['is_active'];
    // checkId = json['check_id'];
    // status = json['status'];
    // receiptNo = json['receipt_no'];
    // backOffice = json['back_office'];
    sId = json['id'];
    name = json['name'];
    prefix = json['prefix'];
    isActive = json['is_active'];
    storesId = json['shop']['id'];

    // service = json['service'];
    // organization = json['organization'];
    // serviceId = json['service_id'];
    // iV = json['__v'];
    // imei = json['imei'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    // data['is_active'] = isActive;
    // data['check_id'] = checkId;
    // data['status'] = status;
    // data['receipt_no'] = receiptNo;
    // data['back_office'] = backOffice;
    data['id'] = sId;
    data['name'] = name;
    data['prefix'] = prefix;
    data['is_active'] = isActive;

    // data['service'] = service;
    // data['organization'] = organization;
    // data['service_id'] = serviceId;
    // data['__v'] = iV;
    // data['imei'] = imei;
    return data;
  }
}
