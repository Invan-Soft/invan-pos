import 'package:hive/hive.dart';

part 'shift_hive_model.g.dart';

@HiveType(typeId: 30)
class ShiftModelHive extends HiveObject {
  @override
  get key => iV;
  @HiveField(0)
  CashDrawerHive? cashDrawerHive;
  @HiveField(1)
  SalesSummaryHive? salesSummary;
  @HiveField(2)
  String? byWhomName;
  @HiveField(3)
  String? byWhomNameClose;
  @HiveField(4)
  int? closingTime;
  @HiveField(5)
  String? currency;
  @HiveField(6)
  List<PaysHive>? pays;
  @HiveField(7)
  String? sId;
  @HiveField(8)
  String? posId;
  @HiveField(9)
  int? openingTime;
  @HiveField(10)
  String? organization;
  @HiveField(11)
  String? service;
  @HiveField(12)
  String? pos;
  @HiveField(13)
  String? byWhom;
  @HiveField(14)
  String? createdAt;
  @HiveField(15)
  String? updatedAt;
  @HiveField(16)
  int? iV;
  @HiveField(17)
  bool? isUploaded;
  @HiveField(18)
  bool? isWithOFD;
  @HiveField(19)
  String? shiftId;
  @HiveField(20)
  bool? isClosed;

  ShiftModelHive({
    this.isClosed,
    this.isWithOFD,
    this.cashDrawerHive,
    this.salesSummary,
    this.byWhomName,
    this.byWhomNameClose,
    this.closingTime,
    this.currency,
    this.pays,
    this.sId,
    this.posId,
    this.openingTime,
    this.organization,
    this.service,
    this.pos,
    this.byWhom,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.isUploaded,
    this.shiftId,
  });

  ShiftModelHive.fromJson(Map<String, dynamic> json) {
    cashDrawerHive = json['cash_drawer'] != null
        ? CashDrawerHive.fromJson(json['cash_drawer'])
        : null;
    salesSummary = json['sales_summary'] != null
        ? SalesSummaryHive.fromJson(json['sales_summary'])
        : null;
    byWhomName = json['by_whom_name'];
    byWhomNameClose = json['by_whom_name_close'];
    closingTime = json['closing_time'];
    currency = json['currency'];
    isClosed = json['isClosed'];
    if (json['Pays'] != null) {
      pays = <PaysHive>[];
      json['pays'].forEach((v) {
        pays!.add(PaysHive.fromJson(v));
      });
    }
    sId = json['_id'];
    posId = json['pos_id'];
    openingTime = json['opening_time'];
    organization = json['organization'];
    service = json['service'];
    pos = json['pos'];
    byWhom = json['by_whom'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    isUploaded = json['isUploaded'];
    shiftId = json['shiftId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (cashDrawerHive != null) {
      data['cash_drawer'] = cashDrawerHive!.toJson();
    }
    if (salesSummary != null) {
      data['sales_summary'] = salesSummary!.toJson();
    }
    data['isClose'] = isClosed;
    data['shiftId'] = shiftId;
    data['isWithOFD'] = isWithOFD;
    data['by_whom_name'] = byWhomName;
    data['by_whom_name_close'] = byWhomNameClose;
    data['closing_time'] = closingTime;
    data['currency'] = currency;
    if (pays != null) {
      data['Pays'] = pays!.map((v) => v.toJson()).toList();
    }
    data['_id'] = sId;
    data['pos_id'] = posId;
    data['opening_time'] = openingTime;
    data['organization'] = organization;
    data['service'] = service;
    data['pos'] = pos;
    data['by_whom'] = byWhom;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    data['isUploaded'] = isUploaded;
    return data;
  }
}

@HiveType(typeId: 31)
class CashDrawerHive {
  @HiveField(0)
  num? startingCash;
  @HiveField(1)
  num? cashPayment;
  @HiveField(2)
  num? inkassa;
  @HiveField(3)
  num? cashRefund;
  @HiveField(4)
  num? paidIn;
  @HiveField(5)
  num? paidOut;
  @HiveField(6)
  num? expCashAmount;
  @HiveField(7)
  num? actCashAmount;
  @HiveField(8)
  num? withdrawal;
  @HiveField(9)
  num? difference;

  CashDrawerHive({
    this.startingCash,
    this.cashPayment,
    this.inkassa,
    this.cashRefund,
    this.paidIn,
    this.paidOut,
    this.expCashAmount,
    this.actCashAmount,
    this.withdrawal,
    this.difference,
  });

  CashDrawerHive.fromJson(Map<String, dynamic> json) {
    startingCash = json['starting_cash'];
    cashPayment = json['cash_payment'];
    inkassa = json['inkassa'];
    cashRefund = json['cash_refund'];
    paidIn = json['paid_in'];
    paidOut = json['paid_out'];
    expCashAmount = json['exp_cash_amount'];
    actCashAmount = json['act_cash_amount'];
    withdrawal = json['withdrawal'];
    difference = json['difference'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['starting_cash'] = startingCash;
    data['cash_payment'] = cashPayment;
    data['inkassa'] = inkassa;
    data['cash_refund'] = cashRefund;
    data['paid_in'] = paidIn;
    data['paid_out'] = paidOut;
    data['exp_cash_amount'] = expCashAmount;
    data['act_cash_amount'] = actCashAmount;
    data['withdrawal'] = withdrawal;
    data['difference'] = difference;
    return data;
  }
}

@HiveType(typeId: 32)
class SalesSummaryHive {
  @HiveField(0)
  num? grossSales;
  @HiveField(1)
  num? refunds;
  @HiveField(2)
  num? discounts;
  @HiveField(3)
  num? netSales;
  @HiveField(4)
  num? cash;
  @HiveField(5)
  num? card;
  @HiveField(6)
  num? debt;
  @HiveField(7)
  num? taxes;
  @HiveField(8)
  num? cashbackIn;
  @HiveField(9)
  num? cashbackOut;
  @HiveField(10)
  num? click;
  @HiveField(11)
  num? payme;
  @HiveField(12)
  num? uzum;
  @HiveField(13)
  num? clickQr;
  @HiveField(14)
  num? paymeQr;
  @HiveField(15)
  num? uzumQr;
  @HiveField(16)
  num? uzCard;
  @HiveField(17)
  num? humoCard;
  @HiveField(18)
  num? other;

  SalesSummaryHive({
    this.grossSales,
    this.refunds,
    this.discounts,
    this.netSales,
    this.cash,
    this.card,
    this.click,
    this.payme,
    this.uzum,
    this.clickQr,
    this.paymeQr,
    this.uzumQr,
    this.debt,
    this.taxes,
    this.cashbackIn,
    this.cashbackOut,
    this.uzCard,
    this.humoCard,
    this.other,
  });

  SalesSummaryHive.fromJson(Map<String, dynamic> json) {
    grossSales = json['gross_sales'];
    refunds = json['refunds'];
    discounts = json['discounts'];
    netSales = json['net_sales'];
    cash = json['cash'];
    card = json['card'];
    click = json['click'];
    clickQr = json['clickQr'];
    paymeQr = json['paymeQr'];
    uzumQr = json['uzumQr'];
    uzum = json['uzum'];
    payme = json['payme'];
    debt = json['debt'];
    taxes = json['taxes'];
    cashbackIn = json["cashback_in"];
    cashbackOut = json["cashback_out"];
    other = json["other"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['gross_sales'] = grossSales;
    data['refunds'] = refunds;
    data['discounts'] = discounts;
    data['net_sales'] = netSales;
    data['cash'] = cash;
    data['card'] = card;
    data['click'] = click;
    data['clickQr'] = clickQr;
    data['uzumQr'] = uzumQr;
    data['paymeQr'] = paymeQr;
    data['uzum'] = uzum;
    data['payme'] = payme;
    data['debt'] = debt;
    data['taxes'] = taxes;
    data["cashback_in"] = cashbackIn;
    data["cashback_out"] = cashbackOut;
    data["uzcard"] = uzCard;
    data["humocard"] = humoCard;
    data["other"] = other;

    return data;
  }
}

@HiveType(typeId: 33)
class PaysHive {
  @HiveField(0)
  int? time;
  @HiveField(1)
  String? name;
  @HiveField(2)
  String? createdShiftId;
  @HiveField(3)
  String? shiftId;
  @HiveField(4)
  String? comment;
  @HiveField(5)
  num? value;
  @HiveField(6)
  String? who;
  @HiveField(7)
  List<String>? type;

  PaysHive(
      {this.time,
      this.name,
      this.createdShiftId,
      this.shiftId,
      this.comment,
      this.value,
      this.who,
      this.type});

  PaysHive.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    name = json['name'];
    createdShiftId = json['created_shift_id'];
    shiftId = json['shift_id'];
    comment = json['comment'];
    value = json['value'];
    who = json['who'];
    type = json['type'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['time'] = time;
    data['name'] = name;
    data['created_shift_id'] = createdShiftId;
    data['shift_id'] = shiftId;
    data['comment'] = comment;
    data['value'] = value;
    data['who'] = who;
    data['type'] = type;
    return data;
  }
}
