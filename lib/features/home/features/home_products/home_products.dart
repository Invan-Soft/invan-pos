import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:provider/provider.dart';
import 'shift_closed/view/shift_closed_content.dart';
import 'shift_opened/shift_opened_content.dart';

class HomeProducts extends StatelessWidget {
  const HomeProducts({
    Key? key,
    required this.scaffoldKey,
  }) : super(key: key);

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final OpenShiftProvider openShiftProvider =
        Provider.of<OpenShiftProvider>(context);
    final isShiftOpened = openShiftProvider.getIsShiftOpened;

    return Container(
      color: Theme.of(context).colorScheme.background,
      child: isShiftOpened
          ? const ShiftOpenedContent()
          : ShiftClosedContent(scaffoldKey: scaffoldKey),
    );
  }
}
