import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:invan2/widgets/default_button.dart';
import '../../../../utils/l10n/app_localizations.dart';
import '../../return_page/right/return_dialog/return_dialog.dart';
import 'bloc/pre_ofd/preofd_bloc.dart';

class PreOfdDialog extends StatelessWidget {
  final String clientNumber;
  final ReceiptModel4 receiptModel4;

  const PreOfdDialog({
    super.key,
    required this.clientNumber,
    required this.receiptModel4,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    PreOfdBloc preOfdBloc = BlocProvider.of(context, listen: false);
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.only(
          top: SizeConfig.v * 12,
          right: SizeConfig.h * 3,
        ),
        child: Material(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            padding: EdgeInsets.all(SizeConfig.h * 3),
            width: SizeConfig.h * 53,
            height: SizeConfig.v * 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).canvasColor,
                  blurRadius: 13,
                  spreadRadius: 1,
                  offset: const Offset(1, 1),
                ),
              ],
              color: Theme.of(context).colorScheme.background,
            ),
            child: Center(
              child: BlocBuilder<PreOfdBloc, PreOfdState>(
                builder: (context, state) {
                  if (state is PreOfdLoadingState) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CupertinoActivityIndicator(
                                radius: SizeConfig.h * 5,
                              ),
                              Text(
                                getMessage(state.message, loc),
                                textAlign: TextAlign.center,
                                style: MyThemes.txtStyle(
                                    fontSize: 4,
                                    color: Theme.of(context).canvasColor),
                              ),
                            ],
                          ),
                        ),
                        state.message == ReturnMessage.internet
                            ? DefaultButton(
                                text: loc.bekor_qilish,
                                isButtonEnabled: true,
                                onPress: () => AppNavigation.pop(),
                              )
                            : const SizedBox()
                      ],
                    );
                  }
                  if (state is PreOfdNoInternetState) {
                    return Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              loc.internet_yoq,
                              style: MyThemes.txtStyle(
                                  fontSize: 4,
                                  color: Theme.of(context).canvasColor),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: DefaultButton(
                                isErrorButton: true,
                                isButtonEnabled: true,
                                text: loc.bekor_qilish,
                                onPress: () => AppNavigation.pop(),
                              ),
                            ),
                            SizedBox(
                              width: SizeConfig.v * 4,
                            ),
                            Expanded(
                              child: DefaultButton(
                                isButtonEnabled: true,
                                text: loc.qayta_urinish,
                                onPress: () => preOfdBloc.add(
                                  SetPreOfdEvent(
                                    isRetry: true,
                                    clientNumber: clientNumber,
                                    receiptModel4: receiptModel4,
                                    loc: loc,
                                    // toOFD: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    );
                  }
                  if (state is PreOfdFailedState) {
                    return Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  loc.qaytarish_amalga_oshirilmadi,
                                  style: MyThemes.txtStyle(
                                      fontSize: 4,
                                      color: Theme.of(context)
                                          .canvasColor
                                          .withOpacity(.6)),
                                ),
                                SizedBox(height: SizeConfig.v * 2),
                                Text(
                                  "Error: ${state.error} ",
                                  style: MyThemes.txtStyle(
                                      fontSize: 4,
                                      color: Theme.of(context).canvasColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: DefaultButton(
                                isErrorButton: true,
                                isButtonEnabled: true,
                                text: loc.bekor_qilish,
                                onPress: () => AppNavigation.pop(),
                              ),
                            ),
                            SizedBox(
                              width: SizeConfig.v * 4,
                            ),
                            Expanded(
                              child: DefaultButton(
                                isButtonEnabled: true,
                                text: loc.qayta_urinish,
                                onPress: () => preOfdBloc.add(
                                  SetPreOfdEvent(
                                    isRetry: true,
                                    clientNumber: clientNumber,
                                    receiptModel4: receiptModel4,
                                    loc: loc,
                                    // toOFD: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    );
                  }
                  if (state is PreOfdSuccedState) {
                    return Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              loc.jonatish_tugatildi,
                              style: MyThemes.txtStyle(
                                  fontSize: 4,
                                  color: Theme.of(context).canvasColor),
                            ),
                          ),
                        ),
                        DefaultButton(
                          isButtonEnabled: true,
                          text: "Ok",
                          onPress: () => AppNavigation.pop(),
                        ),
                      ],
                    );
                  }
                  return Text("${state.toString()}this is PreOfd dialog");
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String getMessage(ReturnMessage v, AppLocalizations loc) {
    switch (v) {
      case ReturnMessage.internet:
        return loc.internet_tekshirilmoqda;
      case ReturnMessage.returnig:
        return loc.kuting;
    }
  }
}
