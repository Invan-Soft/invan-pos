class CreatProductToInvanModel {
  List<String?> barcode;
  String? brandId;
  String? categoryId;
  List? categoryIds;
  List? customFields;
  String? description;
  List? images;
  bool? isActive;
  bool? isMarking;
  String? measurementUnitId;
  List<MeasurementValuesToInvan2Model>? measurementValues;
  String? mxikCode;
  String? name;
  bool? noLoyalty;
  String? packageCode;
  String? packageName;
  String? packageType;
  String? productTypeId;
  List<ShopPricesToInvan2Model>? shopPrices;
  String? sku;
  List? tags;
  String? vatId;

  CreatProductToInvanModel(
      {required this.barcode,
      this.brandId,
      this.categoryId,
      this.categoryIds,
      this.customFields,
      this.description,
      this.images,
      this.isActive,
      this.isMarking,
      this.measurementUnitId,
      this.measurementValues,
      this.mxikCode,
      this.name,
      this.noLoyalty,
      this.packageCode,
      this.packageName,
      this.packageType,
      this.productTypeId,
      this.shopPrices,
      this.sku,
      this.tags,
      this.vatId});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['barcode'] = barcode;
    data['brand_id'] = brandId;
    data['category_id'] = [];
    data['custom_fields'] = [];
    data['description'] = description;
    data['images'] = [];

    data['is_active'] = isActive;
    data['is_marking'] = isMarking;
    data['measurement_unit_id'] = measurementUnitId;
    if (measurementValues != null) {
      data['measurement_values'] =
          measurementValues!.map((v) => v.toJson()).toList();
    }
    data['mxik_code'] = mxikCode;
    data['name'] = name;
    data['no_loyalty'] = noLoyalty;
    data['package_code'] = packageCode;
    data['package_name'] = packageName;
    data['package_type'] = packageType;
    data['product_type_id'] = productTypeId;
    if (shopPrices != null) {
      data['shop_prices'] = shopPrices!.map((v) => v.toJson()).toList();
    }
    data['sku'] = sku;
    data['tags'] = [];
    data['vat_id'] = vatId;
    return data;
  }
}

class MeasurementValuesToInvan2Model {
  int? amount;
  bool? hasTrigger;
  bool? isAvailable;
  int? smallLeft;
  String? title;
  String? shopId;

  MeasurementValuesToInvan2Model({
    this.amount,
    this.hasTrigger,
    this.isAvailable,
    this.smallLeft,
    this.shopId,
    this.title,
  });

  MeasurementValuesToInvan2Model.fromJson(Map<String, dynamic> json) {
    amount = json['amount'];
    hasTrigger = json['has_trigger'];
    isAvailable = json['is_available'];
    smallLeft = json['small_left'];
    title = json['title'];
    shopId = json['shop_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['amount'] = amount;
    data['has_trigger'] = hasTrigger;
    data['is_available'] = isAvailable;
    data['small_left'] = smallLeft;
    data['title'] = title;
    data['shop_id'] = shopId;
    return data;
  }
}

class ShopPricesToInvan2Model {
  double? maxPrice;
  double? minPrice;
  double? retailPrice;
  String? shopId;
  double? supplyPrice;
  double? wholeSalePrice;
  List<ShopPriceTiers>? shopPriceTiers;

  ShopPricesToInvan2Model({
    this.shopId,
    this.retailPrice,
    this.supplyPrice,
    this.minPrice,
    this.maxPrice,
    this.wholeSalePrice,
    this.shopPriceTiers,
  });

  ShopPricesToInvan2Model.fromJson(Map<String, dynamic> json) {
    maxPrice = json['max_price'];
    minPrice = json['min_price'];
    retailPrice = json['retail_price'];
    shopId = json['shop_id'];
    supplyPrice = json['supply_price'];
    wholeSalePrice = json['whole_sale_price'];
    if (json['shop_price_tiers'] != null) {
      shopPriceTiers = <ShopPriceTiers>[];
      json['shop_price_tiers'].forEach((v) {
        shopPriceTiers!.add(new ShopPriceTiers.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['max_price'] = maxPrice;
    data['min_price'] = minPrice;
    data['retail_price'] = retailPrice;
    data['shop_id'] = shopId;
    data['supply_price'] = supplyPrice;
    data['whole_sale_price'] = wholeSalePrice;
    if (this.shopPriceTiers != null) {
      data['shop_price_tiers'] =
          this.shopPriceTiers!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ShopPriceTiers {
  int? minQuantity;
  num? retailPrice;

  ShopPriceTiers({this.minQuantity, this.retailPrice});

  ShopPriceTiers.fromJson(Map<String, dynamic> json) {
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
