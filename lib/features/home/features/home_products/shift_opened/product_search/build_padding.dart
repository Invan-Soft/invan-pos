import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class BuildPadding extends StatelessWidget {
  const BuildPadding({
    Key? key,
    required this.children,
  }) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.v * 1.5,
        horizontal: SizeConfig.h * 2,
      ),
      child: Container(
        height: SizeConfig.v * 7,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
        ),
        child: Row(children: children),
      ),
    );
  }
}
