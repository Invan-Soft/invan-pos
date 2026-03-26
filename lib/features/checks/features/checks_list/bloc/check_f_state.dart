part of 'check_f_bloc.dart';

abstract class CheckFState {
  ReceiptModel4? selectedCheck;
  CheckFState([this.selectedCheck]);
  
}

class CheckFInitial extends CheckFState {
  final List<ReceiptModel4> checksList;
  final int selected;
  CheckFInitial(
    super.selectedCheck, {
    required this.selected,
    required this.checksList,
  });
}

class CheckFLoadingState extends CheckFState {
  final CheckF message;
  CheckFLoadingState(this.message, ReceiptModel4? selectedCheck)
      : super(selectedCheck);
}

class ChecksFNotFoundState extends CheckFState {
  ChecksFNotFoundState(ReceiptModel4? selectedCheck) : super(selectedCheck);
}

class CheckFNoIternetState extends CheckFState {
  final String pattern;
  CheckFNoIternetState({ReceiptModel4? selectedCheck, required this.pattern})
      : super(selectedCheck);
}

class CheckFNoChekYetState extends CheckFState {}

class CheckFErrorState extends CheckFState {
  final String error;
  CheckFErrorState(this.error);
}
