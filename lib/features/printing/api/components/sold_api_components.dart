// ignore_for_file: unused_local_variable
import 'dart:math';
import 'package:invan2/changes/models/client_model.dart';
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/models/product_discount_model.dart';
import 'package:invan2/changes/services/app_constants.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:invan2/utils/utils.dart';
import '../printing_api_helper.dart';

class SoldApiComponents {
  static pw.Widget buildDashes(pw.TextStyle myStyle) {
    return pw.Text(
      "------" * 20,
      style: myStyle,
      maxLines: 1,
    );
  }

  static pw.Widget buildImage(pw.MemoryImage memoryImage, double mm) {
    return pw.Center(
      child: pw.Image(
        memoryImage,
        alignment: pw.Alignment.center,
        height: mm * 35,
      ),
    );
  }

  static pw.Widget buildAddress(
      pw.TextStyle myStyle, pw.TextStyle myStyle2, double mm) {
    final address = Pref.getString(PrefKeys.storeAddress, "not initialized");
    final name = Pref.getString(PrefKeys.comName, "");
    final numberPhone = Pref.getString(PrefKeys.storePhoneNum, "");

    return pw.Column(children: [
      Pref.getBool(PrefKeys.storeNameRD, true)
          ? pw.Center(
              child: pw.Text(
                name,
                textAlign: pw.TextAlign.center,
                style: myStyle2,
              ),
            )
          : pw.SizedBox.shrink(),
      pw.SizedBox(
        height: mm * 2,
      ),
      Pref.getBool(PrefKeys.storeAddressRD, true)
          ? pw.Center(
              child: pw.Text(
                address,
                textAlign: pw.TextAlign.center,
                style: myStyle,
              ),
            )
          : pw.SizedBox.shrink(),
      pw.SizedBox(
        height: mm * 1,
      ),
      Pref.getBool(PrefKeys.phoneNumberRD, true)
          ? pw.Center(
              child: pw.Text(
                '+$numberPhone',
                textAlign: pw.TextAlign.center,
                style: myStyle,
              ),
            )
          : pw.SizedBox.shrink(),
    ]);
  }

  static pw.Widget buildPosVersionn(pw.TextStyle myStyle) {
    final version = AppConstants.version;

    return pw.Align(
        alignment: const pw.Alignment(1, 0.0),
        child: pw.Text(
          "Versiya:   $version",
          style: myStyle,
        ));
  }

  static pw.Widget buildCompanyName(pw.TextStyle myBoldStyle) {
    final companyName =
        Pref.getString(PrefKeys.organizationName, "not initialized");

    return pw.Center(
      child: pw.Text(
        companyName,
        textAlign: pw.TextAlign.center,
        style: myBoldStyle,
      ),
    );
  }

  static pw.Widget buildSoldCheckTop({
    required ReceiptModel4 receipt4,
    required String? method,
    required pw.TextStyle myStyle,
    required ClientModel? client,
    required Info? info,
    num? clientBalance,
  }) {
    bool ofd = Pref.getBool(PrefKeys.withOFD, false);
    final pos = Pref.getString(PrefKeys.posName, "not initialized");
    final cashierName = Pref.getString(PrefKeys.cashierName, "not initialized");
    final stir = Pref.getString(PrefKeys.organizationINN, "not initialized");
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: [
        ofd
            ? pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Text(
                    "STIR: ",
                    style: myStyle,
                  ),
                  pw.Text(
                    stir,
                    style: myStyle,
                  ),
                ],
              )
            : pw.SizedBox(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            Pref.getBool(PrefKeys.transactionRD, true)
                ? pw.Text(
                    receipt4.isRefund
                        ? "Chek №:  ${receipt4.externalId} (Qaytarish)"
                        : "Chek №:  ${receipt4.externalId}",
                    style: myStyle,
                  )
                : pw.Text(""),
            Pref.getBool(PrefKeys.dateRD, true)
                ? pw.Text(
                    MyTimeStringHelper.getDayMonthYearWithSlash(
                      date: DateTime.fromMillisecondsSinceEpoch(receipt4.date),
                    ),
                    style: myStyle,
                  )
                : pw.Text(''),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            Pref.getBool(PrefKeys.cashierRD, true)
                ? pw.Text("Sotuvchi:   $cashierName", style: myStyle)
                : pw.Text(""),
            Pref.getBool(PrefKeys.dateRD, true)
                ? pw.Text(
                    MyTimeStringHelper.getHourMinute(
                        time: info != null
                            ? MyTimeStringHelper.toDateFromString(
                                info.dateTime!)
                            : DateTime.now()),
                    style: myStyle,
                  )
                : pw.Text(''),
          ],
        ),
        receipt4.clientName != "" && Pref.getBool(PrefKeys.customerRD, true)
            ? pw.Text(
                "Xaridor:   ${receipt4.clientName}",
                style: myStyle,
              )
            : pw.SizedBox(),
        clientBalance != null && Pref.getBool(PrefKeys.customerRD, true)
            ? pw.Text(
                "Xaridor balansi:   ${MoneyFormatter.inputMoneyFormatter.format(clientBalance)} so\'m",
                style: myStyle,
              )
            : pw.SizedBox(),
        pw.Text("Kassa:   $pos", style: myStyle),
        method == 'Api.SendAdvanceReceipt'
            ? pw.Text("Sotuv turi:   Bo`nak", style: myStyle)
            : method == 'Api.SendCreditReceipt'
                ? pw.Text("Sotuv turi:   Kredit", style: myStyle)
                : receipt4.isRefund
                    ? pw.Text("Sotuv turi:   Qaytarish", style: myStyle)
                    : pw.Text("Sotuv turi:   Sotuv", style: myStyle),
        pw.Builder(builder: (_) {
          if (client == null) {
            return pw.SizedBox();
          } else {
            String name = "";
            name += client.firstName ?? "-";
            name += " ${client.lastName ?? ""}";
            return pw.Text(name, style: myStyle);
          }
        }),
      ],
    );
  }

  static pw.Widget buildInfoFromIncom({
    required Info incomReceipt,
    required pw.TextStyle myStyle,
    required ClientModel? client,
  }) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "TERMINAL ID",
              style: myStyle,
            ),
            pw.Text(
              incomReceipt.terminalId.toString(),
              style: myStyle,
            ),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("FISKAL BELGI: ", style: myStyle),
            pw.Text(
                incomReceipt.fiscalSign != null
                    ? incomReceipt.fiscalSign.toString()
                    : "",
                style: myStyle),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("CHEK RAQAMI", style: myStyle),
            pw.Text(
                incomReceipt.receiptSeq != null
                    ? incomReceipt.receiptSeq.toString()
                    : "",
                style: myStyle),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("SERIYA RAQAM", style: myStyle),
            pw.Text(Pref.getString(PrefKeys.serialNumber, ""), style: myStyle),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("VERSIYA RAQAM", style: myStyle),
            pw.Text('1.0.8', style: myStyle),
          ],
        ),
        buildDashes(myStyle)
      ],
    );
  }

  static pw.Widget buildProductList(
    List<ReceiptModelSoldItem4> soldItems,
    List<ItemInfo>? itemInfo,
    pw.TextStyle myBoldStyle,
    pw.TextStyle myMiniStyle,
    pw.TextStyle crilic,
  ) {
    return pw.ListView(
      children: soldItems.map((item) {
        return buildProduct(
          item,
          itemInfo,
          myBoldStyle,
          myMiniStyle,
          crilic,
        );
      }).toList(),
    );
  }

  static pw.Widget buildProduct(
    ReceiptModelSoldItem4 soldItem,
    List<ItemInfo>? itemInfo,
    pw.TextStyle myBoldStyle,
    pw.TextStyle myMiniStyle,
    pw.TextStyle crilic,
  ) {
    String barcode = "";
    String sku = "";
    String mxik = "";

    String packageName = "";
    dynamic oldPrice = soldItem.onlyPrice;

    bool ofd = Pref.getBool(PrefKeys.withOFD, false);
    if (ofd) {
      itemInfo?.forEach((element) {
        if (soldItem.productId == element.id) {
          barcode = element.barcode ?? '';
          mxik = element.mxikCode ?? '';
          sku = soldItem.sku.toString();
          packageName = element.packageName ?? '';
        } else {
          barcode = soldItem.barcode;
          mxik = soldItem.mxik;
          sku = soldItem.sku.toString();
          packageName = soldItem.packageName ?? "";
        }
      });
    } else {
      sku = soldItem.sku.toString();
      barcode = soldItem.barcode;
      mxik = soldItem.mxik;
      packageName = soldItem.packageName ?? "";
    }

    if (mxik.isEmpty) {
      mxik = soldItem.mxik;
    }
    String value = '';
    if (soldItem.value % 1 == 0) {
      value = soldItem.value.toStringAsFixed(0);
    } else {
      value = soldItem.value.toString();
    }

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            soldItem.productName.length > 20
                ? pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      soldItem.productName,
                      style: myBoldStyle,
                    ),
                  )
                : pw.Text(
                    soldItem.productName,
                    style: myBoldStyle,
                  ),
            soldItem.productName.length > 20
                ? pw.Expanded(
                    flex: 2,
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        soldItem.price == oldPrice
                            ? pw.Text(MoneyFormatter.formatVat.format(oldPrice),
                                style: myMiniStyle,
                                textAlign: pw.TextAlign.center)
                            : pw.Column(children: [
                                pw.Stack(
                                  alignment: pw.Alignment.center,
                                  children: [
                                    pw.Text(
                                        MoneyFormatter.formatVat
                                            .format(oldPrice),
                                        style: myMiniStyle,
                                        textAlign: pw.TextAlign.center),
                                    pw.Container(
                                      height: 0.5,
                                      width: oldPrice.toString().length * 4.5,
                                      color: PdfColor.fromHex("#000"),
                                    )
                                  ],
                                ),
                                pw.SizedBox(width: 8),
                                pw.Text(
                                    MoneyFormatter.formatVat
                                        .format(soldItem.price),
                                    style: myMiniStyle,
                                    textAlign: pw.TextAlign.center),
                              ]),
                      ],
                    ),
                  )
                : soldItem.price.toStringAsFixed(2) ==
                        oldPrice.toStringAsFixed(2)
                    ? pw.Text(MoneyFormatter.formatVat.format(oldPrice),
                        style: myMiniStyle, textAlign: pw.TextAlign.center)
                    : pw.Row(children: [
                        pw.Stack(
                          alignment: pw.Alignment.center,
                          children: [
                            pw.Text(MoneyFormatter.formatVat.format(oldPrice),
                                style: myMiniStyle,
                                textAlign: pw.TextAlign.center),
                            pw.Container(
                              height: 0.5,
                              width: oldPrice.toString().length * 4.5,
                              color: PdfColor.fromHex("#000"),
                            )
                          ],
                        ),
                        pw.SizedBox(width: 6),
                        pw.Text(MoneyFormatter.formatVat.format(soldItem.price),
                            style: myMiniStyle, textAlign: pw.TextAlign.center)
                      ]),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "     Jami:",
              style: myMiniStyle,
            ),
            pw.Text(
              "$value*${MoneyFormatter.formatter.format(soldItem.price)}"
              " = "
              "${MoneyFormatter.formatter.format(soldItem.value * soldItem.price)}",
              style: myMiniStyle,
              textAlign: pw.TextAlign.right,
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "     sh.j QQS ${soldItem.vatPercent.toStringAsFixed(0)}%",
              style: myMiniStyle,
            ),
            pw.Text(
              MoneyFormatter.formatVat.format(
                  ((soldItem.price * soldItem.value) * soldItem.vatPercent) /
                      (100 + soldItem.vatPercent)),
              style: myMiniStyle,
            ),
          ],
        ),
        oldPrice - soldItem.price == 0
            ? pw.SizedBox(height: 0)
            : pw.SizedBox(height: 2),
        oldPrice - soldItem.price > 0
            ? pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "     Chegirma:",
                    style: myMiniStyle,
                  ),
                  pw.Text(
                    MoneyFormatter.formatVat
                        .format(soldItem.value * (oldPrice - soldItem.price)),
                    style: myMiniStyle,
                  ),
                ],
              )
            : pw.Text(''),
        soldItem.productDiscount.isNotEmpty
            ? pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      "     Chegirmalar:",
                      style: myMiniStyle,
                    ),
                  ),
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        for (ProductDiscountModel p in soldItem.productDiscount)
                          pw.Text(
                            p.name,
                            style: myMiniStyle,
                          ),
                      ],
                    ),
                  ),
                ],
              )
            : pw.Text(''),
        pw.SizedBox(height: 2),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "     Sku/Mxik",
              style: myMiniStyle,
            ),
            pw.Text(
              sku.isEmpty && mxik.isEmpty
                  ? "-/-"
                  : sku.isNotEmpty && mxik.isNotEmpty
                      ? "$sku/$mxik"
                      : sku.isNotEmpty && mxik.isEmpty
                          ? sku
                          : mxik,
              style: myMiniStyle,
            ),
          ],
        ),
        // pw.Row(
        //   crossAxisAlignment: pw.CrossAxisAlignment.start,
        //   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        //   children: [
        //     pw.Text(
        //       "     Mxik",
        //       style: myMiniStyle,
        //     ),
        //     pw.Text(
        //       // soldItem.mxik,
        //       mxik,
        //       style: myMiniStyle,
        //     ),
        //   ],
        // ),
        // pw.Row(
        //   crossAxisAlignment: pw.CrossAxisAlignment.start,
        //   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        //   children: [
        //     pw.Text(
        //       "     O'lchov birligi",
        //       style: myMiniStyle,
        //     ),
        //     pw.SizedBox(
        //       width: 120,
        //       child: pw.Text(
        //         soldItem.packageName ?? "",
        //         textAlign: pw.TextAlign.right,
        //         style: crilic,
        //       ),
        //     )
        //   ],
        // ),
        // soldItem.tin != null || soldItem.tin != ""
        soldItem.tin != null
            ? pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      soldItem.tin?.length == 14
                          ? "Komitent JSHSHIRi"
                          : "Komitent STIRi",
                      style: myMiniStyle,
                    ),
                    pw.Text(
                      soldItem.tin ?? "",
                      style: myMiniStyle,
                    ),
                  ],
                ))
            : pw.Text(''),
        (soldItem.marking) && (soldItem.mark != null)
            ? pw.Column(
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          "     Mark:",
                          style: myMiniStyle,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "${soldItem.mark}",
                          textAlign: pw.TextAlign.end,
                          style: myMiniStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : pw.SizedBox(height: 0.0, width: 0.0),
        pw.Text("-------------" * 3, style: myMiniStyle),
      ],
    );
  }

  static pw.Widget buildBottom(
      ReceiptModel4 receiptModel4,
      pw.TextStyle myMiniStyle,
      pw.TextStyle myStyleBold,
      double sdacha,
      double discount,
      {List<ReceiptModelSoldItem4>? listAll}) {
    if (listAll != null) {
      receiptModel4.soldItemList.clear();
      receiptModel4.soldItemList.addAll(listAll);
    }
    double vat = 0;
    for (int i = 0; i < receiptModel4.soldItemList.length; i++) {
      ReceiptModelSoldItem4 item = receiptModel4.soldItemList[i];

      vat += ((item.price * item.value) * item.vatPercent) /
          (100 + item.vatPercent);
    }
    List<PrintingApiHelperTolovTuri> list = [];

    for (var element in receiptModel4.payment) {
      if (element.value > 0 || (element.name == "cash" && sdacha > 0)) {
        list.add(
          PrintingApiHelperTolovTuri(
            PrintingApiHelper.getTulovTuri(element.name.toLowerCase()),
            element.name == 'cash'
                ? MoneyFormatter.formatter.format((element.value + sdacha))
                : MoneyFormatter.formatter.format(element.value),
          ),
        );
      }
    }

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        _buildProductInnerItem(
          myStyleBold,
          'HAMMASI',
          MoneyFormatter.formatter.format(receiptModel4.totalPrice),
        ),
        _buildProductInnerItem(
          myMiniStyle,
          '        shu jumladan QQS',
          MoneyFormatter.formatVat.format(vat),
        ),
        discount > 0
            ? _buildProductInnerItem(
                myMiniStyle,
                '        CHEGIRMA'.toLowerCase(),
                MoneyFormatter.formatVat.format(discount),
              )
            : pw.SizedBox(height: 0, width: 0),
        list.length == 1
            ? pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: list
                    .map((e) => _buildProductInnerItem(
                          myMiniStyle,
                          'To\'lov turi: ${e.nomi}',
                          e.money,
                        ))
                    .toList(),
              )
            : pw.Column(
                children: [
                  _buildProductInnerItem(myMiniStyle, 'To\'lov turlari', ''),
                  pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: list
                        .map((e) => _buildProductInnerItem(
                              myMiniStyle,
                              '        ${e.nomi} : ',
                              e.money,
                            ))
                        .toList(),
                  ),
                ],
              ),
        () {
          final String cardId = Pref.getString(PrefKeys.cardId, '');
          final bool hasCardPayment = cardId.isNotEmpty &&
              receiptModel4.payment.any((e) =>
                  e.payId.replaceFirst('@', '') == cardId);
          if (!hasCardPayment) return pw.SizedBox(height: 0, width: 0);
          String kartaTuri;
          switch (receiptModel4.cardType) {
            case 1:
              kartaTuri = 'Korporativ';
              break;
            case 3:
              kartaTuri = 'Ijtimoiy';
              break;
            default:
              kartaTuri = 'Shaxsiy';
          }
          final cardNumber = receiptModel4.cardNumber ?? '';
          final rrn = receiptModel4.pptId ?? '';
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              _buildProductInnerItem(myMiniStyle, 'Karta turi', kartaTuri),
              if (cardNumber.isNotEmpty)
                _buildProductInnerItem(myMiniStyle, 'Karta raqami', cardNumber),
              if (rrn.isNotEmpty)
                _buildProductInnerItem(myMiniStyle, 'RRN', rrn),
            ],
          );
        }(),
        sdacha > 0
            ? _buildProductInnerItem(
                myMiniStyle,
                'Qaytim',
                sdacha.toStringAsFixed(0),
              )
            : pw.Container(width: 0, height: 0),
        (receiptModel4.zdachiToCashback ?? 0) > 0
            ? _buildProductInnerItem(
                myMiniStyle,
                "Jamg'armaga",
                (receiptModel4.zdachiToCashback ?? 0).toStringAsFixed(1),
              )
            : pw.Container(width: 0, height: 0),
      ],
    );
  }

  static pw.Widget buildThanks(pw.TextStyle style) {
    String thanks = Pref.getString(PrefKeys.thanks, "not initialized");
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.SizedBox(
          height: 20,
        ),
        pw.SizedBox(
          width: 180,
          child: pw.Text(thanks.toUpperCase(),
              textAlign: pw.TextAlign.center, style: style),
        ),
      ],
    );
  }

  static pw.Widget _buildProductInnerItem(
    pw.TextStyle myStyle,
    String str1,
    String str2,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(str1, style: myStyle),
        pw.Text(str2, style: myStyle),
      ],
    );
  }

  ////Table///
  static pw.Widget buildTableTitle(
    pw.TextStyle st,
  ) {
    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FixedColumnWidth(10),
        1: pw.FixedColumnWidth(100),
        2: pw.FixedColumnWidth(70),
        3: pw.FixedColumnWidth(30),
        4: pw.FixedColumnWidth(25),
        5: pw.FixedColumnWidth(40),
        6: pw.FixedColumnWidth(30),
        7: pw.FixedColumnWidth(50),
        8: pw.FixedColumnWidth(40),
      },
      border: pw.TableBorder.all(color: PdfColor.fromHex('555555')),
      children: [
        pw.TableRow(
          children: [
            pw.Center(
              child: pw.Text('№', style: st),
            ),
            pw.Center(
              child: pw.Text('Наименование (услуг)', style: st),
            ),
            pw.Center(
              child: pw.Text(
                  'Идентификационный код и название по Единому электронному национальному каталогу товаров (услуг)',
                  style: st),
            ),
            pw.Center(
              child: pw.Text('Единица\nизмерения', style: st),
            ),
            pw.Center(
              child: pw.Text('Количество', style: st),
            ),
            pw.Center(
              child: pw.Text('Цена', style: st),
            ),
            pw.Center(
              child: pw.Text('Стоимость\nпоставкиct', style: st),
            ),
            pw.Expanded(
              child: pw.Table(
                columnWidths: const {
                  0: pw.FixedColumnWidth(50),
                },
                border: pw.TableBorder.symmetric(
                    inside: pw.BorderSide(
                  color: PdfColor.fromHex('555555'),
                )),
                tableWidth: pw.TableWidth.max,
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        height: 20,
                        child: pw.Center(
                          child: pw.Text('НДС', style: st),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Table(
                        columnWidths: const {
                          0: pw.FixedColumnWidth(20),
                          1: pw.FixedColumnWidth(30),
                        },
                        border: pw.TableBorder.all(
                          color: PdfColor.fromHex('555555'),
                        ),
                        tableWidth: pw.TableWidth.max,
                        children: [
                          pw.TableRow(
                            children: [
                              pw.Container(
                                height: 25,
                                child: pw.Center(
                                  child: pw.Text('Ставка', style: st),
                                ),
                              ),
                              pw.Container(
                                height: 25,
                                child: pw.Center(
                                  child: pw.Text('Сумма', style: st),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
            pw.Center(
              child: pw.Text('Стоимость\nпоставки\nс учетом НДС', style: st),
            ),
          ],
        ),
      ],
    );
  }

  ///Table
  static pw.Widget buildTableRow(
    pw.TextStyle st,
    ReceiptModel4 receiptModel4,
  ) {
    double tPrice = 0;
    double empPrice = 0;
    return pw.ListView.builder(
      itemCount: receiptModel4.soldItemList.length,
      itemBuilder: (context, index) {
        ////varprice 12%=>0.12 +1=>1.12
        double varPercentWithPr =
            (receiptModel4.soldItemList[index].vatPercent / 100) + 1;
        ////all price-varprice
        double priceP =
            receiptModel4.soldItemList[index].price / varPercentWithPr;

        ///
        double pr =
            priceP * (receiptModel4.soldItemList[index].vatPercent / 100);
        double allPrice = receiptModel4.soldItemList[index].vat + priceP;
        //double
        double valuePrice = priceP / receiptModel4.soldItemList[index].value;
        //
        tPrice = tPrice + pr;
        empPrice = empPrice + priceP;

        return pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: pw.FixedColumnWidth(10),
            1: pw.FixedColumnWidth(100),
            2: pw.FixedColumnWidth(70),
            3: pw.FixedColumnWidth(30),
            4: pw.FixedColumnWidth(25),
            5: pw.FixedColumnWidth(40),
            6: pw.FixedColumnWidth(30),
            7: pw.FixedColumnWidth(20),
            8: pw.FixedColumnWidth(30),
            9: pw.FixedColumnWidth(40),
          },
          border: pw.TableBorder.all(color: PdfColor.fromHex('555555')),
          children: [
            if (index == 0)
              pw.TableRow(
                children: [
                  pw.Center(
                    child: pw.Text(""),
                  ),
                  pw.Center(
                    child: pw.Text('1', style: st),
                  ),
                  pw.Center(
                    child: pw.Text('2', style: st),
                  ),
                  pw.Center(
                    child: pw.Text('3', style: st),
                  ),
                  pw.Center(
                    child: pw.Text('4', style: st),
                  ),
                  pw.Center(
                    child: pw.Text('5', style: st),
                  ),
                  pw.Center(
                    child: pw.Text('6', style: st),
                  ),
                  pw.Center(
                    child: pw.Text('7', style: st),
                  ),
                  pw.Center(
                    child: pw.Text('8', style: st),
                  ),
                  pw.Center(
                    child: pw.Text('9', style: st),
                  ),
                ],
              ),
            pw.TableRow(
              children: [
                pw.Center(
                  child: pw.Text((index + 1).toString(), style: st),
                ),
                pw.Text(receiptModel4.soldItemList[index].productName,
                    style: st),
                pw.Center(
                  child: pw.Text(receiptModel4.soldItemList[index].mxik,
                      style: st),
                ),
                pw.Center(
                  child: pw.Text(
                      receiptModel4.soldItemList[index].soldBy == 'weight'
                          ? "Кг"
                          : "Шт",
                      style: st),
                ),
                pw.Center(
                  child: pw.Text(
                      receiptModel4.soldItemList[index].value.toString(),
                      style: st),
                ),
                pw.Center(
                  child: pw.Text(valuePrice.toStringAsFixed(3).toString(),
                      style: st),
                ),
                pw.Center(
                  child:
                      pw.Text(priceP.toStringAsFixed(3).toString(), style: st),
                ),
                pw.Center(
                  child: pw.Text(
                      '${receiptModel4.soldItemList[index].vatPercent} %'
                          .toString(),
                      style: st),
                ),
                pw.Center(
                  child: pw.Text(pr.toStringAsFixed(3).toString(), style: st),
                ),
                pw.Center(
                  child: pw.Text(
                      receiptModel4.soldItemList[index].price.toString(),
                      style: st),
                ),
              ],
            ),
            if ((receiptModel4.soldItemList.length - 1) == index)
              pw.TableRow(
                children: [
                  pw.Center(
                    child: pw.Text(""),
                  ),
                  pw.Center(
                    child: pw.Text('Итого', style: st),
                  ),
                  pw.Center(
                    child: pw.Text('', style: st),
                  ),
                  pw.Center(
                    child: pw.Text('', style: st),
                  ),
                  pw.Center(
                    child: pw.Text('', style: st),
                  ),
                  pw.Center(
                    child: pw.Text('', style: st),
                  ),
                  pw.Center(
                    child: pw.Text(empPrice.toStringAsFixed(3).toString(),
                        style: st),
                  ),
                  pw.Center(
                    child: pw.Text('', style: st),
                  ),
                  pw.Center(
                    child: pw.Text(tPrice.toStringAsFixed(3).toString(),
                        style: st),
                  ),
                  pw.Center(
                    child:
                        pw.Text(receiptModel4.totalPrice.toString(), style: st),
                  ),
                ],
              )
          ],
        );
      },
    );
  }

  // pw.Widget calculate(
  //   int a,
  //   pw.TextStyle st,
  // ) {
  //   int w = a;
  //   int b = 0;
  //   int i = 0;

  //   List<String> cal = [];
  //   while (w > 0) {
  //     b = (w % 1000).toInt();
  //     w = (w / 1000).toInt();
  //     int f = (b / 100).toInt();
  //     int g = ((b / 10) % 10).toInt();
  //     int h = (b % 10).toInt();
  //     cal.add(minglik[i]);
  //     cal.add(onlik[h]);
  //     cal.add(yuzlik[g]);
  //     f != 0 ? cal.add('сто ') : cal.add("");
  //     cal.add(onlik[f]);
  //     i++;
  //   }
  //   return pw.Text(
  //       'Всего к оплате: ${cal.reversed.join()} сум 00 тийин . в т. ч. НДС: $a',
  //       style: st);
  // }

  // List<String> minglik = [
  //   "",
  //   'ming ',
  //   'million ',
  // ];
  // List<String> onlik = [
  //   '',
  //   'один ',
  //   'два ',
  //   'три ',
  //   'to`четыре ',
  //   'пять ',
  //   'шесть ',
  //   'семь ',
  //   'восемь ',
  //   'девять ',
  //   "",
  // ];
  // List<String> yuzlik = [
  //   "",
  //   'десять ',
  //   'двадцать ',
  //   'тридцать ',
  //   'сорок ',
  //   'пятьдесят ',
  //   'шестьдесят ',
  //   'семьдесят ',
  //   'восемьдесят ',
  //   'девяносто ',
  //   ""
  // ];

  static pw.Widget buildSignature(
    pw.TextStyle st,
  ) {
    var organization =
        Pref.getObject(PrefKeys.organizationModel) as OrganizationModel;
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(height: 5),
              pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Руководитель:  ', style: st),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("..", style: st),
                      pw.Container(
                          width: 140, height: 0.5, color: PdfColors.black),
                    ]),
              ]),
              pw.SizedBox(height: 5),
              pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Главный бухгалтер:  ', style: st),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("..", style: st),
                      pw.Container(
                          width: 140, height: 0.5, color: PdfColors.black),
                    ]),
              ]),
              pw.SizedBox(height: 5),
              pw.Text('М.П.: (при наличии печати)', style: st),
              pw.SizedBox(height: 5),
              pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Товар отпустил:  ', style: st),
                pw.Container(width: 140, height: 0.5, color: PdfColors.black),
              ]),
            ],
          ),
        ),
        pw.SizedBox(height: 30),
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(height: 5),
              pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Получил:  ', style: st),
                pw.Container(width: 140, height: 0.5, color: PdfColors.black),
              ]),
              pw.SizedBox(height: 5),
              pw.Text('(подпись покупателя или уполномоченного представителя)',
                  style: st),
              pw.SizedBox(height: 5),
              pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Доверенность:  ', style: st),
                pw.Container(width: 140, height: 0.5, color: PdfColors.black),
              ]),
              pw.SizedBox(height: 15),
              pw.Container(width: 180, height: 0.5, color: PdfColors.black),
              pw.SizedBox(height: 2),
              pw.Text('ФИО получателя', style: st),
            ],
          ),
        )
      ],
    );
  }

  static pw.Widget buildTitle(
    pw.TextStyle st,
    pw.TextStyle sts,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildT(st, sts, 'Поставщик:', 'organization_name'),
              buildT(st, sts, 'Адрес:', 'service_address'),
              pw.Text('Идентификационный номер', style: st),
              buildT(st, sts, 'поставщика (ИНН):', 'organization_inn'),
              pw.Text('Регистрационный код плательщика', style: st),
              buildT(st, sts, 'НДС:', ""),
              buildT(st, sts, 'Р/С:', ""),
              buildT(st, sts, 'МФО:', ""),
            ],
          ),
        ),
        pw.SizedBox(width: 30),
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildT(st, sts, 'Поставщик:', ''),
              buildT(st, sts, 'Адрес:', ''),
              pw.Text('Идентификационный номер', style: st),
              buildT(st, sts, 'поставщика (ИНН):', ''),
              pw.Text('Регистрационный код плательщика', style: st),
              buildT(st, sts, 'НДС:', ''),
              buildT(st, sts, 'Р/С:', ''),
              buildT(st, sts, 'МФО:', ''),
            ],
          ),
        )
      ],
    );
  }

  static pw.Widget buildT(
    pw.TextStyle st,
    pw.TextStyle sts,
    String text,
    String key,
  ) {
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(text, style: st),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(Pref.getString(key, ""), style: sts),
                      pw.Container(
                          width: 180, height: 0.5, color: PdfColors.black),
                    ]),
              ]),
          pw.SizedBox(height: 5),
        ]);
  }
}

class NumericToWords {
  final _digitWords = {
    0: {'male': 'ноль'},
    1: {'male': 'один', 'female': 'одна'},
    2: {'male': 'два', 'female': 'две'},
    3: {'male': 'три'},
    4: {'male': 'четыре'},
    5: {'male': 'пять'},
    6: {'male': 'шесть'},
    7: {'male': 'семь'},
    8: {'male': 'восемь'},
    9: {'male': 'девять'},
    10: {'male': 'десять'},
    11: {'male': 'одинадцать'},
    12: {'male': 'двенадцать'},
    13: {'male': 'тринадцать'},
    14: {'male': 'четырнадцать'},
    15: {'male': 'пятнадцать'},
    16: {'male': 'шеснадцать'},
    17: {'male': 'семнадцать'},
    18: {'male': 'восемнадцать'},
    19: {'male': 'девятнадцать'},
    20: {'male': 'двадцать'},
    30: {'male': 'тридцать'},
    40: {'male': 'сорок'},
    50: {'male': 'пятьдесят'},
    60: {'male': 'шестьдесят'},
    70: {'male': 'семьдесят'},
    80: {'male': 'восемьдесят'},
    90: {'male': 'девяносто'},
    100: {'male': 'сто'},
    200: {'male': 'двести'},
    300: {'male': 'триста'},
    400: {'male': 'четыреста'},
    500: {'male': 'пятьсот'},
    600: {'male': 'шестьсот'},
    700: {'male': 'семьсот'},
    800: {'male': 'восемьсот'},
    900: {'male': 'девятьсот'},
    1000: {'one': 'тысяча', 'few': 'тысячи', 'many': 'тысяч'},
    1000000: {'one': 'миллион', 'few': 'миллиона', 'many': 'миллионов'},
    1000000000: {'one': 'миллиард', 'few': 'миллиарда', 'many': 'миллиардов'},
    1000000000000: {
      'one': 'триллион',
      'few': 'триллиона',
      'many': 'триллионов'
    },
  };

  List<String> splitToTriades(int number) {
    var strNumber = number.toString();
    var numberLength = strNumber.length;
    List<String> triades = [];
    var i = numberLength;
    do {
      var triade = strNumber.substring((i - 3 >= 0) ? i - 3 : 0, i);
      triades.add(triade);
      i -= 3;
    } while (i > 0);
    return List.from(triades.reversed);
  }

  int extractFraction(num number) {
    return int.parse(number.toStringAsFixed(2).split('.')[1]);
  }

  String? toWords(int number, {bool lowNumberInFemenineGender = false}) {
    if (number == 0) return _digitWords[number]!['male'];

    var words = [];
    var triades = splitToTriades(number);
    triades.reversed.toList().asMap().forEach((index, triade) {
      final intTriade = int.parse(triade);
      var triadeWords = [];
      final lowNumberKindIdx =
          (index == 1 || index == 0 && lowNumberInFemenineGender)
              ? 'female'
              : 'male';
      final hundred = _hundredFromTriade(intTriade);
      final decimal = _decimalFromTriade(intTriade);
      final lowNumber = _lowNumberFromTriade(intTriade);
      final countableIdx =
          lowNumber == 1 ? 'one' : (lowNumber < 5 ? 'few' : 'many');

      if (hundred > 0) triadeWords.add(_digitWords[hundred]!['male']);

      if (decimal > 0) triadeWords.add(_digitWords[decimal]!['male']);

      if (lowNumber > 0) {
        triadeWords.add(_digitWords[lowNumber]![lowNumberKindIdx] ??
            _digitWords[lowNumber]!['male']);
      }

      if (index > 0) {
        triadeWords.add(_digitWords[pow(10, 3 * index)]![countableIdx]);
      }

      words = triadeWords + words;
    });
    return words.join(' ');
  }

  int _hundredFromTriade(int triade) {
    return ((triade ~/ 100).truncate() * 100).toInt();
  }

  int _decimalFromTriade(int triade) {
    final decimal = triade - _hundredFromTriade(triade);
    return decimal < 20 ? 0 : ((decimal ~/ 10).truncate() * 10).toInt();
  }

  int _lowNumberFromTriade(int triade) {
    return triade - (_hundredFromTriade(triade) + _decimalFromTriade(triade));
  }
}
