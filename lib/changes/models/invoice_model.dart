import 'dart:convert';

class InvoiceModel {
  final String id;
  final CreatedBy createdBy;
  final Shop shop;
  final String externalId;
  final DateTime createdDate;
  final Status status;
  final List<InvoiceItem> items;
  final Client client;
  final String comment;

  InvoiceModel({
    required this.id,
    required this.createdBy,
    required this.shop,
    required this.externalId,
    required this.createdDate,
    required this.status,
    required this.items,
    required this.client,
    required this.comment,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      createdBy: CreatedBy.fromJson(json['created_by'] as Map<String, dynamic>),
      shop: Shop.fromJson(json['shop'] as Map<String, dynamic>),
      externalId: json['external_id'] as String,
      createdDate: DateTime.parse(json['created_date'] as String),
      status: Status.fromJson(json['status'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>)
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      client: json['client'] == null
          ? Client(id: '', firstName: '', lastName: '')
          : Client.fromJson(json['client'] as Map<String, dynamic>),
      comment: json['comment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': createdBy.toJson(),
      'shop': shop.toJson(),
      'external_id': externalId,
      'created_date': createdDate.toIso8601String(),
      'status': status.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'client': client.toJson(),
      'comment': comment,
    };
  }
}

// =========================================

class CreatedBy {
  final String id;
  final String firstName;
  final String lastName;

  CreatedBy({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
  };
}

class Shop {
  final String id;
  final String name;
  final bool isAdded;

  Shop({
    required this.id,
    required this.name,
    required this.isAdded,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      name: json['name'],
      isAdded: json['is_added'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'is_added': isAdded,
  };
}

class Status {
  final String id;
  final String name;
  final Map<String, String> translation;

  Status({
    required this.id,
    required this.name,
    required this.translation,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      id: json['id'],
      name: json['name'],
      translation: Map<String, String>.from(json['translation']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'translation': translation,
  };
}

class Client {
  final String id;
  final String firstName;
  final String lastName;

  Client({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
  };
}

class InvoiceItem {
  final String id;
  final String productId;
  final String productName;
  final String barcode;
  final String sku;
  final int expectedAmount;
  final double cost;
  final double totalAmount;
  final String invoiceId;
  final int productStock;
  final List<Price> prices;
  final List<RealPrice> realPrices;

  InvoiceItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.sku,
    required this.expectedAmount,
    required this.cost,
    required this.totalAmount,
    required this.invoiceId,
    required this.productStock,
    required this.prices,
    required this.realPrices,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      barcode: json['barcode']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      expectedAmount: json['expected_amount'] as int,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      invoiceId: json['invoice_id'] as String,
      productStock: json['product_stock'] as int? ?? 0,
      prices: (json['prices'] as List<dynamic>)
          .map((e) => Price.fromJson(e as Map<String, dynamic>))
          .toList(),
      realPrices: (json['real_prices'] as List<dynamic>?)
          ?.map((e) => RealPrice.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'barcode': barcode,
    'sku': sku,
    'expected_amount': expectedAmount,
    'cost': cost,
    'total_amount': totalAmount,
    'invoice_id': invoiceId,
    'product_stock': productStock,
    'prices': prices.map((e) => e.toJson()).toList(),
    'real_prices': realPrices.map((e) => e.toJson()).toList(),
  };
}

class Price {
  final int minQuantity;
  final double price;
  final String invoiceItemId;

  Price({
    required this.minQuantity,
    required this.price,
    required this.invoiceItemId,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      minQuantity: json['min_quantity'],
      price: json['price']?.toDouble() ?? 0.0,
      invoiceItemId: json['invoice_item_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'min_quantity': minQuantity,
    'price': price,
    'invoice_item_id': invoiceItemId,
  };
}

class RealPrice {
  final int minQuantity;
  final double price;
  final String invoiceItemId;

  RealPrice({
    required this.minQuantity,
    required this.price,
    required this.invoiceItemId,
  });

  factory RealPrice.fromJson(Map<String, dynamic> json) {
    return RealPrice(
      minQuantity: json['min_quantity'],
      price: json['price']?.toDouble() ?? 0.0,
      invoiceItemId: json['invoice_item_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'min_quantity': minQuantity,
    'price': price,
    'invoice_item_id': invoiceItemId,
  };
}