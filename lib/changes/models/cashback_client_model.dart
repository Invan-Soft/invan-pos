
class CashbackClientModel {
  CashbackClientModel({
    this.statusCode,
    this.error,
    this.message,
    this.data,
  });

  int? statusCode;
  String? error;
  String? message;
  Data? data;

  factory CashbackClientModel.fromJson(Map<String, dynamic> json) =>
      CashbackClientModel(
        statusCode: json["statusCode"],
        error: json["error"],
        message: json["message"],
        data: Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "error": error,
        "message": message,
        "data": data?.toJson(),
      };
}

class Data {
  Data({
    this.id,
    this.userId,
    this.firstName,
    this.lastName,
    this.visitCounter,
    this.totalSale,
    this.sales,
    this.refunds,
    this.firstVisit,
    this.lastVisit,
    this.pointBalance,
    this.debtPayHistory,
    this.phoneNumber,
    this.organization,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.status,
    this.otp,
    this.otpRetry,
    this.otpSend,
    this.hashedToken,
    this.firebaseToken,
  });

  String? id;
  String? userId;
  String? firstName;
  String? lastName;
  int? visitCounter;
  double? totalSale;
  int? sales;
  int? refunds;
  int? firstVisit;
  int? lastVisit;
  double? pointBalance;
  List<DebtPayHistory>? debtPayHistory;
  String? phoneNumber;
  String? organization;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;
  String? status;
  dynamic otp;
  int? otpRetry;
  dynamic otpSend;
  String? hashedToken;
  String? firebaseToken;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["_id"],
        userId: json["user_id"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        visitCounter: json["visit_counter"],
        totalSale: json["total_sale"].toDouble(),
        sales: json["sales"],
        refunds: json["refunds"],
        firstVisit: json["first_visit"],
        lastVisit: json["last_visit"],
        pointBalance: json["point_balance"].toDouble(),
        debtPayHistory: List<DebtPayHistory>.from(
            json["debt_pay_history"].map((x) => DebtPayHistory.fromJson(x))),
        phoneNumber: json["phone_number"],
        organization: json["organization"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        v: json["__v"],
        status: json["status"],
        otp: json["otp"],
        otpRetry: json["otp_retry"],
        otpSend: json["otp_send"],
        hashedToken: json["hashed_token"],
        firebaseToken: json["firebase_token"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "user_id": userId,
        "first_name": firstName,
        "last_name": lastName,
        "visit_counter": visitCounter,
        "total_sale": totalSale,
        "sales": sales,
        "refunds": refunds,
        "first_visit": firstVisit,
        "last_visit": lastVisit,
        "point_balance": pointBalance,
        "debt_pay_history":
            List<dynamic>.from(debtPayHistory!.map((x) => x.toJson())),
        "phone_number": phoneNumber,
        "organization": organization,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
        "status": status,
        "otp": otp,
        "otp_retry": otpRetry,
        "otp_send": otpSend,
        "hashed_token": hashedToken,
        "firebase_token": firebaseToken,
      };
}

class DebtPayHistory {
  DebtPayHistory({
    this.receiptId,
    this.receiptNo,
    this.cashBack,
    this.totalPrice,
    this.currency,
    this.currencyValue,
    this.date,
    this.minusCash,
    this.comment,
  });

  String? receiptId;
  String? receiptNo;
  double? cashBack;
  double? totalPrice;
  String? currency;
  double? currencyValue;
  int? date;
  int? minusCash;
  String? comment;

  factory DebtPayHistory.fromJson(Map<String, dynamic> json) => DebtPayHistory(
        receiptId: json["receipt_id"],
        receiptNo: json["receipt_no"],
        cashBack: json["cash_back"].toDouble(),
        totalPrice: json["total_price"].toDouble(),
        currency: json["currency"],
        currencyValue: json["currency_value"].toDouble(),
        date: json["date"],
        minusCash: json["minus_cash"],
        comment: json["comment"],
      );

  Map<String, dynamic> toJson() => {
        "receipt_id": receiptId,
        "receipt_no": receiptNo,
        "cash_back": cashBack,
        "total_price": totalPrice,
        "currency": currency,
        "currency_value": currencyValue,
        "date": date,
        "minus_cash": minusCash,
        "comment": comment,
      };
}
