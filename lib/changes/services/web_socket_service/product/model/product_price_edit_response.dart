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
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    isRead = json['is_read'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = this.id;
    data['company_id'] = this.companyId;
    data['shop_id'] = this.shopId;
    data['type'] = this.type;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['is_read'] = this.isRead;
    data['created_at'] = this.createdAt;
    return data;
  }
}

class Data {
  Request? request;
  List<ProductsValues>? productsValues;

  Data({this.request, this.productsValues});

  Data.fromJson(Map<String, dynamic> json) {
    request =
        json['request'] != null ? new Request.fromJson(json['request']) : null;
    if (json['product_values'] != null) {
      productsValues = <ProductsValues>[];
      json['product_values'].forEach((v) {
        productsValues!.add(new ProductsValues.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.request != null) {
      data['request'] = this.request!.toJson();
    }
    if (this.productsValues != null) {
      data['product_values'] =
          this.productsValues!.map((v) => v.toJson()).toList();
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
    data['company_id'] = this.companyId;
    data['user_id'] = this.userId;
    data['user_type_id'] = this.userTypeId;
    data['timezone'] = this.timezone;
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
    if (this.price != null) {
      data['price'] = this.price!.toJson();
    }
    data['product_id'] = this.productId;
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
        shopPriceTiers!.add(new ShopPriceTiersSub.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['shop_id'] = this.shopId;
    data['retail_price'] = this.retailPrice;
    data['supply_price'] = this.supplyPrice;
    data['last_supply_price'] = this.lastSupplyPrice;
    if (this.shopPriceTiers != null) {
      data['shop_price_tiers'] =
          this.shopPriceTiers!.map((v) => v.toJson()).toList();
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
