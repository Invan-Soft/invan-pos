import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';


class PrinterNotSelectedDialog extends StatelessWidget {
  final String text;

  const PrinterNotSelectedDialog({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: CupertinoAlertDialog(
        content: Text(
          text,
          style: const TextStyle(fontSize: 22),
        ),
        actions: [
          CupertinoButton(
            child: const Text(
              "Ok",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () => AppNavigation.pop(),
          ),
        ],
      ),
    );
  }
}
