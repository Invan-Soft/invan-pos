import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invan2/utils/utils.dart';

class SettingsInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final bool onlyDigits;

  const SettingsInputField({
    Key? key,
    required this.controller,
    required this.label,
    required this.enabled,
    required this.onlyDigits,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: SizeConfig.v * 4,
            color: Theme.of(context).dividerColor,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: SizeConfig.v),
        TextFormField(
          enabled: enabled,
          validator: (v) {
            if (v!.isEmpty) {
              return "$label kiritilmagan!!!";
            }
            return null;
          },
          style: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
          controller: controller,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(SizeConfig.h),
            fillColor: enabled
                ? Theme.of(context).colorScheme.background
                : Theme.of(context).disabledColor,
            filled: true,
            hintStyle: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
            hintText: "$label ...",
            focusedBorder: _border(),
            enabledBorder: _border(),
            errorBorder: _border(color: Colors.red),
            border: _border(),
          ),
          inputFormatters:
              onlyDigits ? [FilteringTextInputFormatter.digitsOnly] : [],
        ),
        SizedBox(height: SizeConfig.v * 3),
      ],
    );
  }

  OutlineInputBorder _border({Color? color}) {
    return OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(
        SizeConfig.v,
      ),
    );
  }
}
