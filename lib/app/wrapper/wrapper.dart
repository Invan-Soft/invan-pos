import 'package:invan2/changes/bloc/network/network_bloc.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/widgets/alice_pincode.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:invan2/app/wrapper/bloc/wrapper_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/changes/components/logo_widget.dart';
import 'package:invan2/features/authentication/view/phone_number_page.dart';
import 'package:invan2/features/checks/features/checks_app_bar/bloc/usr_bloc.dart';
import 'package:invan2/features/checks/features/checks_list/bloc/check_f_bloc.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import '../../objectbox.g.dart';
import 'package:invan2/features/lock/access_level/view/access_level_page.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/auth_backup.dart';
import 'package:invan2/utils/helpers/auth_reset.dart';
import 'package:invan2/changes/services/catalog_refresh_notice.dart';
import 'package:invan2/changes/services/startup_progress.dart';
import 'package:invan2/changes/services/discount_auto_sync_service.dart';
import 'package:invan2/changes/services/shift/shift_sync_queue.dart';
import 'package:invan2/utils/helpers/network_error_helper.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';
import 'package:invan2/utils/themes.dart';
import 'package:provider/provider.dart';
import '../../changes/providers/update_provider.dart';
import '../../idle_service.dart';

/// Debug rejimida ham ilova ochilganda katalog to'liq yangilanadimi.
///
/// Odatda `false`: debug'da har restartda 43 MB katalog tortilishi ishlab
/// chiqishni sekinlashtiradi. `true` qilinsa "internet yo'q holatda ochilish"
/// stsenariysini debug'da sinab ko'rish mumkin bo'ladi.
const bool kDebugStartupCatalogSync = false;

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  late CheckFBloc checkFBloc;
  late bool internet;
  late WrapperBloc wrapperBloc;
  late UsrBloc usrBloc;
  late NetworkBloc networkBloc;
  List<ReceiptModel4> receipts = [];
  StreamSubscription? subscription;

  StreamSubscription? networkSubscription;
  late Stream<Query<ReceiptModel4>> stream;
  late bool called;

  @override
  void initState() {
    internet = true;
    called = false;

    networkBloc = BlocProvider.of(context);
    usrBloc = BlocProvider.of(context);
    checkFBloc = BlocProvider.of(context);
    stream = MyObjectbox.saleStore.box<ReceiptModel4>().query().watch();
    subscription = stream.listen((event) async {
      List<ReceiptModel4> v = event.find().reversed.toList();
      _dataChanged(v);
    });
    networkSubscription = InternetConnectionChecker()
        .onStatusChange
        .listen((InternetConnectionStatus status) {
      internet = status == InternetConnectionStatus.connected;
      networkBloc.add(NetworkChangedEvent(status: internet));
      if (internet) {
        usrBloc.add(UsrSendEvent("Wrapper Network Listener", null));
      }
    });
    /// Kompaniya diskontlarini har 10 daqiqada fonda jimgina yangilab turadi
    /// (WS o'tkazib yuborgan diskontlarni qoplash uchun). Login bo'lmaguncha
    /// har tsikl ichidagi token/shop guard tufayli no-op — shuning uchun
    /// autentifikatsiyadan qat'i nazar shu yerda ishga tushirish xavfsiz.
    DiscountAutoSyncService.instance.start();

    Timer(const Duration(milliseconds: 1000), () async {
      try {
        /// dev↔pro almashgan bo'lsa saqlangan token boshqa muhitniki —
        /// u bilan qolinsa ilova "kirgan" ko'rinadi-yu har so'rov 401 bo'ladi.
        /// Shuning uchun tokenlarni tozalab, login sahifasiga qaytaramiz.
        if (await AuthReset.resetIfApiEnvChanged()) {
          IdleService().disable(); // auth sahifalarida idle redirect ishlamasin
          AppNavigation.pushAndRemoveUntil(const PhoneNumberPage());
          return;
        }

        String token = Pref.getString(PrefKeys.token, '');
        if (token.isEmpty) {
          token = await AuthBackup.read();
          if (token.isNotEmpty) {
            await Pref.setString(PrefKeys.token, token);
            await Pref.setBool(PrefKeys.authenticationBool, true);
          }
        }
        if (!Pref.getBool(PrefKeys.authenticationBool, false) &&
            token.isEmpty) {
          IdleService().disable(); // auth sahifalarida idle redirect ishlamasin
          AppNavigation.pushAndRemoveUntil(const PhoneNumberPage());
        } else {
          /// Ilova ochilganda ketmagan (rejected=false) cheklarni fon rejimida
          /// yuborishni boshlaymiz. Internet tekshiruvi UsrBloc._send ichida
          /// bajariladi, shuning uchun internet bo'lmasa xavfsiz to'xtaydi.
          _flushUnsentReceiptsOnStartup();

          /// Serverga yetmagan smena ochish/yopish navbati.
          ///
          /// Nima uchun aynan startup'da: `NetworkBloc` faqat internet holati
          /// O'ZGARGANDA emit qiladi (`onStatusChange`). Ilova internet
          /// allaqachon ulangan holda ochilsa hech qanday trigger bo'lmaydi va
          /// navbat abadiy qolib ketadi. 2026-08-13 da smena yopilishi aynan
          /// shu sabab serverga ketmagan: ilova 16:25:55 da internet bor holda
          /// qayta ishga tushgan va navbatni tekshiradigan hech kim bo'lmagan.
          unawaited(ShiftSyncQueue.flush(reason: 'startup'));

          // Startup yuklashi davomida "baza yangilanmagan" dialogi
          // chiqmasligi kerak — u yuklanish ekranining ustiga tushib qolardi.
          CatalogRefreshNotice.beginLoad();
          if (!kDebugMode || kDebugStartupCatalogSync) {
            /// Full employees update ///
            ///
            StartupProgress.set(StartupPhase.employees);
            String? employeeResult =
                await Provider.of<UpdateProvider>(context, listen: false)
                    .fullUpdateEmployee();
            if (employeeResult != null) {
              await Provider.of<UpdateProvider>(context, listen: false)
                  .fullUpdateEmployee();
            }
            /// Full product update ///
            ///
            String? result =
                await Provider.of<UpdateProvider>(context, listen: false)
                    .fullUpdateItems();
            if (result != null) {
              result = await Provider.of<UpdateProvider>(context, listen: false)
                  .fullUpdateItems();
            }
          }

          CatalogRefreshNotice.endLoad();
          // Shkala 100% ga to'lib, keyin sahifa almashadi — kassir
          // "yarmida uzilib qoldi" degan taassurot olmasligi kerak.
          StartupProgress.done();
          AppNavigation.pushAndRemoveUntil(const AccessLevelPage());
          return;
        }
      } catch (e) {
        CatalogRefreshNotice.endLoad();
        StartupProgress.reset();
        if (mounted) {
          final loc = AppLocalizations.of(context);
          final isUz = loc != null && loc.ha.toLowerCase() == 'ha';
          await showErrorDialog(
              context,
              "${isUz ? 'Xatolik yuz berdi' : 'Произошла ошибка'}:\n"
              "${NetworkErrorHelper.friendlyMessage(e, isUz: isUz)}");
        }
      }
    });
    if (Pref.getBool(PrefKeys.isFirstTime, true)) {
      usrBloc.add(UsrSendSpecialEvent("Checks appBar", usrBloc.unsents));
    }
    super.initState();
  }

  /// Ilova ochilganda ObjectBox'da qolib ketgan (serverga ketmagan, lekin
  /// server rad etmagan) cheklarni fon rejimida yuborishni boshlaydi.
  ///
  /// Nima uchun kerak: startup'da ObjectBox `.watch()` (triggerImmediately=false)
  /// eski ma'lumot uchun emit qilmaydi va network listener ham faqat internet
  /// statusi o'zgarsa ishlaydi. Shu sabab internet allaqachon ulangan holda
  /// ilova ochilsa, ketmagan cheklarni avtomatik yuboradigan trigger yo'q edi.
  ///
  /// Faqat `rejected == false` cheklar olinadi — ular internet yo'q edi yoki
  /// urinilmagan cheklar bo'lib, qayta yuborishda odatda muvaffaqiyatli ketadi.
  /// `rejected == true` (server rad etgan) cheklar bu yerda tegilmaydi.
  /// Internet tekshiruvi UsrBloc._send ichida bo'lgani uchun internet bo'lmasa
  /// xavfsiz to'xtaydi.
  void _flushUnsentReceiptsOnStartup() {
    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    final query = box
        .query(ReceiptModel4_.uploaded.equals(false) &
            ReceiptModel4_.rejected.equals(false))
        .build();
    final int pending = query.count();
    query.close();

    if (pending > 0) {
      usrBloc.add(UsrSendEvent("Wrapper Startup", pending));
    }
  }

  _dataChanged(List<ReceiptModel4> v) {
    receipts = v;

    int unsents = v.where((e) => !e.uploaded).toList().length;

    checkFBloc.add(CheckFDateChangedEvent(v, unsents));

    if (unsents > 0) {
      usrBloc.add(UsrSendEvent("Wrapper ObjectBox Listener", unsents));
    }
  }

  Future<void> showErrorDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 6),
          child: Container(
            width: SizeConfig.h * 40,
            padding: EdgeInsets.all(SizeConfig.h * 3),
            decoration: BoxDecoration(
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(SizeConfig.h * 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: MyThemes.txtStyle(
                    color: Colors.redAccent,
                    fontSize: 4.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: SizeConfig.v * 3),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SizeConfig.h * 1.5),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: SizeConfig.v * 1.8),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "OK",
                      style: MyThemes.txtStyle(
                        color: Colors.white,
                        fontSize: 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context, builder: (context) => AlicePincodePage());
        },
        child: Icon(
          Icons.http_outlined,
          color: Colors.white,
          size: 30,
        ),
      ),
      body: Center(
        child: Stack(
          children: [
            Container(
              alignment: Alignment.center,
              height: double.infinity,
              width: double.infinity,
              color: MyThemes.darkPrimaryColor,
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 2.5,
                child: Hero(
                  tag: "logo_wrapper",
                  child: LogoInvanWidget(
                    color: MyThemes.textWhiteColor,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height / 20),
                child: ValueListenableBuilder<StartupProgressState>(
                  valueListenable: StartupProgress.notifier,
                  builder: (context, progress, _) =>
                      _StartupProgressView(progress: progress),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yuklanish ekranidagi bosqich matni va foiz.
///
/// Foiz FAQAT server `Content-Length` bergan bo'lsa chiziladi — aks holda
/// oddiy aylanuvchi indikator qoladi. Ya'ni kassirga hech qachon o'ylab
/// topilgan raqam ko'rsatilmaydi.
class _StartupProgressView extends StatelessWidget {
  const _StartupProgressView({required this.progress});

  final StartupProgressState progress;

  String? _label(AppLocalizations loc) {
    switch (progress.phase) {
      case StartupPhase.employees:
        return loc.yuklanmoqda_xodimlar;
      case StartupPhase.packageCode:
        return loc.yuklanmoqda_mxik;
      case StartupPhase.productsRequest:
      case StartupPhase.productsDownload:
        return loc.yuklanmoqda_mahsulotlar;
      case StartupPhase.productsSaving:
        return loc.yuklanmoqda_saqlanmoqda;
      case StartupPhase.done:
        return loc.yuklanmoqda_tayyor;
      case StartupPhase.idle:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? loc = AppLocalizations.of(context);
    final String? label = loc == null ? null : _label(loc);
    final int? percent = progress.isActive ? progress.percent : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(.9),
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (percent != null) ...[
          SizedBox(height: MediaQuery.of(context).size.height / 55),
          SizedBox(
            width: MediaQuery.of(context).size.width / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 12,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height / 70),
          Text(
            '$percent%',
            style: TextStyle(
              color: Colors.white.withOpacity(.8),
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
