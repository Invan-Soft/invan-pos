import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/bloc/payme/payme_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PaymeDialog extends StatefulWidget {
  VoidCallback callback;

  PaymeDialog({super.key, required this.callback});

  @override
  State<PaymeDialog> createState() => _PaymeDialogState();
}

class _PaymeDialogState extends State<PaymeDialog> {
  bool _visible = false;
  bool _transaksiyaSuccess = false;

  @override
  Widget build(BuildContext context) {
    BlBloc blBloc = BlocProvider.of(context, listen: false);
    blBloc.add(BlStatusChangedEvent(
        status: BLStatus.payme,
        where: "lib/changes/dialogs/payme_dialog.dart"));
    AppLocalizations loc = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        height: SizeConfig.v * 60,
        width: SizeConfig.h * 40,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).canvasColor,
              blurRadius: 5,
            ),
          ],
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(
            SizeConfig.v,
          ),
        ),
        child: BlocConsumer<PaymeBloc, PaymeState>(
          listener: (ctx, state) {
            if (state is PaymeFailCreate) {}
            if (state is PaymeSuccessCreate) {
              _transaksiyaSuccess = true;
              setState(() {});
            }
            if (state is PaymeSuccessPay) {
              widget.callback();
            }
          },
          builder: (ctx, state) {
            if (state is PaymeLoading) {
              return Center(
                child: SpinKitCircle(
                  color: Theme.of(context).primaryColor,
                ),
              );
            }

            if (state is PaymeSuccessCreate) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VisibilityDetector(
                      onVisibilityChanged: (VisibilityInfo v) {
                        blBloc.add(
                            BlVisibilityChangedEvent(v.visibleFraction > 0));
                        _visible = v.visibleFraction > 0;
                      },
                      key: const Key('visibility_key_of_payme_dialog'),
                      child: MyBarcodeListener(
                        onBarcodeScannedPayme: (String paymeCode) {
                          if (!_visible || !_transaksiyaSuccess) return;
                          PaymeBloc paymeBloc = BlocProvider.of(context);
                          paymeBloc.add(PaymePayEvent(paymeCode));
                        },
                        onBarcodeScannedClick: (v) {},
                        onBarcodeScannedMagnetic: (v) {},
                        onShiftDeletePressed: () {},
                        onDelPressed: () {},
                        onF12Pressed: () {},
                        onF5pressed: () {},
                        key: const Key("Payme Scanner"),
                        onBarcodeScanned: (v) {},
                        bufferDuration: const Duration(milliseconds: 300),
                        onF1pressed: () {},
                        onF2pressed: () {},
                        onF3pressed: () {},
                        onDownPressed: () {},
                        onUpPressed: () {},
                        onBarcodeScannedClient: (s) {},
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "${(state.amount)}",
                                style: MyThemes.txtStyle(
                                  fontSize: 8,
                                  color: Theme.of(context).canvasColor,
                                ),
                              ),
                              TextSpan(
                                text: loc.tarnsaksiya_yaratildi,
                                style: MyThemes.txtStyle(
                                  fontSize: 3,
                                  color: Theme.of(context).canvasColor,
                                ),
                              ),
                              TextSpan(
                                text: loc.kartani_oqiting,
                                style: MyThemes.txtStyle(
                                  fontSize: 8,
                                  color: Theme.of(context).canvasColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is PaymeFailCreate) {
              return Center(
                  child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: MyThemes.txtStyle(
                  fontSize: 6,
                  color: Theme.of(context).canvasColor,
                ),
              ));
            }

            if (state is PaymeSuccessPay) {
              return Center(
                child: Text(
                  loc.tolov_amalga_oshirildi,
                  textAlign: TextAlign.center,
                  style: MyThemes.txtStyle(
                    fontSize: 6,
                    color: Theme.of(context).canvasColor,
                  ),
                ),
              );
            }

            if (state is PaymeFailPay) {
              return Center(
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: MyThemes.txtStyle(
                    fontSize: 6,
                    color: Theme.of(context).canvasColor,
                  ),
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
