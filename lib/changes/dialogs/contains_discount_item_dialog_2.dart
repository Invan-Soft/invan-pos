import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:invan2/widgets/default_button.dart';

import '../providers/ordering_provider_4.dart';

class ContainsDiscountItemDialog2 extends StatefulWidget {
  final OrderingProvider4 provider;
  String? text;
  bool isFirst = false;

  ContainsDiscountItemDialog2({
    super.key,
    required this.provider,
    this.text,
    this.isFirst = false,
  });

  @override
  State<ContainsDiscountItemDialog2> createState() =>
      _ContainsDiscountItemDialog2State();
}

class _ContainsDiscountItemDialog2State
    extends State<ContainsDiscountItemDialog2> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 2.2,
        height: MediaQuery.of(context).size.height / 1.4,
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.green.shade500, blurRadius: 100)],
          color: MyThemes.darkBackgroundColor,
          borderRadius: BorderRadius.circular(
            SizeConfig.v * 1.1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  widget.text ?? '',
                  textAlign: TextAlign.center,
                  style: MyThemes.txtStyle(
                    color: MyThemes.textWhiteColor,
                    fontSize: 4.5,
                  ),
                ),
              ),
            ),
            DefaultButton(
              text: "Ok",
              isButtonEnabled: true,
              onPress: () async {
                if (widget.isFirst) {
                  widget.provider.setDialogForDiscount(false);
                }
                AppNavigation.pop();
              },
              okButton: true,
            )
          ],
        ),
      ),
    );
  }
}
