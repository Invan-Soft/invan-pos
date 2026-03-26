import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import '../../../../../../changes/providers/product_search_provider.dart';
import 'package:invan2/utils/utils.dart';

class BuildTypeahead extends StatefulWidget {
  const BuildTypeahead({
    super.key,
    required this.loc,
    required this.searchType,
    required this.gridviewProvider,
    required this.orderingProvider4,
    required this.productSearchProvider,
  });

  final AppLocalizations loc;
  final SearchTypeEnum searchType;
  final OrderingProvider4 gridviewProvider;
  final OrderingProvider4 orderingProvider4;
  final ProductSearchProvider productSearchProvider;

  @override
  BuildTypeaheadState createState() => BuildTypeaheadState();
}

class BuildTypeaheadState extends State<BuildTypeahead> {
  TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();
  ItemModel? oneProduct;

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<ItemModel>(
      animationDuration: const Duration(seconds: 0),
      debounceDuration: const Duration(seconds: 0),
      noItemsFoundBuilder: null,
      hideOnEmpty: true,
      hideOnError: true,
      hideOnLoading: true,
      textFieldConfiguration: textFieldConfiguration(),
      onSuggestionSelected: onSuggestionSelected,
      itemBuilder: itemBuilder,
      suggestionsCallback: suggestionsCallback,
      suggestionsBoxDecoration: suggestionsBoxDecoration,
    );
  }

  final suggestionsBoxDecoration = SuggestionsBoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
  );

  Widget itemBuilder(BuildContext context, ItemModel product) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.h,
        vertical: SizeConfig.v,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            product.name!,
            style: MyThemes.txtStyle(
              fontSize: 2.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  TextFieldConfiguration textFieldConfiguration() {
    return TextFieldConfiguration(
      autofocus: true,
      controller: controller,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
      style: MyThemes.txtStyle(),
      inputFormatters: inputFormatters(),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: getHintText(),
        hintStyle: MyThemes.txtStyle(color: Colors.grey),
      ),
    );
  }

  List<ItemModel> suggestionsCallback(String pattern) {
    if (pattern == '') {
      return [];
    } else {
      List<ItemModel> list = [];

      if (widget.searchType == SearchTypeEnum.byProductName) {
        list = ItemsSingleton.searchProductsByName(pattern);
      } else if (widget.searchType == SearchTypeEnum.byBarcode) {
        list = ItemsSingleton.searchProductsByBarcode(pattern);
      } else {
        list = ItemsSingleton.searchProductsBySku(pattern);
      }

      if (list.length == 1) {
        oneProduct = list[0];
      } else {
        oneProduct = null;
      }

      return list;
    }
  }

  String getHintText() {
    switch (widget.searchType) {
      case SearchTypeEnum.option:
        return 'Search';
      case SearchTypeEnum.byProductName:
        return widget.loc.mahsulotNomiBoyichaQidirish;
      case SearchTypeEnum.byBarcode:
        return widget.loc.shtrixKodOrqaliQidirish;
      case SearchTypeEnum.bySKU:
        return widget.loc.artikulBoyichaQidirish;
    }
  }

  List<TextInputFormatter>? inputFormatters() {
    if (widget.searchType == SearchTypeEnum.bySKU) {
      return [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))];
    }
    return null;
  }

  void onSubmitted(String v) {
    if (oneProduct != null) {
      onSuggestionSelected(oneProduct!);
    } else {
      focusNode.requestFocus();
    }
  }

  void onSuggestionSelected(ItemModel product) {
    widget.productSearchProvider.pressCloseSearchFieldButton();
    widget.orderingProvider4.addProduct(
        context: context,
        value: 1,
        product: product,
        where: "BUILD TYPEAHEAD / onSuggestionSelected");
  }
}
