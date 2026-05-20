import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class ReturnPageCard extends StatelessWidget {
  const ReturnPageCard({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.v * 3),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
               BoxShadow(
                color:  Theme.of(context).dialogBackgroundColor,
                offset:const Offset(.5, .5),
                blurRadius: 3,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
