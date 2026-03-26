import 'dart:io';
import 'package:flutter/services.dart';
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/features/file_crud/operations/file_printer_image.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'components/sold_api_components.dart';

class PrintSoldApi {
  static Future<Uint8List> generatePdf57({
    required ReceiptModel4 receiptsCreateGroup,
    required double sdacha,
    Info? incomInfo,
    String? method,
    String? companyName,
    int? copyNumber,
    List<ItemInfo>? itemInfo,
  }) async {
    bool doubleReceipt = Pref.getBool(PrefKeys.doubleReceipt, false);
    int restaranReceiptNo = Pref.getInt(PrefKeys.restaurantReceiptNo, 1);
    double discount = 0;
    const client = null;
    for (int i = 0; i < receiptsCreateGroup.soldItemList.length; i++) {
      for (int n = 0;
          n < receiptsCreateGroup.soldItemList[i].discount.length;
          n++) {
        discount += receiptsCreateGroup.soldItemList[i].discount[n].total;
      }
    }
    File? file = await FilePrinterImage.getPrinterImage();
    pw.MemoryImage? memoryImage;
    try {
      if (file != null) {
        final f = await file.readAsBytes();
        memoryImage = pw.MemoryImage(f);
      }
      // ignore: empty_catches
    } catch (e) {}

    const double mm = PdfPageFormat.mm;

    final data = await rootBundle.load("assets/fonts/calibriregular.ttf");
    final boldData = await rootBundle.load("assets/fonts/calibribold.TTF");

    final myFont = pw.Font.ttf(data);
    final myBoldFont = pw.Font.ttf(boldData);
    final myStyle = pw.TextStyle(font: myFont, fontSize: mm * 3.0);
    final myStyle2 = pw.TextStyle(font: myBoldFont, fontSize: mm * 3.0);

    final myBoldStyle = pw.TextStyle(font: myBoldFont, fontSize: mm * 3.0);
    final myMiniStyle = pw.TextStyle(font: myFont, fontSize: mm * 2.5);
    final crilic = pw.TextStyle(font: myBoldFont, fontSize: mm * 3.4);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(0),
        pageFormat: PdfPageFormat.roll57,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(left: mm * 1, right: mm * 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Center(
                        child: pw.Text('$companyName', style: myBoldStyle),
                      ),
                      companyName == ""
                          ? pw.Center(child: pw.Text(''))
                          : pw.Center(
                              child: pw.Text(
                                'Copy Number $copyNumber',
                              ),
                            )
                    ]),
                memoryImage != null
                    ? SoldApiComponents.buildImage(memoryImage, mm)
                    : pw.SizedBox(),
                if (Pref.getString(PrefKeys.companyNameDialog, "").isNotEmpty)
                  SoldApiComponents.buildCompanyName(myBoldStyle),
                SoldApiComponents.buildAddress(myStyle, myStyle2, mm),
                pw.SizedBox(height: mm * 3),
                SoldApiComponents.buildSoldCheckTop(
                  receipt4: receiptsCreateGroup,
                  myStyle: myStyle,
                  method: method,
                  client: client,
                  info: incomInfo,
                ),
                SoldApiComponents.buildDashes(myStyle),
                SoldApiComponents.buildProductList(
                  receiptsCreateGroup.soldItemList,
                  itemInfo,
                  myBoldStyle,
                  myMiniStyle,
                  crilic,
                ),
                pw.SizedBox(height: mm * 3),
                SoldApiComponents.buildBottom(
                  receiptsCreateGroup,
                  myMiniStyle,
                  myBoldStyle,
                  sdacha,
                  discount,
                ),
                SoldApiComponents.buildDashes(myStyle),
                incomInfo != null
                    ? SoldApiComponents.buildInfoFromIncom(
                        incomReceipt: incomInfo,
                        myStyle: myStyle,
                        client: client,
                      )
                    : pw.SizedBox(),
                // SoldApiComponents.buildPosVersionn(myStyle),
                SoldApiComponents.buildThanks(myBoldStyle),
                // incomInfo?.qrCodeUrl != null
                //     ? SoldApiComponents.buildThanks(myBoldStyle)
                //     : pw.SizedBox(),
                pw.SizedBox(height: 8.0),
                incomInfo == null &&
                        Pref.getBool('enableQrReceipts', false) == true
                    ? pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.SizedBox(
                            height: 32.mm,
                            width: 32.mm,
                            child: pw.BarcodeWidget(
                              data: Pref.getString('setQrUrl', "SorryQrError"),
                              barcode:
                                  pw.Barcode.fromType(pw.BarcodeType.QrCode),
                            ),
                          )
                        ],
                      )
                    : pw.SizedBox(),
                incomInfo != null && incomInfo.qrCodeUrl != null
                    ? pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.SizedBox(
                            height: 32.mm,
                            width: 32.mm,
                            child: pw.BarcodeWidget(
                              data: incomInfo.qrCodeUrl!,
                              barcode:
                                  pw.Barcode.fromType(pw.BarcodeType.QrCode),
                            ),
                          )
                        ],
                      )
                    : pw.SizedBox(),
                doubleReceipt
                    ? pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                            pw.Text("$restaranReceiptNo",
                                style: pw.TextStyle(
                                    font: myBoldFont, fontSize: mm * 26))
                          ])
                    : pw.SizedBox(),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generatePdf80({
    required ReceiptModel4 receiptsCreateGroup,
    required double sdacha,
    Info? incomInfo,
    String? method,
    String? companyName,
    int? copyNumber,
    List<ItemInfo>? itemInfo,
    bool? isTop,
    bool? isCut,
    List<ReceiptModelSoldItem4>? list,
    bool? imageAccess,
    bool? isCopy,
    num? clientBalance,
  }) async {
    bool doubleReceipt = Pref.getBool(PrefKeys.doubleReceipt, false);
    int restaranReceiptNo = Pref.getInt(PrefKeys.restaurantReceiptNo, 1);

    double discount = 0;
    const client = null;
    for (int i = 0; i < receiptsCreateGroup.soldItemList.length; i++) {
      for (int n = 0;
          n < receiptsCreateGroup.soldItemList[i].discount.length;
          n++) {
        discount += (receiptsCreateGroup.soldItemList[i].discount[n].total *
            receiptsCreateGroup.soldItemList[i].value);
      }
    }
    File? file = await FilePrinterImage.getPrinterImage();
    pw.MemoryImage? memoryImage;
    if (imageAccess == null) {
      try {
        if (file != null) {
          final f = await file.readAsBytes();
          memoryImage = pw.MemoryImage(f);
        }
        // ignore: empty_catches
      } catch (e) {}
    }

    const double mm = PdfPageFormat.mm;

    final data = await rootBundle.load(
      "assets/fonts/calibriregular.ttf",
    );
    final boldData = await rootBundle.load(
      "assets/fonts/calibribold.TTF",
    );
    final arial = await rootBundle.load(
      "assets/fonts/arial.TTF",
    );
    final myFont = pw.Font.ttf(data);
    final myArial = pw.Font.ttf(arial);
    final myBoldFont = pw.Font.ttf(boldData);
    final myStyle = pw.TextStyle(font: myFont, fontSize: mm * 3.6);
    final myStyle2 = pw.TextStyle(font: myBoldFont, fontSize: mm * 3.6);
    final myBoldStyle = pw.TextStyle(font: myBoldFont, fontSize: mm * 3.6);
    final myMiniStyle = pw.TextStyle(font: myFont, fontSize: mm * 3);
    final crilic = pw.TextStyle(font: myArial, fontSize: mm * 3.6);
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(0),
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(left: mm * 1, right: mm * 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Center(
                        child: pw.Text('$companyName', style: myBoldStyle),
                      ),
                      companyName == ""
                          ? pw.Center(child: pw.Text(''))
                          : pw.Center(
                              child: pw.Text(
                                'Copy Number $copyNumber',
                              ),
                            )
                    ]),
                isTop != null || isTop == false
                    ? pw.SizedBox()
                    : pw.Column(children: [
                        isCopy != null && isCopy
                            ? pw.Center(
                                child: pw.Text(
                                  'Nusxa',
                                  textAlign: pw.TextAlign.center,
                                  style: myStyle,
                                ),
                              )
                            : pw.SizedBox.shrink(),
                        pw.SizedBox(height: mm * 2),
                        memoryImage != null
                            ? SoldApiComponents.buildImage(memoryImage, mm)
                            : pw.SizedBox(),
                        if (Pref.getString(PrefKeys.companyNameDialog, "")
                            .isNotEmpty)
                          SoldApiComponents.buildCompanyName(myBoldStyle),
                        pw.SizedBox(height: mm * 2),
                        SoldApiComponents.buildAddress(myStyle, myStyle2, mm),
                        pw.SizedBox(height: mm * 2),
                        SoldApiComponents.buildSoldCheckTop(
                          receipt4: receiptsCreateGroup,
                          method: method,
                          myStyle: myStyle,
                          client: client,
                          info: incomInfo,
                          clientBalance: clientBalance,
                        ),
                        SoldApiComponents.buildDashes(myStyle),
                      ]),
                SoldApiComponents.buildProductList(
                  receiptsCreateGroup.soldItemList,
                  itemInfo,
                  myBoldStyle,
                  myMiniStyle,
                  crilic,
                ),
                pw.SizedBox(height: mm * 3),
                isCut != null && isCut
                    ? pw.Column(children: [
                        SoldApiComponents.buildBottom(receiptsCreateGroup,
                            myMiniStyle, myBoldStyle, sdacha, discount,
                            listAll: list),
                        SoldApiComponents.buildDashes(myStyle),
                        incomInfo != null
                            ? SoldApiComponents.buildInfoFromIncom(
                                incomReceipt: incomInfo,
                                myStyle: myStyle,
                                client: client,
                              )
                            : pw.SizedBox(),
                        // SoldApiComponents.buildPosVersionn(myStyle),
                        // incomInfo?.qrCodeUrl != null
                        //     ? SoldApiComponents.buildThanks(myBoldStyle)
                        //     : pw.SizedBox(),
                        SoldApiComponents.buildThanks(myBoldStyle),

                        pw.SizedBox(height: 8.0),
                        incomInfo == null &&
                                Pref.getBool('enableQrReceipts', false) == true
                            ? pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.SizedBox(
                                    height: 32.mm,
                                    width: 32.mm,
                                    child: pw.BarcodeWidget(
                                      data: Pref.getString(
                                          'setQrUrl', "SorryQrError"),
                                      barcode: pw.Barcode.fromType(
                                          pw.BarcodeType.QrCode),
                                    ),
                                  )
                                ],
                              )
                            : pw.SizedBox(),
                        incomInfo != null && incomInfo.qrCodeUrl != null
                            ? pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.SizedBox(
                                    height: 32.mm,
                                    width: 32.mm,
                                    child: pw.BarcodeWidget(
                                      data: incomInfo.qrCodeUrl!,
                                      barcode: pw.Barcode.fromType(
                                          pw.BarcodeType.QrCode),
                                    ),
                                  )
                                ],
                              )
                            : pw.SizedBox(),
                        doubleReceipt
                            ? pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                    pw.Text("$restaranReceiptNo",
                                        style: pw.TextStyle(
                                            font: myBoldFont,
                                            fontSize: mm * 34))
                                  ])
                            : pw.SizedBox(),
                      ])
                    : pw.SizedBox(),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> checkPrinterList() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Text('df');
        },
      ),
    );

    return pdf.save();
  }

// static Future<Uint8List> generatePdfA4({
//   required ReceiptModel4 receiptsCreateGroup,
//   required double sdacha,
//   Info? incomInfo,
//   String? companyName,
//   int? copyNumber,
// }) async {
//   double discount = 0;
//   for (int i = 0; i < receiptsCreateGroup.soldItemList.length; i++) {
//     for (int n = 0;
//         n < receiptsCreateGroup.soldItemList[i].discount.length;
//         n++) {
//       discount += receiptsCreateGroup.soldItemList[i].discount[n].total;
//     }
//   }
//   const double mm = PdfPageFormat.mm;
//   final data = await rootBundle.load(
//     "assets/fonts/calibriregular.ttf",
//   );
//   final boldData = await rootBundle.load(
//     "assets/fonts/calibribold.TTF",
//   );
//   final myFont = pw.Font.ttf(data);
//   final myBoldFont = pw.Font.ttf(boldData);
//   final pdf = pw.Document();
//   pdf.addPage(
//     pw.Page(
//       margin: const pw.EdgeInsets.all(0),
//       pageFormat: PdfPageFormat.a4,
//       build: (context) {
//         return pw.Padding(
//           padding: const pw.EdgeInsets.only(
//             left: mm * 8,
//             right: mm * 8,
//             top: mm * 8,
//           ),
//           child: pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.center,
//             children: [
//               pw.Text(
//                 'Счет-фактура',
//                 style: pw.TextStyle(
//                   font: myBoldFont,
//                   fontSize: mm * 3.3,
//                 ),
//               ),
//               pw.Text(
//                 '№ 377/15 от 10.02.2023',
//                 style: pw.TextStyle(
//                   font: myBoldFont,
//                   fontSize: mm * 3.3,
//                 ),
//               ),
//               pw.Text(
//                 'к договору № 260/10 от 03.01.2023',
//                 style: pw.TextStyle(
//                   font: myBoldFont,
//                   fontSize: mm * 3.3,
//                 ),
//               ),
//               pw.SizedBox(
//                 height: mm * 11,
//               ),
//               SoldApiComponents.buildTitle(
//                 pw.TextStyle(
//                   font: myFont,
//                   fontSize: mm * 2.4,
//                 ),
//                 pw.TextStyle(
//                   font: myFont,
//                   fontSize: mm * 2.4,
//                 ),
//               ),
//               pw.SizedBox(
//                 height: mm * 6,
//               ),
//               SoldApiComponents.buildTableTitle(pw.TextStyle(
//                 font: myBoldFont,
//                 fontSize: mm * 2.3,
//               )),
//               SoldApiComponents.buildTableRow(
//                 pw.TextStyle(
//                   font: myFont,
//                   fontSize: mm * 2.3,
//                 ),
//                 receiptsCreateGroup,
//               ),
//               pw.SizedBox(
//                 height: mm * 5,
//               ),
//               pw.Text(
//                 'Всего к оплате: ${NumericToWords().toWords(receiptsCreateGroup.totalPrice.toInt())} сум 00 тийин . в т. ч. НДС: ${receiptsCreateGroup.totalPrice.toInt()}',
//                 style: pw.TextStyle(
//                   font: myFont,
//                   fontSize: mm * 2.8,
//                 ),
//               ),
//               pw.SizedBox(
//                 height: mm * 4,
//               ),
//               SoldApiComponents.buildSignature(
//                 pw.TextStyle(
//                   font: myFont,
//                   fontSize: mm * 2.7,
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     ),
//   );
//   return pdf.save();
// }
}

extension MM on num {
  get mm => this * PdfPageFormat.mm;
}
