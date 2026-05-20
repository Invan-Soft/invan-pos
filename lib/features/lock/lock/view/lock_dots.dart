import 'package:flutter/material.dart';
import 'lock_dot.dart';

class LockDots extends StatelessWidget {
  final int typed;
  final int passwordLength;
  const LockDots(this.typed, {required this.passwordLength, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> dots = [
      LockDot(isColored: typed > 0),
      LockDot(isColored: typed > 1),
      LockDot(isColored: typed > 2),
      LockDot(isColored: typed > 3),
      LockDot(isColored: typed > 4),
      LockDot(isColored: typed > 5),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(passwordLength, (i) => dots[i]),
    );
  }
}
