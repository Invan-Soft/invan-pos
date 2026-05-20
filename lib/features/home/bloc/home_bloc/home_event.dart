part of 'home_bloc.dart';

@immutable
abstract class HomeEvent {}

class HomeSyncEvent extends HomeEvent {}

class HomeCallInitialEvent extends HomeEvent {}
