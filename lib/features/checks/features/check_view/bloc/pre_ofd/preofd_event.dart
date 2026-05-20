part of 'preofd_bloc.dart';

abstract class PreOfdEvent {}

class SetPreOfdEvent extends PreOfdEvent {
  final bool isRetry;
  final String clientNumber;
  final AppLocalizations loc;
  final ReceiptModel4 receiptModel4;
  // final bool toOFD;
  SetPreOfdEvent({
    required this.isRetry,
    required this.clientNumber,
    required this.receiptModel4,
    required this.loc,
    // required this.toOFD,
  });
}
