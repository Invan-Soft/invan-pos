part of 'set_serive_sid_bloc.dart';

abstract class SetServeceSidEvent {}
 
class StartSetServiceSidEvent extends SetServeceSidEvent {
  final String sID;
  final String name;

  StartSetServiceSidEvent(this.sID, this.name);
}
