import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';

import '../../utils/constants/constants.dart';
import '../../utils/helpers/helpers.dart';

class PrinterNotSelectedDialog extends StatelessWidget {
  final String text;

  const PrinterNotSelectedDialog({Key? key, required this.text})
      : super(key: key);

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
