part of 'connect_bloc.dart';

@immutable
abstract class ConnectEvent {}

class ConnectRequestEvent extends ConnectEvent {
  BuildContext context;
  bool mounded;
  Function() onDisconnect;

  ConnectRequestEvent(
    this.context,
    this.mounded,
    this.onDisconnect,
  );
}

class InitialEvent extends ConnectEvent {}

class DisconnectEvent extends ConnectEvent {}
