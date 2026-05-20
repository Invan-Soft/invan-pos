// ignore_for_file: non_constant_identifier_names

class LoginVerifyResponse {
  int? statusCode;
  String? error;
  String? message;
  LoginVerifyResponseData? data;

  LoginVerifyResponse({
    this.statusCode,
    this.error,
    this.message,
    this.data,
  });

  LoginVerifyResponse.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    error = json['error'];
    message = json['message'];
    data = json['data'] != null
        ? LoginVerifyResponseData.fromJson(json['data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['error'] = error;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class LoginVerifyResponseData {
  LoginVerifyResponseUiLanguage? uiLanguage;
  bool? isBoss;
  String? service;
  bool? isActive;
  int? percentage;
  bool? isPassword;
  String? password;
  String? role;
  String? fullName;
  String? name;
  String? email;
  String? lastName;
  bool? isPhoneNumber;
  String? token;
  String? fireToken;
  String? imageUrl;
  String? sId;
  List<LoginVerifyResponseServices>? services;
  String? phoneNumber;
  String? superPassword;
  String? organization;
  int? iV;
  LoginVerifyResponseAccess? access;

  LoginVerifyResponseData({
    this.uiLanguage,
    this.isBoss,
    this.service,
    this.isActive,
    this.percentage,
    this.isPassword,
    this.password,
    this.role,
    this.fullName,
    this.name,
    this.email,
    this.lastName,
    this.isPhoneNumber,
    this.token,
    this.fireToken,
    this.imageUrl,
    this.sId,
    this.services,
    this.phoneNumber,
    this.superPassword,
    this.organization,
    this.iV,
    this.access,
  });

  LoginVerifyResponseData.fromJson(Map<String, dynamic> json) {
    uiLanguage = json['ui_language'] != null
        ? LoginVerifyResponseUiLanguage.fromJson(json['ui_language'])
        : null;
    isBoss = json['is_boss'];
    service = json['service'];
    isActive = json['is_active'];
    percentage = json['percentage'];
    isPassword = json['is_password'];
    password = json['password'];
    role = json['role'];
    fullName = json['full_name'];
    name = json['name'];
    email = json['email'];
    lastName = json['last_name'];
    isPhoneNumber = json['is_phone_number'];
    token = json['token'];
    fireToken = json['fire_token'];
    imageUrl = json['image_url'];
    sId = json['_id'];
    if (json['services'] != null) {
      services = [];
      json['services'].forEach((v) {
        services!.add(LoginVerifyResponseServices.fromJson(v));
      });
    }
    phoneNumber = json['phone_number'];
    superPassword = json['super_password'];
    organization = json['organization'];
    iV = json['__v'];
    access = json['access'] != null
        ? LoginVerifyResponseAccess.fromJson(json['access'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (uiLanguage != null) {
      data['ui_language'] = uiLanguage!.toJson();
    }
    data['is_boss'] = isBoss;
    data['service'] = service;
    data['is_active'] = isActive;
    data['percentage'] = percentage;
    data['is_password'] = isPassword;
    data['password'] = password;
    data['role'] = role;
    data['full_name'] = fullName;
    data['name'] = name;
    data['email'] = email;
    data['last_name'] = lastName;
    data['is_phone_number'] = isPhoneNumber;
    data['token'] = token;
    data['fire_token'] = fireToken;
    data['image_url'] = imageUrl;
    data['_id'] = sId;
    if (services != null) {
      data['services'] = services!.map((v) => v.toJson()).toList();
    }
    data['phone_number'] = phoneNumber;
    data['super_password'] = superPassword;
    data['organization'] = organization;
    data['__v'] = iV;
    if (access != null) {
      data['access'] = access!.toJson();
    }
    return data;
  }
}

class LoginVerifyResponseUiLanguage {
  String? text;
  String? value;

  LoginVerifyResponseUiLanguage({this.text, this.value});

  LoginVerifyResponseUiLanguage.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['text'] = text;
    data['value'] = value;
    return data;
  }
}

class LoginVerifyResponseServices {
  String? id;
  int? number_of_cashbox;
  String? title;
  String? address;
  String? number;

  LoginVerifyResponseServices({
    this.id,
    this.number_of_cashbox,
    this.title,
    this.address,
    this.number,
  });
  LoginVerifyResponseServices.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    number_of_cashbox = json['number_of_cashbox'];
    title = json['title'];
    address = json['address'];
    number = json['phone_number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['number_of_cashbox'] = number_of_cashbox;
    data['title'] = title;
    data['address'] = address;
    data['phone_number'] = number;

    return data;
  }
}

class LoginVerifyResponseAccess {
  bool? isBos;
  bool? pos;
  bool? closeTicket;
  bool? wharehouseManager;
  bool? canSell;
  bool? printPreCheck;
  bool? receiptSaveAsDraft;
  bool? canChangePrice;
  bool? refund;
  bool? showAllReceipts;
  bool? payDebt;
  bool? showShiftHistory;
  bool? applyDiscount;
  bool? changeSettings;
  bool? editItems;
  bool? editTicket;
  bool? splitTicket;
  bool? changeWaiter;
  bool? deleteTicket;
  bool? showAllTickets;
  bool? canAccessToShift;
  bool? backOffice;
  bool? reports;
  bool? items;
  bool? employees;
  bool? customers;
  bool? settings;
  bool? editProfile;
  bool? setTheTaxes;
  bool? managePosDevices;
  bool? inventory;
  bool? invPurchaseOrders;
  bool? invPurchaseMark;
  bool? invPurchaseOrdersCost;
  bool? invTransferOrders;
  bool? invStockAdjusment;
  bool? invStockAdjusmentCost;
  bool? invInventoryCounts;
  bool? invProductions;
  bool? invProductionsCost;
  bool? invSuppliers;
  bool? invSupplierTransaction;
  bool? invSupplierTransactionCorrector;
  bool? invFees;
  bool? invInventoryHistory;
  bool? invInventoryValuation;
  bool? workgroup;
  bool? workgroupEditCost;
  String? sId;
  String? organization;
  String? name;
  int? iV;

  LoginVerifyResponseAccess({
    this.isBos,
    this.pos,
    this.closeTicket,
    this.wharehouseManager,
    this.canSell,
    this.printPreCheck,
    this.receiptSaveAsDraft,
    this.canChangePrice,
    this.refund,
    this.showAllReceipts,
    this.payDebt,
    this.showShiftHistory,
    this.applyDiscount,
    this.changeSettings,
    this.editItems,
    this.editTicket,
    this.splitTicket,
    this.changeWaiter,
    this.deleteTicket,
    this.showAllTickets,
    this.canAccessToShift,
    this.backOffice,
    this.reports,
    this.items,
    this.employees,
    this.customers,
    this.settings,
    this.editProfile,
    this.setTheTaxes,
    this.managePosDevices,
    this.inventory,
    this.invPurchaseOrders,
    this.invPurchaseMark,
    this.invPurchaseOrdersCost,
    this.invTransferOrders,
    this.invStockAdjusment,
    this.invStockAdjusmentCost,
    this.invInventoryCounts,
    this.invProductions,
    this.invProductionsCost,
    this.invSuppliers,
    this.invSupplierTransaction,
    this.invSupplierTransactionCorrector,
    this.invFees,
    this.invInventoryHistory,
    this.invInventoryValuation,
    this.workgroup,
    this.workgroupEditCost,
    this.sId,
    this.organization,
    this.name,
    this.iV,
  });

  LoginVerifyResponseAccess.fromJson(Map<String, dynamic> json) {
    isBos = json['is_bos'];
    pos = json['pos'];
    closeTicket = json['close_ticket'];
    wharehouseManager = json['wharehouse_manager'];
    canSell = json['can_sell'];
    printPreCheck = json['print_pre_check'];
    receiptSaveAsDraft = json['receipt_save_as_draft'];
    canChangePrice = json['can_change_price'];
    refund = json['refund'];
    showAllReceipts = json['show_all_receipts'];
    payDebt = json['pay_debt'];
    showShiftHistory = json['show_shift_history'];
    applyDiscount = json['apply_discount'];
    changeSettings = json['change_settings'];
    editItems = json['edit_items'];
    editTicket = json['edit_ticket'];
    splitTicket = json['split_ticket'];
    changeWaiter = json['change_waiter'];
    deleteTicket = json['delete_ticket'];
    showAllTickets = json['show_all_tickets'];
    canAccessToShift = json['can_access_to_shift'];
    backOffice = json['back_office'];
    reports = json['reports'];
    items = json['items'];
    employees = json['employees'];
    customers = json['customers'];
    settings = json['settings'];
    editProfile = json['edit_profile'];
    setTheTaxes = json['set_the_taxes'];
    managePosDevices = json['manage_pos_devices'];
    inventory = json['inventory'];
    invPurchaseOrders = json['inv_purchase_orders'];
    invPurchaseMark = json['inv_purchase_mark'];
    invPurchaseOrdersCost = json['inv_purchase_orders_cost'];
    invTransferOrders = json['inv_transfer_orders'];
    invStockAdjusment = json['inv_stock_adjusment'];
    invStockAdjusmentCost = json['inv_stock_adjusment_cost'];
    invInventoryCounts = json['inv_inventory_counts'];
    invProductions = json['inv_productions'];
    invProductionsCost = json['inv_productions_cost'];
    invSuppliers = json['inv_suppliers'];
    invSupplierTransaction = json['inv_supplier_transaction'];
    invSupplierTransactionCorrector =
        json['inv_supplier_transaction_corrector'];
    invFees = json['inv_fees'];
    invInventoryHistory = json['inv_inventory_history'];
    invInventoryValuation = json['inv_inventory_valuation'];
    workgroup = json['workgroup'];
    workgroupEditCost = json['workgroup_edit_cost'];
    sId = json['_id'];
    organization = json['organization'];
    name = json['name'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_bos'] = isBos;
    data['pos'] = pos;
    data['close_ticket'] = closeTicket;
    data['wharehouse_manager'] = wharehouseManager;
    data['can_sell'] = canSell;
    data['print_pre_check'] = printPreCheck;
    data['receipt_save_as_draft'] = receiptSaveAsDraft;
    data['can_change_price'] = canChangePrice;
    data['refund'] = refund;
    data['show_all_receipts'] = showAllReceipts;
    data['pay_debt'] = payDebt;
    data['show_shift_history'] = showShiftHistory;
    data['apply_discount'] = applyDiscount;
    data['change_settings'] = changeSettings;
    data['edit_items'] = editItems;
    data['edit_ticket'] = editTicket;
    data['split_ticket'] = splitTicket;
    data['change_waiter'] = changeWaiter;
    data['delete_ticket'] = deleteTicket;
    data['show_all_tickets'] = showAllTickets;
    data['can_access_to_shift'] = canAccessToShift;
    data['back_office'] = backOffice;
    data['reports'] = reports;
    data['items'] = items;
    data['employees'] = employees;
    data['customers'] = customers;
    data['settings'] = settings;
    data['edit_profile'] = editProfile;
    data['set_the_taxes'] = setTheTaxes;
    data['manage_pos_devices'] = managePosDevices;
    data['inventory'] = inventory;
    data['inv_purchase_orders'] = invPurchaseOrders;
    data['inv_purchase_mark'] = invPurchaseMark;
    data['inv_purchase_orders_cost'] = invPurchaseOrdersCost;
    data['inv_transfer_orders'] = invTransferOrders;
    data['inv_stock_adjusment'] = invStockAdjusment;
    data['inv_stock_adjusment_cost'] = invStockAdjusmentCost;
    data['inv_inventory_counts'] = invInventoryCounts;
    data['inv_productions'] = invProductions;
    data['inv_productions_cost'] = invProductionsCost;
    data['inv_suppliers'] = invSuppliers;
    data['inv_supplier_transaction'] = invSupplierTransaction;
    data['inv_supplier_transaction_corrector'] =
        invSupplierTransactionCorrector;
    data['inv_fees'] = invFees;
    data['inv_inventory_history'] = invInventoryHistory;
    data['inv_inventory_valuation'] = invInventoryValuation;
    data['workgroup'] = workgroup;
    data['workgroup_edit_cost'] = workgroupEditCost;
    data['_id'] = sId;
    data['organization'] = organization;
    data['name'] = name;
    data['__v'] = iV;
    return data;
  }
}
