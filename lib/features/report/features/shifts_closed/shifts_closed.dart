import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/features/report/features/shifts_closed/keyboard.dart';
import 'package:invan2/changes/providers/shift_closed_provider.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';
import 'package:provider/provider.dart';

class ShiftsClosed extends StatefulWidget {
  const ShiftsClosed({super.key});
  static CupertinoPageRoute route() => CupertinoPageRoute(
        builder: (_) {
          return const ShiftsClosed();
        },
      );

  @override
  ShiftsClosedState createState() => ShiftsClosedState();
}

class ShiftsClosedState extends State<ShiftsClosed> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        height: SizeConfig.v * 73,
        width: SizeConfig.h * 27.14,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SizeConfig.v * 1.56),
          boxShadow: const [
            BoxShadow(
                color: Colors.black,
                blurRadius: 1,
                offset: Offset(1, 1),
                spreadRadius: 1)
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.v * 1.56,
                  vertical: SizeConfig.v,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.h * 1.17),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _topText(loc),
                          SizedBox(height: SizeConfig.v * .52),
                          _display(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                loc.boshlangichMiqdor,
                                textAlign: TextAlign.end,
                                style: MyThemes.txtStyle(
                                    color: const Color(0xffA8A8A8),
                                    fontSize: 1.82,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const KeyboardOfShiftClosed(),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.h * 1.17,
                      ),
                      child: MaterialButton(
                        focusNode: FocusNode(skipTraversal: true),
                        onPressed: () {

                          Provider.of<ShiftClosedProvider>(
                            context,
                            listen: false,
                          ).onOpenShiftButtonPressed(context);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            SizeConfig.v * 1.56,
                          ),
                        ),
                        color: Theme.of(context).primaryColor,
                        height: SizeConfig.v * 7.55,
                        minWidth: double.infinity,
                        child: Text(
                          loc.smenaniOchish.toUpperCase(),
                          style: MyThemes.txtStyle(
                            fontSize: 2.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: SizeConfig.v * 1.34)
                  ],
                ),
              ),
            ),
            context.watch<ShiftClosedProvider>().getIsWaiting
                ? Positioned.fill(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Theme.of(context).primaryColor.withOpacity(.4),
                      child: const Center(
                        child: SpinKitCircle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  )
                : const Positioned(
                    top: 0,
                    left: 0,
                    child: SizedBox(
                      height: 0,
                      width: 0,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  _display() {
    return TextButton(
      focusNode: FocusNode(skipTraversal: true),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.all(0.0),
      ),
      onPressed: () {
        context.read<ShiftClosedProvider>().focusNode.requestFocus();
      },
      child: Container(
        alignment: Alignment.centerLeft,
        height: SizeConfig.v * 7,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.h),
        decoration: BoxDecoration(
          color: MyThemes.lightGreyColorr,
          borderRadius: BorderRadius.circular(
            SizeConfig.v,
          ),
        ),
        child: Text(
          context.read<ShiftClosedProvider>().startingCash.text,
          style: MyThemes.txtStyle(fontSize: 2.8),
        ),
      ),
    );
  }

  Text _topText(AppLocalizations loc) {
    return Text(
      loc.smenaniOchish,
      style: MyThemes.txtStyle(fontSize: 1.82, fontWeight: FontWeight.w500),
    );
  }
}
