// Kaftpay yon menyuda (2026-11-02, Sozlamalardan ko'chirildi): faqat Kaftpay
// to'lov turi ulangan kassada, "Sozlamalar" dan keyin.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/features/drawer/model/drawer_item.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';

import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => setUpPosTestEnv('kaftpay_drawer', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  Future<List<DrawerItemId>> items(WidgetTester tester) async {
    late List<DrawerItemId> ids;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('uz'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (ctx) {
        ids = DrawerItem.drawerList(ctx).map((e) => e.id).toList();
        return const SizedBox();
      }),
    ));
    return ids;
  }

  testWidgets('Kaftpay ulangan — "Sozlamalar" dan keyin', (tester) async {
    await tester.runAsync(() => Pref.setString(PrefKeys.kaftpayId, 'kp'));
    final ids = await items(tester);
    expect(ids.indexOf(DrawerItemId.kaftpay),
        ids.indexOf(DrawerItemId.settings) + 1);
  });

  testWidgets('Kaftpay ulanmagan — menyuda yo\'q', (tester) async {
    await tester.runAsync(() => Pref.setString(PrefKeys.kaftpayId, ''));
    expect(await items(tester), isNot(contains(DrawerItemId.kaftpay)));
  });
}
