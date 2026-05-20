import 'package:invan2/features/features.dart';
import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class ItemSubCategory extends StatelessWidget {
  const ItemSubCategory({
    Key? key,
    required this.subCategory,
  }) : super(key: key);

  final SubCategoryModel subCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: HexColor.fromHex('#808080'),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(SizeConfig.v * .8),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5, right: 5),
            width: double.infinity,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Theme.of(context).bottomAppBarTheme.color,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(SizeConfig.v * .8),
              ),
            ),
            child: Text(
              subCategory.name ?? '',
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
