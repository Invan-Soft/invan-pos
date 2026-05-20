import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/rule_cash/rule_cash_button.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import '../../../changes/providers/rule_cash_provider.dart';

class Left extends StatefulWidget {
  const Left({Key? key}) : super(key: key);

  @override
  LeftState createState() => LeftState();
}

class LeftState extends State<Left> {
  final _moneyController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final ruleCashProvider = Provider.of<RuleCashProvider>(context);
    final isButtonValid = ruleCashProvider.getIsButtonValid;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.h * 2,
        vertical: SizeConfig.v * 2,
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (v) {
              ruleCashProvider.typeMoney(v);
            },
            controller: _moneyController,
            style: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
            decoration: InputDecoration(
              enabledBorder: _border(false),
              focusedBorder: _border(true),
              hintText: loc.miqdor,
              hintStyle:
                  MyThemes.txtStyle(color: Theme.of(context).dividerColor),
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
          ),
          SizedBox(height: SizeConfig.v * 2),
          TextField(
            onChanged: (v) {
              ruleCashProvider.typeNote(v);
            },
            controller: _noteController,
            style: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
            decoration: InputDecoration(
              enabledBorder: _border(false),
              focusedBorder: _border(true),
              hintText: loc.izoh,
              hintStyle:
                  MyThemes.txtStyle(color: Theme.of(context).dividerColor),
            ),
          ),
          SizedBox(height: SizeConfig.v * 5),
          Row(
            children: [
              RuleCashbutton(
                isEnabled: isButtonValid,
                onPressed: () {
                  ruleCashProvider.pressKirim();
                  _moneyController.clear();
                  _noteController.clear();
                },
                title: loc.kirim,
              ),
              SizedBox(width: SizeConfig.h),
              RuleCashbutton(
                isEnabled: isButtonValid,
                onPressed: () {
                  ruleCashProvider.pressChiqim();
                  _moneyController.clear();
                  _noteController.clear();
                },
                title: loc.chiqim,
              )
            ],
          ),
          SizedBox(height: SizeConfig.v * 2),
          Row(
            children: [
              Expanded(
                child: Container(),
              ),
              SizedBox(width: SizeConfig.h),
              RuleCashbutton(
                isEnabled: isButtonValid,
                onPressed: () {
                  ruleCashProvider.pressInkassatsiya();
                  _moneyController.clear();
                  _noteController.clear();
                },
                title: loc.inkassatsiya,
              ),
            ],
          ),
        ],
      ),
    );
  }

  UnderlineInputBorder _border(bool focused) {
    return UnderlineInputBorder(
      borderSide: BorderSide(
        color: focused
            ? Theme.of(context).canvasColor
            : Theme.of(context).dividerColor,
      ),
    );
  }

  @override
  void dispose() {
    _moneyController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
