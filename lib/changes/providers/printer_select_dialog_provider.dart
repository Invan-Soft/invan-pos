import 'package:flutter/material.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:printing/printing.dart';
import 'package:invan2/features/features.dart';

class PrinterSelectDialogProvider extends ChangeNotifier {
  int _paperSize = 0;
  int _selectedPrinter = 0;
  Printer? _printer;
  PrinterModel? _printerModel;

  /* //////////////////////// PROVIDER GETTERS //////////////////////// */

  int get getPaperSize => _paperSize;

  int get getSelectedPrinter => _selectedPrinter;

  /* //////////////////////// PROVIDER METHODS //////////////////////// */

  void selectPrinter(int index, Printer printer) {
    _selectedPrinter = index;
    _printer = printer;

    notifyListeners();
  }

  Future<void> setPaperSize(int paperSize) async {
    if (_printer == null) {
      final list = await Printing.listPrinters();
      _printer = list[0];
    }

    _paperSize = paperSize;

    _printerModel = PrinterModel(
      name: _printer!.name,
      url: _printer!.url,
      model: _printer!.model ?? '',
      location: _printer!.location ?? '',
      comment: _printer!.comment ?? '',
      paperSize: _paperSize,
    );

    notifyListeners();
  }

  Future<void> addPrinterToHive() async {
    final box = HiveBoxes.getPrinters();
    final printers = box.values.toList().cast<PrinterModel>();

    if (!printers.any((element) => element.url == _printerModel!.url)) {
      await box.add(_printerModel!);

      notifyListeners();
    }
  }
}
