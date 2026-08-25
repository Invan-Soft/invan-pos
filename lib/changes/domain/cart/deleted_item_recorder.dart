// Savatdan o'chirilgan mahsulotlarni qayd etish.
//
// Kassir savatdan qator o'chirsa (yoki sonini kamaytirsa) bu yozuv
// `order_pos` ning "deleted_items" massivida serverga ketadi — do'kon
// egasi "qo'shildi-o'chirildi" holatlarini ko'ra oladi.
//
// Ikki holat farqlanadi:
//   - chek YAKUNLANDI  -> yozuvga o'sha chek raqami biriktiriladi
//   - savat SOTUVSIZ bo'shadi -> checkNumber = "-" (orphan)
//
// `OrderingProvider4` dan ko'chirildi (Faza 9.3) — tanalar o'zgarmagan.
// Xodim IDsi callback orqali keladi, shuning uchun modul Hive'ga bog'liq
// emas va to'g'ridan-to'g'ri testlanadi.

import 'package:intl/intl.dart';
import 'package:invan2/changes/models/deleted_item_model.dart';
import 'package:invan2/features/get_employees/model/employees_find_response.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

class DeletedItemRecorder {
  const DeletedItemRecorder._();

  /// O'chirilgan mahsulotni joriy savat sessiyasining deleted-items
  /// ro'yxatiga yozadi — sotuv yakunlanganda order_pos "deleted_items"
  /// massivida serverga ketadi (offline chekda ham saqlanadi).
  ///
  /// [approvedBy] — o'chirishga PIN kodi bilan ruxsat bergan xodim. Kassirning
  /// o'zida `deletePrice` ruxsati bo'lmasa, PIN dialogi ochiladi va o'sha PIN
  /// egasi shu yerga keladi — `deleted_by` da AYNAN O'SHA xodim ketadi.
  /// null bo'lsa (PIN so'ralmagan, kassirning o'zida ruxsat bor) — joriy kassir.
  static void record(
    List<DeletedItemModel4> into,
    ReceiptModelSoldItem4 item, {
    double? quantity,
    Employee? approvedBy,
    required String Function() currentEmployeeId,
  }) {
    // Auto-boshqariladigan qatorlar (free gift qayta hisoblash va h.k.) emas,
    // faqat kassir qo'li bilan o'chirgan qatorlar shu metod orqali yoziladi.
    // quantity berilsa qisman o'chirish (qty kamaytirish), aks holda butun qator.
    // Red-delete'da allaqachon o'chirilgan qator qayta yozilmaydi (X tugmasi
    // ketma-ket bosilganda index 0 dagi o'sha qatorga qayta tushishi mumkin).
    if (item.isDeleted ?? false) return;
    final qty = quantity ?? item.value;
    if (qty <= 0) return;
    final employeeId = approvedBy?.user?.id ?? currentEmployeeId();
    into.add(
      DeletedItemModel4(
        deletedBy: employeeId,
        deletedTime:
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()),
        addedTime: item.createdTime > 0
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(
                DateTime.fromMillisecondsSinceEpoch(item.createdTime).toUtc())
            : '',
        productId: item.productId,
        quantity: qty,
        totalPrice: double.parse((item.price * qty).round().toStringAsFixed(1)),
      ),
    );
  }

  /// Savat SOTUVSIZ bo'shaganda (barcha aktiv mahsulot o'chirilib, chek
  /// yakunlanmasdan) — shu paytgacha yig'ilgan, hali biror chek raqami
  /// olmagan o'chirishlarni "sotuvsiz" deb belgilaydi: checkNumber = "-".
  /// Keyingi yakunlangan sotuv bilan shu "-" holatida yuklanadi, shunda
  /// backend "mahsulot qo'shildi-o'chirildi, lekin sotuv bo'lmadi" holatni
  /// ajrata oladi (masalan, kassir klientdan pul olib o'chirib tashladimi).
  ///
  /// Savatda aktiv mahsulot qolgan bo'lsa — hech narsa qilmaydi (no-op),
  /// shuning uchun barcha to'liq-o'chirish metodlaridan xavfsiz chaqiriladi.
  static void flagOrphansIfCartEmpty(
    List<ReceiptModelSoldItem4> rows,
    List<DeletedItemModel4> deletedItems,
  ) {
    final hasActive = rows.any((p) => !(p.isDeleted ?? false));
    if (hasActive) return;
    for (final d in deletedItems) {
      if (d.checkNumber.isEmpty) d.checkNumber = '-';
    }
  }
}
