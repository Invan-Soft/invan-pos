// Terminal (Arcus) chek matni va xato javoblarini tahlil qilish.
//
// Sof funksiyalar: holatga, Hive'ga, tarmoqqa yoki Flutter'ga bog'liq emas.
// OrderingProvider4 dan ajratildi (2026-08-05) — tanalar o'zgartirilmadi.
//
// Testlar: test/terminal_receipt_test.dart, test/terminal_approval_test.dart

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

      // Karta raqami: "4916********3620", "986017******4357", "9860 **** **** 1220",
      // yangi terminallar: "8600 49** **** 1234", "************1234", "8600XXXXXXXX1234"
      cardNumber ??= _maskedPan(content);

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

  /// Chek (`cheq.out`) va shu operatsiya Arcus logi bo'yicha to'lov
  /// ma'lumotlari: chekda topilmagan maydon logdagi `RECV <- PRINT:`
  /// qatorlaridan olinadi (chek ustun).
  ///
  /// Sabab (2026-10-20): yangi terminalda korporativ Uzcard to'lovida fiskal
  /// `ExtraInfo.CardNumber` bo'sh ketdi (Humo'da to'g'ri) — karta raqami chekda
  /// eski regex bilmaydigan ko'rinishda yoki chekda umuman yo'q bo'lishi mumkin.
  static Map<String, String?> parseTerminalResult({
    required String receipt,
    required String log,
  }) {
    final fromReceipt = parseTerminalReceipt(receipt);
    if (log.isEmpty || !fromReceipt.values.contains(null)) return fromReceipt;
    final fromLog = parseTerminalReceipt(log);
    return {
      for (final e in fromReceipt.entries) e.key: e.value ?? fromLog[e.key],
    };
  }

  /// Eski (2026-04) format — o'zgarishsiz.
  static final RegExp _panLegacy = RegExp(r'(\d{4,8}[\*\s]{4,12}\d{4})');

  /// Umumiy niqoblangan raqam: raqam / niqob belgilari (`*`, `X`, `•`, `#`),
  /// orada bittadan bo'sh joy, oxiri 4 raqam.
  static final RegExp _panCandidate =
      RegExp(r'[\d*Xx•#](?:[\d*Xx•#]| (?=[\d*Xx•#])){8,24}\d{4}');

  /// Qatordagi niqoblangan karta raqami (bo'sh joysiz, niqob `*`) yoki `null`.
  /// Kamida 4 ta niqob belgisi va 13–19 belgi talab qilinadi — RRN, PPTID,
  /// TID kabi to'liq raqamlar karta raqami deb olinmaydi.
  static String? _maskedPan(String line) {
    final legacy = _panLegacy.firstMatch(line);
    if (legacy != null) return legacy.group(1)!.replaceAll(RegExp(r'\s+'), '');

    for (final m in _panCandidate.allMatches(line)) {
      final pan =
          m.group(0)!.replaceAll(' ', '').replaceAll(RegExp(r'[Xx•#]'), '*');
      final masks = '*'.allMatches(pan).length;
      if (pan.length >= 13 && pan.length <= 19 && masks >= 4) return pan;
    }
    return null;
  }

  /// Arcus logi bo'yicha terminal to'lovni tasdiqlaganmi.
  ///
  /// 1) Agar logda terminal javob kodi (`RECV <- STORERC:NNN`) bo'lsa — faqat
  ///    shu kod hal qiladi: 0 (masalan `000`) = tasdiqlandi, boshqasi = rad.
  /// 2) Kod bo'lmasa yoki bo'sh bo'lsa (QR to'lov) — chek matnidagi
  ///    "ОДОБРЕНО"/"TASDIQLANDI" so'zi harf katta-kichikligiga qaramay
  ///    qidiriladi ("НЕ ОДОБРЕНО" bundan mustasno). Yangi terminallar
  ///    (SKappay) "Одобрено" deb yozadi.
  ///
  /// rc.out fayliga tayanilmaydi: ulanish xatosida u yangilanmasligi va
  /// oldingi muvaffaqiyatli to'lovning `000` kodi qolib ketishi mumkin.
  static bool isTerminalApproved(String log) {
    // Faqat shu qatordagi raqamlar: QR (TezQR) to'lovda terminal kodni bo'sh
    // yuboradi ("STORERC:") — keyingi qatordagi sanani kod deb olmaslik kerak.
    final rcMatches = RegExp(r'STORERC:[ \t]*(\d*)').allMatches(log);
    if (rcMatches.isNotEmpty) {
      final code = int.tryParse(rcMatches.last.group(1) ?? '');
      if (code != null) return code == 0;
    }

    final text = log.toUpperCase();
    if (text.contains('НЕ ОДОБРЕНО') || text.contains('НЕОДОБРЕНО')) {
      return false;
    }
    return text.contains('ОДОБРЕНО') ||
        text.contains('TASDIQLANDI') ||
        (text.contains('ОДО') && text.contains('РЕНО'));
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
