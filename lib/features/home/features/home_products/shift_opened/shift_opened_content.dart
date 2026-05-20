import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:provider/provider.dart';
import '../../../../../changes/providers/product_search_provider.dart';
import 'product_search/product_search_3.dart';
import 'top_buttons/top_buttons.dart';
import 'products_gridview/products_gridview.dart';
import 'bottom_buttons/bottom_buttons.dart';
import 'package:invan2/utils/utils.dart';

class ShiftOpenedContent extends StatelessWidget {
  const ShiftOpenedContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => ProductSearchProvider(),
      builder: (context, child) {
        final ProductSearchProvider productSearchProvider =
        Provider.of<ProductSearchProvider>(context);
        final searchState = productSearchProvider.getSearchState;
        final LocalCategoryProvider localCategoryProvider =
        Provider.of<LocalCategoryProvider>(context);
        final isEditingLocalCategory =
            localCategoryProvider.getIsLocalCategoryEditing;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            searchState ? const ProductSearch3() : const TopButtons(),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ProductsGridview(),
                  ),
                  Positioned(
                    bottom: SizeConfig.v * 2,
                    right: SizeConfig.h * 4,
                    child: isEditingLocalCategory
                        ? FloatingActionButton(
                      focusNode: FocusNode(skipTraversal: true),
                      heroTag: 'done_button_for_local_category',
                      onPressed: () async {
                        await localCategoryProvider.pressDoneButton();
                        Provider.of<OrderingProvider4>(
                          context,
                          listen: false,
                        ).changeGridviewItems(null);
                      },
                      child: Icon(
                        Icons.done,
                        size: SizeConfig.v * 5,
                        color: Colors.white,
                      ),
                    )
                        : const SizedBox(width: 0, height: 0),
                  ),
                ],
              ),
            ),
            searchState
                ? SizedBox(
              height: SizeConfig.v * 10,
              width: double.infinity,
            )
                : const BottomButtons(),
          ],
        );
      },
    );
  }
}
