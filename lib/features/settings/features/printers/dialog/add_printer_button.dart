import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import '../../../../../changes/providers/printer_select_dialog_provider.dart';
import 'package:invan2/features/features.dart';

class AddPrinterButton extends StatelessWidget {
  const AddPrinterButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PrinterSelectDialogProvider printerSelectDialogProvider =
        Provider.of<PrinterSelectDialogProvider>(context);
    final int paperSize = printerSelectDialogProvider.getPaperSize;

    final loc = AppLocalizations.of(context)!;

    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      disabledColor: Theme.of(context).primaryColor.withOpacity(.7),
      disabledTextColor: Colors.white,
      color: Theme.of(context).primaryColor,
      minWidth: double.infinity,
      height: SizeConfig.v * 7,
      textColor: Colors.white,
      onPressed: (paperSize == 80 || paperSize == 58 || paperSize == 4)
          ? () async {
              await printerSelectDialogProvider.addPrinterToHive();

              AppNavigation.pop();
            }
          : null,
      child: Text(
        loc.printerQoshish.toUpperCase(),
        style: MyThemes.txtStyle(color: Colors.white),
      ),
    );
  }
}
