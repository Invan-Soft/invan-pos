import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/utils.dart';

import '../../../../../utils/l10n/app_localizations.dart';

class BuildListItem extends StatelessWidget {
  const BuildListItem({
    super.key,
    required this.receiptModel4,
    required this.onPressed,
    required this.isSelected,
  });

  final ReceiptModel4 receiptModel4;
  final VoidCallback onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final isUploaded = receiptModel4.uploaded;
    final isRefund = receiptModel4.isRefund;
    String paymentName = receiptModel4.payment.length > 2
        ? "mix"
        : (receiptModel4.payment.isEmpty
            ? "empty"
            : receiptModel4.payment.first.name);

    IconData iconData = Icons.money;
    if (paymentName == 'cash') {
      iconData = Icons.money;
    } else if (paymentName == 'mix') {
      iconData = Icons.blender;
    } else if (paymentName == 'gift') {
      iconData = Icons.card_giftcard;
    } else {
      iconData = Icons.credit_card;
    }

    final dateTime = DateTime.fromMillisecondsSinceEpoch(receiptModel4.date);
    final time = _storeTimeString(dateTime);
    return ListTile(
      onTap: onPressed,
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(.3),
      hoverColor: Theme.of(context).primaryColor.withOpacity(.3),
      leading: Icon(
        iconData,
        size: SizeConfig.v * 3.5,
        color: Theme.of(context).canvasColor,
      ),
      title: Text(
        MoneyFormatter.formatVat.format(receiptModel4.totalPrice),
        style: MyThemes.txtStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).canvasColor,
          fontSize: 2.3,
        ),
      ),
      subtitle: Text(
        time,
        style: MyThemes.txtStyle(
          color: Colors.grey,
          fontSize: 1.8,
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isUploaded
                  ? const SizedBox(width: 0, height: 0)
                  : Icon(
                      Icons.error_outline,
                      color: Colors.red.shade900.withOpacity(.8),
                      size: SizeConfig.v * 3,
                    ),
              const SizedBox(width: 10),
              Row(
                children: [
                  Text(
                    (receiptModel4.url == null || receiptModel4.url!.isEmpty) &&
                            !receiptModel4.isRefund
                        ? loc.ha == 'Ha'
                            ? '(Pre Check)'
                            : '(Пре Чек)'
                        : '',
                    style: MyThemes.txtStyle(
                      color: Colors.grey,
                      fontSize: 1.6,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    receiptModel4.externalId,
                    style: MyThemes.txtStyle(
                      color: Theme.of(context).canvasColor,
                      fontSize: 2.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          isRefund
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tolovniQaytarish,
                      style: MyThemes.txtStyle(
                        fontSize: 1.2,
                        color: Colors.red.shade900.withOpacity(.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    receiptModel4.returnForCheck != ""
                        ? Padding(
                            padding: EdgeInsets.only(left: SizeConfig.h),
                            child: Text(
                              receiptModel4.returnForCheck,
                              style: MyThemes.txtStyle(
                                color: Colors.red.shade900.withOpacity(.8),
                                fontWeight: FontWeight.bold,
                                fontSize: 1.2,
                              ),
                            ),
                          )
                        : const SizedBox(width: 0, height: 0),
                  ],
                )
              : const SizedBox(height: 0, width: 0),
        ],
      ),
    );
  }
}

String _storeTimeString(DateTime dateTime) {
  String t = '';
  if (dateTime.hour.toString().length != 1) {
    t += dateTime.hour.toString();
  } else {
    t += '0${dateTime.hour}';
  }
  t += ':';
  if (dateTime.minute.toString().length != 1) {
    t += dateTime.minute.toString();
  } else {
    t += '0${dateTime.minute}';
  }
  t += '   ';
  if (dateTime.day.toString().length != 1) {
    t += dateTime.day.toString();
  } else {
    t += '0${dateTime.day}';
  }
  t += '.';
  if (dateTime.month.toString().length != 1) {
    t += dateTime.month.toString();
  } else {
    t += '0${dateTime.month}';
  }
  t += '.${dateTime.year}';

  return t;
}
