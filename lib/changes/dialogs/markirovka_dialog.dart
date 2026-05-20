import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/my_time_string_helper.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';

class MarkingDialog extends StatefulWidget {
  final String name;
  final String price;                    // ← bu narx
  final VoidCallback onCancelButtonPressed;
  final Function(String) onAddButtonPressed;
  final Function(String) onSubmitted;

  const MarkingDialog({
    required this.name,
    required this.price,
    required this.onCancelButtonPressed,
    required this.onAddButtonPressed,
    required this.onSubmitted,
    super.key,
  });

  @override
  MarkingDialogState createState() => MarkingDialogState();
}

class MarkingDialogState extends State<MarkingDialog> {
  final TextEditingController controller = TextEditingController();
  String? _errorMessage;

  void _handleSubmit(String value) {
    if (value.length <= 15) {
      setState(() => _errorMessage = 'Markirovka kodi uzunroq bo\'lishi kerak!');
      return;
    }
    setState(() => _errorMessage = null);
    widget.onSubmitted(value);
  }

  void _handleAdd() {
    final value = controller.text.trim();
    if (value.length <= 15) {
      setState(() => _errorMessage = 'Markirovka kodi uzunroq bo\'lishi kerak!');
      return;
    }
    setState(() => _errorMessage = null);
    widget.onAddButtonPressed(value);
  }

  void showInvalidMarkError() {
    if (!mounted) return;
    setState(() {
      controller.clear();
      _errorMessage = 'Noto\'g\'ri markirovka! Qaytadan skaner qiling.';
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        height: SizeConfig.v * 62,
        width: SizeConfig.h * 42,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(SizeConfig.v * 2.5),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: SizeConfig.h * 1.6,
                right: SizeConfig.h * 1.6,
                top: SizeConfig.h * 1.6,
                bottom: SizeConfig.v,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.kodni_scanerlash,
                    style: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
                  ),
                  TextButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: widget.onCancelButtonPressed,
                    child: Image.asset(
                      "assets/images/cancel.png",
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Theme.of(context).dividerColor),

            Expanded(
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.h * 1.6),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mahsulot nomi
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${loc.tovar}: ${widget.name}",
                        textAlign: TextAlign.start,
                        style: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
                      ),
                    ),

                    // Narx va sana
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/qr.png",
                          color: Theme.of(context).canvasColor,
                        ),
                        SizedBox(width: SizeConfig.h * 2.8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ← BU YERGA NARX QO‘SHILDI
                            Text(
                              "${loc.narxi} ${widget.price}",
                              style: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
                            ),
                            Text(
                              "${loc.sana} ${MyTimeStringHelper.getDayMonthYearWithDot()}",
                              style: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Container(
                      alignment: Alignment.center,
                      height: SizeConfig.v * 5.1,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(SizeConfig.v * .6),
                        color: const Color(0xff30557F).withOpacity(.3),
                      ),
                      child: Text(
                        loc.scanerni_codga_qarating_va_scanerlang,
                        style: MyThemes.txtStyleWhite(),
                      ),
                    ),

                    // TextField va tugma qismi o‘zgarmadi
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          autofocus: true,
                          onSubmitted: _handleSubmit,
                          controller: controller,
                          style: MyThemes.txtStyleWhite(),
                          onChanged: (_) {
                            if (_errorMessage != null) {
                              setState(() => _errorMessage = null);
                            }
                          },
                          decoration: InputDecoration(
                            constraints: BoxConstraints(
                              maxHeight: SizeConfig.v * 5.16,
                              maxWidth: double.infinity,
                            ),
                            suffixIcon: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: controller,
                              builder: (_, value, __) {
                                if (value.text.isEmpty) return const SizedBox.shrink();
                                return IconButton(
                                  focusNode: FocusNode(skipTraversal: true),
                                  icon: const Icon(Icons.close, size: 18),
                                  color: Colors.white70,
                                  onPressed: () {
                                    controller.clear();
                                    setState(() => _errorMessage = null);
                                  },
                                );
                              },
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _errorMessage != null
                                    ? Colors.redAccent
                                    : Theme.of(context).canvasColor,
                              ),
                              borderRadius: BorderRadius.circular(SizeConfig.v * .6),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _errorMessage != null
                                    ? Colors.redAccent
                                    : Theme.of(context).canvasColor,
                              ),
                              borderRadius: BorderRadius.circular(SizeConfig.v * .6),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _errorMessage != null
                                    ? Colors.redAccent
                                    : Theme.of(context).canvasColor.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(SizeConfig.v * .6),
                            ),
                          ),
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: EdgeInsets.only(top: SizeConfig.v * 0.6),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                                SizedBox(width: SizeConfig.h * 0.5),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: MyThemes.txtStyle(color: Colors.redAccent).copyWith(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    ElevatedButton(
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: _handleAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        fixedSize: Size(double.infinity, SizeConfig.v * 5.16),
                      ),
                      child: Text(loc.qoshish, style: MyThemes.txtStyleWhite()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}