import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/bloc/network/simple_connection_file.dart';


part 'network_event.dart';
part 'network_state.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  bool internet = false;
  StreamSubscription? _subscription;

  NetworkBloc()
      : super(
          NetworkInitial(
              // Prefs.getBool(PrefKeys.isDarkMode, true),
              ),
        ) {
    //  on<ModeChangedEvent>(_modeChanged);
    on<NetworkChangedEvent>(_changed);
    on<NetworkNoEvent>(_networkFailed);
  }
  _networkFailed(NetworkNoEvent event, Emitter<NetworkState> emit) async {
    await Future.delayed(const Duration(seconds: 3));
    bool i = await SimpleConnectionChecker.isConnectedToInternet();
    if (i) {
      internet = true;
      emit(NetworkSuccess());
    } else {
      internet = false;
      emit(NetworkFailure());
    }
  }

  _changed(NetworkChangedEvent event, Emitter<NetworkState> emit) {
    if (event.status) {
      internet = true;
      emit(NetworkSuccess());
    } else {
      internet = false;
      emit(NetworkFailure());
    }
  }

  // _modeChanged(ModeChangedEvent event, Emitter<NetworkState> emit) async {
  //   emit(NetworkInitial(event.isDark));
  // }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
