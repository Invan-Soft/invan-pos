import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/payment/right/dilogs/click/bloc/click_bloc.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:invan2/widgets/default_button.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ClickPassDialog extends StatelessWidget {
  final double summa;
  final Function() pay;
  final String receiptNumber;
  const ClickPassDialog({
    required this.receiptNumber,
    required this.summa,
    required this.pay,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    BlBloc blBloc = BlocProvider.of(context);
    ClickBloc clickBloc = BlocProvider.of(context);
    blBloc.add(
      BlStatusChangedEvent(
        status: BLStatus.click,
        where:
            "lib/features/payment/right/dilogs/click/clic_pass_dialog.dart build",
      ),
    );
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.only(
          top: SizeConfig.v * 12,
          right: SizeConfig.h * 3,
        ),
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
              color: Theme.of(context).dialogBackgroundColor),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Material(
              color: Theme.of(context).dialogBackgroundColor,
              child: Center(
                child: BlocBuilder<ClickBloc, ClickState>(
                  builder: (context, state) {
                    if (state is ClickLoadingState) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CupertinoActivityIndicator(
                            radius: SizeConfig.h * 5,
                          ),
                          Text(
                            getMessage(state.status, loc),
                            textAlign: TextAlign.center,
                            style: MyThemes.txtStyle(
                              fontSize: 4,
                              color: MyThemes.textWhiteColor,
                            ),
                          ),
                        ],
                      );
                    }
                    if (state is ClickPaymentSuccessState) {
                      return Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                loc.tolov_amalga_oshirildi,
                                textAlign: TextAlign.center,
                                style: MyThemes.txtStyle(
                                  fontSize: 4,
                                  color: MyThemes.textWhiteColor,
                                ),
                              ),
                            ),
                          ),
                          DefaultButton(
                            isButtonEnabled: true,
                            text: "Ok",
                            onPress: () {
                              pay();
                              _onBarcodeListenerChanged(blBloc);
                            },
                          )
                        ],
                      );
                    }
                    if (state is ClickPaymentErrorState) {
                      return Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                state.error,
                                textAlign: TextAlign.center,
                                style: MyThemes.txtStyle(
                                  fontSize: 4,
                                  color: MyThemes.textWhiteColor,
                                ),
                              ),
                            ),
                          ),
                          DefaultButton(
                            isButtonEnabled: true,
                            text: "Ok",
                            onPress: () => _onBarcodeListenerChanged(blBloc),
                          )
                        ],
                      );
                    }
                    if (state is ClickNoInternetState) {
                      return Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                loc.internet_yoq,
                                textAlign: TextAlign.center,
                                style: MyThemes.txtStyle(
                                  fontSize: 4,
                                  color: MyThemes.textWhiteColor,
                                ),
                              ),
                            ),
                          ),
                          DefaultButton(
                            isErrorButton: false,
                            isButtonEnabled: true,
                            text: loc.qayta_urinish,
                            onPress: () => clickBloc.add(ClickPayEvent(
                                isRetry: true,
                                otp: state.otp,
                                summa: summa,
                                receiptNumber: receiptNumber)),
                          )
                        ],
                      );
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: VisibilityDetector(
                              key: const Key(
                                  "Click_pass_dialog_visibility_detectorKey"),
                              onVisibilityChanged: (v) {
                                blBloc.add(BlVisibilityChangedEvent(
                                    v.visibleFraction > 0));
                              },
                              child: MyBarcodeListener(
                                onBarcodeScannedClick: (v) => clickBloc.add(
                                  ClickPayEvent(
                                    isRetry: false,
                                    otp: v,
                                    summa: summa,
                                    receiptNumber: receiptNumber,
                                  ),
                                ),
                                onBarcodeScannedMagnetic: (v) {},
                                onBarcodeScannedPayme: (v) {},
                                onShiftDeletePressed: () {},
                                onDelPressed: () {},
                                onF12Pressed: () {},
                                onF5pressed: () {},
                                key: const Key("Click Pass"),
                                bufferDuration:
                                    const Duration(milliseconds: 300),
                                onBarcodeScanned: (v) {},
                                onF1pressed: () {},
                                onF2pressed: () {},
                                onF3pressed: () {},
                                onDownPressed: () {  },
                                onUpPressed: () {  },
                                onBarcodeScannedClient: (s ) {  },
                                child: Text(
                                  MoneyFormatter.inputMoneyFormatter
                                      .format(summa),
                                  textAlign: TextAlign.center,
                                  style: MyThemes.txtStyle(
                                    fontSize: 8,
                                    color: Theme.of(context).canvasColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        DefaultButton(
                          text: loc.bekor_qilish,
                          onPress: () => _onBarcodeListenerChanged(blBloc),
                          isButtonEnabled: true,
                        )
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onBarcodeListenerChanged(BlBloc blBloc) {
    blBloc.add(BlStatusChangedEvent(status: BLStatus.other, where: 'click'));
    AppNavigation.pop();
  }

  String getMessage(ClickLoadingStatus v, AppLocalizations loc) {
    switch (v) {
      case ClickLoadingStatus.internet:
        return loc.internet_tekshirilmoqda;
      case ClickLoadingStatus.paying:
        return loc.tolov_amalga_oshirilmoqda;
    }
  }
}

enum ClickLoadingStatus { internet, paying }
