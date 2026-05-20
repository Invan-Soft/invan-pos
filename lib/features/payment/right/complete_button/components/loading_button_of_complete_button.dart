
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';

class LoadingWidgetOfCompleteButton extends StatelessWidget {
  const LoadingWidgetOfCompleteButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    SizeConfig.v * 1.1,
                  ),
                  color: Theme.of(context).primaryColor,
                ),
                child: Center(
                  child: CupertinoActivityIndicator(
                    color: MyThemes.textWhiteColor,
                    radius: SizeConfig.v * 3,
                  ),
                ),
            
            );
  }
}
