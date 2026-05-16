import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';

typedef MyBarcodeScannedCallback = void Function(String barcode);

typedef OnDeLPressedCallback = void Function();

typedef OnHomePressedCallback = void Function();
typedef Onf1PressedCallback = void Function();

typedef Onf2PressedCallback = void Function();

typedef Onf3PressedCallback = void Function();
typedef OnUpPressedCallback = void Function();
typedef OnDownPressedCallback = void Function();

typedef OnF12PressedCallback = void Function();
typedef OnShiftDeletePressedCallback = void Function();

const int _lineFeed = 10;

class MyBarcodeListener extends StatefulWidget {
  const MyBarcodeListener(
      {super.key,
      required this.child,
      required Function(String) onBarcodeScannedClick,
      required Function(String) onBarcodeScannedClient,
      required Function(String) onBarcodeScannedMagnetic,
      required Function(String) onBarcodeScannedPayme,
      required Function(String) onBarcodeScanned,
      required Duration bufferDuration,
      required Function() onF5pressed,
      required Function() onF1pressed,
      required Function() onF2pressed,
      required Function() onF3pressed,
      required Function() onDelPressed,
      required Function() onF12Pressed,
      required Function() onUpPressed,
      required Function() onDownPressed,
      required Function() onShiftDeletePressed})
      : _onBarcodeScannedClick = onBarcodeScannedClick,
        _onBarcodeScannedClient = onBarcodeScannedClient,
        _onBarcodeScannedMagnetic = onBarcodeScannedMagnetic,
        _onBarcodeScannedPayme = onBarcodeScannedPayme,
        _onBarcodeScanned = onBarcodeScanned,
        _bufferDuration = bufferDuration,
        _onF5pressed = onF5pressed,
        _onF1pressed = onF1pressed,
        _onF2pressed = onF2pressed,
        _onF3pressed = onF3pressed,
        _onUpPressed = onUpPressed,
        _onDownPressed = onDownPressed,
        _onDelPressed = onDelPressed,
        _onF12Pressed = onF12Pressed,
        _onShiftDeletePressed = onShiftDeletePressed;

  final Widget child;

  final MyBarcodeScannedCallback _onBarcodeScanned;
  final MyBarcodeScannedCallback _onBarcodeScannedClick;
  final MyBarcodeScannedCallback _onBarcodeScannedClient;

  final MyBarcodeScannedCallback _onBarcodeScannedMagnetic;
  final MyBarcodeScannedCallback _onBarcodeScannedPayme;
  final Duration _bufferDuration;
  final OnDeLPressedCallback _onDelPressed;
  final OnHomePressedCallback _onF5pressed;
  final Onf1PressedCallback _onF1pressed;
  final Onf2PressedCallback _onF2pressed;
  final Onf3PressedCallback _onF3pressed;
  final Onf3PressedCallback _onUpPressed;

  final Onf3PressedCallback _onDownPressed;

  final OnF12PressedCallback _onF12Pressed;
  final OnShiftDeletePressedCallback _onShiftDeletePressed;

  @override
  // ignore: no_logic_in_create_state
  MyBarcodeListenerState createState() => MyBarcodeListenerState(
        _onBarcodeScanned,
        _onBarcodeScannedClick,
        _onBarcodeScannedClient,
        _onBarcodeScannedMagnetic,
        _onBarcodeScannedPayme,
        _bufferDuration,
        _onDelPressed,
        _onF5pressed,
        _onF1pressed,
        _onF2pressed,
        _onF3pressed,
        _onDownPressed,
        _onUpPressed,
        _onF12Pressed,
        _onShiftDeletePressed,
      );
}

class MyBarcodeListenerState extends State<MyBarcodeListener> {
  MyBarcodeListenerState(
    this._onBarcodeScannedCallback,
    this._onBarcodeScannedClickCallback,
    this._onBarcodeScannedClientCallback,
    this._onBarcodeScannedMagneticCallback,
    this._onBarcodeScannedPaymeCallback,
    this._bufferDuration,
    this._onDeLPressedCallback,
    this._onF5PressedCallback,
    this._onF1PressedCallback,
    this._onF2PressedCallback,
    this._onF3PressedCallback,
    this._onDownPressedCallback,
    this._onUpPressedCallback,
    this._onF12PressedCallback,
    this._onShiftDeletePressedCallback,
  ) {
    RawKeyboard.instance.addListener(_keyboardCallback);
    _keyboardSubscription = _controller.stream.listen(onKeyEvent);
  }

  final MyBarcodeScannedCallback _onBarcodeScannedCallback;
  final MyBarcodeScannedCallback _onBarcodeScannedClickCallback;
  final MyBarcodeScannedCallback _onBarcodeScannedClientCallback;

  final MyBarcodeScannedCallback _onBarcodeScannedMagneticCallback;
  final MyBarcodeScannedCallback _onBarcodeScannedPaymeCallback;
  final Duration _bufferDuration;
  final OnDeLPressedCallback _onDeLPressedCallback;
  final OnHomePressedCallback _onF5PressedCallback;
  final Onf1PressedCallback _onF1PressedCallback;
  final Onf2PressedCallback _onF2PressedCallback;
  final Onf3PressedCallback _onF3PressedCallback;
  final OnF12PressedCallback _onF12PressedCallback;
  final OnDownPressedCallback _onDownPressedCallback;
  final OnUpPressedCallback _onUpPressedCallback;
  final OnShiftDeletePressedCallback _onShiftDeletePressedCallback;

  List<int> _scannedCharCodes = [];

  DateTime? _lastScannedCharCodeTime;

  StreamSubscription<int>? _keyboardSubscription;

  final _controller = StreamController<int>();

  bool isShiftPressed = false;
  late BlBloc blBloc;

  @override
  Widget build(BuildContext context) {
    blBloc = BlocProvider.of(context);
    return BlocBuilder<BlBloc, BlState>(
      builder: (context, state) {
        return widget.child;
      },
    );
  }

  @override
  void dispose() {
    _keyboardSubscription?.cancel();
    _controller.close();
    RawKeyboard.instance.removeListener(_keyboardCallback);
    super.dispose();
  }

  //---------------------------------

  DateTime lastEnter = DateTime.now();
String fixKeyboardLayout(String input) {
  if (input.isEmpty) return input;

  // To'liq ЙЦУКЕН → QWERTY keyboard layout mapping
  const Map<String, String> ruToEn = {
    'й': 'q', 'ц': 'w', 'у': 'e', 'к': 'r', 'е': 't', 'н': 'y', 'г': 'u',
    'ш': 'i', 'щ': 'o', 'з': 'p', 'х': '[', 'ъ': ']',
    'ф': 'a', 'ы': 's', 'в': 'd', 'а': 'f', 'п': 'g', 'р': 'h',
    'о': 'j', 'л': 'k', 'д': 'l', 'ж': ';', 'э': "'",
    'я': 'z', 'ч': 'x', 'с': 'c', 'м': 'v', 'и': 'b', 'т': 'n',
    'ь': 'm', 'б': ',', 'ю': '.',
    'Й': 'Q', 'Ц': 'W', 'У': 'E', 'К': 'R', 'Е': 'T', 'Н': 'Y', 'Г': 'U',
    'Ш': 'I', 'Щ': 'O', 'З': 'P', 'Х': '{', 'Ъ': '}',
    'Ф': 'A', 'Ы': 'S', 'В': 'D', 'А': 'F', 'П': 'G', 'Р': 'H',
    'О': 'J', 'Л': 'K', 'Д': 'L', 'Ж': ':', 'Э': '"',
    'Я': 'Z', 'Ч': 'X', 'С': 'C', 'М': 'V', 'И': 'B', 'Т': 'N',
    'Ь': 'M', 'Б': '<', 'Ю': '>',
    'ё': '`', 'Ё': '~',
  };

  String result = input;
  ruToEn.forEach((rus, eng) {
    result = result.replaceAll(rus, eng);
  });
  return result;
}
 
  void onKeyEvent(int charCode) {
    if (!(blBloc.isVisible && blBloc.status != BLStatus.other)) {
      return;
    }

    checkPendingCharCodesToClear();
    _lastScannedCharCodeTime = DateTime.now();

    if (charCode == _lineFeed) {
      String scanned = String.fromCharCodes(_scannedCharCodes);
        scanned = fixKeyboardLayout(scanned.trim());

      final now = DateTime.now();
      if ((now.millisecondsSinceEpoch - lastEnter.millisecondsSinceEpoch) >
          300) {
        switch (blBloc.status) {
          case BLStatus.home:
            _onBarcodeScannedCallback.call(scanned);
            break;
          case BLStatus.click:
            _onBarcodeScannedClickCallback(scanned);
            break;
          case BLStatus.client:
            _onBarcodeScannedClientCallback(scanned);
            break;
          case BLStatus.payme:
            _onBarcodeScannedPaymeCallback(scanned);
            break;
          case BLStatus.magneticStripe:
            _onBarcodeScannedMagneticCallback(scanned);
            break;
          case BLStatus.uzum:
            break;
          case BLStatus.other:
            return;
        }
      }

      resetScannedCharCodes();
      lastEnter = now;
      return;
    }

    _scannedCharCodes.add(charCode);
  }

  void checkPendingCharCodesToClear() {
    if (_lastScannedCharCodeTime == null) return;
    if (_lastScannedCharCodeTime!
        .isBefore(DateTime.now().subtract(_bufferDuration))) {
      resetScannedCharCodes();
      return;
    }
  }

  void resetScannedCharCodes() {
    _scannedCharCodes = [];
  }

  void addScannedCharCode(int charCode) {
    _scannedCharCodes.add(charCode);
  }

  void _keyboardCallback(RawKeyEvent keyEvent) {
    if (!(blBloc.isVisible && blBloc.status != BLStatus.other)) return;

    if (keyEvent is RawKeyDownEvent) {
      if (keyEvent.logicalKey == LogicalKeyboardKey.enter) {
        _controller.sink.add(_lineFeed);
      } else if (keyEvent.logicalKey == LogicalKeyboardKey.backspace &&
          blBloc.status == BLStatus.home) {
        _onDeLPressedCallback();
      } else {
        final String? char = keyEvent.character;
        if (char != null && char.isNotEmpty) {
          final int code = char.codeUnitAt(0);
          _controller.sink.add(code);
        }
      }
    }
  }
}

