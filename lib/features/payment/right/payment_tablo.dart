import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';
import 'package:provider/provider.dart';

class PaymentTablo extends StatelessWidget {
  const PaymentTablo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return SizedBox(
      height: SizeConfig.v * 12,
      child: TextButton(
        focusNode: FocusNode(skipTraversal: true),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.background,
          elevation: 0,
          padding: const EdgeInsets.all(0.0),
        ),
        onPressed: () {
          context.read<OrderingProvider4>().focusNodeListener.requestFocus();
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.v,
          ),
          margin: EdgeInsets.only(bottom: SizeConfig.v * 1.78),
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: BorderRadius.circular(SizeConfig.v * 1.1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.hisoblash,
                style: MyThemes.txtStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 4,
                  color: Theme.of(context).canvasColor,
                ),
              ),
              Text(
                context.watch<OrderingProvider4>().controller.text,
                style: TextStyle(
                  fontSize: SizeConfig.v * 6.2,
                  color: Theme.of(context).canvasColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
