part of 'payme_bloc.dart';

@immutable
abstract class PaymeEvent {}

class PaymeCreateReceiptEvent extends PaymeEvent {
  final int amount;
  final List<ReceiptModelSoldItem4> items;
  PaymeCreateReceiptEvent({required this.amount, required this.items});
}

class PaymePayEvent extends PaymeEvent {
  final String token;

  PaymePayEvent(this.token);
}
