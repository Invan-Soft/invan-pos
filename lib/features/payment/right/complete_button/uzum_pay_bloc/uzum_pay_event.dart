part of 'uzum_pay_bloc.dart';

class UzumPayEvent {}

class StartUzumPay extends UzumPayEvent {
  final String transactionId;
  final String otpData;
  final num amount;

  StartUzumPay({
    required this.transactionId,
    required this.otpData,
    required this.amount,
  });
}
