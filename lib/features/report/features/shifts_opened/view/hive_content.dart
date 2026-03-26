import 'package:flutter/material.dart';
import 'package:invan2/changes/models/shift/shift_hive_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart';
import 'package:invan2/utils/utils.dart';

class ShiftContennt extends StatelessWidget {
  ShiftContennt({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    ShiftModelHive? shift = ShiftSingleton4.getCurrentHiveShift();
    return shift == null
        ? Container()
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: SizeConfig.h * 2.5,
                  bottom: SizeConfig.v,
                ),
                child: Row(
                  children: [
                    Text(
                      '${loc.tomonidanOchilgan}:',
                      style: stl.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w900),
                    ),
                    Text(
                      ' ${shift.byWhomName}',
                      style: stl.copyWith(
                          color: Theme.of(context).canvasColor,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              buildDivider(context),
              Padding(
                padding: EdgeInsets.only(
                  left: SizeConfig.h * 2.5,
                  right: SizeConfig.h * 3.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: SizeConfig.v * 5),
                    Text(
                      loc.kassadaNaqdPul,
                      style: stl.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: SizeConfig.v * 1.2),
                    _textInRow(loc.smenaBoshidaNaqdPul,
                        shift.cashDrawerHive?.startingCash ?? 0, context),
                    _textInRow(loc.naqdTolovlar,
                        shift.cashDrawerHive!.cashPayment!, context),
                    _textInRow(loc.naqdPuldaQaytimlar,
                        shift.cashDrawerHive!.cashRefund!, context),
                    // _textInRow(loc.kirimlar, shift.cashDrawerHive!.paidIn!,context),
                    // _textInRow(loc.chiqimlar, shift.cashDrawerHive!.paidOut!,context),
                    // _textInRow(
                    //     loc.inkassatsiya, shift.cashDrawerHive!.inkassa!,context),
                    SizedBox(height: SizeConfig.v * 3.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          loc.kutilayotganPulMiqdori,
                          style: stl.copyWith(
                              color: Theme.of(context).canvasColor,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          MoneyFormatter.formatter
                              .format(shift.cashDrawerHive!.expCashAmount!),
                          style: stl.copyWith(
                              color: Theme.of(context).canvasColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.v * 3),
                    Text(
                      loc.jamiSotuvlar,
                      style: stl.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: SizeConfig.v * 1),
                  ],
                ),
              ),
              buildDivider(context),
              Container(
                padding: EdgeInsets.only(
                  left: SizeConfig.h * 2.5,
                  right: SizeConfig.h * 3.5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: SizeConfig.v * 2),
                    _textInRow(
                        loc.savdolar, shift.salesSummary!.grossSales!, context),
                    _textInRow(loc.naqdPuldaQaytimlar,
                        shift.salesSummary!.refunds!, context),
                    _textInRow(loc.chegirmalar, shift.salesSummary!.discounts!,
                        context),
                    SizedBox(height: SizeConfig.v),
                  ],
                ),
              ),
              buildDivider(context),
              Container(
                padding: EdgeInsets.only(
                  left: SizeConfig.h * 2.5,
                  right: SizeConfig.h * 3.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: SizeConfig.v * 2),
                    _textInRow(
                        loc.naqdPulda, shift.salesSummary!.cash!, context),
                    _textInRow(
                        loc.plastik,
                        (shift.salesSummary!.uzCard ?? 0) +
                            (shift.salesSummary!.humoCard ?? 0),
                        context),
                    _textInRow(loc.keshbek_tolov,
                        shift.salesSummary!.cashbackOut!, context),
                    _textInRow(
                        loc.qarz, (shift.salesSummary?.debt ?? 0), context),

                    /// OTHER
                    (shift.salesSummary?.click ?? 0) > 0
                        ? _textInRow('Click Pass',
                            (shift.salesSummary?.click ?? 0), context)
                        : SizedBox.shrink(),
                    (shift.salesSummary?.clickQr ?? 0) > 0
                        ? _textInRow('Click QR',
                            (shift.salesSummary?.clickQr ?? 0), context)
                        : SizedBox.shrink(),
                    (shift.salesSummary?.payme ?? 0) > 0
                        ? _textInRow('Payme Go',
                            (shift.salesSummary?.payme ?? 0), context)
                        : SizedBox.shrink(),
                    (shift.salesSummary?.paymeQr ?? 0) > 0
                        ? _textInRow('Payme QR',
                            (shift.salesSummary?.paymeQr ?? 0), context)
                        : SizedBox.shrink(),
                    (shift.salesSummary?.uzum ?? 0) > 0
                        ? _textInRow('Uzum Pass',
                            (shift.salesSummary?.uzum ?? 0), context)
                        : SizedBox.shrink(),
                    (shift.salesSummary?.uzumQr ?? 0) > 0
                        ? _textInRow('Uzum QR',
                            (shift.salesSummary?.uzumQr ?? 0), context)
                        : SizedBox.shrink(),
                    (shift.salesSummary?.other ?? 0) > 0
                        ? _textInRow(
                            'Other', (shift.salesSummary?.other ?? 0), context)
                        : SizedBox.shrink(),

                    /// OTHER

                    SizedBox(height: SizeConfig.v * 2),
                  ],
                ),
              ),
            ],
          );
  }

  Row _textInRow(String text, num amount, BuildContext con) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          text,
          style: stl.copyWith(color: Theme.of(con).canvasColor),
        ),
        Text(
          MoneyFormatter.formatter.format(amount),
          style: stl.copyWith(color: Theme.of(con).canvasColor),
        ),
      ],
    );
  }

  Container buildDivider(BuildContext con) {
    return Container(
      width: double.infinity,
      height: 1.5,
      color: Theme.of(con).primaryColor,
    );
  }

  final stl = MyThemes.txtStyle(fontSize: 2.3);
}
