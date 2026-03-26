import 'package:flutter/material.dart';
import 'package:invan2/utils/themes.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../../../changes/providers/printer_select_dialog_provider.dart';

class PrintersList extends StatelessWidget {
  const PrintersList({super.key});

  @override
  Widget build(BuildContext context) {
    final PrinterSelectDialogProvider printerSelectDialogProvider =
        Provider.of<PrinterSelectDialogProvider>(context);
    final int selectedPrinter = printerSelectDialogProvider.getSelectedPrinter;

    return FutureBuilder<List<Printer>>(
      initialData:const  [],
      future: Printing.listPrinters(),
      builder: (BuildContext context, AsyncSnapshot<List<Printer>> snapshot) {
        final printers = snapshot.data;

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: printers!.length,
          itemBuilder: (context, index) {
            Printer printer = printers[index];

            return ListTile(
              onTap: () {
                printerSelectDialogProvider.selectPrinter(index, printer);
              },
              hoverColor: Theme.of(context).primaryColor.withOpacity(.4),
              selected: selectedPrinter == index,
              selectedTileColor: Theme.of(context).primaryColor,
              title: Text(
                printer.name,
                style: MyThemes.txtStyle(
                  color: selectedPrinter == index ? Colors.white :Theme.of(context).dividerColor,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
