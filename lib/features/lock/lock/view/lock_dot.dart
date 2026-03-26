import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class LockDot extends StatelessWidget {
  const LockDot({Key? key, required this.isColored}) : super(key: key);

  final bool isColored;

  @override
  Widget build(BuildContext context) {
    if (isColored) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.v),
        child: Container(
          width: SizeConfig.v * 1.5,
          height: SizeConfig.v *1.5,
          decoration: const BoxDecoration(
            color:  Color(0xffC4C4C4),
            shape: BoxShape.circle,
          ),
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.v),
        child: Container(
          width: SizeConfig.v * 1.5,
          height: SizeConfig.v * 1.5,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xffC4C4C4),
              width: 2,
            ),
          ),
        ),
      );
    }
  }
}
