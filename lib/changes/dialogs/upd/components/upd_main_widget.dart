import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/dialogs/upd/bloc/upd_bloc.dart';
import 'package:invan2/changes/dialogs/upd/components/upd_done_widget.dart';
import 'package:invan2/changes/dialogs/upd/components/upd_selected_widget.dart';
import 'package:invan2/changes/dialogs/upd/components/upd_show_error_widget.dart';
import 'package:invan2/changes/dialogs/upd/components/upd_loading_widget.dart';
import 'package:invan2/changes/dialogs/upd/components/upd_done_some_failed.dart';
import 'package:provider/provider.dart';

import '../../../providers/ordering_provider_4.dart';

class UpdDialogMainWidget extends StatefulWidget {
  const UpdDialogMainWidget({super.key});

  @override
  State<UpdDialogMainWidget> createState() => _UpdDialogMainWidgetState();
}

class _UpdDialogMainWidgetState extends State<UpdDialogMainWidget> {
  @override
  void initState() {
    context.read<UpdBloc>().add(UpdInitialEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UpdBloc, UpdState>(
      listener: (context, state) {
        if (state is UpdAllDoneState) {
          Provider.of<OrderingProvider4>(context, listen: false).pressAllPath();
        }
        if (state is UpdAllDoneSomeFailedState) {
          Provider.of<OrderingProvider4>(context, listen: false).pressAllPath();
        }
      },
      builder: (context, state) {
        if (state is UpdAllDoneState) {
          return const UpdAllDoneWidget();
        }

        if (state is UpdShowErrorState) {
          return UpdFailedWidget(
            repo: state.repo,
          );
        }
        if (state is UpdLoadingState) {
          return UpdLoadingWidget(repos: state.repos);
        }

        if (state is UpdAllDoneSomeFailedState) {
          return UpdDoneSomeFailedWidget(repos: state.repos);
        }
        if (state is UpdInitialState2) {
          return UpdSelectedWidget(repos: state.repos);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
