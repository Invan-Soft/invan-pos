import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/bloc/tp_bloc.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/discount_type_status.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';

class SummaInputOfOperationOnTotalPriceDialog extends StatefulWidget {
  final InputBorder border;

  const SummaInputOfOperationOnTotalPriceDialog(this.border, {Key? key})
      : super(key: key);

  @override
  State<SummaInputOfOperationOnTotalPriceDialog> createState() =>
      _SummaInputOfOperationOnTotalPriceDialogState();
}

class _SummaInputOfOperationOnTotalPriceDialogState
    extends State<SummaInputOfOperationOnTotalPriceDialog> {
  @override
  Widget build(BuildContext context) {
    TpBloc tpBloc = BlocProvider.of(context, listen: false);
    AppLocalizations loc = AppLocalizations.of(context)!;
    return SizedBox(
      height: SizeConfig.v * 4.81,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              loc.jami,
              style: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(SizeConfig.h * .2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).canvasColor,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.percent, color: Colors.transparent),
                  TextButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () {
                      DiscountTypeStatus.disTypeStatus = TpStatus.summa;
                      return tpBloc.add(TpSelectInputEvent(TpStatus.summa));
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).dialogBackgroundColor,
                      padding: const EdgeInsets.all(0.0),
                    ),
                    child: BlocBuilder<TpBloc, TpState>(
                      builder: (context, state) {
                        return Text(
                          tpBloc.totalPriceString,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: SizeConfig.v * 2.3,
                            fontWeight: FontWeight.normal,
                            fontStyle: FontStyle.normal,
                            color: Theme.of(context).canvasColor,
                            backgroundColor: tpBloc.selectedAll &&
                                    tpBloc.inputStatus == TpStatus.summa
                                ? Colors.red.withOpacity(.4)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const Icon(Icons.percent, color: Colors.transparent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
