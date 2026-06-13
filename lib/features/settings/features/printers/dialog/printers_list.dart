import 'dart:io';

import 'package:flutter/material.dart';
import 'package:invan2/features/printing/model/printer_model.dart';
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
        final printers = <Printer>[...?snapshot.data];

        // macOS'da real PDF printeri yo'q (Windows'dagi "Microsoft Print to PDF"
        // kabi). Shuning uchun faqat macOS'da soxta "PDF" elementini qo'shamiz.
        // Boshqa platformalarda ro'yxat o'zgarmaydi.
        if (Platform.isMacOS) {
          printers.insert(
            0,
            const Printer(
              url: kPdfExportPrinterUrl,
              name: 'PDF (faylga saqlash)',
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: printers.length,
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
