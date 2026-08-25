// OPD (mahsulot ustida amal) dialogidan keladigan savat tahrirlari.
//
// Dialogning ikki tugmasi bor — "Saqlash" va "O'chirish" — va ular uch xil
// nishonga tushishi mumkin: markirovka guruhi, blok guruhi yoki bitta qator.
// Nishonni tahrir rejimi bayroqlari hal qiladi.
//
// Savatda markirovkali mahsulot har skanda alohida qator (marka bir-biriga
// qo'shilmaydi), blok ham alohida qator. UI ularni bitta qator qilib
// ko'rsatadi, shuning uchun OPD dialogi butun GURUHGA qo'llanishi kerak:
//   qty kamaytirish -> eng yangi qatorlarni o'chirish (eng past indeks)
//   qty oshirish     -> mumkin emas (yangi marka/blok skanerlanishi kerak)
//   narx o'zgarishi  -> butun guruhga, qo'lda narx bo'lsa mahsulotning
//                       boshqa qatorlariga ham (blok <-> dona)
//
// `OrderingProvider4` dan ko'chirildi (Faza 9.2) — tanalar o'zgarmagan.
//
// 2-QOIDA: bu sinf `ChangeNotifier` EMAS. Provider `notifyListeners` ni
// callback sifatida beradi, aks holda holat o'zgarib UI qayta chizilmay
// qolardi. Savat va provider holatiga murojaatlar ham callback orqali —
// savat egaligi providerda qoladi.

import 'package:intl/intl.dart';
import 'package:invan2/features/get_employees/model/employees_find_response.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

class CartEditController {
  CartEditController({
    required this.rowsOf,
    required this.notify,
    required this.recordDeletedItem,
    required this.reprice,
    required this.syncManualPrice,
    required this.refreshDiscountEffects,
    required this.clearShowCounts,
    required this.resetClientDiscount,
    required this.flagOrphanDeletedItems,
    required this.isRedDeleteOn,
    required this.currentEmployeeName,
    required this.posNameOf,
    required this.notifyDeleted,
  });

  /// Joriy mijozning savat qatorlari (egalik providerda qoladi).
  final List<ReceiptModelSoldItem4> Function() rowsOf;

  /// `notifyListeners` — 2-qoida.
  final void Function() notify;

  /// O'chirilgan qatorni `deleted_items` ga yozadi.
  final void Function(ReceiptModelSoldItem4 item,
      {double? quantity, Employee? approvedBy}) recordDeletedItem;

  /// Tier'ni savatdagi umumiy dona soni bo'yicha qayta tanlaydi.
  final void Function(String? productId) reprice;

  /// Qo'lda narxni mahsulotning barcha qatorlariga sinxronlaydi.
  final void Function(ReceiptModelSoldItem4 edited) syncManualPrice;

  /// BuyXGetY / FreeGift / BuyXGetX effektlarini qayta hisoblaydi.
  final void Function() refreshDiscountEffects;

  /// Mahsulotning diskont-dialog hisoblagichlarini tozalaydi.
  final void Function(String productId) clearShowCounts;

  /// Savat bo'shagach mijoz tanlovi va uning foizini bekor qiladi.
  final void Function() resetClientDiscount;

  /// Savat sotuvsiz bo'shaganda o'chirishlarni "-" deb belgilaydi.
  final void Function() flagOrphanDeletedItems;

  /// "Qizil o'chirish" rejimi yoqilganmi (qator savatda qoladi).
  final bool Function() isRedDeleteOn;

  /// Joriy kassir ismi — xabarnoma matni uchun.
  final String Function() currentEmployeeName;

  /// Kassa (POS) nomi — xabarnoma matni uchun.
  final String Function() posNameOf;

  /// O'chirish haqida tashqi xabarnoma (Telegram). Sotuvni to'xtatmaydi.
  final Future<void> Function({
    required String productName,
    required String productId,
    required String posName,
    required String employeeName,
    required String deleteTime,
    required String product_qunatity,
  }) notifyDeleted;

  List<ReceiptModelSoldItem4> get rows => rowsOf();

  /// Markirovka guruhi tahrir rejimi: null bo'lmasa, tahrir qilinayotgan
  /// markirovka guruhining productId si.
  String? markGroupProductId;

  /// Blok guruhi tahrir rejimi: null bo'lmasa, tahrir qilinayotgan blok
  /// guruhining productId si.
  String? boxGroupProductId;

  bool get isMarkGroupEditing => markGroupProductId != null;

  bool get isBoxGroupEditing => boxGroupProductId != null;

  /// Berilgan productId uchun aktiv (o'chirilmagan) markirovka itemlarining
  /// orderedProducts dagi indekslari. Eng yangi (insert(0) bilan qo'shilgan)
  /// markalar pastroq indeksda bo'ladi.
  List<int> activeMarkIndices(String productId) {
    final result = <int>[];
    for (var i = 0; i < rows.length; i++) {
      final e = rows[i];
      if (e.productId == productId && e.marking && !(e.isDeleted ?? false)) {
        result.add(i);
      }
    }
    return result;
  }

  /// Markirovka guruhini saqlash: yangi qty ga qarab eng yangi markalarni
  /// o'chiradi (qty kamayganda) yoki narx/diskont o'zgarishini barcha markalarga
  /// qo'llaydi. Qty ni oshirib bo'lmaydi (yangi mark skanerlanishi kerak).
  Future<void> saveMarkGroup(ReceiptModelSoldItem4 edited,
      {Employee? approvedBy}) async {
    final pid = markGroupProductId!;
    final indices = activeMarkIndices(pid);
    if (indices.isEmpty) return;

    final currentCount = indices.length;
    final newCount = edited.value.floor();

    if (newCount <= 0) {
      deleteMarkGroup(pid, approvedBy: approvedBy);
      return;
    }

    if (newCount < currentCount) {
      // Eng yangi markalarni o'chiramiz: indices o'sish tartibida, eng past
      // indeks = eng yangi. Birinchi (currentCount - newCount) tasini olamiz.
      final removeCount = currentCount - newCount;
      final toRemove = indices.take(removeCount).toList()
        ..sort((a, b) => b.compareTo(a)); // teskari tartib (xavfsiz o'chirish)
      final redDelete = isRedDeleteOn();
      for (final idx in toRemove) {
        recordDeletedItem(rows[idx],
            approvedBy: approvedBy);
        if (redDelete) {
          rows[idx].isDeleted = true;
        } else {
          rows.removeAt(idx);
        }
      }
    }
    // newCount >= currentCount → qty oshmaydi (skan kerak), o'zgarishsiz.

    // Narx/diskont o'zgarishini guruhdagi qolgan barcha markalarga qo'llaymiz.
    for (final m in activeMarkIndices(pid)) {
      final item = rows[m];
      item.price = edited.price;
      item.realPrice = edited.realPrice;
      item.onlyPrice = edited.onlyPrice;
      item.singleDiscount = edited.singleDiscount;
      item.discountPercent = edited.discountPercent;
      item.isPriceOnlyChanged = edited.isPriceOnlyChanged;
      item.isPriceChanged = edited.isPriceChanged;
      item.tin = edited.tin;
      item.vat = (edited.price * item.vatPercent) / (100 + item.vatPercent);
    }

    final remaining = activeMarkIndices(pid);
    if (remaining.isEmpty) {
      clearShowCounts(pid);
      if (rows.every((e) => (e.isDeleted ?? false))) {
        resetClientDiscount();
      }
    }

    // Narx qo'lda o'zgartirilgan bo'lsa — mahsulotning BOSHQA qatorlariga
    // (ayniqsa blok qatori) ham sinxronlaymiz. Aks holda marka guruhini
    // tahrirlaganda blok tier narxda qolib ketardi (bir xil mahsulot, narxi
    // bir xil bo'lishi kerak).
    if (edited.isPriceOnlyChanged) {
      syncManualPrice(edited);
    }

    reprice(pid);
    refreshDiscountEffects();
    notify();
  }

  /// Markirovka guruhidagi barcha aktiv markalarni o'chiradi (red-delete ni hisobga olib).
  void deleteMarkGroup(String pid, {Employee? approvedBy}) {
    final redDelete = isRedDeleteOn();
    final indices = activeMarkIndices(pid)..sort((a, b) => b.compareTo(a));
    for (final idx in indices) {
      recordDeletedItem(rows[idx],
          approvedBy: approvedBy);
      if (redDelete) {
        rows[idx].isDeleted = true;
      } else {
        rows.removeAt(idx);
      }
    }
    clearShowCounts(pid);

    if (rows.isEmpty ||
        rows.every((e) => (e.isDeleted ?? false))) {
      resetClientDiscount();
      // Savat sotuvsiz bo'shadi — yig'ilgan o'chirishlarni "sotuvsiz" (-) belgila.
      flagOrphanDeletedItems();
    }

    reprice(pid);
    refreshDiscountEffects();
    notify();
  }

  /// Berilgan productId uchun aktiv (o'chirilmagan) blok itemlarining
  /// (saleType==2) orderedProducts dagi indekslari. Eng yangi (insert(0) bilan
  /// qo'shilgan) bloklar pastroq indeksda bo'ladi.
  List<int> activeBoxIndices(String productId) {
    final result = <int>[];
    for (var i = 0; i < rows.length; i++) {
      final e = rows[i];
      if (e.productId == productId &&
          e.saleType == 2 &&
          !(e.isDeleted ?? false)) {
        result.add(i);
      }
    }
    return result;
  }

  /// Blok guruhini saqlash: yangi qty (blok soni) ga qarab eng yangi bloklarni
  /// o'chiradi (qty kamayganda) yoki narx o'zgarishini butun mahsulotga qo'llaydi.
  /// Qty ni oshirib bo'lmaydi (yangi blok skanerlanishi kerak — OPD'da "+" bloklangan).
  /// [edited.value] blok soni hisobida keladi (order_list displayValue = blok soni).
  Future<void> saveBoxGroup(ReceiptModelSoldItem4 edited,
      {Employee? approvedBy}) async {
    final pid = boxGroupProductId!;
    final indices = activeBoxIndices(pid);
    if (indices.isEmpty) return;

    final currentCount = indices.length;
    final newCount = edited.value.floor();

    if (newCount <= 0) {
      deleteBoxGroup(pid, approvedBy: approvedBy);
      return;
    }

    if (newCount < currentCount) {
      // Eng yangi bloklarni o'chiramiz: indices o'sish tartibida, eng past
      // indeks = eng yangi. Birinchi (currentCount - newCount) tasini olamiz.
      final removeCount = currentCount - newCount;
      final toRemove = indices.take(removeCount).toList()
        ..sort((a, b) => b.compareTo(a)); // teskari tartib (xavfsiz o'chirish)
      final redDelete = isRedDeleteOn();
      for (final idx in toRemove) {
        recordDeletedItem(rows[idx],
            approvedBy: approvedBy);
        if (redDelete) {
          rows[idx].isDeleted = true;
        } else {
          rows.removeAt(idx);
        }
      }
    }
    // newCount >= currentCount → qty oshmaydi (skan kerak), o'zgarishsiz.

    if (edited.isPriceOnlyChanged) {
      // Narx qo'lda o'zgartirilgan: blok narxini qolgan bloklarga va (blok⇄dona
      // bitta dona narxi bazasida) mahsulotning boshqa qatorlariga sinxronlaymiz.
      for (final m in activeBoxIndices(pid)) {
        final item = rows[m];
        item.price = edited.price;
        item.realPrice = edited.realPrice;
        item.onlyPrice = edited.onlyPrice;
        item.singleDiscount = edited.singleDiscount;
        item.discountPercent = edited.discountPercent;
        item.isPriceOnlyChanged = true;
        item.isPriceChanged = edited.isPriceChanged;
        item.vat = (edited.price * item.vatPercent) / (100 + item.vatPercent);
      }
      syncManualPrice(edited);
    } else {
      // Faqat qty o'zgardi: tier savatdagi umumiy dona bo'yicha qayta tanlanadi.
      reprice(pid);
    }

    final remaining = activeBoxIndices(pid);
    if (remaining.isEmpty) {
      clearShowCounts(pid);
      if (rows.every((e) => (e.isDeleted ?? false))) {
        resetClientDiscount();
      }
    }

    refreshDiscountEffects();
    notify();
  }

  /// Blok guruhidagi barcha aktiv bloklarni o'chiradi (red-delete ni hisobga olib).
  void deleteBoxGroup(String pid, {Employee? approvedBy}) {
    final redDelete = isRedDeleteOn();
    final indices = activeBoxIndices(pid)..sort((a, b) => b.compareTo(a));
    for (final idx in indices) {
      recordDeletedItem(rows[idx],
          approvedBy: approvedBy);
      if (redDelete) {
        rows[idx].isDeleted = true;
      } else {
        rows.removeAt(idx);
      }
    }
    clearShowCounts(pid);

    if (rows.isEmpty ||
        rows.every((e) => (e.isDeleted ?? false))) {
      resetClientDiscount();
      // Savat sotuvsiz bo'shadi — yig'ilgan o'chirishlarni "sotuvsiz" (-) belgila.
      flagOrphanDeletedItems();
    }

    reprice(pid);
    refreshDiscountEffects();
    notify();
  }

  /// OPD dialogidan BITTA qatorni o'chiradi (guruh rejimi yoqilmaganda).
  ///
  /// [approvedBy] — PIN kodi bilan o'chirishga ruxsat bergan xodim.
  Future<void> deleteRow(int index, {Employee? approvedBy}) async {
    final bool isRedDeleteActivated = isRedDeleteOn();
    final employeeName = currentEmployeeName();

    final deletedProduct = rows[index];
    final productName = deletedProduct.productName ?? "Noma'lum mahsulot";
    final productId = deletedProduct.productId ?? "-";
    final posName = posNameOf();
    final deleteTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final product_qunatity = deletedProduct.value ?? "0";
    final deletedProductId = deletedProduct.productId;

    recordDeletedItem(deletedProduct, approvedBy: approvedBy);

    if (isRedDeleteActivated) {
      rows[index].isDeleted = true;
    } else {
      rows.removeAt(index);
    }

    // Agar shu productdan boshqa hech narsa qolmagan bo'lsa, dialog flagini tozala
    if (deletedProductId.isNotEmpty) {
      final hasRemaining = rows.any(
        (e) => e.productId == deletedProductId && !(e.isDeleted ?? false),
      );
      if (!hasRemaining) {
        clearShowCounts(deletedProductId);
      }
    }

    if (rows.isEmpty) {
      resetClientDiscount();
    }

    // Qator o'chgach umumiy son kamayadi — qolgan qatorlar tier'i qayta tanlanadi
    reprice(deletedProductId);

    // Savat sotuvsiz bo'shagan bo'lsa (red-delete'da ham) yig'ilgan
    // o'chirishlarni "sotuvsiz" (-) belgila.
    flagOrphanDeletedItems();

    refreshDiscountEffects();
    notify();
    await notifyDeleted(
      productName: productName,
      productId: productId,
      product_qunatity: product_qunatity.toString(),
      posName: posName,
      employeeName: employeeName,
      deleteTime: deleteTime,
    );
  }
}
