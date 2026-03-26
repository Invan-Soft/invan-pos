part of 'comlete_bloc.dart';

abstract class CtState {}

class CtInitialState extends CtState {
  CtInitialState();
}

class CtLoadingState extends CtState {}

class CtSucceedState extends CtState {
  final bool showSdachaDialog;
  final double sdacha;
  CtSucceedState({required this.sdacha, required this.showSdachaDialog});
}

class CtPrepereState extends CtState {}

class CtErrorState extends CtState {
  Object subError;
  final String error;
  CtErrorState({required this.error, required this.subError});
}

class CtPayingState extends CtState {
  final bool ofd;
  final bool sdachaToCashback;
  final double sdacha;

  CtPayingState(
      {required this.ofd,
      required this.sdachaToCashback,
      required this.sdacha});
}
