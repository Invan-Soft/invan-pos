// ignore_for_file: unnecessary_getters_setters
import 'package:hive/hive.dart';
import '../../hive_repository/hive_types.dart';

part 'employees_find_response.g.dart';

class EmployeesFindResponse {
  int? statusCode;
  String? error;
  String? message;
  List<Employee>? data;

  EmployeesFindResponse({
    this.statusCode,
    this.error,
    this.message,
    this.data,
  });

  EmployeesFindResponse.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    error = json['error'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(Employee.fromJson(v));
      });
    }
  }
}

@HiveType(typeId: HiveTypes.employee)
class Employee extends HiveObject {
  @override
  get key => _user?.id;
  @HiveField(0)
  EmployeeUser? _user;
  @HiveField(1)
  EmployeeRole? _role;
  @HiveField(2)
  EmployeeAccess? _access;

  Employee({
    EmployeeUser? user,
    EmployeeRole? role,
    EmployeeAccess? access,
  }) {
    if (user != null) {
      _user = user;
    }
    if (role != null) {
      _role = role;
    }
    if (access != null) {
      _access = access;
    }
  }

  EmployeeUser? get user => _user;

  set user(EmployeeUser? user) => _user = user;

  EmployeeAccess? get access => _access;

  set access(EmployeeAccess? access) => _access = access;

  EmployeeRole? get role => _role;

  set role(EmployeeRole? role) => _role = role;

  Employee.fromJson(Map<String, dynamic> json) {
    _user = json['user'] != null ? EmployeeUser.fromJson(json['user']) : null;
    _role = json['role'] != null ? EmployeeRole.fromJson(json['role']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (_user != null) {
      data['user'] = _user!.toJson();
    }
    if (_role != null) {
      data['role'] = _role!.toJson();
    }
    if (_access != null) {
      data['access'] = _access!.toJson();
    }
    return data;
  }

  Employee copyWith({
    EmployeeUser? user,
    EmployeeRole? role,
    EmployeeAccess? access,
  }) {
    return Employee(
      user: user ?? _user,
      role: role ?? _role,
      access: access ?? _access,
    );
  }
}

@HiveType(typeId: HiveTypes.employeeUser)
class EmployeeUser extends HiveObject {
  @HiveField(0)
  String? _id;
  @HiveField(2)
  String? _firstName;
  @HiveField(3)
  String? _lastName;
  @HiveField(4)
  String? _image;
  @HiveField(5)
  String? _color;
  @HiveField(6)
  String? _phoneNumber;
  @HiveField(7)
  String? _passCode;

  EmployeeUser(
      {String? id,
      String? firstName,
      String? lastName,
      String? image,
      String? color,
      String? phoneNumber,
      String? passCode}) {
    if (id != null) {
      _id = id;
    }
    if (firstName != null) {
      _firstName = firstName;
    }
    if (lastName != null) {
      _lastName = lastName;
    }
    if (image != null) {
      _image = image;
    }
    if (color != null) {
      _color = color;
    }
    if (phoneNumber != null) {
      _phoneNumber = phoneNumber;
    }
    if (passCode != null) {
      _passCode = passCode;
    }
  }

  String? get id => _id;

  set id(String? id) => _id = id;

  String? get firstName => _firstName;

  set firstName(String? firstName) => _firstName = firstName;

  String? get lastName => _lastName;

  set lastName(String? lastName) => _lastName = lastName;

  String? get image => _image;

  set image(String? image) => _image = image;

  String? get color => _color;

  set color(String? color) => _color = color;

  String? get phoneNumber => _phoneNumber;

  set phoneNumber(String? phoneNumber) => _phoneNumber = phoneNumber;

  String? get passCode => _passCode;

  set passCode(String? passCode) => _passCode = passCode;

  EmployeeUser.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _firstName = json['first_name'];
    _lastName = json['last_name'];
    _image = json['image'];
    _color = json['color'];
    _phoneNumber = json['phone_number'];
    _passCode = json['pass_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = _id;
    data['first_name'] = _firstName;
    data['last_name'] = _lastName;
    data['image'] = _image;
    data['color'] = _color;
    data['phone_number'] = _phoneNumber;
    data['pass_code'] = _passCode;
    return data;
  }
}

@HiveType(typeId: HiveTypes.employeeRole)
class EmployeeRole {
  @HiveField(0)
  String? _id;
  @HiveField(1)
  String? _name;
  @HiveField(2)
  String? _createdBy;
  @HiveField(3)
  int? _numberOfEmployees;
  @HiveField(4)
  bool? _isDeletable;
  @HiveField(5)
  bool? _saleCreate;
  @HiveField(6)
  bool? _saleCreatViewOnly;
  @HiveField(7)
  bool? _applyDiscount;
  @HiveField(8)
  bool? _refundProduct;
  @HiveField(9)
  bool? _saleDebt;
  @HiveField(10)
  bool? _stock;
  @HiveField(11)
  bool? _saleViewOnly;
  @HiveField(12)
  bool? _printReports;
  @HiveField(13)
  bool? _receipthistory;
  @HiveField(14)
  bool? _creatCustomer;
  @HiveField(15)
  bool? _openShift;
  @HiveField(16)
  bool? _xReport;
  @HiveField(17)
  bool? _zReport;

  EmployeeRole(
      {String? id,
      String? name,
      String? createdBy,
      int? numberOfEmployees,
      bool? isDeletable,
      bool? saleCreate,
      bool? saleCreatViewOnly,
      bool? applyDiscount,
      bool? refundProduct,
      bool? saleDebt,
      bool? stock,
      bool? saleViewOnly,
      bool? printReports,
      bool? receipthistory,
      bool? creatCustomer,
      bool? openShift,
      bool? xReport,
      bool? zReport}) {
    if (id != null) {
      _id = id;
    }
    if (name != null) {
      _name = name;
    }
    if (createdBy != null) {
      _createdBy = createdBy;
    }
    if (numberOfEmployees != null) {
      _numberOfEmployees = numberOfEmployees;
    }
    if (isDeletable != null) {
      _isDeletable = isDeletable;
    }
    if (saleCreate != null) {
      _saleCreate = saleCreate;
    }
    if (saleCreatViewOnly != null) {
      _saleCreatViewOnly = saleCreatViewOnly;
    }
    if (applyDiscount != null) {
      _applyDiscount = applyDiscount;
    }
    if (refundProduct != null) {
      _refundProduct = refundProduct;
    }
    if (saleDebt != null) {
      _saleDebt = saleDebt;
    }
    if (stock != null) {
      _stock = stock;
    }
    if (saleViewOnly != null) {
      _saleViewOnly = saleViewOnly;
    }
    if (printReports != null) {
      _printReports = printReports;
    }
    if (receipthistory != null) {
      _receipthistory = receipthistory;
    }
    if (creatCustomer != null) {
      _creatCustomer = creatCustomer;
    }
    if (openShift != null) {
      _openShift = openShift;
    }
    if (xReport != null) {
      _xReport = xReport;
    }
    if (zReport != null) {
      _zReport = zReport;
    }
  }

  String? get id => _id;

  set id(String? id) => _id = id;

  String? get name => _name;

  set name(String? name) => _name = name;

  String? get createdBy => _createdBy;

  set createdBy(String? createdBy) => _createdBy = createdBy;

  int? get numberOfEmployees => _numberOfEmployees;

  set numberOfEmployees(int? numberOfEmployees) =>
      _numberOfEmployees = numberOfEmployees;

  bool? get isDeletable => _isDeletable;

  set isDeletable(bool? isDeletable) => _isDeletable = isDeletable;

  bool? get saleCreate => _saleCreate;

  set saleCreate(bool? saleCreate) => _saleCreate = saleCreate;

  bool? get saleCreatViewOnly => _saleCreatViewOnly;

  set saleCreatViewOnly(bool? saleCreatViewOnly) =>
      _saleCreatViewOnly = saleCreatViewOnly;

  bool? get applyDiscount => _applyDiscount;

  set applyDiscount(bool? applyDiscount) => _applyDiscount = applyDiscount;

  bool? get refundProduct => _refundProduct;

  set refundProduct(bool? refundProduct) => _refundProduct = refundProduct;

  bool? get saleDebt => _saleDebt;

  set saleDebt(bool? saleDebt) => _saleDebt = saleDebt;

  bool? get stock => _stock;

  set stock(bool? stock) => _stock = stock;

  bool? get saleViewOnly => _saleViewOnly;

  set saleViewOnly(bool? saleViewOnly) => _saleViewOnly = saleViewOnly;

  bool? get printReports => _printReports;

  set printReports(bool? printReports) => _printReports = printReports;

  bool? get receipthistory => _receipthistory;

  set receipthistory(bool? receipthistory) => _receipthistory = receipthistory;

  bool? get creatCustomer => _creatCustomer;

  set creatCustomer(bool? creatCustomer) => _creatCustomer = creatCustomer;

  bool? get openShift => _openShift;

  set openShift(bool? openShift) => _openShift = openShift;

  bool? get xReport => _xReport;

  set xReport(bool? xReport) => _xReport = xReport;

  bool? get zReport => _zReport;

  set zReport(bool? zReport) => _zReport = zReport;

  EmployeeRole.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    _createdBy = json['createdBy'];
    _numberOfEmployees = json['numberOfEmployees'];
    _isDeletable = json['isDeletable'];
    _saleCreate = json['saleCreate'];
    _saleCreatViewOnly = json['saleCreatViewOnly'];
    _applyDiscount = json['applyDiscount'];
    _refundProduct = json['refundProduct'];
    _saleDebt = json['saleDebt'];
    _stock = json['stock'];
    _saleViewOnly = json['saleViewOnly'];
    _printReports = json['printReports'];
    _receipthistory = json['receipthistory'];
    _creatCustomer = json['creatCustomer'];
    _openShift = json['openShift'];
    _xReport = json['xReport'];
    _zReport = json['zReport'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = _id;
    data['name'] = _name;
    data['createdBy'] = _createdBy;
    data['numberOfEmployees'] = _numberOfEmployees;
    data['isDeletable'] = _isDeletable;
    data['saleCreate'] = _saleCreate;
    data['saleCreatViewOnly'] = _saleCreatViewOnly;
    data['applyDiscount'] = _applyDiscount;
    data['refundProduct'] = _refundProduct;
    data['saleDebt'] = _saleDebt;
    data['stock'] = _stock;
    data['saleViewOnly'] = _saleViewOnly;
    data['printReports'] = _printReports;
    data['receipthistory'] = _receipthistory;
    data['creatCustomer'] = _creatCustomer;
    data['openShift'] = _openShift;
    data['xReport'] = _xReport;
    data['zReport'] = _zReport;
    return data;
  }
}

@HiveType(typeId: 2)
class EmployeeAccess extends HiveObject {
  @HiveField(0)
  bool? creatNewSale;
  @HiveField(1)
  bool? xreport;
  @HiveField(2)
  bool? openShift;
  @HiveField(3)
  bool? zreport;
  @HiveField(4)
  bool? creatNewCustomer;
  @HiveField(5)
  bool? receiptHistory;
  @HiveField(6)
  bool? deleteS;
  @HiveField(7)
  bool? printReports;
  @HiveField(8)
  bool? viewOnlyAllSale;
  @HiveField(9)
  bool? stock;
  @HiveField(10)
  bool? saleAsDebt;
  @HiveField(11)
  bool? refund;
  @HiveField(12)
  bool? applyManualDiscountsNewSale;
  @HiveField(13)
  bool? viewOnlyNewSale;
  @HiveField(14)
  bool? editPrice;
  @HiveField(15)
  bool? deletePrice;

  EmployeeAccess({
    this.xreport,
    this.openShift,
    this.zreport,
    this.creatNewCustomer,
    this.receiptHistory,
    this.deleteS,
    this.printReports,
    this.viewOnlyAllSale,
    this.stock,
    this.saleAsDebt,
    this.refund,
    this.applyManualDiscountsNewSale,
    this.viewOnlyNewSale,
    this.creatNewSale,
    this.editPrice,
    this.deletePrice,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data["xreport"] = xreport;
    data["openShift"] = openShift;
    data["zreport"] = zreport;
    data["creatNewCustomer"] = creatNewCustomer;
    data["receiptHistory"] = receiptHistory;
    data["deleteS"] = deleteS;
    data["printReports"] = printReports;
    data["viewOnlyAllSale"] = viewOnlyAllSale;
    data["stock"] = stock;
    data["saleAsDebt"] = saleAsDebt;
    data["refund"] = refund;
    data["applyManualDiscountsNewSale"] = applyManualDiscountsNewSale;
    data["viewOnlyNewSale"] = viewOnlyNewSale;
    data["creatNewSale"] = creatNewSale;
    data["edit_price"] = editPrice;
    data["delete_price"] = deletePrice;
    return data;
  }
}

/// /// ///  =========================Foydalanuvchining rollari haqida permissionlar================

class RoleWithPermissions {
  List<RoleWithPermission>? data;
  int? total;

  RoleWithPermissions({this.data, this.total});

  RoleWithPermissions.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <RoleWithPermission>[];
      json['data'].forEach((v) {
        data!.add(RoleWithPermission.fromJson(v));
      });
    }
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['total'] = total;
    return data;
  }
}

@HiveType(typeId: HiveTypes.rolePermissionsWithIDModel)
class RoleWithPermission extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;
  @HiveField(2)
  List<Modules>? modules;

  RoleWithPermission({this.id, this.name, this.modules});

  RoleWithPermission.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['modules'] != null) {
      modules = <Modules>[];
      json['modules'].forEach((v) {
        modules!.add(Modules.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    if (modules != null) {
      data['modules'] = modules!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

@HiveType(typeId: HiveTypes.rolePermissions)
class Modules extends HiveObject {
  @HiveField(0)
  List<Sections>? sections;
  @HiveField(1)
  String? name;
  @HiveField(2)
  String? id;

  Modules({this.sections, this.name, this.id});

  Modules.fromJson(Map<String, dynamic> json) {
    if (json['sections'] != null) {
      sections = <Sections>[];
      json['sections'].forEach((v) {
        sections!.add(Sections.fromJson(v));
      });
    }
    name = json['name'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (sections != null) {
      data['sections'] = sections!.map((v) => v.toJson()).toList();
    }
    data['name'] = name;
    data['id'] = id;
    return data;
  }
}

@HiveType(typeId: HiveTypes.sectionsModel)
class Sections extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;
  @HiveField(2)
  List<Permissions>? permissions;

  Sections({
    this.id,
    this.name,
    this.permissions,
  });

  Sections.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['permissions'] != null) {
      permissions = <Permissions>[];
      json['permissions'].forEach((v) {
        permissions!.add(Permissions.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    if (permissions != null) {
      data['permissions'] = permissions!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

@HiveType(typeId: HiveTypes.permissionsModel)
class Permissions extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;
  @HiveField(2)
  bool? isAdded;

  Permissions({this.id, this.name, this.isAdded});

  Permissions.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    isAdded = json['is_added'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['is_added'] = isAdded;
    return data;
  }
}
