import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';

class SettingsSwitch extends StatelessWidget {
  final String title;
  final ValueChanged<bool> onChanged;
  final bool value;
  final bool? isSubtitle;

  const SettingsSwitch({
    Key? key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.isSubtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppLocalizations? loc = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isSubtitle != null && isSubtitle!
              ? "$title ${loc?.activligi}"
              : title,
          style: TextStyle(
              fontSize: SizeConfig.v * 4,
              color: Theme.of(context).dividerColor),
        ),
        Transform.scale(
          scale: 1.8,
          child: Switch(
            materialTapTargetSize: MaterialTapTargetSize.padded,
            activeTrackColor: Theme.of(context).primaryColor.withOpacity(.5),
            inactiveTrackColor: Theme.of(context).disabledColor,
            thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.disabled)) {
                return Colors.orange.withOpacity(.48);
              }
              return Theme.of(context).primaryColor;
            }),
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
