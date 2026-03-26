import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';

class SixClientsButton extends StatelessWidget {
  const SixClientsButton({
    Key? key,
    required this.onPressed,
    required this.clientNumber,
    required this.isSelected,
  }) : super(key: key);

  final VoidCallback onPressed;
  final int clientNumber;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.v * .75,
        horizontal: SizeConfig.h * .2,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SizeConfig.v * 2),
        child: MaterialButton(
          focusNode: FocusNode(skipTraversal: false),
          elevation: 0,
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).dialogBackgroundColor,
          minWidth: SizeConfig.v * 5.2,
          height: SizeConfig.v * 4.4,
          onPressed: onPressed,
          child: Text(
            '${loc.mijoz} $clientNumber',
            style: MyThemes.txtStyle(
              color: isSelected ? Colors.white : Theme.of(context).canvasColor,
              fontSize: 2,
            ),
          ),
        ),
      ),
    );
  }
}
