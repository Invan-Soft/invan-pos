import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';

class SearchProductButton extends StatefulWidget {
  final int productLength;
  final bool selected;
  final VoidCallback onPressed;
  final String title;
  final List<String>? barcodes;
  final String? sku;
  final num price;

  const SearchProductButton({
    Key? key,
    required this.productLength,
    required this.onPressed,
    required this.selected,
    required this.title,
    required this.price,
    this.barcodes,
    this.sku,
  }) : super(key: key);

  @override
  State<SearchProductButton> createState() => _SearchProductButtonState();
}

class _SearchProductButtonState extends State<SearchProductButton> {
  String barcode = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    barcode = '\t\t';
    if (widget.barcodes != null) {
      for (int i = 0; i < widget.barcodes!.length - 1; i++) {
        if (i == 0) {
          barcode += widget.barcodes![i];
        } else {
          barcode += ' / ${widget.barcodes![i]}';
        }
      }
    }
    return SizedBox(
      height: 120,
      child: MaterialButton(
        color: widget.selected
            ? Theme.of(context).primaryColor.withOpacity(.3)
            : null,
        focusNode: FocusNode(skipTraversal: true),
        onPressed: widget.onPressed,
        hoverColor: Theme.of(context).primaryColor.withOpacity(.4),
        hoverElevation: 0,
        focusColor: Theme.of(context).primaryColor.withOpacity(.3),
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.h * .5,
            right: SizeConfig.h * .5,
            top: SizeConfig.v,
            bottom: SizeConfig.v,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: MyThemes.txtStyle(
                          color: Theme.of(context).canvasColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        barcode,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: MyThemes.txtStyle(
                          color: Theme.of(context).canvasColor,
                          fontWeight: FontWeight.w100,
                          fontSize: 1.7,
                        ),
                      ),
                      Text(
                        '\t\t${widget.sku}',
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: MyThemes.txtStyle(
                          color: Theme.of(context).canvasColor,
                          fontWeight: FontWeight.w100,
                          fontSize: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    widget.price.toString(),
                    textAlign: TextAlign.end,
                    style: MyThemes.txtStyle(
                      color: Theme.of(context).canvasColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
