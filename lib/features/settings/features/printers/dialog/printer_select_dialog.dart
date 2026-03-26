import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import '../../../../../changes/providers/printer_select_dialog_provider.dart';
import 'size_of_paper.dart';
import 'add_printer_button.dart';
import 'printers_list.dart';

class PrinterSelectDialog extends StatelessWidget {
  const PrinterSelectDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return ChangeNotifierProvider(
      create: (BuildContext context) => PrinterSelectDialogProvider(),
      child: AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.v),
          side: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
        content: Container(
          height: SizeConfig.v * 80,
          width: SizeConfig.h * 40,
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.h,
            vertical: SizeConfig.v * 2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.printerlar,
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                  fontSize: 2.7,
                ),
              ),
              SizedBox(height: SizeConfig.v * 2),
              const Expanded(child:  PrintersList()),
              const SizeOfPaper(),
              const AddPrinterButton(),
            ],
          ),
        ),
      ),
    );
  }
}
