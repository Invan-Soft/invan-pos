import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/models/shift/shift_hive_model.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/utils.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../api/print_payment_page_api.dart';
import '../api/print_sold_api.dart';
import '../api/print_smena_api.dart';

class PrintingMethods {
  static Future<void> printSmena({
    required ShiftModelHive shift,
    required AppLocalizations loc,
    required bool isZ,
  }) async {
    final printers =
        HiveBoxes.getPrinters().values.toList().cast<PrinterModel>();

    PrinterModel? selectedPrinterModel;
    Printer? selectPrinter;

    final devices = await Printing.listPrinters();

    // ignore: avoid_function_literals_in_foreach_calls
    printers.forEach((printer) {
      // ignore: avoid_function_literals_in_foreach_calls
      devices.forEach((device) {
        if (device.url == printer.url) {
          selectedPrinterModel = printer;
          selectPrinter = device;
        }
      });
    });

    if (selectPrinter != null && selectedPrinterModel != null) {
      // ignore: unused_local_variable
      final b = await Printing.directPrintPdf(
        printer: selectPrinter!,
        format: selectedPrinterModel!.paperSize == 80
            ? PdfPageFormat.roll80
            : PdfPageFormat.roll57,
        onLayout: (format) {
          if (selectedPrinterModel!.paperSize == 80) {
            return PrintSmenaApi.generatePdf80(shift, loc, isZ);
          } else {
            return PrintSmenaApi.generatePdf57(shift, loc, isZ);
          }
        },
      );
    }
  }

  static Future<void> printPaymentPageCheck({
    required SixClientModel4 clientModel3,
  }) async {
    final printers =
        HiveBoxes.getPrinters().values.toList().cast<PrinterModel>();

    PrinterModel? selectedPrinterModel;
    Printer? selectPrinter;

    final devices = await Printing.listPrinters();

    // ignore: avoid_function_literals_in_foreach_calls
    printers.forEach((printer) {
      // ignore: avoid_function_literals_in_foreach_calls
      devices.forEach((device) {
        if (device.url == printer.url) {
          selectedPrinterModel = printer;
          selectPrinter = device;
        }
      });
    });

    if (selectPrinter != null && selectedPrinterModel != null) {
      // ignore: unused_local_variable
      final b = await Printing.directPrintPdf(
        printer: selectPrinter!,
        format: selectedPrinterModel!.paperSize == 80
            ? PdfPageFormat.roll80
            : PdfPageFormat.roll57,
        onLayout: (format) {
          if (selectedPrinterModel!.paperSize == 80) {
            return PrintPaymentPageApi.generatePdf80(clientModel3);
          } else {
            return PrintPaymentPageApi.generatePdf57(clientModel3);
          }
        },
      );
    }
  }

  static Future<void> printTopCheck() async {
    final printers =
        HiveBoxes.getPrinters().values.toList().cast<PrinterModel>();
    PrinterModel? selectedPrinterModel;
    Printer? selectPrinter;

    final devices = await Printing.listPrinters();
    // ignore: avoid_function_literals_in_foreach_calls
    printers.forEach(
      (printer) {
        // ignore: avoid_function_literals_in_foreach_calls
        devices.forEach(
          (device) {
            if (device.url == printer.url) {
              selectedPrinterModel = printer;
              selectPrinter = device;
            }
          },
        );
      },
    );

    if (selectPrinter != null && selectedPrinterModel != null) {
      await Printing.directPrintPdf(
        usePrinterSettings: true,
        printer: selectPrinter!,
        name: 'documentSpoler',
        format: selectedPrinterModel!.paperSize == 80
            ? PdfPageFormat.roll80
            : PdfPageFormat.roll57,
        onLayout: (format) {
          if (selectedPrinterModel!.paperSize == 80) {
            return PrintPaymentPageApi.generatePdfChecking();
          } else {
            return PrintPaymentPageApi.generatePdfChecking();
          }
        },
      );
    }
  }

/////////Humo recipt
  static Future<void> printHumoRecipts(String text) async {
    final printers =
        HiveBoxes.getPrinters().values.toList().cast<PrinterModel>();
    PrinterModel? selectedPrinterModel;
    Printer? selectPrinter;

    final devices = await Printing.listPrinters();
    // ignore: avoid_function_literals_in_foreach_calls
    printers.forEach(
      (printer) {
        // ignore: avoid_function_literals_in_foreach_calls
        devices.forEach(
          (device) {
            if (device.url == printer.url) {
              selectedPrinterModel = printer;
              selectPrinter = device;
            }
          },
        );
      },
    );

    if (selectPrinter != null && selectedPrinterModel != null) {
      bool doubleRec = Pref.getBool(PrefKeys.doubleHumoReceipt, false);
      int count = 0;
      doubleRec ? count = 2 : count = 1;

      for (int i = 0; i < count; i++) {
        await Printing.directPrintPdf(
          usePrinterSettings: true,
          printer: selectPrinter!,
          format: selectedPrinterModel!.paperSize == 80
              ? PdfPageFormat.roll80
              : PdfPageFormat.roll57,
          onLayout: (format) {
            if (selectedPrinterModel!.paperSize == 80) {
              return PrintPaymentPageApi.generateHumoRecipt(text);
            } else {
              return PrintPaymentPageApi.generateHumoRecipt(text);
            }
          },
        );
      }
    }
  }

  /*static Future<void> printCheck(
    ReceiptModel4 receipt,
    double sdacha, {
    Info? incomInfo,
    String? method,
    List<ItemInfo>? itemInfo,
  }) async {
    final printers =
        HiveBoxes.getPrinters().values.toList().cast<PrinterModel>();
    PrinterModel? selectedPrinterModel;
    Printer? selectPrinter;

    final devices = await Printing.listPrinters();
    // ignore: avoid_function_literals_in_foreach_calls
    printers.forEach(
      (printer) {
        // ignore: avoid_function_literals_in_foreach_calls
        devices.forEach(
          (device) {
            if (device.url == printer.url) {
              selectedPrinterModel = printer;
              selectPrinter = device;
            }
          },
        );
      },
    );

    if (selectPrinter != null && selectedPrinterModel != null) {
      // ignore: unused_local_variable
      int lengthR = Pref.getInt(PrefKeys.companyResipt, 1);
      for (int i = 1; i <= lengthR; i++) {
        await Printing.directPrintPdf(
          usePrinterSettings: true,
          printer: selectPrinter!,
          dynamicLayout: false,
          format: selectedPrinterModel!.paperSize == 80
              ? PdfPageFormat.roll80
              : PdfPageFormat.roll57,
          // selectedPrinterModel!.paperSize == 57
          //     ? PdfPageFormat.roll57
          // : PdfPageFormat.a4,
          onLayout: (format) {
            if (selectedPrinterModel!.paperSize == 80) {
              return PrintSoldApi.generatePdf80(
                receiptsCreateGroup: receipt,
                sdacha: sdacha,
                method: method,
                incomInfo: incomInfo,
                companyName: Pref.getString(PrefKeys.companyNameDialog, ""),
                copyNumber: i,
                itemInfo: itemInfo,
              );
            } else
            // if (selectedPrinterModel!.paperSize == 57)
            {
              return PrintSoldApi.generatePdf57(
                receiptsCreateGroup: receipt,
                sdacha: sdacha,
                method: method,
                companyName: Pref.getString(PrefKeys.companyNameDialog, ""),
                incomInfo: incomInfo,
                itemInfo: itemInfo,
              );
            }
            //  else {
            //   return PrintSoldApi.generatePdfA4(
            //       receiptsCreateGroup: receipt,
            //       sdacha: sdacha,
            //       incomInfo: incomInfo);
            // }
          },
        );
      }
      Pref.removeWithKey(
        PrefKeys.companyResipt,
      );
      Pref.removeWithKey(
        PrefKeys.companyNameDialog,
      );
    }
  }*/

  static Future<void> printCheck(
    ReceiptModel4 receipt,
    double sdacha, {
    Info? incomInfo,
    String? method,
    List<ItemInfo>? itemInfo,
    bool? imageAccess,
    bool? isCopy,
    num? clientBalance,
  }) async {
    if (incomInfo != null &&
        (incomInfo.qrCodeUrl == null || incomInfo.qrCodeUrl == 'null')) {
      incomInfo.qrCodeUrl = receipt.url;
    }
    final printers =
        HiveBoxes.getPrinters().values.toList().cast<PrinterModel>();
    PrinterModel? selectedPrinterModel;
    Printer? selectPrinter;

    final devices = await Printing.listPrinters();
    printers.forEach(
      (printer) {
        devices.forEach(
          (device) {
            if (device.url == printer.url) {
              selectedPrinterModel = printer;
              selectPrinter = device;
            }
          },
        );
      },
    );

    if (selectPrinter != null && selectedPrinterModel != null) {
      int lengthR = Pref.getInt(PrefKeys.companyResipt, 1);

      for (int i = 1; i <= lengthR; i++) {
        int limit = 70;

        if (receipt.soldItemList.length <= limit) {
          await printing(
            selectPrinter!,
            selectedPrinterModel!,
            receipt,
            sdacha,
            incomInfo,
            method,
            itemInfo,
            i,
            isCut: true,
            imageAccess: imageAccess,
            isCopy: isCopy,
            clientBalance: clientBalance,
          );
        } else {
          int l1 = (receipt.soldItemList.length / limit).toInt();
          int l2 = (receipt.soldItemList.length ~/ limit);
          if (l2 > 0) l1++;

          List<ReceiptModelSoldItem4> list = List.from(receipt.soldItemList);

          receipt.soldItemList.clear();
          for (int n = 0; n < limit; n++) {
            receipt.soldItemList.add(list[n]);
          }
          await printing(
            selectPrinter!,
            selectedPrinterModel!,
            receipt,
            sdacha,
            incomInfo,
            method,
            itemInfo,
            i,
            imageAccess: imageAccess,
            isCopy: isCopy,
            clientBalance: clientBalance,
          );

          for (int n = 1; n < (l1 - 1); n++) {
            receipt.soldItemList.clear();
            for (int m = limit * n; m < ((limit * n) + limit); m++) {
              receipt.soldItemList.add(list[m]);
            }
            await printing(
              selectPrinter!,
              selectedPrinterModel!,
              receipt,
              sdacha,
              incomInfo,
              method,
              itemInfo,
              i,
              isTop: false,
              imageAccess: imageAccess,
              isCopy: isCopy,
              clientBalance: clientBalance,
            );
          }

          receipt.soldItemList.clear();
          for (int n = limit * (l1 - 1); n < list.length; n++) {
            receipt.soldItemList.add(list[n]);
          }
          await printing(
            selectPrinter!,
            selectedPrinterModel!,
            receipt,
            sdacha,
            incomInfo,
            method,
            itemInfo,
            i,
            isTop: false,
            isCut: true,
            list: list,
            imageAccess: imageAccess,
            isCopy: isCopy,
            clientBalance: clientBalance,
          );
        }
      }
      Pref.removeWithKey(PrefKeys.companyResipt);
      Pref.removeWithKey(PrefKeys.companyNameDialog);
    }
  }

  static Future<void> printing(
    Printer selectPrinter,
    PrinterModel selectedPrinterModel,
    ReceiptModel4 receipt,
    double sdacha,
    Info? incomInfo,
    String? method,
    List<ItemInfo>? itemInfo,
    int i, {
    bool? isTop,
    bool? isCut,
    List<ReceiptModelSoldItem4>? list,
    bool? imageAccess,
    bool? isCopy,
    num? clientBalance,
  }) async {
    await Printing.directPrintPdf(
      usePrinterSettings: true,
      printer: selectPrinter,
      dynamicLayout: false,
      format: selectedPrinterModel.paperSize == 80
          ? PdfPageFormat.roll80
          : PdfPageFormat.roll57,
      onLayout: (format) async {
        return selectedPrinterModel.paperSize == 80
            ? await PrintSoldApi.generatePdf80(
                receiptsCreateGroup: receipt,
                sdacha: sdacha,
                method: method,
                incomInfo: incomInfo,
                companyName: Pref.getString(PrefKeys.companyNameDialog, ""),
                copyNumber: i,
                itemInfo: itemInfo,
                isCut: isCut != null ? true : null,
                isTop: isTop != null ? false : null,
                list: isCut != null && isCut ? list : null,
                imageAccess: imageAccess,
                isCopy: isCopy,
                clientBalance: clientBalance,
              )
            : await PrintSoldApi.generatePdf57(
                receiptsCreateGroup: receipt,
                sdacha: sdacha,
                method: method,
                companyName: Pref.getString(PrefKeys.companyNameDialog, ""),
                incomInfo: incomInfo,
                itemInfo: itemInfo,
              );
      },
    );
  }

  static Future<void> printTransefer(
    List<ReceiptModelSoldItem4> orderedProducts,
    String customerName,
    String serviceName,
    String driverName,
    String pdfUrl,
    String numberT,
  ) async {
    final printers =
        HiveBoxes.getPrinters().values.toList().cast<PrinterModel>();
    PrinterModel? selectedPrinterModel;
    Printer? selectPrinter;

    final devices = await Printing.listPrinters();
    // ignore: avoid_function_literals_in_foreach_calls
    printers.forEach(
      (printer) {
        // ignore: avoid_function_literals_in_foreach_calls
        devices.forEach(
          (device) {
            if (device.url == printer.url) {
              selectedPrinterModel = printer;
              selectPrinter = device;
            }
          },
        );
      },
    );

    if (selectPrinter != null && selectedPrinterModel != null) {
      await Printing.directPrintPdf(
        usePrinterSettings: true,
        printer: selectPrinter!,
        name: 'documentSpoler',
        format: selectedPrinterModel!.paperSize == 80
            ? PdfPageFormat.roll80
            : PdfPageFormat.roll57,
        onLayout: (format) {
          if (selectedPrinterModel!.paperSize == 80) {
            return PrintPaymentPageApi.transferGeneratePdf80(orderedProducts,
                customerName, serviceName, driverName, pdfUrl, numberT);
          } else {
            return PrintPaymentPageApi.transferGeneratePdf80(orderedProducts,
                customerName, serviceName, driverName, pdfUrl, numberT);
          }
        },
      );
    }
  }
}
