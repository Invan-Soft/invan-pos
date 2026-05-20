import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/size_config.dart';

class PaginationButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final bool isActiv;
  const PaginationButton(
      {Key? key,
      required this.child,
      required this.onPressed,
      required this.isActiv})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SizeConfig.v)),
        padding: EdgeInsets.only(
            top: SizeConfig.v * 1.5,
            bottom: SizeConfig.v * 1.5,
            left: SizeConfig.v),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      onPressed: isActiv ? onPressed : null,
      child: child,
    );
  }
}
