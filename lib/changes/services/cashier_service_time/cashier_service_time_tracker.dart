/// Har bir mijoz sloti (clientNumber, 6-mijoz rejimi) uchun xizmat
/// boshlanish vaqtini xotirada saqlaydi.
///
/// Qoida: boshlanish vaqti FAQAT sotuv yakunlanganda (`takeStartedTime`)
/// tozalanadi. Kassir savatni sotuvsiz tozalasa ham vaqt saqlanib qoladi —
/// keyingi sotuv o'sha birinchi qo'shilgan paytdan hisoblanadi.
class CashierServiceTimeTracker {
  CashierServiceTimeTracker._();

  static final CashierServiceTimeTracker instance =
      CashierServiceTimeTracker._();

  final Map<int, DateTime> _startedTimes = {};

  /// Savatga mahsulot qo'shilganda chaqiriladi. Slot uchun vaqt allaqachon
  /// mavjud bo'lsa, tegilmaydi (birinchi qo'shilish g'olib).
  void markStarted(int clientNumber) {
    _startedTimes.putIfAbsent(clientNumber, () => DateTime.now());
  }

  /// Sotuv yakunlanganda boshlanish vaqtini qaytaradi va slotni tozalaydi.
  /// Vaqt topilmasa (masalan, savat holatida ilova qayta ochilgan) null.
  DateTime? takeStartedTime(int clientNumber) {
    return _startedTimes.remove(clientNumber);
  }
}
