import 'dart:async';
import 'dart:ffi';
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/lock/access_level/view/access_level_page.dart';

import 'features/lock/access_level/bloc/access/access_bloc.dart';

final DynamicLibrary? user32 =
    Platform.isWindows ? DynamicLibrary.open('user32.dll') : null;
final DynamicLibrary? kernel32 =
    Platform.isWindows ? DynamicLibrary.open('kernel32.dll') : null;
typedef GetLastInputInfoC = Int32 Function(Pointer<LASTINPUTINFO>);
typedef GetLastInputInfoDart = int Function(Pointer<LASTINPUTINFO>);

final int Function(Pointer<LASTINPUTINFO>)? getLastInputInfo = user32
    ?.lookupFunction<GetLastInputInfoC, GetLastInputInfoDart>(
        'GetLastInputInfo');
typedef GetTickCountC = Uint32 Function();

final int Function()? getTickCount =
    kernel32?.lookupFunction<GetTickCountC, int Function()>('GetTickCount');

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

  /// true bo'lsa idle redirect ishlaydi (faqat AccessLevelPage da).
  bool _enabled = false;

  /// AccessLevelPage da turganligini bildiradi.
  bool _isOnLockPage = false;

  /// Yangi flag: Critical auth sahifalarda (PhoneNumber, ChooseStore va h.k.) turganda idle umuman ishlamaydi.
  bool _isOnCriticalAuthPage = false;

  /// Idle redirect ni yoqish (AccessLevelPage.initState da chaqiriladi).
  void enable() {
    _enabled = true;
  }

  /// Idle redirect ni o'chirish (Auth sahifalariga o'tilganda chaqiriladi).
  void disable() {
    _enabled = false;
  }

  /// AccessLevelPage ochilganda.
  void onLockPageEntered() {
    _isOnLockPage = true;
  }

  /// AccessLevelPage yopilganda.
  void onLockPageExited() {
    _isOnLockPage = false;
  }

  /// Critical auth sahifaga kirilganda (PhoneNumberPage, ChooseStorePage va h.k.).
  void onCriticalAuthPageEntered() {
    _isOnCriticalAuthPage = true;
  }

  /// Critical auth sahifadan chiqilganda.
  void onCriticalAuthPageExited() {
    _isOnCriticalAuthPage = false;
  }

  void start(BuildContext context) {
    _timer?.cancel();
    _timer = Timer.periodic(_checkInterval, (_) {
      // Auth sahifalarida hech qachon redirect qilmaymiz
      if (!_enabled) return;

      // Allaqachon AccessLevelPage da turgan bo'lsa
      if (_isOnLockPage) return;

      // YANGI: Critical auth sahifalarda (PhoneNumber, ChooseStore va h.k.) umuman redirect qilmaymiz
      if (_isOnCriticalAuthPage) return;

      if (_isIdle()) {
        _goToProdaja(context);
      }
    });
  }

  bool _isIdle() {
    if (!Platform.isWindows) return false;
    final info = calloc<LASTINPUTINFO>();
    try {
      info.ref.cbSize = sizeOf<LASTINPUTINFO>();
      final result = getLastInputInfo!(info);
      final idleTime = result != 0 ? getTickCount!() - info.ref.dwTime : 0;
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