import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class SearchPartItem extends StatelessWidget {
  const SearchPartItem({
    Key? key,
    required this.isSelected,
    required this.text,
    required this.onPress,
  }) : super(key: key);

  final bool isSelected;
  final String text;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        height: SizeConfig.v * 6,
        color: Colors.transparent,
        width: SizeConfig.h * 15,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  text,
                  style: MyThemes.txtStyle(
                    color: Theme.of(context).canvasColor,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: SizeConfig.v * .5,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
