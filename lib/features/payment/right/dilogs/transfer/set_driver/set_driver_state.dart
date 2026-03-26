part of 'set_driver_bloc.dart';

abstract class SetDriverState {}

class SetDriverInitial extends SetDriverState {}

class SetDriverNameSucces extends SetDriverState {
  final String name;
  final String pass;

  SetDriverNameSucces(this.name, this.pass);
}
