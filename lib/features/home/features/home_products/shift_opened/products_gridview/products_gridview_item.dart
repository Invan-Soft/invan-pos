// ignore_for_file: unnecessary_cast
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/products_gridview/item_subcategory.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import 'item_category.dart';
import 'item_product.dart';
import 'item_category_when_editing.dart';
import 'item_product_when_editing.dart';
import 'add_item_to_local_category_dialog/dialog_content.dart';

class ProductsGridviewItem extends StatelessWidget {
  const ProductsGridviewItem({
    Key? key,
    required this.item,
    required this.isCategory,
    required this.onDeletePressed,
    required this.position,
  }) : super(key: key);

  final dynamic item;
  final bool isCategory;
  final VoidCallback onDeletePressed;
  final int position;

  @override
  Widget build(BuildContext context) {
    final LocalCategoryProvider localCategoryProvider =
        Provider.of<LocalCategoryProvider>(context);
    final isEditingLocalCategory =
        localCategoryProvider.getIsLocalCategoryEditing;
    final currentCategoryButton =
        localCategoryProvider.getCurrentSelectedCategoryButton;

    return ElevatedButton(
      focusNode: FocusNode(skipTraversal: true),
      style: ElevatedButton.styleFrom(
          elevation: item == null ? 0 : 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SizeConfig.v * .8),
          ),
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.all(0.0)),
      onLongPress: () {
        if (!isEditingLocalCategory) {
          localCategoryProvider.setLocalCategoryEditing();
        }
      },
      onPressed: () async {
        if (isEditingLocalCategory) {
          if (currentCategoryButton >= 0) {
            showDialog(
                context: context,
                builder: (_) => const AddItemToLocalCategoryDialog());
            localCategoryProvider.pressCategoryProductPosition(position);
          }
        } else {
          if (item == null) {
            return;
          } else {
            if (isCategory) {
              Provider.of<OrderingProvider4>(context, listen: false)
                  .pressCategory(item as CategoryData);
            } else {
              final ItemModel product = item as ItemModel;

              Provider.of<OrderingProvider4>(
                context,
                listen: false,
              ).pressProduct(context, product, "PRODUCT GRID VIEW ITEM");
            }
          }
        }
      },
      child: isEditingLocalCategory && currentCategoryButton >= 0
          ? _buildChildWhenEditing(item, onDeletePressed)
          : _buildChild(item, context),
    );
  }

  Widget _buildChild(dynamic item, BuildContext con) {
    if (item != null) {
      if (isCategory) {
        return ItemCategory(categoryData: item as CategoryData);
      } else {
        return ItemProduct(product: item as ItemModel);
      }
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(con).colorScheme.background,
          borderRadius: BorderRadius.circular(SizeConfig.v * .8),
        ),
      );
    }
  }

  Widget _buildChildWhenEditing(dynamic item, VoidCallback onDeletePressed) {
    if (item != null) {
      if (isCategory) {
        return ItemCategoryWhenEditing(
          categoryData: item as CategoryData,
          onDeletePressed: onDeletePressed,
        );
      } else {
        return ItemProductWhenEditing(
          product: item as ItemModel,
          onDeletePressed: onDeletePressed,
        );
      }
    } else {
      return Center(
        child: Icon(
          Icons.add,
          color: Colors.grey,
          size: SizeConfig.v * 6,
        ),
      );
    }
  }
}
