# Task: Shorebird build/patch olinganini Telegram kanalga hisobot qilish

**Boshlangan:** 2026-10-02
**Holat:** in-progress (1.1.2+129 relizi bilan; prod'da birinchi xabarlarni kuzatish kutilmoqda)
**Branch:** fix/smena-navbat-fifo (ishchi papka; commit qilinmagan)

## Maqsad
Qaysi do'konning qaysi kassasi oxirgi Shorebird build'ni (reliz yoki patch)
olganini kuzatish: har qurilma har build uchun bir marta "✅ muammo yo'q"
xabari; Shorebird yangilanish yo'lidagi xatolar ham kanalga.

## Scope
- `lib/changes/services/patch_reporter.dart` (YANGI) — barcha mantiq
- `lib/changes/services/patch_updater.dart` — 6 ta `PatchReporter.error(...)`
  + `start()` ichida `PatchReporter.start(_updater)` (main.dart ga tegilmadi)
- `lib/utils/constants/pref_keys.dart` — `patchReportedBuild`,
  `patchPendingBuild`, `patchReportErrors`
- `test/patch_reporter_test.dart` (YANGI) — 26 test
- Scope dan tashqari: boshqa (Shorebird bo'lmagan) xatolar, StartupErrorApp

## Bajarilgan
- [x] PatchReporter: "build olindi" (installed), rollback, "patch ishga
  tushmadi" (notApplied), Shorebird xatolari
  → lib/changes/services/patch_reporter.dart
  → Sabab: alohida fayl — boshqa sessiya patch_updater/main.dart ustida
    ishlayotgan edi, tegish nuqtalari minimal
- [x] Hisobot dastur yangi build'da ISHGA TUSHGANDA (yuklanganda emas) —
  kalit `<versiya>#<patch>`, Pref'da; yuborilmasa 5 daqiqada / server
  qaytganda qayta uriniladi; aktivatsiyagacha (storeName bo'sh) kutadi
- [x] Xato filtri: tarmoq xatolari (oflayn kassa) yuborilmaydi;
  installFailed doim; bir xil xato bir build'da 1 marta; kuniga ≤10;
  startup'dagi checkForUpdate xatosi (avtomatik yuklovchi bilan poyga)
  yuborilmaydi
- [x] Testlar: `flutter test test/patch_reporter_test.dart` — 26/26

- [x] Bot @invan_update_monitor_bot, kanal "Invan Shorebird Builds"
  (-1003904407778) — kodga qo'yildi (foydalanuvchi qarori: A varianti, kodda
  const); curl bilan namunaviy xabar → 200
  → lib/changes/services/patch_reporter.dart `_botToken` / `_chatId`

## Keyingi qadamlar (prioritet bo'yicha)
- [x] Mac sinov relizi (+9128) bilan patch → kanalda xabar ko'rinishini sinash
  (2026-10-02, reliz sessiyasi: patch 4 va patch 5 uchun "build olindi" —
  Telegram 200, `patch_reported_build` 9128#4 → 9128#5; birinchi tick
  ochilgandan 20–30 s keyin)
- [x] Commit (reliz sessiyasi, 1.1.2+129) + `docs/port-changelog.md` 12-TASK.
  Odoo forkiga: kerak emas — InVan Shorebird app_id va InVan Telegram
  kanaliga bog'langan; Odoo xohlasa o'z bot/kanali bilan oladi
- [ ] Prod: 1.1.2+129 o'rnatilgan kassalardan "build olindi" xabarlari
  kelishini va patch'dan keyin yangi xabarni kuzatish
  (Shorebird mantig'i umumiy; Odoo o'z kanalini qo'yadi)

## Qabul qilingan qarorlar
- Token kodda const (loyihadagi `TelegramNotifier` uslubi) — CI'dagi
  `TELEGRAM_BOT_TOKEN` dart-define hozir kodda ishlatilmaydi; xohlansa
  `String.fromEnvironment` ga o'tkazish oson (patch.yml/release.yml allaqachon
  uzatadi — lekin u sekret boshqa kanalniki bo'lishi mumkin)
- Logout'da Pref tozalanadi → qayta aktivatsiyadan keyin shu build yana bir
  marta "(birinchi hisobot)" bo'lib keladi — qabul qilinadi

## Ochiq savollar
- Xatolar alohida kanalga ketsinmi yoki bitta kanal? (hozir bitta)

## Test / Verifikatsiya
- Unit: test/patch_reporter_test.dart (26)
- `flutter analyze` — 3 fayl toza
