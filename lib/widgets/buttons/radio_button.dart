import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';

import '../../utils/l10n/app_localizations.dart';

class AppRadioButton extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool group;
  const AppRadioButton({
    super.key,
    required this.value,
    required this.group,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return RadioListTile( 
      focusNode: FocusNode(skipTraversal: true),
      value: value,
      groupValue: group,  
      onChanged: onChanged,
      activeColor: Theme.of(context).canvasColor,
      title: Text(value ? loc.erkak : loc.ayol,
          style: TextStyle(color: Theme.of(context).canvasColor)),
    );
  }
}
