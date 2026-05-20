import 'package:flutter/material.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/themes.dart';
import 'package:provider/provider.dart';
import '../../../../../../changes/providers/product_search_provider.dart';

class SearchListItem extends StatelessWidget {
  const SearchListItem({
    super.key,
    required this.product,
  });

  final ItemModel product;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: ListTile(
        onTap: () {
          Provider.of<OrderingProvider4>(context, listen: false).addProduct(
              context: context,
              value: 1,
              product: product,
              where: "SEARCH LIST ITEM / ");

          Provider.of<ProductSearchProvider>(context, listen: false)
              .pressCloseSearchFieldButton();
        },
        title: Row(
          children: [
            Flexible(
              child: Text(
                product.name!,
                style: MyThemes.txtStyle(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Text(
          product.shopPrices!.shID!.shopPriceTiers![0].retailPrice!
              .toStringAsFixed(2),
          style: MyThemes.txtStyle(),
        ),
        contentPadding: const EdgeInsets.all(0),
      ),
    );
  }
}
