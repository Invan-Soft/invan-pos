part of 'return_bloc.dart';

abstract class ReturnEvent {}

class ReturnReturnEvent extends ReturnEvent {
  final bool isRetry;
  final String clientNumber;
  final AppLocalizations loc;
  final ReceiptModel4 receiptModel4;
  final List<ReceiptModelSoldItem4> rightList;
  ReturnReturnEvent({required this.isRetry, 
    required this.clientNumber,
    required this.receiptModel4,
    required this.rightList,
    required this.loc,
  });
}
