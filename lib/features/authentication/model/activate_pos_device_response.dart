

class ActivatePosDeviceResponseData {
  bool? isActive;
  String? checkId;
  bool? status;
  int? receiptNo;
  bool? backOffice;
  String? sId;
  String? name;
  String? service;
  String? organization;
  String? serviceId;
  int? iV;
  String? imei;

  ActivatePosDeviceResponseData({
    this.isActive,
    this.checkId,
    this.status,
    this.receiptNo,
    this.backOffice,
    this.sId,
    this.name,
    this.service,
    this.organization,
    this.serviceId,
    this.iV,
    this.imei,
  });

  ActivatePosDeviceResponseData.fromJson(Map<String, dynamic> json) {
    isActive = json['is_active'];
    checkId = json['check_id'];
    status = json['status'];
    receiptNo = json['receipt_no'];
    backOffice = json['back_office'];
    sId = json['_id'];
    name = json['name'];
    service = json['service'];
    organization = json['organization'];
    serviceId = json['service_id'];
    iV = json['__v'];
    imei = json['imei'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_active'] = isActive;
    data['check_id'] = checkId;
    data['status'] = status;
    data['receipt_no'] = receiptNo;
    data['back_office'] = backOffice;
    data['_id'] = sId;
    data['name'] = name;
    data['service'] = service;
    data['organization'] = organization;
    data['service_id'] = serviceId;
    data['__v'] = iV;
    data['imei'] = imei;
    return data;
  }
}
