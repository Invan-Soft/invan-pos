import 'package:invan2/changes/services/cashier_service_time/cashier_service_time_tracker.dart';

/// Kassir xizmat vaqtini o'lchash facade'i — provider faqat shu klass
/// bilan gaplashadi (tracker ichki detal).
///
/// Oqim:
///  - savatga mahsulot qo'shilganda `onProductAdded` → start belgilanadi;
///  - chek (ReceiptModel4) tuzilayotganda, order_pos'ga yuborilishidan OLDIN,
///    `takeStartedTime` orqali start vaqti olinadi va chekning "order_time"
///    maydoniga (started_time/closed_time/duration_seconds) yoziladi.
class CashierServiceTimeService {
  CashierServiceTimeService._(this._tracker);

  static final CashierServiceTimeService instance =
      CashierServiceTimeService._(CashierServiceTimeTracker.instance);

  final CashierServiceTimeTracker _tracker;

  void onProductAdded(int clientNumber) {
    _tracker.markStarted(clientNumber);
  }

  /// Slot uchun start vaqtini oladi va slotni tozalaydi (bir martalik —
  /// keyingi sotuvga eski vaqt o'tib ketmasligi uchun). Topilmasa null.
  DateTime? takeStartedTime(int clientNumber) {
    return _tracker.takeStartedTime(clientNumber);
  }
}
