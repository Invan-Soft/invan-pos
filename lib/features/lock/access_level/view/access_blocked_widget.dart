import 'dart:async';
import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/lock/lock/view/pincode_keyboard_widget.dart';
import 'package:invan2/utils/themes.dart';

class AccessBlocedWidget extends StatefulWidget {
  final int passwordLenth;
  final int remainingSeconds;
  const AccessBlocedWidget(this.passwordLenth, {Key? key, this.remainingSeconds = 30}) : super(key: key);

  @override
  State<AccessBlocedWidget> createState() => _AccessBlocedWidgetState();
}

class _AccessBlocedWidgetState extends State<AccessBlocedWidget> {
  bool isActiv = true;
  late int interval;
  @override
  void initState() {
    interval = widget.remainingSeconds;
    Timer.periodic(const Duration(seconds: 1), (Timer t) => _getCount());
    super.initState();
  }

  @override
  void dispose() {
    isActiv = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Positioned.fill(
            child: PincodeKeyboardWidgetOff(
                passwordLenth: widget.passwordLenth,
                cardPressedd: () {},
                length: 0,
                pressDeleteButton: () {},
                pressNum: (v) {},
                key: const Key("using in access bloced widget"))),
        Positioned.fill(
          child: Container(
            alignment: const Alignment(0.0, 0.93),
            color: MyThemes.darkPrimaryColor.withOpacity(.4),
            child: Text(
              "${loc.kutish_vaqti} 00:${interval.toString().length < 2 ? "0$interval" : "$interval"} ${loc.sek}",
              style: MyThemes.txtStyle(
                color: MyThemes.darkPrimaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _getCount() {
    if (isActiv) {
      setState(() {
        interval--;
      });
    }
  }
}
