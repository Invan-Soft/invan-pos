class SupplierModel {
  final String id;
  final String supplierCompanyName;
  final List<String> agreementNumber;
  final String name;
  final List<String> phoneNumber;
  final String externalId;
  final String status;
  final String contact;
  final String inn;
  final String email;

  SupplierModel({
    required this.id,
    required this.supplierCompanyName,
    required this.agreementNumber,
    required this.name,
    required this.phoneNumber,
    required this.externalId,
    required this.status,
    required this.contact,
    required this.inn,
    required this.email,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] ?? '',
      supplierCompanyName: json['supplier_company_name'] ?? '',
      agreementNumber: List<String>.from(json['agreement_number'] ?? []),
      name: json['name'] ?? '',
      phoneNumber: List<String>.from(json['phone_number'] ?? []),
      externalId: json['external_id'] ?? '',
      status: json['status'] ?? '',
      contact: json['contact'] ?? '',
      inn: json['inn'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class SupplierResponse {
  final List<SupplierModel> data;
  final int total;

  SupplierResponse({
    required this.data,
    required this.total,
  });

  factory SupplierResponse.fromJson(Map<String, dynamic> json) {
    return SupplierResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => SupplierModel.fromJson(e))
          .toList(),
      total: json['total'] ?? 0,
    );
  }
}