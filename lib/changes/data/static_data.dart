import 'package:invan2/utils/constants/secrets.dart';

class StaticData {
  // ignore: constant_identifier_names
  static const Map RECEIPT = {
    "token": Secrets.fiscalApiToken,
    "method": "refund",
    "companyName": "Humo MCHJ",
    "companyAddress": "Tashkent",
    "companyINN": "123456",
    "staffName": "Abdulazizov Shakhboz",
    "printerSize": 80,
    "params": {
      "discountCard": {
        "available": 0,
        "addition": 0,
        "subtraction": 0,
        "remainder": 0
      },
      "paycheckNumber": "7654321",
      "items": [
        {
          "discount": 50000,
          "price": 100000,
          "barcode": "98743154313",
          "amount": 2000,
          "vatPercent": 15,
          "vat": 103839,
          "name": "AAAAAAAAAAAAAA",
          "label": "qwertyuuuuuuiopasdfghjklzxcvbnm",
          "classCode": "08510003002000000",
          "other": 10000
        },
        {
          "discount": 150000,
          "price": 200000,
          "barcode": "23412334321",
          "amount": 2000,
          "vatPercent": 15,
          "vat": 103839,
          "name": "BBBBBBBBBB",
          "classCode": "08510003002000000",
          "other": 0
        }
      ]
    }
  };
}
