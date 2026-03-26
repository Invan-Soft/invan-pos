part of 'pin_bloc.dart';

abstract class PinState {}

class PinInitial extends PinState {
  String? error;
  final PinSuccesStatus status;
  final int length;
  PinInitial(
      {required this.length, required this.status,this.error});
}

class PinLoadingStatee extends PinState {
  PinLoadingStatee();
}

enum PinSuccesStatus { pinSucced, pinWrong, initial,getOrgErr }
