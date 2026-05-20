import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import 'products_gridview_item.dart';

class ProductsGridview extends StatefulWidget {
  const ProductsGridview({super.key});

  @override
  ProductsGridviewState createState() => ProductsGridviewState();
}

class ProductsGridviewState extends State<ProductsGridview> {
  final ScrollController _productsGridviewController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        right: SizeConfig.v,
        left: SizeConfig.v,
      ),
      child: GridView.count(
        padding: EdgeInsets.only(top: SizeConfig.v * 3),
        crossAxisSpacing: SizeConfig.v,
        mainAxisSpacing: SizeConfig.v,
        controller: _productsGridviewController,
        physics: const BouncingScrollPhysics(),
        childAspectRatio: .797,
        crossAxisCount: 3,
        children: _mapIndexed(
          context.watch<OrderingProvider4>().getItems,
          (index, item) => ProductsGridviewItem(
            item: item,
            isCategory: item is CategoryData,
            onDeletePressed: () {
              Provider.of<LocalCategoryProvider>(context, listen: false)
                  .removeItemFromLocalCategoryList(index, context);
            },
            position: index,
          ),
        ).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _productsGridviewController.dispose();
    super.dispose();
  }
}

Iterable<E> _mapIndexed<E, T>(
    Iterable<T> items, E Function(int index, T item) f) sync* {
  var index = 0;

  for (final item in items) {
    yield f(index, item);
    index = index + 1;
  }
}
