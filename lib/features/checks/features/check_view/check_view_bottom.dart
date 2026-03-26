import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/singletons/organization_singleton.dart';
import 'package:invan2/features/checks/features/checks_list/bloc/check_f_bloc.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/util_functions.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';

import '../../../../utils/l10n/app_localizations.dart';

class CheckViewBottom extends StatelessWidget {
  const CheckViewBottom({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocBuilder<CheckFBloc, CheckFState>(
      builder: (context, state) {
        ReceiptModel4? selectedCheck = state.selectedCheck;
        double realTotalPrice = 0;
        if (selectedCheck != null) {
          for (ReceiptModelSoldItem4 item in selectedCheck.soldItemList) {
            realTotalPrice +=
                UtilFunctions.roundToNearest(item.value * item.onlyPrice);
          }
        }
        double width = 80;
        if (realTotalPrice.toStringAsFixed(0).length > 11) {
          width = 160;
        } else if (realTotalPrice.toStringAsFixed(0).length > 9) {
          width = 150;
        } else if (realTotalPrice.toStringAsFixed(0).length > 7) {
          width = 125;
        } else if (realTotalPrice.toStringAsFixed(0).length > 5) {
          width = 100;
        }
        final paymentList = selectedCheck!.payment;
        return Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.h * 2,
            right: SizeConfig.h * 1,
            bottom: SizeConfig.v * 3,
            top: SizeConfig.v * 2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.jami,
                    style: MyThemes.txtStyle(
                      color: Theme.of(context).canvasColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 2.3,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        MoneyFormatter.formatVat
                            .format(selectedCheck.totalPrice),
                        style: MyThemes.txtStyle(
                          color: Theme.of(context).canvasColor,
                          fontSize: 2.3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selectedCheck.totalPrice != realTotalPrice
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    MoneyFormatter.formatVat
                                        .format(realTotalPrice),
                                    textAlign: TextAlign.center,
                                    style: MyThemes.txtStyle(
                                      textDecoration:
                                          TextDecoration.lineThrough,
                                      fontSize: 2,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.normal,
                                      color: Theme.of(context).canvasColor,
                                    ),
                                  ),
                                  Container(
                                    height: 2,
                                    width: width,
                                    color: Colors.red,
                                  )
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ],
              ),
              ListView.builder(
                itemCount: paymentList.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final payment = paymentList[index];
                  double? cashPayment;
                  if (payment.name == 'cash') {
                    cashPayment = payment.value + selectedCheck.sdacha;
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getPaymentName(loc, payment.payId, payment.name),
                        style: MyThemes.txtStyle(
                          fontSize: 2.3,
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      Text(
                        cashPayment == null
                            ? MoneyFormatter.formatVat.format(payment.value)
                            : MoneyFormatter.formatVat.format(cashPayment),
                        style: MyThemes.txtStyle(
                          fontSize: 2.3,
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
              selectedCheck.sdacha == 0
                  ? const SizedBox(width: 0, height: 0)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.sdacha,
                          style: MyThemes.txtStyle(
                            fontSize: 2.3,
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        Text(
                          MoneyFormatter.formatVat.format(selectedCheck.sdacha),
                          style: MyThemes.txtStyle(
                            fontSize: 2.3,
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }
}

String _getPaymentName(AppLocalizations loc, String id, String name) {
  for (Payment p in otherPaymentsGlobal) {
    if (p.id == id.replaceFirst('@', '')) {
      if (p.id == Pref.getString(PrefKeys.cardId, "")) {
        return name.toUpperCase() == 'HUMO' ? 'HUMO' : 'UZCARD';
      } else if (p.id == Pref.getString(PrefKeys.clickId, "")) {
        return name.toUpperCase() == 'CLICK QR' ? 'CLICK QR' : 'CLICK PASS';
      } else if (p.id == Pref.getString(PrefKeys.uzumId, "")) {
        return name.toUpperCase() == 'UZUM QR' ? 'UZUM QR' : 'UZUM';
      } else if (p.id == Pref.getString(PrefKeys.paymeId, "")) {
        return name.toUpperCase() == 'PAYME QR' ? 'PAYME QR' : 'PAYME GO';
      } else {
        return p.name ?? 'NFC';
      }
    }
  }
  return 'NFC';
}
