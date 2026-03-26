import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';

class ProductSearchButton extends StatelessWidget {
  final VoidCallback onPressed;
  const ProductSearchButton({required this.onPressed, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return TextButton(
      focusNode: FocusNode(skipTraversal: true),
      style: TextButton.styleFrom(
          padding: const EdgeInsets.all(0.0),
          minimumSize: Size(SizeConfig.h * 15, SizeConfig.v * 5),
          foregroundColor: Theme.of(context).colorScheme.background.withOpacity(.4)),
      onPressed: onPressed,
      child: Container(
        width: SizeConfig.h * 18,
        height: SizeConfig.v * 4.5,
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 1),
        decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: BorderRadius.circular(SizeConfig.v * 1.17)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.mahsulotNomiBoyichaQidirish,
              overflow: TextOverflow.fade,
              style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor, fontSize: 2),
            ),
            Image.asset(
              "assets/images/search.png",
              color: Theme.of(context).canvasColor,
            )
          ],
        ),
      ),
    );
  }
}
