part of 'set_driver_bloc.dart';

abstract class SetDriverEvent {}

class SetStartDriverName extends SetDriverEvent {
  final String name;
  final String pass;

  SetStartDriverName(this.name, this.pass);
}
