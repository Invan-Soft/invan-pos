import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/checks/features/checks_list/bloc/check_f_bloc.dart';
import 'package:invan2/features/checks/features/checks_list/components/build_list.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';
import 'package:invan2/widgets/default_button.dart';

import '../../../../../utils/l10n/app_localizations.dart';

class CheckListWidget extends StatelessWidget {
  final List<ReceiptModel4> receipts;
  final VoidCallback onOkButtonPressed;

  const CheckListWidget(
      {required this.onOkButtonPressed, required this.receipts, super.key});

  @override
  Widget build(BuildContext context) {
    CheckFBloc checkFBloc = BlocProvider.of(context);
    AppLocalizations loc = AppLocalizations.of(context)!;
    return BlocConsumer<CheckFBloc, CheckFState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is CheckFLoadingState) {
          return Center(
            child: Column(
              children: [
                CupertinoActivityIndicator(radius: SizeConfig.v * 3),
                Text(
                  loc.check_qidirilmoqda,
                  style: MyThemes.txtStyle(
                      fontSize: 3, color: Theme.of(context).canvasColor),
                ),
              ],
            ),
          );
        }
        if (state is CheckFErrorState) {
          return Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  setText("ERROR: ${state.error}", context),
                  _okButton(onPressed: onOkButtonPressed),
                ],
              ),
            ),
          );
        }
        if (state is ChecksFNotFoundState) {
          return Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  setText(loc.belgiga_tegishli_check_topilmadi, context),
                  // _okButton(onPressed: onOkButtonPressed),
                ],
              ),
            ),
          );
        }

        if (state is CheckFNoIternetState) {
          return Column(
            children: [
              setText(loc.internet_yoq, context),
              _okButton(
                  onPressed: () => checkFBloc.add(CheckFSearchGlobalEvent(
                      state.pattern,
                      isRetry: true,
                      page: checkFBloc.currentPage)),
                  title: loc.qayta_urinish),
            ],
          );
        }
        if (state is CheckFInitial) {
          return Expanded(
            child: BuildList(
              list: state.checksList,
              selectedIndex: state.selected,
            ),
          );
        }
        if (state is CheckFNoChekYetState) {
          return Expanded(
            child: Center(
              child: setText(loc.hali_checklar_mavjud_emas, context),
            ),
          );
        }
        return Expanded(
          child: BuildList(list: receipts, selectedIndex: 0),
        );
      },
    );
  }

  _okButton({required VoidCallback onPressed, String title = "Ok"}) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: SizeConfig.h, vertical: SizeConfig.v),
      child: Column(
        children: [
          DefaultButton(
            text: title,
            isButtonEnabled: true,
            onPress: onPressed,
            height: 6,
          )
        ],
      ),
    );
  }

  setText(String v, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 2),
      child: Text(
        v,
        textAlign: TextAlign.center,
        style: MyThemes.txtStyle(
            fontSize: 3, color: Theme.of(context).canvasColor),
      ),
    );
  }
}
