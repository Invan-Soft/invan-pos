import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/size_config.dart';

class BgOfNad extends StatelessWidget {
  final Widget child;
  final Color color;
  const BgOfNad({required this.child, required this.color, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.v * 3),
      alignment: Alignment.center,
      width: SizeConfig.h * 40.58,
      height: SizeConfig.v * 75.7,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          SizeConfig.v * 1.1,
        ),
      ),
      child: child,
    );
  }
}
