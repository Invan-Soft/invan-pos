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

## Kassada test natijasi (2026-06-11)
- Config fayl `config.ini` ekan (kengaytma yashirilgan) — papka-skanerlash tuzatdi.
- ✅ Config YOZISH admin'siz ham ishladi — haqiqiy `config.ini` to'g'ri o'zgardi
  (eski ofd*.yt.uz ketdi, s0/s1/s2 qoldi). VirtualStore taxmini NOTO'G'RI chiqdi.
- ⚠️ Faqat `taskkill` ishlamadi (exit 1) — SYSTEM servisini o'chirish admin
  talab qiladi. Servis hali ishlab turgan eski config'ni xotirada ushlaydi.
- YECHIM: config allaqachon to'g'ri → kompyuterni BIR MARTA restart qilsa
  (yoki services.msc'dan FiscalDriveAPI restart), servis yangisini o'qiydi. Tamom.
- Log xabari yumshatildi: endi "kompyuterni bir marta qayta yoqing" deb yozadi.

## Yakuniy qaror (2026-06-12)
- Admin (requireAdministrator manifest) yondashuvi KO'RIB CHIQILDI va RAD ETILDI.
  Sabab: minuslari har kunlik (har ochilganda UAC, oddiy hisobda admin parol
  so'rashi → POS ochilmasligi, autostart buzilishi), foydasi esa atigi bir
  martalik servis restart. Arzimaydi.
- TANLANGAN yo'l: admin'siz. POS startup'da config'ni o'zi to'g'rilaydi
  (ishlayapti), servis yangisini KEYINGI PC restartda o'qiydi. Bir martalik.
- Manifest o'zgarishi qaytarib tashlandi (git checkout), push qilinmadi.

## Holat: working (admin'siz, per-register reboot bilan kuchga kiradi)
Kod tayyor va push qilingan: d1b22ab, d110763, 7a2f4ec.

## Ochiq savollar
- Config CRLF emas, LF (screenshot status bar: UNIX LF) — split/join '\n' to'g'ri.

## Test / Verifikatsiya
- Statik: flutter analyze toza.
- Real test kutilmoqda (bitta kassada). macOS'dan Windows xulq-atvorini
  sinab bo'lmaydi — kassada tekshirish shart.
