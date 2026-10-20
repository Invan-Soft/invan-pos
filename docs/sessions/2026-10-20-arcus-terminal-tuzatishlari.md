# Task: Arcus2 karta terminali tuzatishlari (Odoo forkidan port)

**Boshlangan:** 2026-10-20
**Holat:** in-progress (commit `4689618`, `ayyubxon` ga merge, GitHub `main` ga push — 2026-10-20; Windows kassada real terminal sinovi kutilmoqda)
**Branch:** fix/arcus-terminal (worktree: `../pos-invan-2-arcus`, `ayyubxon` d6c5a7f dan)

## Maqsad
Odoo forkida real terminallarda sinalgan 4 ta Arcus2 tuzatishini InVan 2 ga 1:1 ko'chirish.
Manba: `~/Desktop/ARCUS-TERMINAL-PORT-2026-10-20.md`.

1. SKappay `Одобрено` (kichik harf) → endi tasdiq deb olinadi (`STORERC:000` kodi ustun).
2. TezQR/UzQR da `STORERC:` bo'sh keladi → matnga qaraladi (regex `[ \t]*`, `\s*` emas).
3. **XAVFLI:** Arcus2 ishga tushmasa (999) eski log/`cheq.out` o'qilib pulsiz "ОДОБРЕНО" bo'lardi →
   `ArcusResultReader` faqat operatsiya boshlangandan keyin yozilgan faylga ishonadi.
4. Bir kompyuterda Uzcard + Humo → `ArcusProfile` to'lovdan oldin `INI-uzcard`/`INI-humo` ni `INI` ga ko'chiradi.

## Scope
- `lib/changes/domain/terminal/terminal_receipt_parser.dart` — `isTerminalApproved()`
- `lib/changes/services/payment/arcus_result_reader.dart` (yangi)
- `lib/changes/services/payment/arcus_profile.dart` (yangi)
- `lib/changes/providers/ordering_provider_4.dart` — `typeUzcard()` / `typeHumo()` faqat log o'qish + tasdiq qismi
- Testlar: `test/terminal_approval_test.dart`, `test/arcus_result_reader_test.dart`, `test/arcus_profile_test.dart`
- Scope dan tashqari: `humo_content.dart` (terminal menyusi `/o98`, balans `/o25`), `shell_page.dart`,
  984 ("band") uchun alohida xabar, QR ni hisobotda alohida to'lov turi qilish.

## Bajarilgan
- [x] `isTerminalApproved()` qo'shildi (regexda haqiqiy `\t`, TAB emas — `od -c` bilan tekshirildi)
  → lib/changes/domain/terminal/terminal_receipt_parser.dart:82
- [x] `ArcusResultReader`, `ArcusProfile` yaratildi
  → lib/changes/services/payment/arcus_result_reader.dart, arcus_profile.dart
  → Sabab (MD dan farq): yo'llar `'$dir\\Logs'` o'rniga `'$dir${_sep}Logs'` (`Platform.pathSeparator`).
    MD dagi variantda macOS'da 3 test yiqildi — `\` POSIX'da fayl nomining bir qismi, papka
    ichiga emas, yonidagi `xxx\Logs` nomli faylga yozadi. Windows'da natija bir xil (`C:\Arcus2\Logs`).
    `package:path` ishlatilmadi — pubspec'da to'g'ridan-to'g'ri dependency emas.
- [x] `typeUzcard()` / `typeHumo()`: `ArcusProfile.activate` → `markStart()` → CommandLineTool → `read()`
  → lib/changes/providers/ordering_provider_4.dart:2428-2451, 2519-2542
- [x] Ishlatilmay qolgan `dart:io`, `windows1251`, `package:file/local.dart`, ikkita `fs` olib tashlandi
- [x] Fiskal: QR Uzcard/Humo tugmasi orqali o'tadi → `FiscalPaymentSplit.of` da UZCARD/HUMO/`cardId` → `card`
  → lib/changes/domain/receipt/receipt_vat.dart:94-97 — o'zgartirish kerak emas

- [x] Commit `4689618` + `docs/port-changelog.md` 14-task bo'limi; `fix/arcus-terminal` → `ayyubxon` merge, `ayyubxon:main` GitHub'ga push
  → Sabab: foydalanuvchi Windows'da GitHub `main` dan pull olib sinamoqchi (2026-10-20). GitLab'ga push qilinmagan.

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows kassada (GitHub `main` dan pull) real terminal sinovi: karta (Uzcard, Humo), TezQR, Arcus2 o'chiq holat (999 → xato dialogi, chek chop etilmasin)
- [ ] Ikki terminalli kassada `C:\Arcus2\INI-uzcard` / `INI-humo` sozlash (MD §5)
- [ ] Sinov o'tsa: Shorebird patch (`release_version=1.1.2+129`, avval `staging`) yoki yangi versiya — foydalanuvchi qarori
- [ ] GitLab `ayyubxon` ni GitHub `main` bilan sinxronlash (so'ralsa)
- [ ] Odoo forkiga ixtiyoriy: `Platform.pathSeparator` tuzatishi (u yerda testlar faqat Windows'da o'tadi)

## Qabul qilingan qarorlar
- Alohida worktree — joriy `fix/tolov-summasi-mijoz-almashganda` da `ordering_provider_4.dart` commit qilinmagan, aralashmasin.
- `feedback_no_refactor_untestable_hardware` istisnosi: refaktoring emas, bug fix; Odoo forkida real terminalda sinalgan; foydalanuvchi so'radi.

## Ochiq savollar
- 984 (pin-pad band) uchun tushunarli xabar kerakmi — keyin.

## Test / Verifikatsiya
- `flutter test` (16 yangi + 20 eski terminal) — o'tdi; to'liq to'plam 1922 o'tdi, 4 skip.
- `flutter analyze` — yangi ogohlantirish yo'q (qolgan 3 tasi oldindan bor: paynet import, :1424, `_baseUrlProd`).
- Qurilmada sinalmagan (Mac'da Arcus yo'q).
