part of 're_update_bloc.dart';

class ReUpdateState {}

class ReUpdateInitial extends ReUpdateState {}

class ReUpdateProccesState extends ReUpdateState {}

class ReUpdateFailureState extends ReUpdateState {}

class ReUpdateSuccesState extends ReUpdateState {
  final ReceiptModel4 receiptModel4;
  ReUpdateSuccesState({required this.receiptModel4});
}
