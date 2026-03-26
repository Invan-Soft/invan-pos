import 'package:flutter/material.dart';
import '../../../../utils/utils.dart';

class SettingsReportPageButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  const SettingsReportPageButton(
      {required this.onPressed, required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: SizeConfig.v * 2,
        right: SizeConfig.h,
      ),
      child: SizedBox(
        width: SizeConfig.h * 25,
        height: SizeConfig.v * 14,
        child: ElevatedButton(
          focusNode: FocusNode(skipTraversal: true),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.all(SizeConfig.v * 2),
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SizeConfig.v * 1.5),
            ),
          ),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: MyThemes.txtStyle(
                fontWeight: FontWeight.w600,
                color: MyThemes.textWhiteColor,
                fontSize: 2.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
