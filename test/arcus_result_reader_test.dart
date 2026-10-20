// ArcusResultReader — eski (oldingi operatsiya) log/chekka ishonmaslik.
//
// Sabab: 2026-10-20 da INI papkasi topilmay Arcus2 999 bilan chiqib ketdi,
// yangi log yozilmadi; eski kod oxirgi muvaffaqiyatli logni o'qib, terminalga
// so'rov bormasdan "ОДОБРЕНО" dedi va eski chekni chop etdi.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/terminal/terminal_receipt_parser.dart';
import 'package:invan2/changes/services/payment/arcus_result_reader.dart';
import 'package:windows1251/windows1251.dart';

const _approvedLog = '''
2026/10/20 13:30:15 RECV <- STORERC:000
2026/10/20 13:30:16 RECV <- PRINT:Одобрено
2026/10/20 13:30:16 RECV <- ENDTR
''';

final _sep = Platform.pathSeparator;

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('arcus_reader_test');
    await Directory('${dir.path}${_sep}Logs').create();
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Future<File> writeCp1251(String name, String text, {DateTime? at}) async {
    final f = File('${dir.path}$_sep$name');
    await f.writeAsBytes(windows1251.encode(text));
    if (at != null) await f.setLastModified(at);
    return f;
  }

  test('Arcus2 yangi log yozmasa — eski tasdiqlangan log qabul qilinmaydi',
      () async {
    final old = DateTime.now().subtract(const Duration(minutes: 48));
    await writeCp1251('Logs${_sep}261020133015.log', _approvedLog, at: old);
    await writeCp1251('cheq.out', 'TASDIQLANDI\nRRN :629308797462', at: old);
    await writeCp1251('output.dat', '999\n\n\n10000\n860\n');

    final r = await ArcusResultReader.read(
      startedAt: DateTime.now(),
      arcusDir: dir.path,
    );

    expect(r.isFresh, isFalse);
    expect(r.receipt, isEmpty);
    expect(r.log, contains('999'));
    // Provider shartini takrorlaymiz: isFresh && isTerminalApproved.
    expect(
        r.isFresh && TerminalReceiptParser.isTerminalApproved(r.log), isFalse);
  });

  test('operatsiya davomida yozilgan log va chek o\'qiladi', () async {
    final started = DateTime.now();
    await writeCp1251('Logs${_sep}old.log', 'eski',
        at: started.subtract(const Duration(hours: 1)));
    await writeCp1251('Logs${_sep}new.log', _approvedLog);
    await writeCp1251('cheq.out', 'Одобрено\nRRN 032150038197');

    final r = await ArcusResultReader.read(
      startedAt: started,
      arcusDir: dir.path,
    );

    expect(r.isFresh, isTrue);
    expect(r.log, contains('STORERC:000'));
    expect(r.receipt, contains('032150038197'));
    expect(TerminalReceiptParser.isTerminalApproved(r.log), isTrue);
  });

  test('log yangi, lekin cheq.out eski — chek bo\'sh qaytadi', () async {
    final started = DateTime.now();
    await writeCp1251('Logs${_sep}new.log', 'Connection ERROR');
    await writeCp1251('cheq.out', 'eski chek',
        at: started.subtract(const Duration(hours: 1)));

    final r = await ArcusResultReader.read(
      startedAt: started,
      arcusDir: dir.path,
    );

    expect(r.isFresh, isTrue);
    expect(r.receipt, isEmpty);
  });

  test('Logs papkasi umuman yo\'q — isFresh false', () async {
    await Directory('${dir.path}${_sep}Logs').delete(recursive: true);

    final r = await ArcusResultReader.read(
      startedAt: DateTime.now(),
      arcusDir: dir.path,
    );

    expect(r.isFresh, isFalse);
  });
}
