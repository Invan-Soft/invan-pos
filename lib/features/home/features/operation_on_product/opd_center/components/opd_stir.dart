import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invan2/changes/providers/operation_on_product_provider.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:provider/provider.dart';

import '../../../../../../utils/constants/pref_keys.dart';
import '../../../../../hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

// ignore: must_be_immutable
class OPDstir extends StatelessWidget {
  final Function(bool) onChanged;
  final Function(bool) onChanged2;

  final ReceiptModelSoldItem4 item;
  bool value;
  OPDstir(
      {required this.onChanged,
      required this.onChanged2,
      required this.value,
      Key? key,
      required this.item})
      : super(key: key);
  TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    if (item.tin != null && item.tin != '') {
      value = true;
    }
    controller.text = item.tin ?? "";
    if (focusNode.canRequestFocus) {
      focusNode.requestFocus();
    }
    return SizedBox(
      height: SizeConfig.v * 4.81,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "ИНН комитента",
            style: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
          ),
          const Spacer(flex: 3),
          Switch(
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveThumbColor: Theme.of(context).primaryColor,
            onChanged: onChanged,
            value: value,
            // value: item.tin == null ? value : true,
          ),
          const Spacer(flex: 3),
          value
              ? Expanded(
                  flex: 24,
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
                    child: EditableText(
                      onChanged: (v) {
                        Provider.of<OperationOnProductProvider>(context,
                                listen: false)
                            .onINNcomitenta(value, v);
                        if (v.isEmpty) {
                          value == false;
                          onChanged2;
                        }
                        Pref.setString(PrefKeys.innLength, controller.text);
                      },
                      controller: controller,
                      focusNode: focusNode,
                      style: MyThemes.txtStyle(color: MyThemes.textWhiteColor),
                      cursorColor: Colors.cyan,
                      backgroundCursorColor: Colors.amber,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                )
              : const Spacer(
                  flex: 25,
                ),
        ],
      ),
    );
  }
}
