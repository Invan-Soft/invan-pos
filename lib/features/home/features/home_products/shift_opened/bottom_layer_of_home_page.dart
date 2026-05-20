import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/checks/features/checks_list/bloc/check_f_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/widgets/text_in_row.dart';
import 'package:invan2/utils/utils.dart';

import '../../../../../widgets/widgets.dart';

class BottomLayerOfHomePage extends StatefulWidget {
  // final int lastUpdate;
  const BottomLayerOfHomePage({super.key});

  @override
  State<BottomLayerOfHomePage> createState() => _BottomLayerOfHomePageState();
}

class _BottomLayerOfHomePageState extends State<BottomLayerOfHomePage> {
  late CheckFBloc checkFBloc;

  @override
  void initState() {
    checkFBloc = BlocProvider.of(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    bool selectedClientIsNotNull =
        context.watch<OrderingProvider4>().getCurrentClientIsNotNULL;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        boxShadow: [
          BoxShadow(
            blurRadius: 3,
            color: Theme.of(context).highlightColor,
          ),
        ],
      ),
      width: MediaQuery.of(context).size.width,
      height: SizeConfig.v * 3.71,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(width: SizeConfig.h),
                TextInRowHomeBottomSide(
                  text1: "${loc.xodim}:",
                  text2:
                      Pref.getString(PrefKeys.cashierName, "not initialized"),
                ),
                _verticalDivider(),
                BlocBuilder<CheckFBloc, CheckFState>(
                  builder: (context, state) {
                    return TextInRowHomeBottomSide(
                      text1: "${loc.sotuv}:",
                      text2: "${checkFBloc.checksList.length}",
                    );
                  },
                ),
                _verticalDivider(),
                TextInRowHomeBottomSide(
                    text1: "${loc.sync}:",
                    text2: DateTime.fromMillisecondsSinceEpoch(
                      Pref.getInt(PrefKeys.lastSyncTime, 0),
                    ).toString().substring(0, 19)),
              ],
            ),
          ),
          Expanded(
            child: selectedClientIsNotNull
                ? Row(
                    children: [
                      _verticalDivider(),
                      TextInRowHomeBottomSide(
                          text1: "${loc.mijoz}:",
                          text2:
                              "${context.watch<OrderingProvider4>().getClientFirstname} ${context.watch<OrderingProvider4>().getClientLastName}"),
                      _verticalDivider(),
                      TextInRowHomeBottomSide(
                        text1: "${loc.balans}:",
                        text2: MoneyFormatter.inputMoneyFormatter.format(
                          context
                              .watch<OrderingProvider4>()
                              .getClientPointBalance,
                        ),
                      ),
                      _verticalDivider(),
                      TextInRowHomeBottomSide(
                          text1: "${loc.turi}:",
                          text2: context
                                      .watch<OrderingProvider4>()
                                      .getClientType ==
                                  Pref.getString(PrefKeys.flatRate, "")
                              ? "DISCOUNT"
                              : context
                                          .watch<OrderingProvider4>()
                                          .getClientType ==
                                      Pref.getString(PrefKeys.cashBeckCC, "")
                                  ? "CASHBACK"
                                  : "STANDART"),
                      const Spacer(),
                    ],
                  )
                : const SizedBox(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AppBarLamp(min: true),
            // child: AppBarLamp(min: true, isWebsocket: true),
          ),
        ],
      ),
    );
  }

  SizedBox _verticalDivider() {
    return SizedBox(
      width: SizeConfig.h * 1.9,
      child: VerticalDivider(
        indent: 7,
        endIndent: 7,
        color: Theme.of(context).dividerColor,
      ),
    );
  }
}
