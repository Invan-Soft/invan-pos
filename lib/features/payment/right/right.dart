import 'package:flutter/material.dart';
import 'package:invan2/features/payment/right/keyboard_of_payment_page.dart';
import 'package:invan2/features/payment/right/payment_tablo.dart';
import 'package:invan2/utils/utils.dart';

class Right extends StatefulWidget {
  final BuildContext homeContext;
  const Right(this.homeContext, {Key? key}) : super(key: key);
  @override
  RightState createState() => RightState();
}
class RightState extends State<Right> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SizeConfig.v * 88,
      width: SizeConfig.h * 43.65,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const PaymentTablo(),
          KeyboardOfPaymentPage(widget.homeContext),
        ],
      ),
    );
  }
}
