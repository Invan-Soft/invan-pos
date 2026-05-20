import 'package:flutter/material.dart';

class SelectSearchButton extends StatelessWidget {
  final Color bacColor;
  final String imageUrl;

  const SelectSearchButton(
      {required this.bacColor, required this.imageUrl, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: bacColor,
      ),
      child: Image.asset(
        height: 40,
        width: 40,
        imageUrl,
        color: Theme.of(context).canvasColor,
        scale: .8,
      ),
    );
  }
}
