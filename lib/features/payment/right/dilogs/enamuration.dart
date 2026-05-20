import 'dart:async';

import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:invan2/widgets/default_button.dart';

class Enamuration extends StatefulWidget {
  const Enamuration({
    Key? key,
  }) : super(key: key);

  @override
  State<Enamuration> createState() => _EnamurationState();
}

class _EnamurationState extends State<Enamuration> {
  TextEditingController comppanyController = TextEditingController();
  int a = 1;
  StreamController<int> counterContrller = StreamController();
  var focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.canRequestFocus;
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = Pref.getBool(PrefKeys.isDarkMode, true)
        ? Theme.of(context).dialogBackgroundColor
        : MyThemes.lightGreyColorr;
    AppLocalizations loc = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.all(SizeConfig.h * 3),
        width: SizeConfig.h * 53,
        height: SizeConfig.v * 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: bgColor,
        ),
        child: Material(
          color: bgColor,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(onPressed: () {
                        Navigator.pop(context);
                      }, icon: const Icon(Icons.arrow_back)),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Перечисление",
                          style: MyThemes.txtStyle(
                            color: MyThemes.textWhiteColor,
                            fontSize: 3.5,
                          ),
                        ),
                      ),
                    ),
               
                  ],
                ),
                const SizedBox(
                  height: 20.0,
                ),
                TextField(
                  enableInteractiveSelection: true,
                  autocorrect: false,
                  focusNode: focusNode,
                  controller: comppanyController,
                  enableSuggestions: false,
                  style: const TextStyle(fontSize: 20, color: Colors.blue),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.fromLTRB(20, 24, 12, 16),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0))),
                    labelText: 'Название компании',
                    hintText: 'Введите название вашей компании',
                    hintStyle: TextStyle(fontSize: 20, color: Colors.blue),
                    labelStyle: TextStyle(fontSize: 20, color: Colors.blue),
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        loc.soni,
                        style: MyThemes.txtStyle(
                          color: Theme.of(context).canvasColor,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.h * .1,
                            vertical: SizeConfig.h * .2),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).canvasColor,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _prefixIcon(),
                            TextButton(
                              focusNode: FocusNode(skipTraversal: true),
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).dialogBackgroundColor,
                                padding: const EdgeInsets.all(0.0),
                              ),
                              child: StreamBuilder<int>(
                                  stream: counterContrller.stream,
                                  initialData: 1,
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.requireData.toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: SizeConfig.v * 2.3,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FontStyle.normal,
                                        color: Theme.of(context).canvasColor,
                                      ),
                                    );
                                  }),
                            ),
                            _suffixIcon()
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20.0,
                ),
                DefaultButton(
                  text: "Ok",
                  isButtonEnabled: true,
                  onPress: () async {
                    Pref.setInt(PrefKeys.companyResipt, a);
                    Pref.setString(
                        PrefKeys.companyNameDialog, comppanyController.text);
                    AppNavigation.pop();
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  _prefixIcon() {
    return ElevatedButton(
      focusNode: FocusNode(skipTraversal: true),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(SizeConfig.v * 3.64, SizeConfig.v * 3.64),
        fixedSize: Size(SizeConfig.v * 3.64, SizeConfig.v * 3.64),
        elevation: 0,
        backgroundColor: Theme.of(context).dividerColor.withOpacity(.4),
        padding: const EdgeInsets.all(0.0),
      ),
      onPressed: () {
        counterContrller.add(a > 1 ? a = a - 1 : 1);
      },
      child: Icon(
        Icons.remove,
        color: Theme.of(context).canvasColor,
      ),
    );
  }

  ElevatedButton _suffixIcon() {
    return ElevatedButton(
      focusNode: FocusNode(skipTraversal: true),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(SizeConfig.v * 3.64, SizeConfig.v * 3.64),
        fixedSize: Size(SizeConfig.v * 3.64, SizeConfig.v * 3.64),
        elevation: 0,
        backgroundColor: Theme.of(context).dividerColor.withOpacity(.4),
        padding: const EdgeInsets.all(0.0),
      ),
      onPressed: () {
        counterContrller.add(a < 4 ? a = a + 1 : 4);
      },
      child: Icon(
        Icons.add,
        color: Theme.of(context).canvasColor,
      ),
    );
  }
}
