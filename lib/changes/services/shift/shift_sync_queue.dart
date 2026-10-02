import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:invan2/changes/models/shift/shifting_model.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/shift/shift_diagnostics.dart';
import 'package:invan2/changes/services/shift_api_4.dart';
import 'package:invan2/utils/utils.dart';

enum ShiftQueueMethod { open, close }

/// Navbatdagi bitta voqea: smena ochildi yoki yopildi.
@immutable
class ShiftQueueEvent {
  const ShiftQueueEvent({
    required this.method,
    required this.at,
    required this.userId,
    required this.cashboxId,
    this.failures = 0,
    this.firstFailureAt,
  });

  final ShiftQueueMethod method;

  /// Voqea vaqti, `yyyy-MM-dd HH:mm:ss` (UTC) — serverga `opened_at` /
  /// `closed_at` bo'lib ketadi.
  final String at;

  /// Amalni bajargan kassir — voqea paytidagi `PrefKeys.userId`.
  final String userId;

  /// Voqea sodir bo'lgan kassa — voqea paytidagi `PrefKeys.activatedPosId`.
  /// Kassa keyin boshqasiga qayta aktivlashtirilsa ham voqea o'z kassasiga
  /// ketadi. Bo'sh bo'lsa (eski yozuv) — yuborish paytidagi kassa.
  final String cashboxId;

  /// Server TIRIK bo'lib (kassa holatini ko'rsatib) bu voqeani necha marta
  /// qabul qilmagan. Uzilish paytidagi urinishlar sanalmaydi.
  final int failures;

  /// Birinchi shunday rad etish vaqti.
  final DateTime? firstFailureAt;

  bool get isOpen => method == ShiftQueueMethod.open;

  bool get isClose => method == ShiftQueueMethod.close;

  /// Aynan shu voqeami. `userId` hisobga olinmaydi: eski kalitlardan
  /// tiklangan voqea `userId` ni joriy kassirdan oladi va u o'zgarishi
  /// mumkin. Bir xil turdagi ikki voqea bir soniyada sodir bo'lmaydi.
  bool sameAs(ShiftQueueEvent other) =>
      other.method == method && other.at == at;

  /// Yana bir rad etish qayd etilgan nusxa.
  ShiftQueueEvent withFailure(DateTime now) => ShiftQueueEvent(
        method: method,
        at: at,
        userId: userId,
        cashboxId: cashboxId,
        failures: failures + 1,
        firstFailureAt: firstFailureAt ?? now,
      );

  Map<String, dynamic> toJson() => {
        'method': method.name,
        'at': at,
        'user_id': userId,
        'cashbox_id': cashboxId,
        if (failures > 0) 'failures': failures,
        if (firstFailureAt != null)
          'first_failure_at': firstFailureAt!.toIso8601String(),
      };

  static ShiftQueueEvent? fromJson(dynamic json) {
    if (json is! Map) return null;
    final String at = '${json['at'] ?? ''}';
    if (at.isEmpty) return null;
    final String name = '${json['method']}';
    final ShiftQueueMethod method;
    if (name == 'open') {
      method = ShiftQueueMethod.open;
    } else if (name == 'close') {
      method = ShiftQueueMethod.close;
    } else {
      return null;
    }
    return ShiftQueueEvent(
      method: method,
      at: at,
      userId: '${json['user_id'] ?? ''}',
      cashboxId: '${json['cashbox_id'] ?? ''}',
      failures: int.tryParse('${json['failures'] ?? 0}') ?? 0,
      firstFailureAt: DateTime.tryParse('${json['first_failure_at'] ?? ''}'),
    );
  }

  @override
  String toString() => '${isOpen ? "ochish" : "yopish"} $at';
}

/// Serverga yetkazilmagan smena ochish/yopish voqealarining navbati.
///
/// Kassa oflayn ishlashi shart: server yoki internet bo'lmasa smena avval
/// **lokal** ochiladi/yopiladi, serverga yuborish esa shu navbatga qo'yiladi.
///
/// Navbat — voqealar RO'YXATI. Har voqea o'z vaqti va o'z kassiri bilan
/// saqlanadi va serverga aynan sodir bo'lgan tartibda (FIFO) yuboriladi.
///
/// Nima uchun ro'yxat. 2026-10-02 gacha navbatda ochish va yopish uchun
/// bittadan joy bor edi (`openedDate`/`closedDate`):
/// - ikkinchi oflayn ochish birinchisining vaqtini o'chirib yuborardi. Server
///   ertalabdan o'chiq kunda "ochish 08:00 → yopish 14:00 → ochish 14:05"
///   navbatda "yopish 14:00, ochish 14:05" bo'lib qolardi — 08:00–14:00
///   smenasi serverga UMUMAN yetmasdi (yopiq kassani yopishga server 200
///   qaytaradi, ya'ni yopish bekor ketardi — jonli dev sinovi, 2026-10-02);
/// - ikkinchi oflayn yopish umuman bloklanardi (joy band edi);
/// - `user_id` yuborish paytidagi kassirdan olinardi.
///
/// Haqiqiy server (dev, 2026-10-02 jonli sinov): o'tgan va hatto kechagi
/// vaqtli ochish/yopishni ketma-ket qabul qiladi (200), vaqt tartibini
/// tekshirmaydi, takror ochish/yopishga 200 "OK" qaytaradi (holat
/// o'zgarmaydi), mavjud bo'lmagan `user_id` ga 500 ("sql: no rows"),
/// yaroqsiz tokenga 403.
///
/// Qoidalar:
/// 1. Navbat bo'sh bo'lmasa yangi voqea to'g'ridan-to'g'ri serverga
///    yuborilmaydi — navbat oxiriga turadi (aks holda tartib buziladi).
/// 2. Yuborish birinchi voqeadan boshlanadi va u o'tmaguncha keyingisiga
///    o'tilmaydi.
/// 3. Server 200/201 qaytarmasa, voqea faqat serverdagi kassa holati
///    ALLAQACHON unga mos bo'lsa olib tashlanadi (javobi yo'qolgan yoki
///    takror yuborilgan voqea) — buni `shift_statuses` dan so'raymiz. Status
///    kodiga ishonilmaydi: qayta ishga tushayotgan server ham 500/404
///    qaytaradi va darhol tiriladi — kod bo'yicha "rad etildi" deb tashlab
///    yuborilgan haqiqiy yopilish serverni kassadan ajratib qo'yardi
///    (tasodifiy stend testida topilgan).
/// 4. Aks holda voqea navbatda qoladi va yuborish to'xtaydi (Telegram
///    hisoboti bilan) — keyingi urinishda davom etadi.
/// 5. ZAHARLI voqea: server TIRIK bo'lib (kassa holatini ko'rsatib) uni
///    kamida [poisonAttempts] marta va [poisonAfter] dan uzoq qabul
///    qilmasa (masalan kassir backend'da o'chirilgan) — u majburiy Telegram
///    hisoboti bilan olib tashlanadi. Aks holda bitta buzuq voqea butun
///    navbatni va tizimdan chiqishni abadiy to'sib qo'yardi.
class ShiftSyncQueue {
  ShiftSyncQueue._();

  static bool _inProgress = false;

  /// Zaharli voqea uchun eng kam rad etishlar soni (qoida 5).
  static const int poisonAttempts = 5;

  /// Zaharli voqea uchun birinchi rad etishdan beri o'tishi kerak bo'lgan
  /// vaqt (qoida 5). Qisqa qisman uzilishda haqiqiy voqea tashlanmasligi
  /// uchun uzun.
  static const Duration poisonAfter = Duration(hours: 1);

  /// Hozirgi vaqt — testlarda soatni oldinga surish uchun almashtiriladi.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  /* ─────────────────────────────── O'QISH ─────────────────────────────── */

  /// Navbatdagi voqealar — eskisidan yangisiga.
  static List<ShiftQueueEvent> get pending => _load();

  static int get pendingCount => _load().length;

  static bool get hasPending => _load().isNotEmpty;

  /// Navbatda kutayotgan yopish bormi.
  static bool get hasPendingClose => _load().any((e) => e.isClose);

  /// Navbatda kutayotgan ochish bormi.
  static bool get hasPendingOpen => _load().any((e) => e.isOpen);

  /// Hisobot uchun: "ochish 2026-10-02 03:00:00 → yopish ...".
  static String describe([List<ShiftQueueEvent>? events]) =>
      (events ?? _load()).join(' → ');

  /* ─────────────────────────────── YOZISH ─────────────────────────────── */

  /// Smena ochilishini navbatga qo'yadi. [at] — ochilish vaqti (UTC),
  /// [userId] / [cashboxId] — ochgan kassir va kassa (berilmasa joriy
  /// `PrefKeys.userId` / `PrefKeys.activatedPosId`).
  static Future<void> enqueueOpen(
    String at, {
    String? userId,
    String? cashboxId,
  }) =>
      _enqueue(ShiftQueueMethod.open, at, userId, cashboxId);

  /// Smena yopilishini navbatga qo'yadi. [at] — yopilish vaqti (UTC),
  /// [userId] / [cashboxId] — yopgan kassir va kassa (berilmasa joriy
  /// `PrefKeys.userId` / `PrefKeys.activatedPosId`).
  static Future<void> enqueueClose(
    String at, {
    String? userId,
    String? cashboxId,
  }) =>
      _enqueue(ShiftQueueMethod.close, at, userId, cashboxId);

  static Future<void> _enqueue(
    ShiftQueueMethod method,
    String at,
    String? userId,
    String? cashboxId,
  ) async {
    final List<ShiftQueueEvent> events = _load()
      ..add(ShiftQueueEvent(
        method: method,
        at: at,
        userId: userId ?? Pref.getString(PrefKeys.userId, ''),
        cashboxId: cashboxId ?? Pref.getString(PrefKeys.activatedPosId, ''),
      ));
    await _save(events);
  }

  /* ────────────────────────────── YUBORISH ────────────────────────────── */

  /// Navbatni serverga yuborishga urinadi.
  ///
  /// Xavfsiz: navbat bo'sh bo'lsa yoki boshqa urinish ketayotgan bo'lsa
  /// darhol qaytadi, shuning uchun istalgan joydan (startup, tarmoq yoki
  /// server tiklanganda, cheklar ketgandan keyin) chaqirish mumkin.
  static Future<void> flush({required String reason}) async {
    if (_inProgress || !hasPending) return;
    _inProgress = true;

    try {
      while (true) {
        final List<ShiftQueueEvent> events = _load();
        if (events.isEmpty) return;
        final ShiftQueueEvent event = events.first;

        final int status = await _send(event);
        if (kDebugMode) {
          print('ShiftSyncQueue: $event ($reason) → $status');
        }

        if (status == 200 || status == 201) {
          if (!await _remove(event)) return;
          continue;
        }

        // Muvaffaqiyat javobi kelmadi. Bu "server yiqilgan", "javob
        // yo'qolgan" yoki "server rad etdi" bo'lishi mumkin — status kodidan
        // ajratib bo'lmaydi: qayta ishga tushayotgan server ham 500/502/404
        // qaytaradi va bir lahzadan keyin tiriladi. Shuning uchun voqea
        // faqat serverning O'ZI tasdiqlaganda olib tashlanadi: kassa holati
        // allaqachon bu voqea kutgan holatda (javobi yo'qolgan yoki takror
        // yuborilgan voqea). Aks holda u navbatda qoladi — haqiqiy amal hech
        // qachon tashlab yuborilmaydi.
        final bool? applied = await _alreadyApplied(event);
        if (applied == true) {
          if (!await _remove(event)) return;
          await ShiftDiagnostics.report(
            issue: event.isOpen
                ? ShiftIssue.pendingOpenNotSynced
                : ShiftIssue.pendingCloseNotSynced,
            action: event.isOpen ? ShiftAction.open : ShiftAction.close,
            detail: 'Navbatdagi voqea ($reason): $event — server javobi '
                'status $status, lekin serverdagi kassa holati ALLAQACHON '
                'MOS (javob yo\'qolgan yoki takror). Voqea navbatdan olindi, '
                'keyingisi yuboriladi.\n'
                'Navbatda qoldi: ${_describeOrNone()}',
          );
          continue;
        }

        if (applied == false) {
          // Server TIRIK (kassa holatini ko'rsatdi), lekin voqeani qabul
          // qilmayapti. Qisqa qisman uzilish bo'lishi mumkin — darhol
          // tashlamaymiz, faqat sanaymiz (qoida 5).
          final ShiftQueueEvent counted = event.withFailure(now());
          if (counted.failures >= poisonAttempts &&
              now().difference(counted.firstFailureAt!) >= poisonAfter) {
            if (!await _remove(event)) return;
            await ShiftDiagnostics.report(
              issue: event.isOpen
                  ? ShiftIssue.pendingOpenNotSynced
                  : ShiftIssue.pendingCloseNotSynced,
              action: event.isOpen ? ShiftAction.open : ShiftAction.close,
              detail: 'ZAHARLI VOQEA NAVBATDAN OLIB TASHLANDI ($reason): '
                  '$event, user_id=${event.userId}, '
                  'cashbox_id=${_cashboxOf(event)}. Server tirik, lekin uni '
                  '${counted.failures} marta (birinchisi '
                  '${counted.firstFailureAt}) qabul qilmadi, oxirgi status '
                  '$status. Serverda QO\'LDA tekshiring — bu ochish/yopish '
                  'serverga yetmagan.\n'
                  'Navbatda qoldi: ${_describeOrNone()}',
              force: true,
            );
            continue;
          }
          await _replace(event, counted);
        }

        await ShiftDiagnostics.report(
          issue: event.isOpen
              ? ShiftIssue.pendingOpenNotSynced
              : ShiftIssue.pendingCloseNotSynced,
          action: event.isOpen ? ShiftAction.open : ShiftAction.close,
          detail: 'Navbatni yuborish ($reason) to\'xtadi: $event, '
              'status $status'
              '${applied == false ? ", server rad etdi (${event.failures + 1}-marta)" : ""}'
              '. Navbatda qoldi: ${_describeOrNone()}',
        );
        return;
      }
    } finally {
      _inProgress = false;
    }
  }

  static String _describeOrNone() {
    final String text = describe();
    return text.isEmpty ? "yo'q" : text;
  }

  /// Serverdagi kassa holati [event] kutgan holatdami: ochish uchun kassa
  /// ochiq, yopish uchun to'liq yopiq. `null` — bilib bo'lmadi (server
  /// javob bermadi yoki kassa ro'yxatda yo'q).
  static Future<bool?> _alreadyApplied(ShiftQueueEvent event) async {
    final HttpResult res = await ShiftApi4.shiftStatusInvan2();
    if (!res.isSuccess || res.result is! List) return null;
    final String cashboxId = _cashboxOf(event);
    for (final dynamic cashBox in res.result as List) {
      if (cashBox is Map && cashBox['cashbox_id'] == cashboxId) {
        final bool fullyClosed = ShiftApi4.isCashboxFullyClosed(cashBox);
        return event.isOpen ? !fullyClosed : fullyClosed;
      }
    }
    return null;
  }

  static String _cashboxOf(ShiftQueueEvent event) => event.cashboxId.isNotEmpty
      ? event.cashboxId
      : Pref.getString(PrefKeys.activatedPosId, '');

  /// Voqeani serverga yuboradi va HTTP status kodini qaytaradi.
  /// Istisno bo'lsa -2 (`ApiProvider` dagi "kutilmagan xato" kodi).
  static Future<int> _send(ShiftQueueEvent event) async {
    final String cashboxId = _cashboxOf(event);
    if (event.isOpen) {
      final HttpResult res = await ShiftApi4.openShift(
          openedAt: event.at, userId: event.userId, cashboxId: cashboxId);
      return res.statusCode;
    }
    final ShiftingModel res = await ShiftApi4.closeShift(
        closedAt: event.at, userId: event.userId, cashboxId: cashboxId);
    return res.statusCode ?? -2;
  }

  /// [old] o'rniga [updated] ni yozadi (rad etishlar hisobi uchun).
  static Future<void> _replace(
    ShiftQueueEvent old,
    ShiftQueueEvent updated,
  ) async {
    final List<ShiftQueueEvent> events = _load();
    final int index = events.indexWhere((e) => e.sameAs(old));
    if (index < 0) return;
    events[index] = updated;
    await _save(events);
  }

  /// [event] ni navbatdan olib tashlaydi. `false` — topilmadi.
  static Future<bool> _remove(ShiftQueueEvent event) async {
    final List<ShiftQueueEvent> events = _load();
    final int index = events.indexWhere((e) => e.sameAs(event));
    if (index < 0) return false;
    events.removeAt(index);
    await _save(events);
    return true;
  }

  /* ─────────────────────────────── SAQLASH ─────────────────────────────── */

  static List<ShiftQueueEvent> _load() {
    final List<ShiftQueueEvent> events = [];
    final String raw = Pref.getString(PrefKeys.shiftSyncQueue, '');
    if (raw.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final dynamic item in decoded) {
            final ShiftQueueEvent? event = ShiftQueueEvent.fromJson(item);
            if (event != null) events.add(event);
          }
        }
      } catch (_) {
        // Buzilgan yozuv — bo'sh navbat deb hisoblaymiz.
      }
    }

    // Eski kalitlar ro'yxat OXIRIGA qo'shiladi: oddiy yangilanishda ro'yxat
    // bo'sh, Shorebird rollback'dan keyin esa eski kod yozgan voqealar
    // ro'yxatdagilardan yangiroq. Ro'yxatga ko'chib bo'lganlari takrorlanmaydi
    // (yozuv o'rtasida ilova yopilgan bo'lsa).
    for (final ShiftQueueEvent legacy in _legacyEvents()) {
      if (!events.any((e) => e.sameAs(legacy))) events.add(legacy);
    }
    return events;
  }

  /// Ro'yxatni saqlaydi va eski kalitlarni tozalaydi — ulardagi voqealar
  /// endi ro'yxat ichida.
  static Future<void> _save(List<ShiftQueueEvent> events) async {
    await Pref.setString(
      PrefKeys.shiftSyncQueue,
      jsonEncode(events.map((e) => e.toJson()).toList()),
    );
    await Pref.setInt(PrefKeys.openedCount, 0);
    await Pref.setString(PrefKeys.openedDate, '');
    await Pref.setInt(PrefKeys.closedCount, 0);
    await Pref.setString(PrefKeys.closedDate, '');
  }

  /// Eski (2026-10-02 gacha) navbat kalitlaridagi voqealar.
  ///
  /// Kassa server o'chgan paytda yangilansa, navbat eski kalitlarda qolgan
  /// bo'ladi — u yo'qolmasligi kerak. Ikkalasi ham bo'lsa eski qoida bo'yicha
  /// vaqt tartibida (vaqt noaniq bo'lsa ochish oldin).
  static List<ShiftQueueEvent> _legacyEvents() {
    final String openedAt = Pref.getString(PrefKeys.openedDate, '');
    final String closedAt = Pref.getString(PrefKeys.closedDate, '');
    final bool hasOpen =
        openedAt.isNotEmpty && Pref.getInt(PrefKeys.openedCount, 0) == 1;
    final bool hasClose =
        closedAt.isNotEmpty && Pref.getInt(PrefKeys.closedCount, 0) == 1;
    if (!hasOpen && !hasClose) return const [];

    final String userId = Pref.getString(PrefKeys.userId, '');
    final String cashboxId = Pref.getString(PrefKeys.activatedPosId, '');
    final ShiftQueueEvent open = ShiftQueueEvent(
        method: ShiftQueueMethod.open,
        at: openedAt,
        userId: userId,
        cashboxId: cashboxId);
    final ShiftQueueEvent close = ShiftQueueEvent(
        method: ShiftQueueMethod.close,
        at: closedAt,
        userId: userId,
        cashboxId: cashboxId);
    if (!hasClose) return [open];
    if (!hasOpen) return [close];

    final DateTime? opened = DateTime.tryParse(openedAt);
    final DateTime? closed = DateTime.tryParse(closedAt);
    final bool openFirst =
        opened == null || closed == null || opened.isBefore(closed);
    return openFirst ? [open, close] : [close, open];
  }
}
