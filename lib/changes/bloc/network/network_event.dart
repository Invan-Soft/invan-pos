part of 'network_bloc.dart';

abstract class NetworkEvent {}

// class ModeChangedEvent extends NetworkEvent {
//   final bool isDark;
//   ModeChangedEvent(this.isDark);
// }

class NetworkChangedEvent extends NetworkEvent {
  final bool status;
  NetworkChangedEvent({required this.status});
}

class NetworkNoEvent extends NetworkEvent {}
