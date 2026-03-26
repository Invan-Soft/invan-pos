import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/lock/access_level/view/access_level_page.dart';

import 'features/lock/access_level/bloc/access/access_bloc.dart';

final user32 = DynamicLibrary.open('user32.dll');
final kernel32 = DynamicLibrary.open('kernel32.dll');

typedef GetLastInputInfoC = Int32 Function(Pointer<LASTINPUTINFO>);
typedef GetLastInputInfoDart = int Function(Pointer<LASTINPUTINFO>);

final getLastInputInfo =
    user32.lookupFunction<GetLastInputInfoC, GetLastInputInfoDart>(
        'GetLastInputInfo');

typedef GetTickCountC = Uint32 Function();

final getTickCount =
    kernel32.lookupFunction<GetTickCountC, int Function()>('GetTickCount');

class LASTINPUTINFO extends Struct {
  @Uint32()
  external int cbSize;
  @Uint32()
  external int dwTime;
}

class IdleService {
  static final IdleService _instance = IdleService._internal();

  factory IdleService() => _instance;

  IdleService._internal();

  Timer? _timer;
  final Duration _checkInterval = const Duration(seconds: 10);
  final Duration _idleTimeout = const Duration(minutes: 10);

  void start(BuildContext context) {
    _timer?.cancel();
    _timer = Timer.periodic(_checkInterval, (_) {
      if (_isIdle()) {
        _goToProdaja(context);
      }
    });
  }

  bool _isIdle() {
    final info = calloc<LASTINPUTINFO>();
    try {
      info.ref.cbSize = sizeOf<LASTINPUTINFO>();
      final result = getLastInputInfo(info);
      final idleTime = result != 0 ? getTickCount() - info.ref.dwTime : 0;
      return idleTime > _idleTimeout.inMilliseconds;
    } finally {
      calloc.free(info);
    }
  }

  void _goToProdaja(BuildContext context) {
    final accessBloc = BlocProvider.of<AccessBloc>(context, listen: false);
    accessBloc.add(AccessSwitchToAccessEvent());
    AppNavigation.pushAndRemoveUntil(AccessLevelPage());
  }

  void dispose() {
    _timer?.cancel();
  }
}
