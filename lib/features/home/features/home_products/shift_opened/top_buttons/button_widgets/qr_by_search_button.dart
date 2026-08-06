import 'package:flutter/material.dart';

class QrBySearchButton extends StatelessWidget {
  final VoidCallback onPressed;
  const QrBySearchButton({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      focusNode: FocusNode(skipTraversal: true),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        shadowColor: Theme.of(context).colorScheme.background,
      ),
      onPressed: onPressed,
      child: Image.asset(
        "assets/images/barcode.png",
        color: Theme.of(context).canvasColor,
        scale: .8,
      ),
    );
  }
}
