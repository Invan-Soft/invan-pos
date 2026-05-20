// ignore: must_be_immutable
import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/widgets/default_button.dart';

class PaymentTripleDotDialog extends StatelessWidget {
  final ValueChanged<int> onPressed;
  const PaymentTripleDotDialog({
    required this.onPressed,
    Key? key,
  }) : super(key: key);
  final List<String> options = const ["Debt"];
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: SizeConfig.v * 25,
          right: SizeConfig.h * 3,
        ),
        child: Container(
          width: SizeConfig.h * 20,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 13,
                  spreadRadius: 1,
                  offset: Offset(1, 1),
                ),
              ],
              color: Theme.of(context).colorScheme.background),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Material(
                color: Theme.of(context).dialogBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                        options.length,
                        (__) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: DefaultButton(
                                isButtonEnabled: true,
                                text: options[__],
                                onPress: () => onPressed(__),
                              ),
                            )),
                  ),
                )),
          ),
        ),
      ),
    );
  }
}
