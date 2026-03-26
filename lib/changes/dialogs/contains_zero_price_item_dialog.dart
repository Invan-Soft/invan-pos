import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:invan2/widgets/default_button.dart';

import '../providers/ordering_provider_4.dart';

class ContainsZeroPriceItemDialog extends StatefulWidget {
  final OrderingProvider4 provider;
  String? text;
  String? text2;
  bool delete = true;
  bool isFirst = false;
  bool size = true;

  ContainsZeroPriceItemDialog({
    super.key,
    required this.provider,
    this.text,
    this.text2,
    this.size = false,
    this.delete = true,
    this.isFirst = false,
  });

  @override
  State<ContainsZeroPriceItemDialog> createState() =>
      _ContainsZeroPriceItemDialogState();
}

class _ContainsZeroPriceItemDialogState
    extends State<ContainsZeroPriceItemDialog> {
  final TextEditingController controller = TextEditingController();
  bool isWaiting = false;
  bool isOkButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return AlertDialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        width: widget.size ? SizeConfig.h * 45 : SizeConfig.h * 38.96,
        height: widget.size ? SizeConfig.v * 55 : SizeConfig.v * 42.18,
        decoration: BoxDecoration(
          boxShadow: const [BoxShadow(color: Colors.red, blurRadius: 100)],
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
                  widget.text ?? loc.narh_qoyilmagan,
                  textAlign: TextAlign.center,
                  style: MyThemes.txtStyle(
                    color: MyThemes.textWhiteColor,
                    fontSize: widget.size ? 3 : 4,
                  ),
                ),
              ),
            ),
            DefaultButton(
              text: widget.text2 ?? "Ok",
              isButtonEnabled: true,
              onPress: () async {
                if (widget.delete) {
                  widget.provider.removeLastAdded();
                }
                if (widget.isFirst) {
                  widget.provider.setDialogForMark(false);
                }
                await Future.delayed(const Duration(milliseconds: 100));
                AppNavigation.pop();
              },
              deleteButton: true,
            )
          ],
        ),
      ),
    );
  }
}
