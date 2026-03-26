import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import 'build_close_button.dart';
import 'build_padding.dart';
import 'build_typeahead.dart';
import '../../../../../../changes/providers/product_search_provider.dart';
import 'package:invan2/features/features.dart';

class ProductSearch3 extends StatelessWidget {
  const ProductSearch3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final productSearchProvider = Provider.of<ProductSearchProvider>(context);
    final searchType = productSearchProvider.getSearchTypeEnum;

    final gridviewProvider =
        Provider.of<OrderingProvider4>(context, listen: false);

    final orderingProvider =
        Provider.of<OrderingProvider4>(context, listen: false);

    return BuildPadding(
      children: [
        SizedBox(width: SizeConfig.h),
        Expanded(
          child: BuildTypeahead(
            loc: loc,
            searchType: searchType,
            gridviewProvider: gridviewProvider,
            orderingProvider4: orderingProvider,
            productSearchProvider: productSearchProvider,
          ),
        ),
        const BuildCloseButton(),
      ],
    );
  }
}
