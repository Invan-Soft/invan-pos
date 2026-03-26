import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/dialogs/upd/bloc/upd_bloc.dart';
import 'package:invan2/changes/dialogs/upd/components/upd_text.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/helpers/upper_case_string_extention.dart';

class UpdDoneSomeFailedWidget extends StatelessWidget {
  final List<UpdFailedRepo> repos;

  const UpdDoneSomeFailedWidget({
    required this.repos,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    List<UpdFailedRepo> v =
        repos.where((e) => e.repoStatus == RepoStatus.failed).toList();
    UpdBloc updBloc = BlocProvider.of(context);
    final AppLocalizations loc = AppLocalizations.of(context)!;
    return CupertinoAlertDialog(
      title: UpdText(
        "Failed steps",
      ),
      content: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: SizedBox(
              height: SizeConfig.h * 15,
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: v.length,
                  itemBuilder: (context, __) {
                    return ListTile(
                      onTap: () => updBloc.add(UpdShowErrorEvent(v[__])),
                      leading: v[__].repoStatus == RepoStatus.done
                          ? const Icon(
                              Icons.check,
                              color: Colors.green,
                            )
                          : (v[__].repoStatus == RepoStatus.inProgress
                              ? const CupertinoActivityIndicator()
                              : const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                )),
                      title: UpdText(
                        v[__].apdStatus.name.capitalize(),
                        textAlign: TextAlign.start,
                        fw: FontWeight.bold,
                      ),
                    );
                  }),
            ),
          ),
        ],
      ),
      actions: [
        CupertinoButton(
          child: UpdText(loc.chiqish),
          onPressed: () => AppNavigation.pop(),
        ),
        CupertinoButton(
          child: UpdText(
            loc.qayta_urinish,
          ),
          onPressed: () => updBloc.add(UpdStartEvent(true, statuss)),
        )
      ],
    );
  }
}
