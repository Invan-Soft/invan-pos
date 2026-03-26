import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class ClientModel {
  ClientModel({
    this.id,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.pointBalance,
    this.gender,
    this.cardNumber,
    this.companyId,
    this.discount,
    this.email,
    this.externalId,
    this.group,
    this.groupName,
    this.groupId,
    this.totalPurchaseAmount,
    this.discountGroupType,
    this.discountValue,
    this.discountId,
    this.isAvailableForDebt,
  });

  num? pointBalance;
  String? firstName;
  String? lastName;
  String? phoneNumber;
  String? id;
  String? gender;
  String? cardNumber;
  String? companyId;
  num? discount;
  String? email;
  String? externalId;
  String? group;
  String? groupName;
  String? groupId;
  String? discountGroupType;
  double? discountValue;
  String? discountId;
  num? totalPurchaseAmount;
  bool? isAvailableForDebt;

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
        firstName: json["first_name"].toString(),
        lastName: json["last_name"].toString(),
        pointBalance: json["balance"],
        discountId: json['discount_group_type'].toString() ==
                Pref.getString(PrefKeys.cashBeckCC, "")
            ? Pref.getString(PrefKeys.discountAmountId,
                "9fb3ada6-a73b-4b81-9295-5c1605e54552")
            : json["discount_id"],
        phoneNumber: json["phone_number"].toString(),
        id: json["id"].toString(),
        totalPurchaseAmount: json['total_purchase_amount'],
        gender: json['sex'].toString(),
        cardNumber: json['card_number'].toString(),
        companyId: json['company_id'].toString(),
        discount: json['discount'],
        email: json['email'].toString(),
        discountGroupType: json['discount_group_type'].toString(),
        discountValue: json['discount_group_type'].toString() ==
                Pref.getString(PrefKeys.cashBeckCC, "")
            ? 0
            : double.parse(json["discount_value"].toString()),
        externalId: json['external_id'].toString(),
        // group: json['group'].toString(),
        groupName: json['group_name'].toString(),
        groupId: json['group_id'].toString(),
        isAvailableForDebt: json['is_available_for_debt'],
      );

  Map<String, dynamic> toJson() => {
        "first_name": firstName,
        "last_name": lastName,
        "balance": pointBalance,
        "discount_id": discountId,
        "phone_number": phoneNumber,
        "id": id,
        "total_purchase_amount": totalPurchaseAmount,
        "sex": gender,
        "card_number": cardNumber,
        "company_id": companyId,
        "discount": discount,
        "email": email,
        "external_id": externalId,
        // group: group,
        "group_name": groupName,
        "group_id": groupId,
        'discount_group_type': discountGroupType,
        'discount_value': discountValue,
        'is_available_for_debt': isAvailableForDebt,
      };

  Map<String, dynamic> toApi() => {
        "sex_id": gender,
        "phone_number": phoneNumber,
        "first_name": firstName,
        "last_name": lastName,
        "birthday": "2001-11-01T00:00:00.000Z",
        "info": "",
        "card_number": cardNumber,
        "email": "",
        "group": group,
        "client_type": "ae35a609-f574-459e-af74-750538a1ab58",
      };
}

class DebtPayHistory {
  DebtPayHistory({
    this.paid,
    this.currency,
    this.currencyValue,
    this.date,
    this.comment,
  });

  String? paid;
  String? currency;
  String? currencyValue;
  String? date;
  String? comment;

  factory DebtPayHistory.fromJson(Map<String, dynamic> json) => DebtPayHistory(
        paid: json["paid"].toString(),
        currency: json["currency"].toString(),
        currencyValue: json["currency_value"].toString(),
        date: json["date"].toString(),
        comment: json["comment"].toString(),
      );

  Map<String, dynamic> toJson() => {
        "paid": paid,
        "currency": currency,
        "currency_value": currencyValue,
        "date": date,
        "comment": comment,
      };
}
