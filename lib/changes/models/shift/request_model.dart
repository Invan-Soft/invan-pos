class OpenShiftRequestModel {
  String? posId;
  int? openingTime;
  int? closingTime;
  String? currency;
  CashDrawerRequest? cashDrawerRequest;
  SalesSummaryRequest? salesSummaryRequest;
  List<String>? pays;
  String? shiftId;

  OpenShiftRequestModel(
      {this.posId,
      this.openingTime,
      this.closingTime,
      this.currency,
      this.cashDrawerRequest,
      this.salesSummaryRequest,
      this.pays,
      this.shiftId});

  OpenShiftRequestModel.fromJson(Map<String, dynamic> json) {
    posId = json['pos_id'];
    openingTime = json['opening_time'];
    closingTime = json['closing_time'];
    currency = json['currency'];
    cashDrawerRequest = json['cash_drawer'] != null
        ? CashDrawerRequest.fromJson(json['cash_drawer'])
        : null;
    salesSummaryRequest = json['sales_summary'] != null
        ? SalesSummaryRequest.fromJson(json['sales_summary'])
        : null;
    pays = json['pays'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pos_id'] = posId;
    data['opening_time'] = openingTime;
    data['closing_time'] = closingTime;
    data['currency'] = currency;
    if (cashDrawerRequest != null) {
      data['cash_drawer'] = cashDrawerRequest!.toJson();
    }
    if (salesSummaryRequest != null) {
      data['sales_summary'] = salesSummaryRequest!.toJson();
    }
    data['pays'] = pays;
    data['cashbox_id'] = posId;
    data['method'] = "open";

    return data;
  }
}

class CashDrawerRequest {
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

  CashDrawerRequest(
      {this.startingCash,
      this.cashPayment,
      this.inkassa,
      this.cashRefund,
      this.paidIn,
      this.paidOut,
      this.expCashAmount,
      this.actCashAmount,
      this.withdrawal,
      this.difference});

  CashDrawerRequest.fromJson(Map<String, dynamic> json) {
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

class SalesSummaryRequest {
  num? grossSales;
  num? refunds;
  num? discounts;
  num? netSales;
  num? cash;
  num? card;
  num? debt;
  num? taxes;
  num? cashbackOut;

  SalesSummaryRequest({
    this.grossSales,
    this.refunds,
    this.discounts,
    this.netSales,
    this.cash,
    this.card,
    this.debt,
    this.taxes,
  });

  SalesSummaryRequest.fromJson(Map<String, dynamic> json) {
    grossSales = json['gross_sales'];
    refunds = json['refunds'];
    discounts = json['discounts'];
    netSales = json['net_sales'];
    cash = json['cash'];
    card = json['card'];
    debt = json['debt'];
    taxes = json['taxes'];
    cashbackOut = json['cashback_out'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['gross_sales'] = grossSales;
    data['refunds'] = refunds;
    data['discounts'] = discounts;
    data['net_sales'] = netSales;
    data['cash'] = cash;
    data['card'] = card;
    data['debt'] = debt;
    data['taxes'] = taxes;
    data['cashback_out'] = cashbackOut;
    return data;
  }
}
