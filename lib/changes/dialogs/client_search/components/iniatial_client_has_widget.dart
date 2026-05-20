import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/bloc/client_search/client_search_bloc.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/widgets/default_button.dart';

class InitialHasClientButtons extends StatelessWidget {
  final VoidCallback onDelPressed;

  const InitialHasClientButtons(
    this.onDelPressed, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ClientBloc clientBloc = BlocProvider.of(context);
    return Row(
      children: [
        Expanded(
          child: DefaultButton(
            isErrorButton: true,
            text: "DELETE",
            isButtonEnabled: true,
            onPress: onDelPressed,
          ),
        ),
        SizedBox(
          width: SizeConfig.h,
        ),
        Expanded(
          child: DefaultButton(
            text: "SEARCH",
            isButtonEnabled: true,
            onPress: () => clientBloc.add(ClientSearchEvent(false)),
          ),
        ),
      ],
    );
  }
}
