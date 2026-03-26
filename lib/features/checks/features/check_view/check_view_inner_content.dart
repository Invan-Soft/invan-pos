import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/checks/features/checks_list/bloc/check_f_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import '../../../../utils/l10n/app_localizations.dart';
import 'check_view_top.dart';
import 'check_view_sold_items.dart';
import 'check_view_bottom.dart';

class CheckViewInnerContent extends StatelessWidget {
  const CheckViewInnerContent({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return BlocBuilder<CheckFBloc, CheckFState>(
      builder: (context, state) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
           state.selectedCheck != null
                ? Align(
                    alignment: Alignment.center,
                    child: Text(
                      MoneyFormatter.formatVat
                          .format( state.selectedCheck!.totalPrice),
                      style: MyThemes.txtStyle(
                        fontSize: 3,
                        color: Theme.of(context).canvasColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const SizedBox(width: 0, height: 0),
            state.selectedCheck != null
                ? Align(
                    alignment: Alignment.center,
                    child: Text(
                      loc.tolanganJami,
                      style: MyThemes.txtStyle(
                        fontSize: 2.2,
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  )
                : const SizedBox(width: 0, height: 0),
            const CheckViewTop(),
            state.selectedCheck != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Divider(color: Theme.of(context).dividerColor),
                      const CheckViewSoldItems(),
                      Divider(color: Theme.of(context).dividerColor),
                      const CheckViewBottom(),
                    ],
                  )
                : const SizedBox(width: 0, height: 0),
          ],
        );
      },
    );
  }
}
