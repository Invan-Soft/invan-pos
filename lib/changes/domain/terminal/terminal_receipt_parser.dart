// Terminal (Arcus) chek matni va xato javoblarini tahlil qilish.
//
// Sof funksiyalar: holatga, Hive'ga, tarmoqqa yoki Flutter'ga bog'liq emas.
// OrderingProvider4 dan ajratildi (2026-08-05) — tanalar o'zgartirilmadi.
//
// Testlar: test/terminal_receipt_test.dart

class TerminalReceiptParser {
  const TerminalReceiptParser._();

  /// Terminal chek matnidan RRN, karta raqami, avtorizatsiya kodi, miqdor,
  /// sana va karta turini ajratib oladi.
  ///
  /// Topilmagan maydon `null` bo'ladi; natija har doim 6 ta kalitli map.
  static Map<String, String?> parseTerminalReceipt(String receiptText) {
    String? rrn;
    String? cardNumber;
    String? authCode;
    String? amount;
    String? date;
    String? cardType;

    // Chek matnidagi har bir qatorni tekshiramiz
    for (final line in receiptText.split('\n')) {
      // RECV <- PRINT: prefiksini olib tashlaymiz (log formatida bo'lsa)
      final content =
          line.replaceFirst(RegExp(r'^.*RECV <- PRINT:'), '').trim();

      // RRN: "RRN :608610728951" yoki "RRN:608610728951"
      if (rrn == null) {
        final m = RegExp(r'RRN\s*:?\s*(\d{6,20})').firstMatch(content);
        if (m != null) rrn = m.group(1);
      }

      // Karta raqami: "4916********3620", "986017******4357", "9860 **** **** 1220"
      if (cardNumber == null) {
        final m = RegExp(r'(\d{4,8}[\*\s]{4,12}\d{4})').firstMatch(content);
        if (m != null) cardNumber = m.group(1)?.replaceAll(RegExp(r'\s+'), '');
      }

      // Avtorizatsiya kodi
      if (authCode == null) {
        final m =
            RegExp(r'[Aa]vtorizatsiya\s+kodi\s*:?\s*(\w+)').firstMatch(content);
        if (m != null) authCode = m.group(1);
      }

      // Miqdor/Summa
      if (amount == null) {
        final m = RegExp(r'MIQDOR\s*:\s*([\d\s,.]+UZS?)').firstMatch(content);
        if (m != null) amount = m.group(1)?.trim();
      }

      // Sana
      if (date == null) {
        final m = RegExp(r'Sana\s*:?\s*(.+)').firstMatch(content);
        if (m != null) date = m.group(1)?.trim();
      }

      // Karta turi
      if (cardType == null) {
        if (content.contains('HUMO')) {
          cardType = 'HUMO';
        } else if (content.contains('UZCARD')) {
          cardType = 'UZCARD';
        } else if (content.contains('VISA')) {
          cardType = 'VISA INT';
        }
      }
    }

    return {
      'rrn': rrn,
      'cardNumber': cardNumber,
      'authCode': authCode,
      'amount': amount,
      'date': date,
      'cardType': cardType,
    };
  }

  /// Terminal (Arcus) javobidagi (log + chek) tanish xato sabablarini
  /// tushunarli xabarga o'giradi. Topilmasa bo'sh string qaytaradi.
  static String terminalErrorMessage(String log, String receipt, bool isUz) {
    final text = '$log\n$receipt'.toUpperCase();

    if (text.contains('НЕДОСТАТОЧНО') ||
        text.contains('НЕ ДОСТАТОЧНО') ||
        text.contains('INSUFFICIENT')) {
      return isUz
          ? "Kartada mablag' yetarli emas"
          : "Недостаточно средств на карте";
    }
    if (text.contains('ЛИМИТ ПОПЫТОК PIN')) {
      return isUz
          ? "PIN kodni kiritish urinishlari tugadi"
          : "Лимит попыток ввода PIN исчерпан";
    }
    if (text.contains('ВЕРНЫЙ PIN') ||
        text.contains('ЕРНЫЙ PIN') ||
        text.contains('WRONG PIN')) {
      return isUz ? "Noto'g'ri PIN kod kiritildi" : "Неверный PIN-код";
    }
    if (text.contains('КАРТА НЕДЕЙСТ') ||
        text.contains('НЕДЕЙСТВИТЕЛЬНА') ||
        text.contains('EXPIRED')) {
      return isUz
          ? "Karta yaroqsiz yoki muddati o'tgan"
          : "Карта недействительна или просрочена";
    }
    if (text.contains('ОТМЕН') ||
        text.contains('ПРЕРВАН') ||
        text.contains('CANCEL')) {
      return isUz ? "Amaliyot bekor qilindi" : "Операция отменена";
    }
    if (text.contains('ПРЕВЫШЕН') || text.contains('ЛИМИТ')) {
      return isUz ? "Limit oshib ketdi" : "Превышен лимит";
    }
    if (text.contains('СВЯЖИТЕСЬ') || text.contains('ОБРАТИТЕСЬ')) {
      return isUz ? "Bank bilan bog'laning" : "Свяжитесь с банком";
    }
    if (text.contains('НЕТ СВЯЗИ') ||
        text.contains('СОЕДИНЕН') ||
        text.contains('TIMEOUT') ||
        text.contains('ТАЙМАУТ')) {
      return isUz
          ? "Terminal yoki bank bilan aloqa yo'q. Qayta urinib ko'ring"
          : "Нет связи с терминалом или банком. Повторите попытку";
    }
    if (text.contains('ОТКЛОНЕНА') ||
        text.contains('ОТКАЗ') ||
        text.contains('DECLINED')) {
      return isUz ? "To'lov rad etildi" : "Платёж отклонён";
    }
    return '';
  }
}
