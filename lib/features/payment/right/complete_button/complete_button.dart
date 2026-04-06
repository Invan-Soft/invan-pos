// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:invan2/app_navigation.dart';
// import 'package:invan2/changes/dialogs/sdacha_dialog.dart';
// import 'package:invan2/changes/models/ofd/incom_response_model.dart';
// import 'package:invan2/features/features.dart';
// import 'package:invan2/features/payment/right/complete_button/components/button_widget.dart';
// import 'package:invan2/utils/constants/constants.dart';
// import 'package:invan2/utils/helpers/helpers.dart';
// import 'package:invan2/widgets/my_snackbar.dart';
// import 'package:provider/provider.dart';
// import '../../../../changes/models/ofd/payment_result_model.dart';
// import 'complete_bloc/comlete_bloc.dart';

// class CompleteButtonOfPaymentPageOnBloc extends StatelessWidget {
//   final BuildContext homeContextt;

//   const CompleteButtonOfPaymentPageOnBloc(this.homeContextt, {Key? key})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     CmtBBloc ctBloc = BlocProvider.of(context, listen: false);
//     AppLocalizations loc = AppLocalizations.of(context)!;
//     return SizedBox(
//       height: SizeConfig.v * 15.75,
//       child: BlocConsumer<CmtBBloc, CtState>(
//         listener: (context, state) async {
//           if (state is CtPrepereState) {
//             OrderingProvider4 ordProvider4 =
//                 Provider.of<OrderingProvider4>(context, listen: false);
//             ordProvider4.setPaymentInProgress(true);
//             double sdacha = ordProvider4.getSdacha;
//             bool sdachaToCashback = ordProvider4.isChangeToCashback;
//             bool ofd = Pref.getBool(PrefKeys.withOFD, false);

//             ctBloc.add(
//               CtPayEvent(
//                 sdacha: sdacha,
//                 ofd: ofd,
//                 sdachaToCashbak: sdachaToCashback,
//               ),
//             );
//           }
//           if (state is CtPayingState) {
//             if (state.ofd && !Pref.getBool(PrefKeys.debtClick, false)) {
//               PaymentResult result = await Provider.of<OrderingProvider4>(
//                 context,
//                 listen: false,
//               ).pressPaymentButtonOnlyOFD(homeContextt);
//               if (result.success) {
//                 ctBloc.add(
//                   CtPaySuccessedEvent(
//                     sdacha: state.sdacha,
//                     showSdachaDialog:
//                         (state.sdacha > 0 && !state.sdachaToCashback),
//                   ),
//                 );
//               } else {
//                 ctBloc.add(
//                   CtErrorEvent(
//                       error: result.errorMessage ?? loc.tolov_amalga_oshmadi,
//                       subError: result.mxikError ?? "none"),
//                 );
//               }
//               return;
//             }
//             await Provider.of<OrderingProvider4>(context, listen: false)
//                 .pressPaymentButton(homeContextt);
//             Pref.setBool(PrefKeys.debtClick, false);
//             ctBloc.add(
//               CtPaySuccessedEvent(
//                 sdacha: state.sdacha,
//                 showSdachaDialog: (state.sdacha > 0 && !state.sdachaToCashback),
//               ),
//             );
//           }

//           if (state is CtSucceedState) {
//             if (state.showSdachaDialog) {
//               await showDialog(
//                 barrierDismissible: false,
//                 barrierColor: Colors.black.withOpacity(.5),
//                 context: context,
//                 builder: (context) => SdachaDialog(state.sdacha.toString()),
//               );
//             }
//             await Pref.setBool('isPaper', false);
//             await Pref.setBool("advance", false);
//             await Pref.setBool("credit", false);
//             AppNavigation.pop();
//           }
//           if (state is CtErrorState) {
//             if (state.subError is! MxikError) {
//               // ignore: use_build_context_synchronously
//               final messenger = ScaffoldMessenger.of(context);
//               // ignore: use_build_context_synchronously
//               final snack = mySnackBar(context, msg: state.error, duration: 4000);
//               messenger.showSnackBar(snack);
//               await Future.delayed(const Duration(seconds: 4));
//             }

//             AppNavigation.pop(v: state.subError);
//           }
//         },
//         builder: (context, state) {
//           if (state is CtInitialState) {
//             if (context.read<OrderingProvider4>().getIsButtonEnabled &&
//                 !context.read<OrderingProvider4>().getPaymentInProgress) {
//               return ButtonWidget(
//                 title: loc.yakunlash,
//                 onPredssed: () {
//                   if (context.read<OrderingProvider4>().getIsButtonEnabled &&
//                       !context.read<OrderingProvider4>().getPaymentInProgress) {
//                     ctBloc.add(CtPrepareToPayEvent());
//                   }
//                 },
//               );
//             }
//           }
//           if (state is CtSucceedState) {
//             return ButtonWidget(
//               title: "COMLETE",
//               onPredssed: () {},
//             );
//           }
//           if (state is CtErrorState) {
//             return ButtonWidget(
//               title: "${loc.kuting}...",
//               onPredssed: () {},
//             );
//           }
//           if (state is CtLoadingState || state is CtPayingState) {
//             return ButtonWidget(
//               title: "${loc.kuting}...",
//               onPredssed: () {},
//             );
//             // return const LoadingWidgetOfCompleteButton();
//           }

//           return ButtonWidget(
//             title: "ERROR",
//             onPredssed: () {},
//           );
//         },
//       ),
//     );
//   }
// }
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
            OrderingProvider4 ordProvider4 =
                Provider.of<OrderingProvider4>(context, listen: false);
            ordProvider4.setPaymentInProgress(true);
            double sdacha = ordProvider4.getSdacha;
            bool sdachaToCashback = ordProvider4.isChangeToCashback;
            bool ofd = Pref.getBool(PrefKeys.withOFD, false);

            ctBloc.add(
              CtPayEvent(
                sdacha: sdacha,
                ofd: ofd,
                sdachaToCashbak: sdachaToCashback,
              ),
            );
          }
          if (state is CtPayingState) {
            if (state.ofd && !Pref.getBool(PrefKeys.debtClick, false)) {
              PaymentResult result = await Provider.of<OrderingProvider4>(
                context,
                listen: false,
              ).pressPaymentButtonOnlyOFD(homeContextt);
              if (result.success) {
                ctBloc.add(
                  CtPaySuccessedEvent(
                    sdacha: state.sdacha,
                    showSdachaDialog:
                        (state.sdacha > 0 && !state.sdachaToCashback),
                  ),
                );
              } else {
                ctBloc.add(
                  CtErrorEvent(
                      error: loc.tolov_amalga_oshmadi,
                      subError: result.mxikError ?? "none"),
                );
              }
              return;
            }
            await Provider.of<OrderingProvider4>(context, listen: false)
                .pressPaymentButton(homeContextt);
            Pref.setBool(PrefKeys.debtClick, false);
            ctBloc.add(
              CtPaySuccessedEvent(
                sdacha: state.sdacha,
                showSdachaDialog: (state.sdacha > 0 && !state.sdachaToCashback),
              ),
            );
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
          if (state is CtLoadingState || state is CtPayingState) {
            return ButtonWidget(
              title: "${loc.kuting}...",
              onPredssed: () {},
            );
            // return const LoadingWidgetOfCompleteButton();
          }

          return ButtonWidget(
            title: "ERROR",
            onPredssed: () {},
          );
        },
      ),
    );
  }
}

