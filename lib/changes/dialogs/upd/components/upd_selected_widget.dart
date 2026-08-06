import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/dialogs/upd/bloc/upd_bloc.dart';
import 'package:invan2/changes/dialogs/upd/components/upd_text.dart';
import 'package:invan2/features/features.dart';

import '../../../../features/authentication/bloc/bloc_activate_pos/apd_bloc_bloc.dart';

class UpdSelectedWidget extends StatefulWidget {
  final List<UpdFailedRepo> repos;

  const UpdSelectedWidget({
    required this.repos,
    super.key,
  });

  @override
  _UpdSelectedWidgetState createState() => _UpdSelectedWidgetState();
}

class _UpdSelectedWidgetState extends State<UpdSelectedWidget> {
  List<APDstatus> status = const [
    APDstatus.discounts,
    APDstatus.items,
    APDstatus.category,
    APDstatus.organization,
    APDstatus.employee,
    APDstatus.service,
  ];
  late Map<int, bool> selectedItems;

  @override
  void initState() {
    super.initState();
    selectedItems = {for (int i = 0; i < widget.repos.length; i++) i: true};
  }

  String _localizedName(APDstatus status, AppLocalizations loc) {
    switch (status) {
      case APDstatus.discounts:
        return loc.upd_discounts;
      case APDstatus.items:
        return loc.upd_items;
      case APDstatus.category:
        return loc.upd_category;
      case APDstatus.organization:
        return loc.upd_organization;
      case APDstatus.employee:
        return loc.upd_employee;
      case APDstatus.service:
        return loc.upd_service;
      default:
        return status.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    UpdBloc updBloc = BlocProvider.of(context);
    final AppLocalizations loc = AppLocalizations.of(context)!;

    return CupertinoAlertDialog(
      title: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.repos.length, (index) {
                return CheckboxListTile(
                  checkColor: Colors.white,
                  activeColor: Colors.green,
                  value: selectedItems[index],
                  onChanged: (bool? value) {
                    setState(() {
                      selectedItems[index] = value ?? false;
                    });
                  },
                  title: UpdText(
                    _localizedName(widget.repos[index].apdStatus, loc),
                    textAlign: TextAlign.start,
                    fw: FontWeight.bold,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      actions: [
        CupertinoButton(
          child: UpdText(loc.yopish),
          onPressed: () => AppNavigation.pop(),
        ),
        CupertinoButton(
          child: UpdText(loc.yangilash),
          onPressed: () {
            final selectedRepos = widget.repos
                .asMap()
                .entries
                .where((entry) => selectedItems[entry.key] == true)
                .map((entry) => entry.value)
                .toList();

            final selectedStatus = status
                .asMap()
                .entries
                .where((entry) => selectedItems[entry.key] == true)
                .map((entry) => entry.value)
                .toList();

            if (selectedRepos.isNotEmpty) {
              updBloc.add(UpdStartEvent(false, selectedStatus));
            }
          },
        ),
      ],
    );
  }
}
