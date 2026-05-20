import 'package:cached_network_image/cached_network_image.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class ItemProductWhenEditing extends StatelessWidget {
  const ItemProductWhenEditing({
    Key? key,
    required this.product,
    required this.onDeletePressed,
  }) : super(key: key);

  final ItemModel product;

  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: product.image != null && product.image!.isNotEmpty
                    ? SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(SizeConfig.v * .8)),
                          child: CachedNetworkImage(
                            imageUrl: product.image!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey.withOpacity(.7),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.withOpacity(.7),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        // color: HexColor.fromHex(product.representation!),
                        color: Colors.blue,
                      ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5),
                width: double.infinity,
                color: Colors.white,
                alignment: Alignment.centerLeft,
                child: Text(
                  product.name!,
                  maxLines: 2,
                  style: MyThemes.txtStyle(fontSize: 2.4),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: MaterialButton(
            focusNode: FocusNode(skipTraversal: true),
            color: Colors.white,
            minWidth: 10,
            height: 10,
            elevation: 0,
            onPressed: onDeletePressed,
            child: Icon(
              Icons.close,
              size: SizeConfig.v * 5,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
