import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';

class SettingSwitchListTile extends StatelessWidget {
  final bool activ;
  final String title;
  final Function(bool) onChanged;

  const SettingSwitchListTile(
      {required this.activ,required this.title, required this.onChanged, Key? key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 3.5),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.only(
              left: SizeConfig.v * 2.3,
              bottom: SizeConfig.v * 1.5,
              top: SizeConfig.v * 1.5,
              right: SizeConfig.v,
            ),
            onTap: () {},
            title: Text(
             title,
              style: MyThemes.txtStyle(
                  fontSize: 2.7, color: Theme.of(context).canvasColor),
            ),
            trailing: CupertinoSwitch(
              value: activ,
              onChanged: onChanged,
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
