import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/services/patch_reporter.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() {
  const String v = '1.1.2+128';

  group('bootEvents — "build olindi" har build uchun bir marta', () {
    test('birinchi hisobot (hech narsa yuborilmagan) → installed', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 3, next: 3, lastReported: '', pending: '');
      expect(events.single.kind, PatchBootKind.installed);
      expect(events.single.previous, '');
    });

    test('shu build allaqachon yuborilgan → hech narsa', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 3, next: 3, lastReported: '$v#3', pending: '');
      expect(events, isEmpty);
    });

    test('yangi patch ishga tushdi → installed, oldingi ko\'rsatiladi', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 4, next: 4, lastReported: '$v#3', pending: '$v#4');
      expect(events.single.kind, PatchBootKind.installed);
      expect(events.single.previous, '$v#3');
    });

    test('yangi reliz (patchsiz) — eski relizning patch\'idan keyin → installed', () {
      final events = PatchReportLogic.bootEvents(
          version: '1.1.2+129',
          current: null,
          next: null,
          lastReported: '$v#5',
          pending: '');
      expect(events.single.kind, PatchBootKind.installed);
    });

    test('shu relizda patch raqami kamaydi → rolledBack', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 2, next: 2, lastReported: '$v#3', pending: '');
      expect(events.single.kind, PatchBootKind.rolledBack);
    });

    test('patch\'dan asl relizga qaytdi → rolledBack', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: null, next: null, lastReported: '$v#3', pending: '');
      expect(events.single.kind, PatchBootKind.rolledBack);
    });

    test('yuklangan patch ishga tushmadi (eski patch\'da qoldi) → notApplied', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 3, next: 3, lastReported: '$v#3', pending: '$v#4');
      expect(events.single.kind, PatchBootKind.notApplied);
      expect(events.single.previous, '$v#4');
    });

    test('patch hali navbatda (qayta ochilmagan) → xato emas', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 3, next: 4, lastReported: '$v#3', pending: '$v#4');
      expect(events, isEmpty);
    });

    test('kutilgandan yangiroq patch ishladi → faqat installed', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 5, next: 5, lastReported: '$v#3', pending: '$v#4');
      expect(events.single.kind, PatchBootKind.installed);
    });

    test('pending boshqa relizdan (yangi .exe o\'rnatildi) → notApplied emas', () {
      final events = PatchReportLogic.bootEvents(
          version: '1.1.2+129',
          current: null,
          next: null,
          lastReported: '1.1.2+129',
          pending: '$v#4');
      expect(events, isEmpty);
    });

    test('patch ishga tushmadi + undan oldingisi hali yuborilmagan → ikkalasi', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 3, next: 3, lastReported: '$v#2', pending: '$v#4');
      expect(events.map((e) => e.kind),
          [PatchBootKind.notApplied, PatchBootKind.installed]);
    });
  });

  group('pendingKey', () {
    test('diskda yangiroq patch → saqlanadi', () {
      expect(
          PatchReportLogic.pendingKey(
              version: v, current: 3, next: 4, previous: ''),
          '$v#4');
    });

    test('patchsiz relizda birinchi patch yuklandi', () {
      expect(
          PatchReportLogic.pendingKey(
              version: v, current: null, next: 1, previous: ''),
          '$v#1');
    });

    test('patch ishga tushdi → tozalanadi', () {
      expect(
          PatchReportLogic.pendingKey(
              version: v, current: 4, next: 4, previous: '$v#4'),
          '');
    });

    test('ishga tushmagan patch xabari hali yuborilmagan → saqlanib qoladi', () {
      expect(
          PatchReportLogic.pendingKey(
              version: v, current: 3, next: 3, previous: '$v#4'),
          '$v#4');
    });

    test('rollback kutilmoqda (next null) → pending emas', () {
      expect(
          PatchReportLogic.pendingKey(
              version: v, current: 3, next: null, previous: ''),
          '');
    });

    test('boshqa relizdagi pending → tozalanadi', () {
      expect(
          PatchReportLogic.pendingKey(
              version: '1.1.2+129', current: null, next: null, previous: '$v#4'),
          '');
    });
  });

  group('errorDecision — takror va kunlik chegara', () {
    const String day = '2026-10-02';

    test('yangi xato → yuboriladi, holat yoziladi', () {
      final d = PatchReportLogic.errorDecision(
          state: {}, buildKey: '$v#3', today: day, signature: 'a', dailyCap: 10);
      expect(d.send, isTrue);
      expect(d.newState['sigs'], ['a']);
      expect(d.newState['count'], 1);
    });

    test('shu build\'da shu xato bor → yuborilmaydi', () {
      final d = PatchReportLogic.errorDecision(
          state: {'build': '$v#3', 'day': day, 'count': 1, 'sigs': ['a']},
          buildKey: '$v#3',
          today: day,
          signature: 'a',
          dailyCap: 10);
      expect(d.send, isFalse);
    });

    test('yangi build\'da shu xato → yana yuboriladi', () {
      final d = PatchReportLogic.errorDecision(
          state: {'build': '$v#3', 'day': day, 'count': 1, 'sigs': ['a']},
          buildKey: '$v#4',
          today: day,
          signature: 'a',
          dailyCap: 10);
      expect(d.send, isTrue);
      expect(d.newState['sigs'], ['a']);
      expect(d.newState['count'], 2);
    });

    test('kunlik chegara → yuborilmaydi, ertasiga yana', () {
      final state = {'build': '$v#3', 'day': day, 'count': 10, 'sigs': ['x']};
      expect(
          PatchReportLogic.errorDecision(
                  state: state,
                  buildKey: '$v#3',
                  today: day,
                  signature: 'b',
                  dailyCap: 10)
              .send,
          isFalse);
      expect(
          PatchReportLogic.errorDecision(
                  state: state,
                  buildKey: '$v#3',
                  today: '2026-10-03',
                  signature: 'b',
                  dailyCap: 10)
              .send,
          isTrue);
    });
  });

  group('isNetworkError — oflayn kassa kanalni to\'ldirmaydi', () {
    test('tarmoq istisnolari', () {
      expect(PatchReportLogic.isNetworkError(const SocketException('x')), isTrue);
      expect(PatchReportLogic.isNetworkError(TimeoutException('x')), isTrue);
      expect(PatchReportLogic.isNetworkError(http.ClientException('x')), isTrue);
    });

    test('Shorebird yuklash xatosi tarmoq sababli → tarmoq', () {
      const e = UpdateException(
          message: 'error sending request for url (https://api.shorebird.dev)',
          reason: UpdateFailureReason.downloadFailed);
      expect(PatchReportLogic.isNetworkError(e), isTrue);
    });

    test('yaroqsiz patch (installFailed) → doim yuboriladi', () {
      const e = UpdateException(
          message: 'connection reset while hashing',
          reason: UpdateFailureReason.installFailed);
      expect(PatchReportLogic.isNetworkError(e), isFalse);
    });

    test('noma\'lum Shorebird xatosi → yuboriladi', () {
      const e = UpdateException(
          message: 'Patch hash mismatch',
          reason: UpdateFailureReason.downloadFailed);
      expect(PatchReportLogic.isNetworkError(e), isFalse);
    });
  });

  test('describe va signature', () {
    expect(PatchReportLogic.describe('$v#3'), '1.1.2+128 · patch 3');
    expect(PatchReportLogic.describe(v), '1.1.2+128 · asl reliz');
    expect(
        const PatchErrorReport(stage: 'update', message: 'port 5123 fail')
            .signature,
        const PatchErrorReport(stage: 'update', message: 'port 7000 fail')
            .signature);
  });
}
