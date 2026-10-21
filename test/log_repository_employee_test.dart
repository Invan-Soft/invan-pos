// Telegram log'idagi "Employee" — log yozilgan PAYTDAGI kassir bo'lishi kerak.
//
// 2026-10-21 (Tiin Optom, Kassa 5) vozvrat xatosi: fiskal body'da
// `staffName: "Aqliddin"` (PIN bilan kirgan joriy kassir), Telegram log'ida
// esa `Employee: Dilorom`. Sabab: `LogRepository._currentEmployee` `static
// final` edi — ilova ochilgandan keyingi BIRINCHI log'da bir marta o'qilib,
// keyin kassir PIN bilan almashsa ham o'zgarmasdi. Natijada barcha keyingi
// log'larda birinchi kassir ismi chiqardi.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invan2/changes/models/log/log_model.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/features/get_employees/model/employees_find_response.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('log_repo_employee_test');
    Hive.init(tempDir.path);

    void reg<T>(int typeId, TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(adapter);
    }

    reg(27, LogModelAdapter());
    reg(0, EmployeeAdapter());
    reg(2, EmployeeAccessAdapter());
    reg(101, EmployeeUserAdapter());
    reg(102, EmployeeRoleAdapter());

    await Hive.openBox<dynamic>('prefs');
    await Hive.openBox<LogModel>('logs');
    await Hive.openBox<LogModel>('tg_logs');
    final Box<Employee> employees = await Hive.openBox<Employee>('employees');

    await employees.put(
        'u-dilorom',
        Employee(
            user: EmployeeUser(id: 'u-dilorom', firstName: 'Dilorom')));
    await employees.put(
        'u-aqliddin',
        Employee(
            user: EmployeeUser(id: 'u-aqliddin', firstName: 'Aqliddin')));

    // Telegramga haqiqiy xabar ketmasin: `success: true` + successToTelegram
    // o'chiq bo'lsa log lokal qutiga yoziladi va Telegramdan oldin qaytadi.
    await Pref.setBool(PrefKeys.successToTelegram, false);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  /// Kassir PIN bilan kirgandagi kabi (lock_buttons_with_shortcuts.dart
  /// `goHomePage`): ism va ID Pref'ga yoziladi.
  Future<void> login(String id, String name) async {
    await Pref.setString(PrefKeys.cashierId, id);
    await Pref.setString(PrefKeys.cashierName, name);
  }

  String? lastUserName() => Hive.box<LogModel>('logs').values.last.userName;

  test('addLog: kassir almashsa log\'dagi xodim ham almashadi', () async {
    await login('u-dilorom', 'Dilorom');
    await LogRepository.addLog('birinchi', where: 'test', success: true);
    expect(lastUserName(), 'Dilorom');

    await login('u-aqliddin', 'Aqliddin');
    await LogRepository.addLog('ikkinchi', where: 'test', success: true);
    expect(lastUserName(), 'Aqliddin',
        reason: 'ilgari birinchi log\'dagi kassir (Dilorom) qotib qolardi');
  });

  test('requestSend: kassir almashsa log\'dagi xodim ham almashadi', () async {
    await login('u-dilorom', 'Dilorom');
    await LogRepository.requestSend('birinchi',
        where: 'test', file: 'f', method: 'POST', path: 'p', success: true);
    expect(lastUserName(), 'Dilorom');

    await login('u-aqliddin', 'Aqliddin');
    await LogRepository.requestSend('ikkinchi',
        where: 'test', file: 'f', method: 'POST', path: 'p', success: true);
    expect(lastUserName(), 'Aqliddin');
  });

  test('xodim topilmasa (hali hech kim kirmagan) — "null"', () async {
    await login('yo\'q-id', '');
    await LogRepository.addLog('kirishdan oldin', where: 'test', success: true);
    expect(lastUserName(), 'null');
  });
}
