// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:hive/hive.dart';
import 'package:invan2/changes/dialogs/creat_product/model/mes_vat_unit_model/mes_unit.dart';
import 'package:invan2/features/hive_repository/hive_types.dart';
import 'package:invan2/utils/utils.dart';
import '../../../features/hive_repository/hive_boxes.dart';
import '../../services/api/api_provider.dart';

part 'item_model.g.dart';

// @HiveType(typeId: 29)

@HiveType(typeId: 23)
class ItemModel extends HiveObject {
  @override
  get key => id;
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? sku;
  @HiveField(2)
  String? name;
  @HiveField(3)
  String? image;
  @HiveField(4)
  bool? isMarking;
  @HiveField(5)
  bool? isActive;
  @HiveField(6)
  String? mxikCode;
  @HiveField(7)
  String? parentId;
  @HiveField(8)
  String? companyId;
  @HiveField(9)
  String? description;
  @HiveField(10)
  String? productTypeId;
  @HiveField(11)
  ShopPrices? shopPrices;
  @HiveField(12)
  List<CategoriesFromProducts>? categories;
  @HiveField(13)
  MeasurementUnit? measurementUnit;
  @HiveField(14)
  Vat? vat;
  @HiveField(15)
  String? packageCode;
  @HiveField(16)
  String? packageType;
  @HiveField(17)
  String? packageName;
  @HiveField(18)
  String? commissionTin;
  @HiveField(19)
  String? mark;
  @HiveField(20)
  String? ownerType;
  @HiveField(21)
  List<String>? barcode;

  @HiveField(22)
  String? boxBarcode;
  @HiveField(23)
  num? boxBarcodeQuantity;
  @HiveField(24)
  bool? hasBoxBarcode;

  @HiveField(25)
  int? cashsale;

  ItemModel({
    this.id,
    this.sku,
    this.name,
    this.image,
    this.isMarking,
    this.isActive,
    this.mxikCode,
    this.parentId,
    this.companyId,
    this.description,
    this.productTypeId,
    this.shopPrices,
    this.categories,
    this.measurementUnit,
    this.vat,
    this.packageCode,
    this.packageType,
    this.packageName,
    this.commissionTin,
    this.mark,
    this.barcode,
    this.ownerType,
    this.boxBarcode,
    this.boxBarcodeQuantity,
    this.hasBoxBarcode,
    this.cashsale,
  });
  ItemModel copyWith({
    String? id,
    String? sku,
    String? name,
    String? image,
    bool? isMarking,
    bool? isActive,
    String? mxikCode,
    String? parentId,
    String? companyId,
    String? description,
    String? productTypeId,
    ShopPrices? shopPrices,
    List<CategoriesFromProducts>? categories,
    MeasurementUnit? measurementUnit,
    Vat? vat,
    String? packageCode,
    String? packageType,
    String? packageName,
    String? commissionTin,
    String? mark,
    String? ownerType,
    List<String>? barcode,
    String? boxBarcode,
    num? boxBarcodeQuantity,
    bool? hasBoxBarcode,
    int? cashsale,
  }) {
    return ItemModel(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      image: image ?? this.image,
      isMarking: isMarking ?? this.isMarking,
      isActive: isActive ?? this.isActive,
      mxikCode: mxikCode ?? this.mxikCode,
      parentId: parentId ?? this.parentId,
      companyId: companyId ?? this.companyId,
      description: description ?? this.description,
      productTypeId: productTypeId ?? this.productTypeId,
      shopPrices: shopPrices ?? this.shopPrices,
      categories: categories ?? this.categories,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      vat: vat ?? this.vat,
      packageCode: packageCode ?? this.packageCode,
      packageType: packageType ?? this.packageType,
      packageName: packageName ?? this.packageName,
      commissionTin: commissionTin ?? this.commissionTin,
      mark: mark ?? this.mark,
      ownerType: ownerType ?? this.ownerType,
      barcode: barcode ?? this.barcode,
      boxBarcode: boxBarcode ?? this.boxBarcode,
      boxBarcodeQuantity: boxBarcodeQuantity ?? this.boxBarcodeQuantity,
      hasBoxBarcode: hasBoxBarcode ?? this.hasBoxBarcode,
      cashsale: cashsale ?? this.cashsale,
    );
  }
  ItemModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sku = json['sku'];
    name = json['name'];
    image = json['image'];
    isMarking = json['is_marking'];
    isActive = json['is_active'];
    mxikCode = json['mxik_code'];
    parentId = json['parent_id'];
    companyId = json['company_id'];
    description = json['description'];
    productTypeId = json['product_type_id'];
    barcode = List<String>.from(
      (json["barcode"] ?? <String>[]).map((x) => x.toString()),
    );
    shopPrices = json['shop_prices'] != null
        ? ShopPrices.fromJson(json["shop_prices"])
        : null;
    if (json['categories'] != null) {
      categories = <CategoriesFromProducts>[];
      json['categories'].forEach((v) {
        categories!.add(CategoriesFromProducts.fromJson(v));
      });
    }
    measurementUnit = json['measurement_unit'] != null
        ? MeasurementUnit.fromJson(json['measurement_unit'])
        : null;
    vat = json['vat'] != null ? Vat.fromJson(json['vat']) : null;
    packageCode = json['package_code'];
    packageType = json['package_type'];
    packageName = json['package_name'];
    ownerType = json['owner_type'];
    boxBarcode = json['box_barcode'];
    boxBarcodeQuantity = json['box_barcode_quantity'];
    hasBoxBarcode = json['has_box_barcode'];
    cashsale = ((json['cash_sale'] as num?) ?? 1).toInt();
  }

  ItemModel.fromWebSocketJson(Map<String, dynamic> json) {
    id = json['product_id'];
    sku = json['sku'];
    name = json['name'];
    image = json['images'] != null
        ? ApiProvider.imageUrl + json['images'][0]['image_url']
        : null;
    isMarking = json['is_marking'];
    isActive = json['is_active'];
    mxikCode = json['mxik_code'];
    parentId = json['parent_id'];
    companyId = json['company_id'];
    description = json['description'];
    productTypeId = json['product_type_id'];
    barcode = List<String>.from(
      (json["barcode"] ?? <String>[]).map((x) => x.toString()),
    );

    if (json['shop_prices'] != null) {
      List<ShID> shops = <ShID>[];

      json['shop_prices'].forEach((v) {
        shops.add(ShID.fromJson(v));
      });

      var filteredShops = shops
          .where((e) => e.shopId == Pref.getString(PrefKeys.storeId, ""))
          .toList();

      if (filteredShops.isNotEmpty) {
        shopPrices = ShopPrices(shID: filteredShops.first);
      }
    }

    if (json['categories'] != null) {
      categories = <CategoriesFromProducts>[];
      json['categories'].forEach((v) {
        categories!.add(CategoriesFromProducts(id: v));
      });
    }

    {
      List<MesUnitModel> mesUnits = [];
      final Box<MesUnitModel> mesUnitModel = HiveBoxes.mesUnitBox();
      mesUnits = mesUnitModel.values.toList().where((e) {
        return e.id == json['measurement_unit_id'];
      }).toList();
      MeasurementUnit mess = MeasurementUnit();
      if (mesUnits.isNotEmpty) {
        mess = MeasurementUnit(
          id: mesUnits.first.id ?? "",
          longName: mesUnits.first.longName ?? "",
          shortName: mesUnits.first.shortName ?? "",
        );
      }
      measurementUnit = json['measurement_unit_id'] != null ? mess : null;
    }

    {
      List<VatUnitModel> vatUnits = [];
      final Box<VatUnitModel> vatUnitModel = HiveBoxes.vatUnitBox();
      vatUnits = vatUnitModel.values.toList().where((e) {
        return e.id == json['vat_id'];
      }).toList();
      Vat vatt = Vat();
      if (vatUnits.isNotEmpty) {
        vatt = Vat(
          id: vatUnits.first.id,
          name: vatUnits.first.name,
          percentage: vatUnits.first.percentage,
        );
      }
      vat = json['vat_id'] != null ? vatt : null;
    }

    packageCode = json['package_code'];
    packageType = json['package_type'];
    packageName = json['package_name'];
    boxBarcode = json['box_barcode'];
    boxBarcodeQuantity = json['box_barcode_quantity'];
    hasBoxBarcode = json['has_box_barcode'];
    cashsale = ((json['cash_sale'] as num?) ?? 1).toInt();
  }

  ItemModel.fromWebSocketJsonUpdate(Map<String, dynamic> json) {
    id = json['id'];
    sku = json['sku'];
    name = json['name'];
    image = json['images'] != null
        ? ApiProvider.imageUrl + json['images'][0]['image_url']
        : null;
    isMarking = json['is_marking'];
    isActive = json['is_active'];
    mxikCode = json['mxik_code'];
    parentId = json['parent_id'];
    ownerType = json['owner_type'];
    companyId = json['company_id'];
    description = json['description'];
    productTypeId = json['product_type_id'];
    barcode = List<String>.from(
      (json["barcode"] ?? <String>[]).map((x) => x.toString()),
    );
    // shopPrices = json['shop_prices'] != null
    //     ? ShopPrices.fromJson(json["shop_prices"])
    //     : null;

    if (json['shop_prices'] != null) {
      List<ShID> shops = <ShID>[];

      json['shop_prices'].forEach((v) {
        shops.add(ShID.fromJson(v));
      });

      var filteredShops = shops
          .where((e) => e.shopId == Pref.getString(PrefKeys.storeId, ""))
          .toList();

      if (filteredShops.isNotEmpty) {
        shopPrices = ShopPrices(shID: filteredShops.first);
      }
    }

    if (json['categories'] != null) {
      categories = <CategoriesFromProducts>[];
      json['categories'].forEach((v) {
        categories!.add(CategoriesFromProducts.fromJson(v));
      });
    }

    {
      List<MesUnitModel> mesUnits = [];
      final Box<MesUnitModel> mesUnitModel = HiveBoxes.mesUnitBox();
      mesUnits = mesUnitModel.values.toList().where((e) {
        return e.id == json['measurement_unit_id'];
      }).toList();

      MeasurementUnit mess = MeasurementUnit();
      if (mesUnits.isNotEmpty) {
        mess = MeasurementUnit(
          id: mesUnits.first.id ?? "",
          shortName: mesUnits.first.shortName ?? "",
          longName: mesUnits.first.longName ?? "",
        );
      }
      measurementUnit = json['measurement_unit_id'] != null ? mess : null;
    }

    {
      List<VatUnitModel> vatUnits = [];
      final Box<VatUnitModel> vatUnitModel = HiveBoxes.vatUnitBox();
      vatUnits = vatUnitModel.values.toList().where((e) {
        return e.id == json['vat_id'];
      }).toList();
      Vat vatt = Vat();
      if (vatUnits.isNotEmpty) {
        vatt = Vat(
          id: vatUnits.first.id,
          name: vatUnits.first.name,
          percentage: vatUnits.first.percentage,
        );
      }
      vat = json['vat_id'] != null ? vatt : null;
      packageCode = json['package_code'];
      packageType = json['package_type'];
      packageName = json['package_name'];
      boxBarcode = json['box_barcode'];
      boxBarcodeQuantity = json['box_barcode_quantity'];
      hasBoxBarcode = json['has_box_barcode'];
      cashsale = ((json['cash_sale'] as num?) ?? 1).toInt();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['sku'] = sku;
    data['name'] = name;
    data['image'] = image;
    data['is_marking'] = isMarking;
    data['is_active'] = isActive;
    data['mxik_code'] = mxikCode;
    data['parent_id'] = parentId;
    data['company_id'] = companyId;
    data['description'] = description;
    data['product_type_id'] = productTypeId;
    // data['barcode'] = barcode;
    data["barcode"] = List<dynamic>.from((barcode ?? []).map((x) => x));
    if (shopPrices != null) {
      data['shop_prices'] = shopPrices!.toJson();
    }
    if (categories != null) {
      data['categories'] = categories!.map((v) => v.toJson()).toList();
    }
    if (measurementUnit != null) {
      data['measurement_unit'] = measurementUnit!.toJson();
    }
    if (vat != null) {
      data['vat'] = vat!.toJson();
    }
    data['package_code'] = packageCode;
    data['package_type'] = packageType;
    data['package_name'] = packageName;
    data['mark'] = mark;
    data['owner_type'] = ownerType;
    data['box_barcode'] = boxBarcode;
    data['box_barcode_quantity'] = boxBarcodeQuantity;
    data['has_box_barcode'] = hasBoxBarcode;
    data['cashsale'] = cashsale;

    return data;
  }
}

@HiveType(typeId: HiveTypes.shopPrices)
class ShopPrices extends HiveObject {
  @HiveField(0)
  ShID? shID;

  ShopPrices({this.shID});

  ShopPrices.fromJson(Map<String, dynamic> json) {
    shID = json[Pref.getString(PrefKeys.acceptService, "")] != null
        ? ShID.fromJson(json[Pref.getString(PrefKeys.acceptService, "")])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (shID != null) {
      data[Pref.getString(PrefKeys.acceptService, "")] = shID!.toJson();
    }
    return data;
  }
}

@HiveType(typeId: HiveTypes.shID)
class ShID extends HiveObject {
  @HiveField(0)
  String? shopId;
  @HiveField(1)
  num? supplyPrice;
  @HiveField(2)
  List<ShopPriceTiers>? shopPriceTiers;

  ShID({
    this.shopId,
    this.supplyPrice,
    this.shopPriceTiers,
  });

  ShID.fromJson(Map<String, dynamic> json) {
    shopId = json['shop_id'];
    supplyPrice = json['supply_price'];
    if (json['shop_price_tiers'] != null) {
      shopPriceTiers = <ShopPriceTiers>[];
      json['shop_price_tiers'].forEach((v) {
        shopPriceTiers!.add(ShopPriceTiers.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['shop_id'] = shopId;
    data['supply_price'] = supplyPrice;
    if (shopPriceTiers != null) {
      data['shop_price_tiers'] =
          shopPriceTiers!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

@HiveType(typeId: HiveTypes.shopPriceTiers)
class ShopPriceTiers extends HiveObject {
  @HiveField(0)
  int? minQuantity;
  @HiveField(1)
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

@HiveType(typeId: HiveTypes.categoriesFromProducts)
class CategoriesFromProducts extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;
  @HiveField(2)
  String? parentId;

  CategoriesFromProducts({this.id, this.name, this.parentId});

  CategoriesFromProducts.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    parentId = json['parent_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['parent_id'] = parentId;
    return data;
  }
}

@HiveType(typeId: HiveTypes.measurementUnit)
class MeasurementUnit extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? shortName;
  @HiveField(2)
  String? longName;
  @HiveField(3)
  bool? isDeletable;

  MeasurementUnit({
    this.id,
    this.shortName,
    this.longName,
    this.isDeletable,
  });

  MeasurementUnit.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    shortName = json['short_name'];
    longName = json['long_name'];
    isDeletable = json['is_deletable'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['short_name'] = shortName;
    data['long_name'] = longName;
    data['is_deletable'] = isDeletable;
    return data;
  }
}

@HiveType(typeId: HiveTypes.vat)
class Vat extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;
  @HiveField(2)
  int? percentage;

  Vat({
    this.id,
    this.name,
    this.percentage,
  });

  Vat.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    percentage = json['percentage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['percentage'] = percentage;
    return data;
  }
}
