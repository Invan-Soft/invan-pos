import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/widgets.dart';
import 'package:invan2/features/features.dart';

import '../../../../utils/l10n/app_localizations.dart';

class ReturnPageDialogg extends StatefulWidget {
  const ReturnPageDialogg({
    super.key,
    required this.value,
  });

  final num value;

  @override
  ReturnPageDialogState createState() => ReturnPageDialogState();
}

class ReturnPageDialogState extends State<ReturnPageDialogg> {
  final TextEditingController _textEditingController = TextEditingController();

  late num value;

  @override
  void initState() {
    super.initState();
    if (widget.value % 1 == 0) {
      _textEditingController.text = widget.value.toStringAsFixed(0);
    } else {
      _textEditingController.text = widget.value.toString();
    }
    value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.background,
      content: SizedBox(
        height: SizeConfig.v * 30,
        width: SizeConfig.h * 20,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  loc.miqdor,
                  style: MyThemes.txtStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).canvasColor,
                    fontSize: 2.6,
                  ),
                ),
                SizedBox(width: SizeConfig.h * 2),
                Expanded(
                  child: TextField(
                    cursorColor: Theme.of(context).dividerColor,
                    decoration: InputDecoration(
                        border: _border(),
                        errorBorder: _border(),
                        enabledBorder: _border(),
                        focusedBorder: _border(),
                        disabledBorder: _border()),
                    autofocus: true,
                    style: MyThemes.txtStyle(
                      color: Theme.of(context).canvasColor,
                      fontSize: 2.6,
                      fontWeight: FontWeight.bold,
                    ),
                    controller: _textEditingController,
                    inputFormatters: [DecimalTextInputFormatter()],
                    onChanged: (v) {
                      if (v == '' || v == '.') {
                        value = 0;
                      } else {
                        value = double.parse(v);
                      }
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            DefaultButton(
              text: 'OK',
              isButtonEnabled: value <= widget.value && value > 0,
              isErrorButton: false,
              onPress: () {
                if (value <= widget.value && value > 0) {
                  AppNavigation.pop(v: value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  UnderlineInputBorder _border() {
    return UnderlineInputBorder(
      borderSide: BorderSide(
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}
