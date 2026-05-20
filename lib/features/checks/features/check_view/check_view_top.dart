import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/checks/features/checks_list/bloc/check_f_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/utils.dart';

import '../../../../utils/l10n/app_localizations.dart';

class CheckViewTop extends StatelessWidget {
  const CheckViewTop({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocBuilder<CheckFBloc, CheckFState>(
      builder: (context, state) {
        ReceiptModel4? selectedCheck =state.selectedCheck;
        final cashierName =
            selectedCheck != null ? selectedCheck.cashierName : '';
        final posName = selectedCheck != null ? selectedCheck.posName : '';
        final checkNo = selectedCheck != null ? selectedCheck.externalId : '';
        final date =
            selectedCheck != null ? _getDateString(selectedCheck.date) : '';
        String clientName = '';
        if (selectedCheck != null) {
          clientName = selectedCheck.clientName;
        }
        return Container(
          padding: EdgeInsets.only(
            top: SizeConfig.v * 4,
            left: SizeConfig.h * 2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _textInRow(loc.kassir, cashierName, context),
              _textInRow(loc.pos, posName, context),
              _textInRow(loc.mijoz, clientName, context),
              _textInRow(loc.chekNo, checkNo, context),
              _textInRow(loc.yaratilganSanasi, date, context),
              SizedBox(height: SizeConfig.v * 3),
            ],
          ),
        );
      },
    );
  }

  Row _textInRow(String text, String text1, BuildContext con) {
    return Row(
      children: [
        Text(
          '$text:  ',
          style: MyThemes.txtStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(con).dividerColor,
          ),
        ),
        Text(
          text1,
          style: MyThemes.txtStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(con).canvasColor,
          ),
        ),
      ],
    );
  }
}

String _getDateString(int millisecondsSinceEpoch) {
  final d = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  String t = '';
  t += d.day < 10 ? '0${d.day}' : d.day.toString();
  t += '.';
  t += d.month < 10 ? '0${d.month}' : d.month.toString();
  t += '.';
  t += d.year.toString();
  t += ' ';
  t += d.hour < 10 ? '0${d.hour}' : d.hour.toString();
  t += ':';
  t += d.minute < 10 ? '0${d.minute}' : d.minute.toString();
  return t;
}
