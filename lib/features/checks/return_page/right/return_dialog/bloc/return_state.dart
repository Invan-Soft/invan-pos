part of 'return_bloc.dart';

abstract class ReturnState {}

class ReturnInitial extends ReturnState {}

class ReturnLoadingState extends ReturnState {
  final ReturnMessage message;
  ReturnLoadingState({required this.message});
}

class ReturnNoInternetState extends ReturnState {}

class ReturnSuccedState extends ReturnState {
  /// Vozvrat lokal va fiskal jihatdan bajarildi, lekin server uni rad etdi.
  /// Chek `rejected` belgilangan — cheklar ekranidan qo'lda yuboriladi.
  /// "Qayta urinish" bu holatda BO'LMASLIGI kerak: fiskal chek allaqachon
  /// chiqqan, qayta urinish ikkinchi fiskal vozvrat yaratadi.
  final String? warning;

  ReturnSuccedState({this.warning});
}

class ReturnFailedState extends ReturnState {
  final String error;
  
  ReturnFailedState(
      {required this.error});
}
