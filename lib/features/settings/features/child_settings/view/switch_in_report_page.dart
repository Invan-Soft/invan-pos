import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';

class SwitchTileOfReportPage extends StatelessWidget {
  final String title;
  final String? subtitle; // <-- yangi optional parametr
  final VoidCallback onTap;
  final Function(bool) onChanged;
  final bool activ;

  /// `false` bo'lsa switch qulflangan (masalan sozlama adminkadan boshqariladi).
  final bool enabled;

  const SwitchTileOfReportPage({
    required this.onChanged,
    required this.onTap,
    required this.title,
    required this.activ,
    this.subtitle,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 3.5),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: SizeConfig.h * .5,
              vertical: SizeConfig.v * 1.5,
            ),
            onTap: enabled ? onTap : null,
            title: Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.v),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: MyThemes.txtStyle(
                      fontSize: 2.7,
                      color: enabled
                          ? Theme.of(context).canvasColor
                          : Theme.of(context).disabledColor,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.v * 0.4),
                    Text(
                      subtitle!,
                      style: MyThemes.txtStyle(
                        fontSize: 2.0,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: CupertinoSwitch(
              value: activ,
              onChanged: enabled ? onChanged : null,
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: Theme.of(context).dividerColor,
          ),
        ],
      ),
    );
  }
}