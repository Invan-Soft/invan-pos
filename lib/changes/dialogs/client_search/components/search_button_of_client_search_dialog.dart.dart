import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/bloc/client_search/client_search_bloc.dart';
import 'package:invan2/widgets/default_button.dart';

class SearchButtonOfClientDialog extends StatelessWidget {
  final bool alsoCheckSupplier;

  const SearchButtonOfClientDialog({super.key, this.alsoCheckSupplier = false});

  @override
  Widget build(BuildContext context) {
    ClientBloc clientBloc = BlocProvider.of(context);
    return DefaultButton(
      text: "SEARCH",
      isButtonEnabled: true,
      onPress: () => clientBloc.add(
        ClientSearchEvent(true, alsoCheckSupplier: alsoCheckSupplier),
      ),
    );
  }
}
