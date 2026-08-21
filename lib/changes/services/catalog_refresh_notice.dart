/*
    "Mahsulotlar bazasi yangilanmagan" ogohlantirishi.

    Muammo: ilova ochilganda `wrapper.dart` katalogni to'liq qayta yuklaydi,
    lekin o'sha paytda internet bo'lmasa (masalan kompyuter yoqilib, ilova
    tarmoq ko'tarilishidan oldin ishga tushsa) yuklash JIMGINA yiqiladi —
    na dialog, na log. Ilova eski katalog bilan ochilaveradi va kassir
    bir kun oldin o'zgargan narx bilan sotishda davom etadi.

    Yechim: yiqilish fakti Pref'da belgilanadi va internet tiklangach
    kassirga ko'rinadigan ogohlantirish chiqadi — "Yangilash" tugmasi bilan.
    Mavjud mantiq o'zgarmaydi: internet yo'q bo'lsa ilova baribir eski baza
    bilan ochilaveradi, endi bu holat shunchaki ko'rinadigan bo'ladi.
*/

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:provider/provider.dart';

import '../../app_navigation.dart';
import '../../idle_service.dart';
import '../../utils/constants/pref_keys.dart';
import '../../utils/helpers/prefs.dart';
import '../../utils/helpers/size_config.dart';
import '../../utils/l10n/app_localizations.dart';
import '../../features/home/bloc/home_bloc/home_bloc.dart';
import '../../utils/themes.dart';
import '../models/six_client_model.dart';
import '../providers/ordering_provider_4.dart';
import '../providers/update_provider.dart';

class CatalogRefreshNotice {
  CatalogRefreshNotice._();

  /// "Keyinroq" bosilgandan keyin shuncha vaqt qayta bezovta qilmaymiz.
  ///
  /// Ataylab qisqa: katalog eskiligicha qolsa kassir eski narx bilan sotishda
  /// davom etadi, shuning uchun ogohlantirish tez-tez qaytib turishi kerak.
  /// Ilova qayta ochilsa hisob noldan boshlanadi (maydon xotirada).
  static const Duration snooze = Duration(minutes: 3);

  static bool _showing = false;
  static bool _loading = false;
  static DateTime? _snoozedUntil;

  /// Hozir to'liq katalog yuklanyaptimi.
  ///
  /// Yuklash davomida ogohlantirish CHIQMASLIGI kerak: startup'da wrapper
  /// ikki marta urinadi — birinchi urinish yiqilgach bayroq qo'yiladi, lekin
  /// ikkinchisi hali ketayotgan bo'ladi. Bu bayroqsiz dialog yuklanish
  /// ekranining ustiga chiqib qolardi.
  static bool get isLoading => _loading;

  static void beginLoad() => _loading = true;

  static void endLoad() => _loading = false;

  /// Katalog to'liq va muvaffaqiyatli yuklandi.
  static Future<void> markFresh() async {
    _snoozedUntil = null;
    await Pref.setInt(
        PrefKeys.lastFullCatalogSyncAt, DateTime.now().millisecondsSinceEpoch);
    if (Pref.getBool(PrefKeys.catalogRefreshPending, false)) {
      await Pref.setBool(PrefKeys.catalogRefreshPending, false);
    }
  }

  /// To'liq yuklash yiqildi — kassirga aytish kerak.
  static Future<void> markFailed() async {
    await Pref.setBool(PrefKeys.catalogRefreshPending, true);
  }

  static bool get isPending =>
      Pref.getBool(PrefKeys.catalogRefreshPending, false);

  /// Hozir dialog ko'rsatilyaptimi (takroriy ochilishdan himoya).
  static bool get isShowing => _showing;

  /// Kontekstga bog'liq bo'lmagan barcha shartlar.
  ///
  /// Alohida ajratilgan: shu tufayli qoidalarni widget daraxtisiz,
  /// determinist testda tekshirish mumkin
  /// (qarang: test/catalog_refresh_notice_test.dart).
  static bool shouldShow({DateTime? now}) {
    final String? blockedBy = _blockedReason(now: now);
    if (blockedBy != null) {
      // Ogohlantirishning "nega chiqmadi" savoli tergovga aylanmasligi
      // uchun sabab debug konsolda ko'rinadi.
      if (kDebugMode && isPending) {
        debugPrint('🔕 Katalog ogohlantirishi ko\'rsatilmadi: $blockedBy');
      }
      return false;
    }
    return true;
  }

  /// `null` — ko'rsatish mumkin; aks holda to'sqinlik sababi.
  static String? _blockedReason({DateTime? now}) {
    if (!isPending) return 'bayroq yo\'q (katalog yangi)';
    if (_showing) return 'dialog allaqachon ochiq';
    if (_loading) return 'katalog hozir yuklanmoqda';

    // Login qilinmagan bo'lsa ko'rsatishning ma'nosi yo'q.
    final String token = Pref.getString(PrefKeys.token, '');
    if (token.isEmpty || token == 'not initialized') return 'token yo\'q';

    // PIN yoki auth sahifalari ustiga chiqmaydi — ular kassirni bloklaydi.
    if (IdleService().isOnLockPage) return 'PIN (AccessLevel) sahifasida';
    if (IdleService().isOnCriticalAuthPage) return 'auth sahifasida';

    if (_snoozedUntil != null &&
        (now ?? DateTime.now()).isBefore(_snoozedUntil!)) {
      return 'Keyinroq bosilgan (snooze $_snoozedUntil)';
    }

    return null;
  }

  /// Shart bajarilsa ogohlantirishni ko'rsatadi.
  ///
  /// Ataylab `BuildContext` qabul qilmaydi: chaqiruvchi joylarda (CatchUpSync)
  /// kontekst `MaterialApp` dan YUQORIDA bo'lishi mumkin, u yerda na
  /// `Navigator`, na `Localizations` bor. Shuning uchun navigator kaliti
  /// ishlatiladi.
  static Future<void> maybeShow() async {
    if (!shouldShow()) return;

    final BuildContext? context = AppNavigation.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      if (kDebugMode) {
        debugPrint('🔕 Katalog ogohlantirishi: navigator konteksti yo\'q');
      }
      return;
    }

    // Savatda mahsulot bo'lsa tegmaymiz: dialog modal, kassirni sotuv
    // o'rtasida to'sib qo'yardi. Bundan tashqari "Yangilash" katalogni
    // `clearAndPutItems` bilan almashtiradi — ochiq savat ustida buni
    // qilish xavfli. Tekshiruv har daqiqada takrorlanadi, shuning uchun
    // savat bo'shashi bilan dialog o'zi chiqadi.
    if (isCartBusy(context)) {
      if (kDebugMode) {
        debugPrint('🔕 Katalog ogohlantirishi: savatda mahsulot bor, kutamiz');
      }
      return;
    }

    // Internet yo'q bo'lsa ko'rsatishning ma'nosi yo'q — "Yangilash" baribir
    // yiqilardi. Tekshiruv faqat bayroq qo'yilgan holatda (ya'ni kamdan-kam)
    // bajariladi, shuning uchun odatdagi ishlashga yuk qo'shmaydi.
    if (!await InternetConnectionChecker().hasConnection) {
      if (kDebugMode) {
        debugPrint('🔕 Katalog ogohlantirishi: internet yo\'q, kutamiz');
      }
      return;
    }

    if (!context.mounted) return;

    _showing = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const CatalogStaleDialog(),
      );
    } finally {
      _showing = false;
    }
  }

  /// Biror mijoz savatida mahsulot bormi (6 ta savat ham tekshiriladi).
  ///
  /// Provider daraxtda bo'lmasa `false` — ogohlantirish shu sabab
  /// yo'qolib ketmasligi kerak.
  static bool isCartBusy(BuildContext context) {
    try {
      final OrderingProvider4 provider =
          Provider.of<OrderingProvider4>(context, listen: false);
      if (provider.getCurrentClient.orderedProducts.isNotEmpty) return true;
      for (final SixClientModel4 client in provider.getSixClient4List) {
        if (client.orderedProducts.isNotEmpty) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void snoozeNow() => _snoozedUntil = DateTime.now().add(snooze);

  /// Faqat test uchun: statik holatni tozalaydi.
  @visibleForTesting
  static void resetForTest() {
    _showing = false;
    _loading = false;
    _snoozedUntil = null;
  }
}

class CatalogStaleDialog extends StatefulWidget {
  const CatalogStaleDialog({super.key});

  @override
  State<CatalogStaleDialog> createState() => _CatalogStaleDialogState();
}

class _CatalogStaleDialogState extends State<CatalogStaleDialog> {
  bool _loading = false;
  String? _error;
  bool _errorFallback = false;

  /// To'liq yuklashdan keyin bosh ekran va savat ro'yxatini yangilaydi.
  /// Ikkalasi ham ixtiyoriy: daraxtda bo'lmasa dialog bundan yiqilmasligi
  /// kerak.
  void _refreshUi() {
    try {
      context.read<HomeBloc>().add(HomeSyncEvent());
    } catch (_) {}
    try {
      Provider.of<OrderingProvider4>(context, listen: false).pressAllPath();
    } catch (_) {}
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final String? error =
        await Provider.of<UpdateProvider>(context, listen: false)
            .fullUpdateItems();

    if (!mounted) return;

    if (error == null) {
      // Katalog almashdi — bosh ekrandagi ro'yxat ham yangilanishi kerak,
      // aks holda kassir eski narxni ko'rib turaveradi.
      _refreshUi();
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _loading = false;
      // Ba'zi yo'llarda xato matni bo'sh satr bo'lib keladi — bunday holda
      // kassirga bo'sh joy emas, tushunarli matn ko'rsatiladi.
      _error = error.trim().isEmpty ? null : error;
      _errorFallback = error.trim().isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 6),
      child: Container(
        width: SizeConfig.h * 45,
        padding: EdgeInsets.all(SizeConfig.h * 3),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(SizeConfig.h * 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orangeAccent,
              size: SizeConfig.v * 8,
            ),
            SizedBox(height: SizeConfig.v * 2),
            Text(
              loc.katalog_yangilanmagan_sarlavha,
              textAlign: TextAlign.center,
              style: MyThemes.txtStyle(
                color: Theme.of(context).canvasColor,
                fontSize: 3.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SizeConfig.v * 1.5),
            Text(
              loc.katalog_yangilanmagan_matn,
              textAlign: TextAlign.center,
              style: MyThemes.txtStyle(
                color: Theme.of(context).canvasColor,
                fontSize: 2.4,
              ),
            ),
            if (_error != null || _errorFallback) ...[
              SizedBox(height: SizeConfig.v * 1.5),
              Text(
                _error ?? loc.yangilanish_amalga_oshirilmadi,
                textAlign: TextAlign.center,
                style: MyThemes.txtStyle(
                  color: Colors.redAccent,
                  fontSize: 2.2,
                ),
              ),
            ],
            SizedBox(height: SizeConfig.v * 3),
            if (_loading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.v * 1.5),
                child: const CircularProgressIndicator(),
              )
            else
              // Ikkala tugma bir xil balandlikda bo'lishi uchun balandlik
              // aniq beriladi: aks holda TextButton va ElevatedButton'ning
              // ichki o'lchamlari har xil bo'lib, hover paytida yonidagi
              // tugma "kichrayib" ko'rinadi.
              SizedBox(
                height: SizeConfig.v * 7,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(SizeConfig.h * 1.5),
                          ),
                        ),
                        onPressed: () {
                          CatalogRefreshNotice.snoozeNow();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          loc.keyinroq,
                          style: MyThemes.txtStyle(
                            color: Theme.of(context).canvasColor,
                            fontSize: 2.4,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: SizeConfig.h * 1.5),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(SizeConfig.h * 1.5),
                          ),
                        ),
                        onPressed: _refresh,
                        child: Text(
                          loc.yangilash,
                          style: MyThemes.txtStyle(
                            color: Colors.white,
                            fontSize: 2.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
