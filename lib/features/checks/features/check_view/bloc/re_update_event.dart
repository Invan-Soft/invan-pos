part of 're_update_bloc.dart';

class ReUpdateEvent {}

class GetReUpdateEvent extends ReUpdateEvent {
  final ReceiptModel4 receiptModel4;
  GetReUpdateEvent({required this.receiptModel4});
}
