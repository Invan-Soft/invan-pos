import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';
import 'package:provider/provider.dart';
import 'path_item.dart';

class Path extends StatelessWidget {
  const Path({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final OrderingProvider4 productsGridviewProvider =
        Provider.of<OrderingProvider4>(context);
    final pathList = productsGridviewProvider.getPathList;

    final LocalCategoryProvider localCategoryProvider =
        Provider.of<LocalCategoryProvider>(context);
    final currentSelectedCategoryButton =
        localCategoryProvider.getCurrentSelectedCategoryButton;
    final mainPathName = localCategoryProvider.getMainPathName;
    return Container(
      padding: EdgeInsets.only(left: SizeConfig.h),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextButton(
              focusNode: FocusNode(skipTraversal: true),
              child: Text(
                currentSelectedCategoryButton < 0 ? loc.barchasi : mainPathName,
                style: MyThemes.txtStyle(
                  fontSize: 2.6,
                  color: Theme.of(context).canvasColor,
                ),
              ),
              onPressed: () {
                if (currentSelectedCategoryButton < 0) {
                  productsGridviewProvider.pressAllPath();
                } else {
                  localCategoryProvider
                      .pressBarchasiButtonWhenCategorySelected(context);
                  productsGridviewProvider.clearPathList();
                }
              },
            ),
            ListView.builder(
              itemCount: pathList.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final path = pathList[index];
                return PathItem(
                  categoryData: path,
                  isLast: index == pathList.length - 1,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
