import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';

class PathItem extends StatelessWidget {
  const PathItem({
    Key? key,
    required this.categoryData,
    required this.isLast,
  }) : super(key: key);

  final CategoryData categoryData;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          ">  ",
          style: MyThemes.txtStyle(
            fontSize: 1.6,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).canvasColor,
          ),
        ),
        isLast
            ? Text(
                categoryData.name!,
                style: MyThemes.txtStyle(
                  fontSize: 2.6,
                  color: Theme.of(context).canvasColor,
                ),
              )
            : TextButton(
                focusNode: FocusNode(skipTraversal: true),
                onPressed: () {
                  Provider.of<OrderingProvider4>(context, listen: false)
                      .pressPath(categoryData);
                },
                child: Text(
                  categoryData.name!,
                  style: MyThemes.txtStyle(
                    fontSize: 2.6,
                    color: Theme.of(context).canvasColor,
                  ),
                ),
              ),
      ],
    );
  }
}
