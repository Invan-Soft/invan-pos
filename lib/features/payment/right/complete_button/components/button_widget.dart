import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:provider/provider.dart';

class ButtonWidget extends StatelessWidget {
  final VoidCallback onPredssed;
  final String title;

  const ButtonWidget({
    Key? key,
    required this.title,
    required this.onPredssed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      disabledColor: Theme.of(context).highlightColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          SizeConfig.v * 1.1,
        ),
      ),
      color: Theme.of(context).primaryColor,
      onPressed: context.watch<OrderingProvider4>().getIsButtonEnabled &&
              context.watch<OrderingProvider4>().paymentsMapAsList.isNotEmpty
          ? onPredssed
          : null,
      child: Text(
        context.watch<OrderingProvider4>().getIsButtonEnabled &&
                context.watch<OrderingProvider4>().paymentsMapAsList.isNotEmpty
            ? title.toUpperCase()
            : "",
        style: MyThemes.txtStyle(
          fontWeight: FontWeight.w700,
          color: MyThemes.textWhiteColor,
          fontSize: 3.5,
        ),
      ),
    );
  }
}

class ButtonWidgetWithWidget extends StatelessWidget {
  final VoidCallback onPredssed;

  const ButtonWidgetWithWidget({
    Key? key,
    required this.onPredssed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      disabledColor: Theme.of(context).highlightColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          SizeConfig.v * 1.1,
        ),
      ),
      color: Theme.of(context).primaryColor,
      onPressed: context.watch<OrderingProvider4>().getIsButtonEnabled
          ? onPredssed
          : null,
      child: context.watch<OrderingProvider4>().getIsButtonEnabled
          ? Icon(Icons.print, size: SizeConfig.h * 3)
          : Text(
              "",
              style: MyThemes.txtStyle(
                fontWeight: FontWeight.w700,
                color: MyThemes.textWhiteColor,
                fontSize: 3.5,
              ),
            ),
    );
  }
}
