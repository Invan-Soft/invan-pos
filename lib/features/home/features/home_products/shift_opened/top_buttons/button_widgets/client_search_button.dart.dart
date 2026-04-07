import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/helpers.dart';

class ClientSearchButton extends StatelessWidget {
  final VoidCallback onPressed;
  const ClientSearchButton({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      focusNode: FocusNode(skipTraversal: true),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        fixedSize: Size(SizeConfig.h * 3.5, SizeConfig.v * 7.37),
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.background,
      ),
      child: Icon(
        Icons.person_search_outlined,
        size: SizeConfig.v * 3.7,
        color: Theme.of(context).canvasColor,
      ),
    );
  }
}
