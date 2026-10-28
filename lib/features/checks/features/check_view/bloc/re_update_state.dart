part of 're_update_bloc.dart';

class ReUpdateState {}

class ReUpdateInitial extends ReUpdateState {}

class ReUpdateProccesState extends ReUpdateState {}

class ReUpdateFailureState extends ReUpdateState {}

class ReUpdateSuccesState extends ReUpdateState {
  final ReceiptModel4 receiptModel4;

  /// Serverda shu chek bo'yicha qaytarilgan KM'lar (dona + blok).
  final Set<String> refundedMarks;
  ReUpdateSuccesState({
    required this.receiptModel4,
    this.refundedMarks = const {},
  });
}
