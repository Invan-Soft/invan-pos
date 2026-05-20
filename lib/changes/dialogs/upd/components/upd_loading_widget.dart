import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/dialogs/upd/bloc/upd_bloc.dart';
import 'package:invan2/changes/dialogs/upd/components/upd_text.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/helpers/upper_case_string_extention.dart';

class UpdLoadingWidget extends StatelessWidget {
  final List<UpdFailedRepo> repos;

  const UpdLoadingWidget({
    required this.repos,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
              children: List.generate(repos.length, (index) {
                return ListTile(
                  leading: repos[index].repoStatus == RepoStatus.done
                      ? const Icon(Icons.check, color: Colors.green)
                      : (repos[index].repoStatus == RepoStatus.inProgress
                      ? const CupertinoActivityIndicator()
                      : const Icon(Icons.error, color: Colors.red)),
                  title: UpdText(
                    repos[index].apdStatus.name.capitalize(),
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
      ],
    );

    //
    // return CupertinoAlertDialog(
    //   title: Material(
    //     color: Colors.transparent,
    //     child: ConstrainedBox(
    //       constraints: BoxConstraints(
    //         maxHeight: MediaQuery
    //             .of(context)
    //             .size
    //             .height,
    //       ),
    //       child: ListView.builder(
    //         shrinkWrap: true,
    //         itemCount: repos.length,
    //         itemBuilder: (context, __) {
    //           return ListTile(
    //             leading: repos[__].repoStatus == RepoStatus.done
    //                 ? const Icon(Icons.check, color: Colors.green)
    //                 : (repos[__].repoStatus == RepoStatus.inProgress
    //                 ? const CupertinoActivityIndicator()
    //                 : const Icon(Icons.error, color: Colors.red)),
    //             title: UpdText(
    //               repos[__].apdStatus.name.capitalize(),
    //               textAlign: TextAlign.start,
    //               fw: FontWeight.bold,
    //             ),
    //           );
    //         },
    //       ),
    //     ),
    //   ),
    //   actions: [
    //     CupertinoButton(
    //       child: UpdText(loc.yopish),
    //       onPressed: () => AppNavigation.pop(),
    //     )
    //   ],
    // );
  }
}
