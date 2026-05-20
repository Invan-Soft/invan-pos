import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invan2/features/report/features/shifts_opened/view/buttons.dart';
import 'package:invan2/features/report/features/shifts_opened/view/hive_content.dart';
import 'package:invan2/utils/utils.dart';

class ShiftsOpenedPage extends StatefulWidget {
  final bool isZet;

  const ShiftsOpenedPage({required this.isZet, super.key});

  static CupertinoPageRoute route({required bool isZet}) => CupertinoPageRoute(
        builder: (_) {
          return ShiftsOpenedPage(
            isZet: isZet,
          );
        },
      );

  @override
  State<ShiftsOpenedPage> createState() => _ShiftsOpenedPageState();
}

class _ShiftsOpenedPageState extends State<ShiftsOpenedPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.v * 5,
        horizontal: SizeConfig.h * 18,
      ),
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Theme.of(context).dividerColor)),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Buttons(isZet: widget.isZet),
              ShiftContennt(),
            ],
          ),
        ),
      ),
    );
  }
}
