import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ignore: must_be_immutable
class AppTextFormField extends StatelessWidget {
  final String title;
  TextEditingController? controller;
  String? hint;
  bool? enabled;
  TextInputAction? action;
  bool? autofocus;
  List<TextInputFormatter>? formatters;
  FormFieldValidator<String>? validator;
  AppTextFormField({
    Key? key,
    required this.title,
    this.controller,
    this.hint,
    this.autofocus,
    this.action,
    this.formatters,
    this.validator,
    this.enabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TITLE
        Text(
          title,
          style: TextStyle(color: Theme.of(context).canvasColor),
        ),
        const SizedBox(height: 10),

        // TEXT FORM FIELD
        TextFormField(
          autofocus: autofocus ?? false,
          enabled: enabled,
          controller: controller,
          validator: validator,
          cursorColor: Colors.white,
          textInputAction: action ?? TextInputAction.next,
          style: TextStyle(color: Theme.of(context).canvasColor),
          inputFormatters: formatters,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            filled: true,
            hintText: hint,
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            fillColor: Theme.of(context).dialogBackgroundColor,
            border: _border(),
            hintStyle: TextStyle(
              color: Theme.of(context).canvasColor.withOpacity(0.5),
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  OutlineInputBorder _border() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );
  }
}
