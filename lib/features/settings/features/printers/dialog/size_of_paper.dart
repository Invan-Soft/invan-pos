import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import '../../../../../changes/providers/printer_select_dialog_provider.dart';

class SizeOfPaper extends StatelessWidget {
  const SizeOfPaper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final PrinterSelectDialogProvider printerSelectDialogProvider =
        Provider.of<PrinterSelectDialogProvider>(context);
    final int paperSize = printerSelectDialogProvider.getPaperSize;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.qogozOlchami,
          style: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
        ),
        SizedBox(height: SizeConfig.v * 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FilterChip(
              checkmarkColor: Colors.white,
              selectedColor: Theme.of(context).primaryColor,
              disabledColor: Theme.of(context).primaryColor.withOpacity(.3),
              shadowColor: Colors.transparent,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(.3),
              onSelected: (v) {
                printerSelectDialogProvider.setPaperSize(80);
              },
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.h * 1.5,
                vertical: SizeConfig.v * 1.5,
              ),
              label: Text(
                '80',
                style: _style(paperSize == 80, context),
              ),
              selected: paperSize == 80,
            ),
            SizedBox(width: SizeConfig.h * 2),
            FilterChip(
              checkmarkColor: Colors.white,
              selectedColor: Theme.of(context).primaryColor,
              disabledColor: Theme.of(context).primaryColor.withOpacity(.3),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(.3),
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.h * 1.5,
                vertical: SizeConfig.v * 1.5,
              ),
              onSelected: (v) {
                printerSelectDialogProvider.setPaperSize(58);
              },
              label: Text(
                '58',
                style: _style(paperSize == 58, context),
              ),
              selected: paperSize == 58,
            ),
            // SizedBox(width: SizeConfig.h * 2),
            // FilterChip(
            //   checkmarkColor: Colors.white,
            //   selectedColor: Theme.of(context).primaryColor,
            //   disabledColor: Theme.of(context).primaryColor.withOpacity(.3),
            //   backgroundColor: Theme.of(context).primaryColor.withOpacity(.3),
            //   shadowColor: Colors.transparent,
            //   padding: EdgeInsets.symmetric(
            //     horizontal: SizeConfig.h * 1.5,
            //     vertical: SizeConfig.v * 1.5,
            //   ),
            //   onSelected: (v) {
            //     printerSelectDialogProvider.setPaperSize(4);
            //   },
            //   label: Text(
            //     'A4',
            //     style: _style(paperSize == 4, context),
            //   ),
            //   selected: paperSize == 4,
            // ),
          ],
        ),
        SizedBox(height: SizeConfig.v * 4),
      ],
    );
  }

  TextStyle _style(bool isSelected, BuildContext con) {
    return MyThemes.txtStyle(
      color: isSelected ? Colors.white : MyThemes.textWhiteColor,
    );
  }
}
