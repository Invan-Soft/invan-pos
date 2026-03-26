import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/themes.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../../features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import '../../../../../utils/helpers/helpers.dart';
import '../../../bloc/supplier_search/supplier_search_bloc.dart';

class SearchFieldOfSupplierSearchDialog extends StatefulWidget {
  const SearchFieldOfSupplierSearchDialog({super.key});

  @override
  State<SearchFieldOfSupplierSearchDialog> createState() =>
      _SearchFieldOfSupplierSearchDialogState();
}

class _SearchFieldOfSupplierSearchDialogState
    extends State<SearchFieldOfSupplierSearchDialog> {
  final FocusNode _focusNode = FocusNode();
  late BlBloc blBloc;

  @override
  void initState() {
    super.initState();
    blBloc = BlocProvider.of(context, listen: false);
    blBloc.add(
      BlStatusChangedEvent(
        status: BLStatus.client,
        where: 'Supplier',
      ),
    );
    blBloc.add(BlVisibilityChangedEvent(true));
  }

  @override
  Widget build(BuildContext context) {
    SupplierBloc supplierBloc = BlocProvider.of(context);
    AppLocalizations loc = AppLocalizations.of(context)!;

    return VisibilityDetector(
      key: const Key('supplier-search-field-key'),
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction > 0) {
          Future.delayed(Duration.zero, () {
            FocusScope.of(context).requestFocus(_focusNode);
          });
        }
      },
      child: TextField(
        focusNode: _focusNode,
        autofocus: true,
        onSubmitted: (v) {
          supplierBloc.add(SupplierSearchEvent());
        },
        controller: supplierBloc.controller,
        style: TextStyle(
          color: Theme.of(context).canvasColor,
          fontSize: SizeConfig.v * 2,
        ),
        cursorColor: Theme.of(context).primaryColor,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            vertical: SizeConfig.v * 1.9,
            horizontal: SizeConfig.v * 1.1,
          ),
          fillColor: Theme.of(context).dialogBackgroundColor,
          filled: true,
          suffixIcon: IconButton(
            focusNode: FocusNode(skipTraversal: true),
            onPressed: () {
              supplierBloc.add(SupplierSearchEvent());
            },
            icon: Icon(
              Icons.search,
              color: MyThemes.lightGreyColorr,
            ),
          ),
          hintStyle: TextStyle(
            color: Theme.of(context).canvasColor,
            fontSize: SizeConfig.v * 2,
          ),
          hintText: loc.ha == 'Ha' ? 'Supplier...' : 'Поставщик...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SizeConfig.v),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    blBloc.add(
      BlStatusChangedEvent(
        status: BLStatus.home,
        where: 'Home',
      ),
    );
    blBloc.add(BlVisibilityChangedEvent(false));
    super.dispose();
  }
}