/*
    Ilova ochilishidagi yagona yuklash shkalasi (0–100%).

    Ilgari wrapper faqat aylanuvchi indikator ko'rsatardi: kassir na nima
    yuklanayotganini, na qanchasi qolganini bilardi — 43 MB lik katalog
    tortilayotganda ilova "qotib qolgan"dek ko'rinardi.

    Bu yerdagi foiz BITTA umumiy shkala: xodimlarni olishdan boshlab
    katalog lokal bazaga yozilib bo'lgunicha. Har bosqichga o'z ulushi
    ajratilgan va foiz faqat oldinga siljiydi.

    Ulushlar (jami 100):

      xodimlar          0 →  10
      MXIK/tasnif      10 →  15
      arxiv so'rovi    15 →  20     (server faylni tayyorlaydi)
      arxivni yuklash  20 →  85     (yagona haqiqiy uzluksiz bosqich)
      lokalga yozish   85 → 100

    Muhim: "yuklash" bosqichi ichidagi siljish serverning `Content-Length`
    idan hisoblanadi. U kelmasa (chunked javob) foiz o'sha bosqich
    boshida turadi va sun'iy ravishda "o'sib" ko'rinmaydi — kassirga
    o'ylab topilgan raqam ko'rsatilmasligi kerak.
*/

import 'package:flutter/foundation.dart';

enum StartupPhase {
  /// Yuklash ketmayapti.
  idle,

  /// Xodimlar ro'yxati olinmoqda.
  employees,

  /// MXIK/qadoq kodlari (tasnif.soliq.uz) olinmoqda.
  packageCode,

  /// Server mahsulotlar arxivini tayyorlamoqda.
  productsRequest,

  /// Arxiv yuklab olinmoqda — foiz shu bosqichda uzluksiz o'sadi.
  productsDownload,

  /// Katalog lokal bazaga yozilmoqda.
  productsSaving,

  /// Hammasi tugadi (100%).
  done,
}

extension StartupPhaseRange on StartupPhase {
  /// Bosqichning umumiy shkaladagi boshi (0–100).
  int get from {
    switch (this) {
      case StartupPhase.idle:
        return 0;
      case StartupPhase.employees:
        return 0;
      case StartupPhase.packageCode:
        return 10;
      case StartupPhase.productsRequest:
        return 15;
      case StartupPhase.productsDownload:
        return 20;
      case StartupPhase.productsSaving:
        return 85;
      case StartupPhase.done:
        return 100;
    }
  }

  /// Bosqichning umumiy shkaladagi oxiri (0–100).
  int get to {
    switch (this) {
      case StartupPhase.idle:
        return 0;
      case StartupPhase.employees:
        return 10;
      case StartupPhase.packageCode:
        return 15;
      case StartupPhase.productsRequest:
        return 20;
      case StartupPhase.productsDownload:
        return 85;
      case StartupPhase.productsSaving:
        return 100;
      case StartupPhase.done:
        return 100;
    }
  }
}

@immutable
class StartupProgressState {
  const StartupProgressState({
    required this.phase,
    required this.percent,
  });

  const StartupProgressState.idle()
      : this(phase: StartupPhase.idle, percent: 0);

  final StartupPhase phase;

  /// Umumiy bajarilish foizi (0–100).
  final int percent;

  bool get isActive => phase != StartupPhase.idle;

  @override
  bool operator ==(Object other) =>
      other is StartupProgressState &&
      other.phase == phase &&
      other.percent == percent;

  @override
  int get hashCode => Object.hash(phase, percent);
}

class StartupProgress {
  StartupProgress._();

  static final ValueNotifier<StartupProgressState> notifier =
      ValueNotifier<StartupProgressState>(const StartupProgressState.idle());

  static StartupProgressState get value => notifier.value;

  /// Bosqichni boshlaydi: foiz o'sha bosqichning boshiga qo'yiladi.
  ///
  /// [ratio] — bosqich ichidagi bajarilish (0.0–1.0), ma'lum bo'lsa.
  static void set(StartupPhase phase, {double? ratio}) {
    final int from = phase.from;
    final int to = phase.to;

    int percent = from;
    if (ratio != null && to > from) {
      final double r = ratio.clamp(0.0, 1.0);
      percent = from + ((to - from) * r).round();
    }

    _emit(phase, percent);
  }

  /// Arxivni yuklab olish siljishi.
  ///
  /// [total] noma'lum (`<= 0`) bo'lsa foiz bosqich boshida qoladi —
  /// taxminiy raqam chizilmaydi.
  static void download(int received, int total) => set(
        StartupPhase.productsDownload,
        ratio: total > 0 ? received / total : null,
      );

  /// Lokalga yozish ichidagi siljish (0.0–1.0).
  static void saving(double ratio) =>
      set(StartupPhase.productsSaving, ratio: ratio);

  static void done() => _emit(StartupPhase.done, 100);

  static void reset() => _emit(StartupPhase.idle, 0);

  /// Foiz ortga ketmaydi: bosqichlar ketma-ket bo'lgani uchun orqaga
  /// sakrash faqat xato bo'ladi va kassir ko'zida "qotib qolish"dek
  /// ko'rinadi. `idle` (reset) bundan mustasno.
  static void _emit(StartupPhase phase, int percent) {
    final StartupProgressState current = notifier.value;

    if (phase != StartupPhase.idle &&
        current.isActive &&
        percent < current.percent) {
      percent = current.percent;
    }

    final StartupProgressState next =
        StartupProgressState(phase: phase, percent: percent);

    // Foiz butun son — ya'ni 43 MB da har chunkda emas, faqat ko'rinish
    // haqiqatan o'zgarganda UI qayta chiziladi.
    if (current == next) return;
    notifier.value = next;
  }
}
