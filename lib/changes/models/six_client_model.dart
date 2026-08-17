import 'package:invan2/changes/models/client_model.dart';
import 'package:invan2/changes/models/deleted_item_model.dart';
import 'package:invan2/changes/models/supplier_model.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

class SixClientModel4 {
  int clientNumber;
  int lastAddedIndex;
  List<ReceiptModelSoldItem4> orderedProducts;

  /// Shu savat sessiyasida kassir tomonidan o'chirilgan mahsulotlar.
  /// Sotuv yakunlanganda chekka biriktiriladi va tozalanadi.
  final List<DeletedItemModel4> deletedItems = [];
  String? clientPhone;
  ClientModel? selectedClient;

  /// Shu savat (slot) uchun tanlangan supplier — "Перечисления"/Didox INN
  /// qidiruvi yoki supplier qidiruv oynasi orqali.
  ///
  /// `selectedClient` kabi HAR SLOTGA alohida: 1-mijozda supplier tanlangani
  /// 2-mijozda mijoz/cashback tanlashni bloklamasligi kerak. "Mijoz YOKI
  /// supplier" qoidasi bitta sotuv (slot) doirasida amal qiladi.
  SupplierModel? selectedSupplier;

  /// "Перечисления" oynasida shu savat uchun kiritilgan kompaniya nomi va
  /// chek nusxalari soni. Chop etish ularni global Pref'dan
  /// (`companyNameDialog` / `companyResipt`) o'qigani uchun, savat almashganda
  /// Pref joriy slotning qiymatlari bilan sinxronlanadi
  /// (`OrderingProvider4._syncReceiptCompanyPrefsFromCurrentClient`).
  String? receiptCompanyName;
  int? receiptCopies;
  double? discountAmount;
  double? discountAmountFromNewClient;
  double? discountPercent;

  SixClientModel4({
    this.discountAmount,
    this.clientPhone,
    required this.discountAmountFromNewClient,
    required this.clientNumber,
    required this.lastAddedIndex,
    required this.orderedProducts,
    this.discountPercent,
    this.selectedClient,
  });
}
