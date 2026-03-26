import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/dialogs/virtual_keyboard/componets/keys_row.dart';
import 'package:invan2/changes/dialogs/virtual_keyboard/componets/multi_char_key.dart';
import 'package:invan2/changes/dialogs/virtual_keyboard/componets/single_char_key.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/product_search/dialog/bloc/serch_dialog_bloc.dart';

class ContentOfVirtualKeyboardDialog extends StatefulWidget {
  const ContentOfVirtualKeyboardDialog({
    Key? key,
  }) : super(key: key);

  @override
  State<ContentOfVirtualKeyboardDialog> createState() =>
      _ContentOfVirtualKeyboardDialogState();
}

class _ContentOfVirtualKeyboardDialogState
    extends State<ContentOfVirtualKeyboardDialog> {
  late SDbloc sdBloc;
  @override
  void initState() {
    sdBloc = BlocProvider.of(context);
    super.initState();
  }

  onPressed(v) {
    sdBloc.add(SDtypeFromVirtualKeyboardEvent(v));
  }

  onArrowPressed(ArrowTo arrowTo) => sdBloc.add(SDarrowEvent(arrowTo));

  onMultiCharKeyPressed(v) =>
      sdBloc.add(SDtypeFromVirtualKeyboardEvent(sdBloc.shift ? v[0] : v[1]));

  onPressedEmpty(String v) {
    switch (v) {
      case "delete":
        sdBloc.add(SDbackSpacePressedEvent());
        break;
      case "caps lock":
        sdBloc.add(SDcapsLockEvent());
        break;
      case "shift":
        sdBloc.add(SDshiftEvent());
        break;
      case "return":
        AppNavigation.pop();
        sdBloc.add(SDreturnEvent());
        break;

      default:
    }
  }

  Color bgColor = const Color(0xFFABA7AE);
  @override
  Widget build(BuildContext context) {
    const height = 48.0;
    const separator = 5.0;

    return BlocBuilder<SDbloc, SDstate>(
      builder: (context, state) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 778,
          height: 310,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.3)),
              BoxShadow(
                color: bgColor,
                blurRadius: 3,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 3),
              Expanded(
                child: KeysRow(
                  height: height,
                  separatorWidth: separator,
                  keys: [
                    Expanded(
                      child: MultiCharKey(
                        upperChar: '',
                        lowerChar: '1',
                        onPressed: onMultiCharKeyPressed,
                      ),
                    ),
                    Expanded(
                      child: MultiCharKey(
                        upperChar: '',
                        lowerChar: '2',
                        onPressed: onMultiCharKeyPressed,
                      ),
                    ),
                    Expanded(
                      child: MultiCharKey(
                        upperChar: '',
                        lowerChar: '3',
                        onPressed: onMultiCharKeyPressed,
                      ),
                    ),
                    Expanded(
                      child: MultiCharKey(
                        upperChar: '',
                        lowerChar: '4',
                        onPressed: onMultiCharKeyPressed,
                      ),
                    ),
                    Expanded(
                      child: MultiCharKey(
                        upperChar: '',
                        lowerChar: '5',
                        onPressed: onMultiCharKeyPressed,
                      ),
                    ),
                    Expanded(
                      child: MultiCharKey(
                        upperChar: '',
                        lowerChar: '6',
                        onPressed: onMultiCharKeyPressed,
                      ),
                    ),
                    Expanded(
                      child: MultiCharKey(
                        upperChar: '',
                        lowerChar: '7',
                        onPressed: onMultiCharKeyPressed,
                      ),
                    ),
                    Expanded(
                      child: MultiCharKey(
                        upperChar: '',
                        lowerChar: '8',
                        onPressed: onMultiCharKeyPressed,
                      ),
                    ),
                    Expanded(
                      child: MultiCharKey(
                        upperChar: '',
                        lowerChar: '9',
                        onPressed: onMultiCharKeyPressed,
                      ),
                    ),
                    Expanded(
                      child: MultiCharKey(
                        upperChar: '',
                        lowerChar: '0',
                        onPressed: onMultiCharKeyPressed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                child: KeysRow(
                  height: height,
                  separatorWidth: separator,
                  keys: [
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'Q',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'W',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'E',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'R',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'T',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'Y',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'U',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'I',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        onPressed: onPressed,
                        alignment: Alignment.center,
                        char: 'O',
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'P',
                        onPressed: onPressed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                child: KeysRow(
                  height: height,
                  separatorWidth: separator,
                  keys: [
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'A',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'S',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'D',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'F',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'G',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'H',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'J',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'K',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'L',
                        onPressed: onPressed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                child: KeysRow(
                  height: height,
                  separatorWidth: separator,
                  keys: [
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'Z',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'X',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'C',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'V',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'B',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'N',
                        onPressed: onPressed,
                      ),
                    ),
                    Expanded(
                      child: SingleCharKey(
                        alignment: Alignment.center,
                        char: 'M',
                        onPressed: onPressed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                child: KeysRow(
                  height: height,
                  separatorWidth: separator,
                  keys: [
                    Expanded(
                      flex: 1,
                      child: SingleCharKey(
                        alignment: Alignment.bottomLeft,
                        width: 75,
                        char: 'delete',
                        onPressed: onPressedEmpty,
                      ),
                    ),
                    const Spacer(
                      flex: 1,
                    ),
                    Expanded(
                      flex: 2,
                      child: SingleCharKey(
                        width: 261,
                        alignment: Alignment.center,
                        char: ' ',
                        onPressed: onPressed,
                      ),
                    ),
                    const Spacer(
                      flex: 1,
                    ),
                    Expanded(
                      flex: 1,
                      child: SingleCharKey(
                        alignment: Alignment.bottomRight,
                        width: 90,
                        char: 'return',
                        onPressed: onPressedEmpty,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum ArrowTo { up, down, right, left }
