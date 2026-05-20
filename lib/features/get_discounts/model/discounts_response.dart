/*
    @author Suxrob Sattorov, 1/25/2025, 11:21 AM
*/

// ignore_for_file: unnecessary_getters_setters
import 'package:hive/hive.dart';

import '../../hive_repository/hive_types.dart';

part 'discounts_response.g.dart';

@HiveType(typeId: HiveTypes.discounts)
class DiscountsResponse extends HiveObject {
  @HiveField(0)
  List<DiscountItem>? data;

  @HiveField(1)
  int? total;

  DiscountsResponse({this.data, this.total});

  DiscountsResponse.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <DiscountItem>[];
      json['data'].forEach((v) {
        data!.add(DiscountItem.fromJson(v));
      });
    }
    total = json['total'];
  }

  Map<String, dynamic> toJson() => {
        'data': data?.map((v) => v.toJson()).toList(),
        'total': total,
      };

  Map<String, dynamic> toMap() => toJson();
}

@HiveType(typeId: HiveTypes.discountData)
class DiscountItem extends HiveObject {
  @HiveField(0)
  String? name;
  @HiveField(1)
  String? displayName;
  @HiveField(2)
  DiscountType? discountType;
  @HiveField(3)
  DiscountGroupType? discountGroupType;
  @HiveField(4)
  int? discountValue;
  @HiveField(5)
  bool? isExpirable;
  @HiveField(6)
  String? startDate;
  @HiveField(7)
  String? expireDate;
  @HiveField(8)
  bool? isAllProducts;
  @HiveField(9)
  List<ProductIds>? productIds;
  @HiveField(10)
  List<CategoryIds>? categoryIds;
  @HiveField(11)
  String? id;
  @HiveField(12)
  List<DiscountSchedules>? discountSchedules;
  @HiveField(13)
  bool? isWholeDay;
  @HiveField(14)
  List<CustomerGroups>? customerGroups;
  @HiveField(15)
  List<ShopIds>? shopIds;
  @HiveField(16)
  BuyXGetY? buyXGetY;
  @HiveField(17)
  bool? isRepeatable;
  @HiveField(18)
  bool? isForAllClients;
  @HiveField(19)
  List<Gifts>? gifts;
  @HiveField(20)
  BuyXGetX? buyXGetX;
  DiscountItem({
    this.id,
    this.name,
    this.displayName,
    this.discountType,
    this.discountGroupType,
    this.discountValue,
    this.isExpirable,
    this.startDate,
    this.expireDate,
    this.isAllProducts,
    this.productIds,
    this.categoryIds,
    this.discountSchedules,
    this.isWholeDay,
    this.customerGroups,
    this.shopIds,
    this.buyXGetY,
    this.isRepeatable,
    this.isForAllClients,
    this.gifts,
    this.buyXGetX
  });

  DiscountItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    displayName = json['display_name'];
    discountType = json['discount_type'] != null
        ? (json['discount_type'] is String)
            ? DiscountType(id: json['discount_type'])
            : DiscountType.fromJson(json['discount_type'])
        : null;
    discountGroupType = json['discount_group_type'] != null
        ? (json['discount_group_type'] is String)
            ? DiscountGroupType(id: json['discount_group_type'])
            : DiscountGroupType.fromJson(json['discount_group_type'])
        : null;
    discountValue = json['discount_value'];
    isExpirable = json['is_expirable'];
    startDate = json['start_date'];
    expireDate = json['expire_date'];
    isAllProducts = json['is_all_products'];
    if (json['product_ids'] != null) {
      productIds = (json['product_ids'] as List).map(
        (e) {
          if (e is String) {
            return ProductIds(id: e);
          }
          return ProductIds.fromJson(e);
        },
      ).toList();
    }
    if (json['category_ids'] != null) {
      categoryIds = (json['category_ids'] as List).map(
        (e) {
          if (e is String) {
            return CategoryIds(id: e);
          }
          return CategoryIds.fromJson(e);
        },
      ).toList();
    }
    if (json['discount_schedules'] != null) {
      discountSchedules = (json['discount_schedules'] as List)
          .map((v) => DiscountSchedules.fromJson(v))
          .toList();
    }
    isWholeDay = json['is_whole_day'];
    if (json['customer_groups'] != null) {
      customerGroups = (json['customer_groups'] as List).map(
        (e) {
          if (e is String) {
            return CustomerGroups(id: e);
          }
          return CustomerGroups.fromJson(e);
        },
      ).toList();
    }
    if (json['shop_ids'] != null) {
      shopIds = (json['shop_ids'] as List).map(
        (e) {
          if (e is String) {
            return ShopIds(id: e);
          }
          return ShopIds.fromJson(e);
        },
      ).toList();
    }
    buyXGetY = json['buy_x_get_y'] != null
        ? BuyXGetY.fromJson(json['buy_x_get_y'])
        : null;

    isRepeatable = json['is_repeatable'];
    isForAllClients = json['is_for_all_clients'];
    if (json['gifts'] != null) {
      gifts = <Gifts>[];
      json['gifts'].forEach((v) {
        gifts!.add(new Gifts.fromJson(v));
      });
    }
    buyXGetX = json['buy_x_get_x'] != null ? BuyXGetX.fromJson(json['buy_x_get_x']) : null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'display_name': displayName,
        'discount_type': discountType?.toJson(),
        'discount_group_type': discountGroupType?.toJson(),
        'discount_value': discountValue,
        'is_expirable': isExpirable,
        'start_date': startDate,
        'expire_date': expireDate,
        'is_all_products': isAllProducts,
        'product_ids': productIds?.map((v) => v.toJson()).toList(),
        'category_ids': categoryIds?.map((v) => v.toJson()).toList(),
        'discount_schedules':
            discountSchedules?.map((v) => v.toJson()).toList(),
        'is_whole_day': isWholeDay,
        'shop_ids': shopIds?.map((v) => v.toJson()).toList(),
        'customer_groups': customerGroups?.map((v) => v.toJson()).toList(),
    'buy_x_get_y': buyXGetY?.toJson(),
    'buy_x_get_x': buyXGetX?.toJson(),

    'is_repeatable': isRepeatable,
        'is_for_all_clients': isForAllClients,
        'gifts': gifts?.map((v) => v.toJson()).toList(),
      };

  Map<String, dynamic> toMap() => toJson();
}

@HiveType(typeId: HiveTypes.discountType)
class DiscountType {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? label;

  DiscountType({this.id, this.label});

  DiscountType.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        label = json['label'];

  Map<String, dynamic> toJson() => {'id': id, 'label': label};

  Map<String, dynamic> toMap() => toJson();
}

@HiveType(typeId: HiveTypes.discountGroupType)
class DiscountGroupType {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? label;

  DiscountGroupType({this.id, this.label});

  DiscountGroupType.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        label = json['label'];

  Map<String, dynamic> toJson() => {'id': id, 'label': label};

  Map<String, dynamic> toMap() => toJson();
}

@HiveType(typeId: HiveTypes.discountSchedules)
class DiscountSchedules {
  @HiveField(0)
  int? dayOfWeek;
  @HiveField(1)
  String? startTime;
  @HiveField(2)
  String? endTime;

  DiscountSchedules({this.dayOfWeek, this.startTime, this.endTime});

  DiscountSchedules.fromJson(Map<String, dynamic> json)
      : dayOfWeek = json['day_of_week'],
        startTime = json['start_time'],
        endTime = json['end_time'];

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
      };

  Map<String, dynamic> toMap() => toJson();
}

@HiveType(typeId: HiveTypes.discountByProduct)
class ProductIds extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;

  ProductIds({this.id, this.name});

  ProductIds.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'];

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  Map<String, dynamic> toMap() => toJson();
}

@HiveType(typeId: HiveTypes.discountByCategory)
class CategoryIds extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;

  CategoryIds({this.id, this.name});

  CategoryIds.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'];

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  Map<String, dynamic> toMap() => toJson();
}

@HiveType(typeId: HiveTypes.discountByCustomers)
class CustomerGroups extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;

  CustomerGroups({this.id, this.name});

  CustomerGroups.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'];

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  Map<String, dynamic> toMap() => toJson();
}

@HiveType(typeId: HiveTypes.discountByShops)
class ShopIds extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;

  ShopIds({this.id, this.name});

  ShopIds.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['label'];

  Map<String, dynamic> toJson() => {'id': id, 'label': name};

  Map<String, dynamic> toMap() => toJson();
}

@HiveType(typeId: HiveTypes.discountBuyXGetY)
class BuyXGetY {
  @HiveField(0)
  List<ProductsToBuy>? productsToBuy;
  @HiveField(1)
  num? buyProductsAmount;
  @HiveField(2)
  ProductsToGet? productToGet;
  @HiveField(3)
  num? getProductsAmount;

  BuyXGetY(
      {this.productsToBuy,
      this.buyProductsAmount,
      this.productToGet,
      this.getProductsAmount});

  BuyXGetY.fromJson(Map<String, dynamic> json) {
    if (json['products_to_buy'] != null) {
      productsToBuy = <ProductsToBuy>[];
      for (var v in json['products_to_buy']) {
        if (v is String) {
          productsToBuy!.add(ProductsToBuy(id: v, name: v));
        } else if (v is Map<String, dynamic>) {
          productsToBuy!.add(ProductsToBuy.fromJson(v));
        }
      }
    }
    buyProductsAmount = json['buy_products_amount'];
    productToGet = json['product_to_get'] != null
        ? (json['product_to_get'] is String
            ? ProductsToGet(
                id: json['product_to_get'], name: json['product_to_get'])
            : ProductsToGet.fromJson(json['product_to_get']))
        : null;
    getProductsAmount = json['get_products_amount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (productsToBuy != null) {
      data['products_to_buy'] = productsToBuy!.map((v) => v.toJson()).toList();
    }
    data['buy_products_amount'] = buyProductsAmount;
    if (productToGet != null) {
      data['product_to_get'] = productToGet!.toJson();
    }
    data['get_products_amount'] = getProductsAmount;
    return data;
  }
}



@HiveType(typeId: HiveTypes.discountBuyXGetX)
class BuyXGetX extends HiveObject {
  @HiveField(0)
  List<ProductsToBuy>? productsToBuy;

  @HiveField(1)
  num? buyProductsAmount;

  @HiveField(2)
  num? getProductsAmount;

  BuyXGetX({
    this.productsToBuy,
    this.buyProductsAmount,
    this.getProductsAmount,
  });

  BuyXGetX.fromJson(Map<String, dynamic> json) {
    if (json['products_to_buy'] != null) {
      productsToBuy = <ProductsToBuy>[];
      for (var v in json['products_to_buy']) {
        if (v is String) {
          productsToBuy!.add(ProductsToBuy(id: v, name: v));
        } else if (v is Map<String, dynamic>) {
          productsToBuy!.add(ProductsToBuy.fromJson(v));
        }
      }
    }
    buyProductsAmount = json['buy_products_amount'];
    getProductsAmount = json['get_products_amount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (productsToBuy != null) {
      data['products_to_buy'] = productsToBuy!.map((v) => v.toJson()).toList();
    }
    data['buy_products_amount'] = buyProductsAmount;
    data['get_products_amount'] = getProductsAmount;
    return data;
  }
}
@HiveType(typeId: HiveTypes.discountProductsToBuy)
class ProductsToBuy extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;

  ProductsToBuy({this.id, this.name});

  ProductsToBuy.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'];

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  Map<String, dynamic> toMap() => toJson();
}

@HiveType(typeId: HiveTypes.discountProductsToGet)
class ProductsToGet extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;

  ProductsToGet({this.id, this.name});

  ProductsToGet.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'];

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  Map<String, dynamic> toMap() => toJson();
}

@HiveType(typeId: HiveTypes.gifts)
class Gifts extends HiveObject {
  @HiveField(0)
  int? getProductAmount;
  @HiveField(1)
  int? buyAmount;
  @HiveField(2)
  ProductIds? getProduct;

  Gifts({this.getProductAmount, this.buyAmount, this.getProduct});

  Gifts.fromJson(Map<String, dynamic> json) {
    getProductAmount = json['get_product_amount'];
    buyAmount = json['buy_amount'];
    getProduct = json['get_product'] != null
        ? new ProductIds.fromJson(json['get_product'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['get_product_amount'] = this.getProductAmount;
    data['buy_amount'] = this.buyAmount;
    if (this.getProduct != null) {
      data['get_product'] = this.getProduct!.toJson();
    }
    return data;
  }
}
