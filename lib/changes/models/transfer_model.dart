class TransfersListModel {
  String? _sId;
  num? _quality;
  String? _firstService;
  String? _secondService;
  int? _date;
  String? _notes;
  List<Items>? _items;
  String? _status;
  String? _organization;
  String? _orderedById;
  String? _orderedByName;
  String? _pOrder;
  String? _firstServiceName;
  String? _secondServiceName;
  String? _createdAt;
  String? _updatedAt;
  int? _iV;
  int? _total;

  TransfersListModel(
      {String? sId,
      num? quality,
      String? firstService,
      String? secondService,
      int? date,
      String? notes,
      List<Items>? items,
      String? status,
      String? organization,
      String? orderedById,
      String? orderedByName,
      String? pOrder,
      String? firstServiceName,
      String? secondServiceName,
      String? createdAt,
      String? updatedAt,
      int? iV,
      int? total}) {
    if (sId != null) {
      _sId = sId;
    }
    if (quality != null) {
      _quality = quality;
    }
    if (firstService != null) {
      _firstService = firstService;
    }
    if (secondService != null) {
      _secondService = secondService;
    }
    if (date != null) {
      _date = date;
    }
    if (notes != null) {
      _notes = notes;
    }
    if (items != null) {
      _items = items;
    }
    if (status != null) {
      _status = status;
    }
    if (organization != null) {
      _organization = organization;
    }
    if (orderedById != null) {
      _orderedById = orderedById;
    }
    if (orderedByName != null) {
      _orderedByName = orderedByName;
    }
    if (pOrder != null) {
      _pOrder = pOrder;
    }
    if (firstServiceName != null) {
      _firstServiceName = firstServiceName;
    }
    if (secondServiceName != null) {
      _secondServiceName = secondServiceName;
    }
    if (createdAt != null) {
      _createdAt = createdAt;
    }
    if (updatedAt != null) {
      _updatedAt = updatedAt;
    }
    if (iV != null) {
      _iV = iV;
    }
    if (total != null) {
      _total = total;
    }
  }

  String? get sId => _sId;

  set sId(String? sId) => _sId = sId;

  num? get quality => _quality;

  set quality(num? quality) => _quality = quality;

  String? get firstService => _firstService;

  set firstService(String? firstService) => _firstService = firstService;

  String? get secondService => _secondService;

  set secondService(String? secondService) => _secondService = secondService;

  int? get date => _date;

  set date(int? date) => _date = date;

  String? get notes => _notes;

  set notes(String? notes) => _notes = notes;

  List<Items> get items => _items ?? [];

  set items(List<Items>? items) => _items = items;

  String? get status => _status;

  set status(String? status) => _status = status;

  String? get organization => _organization;

  set organization(String? organization) => _organization = organization;

  String? get orderedById => _orderedById;

  set orderedById(String? orderedById) => _orderedById = orderedById;

  String? get orderedByName => _orderedByName;

  set orderedByName(String? orderedByName) => _orderedByName = orderedByName;

  String? get pOrder => _pOrder;

  set pOrder(String? pOrder) => _pOrder = pOrder;

  String? get firstServiceName => _firstServiceName;

  set firstServiceName(String? firstServiceName) =>
      _firstServiceName = firstServiceName;

  String? get secondServiceName => _secondServiceName;

  set secondServiceName(String? secondServiceName) =>
      _secondServiceName = secondServiceName;

  String? get createdAt => _createdAt;

  set createdAt(String? createdAt) => _createdAt = createdAt;

  String? get updatedAt => _updatedAt;

  set updatedAt(String? updatedAt) => _updatedAt = updatedAt;

  int? get iV => _iV;

  set iV(int? iV) => _iV = iV;

  int? get total => _total;

  set total(int? total) => _total = total;

  TransfersListModel.fromJson(Map<String, dynamic> json) {
    _sId = json['_id'];
    _quality = json['quality'];
    _firstService = json['first_service'];
    _secondService = json['second_service'];
    _date = json['date'];
    _notes = json['notes'];
    if (json['items'] != null) {
      _items = <Items>[];
      json['items'].forEach((v) {
        _items!.add(Items.fromJson(v));
      });
    }
    _status = json['status'];
    _organization = json['organization'];
    _orderedById = json['ordered_by_id'];
    _orderedByName = json['ordered_by_name'];
    _pOrder = json['p_order'];
    _firstServiceName = json['first_service_name'];
    _secondServiceName = json['second_service_name'];
    _createdAt = json['createdAt'];
    _updatedAt = json['updatedAt'];
    _iV = json['__v'];
    _total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = _sId;
    data['quality'] = _quality;
    data['first_service'] = _firstService;
    data['second_service'] = _secondService;
    data['date'] = _date;
    data['notes'] = _notes;
    if (_items != null) {
      data['items'] = _items!.map((v) => v.toJson()).toList();
    }
    data['status'] = _status;
    data['organization'] = _organization;
    data['ordered_by_id'] = _orderedById;
    data['ordered_by_name'] = _orderedByName;
    data['p_order'] = _pOrder;
    data['first_service_name'] = _firstServiceName;
    data['second_service_name'] = _secondServiceName;
    data['createdAt'] = _createdAt;
    data['updatedAt'] = _updatedAt;
    data['__v'] = _iV;
    data['total'] = _total;
    return data;
  }

  num countTotalQuality() {
    num totalQuality = 0;
    for (Items item in (_items ?? [])) {
      totalQuality += item.quality!;
    }
    return totalQuality;
  }
}

class Items {
  num? _firstStock;
  num? _cost;
  List<String>? _barcode;
  num? _secondStock;
  String? _sId;
  String? _productId;
  String? _productName;
  num? _quality;
  num? _price;
  int? _productSku;
  int? _sku;

  Items(
      {num? firstStock,
      num? cost,
      List<String>? barcode,
      num? secondStock,
      String? sId,
      String? productId,
      String? productName,
      num? quality,
      num? price,
      int? productSku,
      int? sku}) {
    if (firstStock != null) {
      _firstStock = firstStock;
    }
    if (cost != null) {
      _cost = cost;
    }
    if (barcode != null) {
      _barcode = barcode;
    }
    if (secondStock != null) {
      _secondStock = secondStock;
    }
    if (sId != null) {
      _sId = sId;
    }
    if (productId != null) {
      _productId = productId;
    }
    if (productName != null) {
      _productName = productName;
    }
    if (quality != null) {
      _quality = quality;
    }
    if (price != null) {
      _price = price;
    }
    if (productSku != null) {
      _productSku = productSku;
    }
    if (sku != null) {
      _sku = sku;
    }
  }

  num? get firstStock => _firstStock;

  set firstStock(num? firstStock) => _firstStock = firstStock;

  num? get cost => _cost;

  set cost(num? cost) => _cost = cost;

  List<String>? get barcode => _barcode;

  set barcode(List<String>? barcode) => _barcode = barcode;

  num? get secondStock => _secondStock;

  set secondStock(num? secondStock) => _secondStock = secondStock;

  String? get sId => _sId;

  set sId(String? sId) => _sId = sId;

  String? get productId => _productId;

  set productId(String? productId) => _productId = productId;

  String? get productName => _productName;

  set productName(String? productName) => _productName = productName;

  num? get quality => _quality;

  set quality(num? quality) => _quality = quality;

  num? get price => _price;

  set price(num? price) => _price = price;

  int? get productSku => _productSku;

  set productSku(int? productSku) => _productSku = productSku;

  int? get sku => _sku;

  set sku(int? sku) => _sku = sku;

  Items.fromJson(Map<String, dynamic> json) {
    _firstStock = json['first_stock'] ?? json['first'];
    _firstStock = json['first'] ?? json['first_stock'];
    _secondStock = json['second'] ?? json['second_stock'];
    _cost = json['cost'];
    _barcode = json['barcode'].cast<String>();
    _secondStock = json['second_stock'] ?? json['second'];
    _sId = json['_id'];
    _productId = json['product_id'];
    _productName = json['product_name'] ?? json['name'];
    _productName = json['name'] ?? json['product_name'];
    _quality = json['quality'];
    _price = json['price'];
    _productSku = json['product_sku'];
    _sku = json['sku'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['first_stock'] = _firstStock;
    data['cost'] = _cost;
    data['barcode'] = _barcode;
    data['second_stock'] = _secondStock;
    data['_id'] = _sId;
    data['product_id'] = _productId;
    data['product_name'] = _productName;
    data['name'] = _productName;
    data['quality'] = _quality;
    data['price'] = _price;
    data['product_sku'] = _productSku;
    data['sku'] = _sku;
    return data;
  }
}
