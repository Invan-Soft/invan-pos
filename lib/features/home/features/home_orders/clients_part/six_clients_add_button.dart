import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class SixClientsAddButton extends StatelessWidget {
  const SixClientsAddButton({
    Key? key,
    required this.color,
    required this.onPressed,
  }) : super(key: key);
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: MaterialButton(
        focusNode: FocusNode(skipTraversal: true),
        color: color,
        minWidth: SizeConfig.v * 7,
        height: SizeConfig.v * 7,
        onPressed: onPressed,
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: SizeConfig.v * 3,
        ),
      ),
    );
  }
}
