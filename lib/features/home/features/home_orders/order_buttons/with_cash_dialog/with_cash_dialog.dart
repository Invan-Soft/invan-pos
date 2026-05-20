import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/features/home_orders/order_buttons/with_cash_dialog/keyboard/keyboard_on_display.dart';
import 'package:invan2/changes/providers/provider_of_with_cash_dialog.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';

class WithCashDialog extends StatefulWidget {
  const WithCashDialog({
    Key? key,
    required this.totalPrice,
  }) : super(key: key);

  final double totalPrice;

  @override
  WithCashDialogState createState() => WithCashDialogState();
}

class WithCashDialogState extends State<WithCashDialog> {
  double kirim = 0;
  double farq = 0;
  double jami = 0;
  late WithCashProvider withCashProvider;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Provider.of<WithCashProvider>(context, listen: false)
        .initController(widget.totalPrice);
    jami = widget.totalPrice;
    kirim = jami;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final withCashProvider = Provider.of<WithCashProvider>(context);

    final orderingProvider =
        Provider.of<OrderingProvider4>(context, listen: false);
    // jami = orderingProvider.totalPrice;
    // kirim = jami;

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _digitBox(loc, context, withCashProvider, orderingProvider),
          const KeyboardOnWithCashPaymentDialog()
        ],
      ),
    );
  }

  _digitBox(AppLocalizations loc, BuildContext context,
      WithCashProvider withCashProvider, OrderingProvider4 orderingProvider) {
    return SizedBox(
      width: SizeConfig.h * 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${loc.jami.toUpperCase()}:',
                style: MyThemes.txtStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                MoneyFormatter.formatter.format(jami),
                style: MyThemes.txtStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${loc.kirim.toUpperCase()}:',
                style: MyThemes.txtStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: TextField(
                  focusNode: _focusNode,
                  controller: context.read<WithCashProvider>().controller,
                  autofocus: true,
                  style: MyThemes.txtStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.end,
                  inputFormatters: [
                    DecimalTextInputFormatter(),
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: MyThemes.txtStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onChanged: (v) {
                    if (v == '' || v == '.') {
                      kirim = 0;
                    } else {
                      withCashProvider.changeControllerValue(v);
                      kirim = double.parse(v);
                    }

                    farq = kirim - jami > 0 ? kirim - jami : 0;
                    setState(() {});
                  },
                  onSubmitted: (v) {
                    if (kirim - jami >= 0) {
                      // orderingProvider.payWithCash(
                      //   context: context,
                      //   sdacha: farq,
                      // );
                      AppNavigation.pop();
                    } else {
                      _focusNode.requestFocus();
                    }
                  },
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${loc.farq.toUpperCase()}:',
                style: MyThemes.txtStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                MoneyFormatter.formatter.format(farq),
                style: MyThemes.txtStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // withCashProvider.disposeController();
    _focusNode.dispose();
    super.dispose();
  }
}
