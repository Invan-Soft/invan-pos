import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class ItemListTile extends StatelessWidget {
  const ItemListTile({
    Key? key,
    required this.text,
    required this.onPress,
  }) : super(key: key);

  final String text;
  final VoidCallback onPress;

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
            onTap: onPress,
            title: Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.h),
              child: Text(
                text,
                style: MyThemes.txtStyle(
                    fontSize: 2.7, color: Theme.of(context).canvasColor),
              ),
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
