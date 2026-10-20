# Task: YagonaQr to'lov turi (Odoo forkidagi variant bo'yicha)

**Boshlangan:** 2026-10-20
**Holat:** in-progress (commit `dd624bf` → `ayyubxon`, reliz 1.1.2+130 GitHub'da — backendga yuklanmagan; jonli sinov kutilmoqda)
**Branch:** feat/yagonaqr (worktree: `../pos-invan-2-yagonaqr2`, `ayyubxon` 3af900f dan)

## Maqsad
Admin panelda "YagonaQr" to'lov turi qo'shiladi. POS to'lov ekranida alohida tugma; kassir belgilaydi
(terminal integratsiyasi yo'q). Serverga YagonaQr id'si bilan, soliqqa karta (`ReceivedCard`,
`CardType` 2), aralash to'lovda ham. X/Z hisobotda alohida qator yo'q — "Plastik" ichida.
Manba: `~/Desktop/YAGONAQR-INVAN-PORT-2026-10-20.md` (Odoo forkidan).

## Avvalgi implementatsiya
`../pos-invan-2-yagonaqr` worktree, branch `feat/yagona-qr`, `docs/sessions/2026-10-19-yagona-qr-tolov-turi.md`
(commit qilinmagan, arxivlanmagan). U yerda nom bo'yicha ("YAGONA" substring, name/title) tanilardi, chek nomi
`YAGONA QR`, cardType yo'q, "faqat karta" rejimida yashirin, smenada `otherPayment`. Endi foydalanuvchi
so'rovi bilan MD (Odoo varianti) asos: id `PrefKeys.yagonaQrId`, chek nomi `YAGONAQR`, cardType 2, "faqat
karta" rejimida ko'rinadi, smenada `uzCard`. Eski worktree'ga tegilmadi.

## Scope
- `lib/changes/domain/payment/yagona_qr.dart` (YANGI), `pref_keys.dart`, `organization_singleton.dart`,
  `ordering_provider_4.dart` (`typeYagonaQr`, `PaymentIds`, `lastCardType` test getter),
  `receipt_payments.dart`, `receipt_vat.dart` (`FiscalPaymentSplit.of`), `keyboard_of_payment_page.dart`,
  `shift_singleton_4.dart`, `printing_api_helper.dart`, `left.dart`, `check_view_bottom.dart`,
  `products_ws_service.dart` (Apps yoqish/o'chirish)
- Scope dan tashqari: vozvrat (hammasi naqd — o'zgarmagan), hisobotda alohida qator

## Bajarilgan
- [x] MD 4.1–4.7, 4.9, 4.10 qo'llandi
  → MD dan farqlar (InVan 2 kodi boshqacha):
    - 4.7 fiskal: `saleOnOFD` dagi sikl emas — `FiscalPaymentSplit.of` (`receipt_vat.dart`), karta shoxidan keyin
      aniq shox (`YAGONAQR` nomi yoki `yagonaQrId`). Qog'oz chek QQS'i ham shu qoidadan.
    - 4.8 (`_lineKind`) — InVan'da yo'q, o'tkazildi (MD ruxsat bergan).
    - 4.9 `updateTheShift` — InVan'da ham ishlatilmaydi (izohda), faqat qayta hisoblash `case 'yagonaqr'`.
    - 4.3 `uzumQrId`/`paymeQrId` InVan'da yo'q — `advanceId` yonida.
    - check_view_bottom: `debtId` shoxi yo'q — `paymeId` shoxidan keyin.
- [x] QO'SHIMCHA (MD da yo'q): `OrganizationSingleton._restoreYagonaQrId` — `setOtherPayments` (ishga
  tushishda, main.dart:177) Pref bo'sh, qutida YagonaQr bo'lsa id'ni tiklaydi
  → Sabab: Shorebird patch'dan oldin "Ma'lumotlarni yangilash" qilingan kassada tur qutida bor, id esa yo'q
    edi → tugma xom nom bilan, cardType 0 bo'lardi. Endi qayta yangilash shart emas.
- [x] `OrderingProvider4.lastCardType` (`@visibleForTesting`) — cardType 2 ni test qilish uchun
- [x] Foydalanuvchi talabi (2026-10-20): admin "Apps" da o'chirilgan YagonaQr tugmasi chiqmasin
  → `keyboard_of_payment_page.dart` — `p.isAdded != true` → yashirin (null ham)
  → `ProductsWsService.applyPaymentToggle` (type 40 holat qismi `_paymentToggle` dan ajratildi, @visibleForTesting):
    YagonaQr nomida `yagonaQrId` yoziladi; qutida tur avval id, keyin nom bo'yicha topiladi (review topilmasi:
    WS nomi qutidagidan farq qilsa o'chirilgan tugma qolib ketardi)
- [x] Review topilmasi: `typeYagonaQr` cardType 2 ni faqat summa haqiqatan yozilganda qo'yadi
- [x] Testlar: `test/yagonaqr_payment_test.dart` (72), `test/yagonaqr_payment_button_test.dart` (9 widget),
  `test/yagonaqr_shift_report_test.dart` (3, ObjectBox kerak — bo'lmasa skip)

- [x] Commit `dd624bf`, port-changelog 15-task, `ayyubxon` ga merge, reliz 1.1.2+130 (GitHub Release)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Admin paneldagi YagonaQr `name` ni tasdiqlash: nomda bo'sh joy/`_`/`-` siz "yagonaqr" bo'lishi kerak
  (`YagonaQr.isName`, lib/changes/domain/payment/yagona_qr.dart:20). `name: 'CARD'` bo'lsa — karta id'sini
  egallaydi (backend'da o'zgartirish kerak).
- [ ] Jonli sinov (dev kassa): "Ma'lumotlarni yangilash" → tugma → naqd + YagonaQr → adminkada to'lov,
  fiskal chekda karta, X hisobotda Plastik
- [ ] Backendga yuklash (`/upload/build`) — foydalanuvchi GitHub Release'dan sinab bo'lgach
- [ ] Eski `../pos-invan-2-yagonaqr` (feat/yagona-qr) ni yopish — foydalanuvchi qarori

## Qabul qilingan qarorlar
- Nom: harf katta-kichikligi va harfdan boshqa belgilar e'tiborsiz (`[^a-z]` olib tashlanadi) — foydalanuvchi:
  "har xil yaratilishi mumkin, muhimi bitta bo'ladi" (2026-10-20). MD dagi `[\s_\-]` dan kengroq.
- Tugma faqat serverdan kelgan va `is_added == true` bo'lsa; umuman kelmasa yoki false/null — UI'da yo'q
  (foydalanuvchi qarori 2026-10-20).
- MD (Odoo varianti) asos — foydalanuvchi so'rovi; ikki fork bir xil mantiqda qoladi.
- `_lastCardType = 2` oxirgi bosilgan bo'yicha (MD) — Uzcard (`card_type` 1) + YagonaQr aralashida 2 bo'ladi.

## Ochiq savollar
- Admin paneldagi aniq `name`? — foydalanuvchi
- Odoo forkiga: kerak emas — Odoo'dan kelgan; `_restoreYagonaQrId` ixtiyoriy.

## Test / Verifikatsiya
- To'liq to'plam: 2003 o'tdi, 7 skip (4 eski + 3 smena testi ObjectBox'siz). ObjectBox dylib bilan smena testi 3/3.
- `flutter analyze` — yangi ogohlantirish yo'q (o'zgargan fayllarda 38 issue, bazada ham 38).
- Jonli (UI + adminka + fiskal modul) sinov qilinmagan.
