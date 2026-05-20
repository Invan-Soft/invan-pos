import 'package:flutter/material.dart';

class SkuBySearchButton extends StatelessWidget {
  final VoidCallback onPressed;
  const SkuBySearchButton({required this.onPressed, Key? key})
      : super(key: key);

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
        "assets/images/skuText.png",
        color: Theme.of(context).canvasColor,
        scale: .8,
      ),
    );
  }
}
