# Task: Shorebird patch'ini Mac'da sinash — kassir uchun maksimal oson yangilanish

**Boshlangan:** 2026-10-02
**Holat:** in-progress (relizda — 1.1.2+129, PRO, 2026-10-02; Windows prod sinovi kutilmoqda)
**Branch:** fix/smena-navbat-fifo → `ayyubxon` (commit `40bc8c2`, `5112b2b`, `f21c8d8`; reliz `c4e42e1`). Sinov o'zgarishlari (entitlements, ranglar) commit QILINMAGAN

## Maqsad
Reliz oldidan Shorebird code push'ni (PatchUpdater: df6ef7c, 919e601,
d16df8a) Mac'da sinash: (1) ilova OCHIQ paytda patch — "Yangilanish tayyor"
tugmasi → qayta ishga tushish; (2) ilova YOPIQ paytda patch — qayta ochilganda
bir martada qo'llanishi. Kassir uchun qadamlar iloji boricha oson bo'lishi.

## Sinov sozlamasi (xavfsizlik)
- Shorebird'da faqat `1.1.2+128 windows` reliz bor (Flutter 3.41.3).
- Mac sinov relizi ALOHIDA versiya: `1.1.2+9128` (`--build-name/--build-number`,
  pubspec'ga tegilmaydi) — ishlab chiqarish relizi yozuviga patch aralashmaydi.
- Mac patch faqat macOS relizlariga tushadi — Windows kassalariga yetmaydi.
  Ilova faqat `stable` ni o'qiydi → Mac patch `stable` ga (kassadagi yo'lning
  o'zi sinalishi uchun).
- API: DEV (ishchi papkadagi api_provider).

## VAQTINCHALIK o'zgarishlar (sinovdan keyin QAYTARILADI, commit qilinmaydi)
- `macos/Runner/Release.entitlements` — sandbox false + network.client true
  (asl: faqat sandbox true → Release build internetga chiqa olmasdi; Debug'da
  bor edi).
- `lib/features/home/home_page.dart` — patch rangi (qizil va h.k.).

## Bajarilgan
- [x] Tahlil: PatchUpdater oqimi, patch.yml/release.yml, mavjud relizlar,
  Release entitlements muammosi
- [x] Mac sinov relizi `1.1.2+9128` (Flutter 3.41.3) — Shorebird talabi bilan
  Release.entitlements'ga `cs.allow-unsigned-executable-memory` ham qo'shildi
- [x] Patch 1 (qizil): ochilishda Shorebird o'zi 1.6 s da yukladi, lekin
  ESKI `applyOnStartup` qayta ishga TUSHIRMADI; ilova ichida — savat
  bo'shagach "Yangilanish tayyor" tugmasi chiqdi → bosildi → qizil ✅
  (ichki yo'l ishlaydi; tugma savatda mahsulot bo'lsa ko'rinmaydi)
- [x] TUZATISH: `PatchUpdater.applyOnStartup` — byudjet (8 s) ichida
  vaqtga asoslangan tsikl, har chaqiruv xatosi qayta urinish, diskdagi tayyor
  patch tarmoqsiz aniqlanadi (`readNextPatch != readCurrentPatch`),
  `upToDate` ikki marta ketma-ket bo'lsagina "patch yo'q"; `[PATCH]` loglari
  (LogHelper → request_logs_of_invan_pos.txt)
  → lib/changes/services/patch_updater.dart
  → Sabab: ochilishda Shorebird'ning avtomatik yuklovchisi bilan poyga
- [x] Patch 2 (yashil + yangi mantiq) → qo'llandi (last_booted 2)
- [x] Patch 3 (ko'k): ilova BIR MARTA ochildi → +3 s da o'zi qayta ishga
  tushdi (`INVAN_PATCH_RELAUNCHED=1`), last_booted 3 ✅ — YANGI MANTIQ ISHLAYDI
- [x] Qora oyna (15:21) — Shorebird EMAS: Odoo forki Mac'da ham
  `com.example.invan2` bundle id → umumiy `~/Library/Application Support/
  com.example.invan2/` → Odoo forki ObjectBox'ni sxema 61 ga ko'targan,
  InVan 2 (50) ochmaydi: `ObjectBoxException: DB's last property ID 61 is
  higher than the incoming one 50 in entity ReceiptModel4` (main.dart:88 →
  runApp gacha yetmaydi). Bazalar zaxiraga ko'chirildi:
  `_backup_objectbox_odoo61_20261002_1528/`
- [x] Lokal `shorebird patch` ba'zan "Unauthorized" (uzoq build'dan keyin
  sessiya) — qayta yuborishda o'tadi; CI API kalitni ishlatadi

- [x] Foydalanuvchi tasdiqladi: ko'k, "ishladi" (2026-10-02)
- [x] Vaqtinchalik o'zgarishlar QAYTARILDI (home_page.dart rangi,
  Release.entitlements) — `git checkout`
- [x] +128 dan keyin ObjectBox sxemasi o'zgarmagan; native o'zgarish yo'q
  (faqat pubspec: shorebird_code_push — sof Dart) → keyingi yangilanish
  +128 ga patch sifatida ham yetishi mumkin

- [x] Taklif 1 — "✓ Dastur yangilandi" xabari: yangilanish uchun o'zi qayta
  ochilgan jarayonda (`PatchUpdater.relaunchedForUpdate`, env
  INVAN_PATCH_RELAUNCHED=1) birinchi ekranda 4 s yashil snackbar
  (`showPatchUpdatedMessage`, SizeConfig'ga bog'liq emas; navigator
  konteksti tayyor bo'lguncha 10 marta urinadi)
  → lib/features/home/components/patch_restart_button.dart, main.dart
  → Mac'da tasdiqlandi: PIN ekranida "✓ Программа обновлена"
- [x] Taklif 3 — ishga tushish xato ekrani: main() dagi bazalar/sozlamalar
  `_initData()` ga ajratildi va try/catch; xato bo'lsa `StartupErrorApp`
  (ikki tilda, ObjectBox sxemasi uchun alohida matn, asl xato, "Qayta ishga
  tushirish" — patch tekshiruvi bilan) + `[STARTUP]` log + `_showWindow()`
  (Windows'da oyna startup'da yashirin — xato ekrani ham ko'rinishi uchun)
  → lib/app/startup_error_app.dart (YANGI), lib/main.dart
  → test/startup_error_app_test.dart (2 test)
  → Mac'da tasdiqlandi: odoo61 baza nusxasi bilan — qora oyna o'rniga ekran;
    bazalar keyin asl holiga qaytarildi
- [ ] Taklif 2 (savat to'la paytdagi ishora) — foydalanuvchi tanlamadi

- [x] Rollback sinovi: patch 3 (ko'k) `shorebird patches rollback` → ilova
  BIR ochilishda patch 2 ga qaytdi (rollforward ham ishlaydi)
  → docs/shorebird-qoidalari.md 5-bo'lim
- [x] Patch 4 — oflayn tuzatish: ketma-ket 2 ta chaqiruv xatosi → darhol
  ochilish (ilgari internetsiz kassa HAR ochilishda 8 s kutardi); har
  chaqiruvga qolgan byudjet bilan timeout; `[PATCH]` loglari `debugPrint`
  ga ham (Mac'da Documents'dagi log faylini terminal o'qiy olmaydi —
  binary to'g'ridan-to'g'ri ishga tushirilib stdout o'qiladi)
- [x] Ochilish o'lchovlari (patch 4): yangilanish — +8 s da bitta ochilishda
  patch 4 ✅; internet yo'q (proxy rad etadi) — 430 ms ✅; oddiy, patch
  yo'q — **1181 ms** (ikkinchi tarmoq so'rovi); internet osilgan (Wi-Fi bor,
  javob yo'q) — **8408 ms** ❌ (oyna 8 s yashirin)
- [x] TUZATISH (patch 5): `upToDate` → ikkinchi tarmoq so'rovi o'rniga 300 ms
  kutib lokal tekshiruv; har startup tekshiruviga 3 s chegara
  (`_checkCap`), chegaraga yetsa — qayta urinmasdan darhol ochiladi
  → lib/changes/services/patch_updater.dart `_waitForPatchOnStartup`
  → Sabab: kundalik ochilish ~0.8 s tezroq; "osilgan" internet 8.4 s → ~3 s
- [x] Patch 5 boshqa sessiyaning yarim tahrirlari (to'lov/chek fayllari —
  kompilyatsiya xatosi) tufayli asosiy papkadan build bo'lmadi → alohida
  git worktree'da (HEAD d16df8a + faqat shu task fayllari) build qilindi
- [x] Patch 5 o'lchovlari (2026-10-02 16:42): 4→5 bitta ochilishda (+3.2 s
  qayta yondi, last_booted 5) ✅; oddiy — 710/761 ms (oldin 1181);
  internet yo'q — 316 ms (oldin 430); osilgan internet — 3040 ms (oldin
  8408) ✅. Jarayonlar 20 s dan oldin yopildi (Telegram'ga xabar ketmadi;
  Mac prefs'da `patch_reported_build` yo'q)
- [x] `update()` → "Update already in progress (unknown)" — avtomatik
  yuklovchi bilan zararsiz poyga, lekin PatchReporter uni kanalga "❌
  Shorebird xatosi" deb yuborardi (sekin internetda — har patch'da).
  shorebird_code_push 2.0.7 buni zararsiz deb o'tkazishi kerak edi, ammo
  3.41.3 dvigateli umumiy xato kodini qaytaradi → `isUpdateInProgress`
  filtri (UpdateException + matn)
  → lib/changes/services/patch_updater.dart `_safeUpdate`
  → test/patch_updater_test.dart (3 test)
- [x] Vaqtinchalik `Release.entitlements` QAYTARILDI (`git checkout`)
- [x] TOPILMA (Windows, sinalmagan): `CheckOneInstance`
  (windows/runner/win32_window.cpp:105) — qayta yongan jarayon eski jarayon
  yopilmasidan oldin tekshirsa jim yopiladi (main.cpp: EXIT_FAILURE).
  Mac'da bu tekshiruv yo'q. Tuzatish taklifi — "Keyingi qadamlar"
- [x] Xato ekranidagi "Qayta ishga tushirish": meros `INVAN_PATCH_RELAUNCHED`
  olib tashlanadi (aks holda yangi jarayon patch tekshiruvini/rollback'ni
  o'tkazib yuborardi va "Dastur yangilandi" derdi), `INVAN_RESTART=1`
  qo'yiladi (Windows runner kutishi uchun)
  → lib/app/startup_error_app.dart `restartEnvironment`, test (+1)
- [x] Windows runner (foydalanuvchi qarori, 1.1.2+129 ga): `CheckOneInstance`
  `INVAN_PATCH_RELAUNCHED=1` yoki `INVAN_RESTART=1` bo'lsa 100 × 100 ms eski
  nusxa yopilishini kutadi; kassir o'zi ochganda xulq o'zgarmagan. Faqat
  ASCII, `/W4 /WX` uchun `== 1u`; clang stub bilan -Wall -Wextra -Werror
  toza; MSVC — CI build
  → windows/runner/win32_window.cpp:105
- [x] PatchReporter Mac sinovi (foydalanuvchi ruxsati bilan): patch 5 bilan
  50 s — `patch_reported_build` 9128#4 → 9128#5 (Telegram 200). TUZATISH:
  avvalroq "Mac'dan kanalga hech narsa ketmagan" deyilgan edi — noto'g'ri:
  patch 4 sinovidagi skript qayta yongan jarayonni yopmagan, u ~50 s
  ishlab patch 4 xabarini yuborgan
- [x] To'liq to'plam (ikkala sessiya ishi birga): 1616/1616, analyze 0 error

## Keyingi qadamlar
- [x] Windows qayta yonish tuzatishi — 1.1.2+129 ga qo'shildi (yuqorida)
- [ ] Windows prod sinovi (1.1.2+129 o'rnatilgach birinchi patch bilan):
  (1) yopiq dastur ochiladi → bir martada yangi patch + "Dastur
  yangilandi"; (2) ish vaqtida tugma → dastur qayta ochiladi (yopilib
  qolmaydi); (3) Telegram'da "build olindi"
- [ ] Odoo forkiga tavsiya: macOS bundle id ni ajratish (u yerda qilinadi);
  Odoo forki ma'lumotlari: `_backup_objectbox_odoo61_20261002_1528/`
- [x] Sinov worktree'si o'chirildi

## Ochiq savollar
- Kassir uchun soddalashtirish takliflari (sinov natijasiga qarab).
- Ishlab chiqarishda (+128 Windows) PatchUpdater stable #5 (919e601)
  orqali BOR, lekin ESKI ochilish mantig'i bilan — yangi mantiq keyingi
  patch bilan yetadi; o'sha patch'ning o'zi hali eski mantiq bilan
  qo'llanadi (tugma yoki 2-ochilish), keyingilari — bir ochilishda.
- XAVF: ObjectBox modelini o'zgartiradigan o'zgarish patch bilan chiqsa va
  keyin rollback bo'lsa — ilova ochilmaydi. Qoida yozildi
  (docs/shorebird-qoidalari.md 2-bo'lim); qora oyna o'rniga endi
  `StartupErrorApp` xabari (Taklif 3).
- PatchReporter (parallel sessiya) haqiqiy Telegram kanaliga ulangan —
  Mac sinov build'i ham "build olindi" yuboradi (ochilgandan 20 s keyin).
  Sinovlarda jarayonlar 20 s dan oldin yopiladi.

## Test / Verifikatsiya
- Mac, Shorebird `1.1.2+9128` macos, stable, patch 1-5 (yuqorida).
