import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invan2/changes/providers/shift_closed_provider.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';

class SmenaOchishDialog extends StatefulWidget {
  const SmenaOchishDialog({super.key});

  @override
  SmenaOchishDialogState createState() => SmenaOchishDialogState();
}

class SmenaOchishDialogState extends State<SmenaOchishDialog> {
  int startingCash = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SizedBox(
      width: SizeConfig.h * 40,
      height: SizeConfig.v * 35,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FDGFDGENOIRNO',
            style: MyThemes.txtStyle(
              fontSize: 2.8,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            loc.boshlangichMiqdor,
            style: MyThemes.txtStyle(),
          ),
          TextField(
            onChanged: (v) {
              setState(() {
                if (v == '') {
                  startingCash = 0;
                } else {
                  startingCash = int.parse(v);
                }
              });
            },
            autofocus: true,
            style: MyThemes.txtStyle(fontSize: 2.8),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: MyThemes.txtStyle(
                color: Colors.grey,
                fontSize: 2.8,
              ),
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
          ),
          MaterialButton(focusNode: FocusNode(skipTraversal: true),
            onPressed: () =>
                Provider.of<ShiftClosedProvider>(context, listen: false)
                    .onOpenShiftButtonPressed(context),
            color: Theme.of(context).primaryColor,
            height: SizeConfig.v * 8,
            minWidth: double.infinity,
            child: Text(
              'SDIFBIERBFIGBEIGUB',
              style: MyThemes.txtStyle(
                fontSize: 2.6,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
