import 'package:intl/intl.dart';

/// Kassirning bitta sotuv (chek) davomida mijozga sarflagan vaqti.
///
/// `startedTime` — savatga birinchi mahsulot qo'shilgan payt.
/// `closedTime` — chek yopilgan (sotuv muvaffaqiyatli yakunlangan) payt.
/// Payload API'ga yuborishga tayyor formatda (`toJson`).
class CashierServiceTimeModel {
  final DateTime startedTime;
  final DateTime closedTime;
  final String checkNumber;
  final String cashierId;
  final String cashierName;
  final String cashboxId;
  final String clientId;
  final String clientName;
  final String clientPhone;

  const CashierServiceTimeModel({
    required this.startedTime,
    required this.closedTime,
    required this.checkNumber,
    required this.cashierId,
    required this.cashierName,
    required this.cashboxId,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
  });

  Duration get serviceDuration => closedTime.difference(startedTime);

  static final DateFormat _dateFormat = DateFormat('dd-MM-yyyy HH:mm:ss');

  Map<String, dynamic> toJson() => {
        'started_time': _dateFormat.format(startedTime),
        'closed_time': _dateFormat.format(closedTime),
        'duration_seconds': serviceDuration.inSeconds,
        'check_number': checkNumber,
        'cashier_id': cashierId,
        'cashier_name': cashierName,
        'cashbox_id': cashboxId,
        'client_id': clientId,
        'client_name': clientName,
        'client_phone': clientPhone,
      };
}
