import 'package:invan2/features/features.dart';
import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class ItemCategory extends StatelessWidget {
  const ItemCategory({
    Key? key,
    required this.categoryData,
  }) : super(key: key);

  final CategoryData categoryData;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          flex: 4,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Pref.getBool(PrefKeys.isDarkMode, true)
                      ? HexColor.fromHex('#808080')
                      : HexColor.fromHex('#C4C4C5'),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(SizeConfig.v * .8),
                  ),
                ),
              ),
              /*Positioned(
                top: 5,
                right: 5,
                child: Image.asset(
                  height: 25,
                  width: 25,
                  "assets/images/category-tag.png",
                  fit: BoxFit.cover,
                  color: Theme.of(context).bottomAppBarTheme.color,
                ),
              ),*/
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding:
                const EdgeInsets.only(left: 10, top: 5, bottom: 5, right: 5),
            width: double.infinity,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Theme.of(context).bottomAppBarTheme.color,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(SizeConfig.v * .8),
              ),
            ),
            child: Text(
              categoryData.name ?? '',
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              maxLines: 2,
              style: MyThemes.txtStyle(
                fontSize: 1.6,
                color: Theme.of(context).canvasColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
