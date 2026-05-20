import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';

SnackBar mySnackBar(BuildContext context, {required String msg,int duration=1500}) {
  Radius radius = Radius.circular(SizeConfig.h * 2);
  return SnackBar(
    duration:  Duration(milliseconds: duration),
    margin: EdgeInsets.only(
      bottom: SizeConfig.v * 10,
      right: SizeConfig.v,
      left: SizeConfig.v,
    ),
    backgroundColor: Colors.transparent,
    behavior: SnackBarBehavior.floating,
    elevation: 0,
    content: Container(
      alignment: Alignment.bottomRight,
      child: Container(
        padding: EdgeInsets.only(
          bottom: SizeConfig.h,
          right: SizeConfig.h * 2,
          left: SizeConfig.h * 2,
        ),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              blurStyle: BlurStyle.outer,
              color: Theme.of(context).dividerColor,
            ),
          ],
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: radius,
          ),
        ),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: SizeConfig.v * 4,
            color: MyThemes.textWhiteColor,
          ),
        ),
      ),
    ),
  );
}
