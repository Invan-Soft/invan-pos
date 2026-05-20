part of 'nad_bloc.dart';

abstract class NadEvent {}

class NadScannedEvent extends NadEvent {
  final String scanned;
  NadScannedEvent(this.scanned);
}
    class  NadCallInitialEvent  extends NadEvent  {

}