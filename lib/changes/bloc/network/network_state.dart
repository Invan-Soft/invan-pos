part of 'network_bloc.dart';

abstract class NetworkState {
  // final bool isDark;
  // NetworkState(this.isDark);
}

class NetworkInitial extends NetworkState {
  NetworkInitial() : super();
}

class NetworkSuccess extends NetworkState {}

class NetworkFailure extends NetworkState {}
