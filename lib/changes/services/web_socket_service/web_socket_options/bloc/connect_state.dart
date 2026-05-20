part of 'connect_bloc.dart';

@immutable
abstract class ConnectState {}

class ConnectInitial extends ConnectState {}

class LoadingConnectState extends ConnectState {}

class ConnectSuccessState extends ConnectState {}

class DisconnectState extends ConnectState {}
