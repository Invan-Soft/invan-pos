part of 'tp_bloc.dart';

abstract class TpState {
  TpStatus inputStatus;
  bool isSelectedAll;

  TpState({required this.inputStatus, required this.isSelectedAll});
}

class TpInitial extends TpState {
  TpInitial({required TpStatus inputStatus, required bool isAllSelected})
      : super(isSelectedAll: isAllSelected, inputStatus: inputStatus);
}

class TpComletedState extends TpState {
  final num dicountPercent;
  final List<ReceiptModelSoldItem4> products;

  TpComletedState(TpStatus status, bool isAllSelected,
      {required this.dicountPercent, required this.products})
      : super(inputStatus: status, isSelectedAll: isAllSelected);
}

enum TpStatus { summa, discount }
