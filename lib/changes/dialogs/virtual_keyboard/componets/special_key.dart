import 'package:flutter/material.dart';
import 'package:invan2/changes/dialogs/virtual_keyboard/componets/macbook_key.dart';

class SpecialKey extends StatelessWidget {
  final Alignment? alignment;
  final String? symbol;
  final String label;
  final double? width;
  final double? height;
  final Function(String) onPressed;

  const SpecialKey({
    Key? key,
    this.alignment,
    required this.label,
    this.symbol,
    this.height,
    this.width,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MacbookKey(
      alignment: alignment,
      onPressed: () {
        onPressed(label);
      },
      width: width,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(symbol ?? "null"),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
