import 'dart:io';
import 'package:flutter/services.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/features/file_crud/operations/file_printer_image.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

class PrintPaymentPageApi {
  static Future<Uint8List> generatePdf57(SixClientModel4 client) async {
    File? file = await FilePrinterImage.getPrinterImage();
    final pos = Pref.getString(PrefKeys.posName, "not initialized");
    final cashierName = Pref.getString(PrefKeys.cashierName, "not initialized");
    String checkNo = Pref.getString(PrefKeys.checkId, "");
    checkNo += (Pref.getInt(PrefKeys.receiptNo, 0) + 1).toString();
    const mm = PdfPageFormat.mm;
    final data = await rootBundle.load('assets/fonts/arial.ttf');
    final myFont = Font.ttf(data);
    final myStyle = TextStyle(font: myFont, fontSize: mm * 3);
    final pdf = Document();
    pdf.addPage(
      Page(
        margin: const EdgeInsets.all(0),
        pageFormat: PdfPageFormat.roll57,
        build: (Context context) {
          return Padding(
            padding: const EdgeInsets.only(left: mm * 2, right: mm * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                file != null ? _buildImage(file, mm) : SizedBox(),
                SizedBox(height: mm * 3),
                _buildCompanyName(myStyle),
                _buildAddress(myStyle),
                SizedBox(height: mm * 3),
                _buildTop(myStyle, cashierName, pos, checkNo),
                _buildDashes(myStyle),
                _buildProductList(client, myStyle, mm),
                SizedBox(height: mm * 3),
              ],
            ),
          );
        },
      ),
    );
    return pdf.save();
  }

  static Future<Uint8List> generatePdf80(SixClientModel4 client) async {
    File? file = await FilePrinterImage.getPrinterImage();
    final pos = Pref.getString(PrefKeys.posName, "not initialized");
    final cashierName = Pref.getString(PrefKeys.cashierName, "not initialized");
    String checkNo = Pref.getString(PrefKeys.checkId, "not initialized");
    checkNo += (Pref.getInt(PrefKeys.receiptNo, 0) + 1).toString();
    const double mm = PdfPageFormat.mm;
    final data = await rootBundle.load('assets/fonts/arial.ttf');
    final myFont = Font.ttf(data);
    final myStyle = TextStyle(font: myFont, fontSize: mm * 3.4);
    final pdf = Document();
    pdf.addPage(
      Page(
        margin: const EdgeInsets.all(0),
        pageFormat: PdfPageFormat.roll80,
        build: (Context context) {
          return Padding(
            padding: const EdgeInsets.only(left: mm * 2, right: mm * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                file != null ? _buildImage(file, mm) : SizedBox(),
                SizedBox(height: mm * 3),
                _buildCompanyName(myStyle),
                _buildAddress(myStyle),
                SizedBox(height: mm * 3),
                _buildTop(myStyle, cashierName, pos, checkNo),
                _buildDashes(myStyle),
                _buildProductList(client, myStyle, mm),
                SizedBox(height: mm * 3),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generatePdfChecking() async {
    const double mm = PdfPageFormat.mm;
    final pdf = Document();
    final data = await rootBundle.load('assets/fonts/arial.ttf');
    final myFont = Font.ttf(data);
    // ignore: unused_local_variable
    final myStyle = TextStyle(font: myFont, fontSize: mm * 3.4);
    pdf.addPage(
      Page(
        margin: const EdgeInsets.all(0),
        pageFormat: PdfPageFormat.roll80,
        build: (Context context) {
          return Column(children: [
            Text('.                                                     .'),
            Text('.                                                     .'),
            Text('.                                                     .'),
            Text('.                                                     .'),
            Text('.                                                     .'),
            Text('.                                                     .'),
            Text('.                                                     .'),
            Text('.                                                     .'),
            Text('.                                                     .'),
            Text('.                                                     .'),
            Text('.                                                     .'),
          ]);
        },
      ),
    );

    return pdf.save();
  }

///////////humo recipt generate
  static Future<Uint8List> generateHumoRecipt(String text) async {
    const double mm = PdfPageFormat.mm;
    final pdf = Document();
    final data = await rootBundle.load('assets/fonts/calibriregular.ttf');
    final myFont = Font.ttf(data);
    final myStyle = TextStyle(
        font: myFont, fontSize: mm * 3.4, fontWeight: FontWeight.normal);
    pdf.addPage(
      Page(
        margin: const EdgeInsets.all(0),
        pageFormat: PdfPageFormat.roll80,
        build: (Context context) {
          return Text(text, style: myStyle);
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> transferGeneratePdf80(
      List<ReceiptModelSoldItem4> client,
      String customer,
      String service,
      String driverName,
      String pdfUrl,
      String numberT) async {
    final pos = Pref.getString(PrefKeys.posName, "not initialized");
    final cashierName = Pref.getString(PrefKeys.cashierName, "not initialized");
    const double mm = PdfPageFormat.mm;
    final data = await rootBundle.load('assets/fonts/arial.ttf');
    final dataCaliFont = await rootBundle.load('assets/fonts/calibribold.ttf');
    final myFont = Font.ttf(data);
    final myFontCaliFont = Font.ttf(dataCaliFont);
    final myStyle = TextStyle(font: myFont, fontSize: mm * 3.4);
    final myStyleBold = TextStyle(font: myFontCaliFont, fontSize: mm * 5);
    final pdf = Document();
    pdf.addPage(
      Page(
        margin: const EdgeInsets.all(0),
        pageFormat: PdfPageFormat.roll80,
        build: (Context context) {
          return Padding(
            padding: const EdgeInsets.only(left: mm * 2, right: mm * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: mm * 3),
                _buildTransferNumber(myStyleBold, numberT),
                SizedBox(height: mm * 3),
                _buildTop2(myStyle, cashierName, pos, driverName),
                _buildDashes(myStyle),
                _buildSenderInfo(myStyle, customer, service),
                _buildDashes(myStyle),
                _buildTransferProductTitle(myStyle, mm),
                _buildDashes(myStyle),
                _buildProductList2(client, myStyle, mm),
                _buildDashes(myStyle),
                _buildSignature(myStyle),
                _buildDashes(myStyle),
                SizedBox(height: mm * 3),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: SizedBox(
                          height: mm * 32,
                          width: mm * 32,
                          child: BarcodeWidget(
                            data: pdfUrl,
                            barcode: Barcode.fromType(BarcodeType.QrCode),
                          ),
                        ),
                      )
                    ])
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Widget _buildTransferNumber(TextStyle myStyle, String number) {
    return Center(
      child: Text(
        "Перемещение $number",
        style: myStyle.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  static Widget _buildTop2(
    TextStyle myStyle,
    String cashierName,
    String pos,
    String driver,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Кассир:',
                style: myStyle,
              ),
              Text(
                'ПОС:',
                style: myStyle,
              ),
              Text(
                'Водитель:',
                style: myStyle,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cashierName,
                style: myStyle,
              ),
              Text(
                pos,
                style: myStyle,
              ),
              Text(
                driver,
                style: myStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildSenderInfo(
    TextStyle myStyle,
    String sender1,
    String sender2,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 8,
              child: Text(
                'Отправитель :',
                style: myStyle,
              ),
            ),
            Expanded(
              flex: 10,
              child: Text(
                sender1,
                style: myStyle,
              ),
            )
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 8,
              child: Text(
                'Получатель :',
                style: myStyle,
              ),
            ),
            Expanded(
              flex: 10,
              child: Text(
                sender2,
                style: myStyle,
              ),
            )
          ],
        ),
      ],
    );
  }

  static Widget _buildTransferProductTitle(
    TextStyle myStyle,
    double mm,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            "№",
            style: myStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 9,
          child: Text(
            "Имя",
            style: myStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            "SKU",
            textAlign: TextAlign.right,
            style: myStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "К/во",
            textAlign: TextAlign.right,
            style: myStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: 20),
      ],
    );
  }

  static Widget _buildProductList2(
    List<ReceiptModelSoldItem4> client,
    TextStyle myStyle,
    double mm,
  ) {
    return ListView.builder(
      itemCount: client.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < client.length - 1 ? mm : 0,
          ),
          child: _buildTransferProduct(
            client[index],
            index,
            myStyle,
            mm,
          ),
        );
      },
    );
  }

  static Widget _buildTransferProduct(
    ReceiptModelSoldItem4 soldItem,
    int index,
    TextStyle myStyle,
    double mm,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            (index + 1).toString(),
            style: myStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 9,
          child: Text(
            soldItem.productName,
            style:
                myStyle.copyWith(fontWeight: FontWeight.bold, fontSize: mm * 3),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            soldItem.sku.toString(),
            textAlign: TextAlign.right,
            style: myStyle.copyWith(
                fontWeight: FontWeight.bold, fontSize: mm * 2.5),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            soldItem.value.toString(),
            textAlign: TextAlign.right,
            style: myStyle.copyWith(
                fontWeight: FontWeight.bold, fontSize: mm * 2.5),
          ),
        ),
        SizedBox(width: 20),
      ],
    );
  }

  static Widget _buildSignature(
    TextStyle myStyle,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 18),
              Text(
                'Отправитель :',
                style: myStyle,
              ),
              SizedBox(height: 25),
              Text(
                'Получатель :',
                style: myStyle,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 18),
              Text(
                "___________________",
                style: myStyle,
              ),
              SizedBox(height: 25),
              Text(
                "___________________",
                style: myStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildImage(File file, double mm) {
    return Image(
      MemoryImage(file.readAsBytesSync()),
      alignment: Alignment.center,
      fit: BoxFit.cover,
    );
  }

  static Widget _buildAddress(TextStyle myStyle) {
    final address = Pref.getString(PrefKeys.serviceAddress, 'not initialized');
    if (address != '') {
      return Center(
        child: Text(
          address,
          style: myStyle,
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return SizedBox();
    }
  }

  static Text _buildDashes(TextStyle myStyle) {
    return Text(
      '--------------------------------------'
      '--------------------------------------',
      style: myStyle,
      maxLines: 1,
    );
  }

  static Widget _buildCompanyName(TextStyle myStyle) {
    final companyName = Pref.getString(PrefKeys.storeName, "not initialized");

    return Center(
      child: Text(
        companyName,
        style: myStyle.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  static Widget _buildTop(
    TextStyle myStyle,
    String cashierName,
    String pos,
    String checkNo,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Кассир:',
                style: myStyle,
              ),
              Text(
                'ПОС:',
                style: myStyle,
              ),
              Text(
                'Чек No:',
                style: myStyle,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cashierName,
                style: myStyle,
              ),
              Text(
                pos,
                style: myStyle,
              ),
              Text(
                checkNo,
                style: myStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildProductList(
    SixClientModel4 client,
    TextStyle myStyle,
    double mm,
  ) {
    return ListView.builder(
      itemCount: client.orderedProducts.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < client.orderedProducts.length - 1 ? mm : 0,
          ),
          child: _buildProductItem(
            client.orderedProducts[index],
            myStyle,
            mm,
          ),
        );
      },
    );
  }

  static Widget _buildProductItem(
    ReceiptModelSoldItem4 soldItem,
    TextStyle myStyle,
    double mm,
  ) {
    String value = '';
    if (soldItem.value % 1 == 0) {
      value = soldItem.value.toStringAsFixed(0);
    } else {
      value = soldItem.value.toString();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductInnerItem(
          myStyle.copyWith(fontWeight: FontWeight.bold),
          soldItem.productName,
          (soldItem.value * soldItem.price).toStringAsFixed(2),
        ),
        Text(
          '$value * ${soldItem.price.toStringAsFixed(2)}',
          style: myStyle.copyWith(fontSize: mm * 2.7),
        ),
        _buildProductInnerItem(
          myStyle.copyWith(fontSize: mm * 2.7),
          'В том числе НДС',
          MoneyFormatter.formatVat.format(
            (((soldItem.price * soldItem.value) * soldItem.vatPercent) /
                (100 + soldItem.vatPercent)),
          ),
        ),
      ],
    );
  }

  static Widget _buildProductInnerItem(
    TextStyle myStyle,
    String str1,
    String str2,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(str1, style: myStyle),
        Text(str2, style: myStyle),
      ],
    );
  }
}
