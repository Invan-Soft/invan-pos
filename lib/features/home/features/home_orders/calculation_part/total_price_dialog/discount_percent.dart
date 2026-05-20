import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/bloc/tp_bloc.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';

import 'discount_type_status.dart';

class DiscountPercent extends StatefulWidget {
  final InputBorder border;

  const DiscountPercent({required this.border, Key? key}) : super(key: key);

  @override
  DiscountPercentState createState() => DiscountPercentState();
}

class DiscountPercentState extends State<DiscountPercent> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    TpBloc tpBloc = BlocProvider.of(context, listen: false);

    return SizedBox(
      height: SizeConfig.v * 6.81,
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              loc.chegirma,
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
                      DiscountTypeStatus.disTypeStatus = TpStatus.discount;
                      return tpBloc.add(TpSelectInputEvent(TpStatus.discount));
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).dialogBackgroundColor,
                      padding: const EdgeInsets.all(0.0),
                    ),
                    child: BlocBuilder<TpBloc, TpState>(
                      builder: (context, state) {
                        return Text(
                          tpBloc.discountString,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: SizeConfig.v * 2.3,
                            fontWeight: FontWeight.normal,
                            fontStyle: FontStyle.normal,
                            color: Theme.of(context).canvasColor,
                            backgroundColor: tpBloc.selectedAll &&
                                    tpBloc.inputStatus == TpStatus.discount
                                ? Colors.red.withOpacity(.4)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  Icon(Icons.percent, color: Theme.of(context).canvasColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
