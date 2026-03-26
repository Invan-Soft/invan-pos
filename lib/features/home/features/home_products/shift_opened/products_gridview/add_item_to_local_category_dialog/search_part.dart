import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';
import 'package:provider/provider.dart';
import '../../../../../../../changes/providers/add_to_l_c_d_provider.dart';
import 'search_part_item.dart';

class SearchPart extends StatelessWidget {
  const SearchPart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final AddItemToLocalCategoryDialogProvider provider =
        Provider.of<AddItemToLocalCategoryDialogProvider>(context);
    final searchState = provider.getSearchState;
    final thereProducts = provider.getThereProducts;

    return Container(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.v * 2),
      width: double.infinity,
      height: SizeConfig.v * 10,
      child: searchState
          ? Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: SizeConfig.h),
                      child: TextField(
                    
                        autofocus: true,
                        onChanged: (v) {
                          provider.typeWordForSearch(v);
                        },
                        decoration: InputDecoration(
                          hintText: loc.qidirish,
                          hintStyle: MyThemes.txtStyle(
                            color: Colors.grey,
                            fontSize: 2.4,
                          ),
                          border: InputBorder.none,
                        ),
                        style: MyThemes.txtStyle(fontSize: 2.4,color: Theme.of(context).canvasColor),
                      ),
                    ),
                  ),
                  IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).canvasColor,
                    ),
                    onPressed: () {
                      provider.pressSearchIconButton();
                    },
                  ),
                  SizedBox(width: SizeConfig.h),
                ],
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SearchPartItem(
                        isSelected: thereProducts,
                        text: loc.tovarlar,
                        onPress: () {
                          provider.setThereProducts(true);
                        },
                      ),
                      SearchPartItem(
                        isSelected: !thereProducts,
                        text: loc.kategoriyalar,
                        onPress: () {
                          provider.setThereProducts(false);
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    icon: Icon(
                      Icons.search,
                      color: Theme.of(context).canvasColor,
                    ),
                    onPressed: () {
                      provider.pressSearchIconButton();
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
