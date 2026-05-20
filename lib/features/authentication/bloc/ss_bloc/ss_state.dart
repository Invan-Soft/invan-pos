part of 'ss_bloc.dart';
// means Select Storage 
abstract class SsState {}

class SsInitial extends SsState {
  List<StoresModel> stores;
  StoresModel selectedStore;
  SsInitial({
    required this.selectedStore,
    required this.stores,
  });
}

class SsLoadingState extends SsState {
  final String message;
  SsLoadingState(this.message);
}

class SsLoadingFailedState extends SsState {
  final String message;
  SsLoadingFailedState(this.message);
}
