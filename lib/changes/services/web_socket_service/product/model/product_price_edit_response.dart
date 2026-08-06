/*
    @author Suxrob Sattorov, 11/11/2024, 10:47 AM
*/

class ProductPriceEdit {
  String? id;
  String? companyId;
  String? shopId;
  int? type;
  Data? data;
  bool? isRead;
  String? createdAt;

  ProductPriceEdit(
      {this.id,
      this.companyId,
      this.shopId,
      this.type,
      this.data,
      this.isRead,
      this.createdAt});

  ProductPriceEdit.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['company_id'];
    shopId = json['shop_id'];
    type = json['type'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    isRead = json['is_read'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['company_id'] = companyId;
    data['shop_id'] = shopId;
    data['type'] = type;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['is_read'] = isRead;
    data['created_at'] = createdAt;
    return data;
  }
}

class Data {
  Request? request;
  List<ProductsValues>? productsValues;

  Data({this.request, this.productsValues});

  Data.fromJson(Map<String, dynamic> json) {
    request =
        json['request'] != null ? Request.fromJson(json['request']) : null;
    if (json['product_values'] != null) {
      productsValues = <ProductsValues>[];
      json['product_values'].forEach((v) {
        productsValues!.add(ProductsValues.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (request != null) {
      data['request'] = request!.toJson();
    }
    if (productsValues != null) {
      data['product_values'] =
          productsValues!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Request {
  String? companyId;
  String? userId;
  String? userTypeId;
  int? timezone;

  Request({this.companyId, this.userId, this.userTypeId, this.timezone});

  Request.fromJson(Map<String, dynamic> json) {
    companyId = json['company_id'];
    userId = json['user_id'];
    userTypeId = json['user_type_id'];
    timezone = json['timezone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['company_id'] = companyId;
    data['user_id'] = userId;
    data['user_type_id'] = userTypeId;
    data['timezone'] = timezone;
    return data;
  }
}

class ProductsValues {
  Price? price;
  String? productId;

  ProductsValues({this.price, this.productId});

  ProductsValues.fromJson(Map<String, dynamic> json) {
    price = json['price'] != null ? Price.fromJson(json['price']) : null;
    productId = json['product_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (price != null) {
      data['price'] = price!.toJson();
    }
    data['product_id'] = productId;
    return data;
  }
}

class Price {
  String? shopId;
  num? retailPrice;
  num? supplyPrice;
  num? lastSupplyPrice;
  List<ShopPriceTiersSub>? shopPriceTiers;

  Price({
    this.shopId,
    this.retailPrice,
    this.supplyPrice,
    this.lastSupplyPrice,
    this.shopPriceTiers,
  });

  Price.fromJson(Map<String, dynamic> json) {
    shopId = json['shop_id'];
    retailPrice = json['retail_price'];
    supplyPrice = json['supply_price'];
    lastSupplyPrice = json['last_supply_price'];
    if (json['shop_price_tiers'] != null) {
      shopPriceTiers = <ShopPriceTiersSub>[];
      json['shop_price_tiers'].forEach((v) {
        shopPriceTiers!.add(ShopPriceTiersSub.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['shop_id'] = shopId;
    data['retail_price'] = retailPrice;
    data['supply_price'] = supplyPrice;
    data['last_supply_price'] = lastSupplyPrice;
    if (shopPriceTiers != null) {
      data['shop_price_tiers'] =
          shopPriceTiers!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ShopPriceTiersSub {
  int? minQuantity;
  num? retailPrice;

  ShopPriceTiersSub({this.minQuantity, this.retailPrice});

  ShopPriceTiersSub.fromJson(Map<String, dynamic> json) {
    minQuantity = json['min_quantity'];
    retailPrice = json['retail_price'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['min_quantity'] = minQuantity;
    data['retail_price'] = retailPrice;
    return data;
  }
}
