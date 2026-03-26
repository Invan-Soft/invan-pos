class ShiftingModel {
  ShiftingModel({
    this.statusCode,
    this.error,
    this.message,
    this.data,
  });

  int? statusCode;
  String? error;
  String? message;
  OpenShiftResponseData? data;

  factory ShiftingModel.fromJson(Map<String, dynamic> json) => ShiftingModel(
        statusCode: json["statusCode"],
        error: json["error"],
        message: json["message"],
        data: OpenShiftResponseData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "error": error,
        "message": message,
        "data": data?.toJson(),
      };
}

class OpenShiftResponseData {
  OpenShiftResponseData({
    this.cashDrawer,
    this.salesSummary,
    this.byWhomName,
    this.byWhomNameClose,
    this.closingTime,
    this.currency,
    this.pays,
    this.id,
    this.posId,
    this.openingTime,
    this.organization,
    this.service,
    this.pos,
    this.byWhom,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  CashDrawerResponse? cashDrawer;
  SalesSummaryResponse? salesSummary;
  String? byWhomName;
  String? byWhomNameClose;
  int? closingTime;
  String? currency;
  List<PaysResponse>? pays;
  String? id;
  String? posId;
  int? openingTime;
  String? organization;
  String? service;
  String? pos;
  String? byWhom;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  factory OpenShiftResponseData.fromJson(Map<String, dynamic> json) =>
      OpenShiftResponseData(
        cashDrawer: CashDrawerResponse.fromJson(json["cash_drawer"]),
        salesSummary: SalesSummaryResponse.fromJson(json["sales_summary"]),
        byWhomName: json["by_whom_name"],
        byWhomNameClose: json["by_whom_name_close"],
        closingTime: json["closing_time"],
        currency: json["currency"],
        pays: List<PaysResponse>.from(json["Pays"].map((x) => x)),
        id: json["_id"],
        posId: json["pos_id"],
        openingTime: json["opening_time"],
        organization: json["organization"],
        service: json["service"],
        pos: json["pos"],
        byWhom: json["by_whom"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        v: json["__v"],
      );

  Map<String, dynamic> toJson() => {
        "cash_drawer": cashDrawer?.toJson(),
        "sales_summary": salesSummary?.toJson(),
        "by_whom_name": byWhomName,
        "by_whom_name_close": byWhomNameClose,
        "closing_time": closingTime,
        "currency": currency,
        "Pays": List<PaysResponse>.from(pays!.map((x) => x)),
        "_id": id,
        "pos_id": posId,
        "opening_time": openingTime,
        "organization": organization,
        "service": service,
        "pos": pos,
        "by_whom": byWhom,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
      };
}

class CashDrawerResponse {
  CashDrawerResponse({
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

  num? startingCash;
  num? cashPayment;
  num? inkassa;
  num? cashRefund;
  num? paidIn;
  num? paidOut;
  num? expCashAmount;
  num? actCashAmount;
  num? withdrawal;
  num? difference;

  factory CashDrawerResponse.fromJson(Map<String, dynamic> json) =>
      CashDrawerResponse(
        startingCash: json["starting_cash"],
        cashPayment: json["cash_payment"],
        inkassa: json["inkassa"],
        cashRefund: json["cash_refund"],
        paidIn: json["paid_in"],
        paidOut: json["paid_out"],
        expCashAmount: json["exp_cash_amount"],
        actCashAmount: json["act_cash_amount"],
        withdrawal: json["withdrawal"],
        difference: json["difference"],
      );

  Map<String, dynamic> toJson() => {
        "starting_cash": startingCash,
        "cash_payment": cashPayment,
        "inkassa": inkassa,
        "cash_refund": cashRefund,
        "paid_in": paidIn,
        "paid_out": paidOut,
        "exp_cash_amount": expCashAmount,
        "act_cash_amount": actCashAmount,
        "withdrawal": withdrawal,
        "difference": difference,
      };
}

class SalesSummaryResponse {
  SalesSummaryResponse({
    this.grossSales,
    this.refunds,
    this.discounts,
    this.netSales,
    this.cash,
    this.card,
    this.debt,
    this.taxes,
  });

  num? grossSales;
  num? refunds;
  num? discounts;
  num? netSales;
  num? cash;
  num? card;
  num? debt;
  num? taxes;

  factory SalesSummaryResponse.fromJson(Map<String, dynamic> json) =>
      SalesSummaryResponse(
        grossSales: json["gross_sales"],
        refunds: json["refunds"],
        discounts: json["discounts"],
        netSales: json["net_sales"],
        cash: json["cash"],
        card: json["card"],
        debt: json["debt"],
        taxes: json["taxes"],
      );

  Map<String, dynamic> toJson() => {
        "gross_sales": grossSales,
        "refunds": refunds,
        "discounts": discounts,
        "net_sales": netSales,
        "cash": cash,
        "card": card,
        "debt": debt,
        "taxes": taxes,
      };
}

class PaysResponse {
  int? time;
  String? name;
  String? createdShiftId;
  String? shiftId;
  String? comment;
  num? value;
  String? who;
  List<String>? type;

  PaysResponse(
      {this.time,
      this.name,
      this.createdShiftId,
      this.shiftId,
      this.comment,
      this.value,
      this.who,
      this.type});

  PaysResponse.fromJson(Map<String, dynamic> json) {
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
