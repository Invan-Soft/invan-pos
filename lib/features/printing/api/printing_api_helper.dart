import 'package:invan2/utils/utils.dart';

class PrintingApiHelper {
  static String getTimeString(int time) {
    String timeString = '';
    final date = DateTime.fromMillisecondsSinceEpoch(time);
    timeString += addNullMethod(date.day);
    timeString += '.${addNullMethod(date.month)}';
    timeString += '.${addNullMethod(date.year)}';
    timeString += ' ${addNullMethod(date.hour)}';
    timeString += ':${addNullMethod(date.minute)}';
    Log.d(timeString, name: 'PrintingApiHelper');
    return timeString;
  }

  static String addNullMethod(int number) {
    String stringNumber = '';

    if (number.toString().length == 1) {
      stringNumber = '0$number';
    } else {
      stringNumber = number.toString();
    }

    return stringNumber;
  }

  static String getTulovTuri(String turi) {
    switch (turi) {
      case 'cash':
        {
          return 'Naqd';
        }
      case 'uzcard':
        {
          return 'Uzcard';
        }
      case 'gift':
        {
          return 'Sovg\'a';
        }
      case 'click pass':
        {
          return "Click PASS";
        }
      case 'payme go':
        {
          return "Payme GO";
        }
      case 'humo':
        {
          return "Humo";
        }
      case 'cashback':
        {
          return "Cashback";
        }
      case 'uzum':
        {
          return "Uzum PASS";
        }
      case 'click qr':
        {
          return "Click QR";
        }
      case 'payme qr':
        {
          return "Payme QR";
        }
      case 'uzum qr':
        {
          return "Uzum QR";
        }
      case 'debt':
        {
          return "Qarz";
        }
      default:
        {
          return turi.toUpperCase();
        }
    }
  }
}

class PrintingApiHelperTolovTuri {
  String nomi;
  String money;

  PrintingApiHelperTolovTuri(this.nomi, this.money);
}
