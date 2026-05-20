import 'package:flutter/material.dart';
import 'package:invan2/changes/dialogs/client_search/components/row_text.dart';
import 'package:invan2/changes/models/client_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import '../../../../utils/utils.dart';
import '../../../models/six_client_model.dart';

class FoundClientWidget extends StatelessWidget {
  final ClientModel client;
  final double hPadding;
  final SixClientModel4 currentClient;
  bool? isType;

  FoundClientWidget(
    this.client, {
    super.key,
    required this.hPadding,
    required this.currentClient,
    this.isType,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * hPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RowTextClintSearch(loc.ism, client.firstName ?? ""),
            RowTextClintSearch(loc.familiya, client.lastName ?? ""),
            RowTextClintSearch(
                loc.balans,
                (client.pointBalance == null
                    ? "-"
                    : client.pointBalance!.toString())),
            isType != null && isType!
                ? RowTextClintSearch("Type", client.groupName ?? "")
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
