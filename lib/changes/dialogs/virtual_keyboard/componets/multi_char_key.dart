import 'package:flutter/material.dart';
import 'package:invan2/changes/dialogs/virtual_keyboard/componets/macbook_key.dart';

class MultiCharKey extends StatelessWidget {
  final String upperChar;
  final String lowerChar;
  final Alignment? alignment;
  final double? width;
  final double? height;
  final Function(List<String>) onPressed;

  const MultiCharKey({
    Key? key,
    required this.upperChar,
    required this.lowerChar,
    this.alignment,
    this.width,
    this.height,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MacbookKey(
      width: width,
      height: height,
      onPressed: () {
        onPressed([upperChar, lowerChar]);
      },
      child: Center(
        child: Column(
          children: [
            Text(
              upperChar,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              lowerChar,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
