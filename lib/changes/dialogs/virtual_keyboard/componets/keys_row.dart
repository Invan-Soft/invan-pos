import 'package:flutter/material.dart';
class KeysRow extends StatelessWidget {
  final double height;
  final List<Widget> keys;
  final double separatorWidth;

  const KeysRow({
    Key? key,
    required this.height,
    required this.keys,
    required this.separatorWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (int i = 0; i < keys.length; i++) ...[
            if (i != 0) SizedBox(width: separatorWidth),
            keys[i],
          ]
        ],
      ),
    );
  }
}