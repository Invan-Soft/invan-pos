import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/widgets.dart';
import 'build_smena_text.dart';

class ReportAppBarr extends StatefulWidget {
  const ReportAppBarr({
    super.key,
    required this.scaffoldKey,
    required this.pressLockButton,
    this.pressPrinterButton,
    this.isPrinter,
  });

  final VoidCallback pressLockButton;
  final VoidCallback? pressPrinterButton;
  final bool? isPrinter;

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<ReportAppBarr> createState() => _ReportAppBarrState();
}

class _ReportAppBarrState extends State<ReportAppBarr> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: SizeConfig.v * 9.3,
      decoration: BoxDecoration(
        boxShadow: const [BoxShadow(color: Colors.black)],
        color: Theme.of(context).colorScheme.background,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const BackToButton(),
          const Spacer(),
          widget.isPrinter != null && widget.isPrinter!
              ? AppBarPrinterButton(onPress: widget.pressPrinterButton!)
              : SizedBox.shrink(),
          AppBarLockButton(
            onPress: widget.pressLockButton,
            color: Theme.of(context).colorScheme.background,
          ),
          AppBarDrawerButton(
            onPress: () => widget.scaffoldKey.currentState!.openEndDrawer(),
            color: Theme.of(context).colorScheme.background,
          ),
        ],
      ),
    );
  }
}
