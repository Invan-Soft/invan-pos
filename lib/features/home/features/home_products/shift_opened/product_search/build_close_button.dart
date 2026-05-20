import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import '../../../../../../changes/providers/product_search_provider.dart';

class BuildCloseButton extends StatelessWidget {
  const BuildCloseButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productSearchProvider =
        Provider.of<ProductSearchProvider>(context, listen: false);

    return Padding(
      padding: EdgeInsets.only(right: SizeConfig.h),
      child: IconButton(
        focusNode: FocusNode(skipTraversal: true),
        onPressed: () {
          productSearchProvider.pressCloseSearchFieldButton();
        },
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        icon: const Icon(
          Icons.close,
        ),
      ),
    );
  }
}
