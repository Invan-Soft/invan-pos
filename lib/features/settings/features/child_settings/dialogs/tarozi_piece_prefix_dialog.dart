import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';

class TaroziPiecePrefixDialog extends StatefulWidget {
  const TaroziPiecePrefixDialog({super.key});

  @override
  TaroziPiecePrefixDialogState createState() => TaroziPiecePrefixDialogState();
}

class TaroziPiecePrefixDialogState extends State<TaroziPiecePrefixDialog> {
  int prefix = 21;
  final _controller = TextEditingController();
  bool isButtonValid = true;

  @override
  void initState() {
    super.initState();
    prefix = Pref.getInt(PrefKeys.taroziPiecePrefix, 21);
    _controller.text = prefix.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.v),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
      content: SizedBox(
        width: SizeConfig.h * 30,
        height: SizeConfig.v * 25,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              loc.taroziShtuchniyUchunShtrixKodPrefixiniKiriting,
              style: MyThemes.txtStyle(
                color: Theme.of(context).canvasColor,
                fontSize: 2.6,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              autofocus: true,
              onChanged: (v) {
                if (v.length == 2) {
                  prefix = int.parse(v);
                  isButtonValid = true;
                } else {
                  isButtonValid = false;
                }
                setState(() {});
              },
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                LengthLimitingTextInputFormatter(2),
              ],
              controller: _controller,
              textAlign: TextAlign.center,
              style: MyThemes.txtStyle(
                color: Theme.of(context).canvasColor,
                fontSize: 2.7,
                fontWeight: FontWeight.bold,
              ),
            ),
            MaterialButton(
              focusNode: FocusNode(skipTraversal: true),
              onPressed: isButtonValid
                  ? () async {
                      await Pref.setInt(PrefKeys.taroziPiecePrefix, prefix);
                      AppNavigation.pop();
                    }
                  : null,
              color: Theme.of(context).primaryColor,
              minWidth: double.infinity,
              height: SizeConfig.v * 7,
              disabledColor: Theme.of(context).primaryColor.withOpacity(.7),
              child: Text(
                loc.saqlash.toUpperCase(),
                style: MyThemes.txtStyle(
                  fontSize: 2.7,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
