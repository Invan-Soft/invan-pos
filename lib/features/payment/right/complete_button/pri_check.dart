// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/dialogs/sdacha_dialog.dart';
import 'package:invan2/changes/models/ofd/incom_response_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/payment/right/complete_button/components/button_widget.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:provider/provider.dart';

import '../../../../utils/constants/constants.dart';
import 'pre_complete_bloc/per_comlete_bloc.dart';

class SimpleCheck extends StatelessWidget {
  final BuildContext homeContextt;

  const SimpleCheck(this.homeContextt, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    PreCmtBBloc ctBloc = BlocProvider.of(context, listen: false);
    AppLocalizations loc = AppLocalizations.of(context)!;
    return SizedBox(
      height: SizeConfig.v * 15.75,
      child: BlocConsumer<PreCmtBBloc, PreCtState>(
        listener: (context, state) async {
          if (state is PreCtPrepereState) {
            OrderingProvider4 ordProvider4 =
                Provider.of<OrderingProvider4>(context, listen: false);
            ordProvider4.setPaymentInProgress(true);
            double sdacha = ordProvider4.getSdacha;
            bool sdachaToCashback = ordProvider4.isChangeToCashback;
            ctBloc.add(
              PreCtPayEvent(
                sdacha: sdacha,
                ofd: false,
                sdachaToCashbak: sdachaToCashback,
              ),
            );
          }
          if (state is PreCtPayingState) {
            Provider.of<OrderingProvider4>(context, listen: false)
                .pressPaymentButton(homeContextt);
            ctBloc.add(
              PreCtPaySuccessedEvent(
                sdacha: state.sdacha,
                showSdachaDialog: (state.sdacha > 0 && !state.sdachaToCashback),
              ),
            );
          }

          if (state is PreCtSucceedState) {
            if (state.showSdachaDialog) {
              await showDialog(
                barrierDismissible: false,
                barrierColor: Colors.black.withOpacity(.5),
                context: context,
                builder: (context) => SdachaDialog(state.sdacha.toString()),
              );
            }
            await Pref.setBool('isPaper', false);
            AppNavigation.pop();
          }
          if (state is PreCtErrorState) {
            if (state.subError is! MxikError) {
              await Future.delayed(const Duration(seconds: 3));
            }
            AppNavigation.pop(v: state.subError);
          }
        },
        builder: (context, state) {
          if (state is PreCtInitialState) {
            if (context.read<OrderingProvider4>().getIsButtonEnabled &&
                !context.read<OrderingProvider4>().getPaymentInProgress) {
              return ButtonWidgetWithWidget(
                onPredssed: () => ctBloc.add(PreCtPrepareToPayEvent()),
              );
            }
          }
          if (state is PreCtSucceedState) {
            Pref.setBool(PrefKeys.debtClick, false);
            return ButtonWidget(
              title: "COMLETE",
              onPredssed: () {},
            );
          }
          if (state is PreCtErrorState) {
            return ButtonWidget(
              title: state.error.toString(),
              onPredssed: () {},
            );
          }
          if (state is PreCtLoadingState || state is PreCtPayingState) {
            return ButtonWidget(
              title: "${loc.kuting}...",
              onPredssed: () {},
            );
          }
          return ButtonWidgetWithWidget(
            onPredssed: () {},
          );
        },
      ),
    );
  }
}
