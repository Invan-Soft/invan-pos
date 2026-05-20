import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/dialogs/virtual_keyboard/content_of_virtual_keyboard.dart';
import 'package:invan2/utils/utils.dart';
import '../../../features/home/features/home_products/shift_opened/product_search/dialog/bloc/serch_dialog_bloc.dart';
import '../../providers/product_search_provider.dart';

class AppVirtualKeyboardDialog extends StatefulWidget {
  const AppVirtualKeyboardDialog({
    Key? key,
    required this.searchTypeEnum,
  }) : super(key: key);

  final SearchTypeEnum searchTypeEnum;

  @override
  State<AppVirtualKeyboardDialog> createState() =>
      _AppVirtualKeyboardDialogState();
}

class _AppVirtualKeyboardDialogState extends State<AppVirtualKeyboardDialog> {
  late SDbloc sdBloc;
  @override
  void initState() {
    sdBloc = SDbloc();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          width: SizeConfig.h * 90 * 1.5,
          height: SizeConfig.v * 50,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 13,
                  spreadRadius: 1,
                  offset: Offset(1, 1),
                ),
              ],
              color: Theme.of(context).colorScheme.background),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Material(
              color: Theme.of(context).dialogBackgroundColor,
              child: BlocBuilder<SDbloc, SDstate>(
                builder: (context, state) {
                  return const  ContentOfVirtualKeyboardDialog();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
