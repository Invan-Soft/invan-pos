// Kaftpay sahifasi — yon menyudan (2026-11-02, foydalanuvchi: Sozlamalardan
// ko'chirildi). PIN undan oldin oynada so'raladi (KaftpayPinDialog,
// DrawerListTile). Ichida KaftpayContent: kalitlar, skaner, ro'yxatdan
// o'tkazish, to'lovlar tarixi va vozvrat — butun oyna bo'ylab.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/drawer/model/drawer_item.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/settings/view/payments/kaftpay_content.dart';
import 'package:invan2/changes/providers/paging_provider.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';
import 'package:provider/provider.dart';

class KaftpayPage extends StatefulWidget {
  const KaftpayPage({super.key});

  @override
  State<KaftpayPage> createState() => _KaftpayPageState();
}

class _KaftpayPageState extends State<KaftpayPage> {
  BlBloc? _bl;
  BLStatus? _blBefore;

  @override
  void initState() {
    super.initState();
    // Sahifadagi maydonlarga (PIN, kalitlar) yozilgan narsa sotuv savatiga
    // mahsulot deb tushmasin.
    try {
      _bl = BlocProvider.of<BlBloc>(context, listen: false);
      _blBefore = _bl!.status;
      _bl!.add(BlStatusChangedEvent(
          status: BLStatus.other, where: 'kaftpay_page initState'));
    } catch (_) {
      _bl = null; // testlarda BlBloc yo'q
    }
  }

  @override
  void dispose() {
    final bl = _bl, before = _blBefore;
    if (bl != null && before != null) {
      bl.add(
          BlStatusChangedEvent(status: before, where: 'kaftpay_page dispose'));
    }
    super.dispose();
  }

  void _back() {
    try {
      Provider.of<PagingProvider>(context, listen: false)
          .setCurrentPageId(DrawerItemId.home);
    } catch (_) {
      // testlarda PagingProvider yo'q
    }
    AppNavigation.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 3,
        backgroundColor: theme.colorScheme.background,
        leadingWidth: SizeConfig.h * 5,
        toolbarHeight: SizeConfig.v * 9.5,
        leading: Padding(
          padding: EdgeInsets.all(SizeConfig.v),
          child: TextButton(
            key: const ValueKey('kaftpay_page_back'),
            focusNode: FocusNode(skipTraversal: true),
            style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.background),
            onPressed: _back,
            child: Icon(Icons.arrow_back_ios_outlined,
                size: SizeConfig.v * 4, color: theme.canvasColor),
          ),
        ),
        title: Padding(
          padding: EdgeInsets.only(left: SizeConfig.h * 2),
          child: Text(
            'Kaftpay',
            style: MyThemes.txtStyle(
              color: theme.canvasColor,
              fontWeight: FontWeight.bold,
              fontSize: 3.2,
            ),
          ),
        ),
      ),
      body: Container(
        color: theme.dialogBackgroundColor,
        child: const KaftpayContent(),
      ),
    );
  }
}
