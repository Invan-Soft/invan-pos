// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employees_find_response.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmployeeAdapter extends TypeAdapter<Employee> {
  @override
  final int typeId = 0;

  @override
  Employee read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Employee()
      .._user = fields[0] as EmployeeUser?
      .._role = fields[1] as EmployeeRole?
      .._access = fields[2] as EmployeeAccess?;
  }

  @override
  void write(BinaryWriter writer, Employee obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj._user)
      ..writeByte(1)
      ..write(obj._role)
      ..writeByte(2)
      ..write(obj._access);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmployeeUserAdapter extends TypeAdapter<EmployeeUser> {
  @override
  final int typeId = 101;

  @override
  EmployeeUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmployeeUser()
      .._id = fields[0] as String?
      .._firstName = fields[2] as String?
      .._lastName = fields[3] as String?
      .._image = fields[4] as String?
      .._color = fields[5] as String?
      .._phoneNumber = fields[6] as String?
      .._passCode = fields[7] as String?;
  }

  @override
  void write(BinaryWriter writer, EmployeeUser obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj._id)
      ..writeByte(2)
      ..write(obj._firstName)
      ..writeByte(3)
      ..write(obj._lastName)
      ..writeByte(4)
      ..write(obj._image)
      ..writeByte(5)
      ..write(obj._color)
      ..writeByte(6)
      ..write(obj._phoneNumber)
      ..writeByte(7)
      ..write(obj._passCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmployeeRoleAdapter extends TypeAdapter<EmployeeRole> {
  @override
  final int typeId = 102;

  @override
  EmployeeRole read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmployeeRole()
      .._id = fields[0] as String?
      .._name = fields[1] as String?
      .._createdBy = fields[2] as String?
      .._numberOfEmployees = fields[3] as int?
      .._isDeletable = fields[4] as bool?
      .._saleCreate = fields[5] as bool?
      .._saleCreatViewOnly = fields[6] as bool?
      .._applyDiscount = fields[7] as bool?
      .._refundProduct = fields[8] as bool?
      .._saleDebt = fields[9] as bool?
      .._stock = fields[10] as bool?
      .._saleViewOnly = fields[11] as bool?
      .._printReports = fields[12] as bool?
      .._receipthistory = fields[13] as bool?
      .._creatCustomer = fields[14] as bool?
      .._openShift = fields[15] as bool?
      .._xReport = fields[16] as bool?
      .._zReport = fields[17] as bool?;
  }

  @override
  void write(BinaryWriter writer, EmployeeRole obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj._id)
      ..writeByte(1)
      ..write(obj._name)
      ..writeByte(2)
      ..write(obj._createdBy)
      ..writeByte(3)
      ..write(obj._numberOfEmployees)
      ..writeByte(4)
      ..write(obj._isDeletable)
      ..writeByte(5)
      ..write(obj._saleCreate)
      ..writeByte(6)
      ..write(obj._saleCreatViewOnly)
      ..writeByte(7)
      ..write(obj._applyDiscount)
      ..writeByte(8)
      ..write(obj._refundProduct)
      ..writeByte(9)
      ..write(obj._saleDebt)
      ..writeByte(10)
      ..write(obj._stock)
      ..writeByte(11)
      ..write(obj._saleViewOnly)
      ..writeByte(12)
      ..write(obj._printReports)
      ..writeByte(13)
      ..write(obj._receipthistory)
      ..writeByte(14)
      ..write(obj._creatCustomer)
      ..writeByte(15)
      ..write(obj._openShift)
      ..writeByte(16)
      ..write(obj._xReport)
      ..writeByte(17)
      ..write(obj._zReport);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmployeeAccessAdapter extends TypeAdapter<EmployeeAccess> {
  @override
  final int typeId = 2;

  @override
  EmployeeAccess read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmployeeAccess(
      xreport: fields[1] as bool?,
      openShift: fields[2] as bool?,
      zreport: fields[3] as bool?,
      creatNewCustomer: fields[4] as bool?,
      receiptHistory: fields[5] as bool?,
      deleteS: fields[6] as bool?,
      printReports: fields[7] as bool?,
      viewOnlyAllSale: fields[8] as bool?,
      stock: fields[9] as bool?,
      saleAsDebt: fields[10] as bool?,
      refund: fields[11] as bool?,
      applyManualDiscountsNewSale: fields[12] as bool?,
      viewOnlyNewSale: fields[13] as bool?,
      creatNewSale: fields[0] as bool?,
      editPrice: fields[14] as bool?,
      deletePrice: fields[15] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, EmployeeAccess obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.creatNewSale)
      ..writeByte(1)
      ..write(obj.xreport)
      ..writeByte(2)
      ..write(obj.openShift)
      ..writeByte(3)
      ..write(obj.zreport)
      ..writeByte(4)
      ..write(obj.creatNewCustomer)
      ..writeByte(5)
      ..write(obj.receiptHistory)
      ..writeByte(6)
      ..write(obj.deleteS)
      ..writeByte(7)
      ..write(obj.printReports)
      ..writeByte(8)
      ..write(obj.viewOnlyAllSale)
      ..writeByte(9)
      ..write(obj.stock)
      ..writeByte(10)
      ..write(obj.saleAsDebt)
      ..writeByte(11)
      ..write(obj.refund)
      ..writeByte(12)
      ..write(obj.applyManualDiscountsNewSale)
      ..writeByte(13)
      ..write(obj.viewOnlyNewSale)
      ..writeByte(14)
      ..write(obj.editPrice)
      ..writeByte(15)
      ..write(obj.deletePrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeAccessAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RoleWithPermissionAdapter extends TypeAdapter<RoleWithPermission> {
  @override
  final int typeId = 106;

  @override
  RoleWithPermission read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoleWithPermission(
      id: fields[0] as String?,
      name: fields[1] as String?,
      modules: (fields[2] as List?)?.cast<Modules>(),
    );
  }

  @override
  void write(BinaryWriter writer, RoleWithPermission obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.modules);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleWithPermissionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ModulesAdapter extends TypeAdapter<Modules> {
  @override
  final int typeId = 107;

  @override
  Modules read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Modules(
      sections: (fields[0] as List?)?.cast<Sections>(),
      name: fields[1] as String?,
      id: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Modules obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.sections)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModulesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SectionsAdapter extends TypeAdapter<Sections> {
  @override
  final int typeId = 105;

  @override
  Sections read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sections(
      id: fields[0] as String?,
      name: fields[1] as String?,
      permissions: (fields[2] as List?)?.cast<Permissions>(),
    );
  }

  @override
  void write(BinaryWriter writer, Sections obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.permissions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PermissionsAdapter extends TypeAdapter<Permissions> {
  @override
  final int typeId = 104;

  @override
  Permissions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Permissions(
      id: fields[0] as String?,
      name: fields[1] as String?,
      isAdded: fields[2] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, Permissions obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isAdded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
