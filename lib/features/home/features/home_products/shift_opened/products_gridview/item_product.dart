import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/utils/utils.dart';

class ItemProduct extends StatelessWidget {
  const ItemProduct({Key? key, required this.product}) : super(key: key);

  final ItemModel product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SizeConfig.v * .8),
        boxShadow: const [
          BoxShadow(color: Colors.grey, blurRadius: 1),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            flex: 4,
            // child: !product.representation!.startsWith('#')
            child: product.image != null
                ? Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(SizeConfig.v * .8),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(SizeConfig.v * .8),
                      ),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            width: double.infinity,
                            height: double.infinity,
                            imageUrl: product.image!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              decoration: BoxDecoration(
                                color: Pref.getBool(PrefKeys.isDarkMode, true)
                                    ? HexColor.fromHex('#9F9F9F')
                                    : HexColor.fromHex('#CFCFCF'),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(SizeConfig.v * .8),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                color: Pref.getBool(PrefKeys.isDarkMode, true)
                                    ? HexColor.fromHex('#9F9F9F')
                                    : HexColor.fromHex('#CFCFCF'),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(SizeConfig.v * .8),
                                ),
                              ),
                            ),
                          ),
                          Pref.getBool(PrefKeys.isDarkMode, true)
                              ? Container(color: Colors.black.withOpacity(.05))
                              : const SizedBox(),
                        ],
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Pref.getBool(PrefKeys.isDarkMode, true)
                          ? HexColor.fromHex('#9F9F9F')
                          : HexColor.fromHex('#CFCFCF'),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(SizeConfig.v * .8),
                      ),
                    ),
                  ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding:
                  const EdgeInsets.only(left: 10, top: 5, bottom: 5, right: 5),
              width: double.infinity,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Theme.of(context).bottomAppBarTheme.color,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(SizeConfig.v * .8),
                ),
              ),
              child: Text(
                product.name ?? "",
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                maxLines: 2,
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                  fontSize: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
