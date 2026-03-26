import 'package:invan2/features/features.dart';
import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class ItemCategoryWhenEditing extends StatelessWidget {
  const ItemCategoryWhenEditing({
    Key? key,
    required this.categoryData,
    required this.onDeletePressed,
  }) : super(key: key);

  final CategoryData categoryData;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                child:
                    //  categoryData.presentType == 'image'
                    //     ? SizedBox(
                    //         width: double.infinity,
                    //         height: double.infinity,
                    //         child: ClipRRect(
                    //           borderRadius: BorderRadius.vertical(
                    //               top: Radius.circular(SizeConfig.v * .8)),
                    //           child: CachedNetworkImage(
                    //             imageUrl: categoryData.image!,
                    //             fit: BoxFit.cover,
                    //             placeholder: (_, __) => Container(
                    //               color: Colors.grey.withOpacity(.7),
                    //             ),
                    //             errorWidget: (_, __, ___) => Container(
                    //               color: Colors.grey.withOpacity(.7),
                    //             ),
                    //           ),
                    //         ),
                    //       )
                    //     :
                    // Container(
                    //     color:
                    //         HexColor.fromHex(categoryData.color ?? '#808080'),
                    //   ),
                    Container(
                  color: HexColor.fromHex('#808080'),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5),
                width: double.infinity,
                color: Colors.white,
                alignment: Alignment.centerLeft,
                child: Text(
                  categoryData.name ?? '',
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
