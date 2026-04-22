import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/payment/right/dilogs/paynet/bloc/paynet_bloc.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/default_button.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PaynetDialog extends StatelessWidget {
  final double summa;
  final Function() pay;
  final String receiptNumber;

  const PaynetDialog({
    required this.summa,
    required this.pay,
    required this.receiptNumber,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    BlBloc blBloc = BlocProvider.of(context);
    PaynetBloc paynetBloc = BlocProvider.of(context);

    Log.d('PaynetDialog build() — summa: $summa', name: 'PaynetDialog');

    blBloc.add(
      BlStatusChangedEvent(
        status: BLStatus.click,
        where: 'lib/features/payment/right/dilogs/paynet/paynet_dialog.dart build',
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
            // ignore: deprecated_member_use
            color: Theme.of(context).dialogBackgroundColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Material(
              // ignore: deprecated_member_use
              color: Theme.of(context).dialogBackgroundColor,
              child: Center(
                child: BlocBuilder<PaynetBloc, PaynetState>(
                  builder: (context, state) {
                    Log.d('PaynetDialog state: $state', name: 'PaynetDialog');

                    // ===== LOADING =====
                    if (state is PaynetLoadingState) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CupertinoActivityIndicator(
                            radius: SizeConfig.h * 5,
                          ),
                          Text(
                            _getLoadingMessage(state.status, loc),
                            textAlign: TextAlign.center,
                            style: MyThemes.txtStyle(
                              fontSize: 4,
                              color: MyThemes.textWhiteColor,
                            ),
                          ),
                        ],
                      );
                    }

                    // ===== MUVAFFAQIYATLI TO'LOV =====
                    if (state is PaynetPaymentSuccessState) {
                      Log.d('PaynetDialog — to\'lov muvaffaqiyatli', name: 'PaynetDialog');
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
                              Log.d('PaynetDialog — Ok bosildi, pay() chaqirilmoqda', name: 'PaynetDialog');
                              pay();
                              _closeBarcodeListener(blBloc);
                            },
                          ),
                        ],
                      );
                    }

                    // ===== XATO =====
                    if (state is PaynetPaymentErrorState) {
                      Log.e('PaynetDialog — xato: ${state.error}', name: 'PaynetDialog');
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
                            onPress: () => _closeBarcodeListener(blBloc),
                          ),
                        ],
                      );
                    }

                    // ===== INTERNET YO'Q =====
                    if (state is PaynetNoInternetState) {
                      Log.d('PaynetDialog — internet yo\'q, retry mumkin', name: 'PaynetDialog');
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
                            onPress: () => paynetBloc.add(
                              PaynetPayEvent(
                                isRetry: true,
                                otp: state.otp,
                                summa: summa,
                                receiptNumber: receiptNumber,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // ===== BOSHLANG'ICH: QR KUTISH =====
                    Log.d('PaynetDialog — QR skanlanishini kutmoqda', name: 'PaynetDialog');
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: VisibilityDetector(
                              key: const Key('paynet_dialog_visibility_key'),
                              onVisibilityChanged: (v) {
                                Log.d('PaynetDialog visibility: ${v.visibleFraction}', name: 'PaynetDialog');
                                blBloc.add(BlVisibilityChangedEvent(v.visibleFraction > 0));
                              },
                              child: MyBarcodeListener(
                                key: const Key('Paynet Pass'),
                                bufferDuration: const Duration(milliseconds: 300),
                                onBarcodeScannedClick: (v) {
                                  Log.d('PaynetDialog — barcode scanlandi: $v', name: 'PaynetDialog');
                                  paynetBloc.add(
                                    PaynetPayEvent(
                                      isRetry: false,
                                      otp: v,
                                      summa: summa,
                                      receiptNumber: receiptNumber,
                                    ),
                                  );
                                },
                                onBarcodeScanned: (v) {},
                                onBarcodeScannedMagnetic: (v) {},
                                onBarcodeScannedPayme: (v) {},
                                onBarcodeScannedClient: (v) {},
                                onShiftDeletePressed: () {},
                                onDelPressed: () {},
                                onF12Pressed: () {},
                                onF5pressed: () {},
                                onF1pressed: () {},
                                onF2pressed: () {},
                                onF3pressed: () {},
                                onDownPressed: () {},
                                onUpPressed: () {},
                                child: Text(
                                  MoneyFormatter.inputMoneyFormatter.format(summa),
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
                          onPress: () {
                            Log.d('PaynetDialog — bekor qilindi', name: 'PaynetDialog');
                            _closeBarcodeListener(blBloc);
                          },
                          isButtonEnabled: true,
                        ),
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

  void _closeBarcodeListener(BlBloc blBloc) {
    blBloc.add(BlStatusChangedEvent(status: BLStatus.other, where: 'paynet'));
    AppNavigation.pop();
  }

  String _getLoadingMessage(PaynetLoadingStatus status, AppLocalizations loc) {
    switch (status) {
      case PaynetLoadingStatus.internet:
        return loc.internet_tekshirilmoqda;
      case PaynetLoadingStatus.paying:
        return loc.tolov_amalga_oshirilmoqda;
    }
  }
}
