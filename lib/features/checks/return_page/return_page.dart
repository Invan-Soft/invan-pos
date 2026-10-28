import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/domain/receipt/refund_mark_split.dart';
import 'package:invan2/changes/services/api.dart';
import 'package:invan2/features/get_products/singletons/checks_singleton.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:provider/provider.dart';
import '../../../widgets/alice_pincode.dart';
import 'return_page_appbar/return_page_appbar.dart';
import 'package:invan2/utils/utils.dart';
import '../../../changes/providers/return_page_provider.dart';
import 'return_page_card.dart';
import 'left/left.dart';
import 'right/right.dart';

class ReturnPage extends StatelessWidget {
  const ReturnPage({
    super.key,
    required this.receiptModel4,
    this.serverRefundedMarks = const {},
  });

  final ReceiptModel4 receiptModel4;

  /// Serverda qaytarilgan KM'lar (`ReUpdateBloc.serverRefundedMarks`).
  final Set<String> serverRefundedMarks;

  @override
  Widget build(BuildContext context) {
    // Vozvrat sahifasida skan sotuv savatiga tushmasin: uy sahifasining
    // VisibilityDetector'i cheklar sahifasiga o'tishda kechikib `home`
    // qo'yib yuborishi mumkin (cheklar sahifasi `other` qo'ygandan keyin).
    BlocProvider.of<BlBloc>(context, listen: false).add(BlStatusChangedEvent(
      status: BLStatus.other,
      where: 'return_page.dart build',
    ));
    final data = _copyWith(receiptModel4, serverRefundedMarks);
    return ChangeNotifierProvider(
      create: (_) => ReturnPageProviderr(
        receiptModel4: data.receipt,
        refundedMarks: data.refundedMarks,
      ),
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: Pref.getBool(PrefKeys.isDevAlice, false)
              ? FloatingActionButton(
                  heroTag: null,
                  backgroundColor: Theme.of(context).primaryColor,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlicePincodePage(),
                    );
                  },
                  child: const Icon(
                    Icons.http_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                )
              : const SizedBox(),
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            elevation: 2,
            shadowColor: Colors.grey,
            leadingWidth: 0.0,
            automaticallyImplyLeading: false,
            toolbarHeight: SizeConfig.v * 9.5,
            backgroundColor: Theme.of(context).colorScheme.background,
            title: const ReturnPageAppbar(),
          ),
          body: Center(
            child: Row(
              children: [
                const ReturnPageCard(child: Left()),
                SizedBox(
                  width: 30,
                  child: Icon(
                    Icons.arrow_right_alt,
                    color: Theme.of(context).canvasColor,
                    size: SizeConfig.v * 5,
                  ),
                ),
                const ReturnPageCard(
                  child: Right(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shu checkga tegishli oldingi refundlarda qaytarilgan miqdorlar
/// (productId → jami qty, dona hisobida), shundan serverga hali yetmaganlari
/// (`uploaded == false`) va ketgan KM'lar (dona + blok).
class _AlreadyRefunded {
  final Map<String, double> qty;
  final Map<String, double> pendingQty;
  final Set<String> marks;

  const _AlreadyRefunded(this.qty, this.pendingQty, this.marks);
}

/// Vozvrat sahifasining boshlang'ich holati: chap ro'yxat va shu chek bo'yicha
/// oldin qaytarilgan KM'lar (skanerda "oldin qaytarilgan" xabari uchun).
class RefundPageData {
  final ReceiptModel4 receipt;
  final Set<String> refundedMarks;

  const RefundPageData(this.receipt, this.refundedMarks);
}

_AlreadyRefunded _getAlreadyRefunded(
  String originalExternalId,
  Map<String, ReceiptModelSoldItem4> originalItems,
) {
  final Map<String, double> refundedQty = {};
  final Map<String, double> pendingQty = {};
  final Set<String> refundedMarks = {};
  try {
    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    final allRefunds = box.getAll().where((r) =>
        r.isRefund && r.returnForCheck == originalExternalId).toList();
    for (final refund in allRefunds) {
      for (final item in refund.soldItemList) {
        refundedMarks
          ..addAll(RefundMarkSplit.marksOf(item.mark))
          ..addAll(RefundMarkSplit.marksOf(item.boxMark));
        double dona = item.value;
        // Self-heal: eski buzilgan yozuvlar (vozvrat cheki qayta konsolidatsiya
        // bo'lib value boxValue marta oshib ketgan — 12 dona "12 blok"=144
        // bo'lib saqlangan). Belgi: qaytarilgan blok soni sotilgandan ko'p.
        final orig = originalItems[item.productId];
        if (item.saleType == 2 &&
            item.boxValue > 0 &&
            orig != null &&
            orig.boxQuantity > 0 &&
            item.boxQuantity > orig.boxQuantity) {
          dona = item.value / item.boxValue;
        }
        refundedQty[item.productId] =
            (refundedQty[item.productId] ?? 0) + dona;
        if (!refund.uploaded) {
          pendingQty[item.productId] =
              (pendingQty[item.productId] ?? 0) + dona;
        }
      }
    }
  } catch (e) {
    // ignore
  }
  return _AlreadyRefunded(refundedQty, pendingQty, refundedMarks);
}

/// Testlar uchun: vozvrat sahifasi ochilganda chap ro'yxat aynan shu qatorlardan.
@visibleForTesting
RefundPageData refundReceiptOf(
  ReceiptModel4 receipt, {
  Set<String> serverRefundedMarks = const {},
}) =>
    _copyWith(receipt, serverRefundedMarks);

RefundPageData _copyWith(
  ReceiptModel4 receipt, [
  Set<String> serverRefundedMarks = const {},
]) {
  // Local DB dan original sotuv itemlarini olamiz. Narxlarni shulardan
  // tiklaymiz — API GET javobi free gift va order-level diskontda har doim
  // ham per-item discount ma'lumotini saqlamaydi, lokal sotuv esa to'g'ri saqlangan.
  final Map<String, ReceiptModelSoldItem4> originalItemsMap =
      ChecksSingleton.localOriginalItems(receipt.externalId);
  // Allaqachon qaytarilgan miqdorlar va KM'lar
  final refunded = _getAlreadyRefunded(receipt.externalId, originalItemsMap);
  final Map<String, double> alreadyRefunded = refunded.qty;
  // Qaytarilgan KM'lar: server (har qanday kassa) + shu kassa (serverga hali
  // yetmaganlari ham). Havzadan chiqariladi, skanerlansa "oldin qaytarilgan".
  final Set<String> refundedMarks = {...refunded.marks, ...serverRefundedMarks};

  final List<ReceiptModelSoldItem4> list = [];
  for (var e in receipt.soldItemList) {
    final ReceiptModelSoldItem4? local = originalItemsMap[e.productId];
    final double refundedSoFar = alreadyRefunded[e.productId] ?? 0;

    // Blok sotuv maydonlari — lokal originaldan; u yo'q bo'lsa (chek boshqa
    // kassada sotilgan) serverdan (ItemsGTR blok token'ini donaga o'giradi).
    final ReceiptModelSoldItem4 boxSource = local ?? e;
    final int boxValue = boxSource.boxValue;
    final int soldBoxQuantity = boxSource.boxQuantity;
    final bool hasBox =
        boxSource.saleType == 2 && boxValue > 0 && soldBoxQuantity > 0;

    // Qoldiq:
    // * lokal original bor (shu kassada sotilgan): min(lokal − shu kassadagi
    //   vozvratlar, server qoldig'i) — server adminkada qilinganlarni ham biladi.
    //   Blokda faqat lokal hisob (ReUpdateBloc bunday itemni filtrlamaydi).
    // * lokal original yo'q (boshqa kassa): server qoldig'i (`e.value` —
    //   ReUpdateBloc refund_amount'ni ayirgan, blokda ItemsGTR token'ni donaga
    //   o'girgan) minus shu kassadagi serverga HALI yetmagan vozvratlar.
    //   Ilgari barcha lokal vozvratlar ayirilardi — serverga yetganlari ikki
    //   marta ayirilib, qolgan dona ro'yxatdan yo'qolardi.
    final double remainingQty = local == null
        ? e.value - (refunded.pendingQty[e.productId] ?? 0)
        : hasBox
            ? (local.value - refundedSoFar)
            : min(local.value - refundedSoFar, e.value);
    if (remainingQty <= 0) continue; // Hammasi qaytarilgan — ro'yxatga qo'shmaymiz

    // Narxlarni local DB dan olamiz (free gift = 0, diskontli = effektiv narx).
    // Topilmasa API qiymatlariga qaytamiz.
    final double itemPrice = local?.price ?? e.price;
    final double itemRealPrice = local?.realPrice ?? e.realPrice;
    final double itemOnlyPrice = local?.onlyPrice ?? e.price;
    final double itemSingleDiscount = local?.singleDiscount ?? e.singleDiscount;

    ReceiptModelSoldItem4 makeItem(
      double qty, {
      int saleType = 1,
      int boxValue = 0,
      int boxQuantity = 0,
      List<String> marks = const [],
    }) {
      return ReceiptModelSoldItem4(
        inBox: e.inBox,
        // Chap qatorda — skanerlab qaytarish mumkin bo'lgan KM'lar havzasi
        // ('\n' bilan, konsolidatsiyalangan chekdagidek). O'ngga skanerlangan
        // bitta KM bilan o'tadi (ReturnPageProviderr.scanMark).
        mark: marks.isEmpty ? null : marks.join('\n'),
        onlyPrice: itemOnlyPrice,
        realPrice: itemRealPrice,
        ownerType: e.ownerType,
        refundItemId: e.refundItemId,
        marking: marks.isNotEmpty && saleType != 2,
        soldBy: e.soldBy,
        cost: e.cost,
        createdTime: e.createdTime,
        price: itemPrice,
        value: qty,
        productId: e.productId,
        productName: e.productName,
        // pricePosition: e.pricePosition,
        barcode: e.barcode,
        sku: e.sku,
        vat: (itemPrice * e.vatPercent) / (100 + e.vatPercent),
        mxik: e.mxik,
        discountPercent: e.discountPercent,
        vatPercent: e.vatPercent,
        // tin: e.tin,
        singleDiscount: itemSingleDiscount,
        packageCode: e.packageCode,
        packageName: e.packageName,
        sellerId: e.sellerId,
        tin: e.tin,
        vatName: e.vatName,
        saleType: saleType,
        boxValue: boxValue,
        boxQuantity: boxQuantity,
      );
    }

    // Blok sotuv (saleType==2): qoldiqni blok va dona qatorlariga ajratamiz.
    // Blok qatori faqat butun blok qaytarish uchun — value baribir DONA hisobida
    // turadi (refund API, fiskal va DB dona bilan ishlaydi), blok faqat UI qatlami.
    // KM'li qism bitta qator, KM'lar havzasi bilan (RefundMarkSplit).
    final int blocksAvailable =
        hasBox ? min(soldBoxQuantity, remainingQty ~/ boxValue) : 0;
    final rows = RefundMarkSplit.plan(
      remainingUnits: remainingQty,
      boxValue: boxValue,
      blocksAvailable: blocksAvailable,
      unitMarks: RefundMarkSplit.marksOf(e.mark, local?.mark),
      boxMarks: RefundMarkSplit.marksOf(e.boxMark, local?.boxMark),
      refundedMarks: refundedMarks,
    );
    for (final row in rows) {
      list.add(row.isBlock
          ? makeItem(
              row.units,
              saleType: 2,
              boxValue: boxValue,
              boxQuantity: row.blocks,
              marks: row.marks,
            )
          : makeItem(row.units, marks: row.marks));
    }
  }

  final newReceiptModel4 = ReceiptModel4(
    supplierId: receipt.supplierId,
    dateTimeOFD: receipt.dateTimeOFD,
    fiscalSign: receipt.fiscalSign,
    receiptSeq: receipt.receiptSeq,
    discountID: receipt.discountID,
    discountVat: receipt.discountVat,
    terminalId: receipt.terminalId,
    newid: receipt.newid,
    rejected: receipt.rejected,
    createdDate: receipt.createdDate,
    refundInfo: receipt.refundInfo,
    clientPhone: receipt.clientPhone,
    cashierId: receipt.cashierId,
    cashierName: receipt.cashierName,
    date: receipt.date,
    isRefund: true,
    externalId: receipt.externalId,
    totalPrice: list.fold(0.0, (sum, e) => sum + e.price * e.value),
    uploaded: false,
    clientName: receipt.clientName,
    clientId: receipt.clientId,
    cashback: receipt.cashback,
    sdacha: receipt.sdacha,
    returnForCheck: receipt.externalId,
    posName: receipt.posName,
    isDonate: Pref.getBool('donate', false),
    commissionTIN: receipt.commissionTIN,
    cashboxId: receipt.cashboxId,
    orderId: receipt.orderId,
    orderType: receipt.orderType,
    shopId: receipt.shopId,
    userId: receipt.userId,
    url: receipt.url,
  );

  newReceiptModel4.soldItemList.clear();
  newReceiptModel4.payment.clear();
  newReceiptModel4.soldItemList.addAll(list);
  for (final p in receipt.payment) {
    newReceiptModel4.payment.add(ReceiptModelPaymentType4(
      name: p.name,
      value: p.value,
      payId: p.payId,
    ));
  }
  if (newReceiptModel4.payment.isEmpty) {
    newReceiptModel4.payment.add(ReceiptModelPaymentType4(
      name: "CASH",
      value: receipt.totalPrice,
      payId: Pref.getString(PrefKeys.cashId, ''),
    ));
  }

  return RefundPageData(newReceiptModel4, refundedMarks);
}
