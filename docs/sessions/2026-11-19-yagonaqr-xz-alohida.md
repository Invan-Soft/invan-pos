# Task: YagonaQr — X/Z hisobotda alohida qator (Plastik ichida emas) + jonli sinov

**Boshlangan:** 2026-11-19
**Holat:** in-progress
**Branch:** feat/yagonaqr-xz-alohida (worktree `.claude/worktrees/yagonaqr-xz`, asos `ayyubxon` aae7500)

## Maqsad
Foydalanuvchi (2026-11-19): "x hisobot z hisobotda ham yagona qrdan to'lansa alohida Yagona Qr ga tushsin plastik
kartaga aralashtirmaylik". YagonaQr summasi smena hisobida `uzCard` ("Plastik") ga qo'shilardi — endi alohida
`SalesSummaryHive.yagonaQr` va X/Z (ekran + chop etilgan chek) da "Yagona QR" qatori. Fiskal (karta) o'zgarmaydi.
Qo'shimcha: vozvrat va aralash sotuvlarni +130 kodida jonli sinash.

## Avvalgi implementatsiya
docs/sessions/2026-10-20-yagonaqr-tolov-turi.md (15-task, `dd624bf`) — u yerda "X/Z hisobotda alohida qator yo'q —
Plastik ichida" qarori (Odoo MD 4.9 bo'yicha) qabul qilingan edi. Endi foydalanuvchi talabi bilan alohida qator.
Namuna: 24-task Kaftpay (`b154fc1`, `feat/kaftpay-xz-alohida`, merge kutilmoqda) — xuddi shu yo'l.

## Scope
- `lib/changes/models/shift/shift_hive_model.dart` (+ `.g.dart`) — `yagonaQr` HiveField **20**
- `lib/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart` — alohida summa
- `lib/features/report/features/shifts_opened/view/hive_content.dart` — X/Z ekrani
- `lib/features/printing/api/print_smena_api.dart` — X/Z cheki (57/80 mm umumiy `_buildSalesSummary`)
- `test/yagonaqr_shift_report_test.dart`
- Scope tashqarisida: fiskal (karta, `ReceivedCard`), serverga sotuv (`payment_type_id`), vozvrat qoidasi (hammasi naqd),
  smena yopilishi serverga (summa yuborilmaydi — `ShiftApi4.closeShift` faqat vaqt/kassir/kassa)

## Bajarilgan
- [x] `SalesSummaryHive.yagonaQr` (HiveField 20) + adapter qo'lda
  → `lib/changes/models/shift/shift_hive_model.dart:~250`, `.g.dart` read/write
  → Sabab: 19 Kaftpay branchiga band; eski yozuv (19 maydon) null bilan o'qiladi
- [x] Smena hisobi: `YagonaQr.isName(p.name)` → `yagonaQrPayment` (uzCard'dan chiqdi), `grossSales` ga qo'shiladi
  → `shift_singleton_4.dart:~520, ~556, ~600`
  → Sabab: nom variantlari ("Yagona QR" bo'sh joyli → avval "Other") ham bitta qatorga
- [x] X/Z ekrani (`hive_content.dart`, Plastik'dan keyin) va chek (`print_smena_api.dart`, HUMO'dan keyin) — summa > 0 bo'lsa "Yagona QR"
- [x] Testlar: `test/yagonaqr_shift_report_test.dart` qayta yozildi (13), `kaftpay_shift_report_test.dart` "YagonaQr + Kaftpay" moslandi
- [x] Commit `c609f7e` (feature branch); +130 manbasiga cherry-pick → `patch/130-yagonaqr-xz` `6263d54`
  (ziddiyat: +130 da `case 'kaftpay'` yo'q — qo'lda; kaftpay testi +130 da yo'q — olib tashlandi)
- [x] Mac DEV jonli sinov +130 kodi bilan (worktree `.claude/worktrees/yqr-130`): sotuvlar, aralash, vozvrat, X, Z — "Test" bo'limida
- [x] port-changelog 26-task bo'limi + jadval + xronologiya
- [x] Shorebird **Patch 7** → 1.1.2+130 stable (2026-11-19, run 44484471027, id 821393) — foydalanuvchi: "patchni chiqar prodda"
  → `patch/130-yagonaqr-xz` (`6263d54`) GitHub + GitLab'ga push qilindi

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] `feat/yagonaqr-xz-alohida` push + MR → `ayyubxon` — foydalanuvchi aytganda
- [ ] Windows / do'kon sinovi (X/Z chop etilgan chekda "Yagona QR" qatori)
- [ ] `feat/kaftpay-xz-alohida` merge bo'lganda: Kaftpay 19 + YagonaQr 20 (`writeByte(21)`), switch'da ikkala case

## Qabul qilingan qarorlar
- HiveField **20** (19 emas) — 19 ni `feat/kaftpay-xz-alohida` (merge qilinmagan) `kaftpay` uchun band qilgan; bitta
  raqam ikki maydonga berilsa, kassadagi eski smena yozuvlari noto'g'ri o'qiladi.
- Qator faqat summa > 0 bo'lsa chiqadi (Kaftpay, Click/Payme ekran qatorlari kabi).

## Ochiq savollar
- Vozvrat YagonaQr bilan qaytsinmi (hozir hammasi naqd — umumiy qoida)? — foydalanuvchi; bu taskda o'zgartirilmadi.

## Test / Verifikatsiya
- `flutter test test/yagonaqr_shift_report_test.dart` 13/13; to'liq: `ayyubxon` asosida 2595/11 skip, +130 manbasida 2304/4 skip.
- Mac DEV (2026-11-19, fiskal emulyator, `aa674a8` + `6263d54`, DEV kassa "dfg", "Yagona Qr" a432bff4…):
  - eski smena: Plastik 124 100 → 0, "Yagona QR" 124 100 (ekranda);
  - #172 QR 50 000 + Uzcard 30 000 + naqd 14 050 → karta 80 000 / naqd 14 050, server 3 tur 201;
  - #173 QR 40 000 + Click QR 20 000 + Payme QR 17 050 → karta 40 000, Other 37 050, server 201;
  - vozvrat #174 (DT43 to'liq, 77 050) va #175 (DT45 dan Knoppers 9 050) → fiskal naqd, `refund_order_items` CASH, 200;
  - X ekrani + PDF (Z 80 mm, X 57 mm): Пластик 30 000 / Uzcard 30 000, "Yagona QR" 214 100, Click Qr 20 000, Payme Qr 17 050;
  - smena yopildi (`shift_pos` 200), yopilgan smena Hive'da yagonaQr 214 100; yangi smena 0, #176 HUMO 50 000 + QR 27 050 →
    X: Plastik 50 000, Yagona QR 27 050.
- Mac holati: Odoo holati `_backup_odoo_20261119_1230` dan qaytarildi; InVan sinov holati `_backup_invan2_20261119_1246`.
