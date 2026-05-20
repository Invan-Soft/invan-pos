import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/helpers.dart';

class CreatProductButton extends StatelessWidget {
  final VoidCallback onPressed;
  const CreatProductButton({required this.onPressed, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      focusNode: FocusNode(skipTraversal: true),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        fixedSize: Size(SizeConfig.h * 5, SizeConfig.v * 7.37),
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.background,
      ),
      child: Icon(
        Icons.create_new_folder_rounded,
        size: SizeConfig.v * 3.7,
        color: Theme.of(context).canvasColor,
      ),
    );
  }
}
