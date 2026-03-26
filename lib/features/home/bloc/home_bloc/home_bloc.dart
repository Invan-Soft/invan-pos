import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_event.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitialState()) {
    on<HomeSyncEvent>(_sync);
    on<HomeCallInitialEvent>(_callInitial);
  }

  _callInitial(HomeCallInitialEvent event, Emitter<HomeState> emit) {
    emit(HomeInitialState());
  }

  _sync(HomeSyncEvent event, Emitter<HomeState> emit) async {
    emit(HomeSyncState());
  }
}
