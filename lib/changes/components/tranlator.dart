class Translit {
  final Map _transliteratedSymbol = {
    'А': 'A',
    'Б': 'B',
    'В': 'V',
    'Г': 'G',
    'Д': 'D',
    'Е': 'E',
    'З': 'Z',
    'И': 'I',
    'Й': 'Y',
    'К': 'K',
    'Л': 'L',
    'М': 'M',
    'Н': 'N',
    'О': 'O',
    'П': 'P',
    'Р': 'R',
    'С': 'S',
    'Т': 'T',
    'У': 'U',
    'Ф': 'F',
    'Х': 'X',
    'Ц': 'C',
    'Ы': 'I',
    'а': 'a',
    'б': 'b',
    'в': 'v',
    'г': 'g',
    'д': 'd',
    'е': 'e',
    'з': 'z',
    'и': 'i',
    'й': 'y',
    'к': 'k',
    'л': 'l',
    'м': 'm',
    'н': 'n',
    'о': 'o',
    'п': 'p',
    'р': 'r',
    'с': 's',
    'т': 't',
    'у': 'u',
    'ф': 'f',
    'х': 'x',
    'ц': 'c',
    'ы': 'i',
    "'": '',
    '"': '',
    'Э': 'E',
    'э': 'e',
    "Қ": "Q",
    "қ": "q",
    "Ҳ": "H",
    "ҳ": "h"
  };

  final Map _complicatedSymbols = {
    'Ё': 'Yo',
    'Ж': 'J',
    'Щ': 'Sh',
    'Ш': 'Sh',
    'Ч': 'Ch',
    'Э': 'E',
    'Ю': 'Yu',
    'Я': 'Ya',
    "Ў": "O`",
    "Ғ": "G'",
    'ё': 'yo',
    'ж': 'zh',
    'щ': 'sh',
    'ш': 'sh',
    'ч': 'ch',
    'э': 'e',
    'ъ': '"',
    'ь': "'",
    'ю': 'yu',
    'я': 'ya',
    "ў": "o`",
    "ғ": "g'",
  };

  /// Method for converting from translit for the [source] value
  String unTranslit({required String source}) {
    if (source.isEmpty) return source;

    var regExp = RegExp(
      r'([a-z]+)',
      caseSensitive: false,
      multiLine: true,
    );

    if (!regExp.hasMatch(source)) return source;

    var sourceSymbols = [];
    var unTranslit = [];
    var deTransliteratedSymbol = {};

    _complicatedSymbols.forEach((key, value) {
      source = source.replaceAll(value, key);
    });

    sourceSymbols = source.split('');

    _transliteratedSymbol.forEach((key, value) {
      deTransliteratedSymbol[value] = key;
    });

    for (final element in sourceSymbols) {
      unTranslit.add(deTransliteratedSymbol.containsKey(element)
          ? deTransliteratedSymbol[element]
          : element);
    }

    return unTranslit.join();
  }

  String toTranslit({required String source}) {
    if (source.isEmpty) return source;

    var regExp = RegExp(
      r'([а-я]+)',
      caseSensitive: false,
      multiLine: true,
    );

    if (!regExp.hasMatch(source)) return source;

    var translit = [];
    var sourceSymbols = [];

    sourceSymbols = source.split('');

    _transliteratedSymbol.addAll(_complicatedSymbols);

    for (final element in sourceSymbols) {
      translit.add(_transliteratedSymbol.containsKey(element)
          ? _transliteratedSymbol[element]
          : element);
    }

    return translit.join();
  }
}