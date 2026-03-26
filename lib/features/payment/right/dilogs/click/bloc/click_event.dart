part of 'click_bloc.dart';

abstract class ClickEvent {}
class ClickCallInitialEvent extends ClickEvent{
  
}

class ClickPayEvent extends ClickEvent {
  final bool isRetry;
  final double summa;
  final String otp;
  final String receiptNumber;
  ClickPayEvent({required this.isRetry, 
    required this.otp,
    required this.summa,
    required this.receiptNumber,
  });
}
