import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/lock/access_level/bloc/access/access_bloc.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/widgets/widgets.dart';
import 'smena_ochish_dialog.dart';

class ShiftClosedContent extends StatelessWidget {
  const ShiftClosedContent({
    Key? key,
    required this.scaffoldKey,
  }) : super(key: key);

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    AccessBloc accessBloc = BlocProvider.of(context, listen: false);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: SizeConfig.v * 7,
            color: Colors.grey.shade700,
          ),
          SizedBox(height: SizeConfig.v * 2),
          Text(
            '${loc.smenaYopilgan}\n${loc.ishniBoshlashUchunSmenaniOching}',
            textAlign: TextAlign.center,
            style: MyThemes.txtStyle(
              color: Colors.grey.shade700,
            ),
          ),
          accessBloc.level == 0
              ? const SizedBox(
                  width: 0,
                  height: 0,
                )
              : Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.h * 10,
                    vertical: SizeConfig.v * 2,
                  ),
                  child: DefaultButton(
                    text: loc.smenaniOchish.toUpperCase(),
                    isButtonEnabled: true,
                    onPress: () {
                      showDialog(
                        context: scaffoldKey.currentContext!,
                        builder: (context) => const AlertDialog(
                          content: SmenaOchishDialog(),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
