part of 'uzum_pay_bloc.dart';

abstract class UzumPayState {}

class UzumPayInitial extends UzumPayState {}

class UzumPaySuccessState extends UzumPayState {}

class UzumPayProcessState extends UzumPayState {}

class UzumPayFailureState extends UzumPayState {
  final String error;
  UzumPayFailureState(this.error);
}
