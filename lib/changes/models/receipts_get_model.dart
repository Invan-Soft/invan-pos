class GetReceiptModel {
  GetReceiptModel({
    this.total,
    this.data,
  });

  int? total;
  List<GlobalReceipt>? data;

  factory GetReceiptModel.fromJson(Map<String, dynamic> json) =>
      GetReceiptModel(
        data: List<GlobalReceipt>.from(
          json["data"].map(
            (x) => GlobalReceipt.fromJson(x),
          ),
        ),
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "data": List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class GlobalReceipt {
  String? id;
  String? type;
  String? externalId;
  num? totalPrice;
  DiscountGTR? discount;
  StatusGTR? status;
  ShopGTR? shop;
  ClientGTR? client;
  Cashbox? cashbox;
  CreatedByGTR? createdBy;
  List<ItemsGTR>? items;
  List<PaysGTR>? pays;
  String? createTime;
  String? cashierId;
  String? terminalId;
  int? receiptSeq;
  String? dateTimeOFD;
  String? fiscalSign;
  String? url;

  GlobalReceipt({
    this.id,
    this.type,
    this.status,
    this.externalId,
    this.totalPrice,
    this.discount,
    this.shop,
    this.client,
    this.cashbox,
    this.createdBy,
    this.items,
    this.pays,
    this.createTime,
    this.cashierId,
    this.terminalId,
    this.receiptSeq,
    this.dateTimeOFD,
    this.fiscalSign,
    this.url,
  });

  GlobalReceipt.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    terminalId = json['terminal_id'];
    receiptSeq = json['receipt_seq'];
    dateTimeOFD = json['date_time'];
    fiscalSign = json['fiscal_sign'];
    status = json['status'] != null ? StatusGTR.fromJson(json['status']) : null;
    type = json['type'];
    externalId = json['external_id'];
    totalPrice = json['total_price'];
    discount = json['discount'] != null
        ? DiscountGTR.fromJson(json['discount'])
        : null;
    shop = json['shop'] != null ? ShopGTR.fromJson(json['shop']) : null;
    client = json['client'] != null ? ClientGTR.fromJson(json['client']) : null;
    cashbox =
        json['cashbox'] != null ? Cashbox.fromJson(json['cashbox']) : null;
    createdBy = json['created_by'] != null
        ? CreatedByGTR.fromJson(json['created_by'])
        : null;
    if (json['items'] != null) {
      items = <ItemsGTR>[];
      json['items'].forEach((v) {
        items!.add(ItemsGTR.fromJson(v));
      });
    }
    if (json['pays'] != null) {
      pays = <PaysGTR>[];
      json['pays'].forEach((v) {
        pays!.add(PaysGTR.fromJson(v));
      });
    }
    createTime = json['create_time'];
    cashierId = json['cashier_id'];
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['status'] = status;
    data['type'] = type;
    data['external_id'] = externalId;
    data['total_price'] = totalPrice;
    if (discount != null) {
      data['discount'] = discount!.toJson();
    }
    if (shop != null) {
      data['shop'] = shop!.toJson();
    }
    if (client != null) {
      data['client'] = client!.toJson();
    }
    if (cashbox != null) {
      data['cashbox'] = cashbox!.toJson();
    }
    if (createdBy != null) {
      data['created_by'] = createdBy!.toJson();
    }
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    if (pays != null) {
      data['pays'] = pays!.map((v) => v.toJson()).toList();
    }
    data['create_time'] = createTime;
    data['cashier_id'] = cashierId;
    data['url'] = url;
    return data;
  }
}

class DiscountGTR {
  num? price;
  num? value;
  String? type;

  DiscountGTR({this.price, this.value, this.type});

  DiscountGTR.fromJson(Map<String, dynamic> json) {
    price = json['price'];
    value = json['value'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['price'] = price;
    data['value'] = value;
    data['type'] = type;
    return data;
  }
}

class StatusGTR {
  String? name;
  StatusGTR({this.name});

  StatusGTR.fromJson(Map<String, dynamic> json) {
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['name'] = name;
    return data;
  }
}

class ShopGTR {
  String? id;
  String? title;
  String? address;
  String? phoneNumber;
  String? companyId;

  ShopGTR(
      {this.id, this.title, this.address, this.phoneNumber, this.companyId});

  ShopGTR.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    address = json['address'];
    phoneNumber = json['phone_number'];
    companyId = json['company_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['title'] = title;
    data['address'] = address;
    data['phone_number'] = phoneNumber;
    data['company_id'] = companyId;
    return data;
  }
}

class ClientGTR {
  String? id;
  String? firstName;
  String? lastName;
  String? phoneNumber;
  String? companyId;

  ClientGTR(
      {this.id,
      this.firstName,
      this.lastName,
      this.phoneNumber,
      this.companyId});

  ClientGTR.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    phoneNumber = json['phone_number'];
    companyId = json['company_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['phone_number'] = phoneNumber;
    data['company_id'] = companyId;
    return data;
  }
}

class Cashbox {
  String? id;
  String? title;
  String? shopId;
  String? companyId;

  Cashbox({this.id, this.title, this.shopId, this.companyId});

  Cashbox.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    shopId = json['shop_id'];
    companyId = json['company_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['title'] = title;
    data['shop_id'] = shopId;
    data['company_id'] = companyId;
    return data;
  }
}

class CreatedByGTR {
  String? id;
  String? firstName;
  String? lastName;
  String? phoneNumber;
  String? passCode;

  CreatedByGTR(
      {this.id,
      this.firstName,
      this.lastName,
      this.phoneNumber,
      this.passCode});

  CreatedByGTR.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    phoneNumber = json['phone_number'];
    passCode = json['pass_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['phone_number'] = phoneNumber;
    data['pass_code'] = passCode;
    return data;
  }
}

class ItemsGTR {
  String? id;
  String? productName;
  String? productId;
  num? productStock;
  num? value;
  num? refundAmount;
  num? lastRefundAmount;
  num? price;
  num? singleDiscount;
  num? supplyPrice;
  num? totalPrice;
  num? newPrice;
  SellerGTR? seller;
  String? orderId;
  String? barcode;
  String? sku;
  String? mxikCode;
  String? image;
  String? vatName;
  String? packageName;
  String? packageCode;
  num? vatPercentage;
  DiscountGTR? discount;

  ItemsGTR(
      {this.id,
      this.packageCode,
      this.packageName,
      this.productName,
      this.productId,
      this.singleDiscount,
      this.productStock,
      this.value,
      this.refundAmount,
      this.lastRefundAmount,
      this.price,
      this.supplyPrice,
      this.totalPrice,
      this.newPrice,
      this.seller,
      this.orderId,
      this.barcode,
      this.sku,
      this.mxikCode,
      this.image,
      this.vatName,
      this.vatPercentage,
      this.discount});

  ItemsGTR.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productName = json['product_name'];
    productId = json['product_id'];
    productStock = json['product_stock'];
    value = json['value'];
    refundAmount = json['refund_amount'];
    lastRefundAmount = json['last_refund_amount'];
    price = json['price'];
    supplyPrice = json['supply_price'];
    totalPrice = json['total_price'];
    newPrice = json['new_price'];
    seller = json['seller'] != null ? SellerGTR.fromJson(json['seller']) : null;
    orderId = json['order_id'];
    barcode = json['barcode'];
    sku = json['sku'];
    singleDiscount = json['single_item_discount'];
    mxikCode = json['mxik_code'];
    image = json['image'];
    vatName = json['vat_name'];
    packageCode = json['package_code'];
    packageName = json['package_name'];
    vatPercentage = json['vat_percentage'];
    discount = json['discount'] != null
        ? DiscountGTR.fromJson(json['discount'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['product_name'] = productName;
    data['product_id'] = productId;
    data['product_stock'] = productStock;
    data['value'] = value;
    data['refund_amount'] = refundAmount;
    data['last_refund_amount'] = lastRefundAmount;
    data['price'] = price;
    data['single_item_discount'] = singleDiscount;
    data['supply_price'] = supplyPrice;
    data['total_price'] = totalPrice;
    data['new_price'] = newPrice;
    if (seller != null) {
      data['seller'] = seller!.toJson();
    }
    data['order_id'] = orderId;
    data['barcode'] = barcode;
    data['sku'] = sku;
    data['mxik_code'] = mxikCode;
    data['image'] = image;
    data['vat_name'] = vatName;
    data['vat_percentage'] = vatPercentage;
    if (discount != null) {
      data['discount'] = discount!.toJson();
    }
    return data;
  }
}

class SellerGTR {
  String? id;
  String? firstName;
  String? lastName;
  String? image;
  String? color;
  String? phoneNumber;
  String? passCode;

  SellerGTR(
      {this.id,
      this.firstName,
      this.lastName,
      this.image,
      this.color,
      this.phoneNumber,
      this.passCode});

  SellerGTR.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    image = json['image'];
    color = json['color'];
    phoneNumber = json['phone_number'];
    passCode = json['pass_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['image'] = image;
    data['color'] = color;
    data['phone_number'] = phoneNumber;
    data['pass_code'] = passCode;
    return data;
  }
}

class PaysGTR {
  String? id;
  num? value;
  String? orderId;
  PaymentTypeGTR? paymentType;

  PaysGTR({this.id, this.value, this.orderId, this.paymentType});

  PaysGTR.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    value = json['value'];
    orderId = json['order_id'];
    paymentType = json['payment_type'] != null
        ? PaymentTypeGTR.fromJson(json['payment_type'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['value'] = value;
    data['order_id'] = orderId;
    if (paymentType != null) {
      data['payment_type'] = paymentType!.toJson();
    }
    return data;
  }
}

class PaymentTypeGTR {
  String? id;
  String? name;
  String? companyId;

  PaymentTypeGTR({this.id, this.name, this.companyId});

  PaymentTypeGTR.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    companyId = json['company_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['company_id'] = companyId;
    return data;
  }
}
