import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';

class ItemListTileSwitch extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Function(bool) onChanged;
  final bool activ;
  const ItemListTileSwitch(
      {required this.onChanged,
      required this.onTap,
      required this.title,
      required this.activ,
      Key? key})
      : super(key: key);

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
            onTap: onTap,
            title: Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.h),
              child: Text(
                title,
                style: MyThemes.txtStyle(
                    fontSize: 2.7, color: Theme.of(context).canvasColor),
              ),
            ),
            trailing: CupertinoSwitch(value: activ, onChanged: onChanged),
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
