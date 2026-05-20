
class MyTimeStringHelper {
  static String getHourMinuteSecond() {
    final time = DateTime.now();
    String str = '';
    str += '${_addZeroMethod(time.hour)}:';
    str += '${_addZeroMethod(time.minute)}:';
    str += _addZeroMethod(time.second);
    return str;
  }

  static String getHourMinute({DateTime? time}) {
    time = time ?? DateTime.now();
    String str = '';
    str += '${_addZeroMethod(time.hour)}:';
    str += _addZeroMethod(time.minute);

    return str;
  }

  static DateTime toDateFromString(String date) {
   
    date = date.replaceAll(RegExp(r'[^0-9,.]+'), '');
    int y = int.parse(date.substring(0, 4));
    int mm = int.parse(date.substring(4, 6));
    int d = int.parse(date.substring(6, 8));
    int h = int.parse(date.substring(8, 10));
    int m = int.parse(date.substring(10, 12));
    int s = int.parse(date.substring(12, 14));
    DateTime dateTime = DateTime(y, mm, d, h, m, s);
    return dateTime;
  }
  static String getDayMonthYearWithDot() {
    final time = DateTime.now();

    String str = '';
    str += '${_addZeroMethod(time.day)}.';
    str += '${_addZeroMethod(time.month)}.';
    str += '${time.year}';
    return str;
  }

  static String getDayMonthYearWithSlash({DateTime? date}) {
    date = date ?? DateTime.now();
    String str = '';
    str += '${_addZeroMethod(date.day)}/';
    str += '${_addZeroMethod(date.month)}/';
    str += '${date.year}';
    return str;
  }

  static String getWeekDay([int lan = 2, bool abbr = true]) {
    final weekDay = DateTime.now().weekday;
    String str = '';

    switch (lan) {
      case 0:
        {
          switch (weekDay) {
            case 1:
              {
                str = abbr ? 'Mon' : 'Monday';
                break;
              }
            case 2:
              {
                str = abbr ? 'Tue' : 'Tuesday';
                break;
              }
            case 3:
              {
                str = abbr ? 'Wed' : 'Wednesday';
                break;
              }
            case 4:
              {
                str = abbr ? 'Thu' : 'Thursday';
                break;
              }
            case 5:
              {
                str = abbr ? 'Fri' : 'Friday';
                break;
              }
            case 6:
              {
                str = abbr ? 'Sat' : 'Saturday';
                break;
              }
            default:
              {
                str = abbr ? 'Sun' : 'Sunday';
                break;
              }
          }
          break;
        }
      case 2:
        {
          switch (weekDay) {
            case 1:
              {
                str = abbr ? 'Du' : 'Dushanba';
                break;
              }
            case 2:
              {
                str = abbr ? 'Se' : 'Seshanba';
                break;
              }
            case 3:
              {
                str = abbr ? 'Chor' : 'Chorshanbe';
                break;
              }
            case 4:
              {
                str = abbr ? 'Pay' : 'Payshanba';
                break;
              }
            case 5:
              {
                str = abbr ? 'Ju' : 'Juma';
                break;
              }
            case 6:
              {
                str = abbr ? 'Sh' : 'Shanba';
                break;
              }
            default:
              {
                str = abbr ? 'Yak' : 'Yakshanba';
                break;
              }
          }
          break;
        }
      default:
        {
          switch (weekDay) {
            case 1:
              {
                str = abbr ? 'Пн' : 'Понедельник';
                break;
              }
            case 2:
              {
                str = abbr ? 'Вт' : 'Вторник';
                break;
              }
            case 3:
              {
                str = abbr ? 'Ср' : 'Среда';
                break;
              }
            case 4:
              {
                str = abbr ? 'Чт' : 'Четверг';
                break;
              }
            case 5:
              {
                str = abbr ? 'Пт' : 'Пятница';
                break;
              }
            case 6:
              {
                str = abbr ? 'Сб' : 'Суббота';
                break;
              }
            default:
              {
                str = abbr ? 'Вс' : 'Воскресенье';
                break;
              }
          }
          break;
        }
    }

    return str;
  }

  static String _addZeroMethod(int i) => '$i'.length == 1 ? '0$i' : '$i';

  static fromInt(int? milliseconds) {
    if (milliseconds != null) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
      return "${(date.day < 10) ? "0${date.day}" : date.day}.${(date.month < 10) ? "0${date.month}" : date.month}.${date.year}";
    } else {
      return "--.--.----";
    }
  }

  static fromStr(String? milliseconds) {
    if (!(milliseconds == "null" || milliseconds == null)) {
      DateTime date =
          DateTime.fromMillisecondsSinceEpoch(int.parse(milliseconds));
      return "${(date.day < 10) ? "0${date.day}" : date.day}.${(date.month < 10) ? "0${date.month}" : date.month}.${date.year}";
    } else {
      return "--.--.----";
    }
  }
}
