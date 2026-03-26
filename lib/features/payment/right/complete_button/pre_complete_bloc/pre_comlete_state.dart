part of 'per_comlete_bloc.dart';

abstract class PreCtState {}

class PreCtInitialState extends PreCtState {
  PreCtInitialState();
}

class PreCtLoadingState extends PreCtState {}

class PreCtSucceedState extends PreCtState {
  final bool showSdachaDialog;
  final double sdacha;
  PreCtSucceedState({required this.sdacha, required this.showSdachaDialog});
}

class PreCtPrepereState extends PreCtState {}

class PreCtErrorState extends PreCtState {
  Object subError;
  final String error;
  PreCtErrorState({required this.error, required this.subError});
}

class PreCtPayingState extends PreCtState {
  final bool ofd;
  final bool sdachaToCashback;
  final double sdacha;

  PreCtPayingState(
      {required this.ofd,
      required this.sdachaToCashback,
      required this.sdacha});
}
