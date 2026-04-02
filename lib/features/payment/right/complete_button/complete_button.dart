import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/dialogs/sdacha_dialog.dart';
import 'package:invan2/changes/models/ofd/incom_response_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/payment/right/complete_button/components/button_widget.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:provider/provider.dart';
import '../../../../changes/models/ofd/payment_result_model.dart';
import 'complete_bloc/comlete_bloc.dart';

class CompleteButtonOfPaymentPageOnBloc extends StatelessWidget {
  final BuildContext homeContextt;

  const CompleteButtonOfPaymentPageOnBloc(this.homeContextt, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    CmtBBloc ctBloc = BlocProvider.of(context, listen: false);
    AppLocalizations loc = AppLocalizations.of(context)!;

    return SizedBox(
      height: SizeConfig.v * 15.75,
      child: BlocConsumer<CmtBBloc, CtState>(
        listener: (context, state) async {
          if (state is CtPrepereState) {
            final OrderingProvider4 ordProvider4 =
            Provider.of<OrderingProvider4>(context, listen: false);

            ordProvider4.setPaymentInProgress(true);

            final double sdacha = ordProvider4.getSdacha;
            final bool sdachaToCashback = ordProvider4.isChangeToCashback;

            // Click Pass orqali to'lov muvaffaqiyatli bo'lgan bo'lsa —
            // OFD yoniq/o'chiq farqi yo'q, har doim pressPaymentButtonOnlyOFD
            if (ordProvider4.clickPassPaid) {
              final PaymentResult result =
                  await ordProvider4.pressPaymentButtonOnlyOFD(homeContextt);

              if (result.success) {
                ctBloc.add(CtPaySuccessedEvent(
                  sdacha: sdacha,
                  showSdachaDialog: (sdacha > 0 && !sdachaToCashback),
                ));
              } else {
                ctBloc.add(CtErrorEvent(
                  error: loc.tolov_amalga_oshmadi,
                  subError: result.mxikError ?? "Click to'lov xatosi",
                ));
              }
              return;
            }

            // Boshqa to'lov turlari uchun eski logika
            final bool withOFD = Pref.getBool(PrefKeys.withOFD, false);

            if (withOFD && !Pref.getBool(PrefKeys.debtClick, false)) {
              final PaymentResult result =
                  await ordProvider4.pressPaymentButtonOnlyOFD(homeContextt);

              if (result.success) {
                ctBloc.add(CtPaySuccessedEvent(
                  sdacha: sdacha,
                  showSdachaDialog: (sdacha > 0 && !sdachaToCashback),
                ));
              } else {
                ctBloc.add(CtErrorEvent(
                  error: loc.tolov_amalga_oshmadi,
                  subError: result.mxikError ?? "none",
                ));
              }
            } else {
              await ordProvider4.pressPaymentButton(homeContextt);
              Pref.setBool(PrefKeys.debtClick, false);
              ctBloc.add(CtPaySuccessedEvent(
                sdacha: sdacha,
                showSdachaDialog: (sdacha > 0 && !sdachaToCashback),
              ));
            }
          }

          // Qolgan holatlar o'zgarmaydi
          if (state is CtPayingState) {
            // Bu yerda eski kod saqlanadi, lekin CtPrepereState da biz allaqachon boshqarib bo'ldik
          }

          if (state is CtSucceedState) {
            if (state.showSdachaDialog) {
              await showDialog(
                barrierDismissible: false,
                barrierColor: Colors.black.withOpacity(.5),
                context: context,
                builder: (context) => SdachaDialog(state.sdacha.toString()),
              );
            }
            await Pref.setBool('isPaper', false);
            await Pref.setBool("advance", false);
            await Pref.setBool("credit", false);
            AppNavigation.pop();
          }

          if (state is CtErrorState) {
            if (state.subError is! MxikError) {
              await Future.delayed(const Duration(seconds: 3));
            }
            AppNavigation.pop(v: state.subError);
          }
        },
        builder: (context, state) {
          if (state is CtInitialState) {
            if (context.read<OrderingProvider4>().getIsButtonEnabled &&
                !context.read<OrderingProvider4>().getPaymentInProgress) {
              return ButtonWidget(
                title: loc.yakunlash,
                onPredssed: () {
                  if (context.read<OrderingProvider4>().getIsButtonEnabled &&
                      !context.read<OrderingProvider4>().getPaymentInProgress) {
                    ctBloc.add(CtPrepareToPayEvent());
                  }
                },
              );
            }
          }

          if (state is CtSucceedState) {
            return ButtonWidget(
              title: "COMLETE",
              onPredssed: () {},
            );
          }

          if (state is CtErrorState) {
            return ButtonWidget(
              title: state.error.toString(),
              onPredssed: () {},
            );
          }

          if (state is CtLoadingState ||
              state is CtPayingState ||
              state is CtPrepereState) {
            return ButtonWidget(
              title: "${loc.kuting}...",
              onPredssed: () {},
            );
          }

          return ButtonWidget(
            title: loc.yakunlash,
            onPredssed: () {},
          );
        },
      ),
    );
  }
}