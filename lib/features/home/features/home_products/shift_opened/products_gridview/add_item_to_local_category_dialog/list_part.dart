import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/utils/themes.dart';
import 'package:provider/provider.dart';
import '../../../../../../../changes/providers/add_to_l_c_d_provider.dart';
import 'package:invan2/features/features.dart';

class ListPart extends StatelessWidget {
  const ListPart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AddItemToLocalCategoryDialogProvider>(context);
    final productList = provider.getProductsForSearch;
    final categoryList = provider.categoryList;

    return Expanded(
      child: provider.getThereProducts
          ? ListView.separated(
              itemBuilder: (context, index) {
                final product = productList[index];
                return Material(
                  color: Theme.of(context).dialogBackgroundColor,
                  child: ListTile(
                    title: Text(
                      product.name!,
                      style: MyThemes.txtStyle(
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                    trailing: Text(
                      // product.price == null
                      //     ? "0"
                      //     : product.price!.toStringAsFixed(2),
                      product.shopPrices!.shID!.shopPriceTiers![0].retailPrice == null
                          ? "0"
                          : product.shopPrices!.shID!.shopPriceTiers![0].retailPrice!
                              .toStringAsFixed(2),

                      style: MyThemes.txtStyle(
                        fontSize: 2.2,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                    hoverColor: Theme.of(context).primaryColor.withOpacity(.3),
                    tileColor: Theme.of(context).dialogBackgroundColor,
                    onTap: () {
                      Provider.of<LocalCategoryProvider>(context, listen: false)
                          .addItemToLocalCategoryList(
                              LocalCategoryItemModel(
                                id: product.id!,
                                isCategory: false,
                              ),
                              context);

                      AppNavigation.pop();
                    },
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return const Divider(
                  height: 0,
                  thickness: 0.5,
                  color: Colors.black45,
                );
              },
              itemCount: productList.length,
              physics: const BouncingScrollPhysics(),
            )
          : ListView.separated(
              itemBuilder: (context, index) {
                final category = categoryList[index];

                return Material(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(
                      category.name!,
                      style: MyThemes.txtStyle(
                        fontSize: 2.2,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                    // trailing: Text(
                    //   category.iV.toString(),
                    //   style:const  TextStyle(
                    //     color: Colors.black,
                    //   ),
                    // ),
                    hoverColor: Theme.of(context).primaryColor.withOpacity(.3),
                    tileColor: Theme.of(context).dialogBackgroundColor,
                    onTap: () {
                      Provider.of<LocalCategoryProvider>(context, listen: false)
                          .addItemToLocalCategoryList(
                              LocalCategoryItemModel(
                                id: category.id ?? "",
                                isCategory: true,
                              ),
                              context);

                      AppNavigation.pop();
                    },
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return const Divider(
                  height: 0,
                  thickness: 0.5,
                  color: Colors.black45,
                );
              },
              itemCount: categoryList.length,
              physics: const BouncingScrollPhysics(),
            ),
    );
  }
}
