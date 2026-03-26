import 'package:flutter/material.dart';

// ignore: must_be_immutable
class SwitchableKey extends StatelessWidget {
  final Alignment? alignment;
  final double? width;
  final double? height;
  final String char;
  bool value;
  final Function(String) onPressed;

  SwitchableKey({
    Key? key,
    this.value = false,
    this.alignment,
    this.width,
    this.height,
    required this.char,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onPressed(char);
      },
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(context).style.copyWith(color: Colors.white),
        child: Container(
          alignment: alignment,
          width: width,
          height: height,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF23272D),
                Color(0xFF1C1B1E),
              ],
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
            const   Text(""),
              const Spacer(),
              Text(
                char,
                style:  TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: value? Colors.pinkAccent:null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
