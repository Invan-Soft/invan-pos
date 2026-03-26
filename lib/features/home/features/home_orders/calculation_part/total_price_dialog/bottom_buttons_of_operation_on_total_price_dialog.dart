import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/bloc/tp_bloc.dart';
import 'package:invan2/utils/utils.dart';

import 'discount_type_status.dart';

class SaveButtonOnTotalPriceOperation extends StatelessWidget {
  const SaveButtonOnTotalPriceOperation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TpBloc tpBloc = BlocProvider.of(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.h * 1.95,
        right: SizeConfig.h * 1.95,
        bottom: SizeConfig.v * 1.43,
      ),
      child: MaterialButton(
        focusNode: FocusNode(skipTraversal: true),
        onPressed: () {
          tpBloc.add(TpSaveButtonPressedEvent());
          DiscountTypeStatus.summa = tpBloc.getBaseTotalPrice;
          AppNavigation.pop();
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            SizeConfig.v * 1.1,
          ),
        ),
        height: SizeConfig.v * 6.18,
        color: Theme.of(context).primaryColor,
        disabledColor: Theme.of(context).primaryColor.withOpacity(.5),
        child: Text(
          loc.saqlash,
          style: MyThemes.txtStyle(color: Colors.white),
        ),
      ),
    );
  }
}
