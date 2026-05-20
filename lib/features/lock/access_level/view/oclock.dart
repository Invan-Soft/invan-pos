import 'dart:async';

import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';

class OclockWidget extends StatefulWidget {
  const OclockWidget({
    super.key,
  });

  @override
  OclockWidgetState createState() => OclockWidgetState();
}

class OclockWidgetState extends State<OclockWidget> {
  bool isActiv = true;
  DateTime? _time;

  @override
  void initState() {
    _time = DateTime.now();
    Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _timeBox(
            _time!.hour < 10 ? "0${_time!.hour}" : "${_time!.hour}", loc.soat),
       
        _timeBox(_time!.minute < 10 ? "0${_time!.minute}" : "${_time!.minute}",
            loc.min),
        _timeBox(_time!.second < 10 ? "0${_time!.second}" : "${_time!.second}",
            loc.sek),
      ],
    );
  }

  void _getTime() {
    if (isActiv) {
      final DateTime now = DateTime.now();
      setState(() {
        _time = now;
      });
    }
  }

  Container _timeBox(String time, String title) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        color: MyThemes.lightGreyColorr,
      ),
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.v*2,vertical: SizeConfig.v),
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.h * .8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            time,
            style: MyThemes.txtStyle(
              fontSize: 3.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            title,
            style: MyThemes.txtStyle(
              fontSize: 1.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xff676767),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    isActiv = false;
    super.dispose();
  }
}
