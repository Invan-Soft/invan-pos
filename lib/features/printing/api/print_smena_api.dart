import 'package:flutter/services.dart';
import 'package:invan2/changes/models/shift/shift_hive_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'printing_api_helper.dart';

class PrintSmenaApi {
  static Future<Uint8List> generatePdf57(
      ShiftModelHive shift, AppLocalizations loc, bool isZ) async {
    final organizationName =
        Pref.getString(PrefKeys.storeName, 'not initialized');
    final posName = Pref.getString(PrefKeys.posName, 'not initialized');
    const double mm = PdfPageFormat.mm;

    final data = await rootBundle.load('assets/fonts/arial.ttf');
    final myFont = Font.ttf(data);
    final style = TextStyle(font: myFont, fontSize: mm * 2.8);

    final pdf = Document();

    pdf.addPage(Page(
      margin: const EdgeInsets.all(0),
      pageFormat: PdfPageFormat.roll57,
      build: (Context context) {
        return Padding(
          padding: const EdgeInsets.only(left: mm * 2, right: mm * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTop(style, organizationName, posName, loc, isZ),
              _buildDashes(style),
              _buildOpenClose(shift, style),
              _buildDashes(style),
              _buildCashInDrawer(shift, style),
              _buildSalesSummary(shift, style),
              _buildBottom(style),
              _buildDashes(style),
            ],
          ),
        );
      },
    ));

    return pdf.save();
  }

  static Future<Uint8List> generatePdf80(
      ShiftModelHive shift, AppLocalizations loc, bool isZ) async {
    final organizationName =
        Pref.getString(PrefKeys.storeName, 'not initialized');
    final posName = Pref.getString(PrefKeys.posName, 'not initialized');
    const double mm = PdfPageFormat.mm;

    final data = await rootBundle.load('assets/fonts/arial.ttf');
    final myFont = Font.ttf(data);
    final style = TextStyle(font: myFont, fontSize: mm * 3.1);

    final pdf = Document();

    pdf.addPage(Page(
      margin: const EdgeInsets.all(0),
      pageFormat: PdfPageFormat.roll80,
      build: (Context context) {
        return Padding(
          padding: const EdgeInsets.only(left: mm * 1, right: mm * 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTop(style, organizationName, posName, loc, isZ),
              _buildDashes(style),
              _buildOpenClose(shift, style),
              _buildDashes(style),
              _buildCashInDrawer(shift, style),
              _buildSalesSummary(shift, style),
              _buildBottom(style),
            ],
          ),
        );
      },
    ));

    return pdf.save();
  }

  static Text _buildDashes(TextStyle style) {
    return Text(
      '--------------------------------------'
      '--------------------------------------',
      style: style,
      maxLines: 1,
    );
  }

  static Widget _buildTop(TextStyle style, String orgName, String posName,
      AppLocalizations loc, bool isZ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          (isZ ? "Z - " : 'X - ') + loc.xisobot,
          style: style.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Сервис:', style: style),
                  Text('ПОС:', style: style),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(orgName, style: style),
                  Text(posName, style: style),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _buildOpenClose(ShiftModelHive shift, TextStyle style) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCustomRow(
          'Смену открыл:',
          shift.byWhomName!,
          style,
        ),
        _buildCustomRow(
          'Время открытия:',
          PrintingApiHelper.getTimeString(shift.openingTime!),
          style,
        ),
        _buildCustomRow(
          'Время закрытия:',
          shift.isClosed ?? false
              ? PrintingApiHelper.getTimeString(shift.closingTime!)
              : "",
          style,
        ),
      ],
    );
  }

  static Widget _buildCashInDrawer(
    ShiftModelHive shift,
    TextStyle style,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Наличные в кассе',
          style: style.copyWith(fontWeight: FontWeight.bold),
        ),
        _buildDashes(style),
        _buildCustomRow(
          'Наличные на начало \nсмены',
          MoneyFormatter.formatter.format(shift.cashDrawerHive!.startingCash),
          style,
        ),
        _buildCustomRow(
          'Оплаты наличными',
          MoneyFormatter.formatter.format(shift.cashDrawerHive!.cashPayment),
          style,
        ),
        _buildCustomRow(
          'Возврат наличными',
          MoneyFormatter.formatter.format(shift.cashDrawerHive!.cashRefund),
          style,
        ),
        /*_buildCustomRow(
          'Внесения',
          MoneyFormatter.formatter.format(shift.cashDrawerHive!.paidIn),
          style,
        ),
        _buildCustomRow(
          'Изъятия',
          MoneyFormatter.formatter.format(shift.cashDrawerHive!.paidOut),
          style,
        ),
        _buildCustomRow(
          'Инкассация',
          MoneyFormatter.formatter.format(shift.cashDrawerHive!.withdrawal),
          style,
        ),*/
        _buildCustomRow(
          'Ожидаемая сумма \nналичных',
          MoneyFormatter.formatter.format(shift.cashDrawerHive!.expCashAmount),
          style,
        ),
        _buildCustomRow(
          'Сумма выданных денег',
          MoneyFormatter.formatter.format(shift.cashDrawerHive!.actCashAmount),
          style,
        ),
      ],
    );
  }

  static Widget _buildSalesSummary(
    ShiftModelHive shift,
    TextStyle style,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildDashes(style),
        Text(
          'Итог продаж',
          style: style.copyWith(fontWeight: FontWeight.bold),
        ),
        _buildDashes(style),
        _buildCustomRow(
          'Продажы',
          MoneyFormatter.formatter.format(shift.salesSummary!.grossSales),
          style,
        ),
        _buildCustomRow(
          'Возвраты',
          MoneyFormatter.formatter.format(shift.salesSummary!.refunds),
          style,
        ),
        _buildCustomRow(
          'Скидки',
          MoneyFormatter.formatter.format(shift.salesSummary!.discounts),
          style,
        ),
        SizedBox(height: 10),
        _buildCustomRow(
          'Наличные',
          MoneyFormatter.formatter.format(shift.salesSummary!.cash),
          style,
        ),
        _buildDashes(style),
        _buildCustomRow(
          'Пластик',
          MoneyFormatter.formatter.format(
            (shift.salesSummary!.uzCard ?? 0) +
                (shift.salesSummary!.humoCard ?? 0),
          ),
          style,
        ),
        _buildCustomRow(
          '   Uzcard',
          MoneyFormatter.formatter.format(shift.salesSummary!.uzCard),
          style,
        ),
        _buildCustomRow(
          '   HUMO',
          MoneyFormatter.formatter.format(shift.salesSummary!.humoCard),
          style,
        ),
        _buildDashes(style),
        _buildCustomRow(
          'Click',
          MoneyFormatter.formatter.format((shift.salesSummary!.click ?? 0) +
              (shift.salesSummary!.clickQr ?? 0)),
          style,
        ),
        _buildCustomRow(
          '  Click Qr',
          MoneyFormatter.formatter.format(shift.salesSummary!.clickQr),
          style,
        ),
        _buildCustomRow(
          '  Click Pass',
          MoneyFormatter.formatter.format(shift.salesSummary!.click),
          style,
        ),
        _buildDashes(style),
        _buildCustomRow(
          'Payme',
          MoneyFormatter.formatter.format((shift.salesSummary!.payme ?? 0) +
              (shift.salesSummary!.paymeQr ?? 0)),
          style,
        ),
        _buildCustomRow(
          '  Payme Qr',
          MoneyFormatter.formatter.format(shift.salesSummary!.paymeQr),
          style,
        ),
        _buildCustomRow(
          '  Payme Go',
          MoneyFormatter.formatter.format(shift.salesSummary!.payme),
          style,
        ),
        _buildDashes(style),
        _buildCustomRow(
          'Uzum',
          MoneyFormatter.formatter.format((shift.salesSummary!.uzum ?? 0) +
              (shift.salesSummary!.uzumQr ?? 0)),
          style,
        ),
        _buildCustomRow(
          '  Uzum Qr',
          MoneyFormatter.formatter.format(shift.salesSummary!.uzumQr),
          style,
        ),
        _buildCustomRow(
          '  Uzum Pass',
          MoneyFormatter.formatter.format(shift.salesSummary!.uzum),
          style,
        ),
        _buildDashes(style),
        _buildCustomRow(
          'Кешбек оплата',
          MoneyFormatter.formatter.format(shift.salesSummary!.cashbackOut),
          style,
        ),
        _buildCustomRow(
          'Долг',
          MoneyFormatter.formatter.format(shift.salesSummary!.debt),
          style,
        ),
        _buildCustomRow(
          'Other',
          MoneyFormatter.formatter.format(shift.salesSummary!.other),
          style,
        ),
      ],
    );
  }

  static Widget _buildBottom(TextStyle style) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildDashes(style),
        Text(
          PrintingApiHelper.getTimeString(
              DateTime.now().millisecondsSinceEpoch),
          style: style,
        ),
      ],
    );
  }

  static Widget _buildCustomRow(String str1, String str2, TextStyle style) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(str1, style: style),
        Text(str2, style: style),
      ],
    );
  }
}

extension MM on num {
  get mm => this * PdfPageFormat.mm;
}
