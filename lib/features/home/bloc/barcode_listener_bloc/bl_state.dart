part of 'bl_bloc.dart';
// BARCODE LISTENER
abstract class BlState {
  BLStatus status;
  BlState(this.status);
}

class BlInitial extends BlState {
  
  BlInitial(super.status);
}
