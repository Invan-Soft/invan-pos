import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:invan2/changes/domain/receipt/refund_preflight.dart';
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/models/receipts_get_model.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/health/backend_health.dart';
import 'package:invan2/changes/services/local_selling_service.dart';
import 'package:invan2/changes/services/receipt/refund_upload_queue.dart';
import 'package:invan2/changes/services/search_receipt_sevice.dart';
import 'package:invan2/features/checks/return_page/right/return_dialog/return_dialog.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/utils/util_functions.dart';
import 'package:invan2/utils/utils.dart';

import '../../../../../../changes/services/api.dart';
import '../../../../../../utils/l10n/app_localizations.dart';

part 'return_event.dart';

part 'return_state.dart';

class ReturnBloc extends Bloc<ReturnEvent, ReturnState> {
  /// [deps] — tashqi bog'liqliklar (internet, server holati, fiskal modul,
  /// ObjectBox, server API). Ishlab chiqarishda `null` qoldiriladi; testda
  /// soxtasi beriladi — shunda vozvrat oqimining tartibi va holatlari
  /// tarmoqsiz, fiskal modulsiz va ObjectBox'siz tekshiriladi.
  ReturnBloc({ReturnBlocDeps? deps})
      : _deps = deps ?? ReturnBlocDeps.production(),
        super(ReturnInitial()) {
    on<ReturnReturnEvent>(_return);
  }

  final ReturnBlocDeps _deps;

  /// Vozvrat ketayotgan paytda ikkinchi hodisa (ikki marta bosish, eskirgan
  /// sahifa) qabul qilinmaydi — aks holda ikkita fiskal vozvrat chiqardi.
  bool _running = false;

  /// Kassir "Internet tekshirilmoqda" paytida "Bekor qilish" bosdi.
  bool _cancelRequested = false;

  /// "Bekor qilish": fiskal chek hali boshlanmagan bo'lsa vozvrat to'xtaydi.
  /// Ilgari oyna yopilar, vozvrat esa orqa fonda davom etardi — kassir bekor
  /// qildim deb chekka qayta kirib ikkinchi vozvrat qilardi.
  void cancelBeforeStart() => _cancelRequested = true;

  Future<void> _return(
      ReturnReturnEvent event, Emitter<ReturnState> emit) async {
    if (_running) return;
    _running = true;
    _cancelRequested = false;
    try {
      await _doReturn(event, emit);
    } finally {
      _running = false;
    }
  }

  Future<void> _doReturn(
      ReturnReturnEvent event, Emitter<ReturnState> emit) async {
    Log.d(event, name: 'return_bloc');

    final bool ofd = _deps.withOfd();

    final newReceiptModel41 = ReceiptModel4(
      supplierId: event.receiptModel4.supplierId,
      dateTimeOFD: event.receiptModel4.dateTimeOFD,
      fiscalSign: event.receiptModel4.fiscalSign,
      receiptSeq: event.receiptModel4.receiptSeq,
      discountID: event.receiptModel4.discountID,
      discountVat: event.receiptModel4.discountVat,
      terminalId: event.receiptModel4.terminalId,
      newid: event.receiptModel4.newid,
      rejected: event.receiptModel4.rejected,
      clientPhone: event.clientNumber,
      cashierId: event.receiptModel4.cashierId,
      cashierName: event.receiptModel4.cashierName,
      date: DateTime.now().millisecondsSinceEpoch,
      isRefund: true,
      externalId: event.receiptModel4.externalId,
      totalPrice: _getRightTotalPrice(event.rightList),
      uploaded: false,
      clientName: event.receiptModel4.clientName,
      clientId: event.receiptModel4.clientId,
      cashback: 0,
      comment: "Refund made from ${event.receiptModel4.externalId}",
      sdacha: 0,
      createdDate: event.receiptModel4.createdDate,
      returnForCheck: event.receiptModel4.returnForCheck,
      posName: event.receiptModel4.posName,
      refundInfo: event.receiptModel4.refundInfo,
      commissionTIN: event.receiptModel4.commissionTIN,
      isDonate: Pref.getBool('donate', false),
      cashboxId: event.receiptModel4.cashboxId,
      orderId: event.receiptModel4.orderId,
      orderType: event.receiptModel4.orderType,
      shopId: event.receiptModel4.shopId,
      userId: event.receiptModel4.userId,
      url: event.receiptModel4.url,
      cardType: 2,
      cardNumber: event.receiptModel4.cardNumber ?? '',
      pptId: event.receiptModel4.pptId ?? '',
    );

    newReceiptModel41.payment.clear();
    newReceiptModel41.soldItemList.clear();

    final double refundTotal = _getRightTotalPrice(event.rightList);
    final String cashId = Pref.getString(PrefKeys.cashId, '');

    // Vozvrat: to'lov turidan qat'iy nazar hammasi CASH orqali qaytariladi
    newReceiptModel41.payment.add(ReceiptModelPaymentType4(
      name: "CASH",
      value: refundTotal,
      payId: cashId,
    ));

    // Eski CASH/CARD ajratish logikasi (qachondir kerak bo'lsa):
    // final String cardId = Pref.getString(PrefKeys.cardId, '');
    // final String clickId = Pref.getString(PrefKeys.clickId, '');
    // final String uzumId = Pref.getString(PrefKeys.uzumId, '');
    // final String paymeId = Pref.getString(PrefKeys.paymeId, '');
    // double origCash = 0;
    // double origOther = 0;
    // String cashPayId = cashId;
    // String cardPayId = cardId;
    // for (final pay in event.receiptModel4.payment) {
    //   final n = pay.name.toUpperCase().trim();
    //   final id = pay.payId.trim();
    //   if (n == 'CASH' || (id.isNotEmpty && id == cashId)) {
    //     origCash += pay.value;
    //     if (id.isNotEmpty) cashPayId = id;
    //   } else {
    //     origOther += pay.value;
    //     if (id.isNotEmpty && id != clickId && id != uzumId && id != paymeId) {
    //       cardPayId = id;
    //     }
    //   }
    // }
    // final double srcTotal = origCash + origOther;
    // if (srcTotal <= 0) {
    //   newReceiptModel41.payment.add(ReceiptModelPaymentType4(name: "CARD", value: refundTotal, payId: cardPayId));
    // } else {
    //   double remaining = refundTotal;
    //   if (origCash > 0) {
    //     final double cashRefund = ((origCash / srcTotal) * refundTotal).roundToDouble();
    //     remaining -= cashRefund;
    //     if (cashRefund > 0) newReceiptModel41.payment.add(ReceiptModelPaymentType4(name: "CASH", value: cashRefund, payId: cashPayId));
    //   }
    //   if (remaining > 0) newReceiptModel41.payment.add(ReceiptModelPaymentType4(name: "CARD", value: remaining, payId: cardPayId));
    // }

    newReceiptModel41.soldItemList.addAll(event.rightList);

    emit(ReturnLoadingState(message: ReturnMessage.internet));

    // Internet va SERVER holati alohida tekshiriladi.
    //
    // Internet yo'q bo'lsa qaytarishni umuman bajarib bo'lmaydi: fiskal chek
    // OFD (soliq) ga yozilishi kerak, u esa internetsiz ishlamaydi.
    //
    // Internet BOR, lekin BIZNING server javob bermayotgan bo'lsa —
    // qaytarish lokal bajariladi (fiskal chek chiqadi, ObjectBox'ga
    // yoziladi), serverga yuborish esa `RefundUploadQueue` navbatida qoladi.
    final bool internet = await _deps.hasInternet();
    final bool serverUp = internet && _deps.isServerUp();
    if (event.isRetry) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (_cancelRequested) {
      // Hali hech narsa (na fiskal, na lokal, na server) o'zgarmagan.
      emit(ReturnInitial());
      return;
    }

    if (!internet) {
      emit(ReturnNoInternetState());
      return;
    }

    emit(ReturnLoadingState(message: ReturnMessage.returnig));

    // Fiskaldan OLDIN: sahifa eskirmaganmi va serverda qoldiq yetarlimi.
    final String? blocked = await _preflight(event, serverUp: serverUp);
    if (blocked != null) {
      emit(ReturnBlockedState(message: blocked));
      return;
    }

    // Yangi check raqami generate qilib APIga ham, local DBga ham bir xil
    // yuboramiz. Raqam lokal hisoblagichdan olinadi — serverga bog'liq emas.
    newReceiptModel41.externalId = await _deps.nextCheckNo();
    newReceiptModel41.uploaded = false;

    // TARTIB: 1) fiskal → 2) ObjectBox + chek chop → 3) server.
    //
    // Ilgari server fiskaldan OLDIN chaqirilardi va serverga vozvrat
    // modelidagi `url` — ya'ni asl SOTUV chekining QR URL'i ketardi.
    // Endi server fiskal javobidan keyin chaqiriladi, shuning uchun
    // `refund_for_pos_new` ga vozvratning o'z `QRCodeURL`i boradi. Oflayn
    // navbat (`RefundUploadQueue`) allaqachon shu tartibda ishlaydi.
    //
    // Server "bu chek allaqachon qaytarilgan" deb rad etishi lokalda
    // to'silgan: return_page qoldiqni shu kassadagi va admin paneldagi
    // vozvratlarni hisobga olib chiqaradi, qoldiq 0 bo'lsa mahsulot
    // ro'yxatga chiqmaydi. Shunga qaramay server rad etsa — chek `rejected`
    // belgilanadi va kassir cheklar ekranidan qo'lda yuboradi (oflayn
    // navbatdagi bilan bir xil qoida).
    final _FiscalOutcome fiscal = await _fiscalRefund(
      newReceiptModel41,
      ofd: ofd,
      loc: event.loc,
    );

    if (fiscal.error != null) {
      // Fiskal vozvrat bo'lmadi — hali hech narsa (na lokal, na server)
      // o'zgarmagan, shuning uchun hech narsa saqlanmaydi. Kassir "Qayta
      // urinish" bossa oqim boshidan toza boshlanadi.
      //
      // Eski tartibda (server birinchi) bu holatda chek baribir lokalga
      // yozilardi, chunki server allaqachon qabul qilgan edi — endi bunga
      // hojat yo'q; aksincha, saqlash qoldiqni ikki marta kamaytirardi
      // (retry'da ikkinchi yozuv).
      emit(ReturnFailedState(error: fiscal.error!));
      return;
    }

    await _deps.saveLocal(newReceiptModel41, fiscal.response);

    String? warning;
    if (serverUp) {
      final RefundUploadResult upload =
          await _deps.uploadToServer(newReceiptModel41);
      if (upload.status == RefundUploadStatus.rejected) {
        warning = event.loc.qaytarish_server_rad_etdi(upload.error ?? '');
      }
    }
    // serverUp == false yoki `pending` → chek navbatda, server tiklangach
    // avtomatik yuboriladi.

    emit(ReturnSuccedState(warning: warning));
  }

  /// Vozvratni boshlash mumkinmi. `null` — mumkin; aks holda kassirga
  /// ko'rsatiladigan sabab. Bu nuqtada hali hech narsa o'zgarmagan.
  ///
  /// 1. Sahifa ochilgandan keyin shu chek bo'yicha lokal vozvrat saqlangan —
  ///    sahifadagi qoldiq eskirgan (ustma-ust ochilgan ikkinchi sahifa).
  /// 2. Server tirik bo'lsa chek qayta so'raladi: so'ralgan miqdor server
  ///    qoldig'idan (minus serverga yetmagan lokal vozvratlar) oshmasligi
  ///    kerak — boshqa kassa yoki adminkada qaytarilgan holat.
  ///
  /// Server javob bermasa tekshiruv o'tkazib yuboriladi: oflayn vozvrat
  /// (`RefundUploadQueue`) ishlashda davom etadi.
  Future<String?> _preflight(
    ReturnReturnEvent event, {
    required bool serverUp,
  }) async {
    final String original = event.receiptModel4.returnForCheck;
    final List<ReceiptModel4> localRefunds =
        original.isEmpty ? const [] : _deps.localRefundsOf(original);

    if (RefundPreflight.isPageStale(
      pageOpenedAt: event.pageOpenedAt,
      localRefunds: localRefunds,
    )) {
      return event.loc.vozvrat_sahifa_eskirgan;
    }

    final String orderId = event.receiptModel4.orderId;
    if (!serverUp || orderId.isEmpty) return null;
    final Map<String, double>? remaining = await _deps.serverRemaining(orderId);
    if (remaining == null) return null;

    final ReceiptModelSoldItem4? over = RefundPreflight.firstOverdrawn(
      requested: event.rightList,
      serverRemaining: remaining,
      localRefunds: localRefunds,
    );
    if (over == null) return null;
    return event.loc.vozvrat_qoldiqdan_kop(over.productName);
  }

  /// Fiskal (OFD) vozvrat. Muvaffaqiyatda modelga vozvratning o'z
  /// `url`/`refundInfo`/fiskal maydonlari yoziladi. Fiskal kerak bo'lmasa yoki
  /// xato bersa — asl sotuvdan nusxalangan fiskal maydonlar TOZALANADI,
  /// aks holda qayta chop etishda va serverda sotuv chekining QR'i chiqadi.
  Future<_FiscalOutcome> _fiscalRefund(
    ReceiptModel4 refund, {
    required bool ofd,
    required AppLocalizations loc,
  }) async {
    if (!ofd || !_wasRegisteredOnOfd(refund)) {
      // OFDda sotuv yo'q — fiskal refund shart emas
      _clearFiscalFields(refund);
      return const _FiscalOutcome();
    }

    try {
      final CommunicatorRESPONSE response =
          await _deps.fiscalSell(loc, refund);
      final Info? info = response.info;
      if ((response.error ?? true) || info == null) {
        _clearFiscalFields(refund);
        return _FiscalOutcome(error: response.paycheck.toString());
      }
      refund.refundInfo = jsonEncode(info.toJson());
      refund.url = info.qrCodeUrl ?? '';
      refund.terminalId = info.terminalId;
      refund.receiptSeq = int.tryParse(info.receiptSeq ?? "0") ?? 0;
      refund.dateTimeOFD = info.dateTime ?? "0";
      refund.fiscalSign = info.fiscalSign;
      return _FiscalOutcome(response: response);
    } catch (err) {
      _clearFiscalFields(refund);
      return _FiscalOutcome(error: err.toString());
    }
  }

  /// Sotuv OFDga ro'yxatdan o'tganmi: URL va fiskal ma'lumotlar
  /// (terminalId, fiscalSign, dateTimeOFD) bo'lishi kerak.
  static bool _wasRegisteredOnOfd(ReceiptModel4 r) {
    final urlValue = r.url;
    final terminalId = r.terminalId;
    final fiscalSign = r.fiscalSign;
    final dateTimeOFD = r.dateTimeOFD;
    return (urlValue != null && urlValue.isNotEmpty) &&
        (terminalId != null && terminalId.isNotEmpty) &&
        (fiscalSign != null && fiscalSign.isNotEmpty) &&
        (dateTimeOFD != null && dateTimeOFD.isNotEmpty && dateTimeOFD != "0");
  }

  static void _clearFiscalFields(ReceiptModel4 r) {
    r.url = '';
    r.refundInfo = null;
    r.terminalId = null;
    r.receiptSeq = null;
    r.dateTimeOFD = null;
    r.fiscalSign = null;
  }

  double _getRightTotalPrice(List<ReceiptModelSoldItem4> v) {
    double t = 0;
    for (var element in v) {
      t += UtilFunctions.roundToNearest(element.price * element.value);
    }

    return t;
  }
}

/// Fiskal vozvrat natijasi. [response] — muvaffaqiyatli fiskal javob (chek
/// chop etish uchun), [error] — fiskal xato matni. Ikkalasi ham `null` bo'lsa
/// fiskal kerak bo'lmagan (OFDsiz sotuv).
class _FiscalOutcome {
  final CommunicatorRESPONSE? response;
  final String? error;

  const _FiscalOutcome({this.response, this.error});
}

/// [ReturnBloc] tashqi bog'liqliklari. Har biri sof funksiya: ishlab
/// chiqarishda [ReturnBlocDeps.production] statik xizmatlarga ulaydi, testda
/// soxtalari beriladi (qarang: test/return_bloc_flow_test.dart).
class ReturnBlocDeps {
  final Future<bool> Function() hasInternet;
  final bool Function() isServerUp;
  final bool Function() withOfd;
  final Future<String> Function() nextCheckNo;

  /// Fiskal modulga vozvrat cheki (`LocalService.sell`).
  final Future<CommunicatorRESPONSE> Function(
      AppLocalizations loc, ReceiptModel4 refund) fiscalSell;

  /// ObjectBox'ga yozish + chek chop etish (`ReceiptSingleton4.toOBJECTBOX`).
  final Future<void> Function(ReceiptModel4 refund, CommunicatorRESPONSE? response)
      saveLocal;

  /// Serverga yuborish (`RefundUploadQueue.uploadOne`).
  final Future<RefundUploadResult> Function(ReceiptModel4 refund) uploadToServer;

  /// Shu sotuv cheki (`externalId`) bo'yicha ObjectBox'dagi vozvratlar.
  final List<ReceiptModel4> Function(String originalExternalId) localRefundsOf;

  /// Serverdagi qoldiq: `order item id → dona`. `null` — server javob
  /// bermadi yoki chek topilmadi (tekshiruv o'tkazib yuboriladi).
  final Future<Map<String, double>?> Function(String orderId) serverRemaining;

  const ReturnBlocDeps({
    required this.hasInternet,
    required this.isServerUp,
    required this.withOfd,
    required this.nextCheckNo,
    required this.fiscalSell,
    required this.saveLocal,
    required this.uploadToServer,
    this.localRefundsOf = _noLocalRefunds,
    this.serverRemaining = _unknownRemaining,
  });

  static List<ReceiptModel4> _noLocalRefunds(String _) => const [];

  static Future<Map<String, double>?> _unknownRemaining(String _) async => null;

  static List<ReceiptModel4> _localRefundsFromBox(String originalExternalId) {
    try {
      return MyObjectbox.saleStore
          .box<ReceiptModel4>()
          .getAll()
          .where((r) => r.isRefund && r.returnForCheck == originalExternalId)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<Map<String, double>?> _remainingFromServer(
      String orderId) async {
    try {
      final HttpResult res = await SearchReceiptService.getReceiptss(orderId);
      if (!res.isSuccess) return null;
      final data = json.decode(utf8.decode(res.reBytes))['data'];
      if (data is! List) return null;
      for (final e in data) {
        final GlobalReceipt receipt = GlobalReceipt.fromJson(e);
        if (receipt.id != orderId) continue;
        return {
          for (final it in receipt.items ?? <ItemsGTR>[])
            if ((it.id ?? '').isNotEmpty && it.value != null)
              it.id!: (it.value! - (it.refundAmount ?? 0)).toDouble(),
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  factory ReturnBlocDeps.production() => ReturnBlocDeps(
        hasInternet: () => InternetConnectionChecker().hasConnection,
        isServerUp: () => BackendHealth.isUp,
        withOfd: () => Pref.getBool(PrefKeys.withOFD, false),
        nextCheckNo: ReceiptSingleton4.getCheckNo,
        fiscalSell: (loc, refund) =>
            LocalService.sell(loc: loc, receiptData: refund),
        saveLocal: (refund, response) => ReceiptSingleton4.toOBJECTBOX(
          refund,
          communicatorRECEIPT: response,
        ),
        uploadToServer: (refund) =>
            RefundUploadQueue.uploadOne(refund, reason: 'return_bloc'),
        localRefundsOf: _localRefundsFromBox,
        serverRemaining: _remainingFromServer,
      );
}
