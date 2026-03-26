
class MyTimeStringHelper8 {
  static String getCurrentTimeStringFormatted() {
    String str = "";
    final time = DateTime.now();
    str += addNull("${time.year}");
    str += "-";
    str += addNull("${time.month}");
    str += "-";
    str += addNull("${time.day}");
    str += "T";
    str += addNull("${time.hour}");
    str += ":";
    str += addNull("${time.minute}");
    str += ":";
    str += addNull("${time.second}");
    str += "+05:00";
    return str;
  }

  static String addNull(String str) {
    if (str.length == 1) {
      return "0$str";
    } else {
      return str;
    }
  }
}
