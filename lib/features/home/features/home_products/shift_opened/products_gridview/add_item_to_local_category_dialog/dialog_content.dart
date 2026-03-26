import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:provider/provider.dart';
import '../../../../../../../changes/providers/add_to_l_c_d_provider.dart';
import 'package:invan2/utils/utils.dart';
import 'list_part.dart';
import 'search_part.dart';

// maybe not in use
class AddItemToLocalCategoryDialog extends StatelessWidget {
  const AddItemToLocalCategoryDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final categoryList = CategorySingleton.categories;
    final productList = ItemsSingleton.products;

    return ChangeNotifierProvider(
      create: (BuildContext context) => AddItemToLocalCategoryDialogProvider(
        categoryList: categoryList,
        productList: productList,
      ),
      child: AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          width: SizeConfig.h * 45,
          height: SizeConfig.v * 85,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              SizeConfig.v,
            ),
            color: Theme.of(context).colorScheme.background,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).canvasColor,
                blurRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () {
                      AppNavigation.pop();
                    },
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).canvasColor,
                      size: SizeConfig.v * 3.5,
                    ),
                  ),
                  SizedBox(width: SizeConfig.h * 1.5),
                  Text(
                    loc.elementQoshish,
                    style: MyThemes.txtStyle(
                      fontSize: 2.6,
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                ],
              ),
              Divider(
                height: SizeConfig.v * 4,
                color: Theme.of(context).primaryColor,
              ),
              const SearchPart(),
              const ListPart(),
            ],
          ),
        ),
      ),
    );
  }
}
