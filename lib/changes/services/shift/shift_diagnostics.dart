import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/objectbox.g.dart';
import 'package:invan2/utils/utils.dart';

/// Smena bilan bog'liq muammolarning yagona ro'yxati.
///
/// Har bir holat uchun: kassirga ko'rsatiladigan aniq sabab (uz/ru) va
/// Telegramga ketadigan tuzilgan hisobot bo'ladi. Ilgari barcha holatlar
/// "Pos is open on the web" / "openshift funksiyasi false qaytargan holat"
/// deb bir xil ko'rsatilardi — sabab na kassirga, na dasturchiga ko'rinmasdi.
enum ShiftIssue {
  /// Internet yo'q — smena lokal yopiladi, serverga keyin yuboriladi.
  noInternet,

  /// Serverga ketmagan cheklar bor (uploaded=false, rejected=false).
  unsentReceipts,

  /// Server rad etgan cheklar bor (uploaded=false, rejected=true).
  /// Bular avtomatik qayta yuborilmaydi — qo'lda yuborish kerak.
  rejectedReceipts,

  /// Lokal smena yopilgan, lekin yopilish serverga yetmagan.
  /// 2026-08-13 hodisasining asosiy sababi shu.
  pendingCloseNotSynced,

  /// Lokal smena ochilgan, lekin ochilish serverga yetmagan.
  pendingOpenNotSynced,

  /// Internetsiz yopib bo'lmaydi: smena oflayn ochilgan va ochilishi hali
  /// serverga yetmagan (`openedCount == 1`).
  ///
  /// `ShiftSingleton4.closeShift` ning oflayn shoxi
  /// `closedCount == 0 && openedCount == 0` ni talab qiladi — bu shart
  /// bajarilmasa smena YOPILMAYDI. Ilgari bu holat `serverCloseFailed` deb
  /// ko'rsatilardi, holbuki serverga umuman murojaat qilinmagan edi.
  offlineCloseBlockedByPendingOpen,

  /// Internetsiz yopib bo'lmaydi: oldingi yopish hali navbatda
  /// (`closedCount == 1`).
  offlineCloseBlockedByPendingClose,

  /// Yopish so'rovi serverga ketdi, lekin server 200 qaytarmadi.
  serverCloseFailed,

  /// Server bu kassani "ochiq" deb ko'rsatyapti (POS orqali ochilgan).
  cashboxOpenOnServer,

  /// Server bu kassani "ochiq" deb ko'rsatyapti (web orqali ochilgan).
  cashboxOpenOnWeb,

  /// Kassa server ro'yxatida umuman topilmadi (activatedPosId mos kelmadi).
  cashboxNotFoundOnServer,

  /// Smena holatini serverdan olib bo'lmadi (tarmoq/500).
  serverStatusUnavailable,

  /// POS aktivlashtirilmagan — activatedPosId bo'sh.
  posNotActivated,

  /// Lokal smena yozuvi Hive'da topilmadi.
  localShiftMissing,

  unknown,
}

/// Smena amaliyoti — xabar va hisobotlarda kontekst sifatida ishlatiladi.
enum ShiftAction { close, open }

/// Muammo aniqlangan paytdagi POS holati.
class ShiftSnapshot {
  const ShiftSnapshot({
    required this.internet,
    required this.unsentReceipts,
    required this.rejectedReceipts,
    required this.pendingCloseAt,
    required this.pendingOpenAt,
    required this.openedCount,
    required this.closedCount,
    required this.shiftsOpened,
    required this.currentShiftKey,
    required this.posName,
    required this.cashboxId,
    required this.cashierName,
  });

  final bool internet;
  final int unsentReceipts;
  final int rejectedReceipts;

  /// `PrefKeys.closedDate` — bo'sh bo'lmasa, serverga yetmagan yopish bor.
  final String pendingCloseAt;

  /// `PrefKeys.openedDate` — bo'sh bo'lmasa, serverga yetmagan ochish bor.
  final String pendingOpenAt;

  /// `PrefKeys.openedCount` — 1 bo'lsa, smena OFLAYN ochilgan va ochilish
  /// serverga yuborilishi kutilyapti.
  final int openedCount;

  /// `PrefKeys.closedCount` — 1 bo'lsa, oflayn yopilish serverga yuborilishi
  /// kutilyapti.
  final int closedCount;

  final bool shiftsOpened;
  final int currentShiftKey;
  final String posName;
  final String cashboxId;
  final String cashierName;

  bool get hasPendingClose => pendingCloseAt.isNotEmpty;

  bool get hasPendingOpen => pendingOpenAt.isNotEmpty;

  /// Internetsiz yopish mumkinmi.
  ///
  /// `ShiftSingleton4.closeShift` ning oflayn shoxidagi shartning aynan
  /// nusxasi — ikkalasi bir joydan o'qilishi kerak, aks holda UI "yopiladi"
  /// deb va'da berib, kod yopmay qo'yadi (2026-08-17 hodisasi).
  bool get canCloseOffline => openedCount == 0 && closedCount == 0;
}

class ShiftDiagnostics {
  ShiftDiagnostics._();

  /// Bir xil muammo qayta-qayta Telegramni to'ldirmasligi uchun eng kam oraliq.
  /// 2026-08-13 da kassir 15 marta bosgan — 15 ta bir xil xabar ketgan.
  static const Duration _minReportInterval = Duration(minutes: 5);

  static final Map<String, DateTime> _lastReportAt = {};
  static final Map<String, int> _suppressedCount = {};

  /// Oxirgi ochish urinishida aniqlangan sabab — `ShiftSingleton4.openShift`
  /// bool? qaytargani uchun sabab shu yerda saqlanadi.
  static ShiftIssue? lastOpenIssue;

  /// Sabab bo'yicha qo'shimcha ma'lumot (kim ochgan, qaysi kassa va h.k.).
  static String lastOpenDetail = '';

  static void resetOpenIssue() {
    lastOpenIssue = null;
    lastOpenDetail = '';
  }

  /* ─────────────────────────── HOLAT YIG'ISH ─────────────────────────── */

  /// POS'ning joriy holatini yig'adi. [internet] berilmasa o'zi tekshiradi.
  static Future<ShiftSnapshot> capture({bool? internet}) async {
    final bool hasNet =
        internet ?? await InternetConnectionChecker().hasConnection;

    int unsent = 0;
    int rejected = 0;
    try {
      final box = MyObjectbox.saleStore.box<ReceiptModel4>();

      final unsentQuery = box
          .query(ReceiptModel4_.uploaded.equals(false) &
              ReceiptModel4_.rejected.equals(false))
          .build();
      unsent = unsentQuery.count();
      unsentQuery.close();

      final rejectedQuery = box
          .query(ReceiptModel4_.uploaded.equals(false) &
              ReceiptModel4_.rejected.equals(true))
          .build();
      rejected = rejectedQuery.count();
      rejectedQuery.close();
    } catch (_) {
      // ObjectBox o'qib bo'lmasa ham diagnostika ishlashda davom etsin.
    }

    return ShiftSnapshot(
      internet: hasNet,
      unsentReceipts: unsent,
      rejectedReceipts: rejected,
      pendingCloseAt: Pref.getString(PrefKeys.closedDate, ''),
      pendingOpenAt: Pref.getString(PrefKeys.openedDate, ''),
      openedCount: Pref.getInt(PrefKeys.openedCount, 0),
      closedCount: Pref.getInt(PrefKeys.closedCount, 0),
      shiftsOpened: Pref.getBool(PrefKeys.shiftsOpened, false),
      currentShiftKey: Pref.getInt(PrefKeys.currentShiftKey, -1),
      posName: Pref.getString(PrefKeys.posName, '-'),
      cashboxId: Pref.getString(PrefKeys.activatedPosId, ''),
      cashierName: Pref.getString(PrefKeys.cashierName, '-'),
    );
  }

  /// Smenani yopishdan oldin kassirga ko'rsatilishi kerak bo'lgan
  /// ogohlantirishlar. Bo'sh ro'yxat — hammasi joyida.
  ///
  /// Bu yerda faqat **kassir tuzata oladigan** yoki **smenaning serverga
  /// yetishiga to'sqinlik qiladigan** holatlar bo'ladi.
  ///
  /// `rejectedReceipts` ataylab ro'yxatda YO'Q: server rad etgan chekni kassir
  /// yopish paytida tuzata olmaydi va u smenaning yopilishiga xalaqit
  /// bermaydi — ogohlantirish shunchaki shovqin bo'lardi. Ular baribir
  /// Telegram hisobotida (`Rad etilgan cheklar: N`) ko'rinadi va Sozlamalar →
  /// rad etilgan cheklar bo'limidan alohida boshqariladi.
  /// Smenani yopish **umuman mumkin emas** bo'lgan holat.
  ///
  /// `null` qaytsa — yopishga urinish mumkin. Aks holda yopish tugmasi
  /// bosilganda hech narsa yozilmasligi kerak: `ShiftSingleton4.closeShift`
  /// Hive yozuviga `isClosed=true` va `closedDate` ni **shartni tekshirishdan
  /// oldin** yozadi, keyin esa shart bajarilmasa smenani yopmay qo'yadi.
  /// Natijada Hive'da "yopiq", POS'da "ochiq" — nomuvofiq holat qoladi.
  ///
  /// Faqat oflayn holat tekshiriladi: internet bo'lsa yopish server javobiga
  /// qarab hal qilinadi.
  static ShiftIssue? blockingCloseIssue(ShiftSnapshot s) {
    if (s.internet || s.canCloseOffline) return null;
    if (s.openedCount != 0) return ShiftIssue.offlineCloseBlockedByPendingOpen;
    return ShiftIssue.offlineCloseBlockedByPendingClose;
  }

  static List<ShiftIssue> closeWarnings(ShiftSnapshot s) {
    final List<ShiftIssue> issues = [];
    if (!s.internet) issues.add(ShiftIssue.noInternet);
    if (s.unsentReceipts > 0) issues.add(ShiftIssue.unsentReceipts);
    if (s.hasPendingClose) issues.add(ShiftIssue.pendingCloseNotSynced);
    if (s.cashboxId.isEmpty) issues.add(ShiftIssue.posNotActivated);
    return issues;
  }

  /* ─────────────────────── KASSIR UCHUN XABARLAR ─────────────────────── */

  /// Muammoning qisqa sarlavhasi.
  static String title(ShiftIssue issue, {required bool isUz}) {
    switch (issue) {
      case ShiftIssue.noInternet:
        return isUz ? 'Internet yo\'q' : 'Нет интернета';
      case ShiftIssue.unsentReceipts:
        return isUz ? 'Ketmagan cheklar bor' : 'Есть неотправленные чеки';
      case ShiftIssue.rejectedReceipts:
        return isUz ? 'Rad etilgan cheklar bor' : 'Есть отклонённые чеки';
      case ShiftIssue.pendingCloseNotSynced:
        return isUz
            ? 'Oldingi smena yopilishi serverga yetmagan'
            : 'Закрытие прошлой смены не дошло до сервера';
      case ShiftIssue.pendingOpenNotSynced:
        return isUz
            ? 'Smena ochilishi serverga yetmagan'
            : 'Открытие смены не дошло до сервера';
      case ShiftIssue.offlineCloseBlockedByPendingOpen:
        return isUz
            ? 'Smena yopilmadi — ochilishi serverga yetmagan'
            : 'Смена не закрыта — открытие не дошло до сервера';
      case ShiftIssue.offlineCloseBlockedByPendingClose:
        return isUz
            ? 'Smena yopilmadi — oldingi yopish navbatda'
            : 'Смена не закрыта — прошлое закрытие в очереди';
      case ShiftIssue.serverCloseFailed:
        return isUz
            ? 'Server smenani yopmadi'
            : 'Сервер не закрыл смену';
      case ShiftIssue.cashboxOpenOnServer:
        return isUz
            ? 'Bu kassa serverda ochiq turibdi'
            : 'Эта касса открыта на сервере';
      case ShiftIssue.cashboxOpenOnWeb:
        return isUz
            ? 'Smena web orqali ochilgan'
            : 'Смена открыта через веб';
      case ShiftIssue.cashboxNotFoundOnServer:
        return isUz
            ? 'Kassa server ro\'yxatida topilmadi'
            : 'Касса не найдена в списке сервера';
      case ShiftIssue.serverStatusUnavailable:
        return isUz
            ? 'Server javob bermadi'
            : 'Сервер не ответил';
      case ShiftIssue.posNotActivated:
        return isUz ? 'Kassa aktivlashtirilmagan' : 'Касса не активирована';
      case ShiftIssue.localShiftMissing:
        return isUz ? 'Smena yozuvi topilmadi' : 'Запись смены не найдена';
      case ShiftIssue.unknown:
        return isUz ? 'Noma\'lum xato' : 'Неизвестная ошибка';
    }
  }

  /// Sabab + nima qilish kerakligi. Kassir shu matnni o'qib harakat qila oladi.
  static String explain(
    ShiftIssue issue,
    ShiftSnapshot s, {
    required bool isUz,
    ShiftAction action = ShiftAction.close,
  }) {
    switch (issue) {
      case ShiftIssue.noInternet:
        return isUz
            ? 'Internet ulanmagan. Smena kassada yopiladi va serverga yuborish '
                'navbatiga tushadi — internet tiklangach avtomatik yuboriladi. '
                'Yopish serverga yetmaguncha bu kassada keyingi smenani '
                'internetsiz yopib bo\'lmaydi.'
            : 'Нет интернета. Смена закроется на кассе и попадёт в очередь '
                'отправки — уйдёт автоматически после восстановления связи. Пока '
                'закрытие не дошло до сервера, следующую смену на этой кассе без '
                'интернета закрыть не получится.';
      case ShiftIssue.unsentReceipts:
        return isUz
            ? '${s.unsentReceipts} ta chek hali serverga yuborilmagan. '
                'Smenani hozir yopsangiz, bu cheklar hisobotga tushmasligi '
                'mumkin. Avval cheklarni yuboring.'
            : '${s.unsentReceipts} чек(ов) ещё не отправлены на сервер. Если '
                'закрыть смену сейчас, они могут не попасть в отчёт. Сначала '
                'отправьте чеки.';
      case ShiftIssue.rejectedReceipts:
        return isUz
            ? '${s.rejectedReceipts} ta chekni server qabul qilmagan. Ular '
                'avtomatik qayta yuborilmaydi — Sozlamalar → rad etilgan '
                'cheklar bo\'limidan qo\'lda yuborish kerak.'
            : '${s.rejectedReceipts} чек(ов) сервер не принял. Они не '
                'отправляются автоматически — отправьте вручную через '
                'Настройки → отклонённые чеки.';
      case ShiftIssue.pendingCloseNotSynced:
        final ago = _agoText(s.pendingCloseAt, isUz: isUz);
        return isUz
            ? 'Oldingi smena kassada yopilgan, lekin serverga yetmagan$ago. '
                'Shu sababli server bu kassani hali "ochiq" deb hisoblaydi va '
                'yangi smena ochilmayapti. "Yopishni yuborish" tugmasini bosing.'
            : 'Прошлая смена закрыта на кассе, но не дошла до сервера$ago. '
                'Поэтому сервер всё ещё считает кассу открытой и новая смена не '
                'открывается. Нажмите «Отправить закрытие».';
      case ShiftIssue.pendingOpenNotSynced:
        final ago = _agoText(s.pendingOpenAt, isUz: isUz);
        return isUz
            ? 'Smena ochilishi serverga yetmagan$ago. Internet tiklangach '
                'avtomatik yuboriladi.'
            : 'Открытие смены не дошло до сервера$ago. Отправится автоматически '
                'при восстановлении связи.';
      case ShiftIssue.offlineCloseBlockedByPendingOpen:
        final ago = _agoText(s.pendingOpenAt, isUz: isUz);
        return isUz
            ? 'NIMA BO\'LDI: Smena yopilmadi — kassada ochiq qoldi.\n'
                'SABAB: Bu smena internetsiz ochilgan, shuning uchun serverda '
                'hali ochilmagan$ago. Serverda ochilmagan smenani yopib '
                'bo\'lmaydi.\n'
                'NIMA QILISH KERAK: Internetni ulang. Ulangan zahoti smena '
                'ochilishi avtomatik serverga yuboriladi — shundan keyin '
                'smenani odatdagidek yopasiz.\n'
                'Sotuvlar va cheklar yo\'qolmaydi, hammasi kassada saqlanib '
                'turibdi.'
            : 'ЧТО ПРОИЗОШЛО: Смена не закрыта — осталась открытой на кассе.\n'
                'ПРИЧИНА: Эта смена открыта без интернета, поэтому на сервере '
                'она ещё не открыта$ago. Закрыть смену, которой нет на сервере, '
                'невозможно.\n'
                'ЧТО ДЕЛАТЬ: Подключите интернет. Сразу после подключения '
                'открытие смены уйдёт на сервер автоматически — после этого '
                'закройте смену как обычно.\n'
                'Продажи и чеки не потеряются, всё сохранено на кассе.';
      case ShiftIssue.offlineCloseBlockedByPendingClose:
        final ago = _agoText(s.pendingCloseAt, isUz: isUz);
        return isUz
            ? 'NIMA BO\'LDI: Smena yopilmadi — kassada ochiq qoldi.\n'
                'SABAB: Oldingi smena yopilishi hali serverga yuborilmagan$ago. '
                'Kassa bir vaqtda faqat bitta yuborilmagan yopishni saqlay '
                'oladi, shuning uchun internetsiz ikkinchi marta yopib '
                'bo\'lmaydi.\n'
                'NIMA QILISH KERAK: Internetni ulang — navbatdagi yopish '
                'yuboriladi, shundan keyin bu smenani yopasiz.\n'
                'Sotuvlar va cheklar yo\'qolmaydi.'
            : 'ЧТО ПРОИЗОШЛО: Смена не закрыта — осталась открытой на кассе.\n'
                'ПРИЧИНА: Закрытие прошлой смены ещё не отправлено на сервер'
                '$ago. Касса хранит только одно неотправленное закрытие, '
                'поэтому без интернета закрыть второй раз нельзя.\n'
                'ЧТО ДЕЛАТЬ: Подключите интернет — закрытие из очереди уйдёт на '
                'сервер, после этого закройте эту смену.\n'
                'Продажи и чеки не потеряются.';
      case ShiftIssue.serverCloseFailed:
        // Navbatga tushdimi? `ShiftSyncQueue` faqat `closedCount == 1` bo'lsa
        // qayta yuboradi. Aks holda "qayta yuboriladi" deb va'da berish
        // yolg'on bo'ladi — kassir kutib o'tiradi, hech narsa ketmaydi.
        final bool queued = s.closedCount == 1 && s.hasPendingClose;
        return isUz
            ? 'NIMA BO\'LDI: Smena kassada yopildi, lekin server tasdiqlamadi.\n'
                'SABAB: Yopish so\'rovi serverga yuborildi, server esa muvaffaqiyat '
                'javobini qaytarmadi.\n'
                '${queued ? "NIMA QILISH KERAK: Yopish navbatda saqlandi — "
                    "internet barqaror bo'lganda avtomatik qayta yuboriladi. "
                    "Yangi smena ochishdan oldin yopish serverga yetganiga "
                    "ishonch hosil qiling." : "NIMA QILISH KERAK: Yopish navbatga "
                    "tushmadi — \"Yopishni yuborish\" tugmasi orqali qo'lda "
                    "yuboring yoki yopishni qaytadan bajaring."}'
            : 'ЧТО ПРОИЗОШЛО: Смена закрыта на кассе, но сервер не подтвердил.\n'
                'ПРИЧИНА: Запрос на закрытие ушёл на сервер, но успешного ответа '
                'не было.\n'
                '${queued ? "ЧТО ДЕЛАТЬ: Закрытие сохранено в очереди — уйдёт "
                    "автоматически при стабильной связи. Перед открытием новой "
                    "смены убедитесь, что закрытие дошло." : "ЧТО ДЕЛАТЬ: "
                    "Закрытие не попало в очередь — отправьте вручную кнопкой "
                    "«Отправить закрытие» или закройте смену заново."}';
      case ShiftIssue.cashboxOpenOnServer:
        return isUz
            ? 'Serverda bu kassaning smenasi ochiq turibdi, shuning uchun yangi '
                'smena ochib bo\'lmaydi.${s.hasPendingClose ? ' Sabab: oldingi '
                    'yopish serverga yetmagan — "Yopishni yuborish"ni bosing.' : ''}'
            : 'На сервере смена этой кассы открыта, поэтому новую открыть '
                'нельзя.${s.hasPendingClose ? ' Причина: прошлое закрытие не '
                    'дошло до сервера — нажмите «Отправить закрытие».' : ''}';
      case ShiftIssue.cashboxOpenOnWeb:
        return isUz
            ? 'Bu kassaning smenasi web (admin panel) orqali ochilgan. Uni web '
                'orqali yoping yoki administratorga murojaat qiling.'
            : 'Смена этой кассы открыта через веб (админ-панель). Закройте её '
                'через веб или обратитесь к администратору.';
      case ShiftIssue.cashboxNotFoundOnServer:
        return isUz
            ? 'Bu kassa server ro\'yxatida yo\'q. Kassa o\'chirilgan yoki boshqa '
                'do\'konga ko\'chirilgan bo\'lishi mumkin — administratorga '
                'murojaat qiling.'
            : 'Этой кассы нет в списке сервера. Возможно, касса удалена или '
                'перенесена в другой магазин — обратитесь к администратору.';
      case ShiftIssue.serverStatusUnavailable:
        return isUz
            ? 'Smena holatini serverdan olib bo\'lmadi. Internetni tekshirib, '
                'qayta urinib ko\'ring.'
            : 'Не удалось получить статус смены с сервера. Проверьте интернет и '
                'попробуйте снова.';
      case ShiftIssue.posNotActivated:
        return isUz
            ? 'Kassa aktivlashtirilmagan (kassa ID bo\'sh). Sozlamalardan '
                'kassani qayta tanlang.'
            : 'Касса не активирована (пустой ID кассы). Выберите кассу заново в '
                'настройках.';
      case ShiftIssue.localShiftMissing:
        return isUz
            ? 'Joriy smena yozuvi topilmadi. Smena ma\'lumotlari buzilgan '
                'bo\'lishi mumkin — hisobotni tekshiring.'
            : 'Запись текущей смены не найдена. Данные смены могли повредиться — '
                'проверьте отчёт.';
      case ShiftIssue.unknown:
        return isUz
            ? 'Kutilmagan xato yuz berdi. Xabar dasturchilarga yuborildi.'
            : 'Произошла непредвиденная ошибка. Сообщение отправлено '
                'разработчикам.';
    }
  }

  /// Snackbar uchun bir qatorli xabar.
  static String shortMessage(
    ShiftIssue issue,
    ShiftSnapshot s, {
    required bool isUz,
  }) {
    switch (issue) {
      case ShiftIssue.unsentReceipts:
        return isUz
            ? 'Smena yopilmadi: ${s.unsentReceipts} ta chek serverga ketmagan'
            : 'Смена не закрыта: ${s.unsentReceipts} чек(ов) не отправлены';
      case ShiftIssue.noInternet:
        return isUz
            ? 'Internet yo\'q — smena serverga yuborilmadi'
            : 'Нет интернета — смена не отправлена на сервер';
      default:
        return '${title(issue, isUz: isUz)}: '
            '${explain(issue, s, isUz: isUz).split('.').first}.';
    }
  }

  /* ────────────────────────── TELEGRAM HISOBOTI ────────────────────────── */

  /// Telegramga tuzilgan, o'qiladigan hisobot yuboradi.
  ///
  /// Xabar o'zbekcha — bu texnik kanal, kassir emas, dasturchi o'qiydi.
  /// Bir xil muammo [_minReportInterval] ichida takrorlansa yuborilmaydi,
  /// keyingi xabarda "takrorlanish: N marta" bo'lib ko'rinadi.
  static Future<void> report({
    required ShiftIssue issue,
    required ShiftAction action,
    ShiftSnapshot? snapshot,
    String? detail,
    bool force = false,
  }) async {
    final ShiftSnapshot s = snapshot ?? await capture();
    final String key = '${action.name}/${issue.name}';

    final DateTime now = DateTime.now();
    final DateTime? last = _lastReportAt[key];
    if (!force &&
        last != null &&
        now.difference(last) < _minReportInterval) {
      _suppressedCount[key] = (_suppressedCount[key] ?? 0) + 1;
      return;
    }
    final int repeats = _suppressedCount.remove(key) ?? 0;
    _lastReportAt[key] = now;

    await LogRepository.addLog(
      _buildBody(issue, action, s, detail: detail, repeats: repeats),
      file: action == ShiftAction.close ? 'SMENA / Yopish' : 'SMENA / Ochish',
      method: action == ShiftAction.close ? 'SHIFT CLOSE' : 'SHIFT OPEN',
      where: 'ShiftDiagnostics',
      path: issue.name,
      statusCode: -1,
      url: '-',
    );
  }

  static String _buildBody(
    ShiftIssue issue,
    ShiftAction action,
    ShiftSnapshot s, {
    String? detail,
    int repeats = 0,
  }) {
    final String header = action == ShiftAction.close
        ? 'SMENA YOPISHDA MUAMMO'
        : 'SMENA OCHISHDA MUAMMO';

    final buffer = StringBuffer()
      ..writeln(header)
      ..writeln('SABAB: ${title(issue, isUz: true)}')
      ..writeln('KOD: ${issue.name}');

    if (repeats > 0) {
      buffer.writeln('TAKRORLANISH: yana $repeats marta (bosilgan)');
    }

    buffer
      ..writeln('')
      ..writeln('Kassa: ${s.posName}')
      ..writeln('Kassa ID: ${s.cashboxId.isEmpty ? "BO'SH" : s.cashboxId}')
      ..writeln('Kassir: ${s.cashierName}')
      ..writeln('Internet: ${s.internet ? "bor" : "yo'q"}')
      ..writeln('Ketmagan cheklar: ${s.unsentReceipts}')
      ..writeln('Rad etilgan cheklar: ${s.rejectedReceipts}')
      ..writeln('Lokal smena: ${s.shiftsOpened ? "ochiq" : "yopiq"}')
      ..writeln('Smena kaliti: ${s.currentShiftKey}')
      ..writeln('Serverga yetmagan YOPISH: '
          '${s.hasPendingClose ? "${s.pendingCloseAt} UTC"
              "${_agoText(s.pendingCloseAt, isUz: true)}" : "yo'q"}')
      ..writeln('Serverga yetmagan OCHISH: '
          '${s.hasPendingOpen ? "${s.pendingOpenAt} UTC"
              "${_agoText(s.pendingOpenAt, isUz: true)}" : "yo'q"}');

    if (detail != null && detail.trim().isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln('QO\'SHIMCHA:')
        ..writeln(detail.trim());
    }

    buffer
      ..writeln('')
      ..writeln('KASSIRGA KO\'RSATILDI:')
      ..writeln(explain(issue, s, isUz: true, action: action));

    return buffer.toString();
  }

  /* ──────────────────────────── YORDAMCHILAR ──────────────────────────── */

  /// `yyyy-MM-dd HH:mm:ss` (UTC) matnidan "(38 daqiqa oldin)" hosil qiladi.
  static String _agoText(String utcText, {required bool isUz}) {
    final Duration? d = _sinceUtc(utcText);
    if (d == null) return '';
    final int minutes = d.inMinutes;
    if (minutes < 1) return isUz ? ' (hozirgina)' : ' (только что)';
    if (minutes < 60) {
      return isUz ? ' ($minutes daqiqa oldin)' : ' ($minutes мин. назад)';
    }
    final int hours = d.inHours;
    if (hours < 24) {
      return isUz ? ' ($hours soat oldin)' : ' ($hours ч. назад)';
    }
    return isUz ? ' (${d.inDays} kun oldin)' : ' (${d.inDays} дн. назад)';
  }

  static Duration? _sinceUtc(String utcText) {
    if (utcText.trim().isEmpty) return null;
    try {
      final DateTime parsed = DateTime.parse('${utcText.trim()}Z');
      final Duration diff = DateTime.now().toUtc().difference(parsed);
      return diff.isNegative ? Duration.zero : diff;
    } catch (_) {
      return null;
    }
  }
}
