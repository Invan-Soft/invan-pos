part of 'paynet_bloc.dart';

abstract class PaynetEvent {}

class PaynetPayEvent extends PaynetEvent {
  final String otp;
  final double summa;
  final String receiptNumber;
  final bool isRetry;

  PaynetPayEvent({
    required this.otp,
    required this.summa,
    required this.receiptNumber,
    this.isRetry = false,
  });
}

class PaynetCallInitialEvent extends PaynetEvent {}
