// Bitta chek ikki marta vozvrat qilinishiga qarshi himoyalar.
//
// Do'kondagi xato (2026-11-14, Tiin Optom): server "refund amount is greater
// than expected amount" — chekdagi hamma tovar allaqachon qaytarilgan, kassa
// esa yana vozvrat yuborgan. Sabab: "Qaytarish" ikki marta bosilganda ikkita
// vozvrat sahifasi ustma-ust ochilardi; birinchisida vozvrat qilingach
// tagidan eski ro'yxatli ikkinchisi chiqar, kassir yana qaytarardi (ikkinchi
// fiskal chek + server rad etishi). Mac DEV kassasida qayta chiqarilgan
// (2026-11-16).
//
//   1. sahifa ochilgandan keyin lokal vozvrat saqlangan → Blocked, fiskal YO'Q
//   2. serverda qoldiq 0 (boshqa kassa/adminka)          → Blocked, fiskal YO'Q
//   3. server qoldig'i yetarli                           → vozvrat o'tadi
//   4. server qoldig'i 1, serverga yetmagan lokal 1      → Blocked
//   5. server javob bermadi (qoldiq noma'lum)            → vozvrat o'tadi
//   6. sahifa ochilishidan OLDINGI lokal vozvrat         → eskirgan emas
//   7. ikki hodisa ketma-ket (ikki marta bosish)         → fiskal BIR marta
//   8. "Bekor qilish" internet tekshiruvi paytida        → hech narsa chaqirilmaydi
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/receipt/refund_preflight.dart';
import 'package:invan2/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/l10n/app_localizations_uz.dart';

import 'return_bloc_flow_test.dart' as base;
import 'support/provider_harness.dart';

const int kOpenedAt = 1000000;

ReceiptModelSoldItem4 item(String id, double qty) =>
    base.row(productId: 'p-$id', value: qty)..refundItemId = id;

/// Vozvrat sahifasidagi model: `returnForCheck` = asl chek raqami.
ReceiptModel4 pageReceipt() => base.sale()..returnForCheck = 'DN-100';

ReceiptModel4 localRefund({
  required int date,
  bool uploaded = true,
  List<ReceiptModelSoldItem4> items = const [],
}) {
  final r = base.sale()
    ..isRefund = true
    ..returnForCheck = 'DN-100'
    ..date = date
    ..uploaded = uploaded;
  r.soldItemList
    ..clear()
    ..addAll(items);
  return r;
}

class Guarded {
  final base.FakeDeps fake = base.FakeDeps();
  List<ReceiptModel4> locals = [];
  Map<String, double>? remaining;
  int remainingCalls = 0;
  Duration internetDelay = Duration.zero;

  ReturnBlocDeps build() {
    final b = fake.build();
    return ReturnBlocDeps(
      hasInternet: () async {
        await Future<void>.delayed(internetDelay);
        return fake.internet;
      },
      isServerUp: b.isServerUp,
      withOfd: b.withOfd,
      nextCheckNo: b.nextCheckNo,
      fiscalSell: b.fiscalSell,
      saveLocal: b.saveLocal,
      uploadToServer: b.uploadToServer,
      localRefundsOf: (_) => locals,
      serverRemaining: (_) async {
        remainingCalls++;
        return remaining;
      },
    );
  }
}

ReturnReturnEvent event(List<ReceiptModelSoldItem4> right) => ReturnReturnEvent(
      isRetry: false,
      pageOpenedAt: kOpenedAt,
      clientNumber: '',
      receiptModel4: pageReceipt(),
      rightList: right,
      loc: AppLocalizationsUz(),
    );

Future<List<ReturnState>> drive(
  Guarded g,
  void Function(ReturnBloc bloc) act,
) async {
  final bloc = ReturnBloc(deps: g.build());
  final states = <ReturnState>[];
  final sub = bloc.stream.listen(states.add);
  act(bloc);
  await Future<void>.delayed(const Duration(milliseconds: 400));
  await sub.cancel();
  await bloc.close();
  return states;
}

void main() {
  setUpAll(() => setUpPosTestEnv('refund_double_guard', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    await Pref.setString(PrefKeys.cashId, 'cash-id');
  });

  test('1. sahifa ochilgandan keyin lokal vozvrat bor — Blocked, fiskal yo\'q',
      () async {
    final g = Guarded()..locals = [localRefund(date: kOpenedAt + 5000)];
    final states = await drive(g, (b) => b.add(event([item('i1', 1)])));
    expect(states.last, isA<ReturnBlockedState>());
    expect((states.last as ReturnBlockedState).message,
        AppLocalizationsUz().vozvrat_sahifa_eskirgan);
    expect(g.fake.calls, isEmpty,
        reason: 'fiskal chek chiqmasligi, hech narsa saqlanmasligi kerak');
  });

  test('2. serverda qoldiq 0 — Blocked, fiskal yo\'q', () async {
    final g = Guarded()..remaining = {'i1': 0, 'i2': 0};
    final states = await drive(
        g, (b) => b.add(event([item('i1', 1), item('i2', 2)])));
    expect(states.last, isA<ReturnBlockedState>());
    expect((states.last as ReturnBlockedState).message, contains('Test tovar'));
    expect(g.fake.calls, isEmpty);
  });

  test('3. server qoldig\'i yetarli — vozvrat o\'tadi', () async {
    final g = Guarded()..remaining = {'i1': 2};
    final states = await drive(g, (b) => b.add(event([item('i1', 2)])));
    expect(states.last, isA<ReturnSuccedState>());
    expect(g.fake.calls, ['fiscal', 'save', 'upload']);
  });

  test('4. server qoldig\'i 1, serverga yetmagan lokal vozvrat 1 — Blocked',
      () async {
    final g = Guarded()
      ..remaining = {'i1': 1}
      ..locals = [
        localRefund(
            date: kOpenedAt - 5000, uploaded: false, items: [item('i1', 1)]),
      ];
    final states = await drive(g, (b) => b.add(event([item('i1', 1)])));
    expect(states.last, isA<ReturnBlockedState>());
    expect(g.fake.calls, isEmpty);
  });

  test('5. server javob bermadi — tekshiruv o\'tkazib yuboriladi', () async {
    final g = Guarded()..remaining = null;
    final states = await drive(g, (b) => b.add(event([item('i1', 1)])));
    expect(g.remainingCalls, 1);
    expect(states.last, isA<ReturnSuccedState>());
  });

  test('5b. server yiqilgani ma\'lum — serverdan so\'ralmaydi, vozvrat o\'tadi',
      () async {
    final g = Guarded()..fake.serverUp = false;
    final states = await drive(g, (b) => b.add(event([item('i1', 1)])));
    expect(g.remainingCalls, 0);
    expect(states.last, isA<ReturnSuccedState>());
    expect(g.fake.calls, ['fiscal', 'save']);
  });

  test('6. sahifa ochilishidan oldingi lokal vozvrat — eskirgan emas',
      () async {
    final g = Guarded()
      ..remaining = {'i1': 1}
      ..locals = [
        localRefund(date: kOpenedAt - 5000, items: [item('i1', 1)]),
      ];
    final states = await drive(g, (b) => b.add(event([item('i1', 1)])));
    expect(states.last, isA<ReturnSuccedState>());
  });

  test('7. ikki hodisa ketma-ket — fiskal bir marta', () async {
    final g = Guarded()..remaining = {'i1': 1};
    await drive(g, (b) {
      b.add(event([item('i1', 1)]));
      b.add(event([item('i1', 1)]));
    });
    expect(g.fake.calls.where((c) => c == 'fiscal').length, 1);
    expect(g.fake.calls.where((c) => c == 'save').length, 1);
  });

  test('8. "Bekor qilish" internet tekshiruvi paytida — vozvrat to\'xtaydi',
      () async {
    final g = Guarded()..internetDelay = const Duration(milliseconds: 100);
    final states = await drive(g, (b) {
      b.add(event([item('i1', 1)]));
      Future<void>.delayed(
          const Duration(milliseconds: 30), b.cancelBeforeStart);
    });
    expect(g.fake.calls, isEmpty);
    expect(states.last, isA<ReturnInitial>());
  });

  test('RefundPreflight: bitta id ikki qatorda — yig\'indisi tekshiriladi', () {
    final over = RefundPreflight.firstOverdrawn(
      requested: [item('i1', 6), item('i1', 1)],
      serverRemaining: {'i1': 6},
      localRefunds: const [],
    );
    expect(over, isNotNull);
    expect(
      RefundPreflight.firstOverdrawn(
        requested: [item('i1', 6), item('i1', 1)],
        serverRemaining: {'i1': 7},
        localRefunds: const [],
      ),
      isNull,
    );
  });
}
