// Skaner klaviatura sifatida yozadi — kassada rus (ЙЦУКЕН) tartibi yoqiq bo'lsa
// kod harflari kirillga, ba'zi belgilar boshqa belgiga aylanib keladi.
//
// Sof funksiyalar. Jadval Windows "Русская" tartibi bo'yicha (do'kon kassalari).
// macOS "Russian" tartibida raqam qatori boshqacha — bu yerda hisobga olinmagan.

class KeyboardLayout {
  const KeyboardLayout._();

  /// Harf tugmalari: kirill → lotin. Asosiy ekran skaneri
  /// (`MyBarcodeListenerState.fixKeyboardLayout`) aynan shuni ishlatadi —
  /// sotuvda blok KM shu o'girishdan keyin saqlanadi.
  static String ruLettersToEn(String input) => _map(input, _letters);

  /// To'liq: harflar + rus tartibida boshqa belgi beradigan tugmalar
  /// (`Shift+7` → `?` aslida `&`, `/` tugmasi → `.` va h.k.). Bitta o'tishda —
  /// `,`→`?` va `?`→`&` bir-biriga ulanib ketmasin.
  static String ruToEnFull(String input) => _map(input, _full);

  static String _map(String input, Map<String, String> table) {
    if (input.isEmpty) return input;
    final buf = StringBuffer();
    for (final ch in input.split('')) {
      buf.write(table[ch] ?? ch);
    }
    return buf.toString();
  }

  static const Map<String, String> _letters = {
    'й': 'q', 'ц': 'w', 'у': 'e', 'к': 'r', 'е': 't', 'н': 'y', 'г': 'u',
    'ш': 'i', 'щ': 'o', 'з': 'p', 'х': '[', 'ъ': ']',
    'ф': 'a', 'ы': 's', 'в': 'd', 'а': 'f', 'п': 'g', 'р': 'h',
    'о': 'j', 'л': 'k', 'д': 'l', 'ж': ';', 'э': "'",
    'я': 'z', 'ч': 'x', 'с': 'c', 'м': 'v', 'и': 'b', 'т': 'n',
    'ь': 'm', 'б': ',', 'ю': '.',
    'Й': 'Q', 'Ц': 'W', 'У': 'E', 'К': 'R', 'Е': 'T', 'Н': 'Y', 'Г': 'U',
    'Ш': 'I', 'Щ': 'O', 'З': 'P', 'Х': '{', 'Ъ': '}',
    'Ф': 'A', 'Ы': 'S', 'В': 'D', 'А': 'F', 'П': 'G', 'Р': 'H',
    'О': 'J', 'Л': 'K', 'Д': 'L', 'Ж': ':', 'Э': '"',
    'Я': 'Z', 'Ч': 'X', 'С': 'C', 'М': 'V', 'И': 'B', 'Т': 'N',
    'Ь': 'M', 'Б': '<', 'Ю': '>',
    'ё': '`', 'Ё': '~',
  };

  static const Map<String, String> _full = {
    ..._letters,
    '"': '@', // Shift+2
    '№': '#', // Shift+3
    ';': r'$', // Shift+4
    ':': '^', // Shift+6
    '?': '&', // Shift+7
    '.': '/', // `/` tugmasi
    ',': '?', // Shift+/
    '/': '|', // Shift+\
  };
}
