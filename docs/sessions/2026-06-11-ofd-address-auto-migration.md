# Task: OFD manzillarini avtomatik yangilash (eski yt.uz → s*.ofd.uz)

**Boshlangan:** 2026-06-11
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Soliq 2026-yil 1-maydan eski OFD domenlarini (ofd1..ofd4.yt.uz) o'chiradi. Har
kassaga qo'lda kirmasdan, POS ilovasining o'zi startup'da FiscalDriveAPI
config faylini tekshirib, eski manzil bo'lsa yangisiga (s0..s2.ofd.uz:3447)
almashtirsin va FiscalDriveAPI jarayonini qayta ishga tushirsin (kompyuter
restart QILMASDAN).

## Scope
- `lib/fiscal_service/ofd_config_migrator.dart` (yangi) — asosiy logika
- `lib/main.dart` — startup'da fon rejimida chaqirish
- Scope'dan tashqari: Flutter ilova kodida OFD manzili YO'Q (faqat lokal
  FiscalDriveAPI config'da, `C:\Program Files\FiscalDriveAPI\config`).

## Bajarilgan
- [x] OfdConfigMigrator sinfi yaratildi
  → lib/fiscal_service/ofd_config_migrator.dart
  → Sabab: config faylni o'qib, [server] bo'limini qayta yozadi, faqat eski
    host topilsa ishlaydi (idempotent), zaxira nusxa (.bak) oladi, taskkill
    bilan jarayonni o'chiradi (NSSM yangi config bilan tiklaydi — PC restart
    shart emas), natijani C:\ProgramData\InVanPos2\cache\ofd_migration.log ga yozadi.
- [x] main.dart startup'iga ulandi (fon rejimida, bloklamaydi)
  → lib/main.dart:129 (doWhenWindowReady'dan keyin)
  → import: lib/main.dart:8
- [x] flutter analyze toza (faqat mavjud empty_catches info qoldi)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] BITTA kassada sinash. Kutilgan natija: ilova ochilgach, config'dagi
      ofd*.yt.uz qatorlari o'chadi, s0/s1/s2 qoladi, jarayon qayta ishga tushadi.
- [ ] Log faylni tekshirish: C:\ProgramData\InVanPos2\cache\ofd_migration.log
      → "config YANGILANDI" + "jarayon qayta ishga tushirildi" bo'lishi kerak.
      → Agar "XATO: ... access denied" bo'lsa → ilova admin emas (pastga qara).
- [ ] Tasdiqlash: PowerShell `Test-NetConnection s0.ofd.uz -Port 3447` = True,
      va test chek soliqqa o'tadimi.

## Qabul qilingan qarorlar
- Per-sale emas, STARTUP'da bir marta — sotuvni sekinlashtirmaslik uchun.
- PC restart emas, faqat `taskkill /F /IM fiscal-drive-api.exe` — NSSM tiklaydi,
  config qayta o'qiladi. Servis nomini bilish shart emas (exe nomi orqali).
- Xato JIM o'tmaydi — log faylga yoziladi (admin yo'qligini aniqlash uchun).
- [server] dan tashqari hech narsaga tegilmaydi (factory_id, [api], [qrcode]).

## Ochiq savollar
- Ilova admin huquqi bilan ishlaydimi? NOMA'LUM. Agar yo'q bo'lsa, Program
  Files'ga yozolmaydi va taskkill ishlamaydi → log'da access denied chiqadi.
  Yechim variantlari: (a) Windows app manifestiga requireAdministrator qo'shish
  (har ochilganda UAC so'raydi), (b) alohida bir martalik admin skript.
- Config CRLF emas, LF (screenshot status bar: UNIX LF) — split/join '\n' to'g'ri.

## Test / Verifikatsiya
- Statik: flutter analyze toza.
- Real test kutilmoqda (bitta kassada). macOS'dan Windows xulq-atvorini
  sinab bo'lmaydi — kassada tekshirish shart.
