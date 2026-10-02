# Task: Click Pass / Payme Go — fiskalda ReceivedCard, QQS to'liq

**Boshlangan:** 2026-09-30
**Holat:** in-progress (relizda — 1.1.2+129, PRO, 2026-10-02, commit `f007377` + `e5ba429`; qurilmada haqiqiy Click Pass / Payme Go + fiskal sinovi kutilmoqda)
**Branch:** `f007377` (fix/is-marking-false-sinxron → ayyubxon, 2026-10-01); ePay ID davomi — fix/smena-navbat-fifo → ayyubxon (2026-10-02)

## Maqsad
RPC (fiskal modul) talabi: Click Pass va Payme Go orqali to'lov `Other` da emas, `ReceivedCard` da
ketishi, QQS 0 emas, to'liq bo'lishi kerak. Click QR / Payme QR (qo'lda belgilanadigan) — o'zgarishsiz
`Other`, QQS 0. Yo'l-yo'lakay: QR to'lovda ham fiskal chek URL'i Click/Payme/Uzum API'siga yuborilardi.

## Scope
- `lib/changes/domain/receipt/receipt_vat.dart` — `FiscalPaymentSplit` tasnifi
- `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart` — `saleOnOFD` `received*` bayroqlari
- Scope dan tashqari: `PaymentType` maydoni (foydalanuvchi: "qo'yib tur"), Uzum Pass tasnifi, vozvrat, `has_click/has_payme` (serverga ketadigan maydon)

## Bajarilgan
- [x] Click Pass / Payme Go → `card` (ReceivedCard); Click/Payme QR va Uzum → `epay` (Other)
  → lib/changes/domain/receipt/receipt_vat.dart (`FiscalPaymentSplit.of`, `isQr`)
  → Sabab: QR = payId '@id' (type 1) yoki nomida 'QR' (serverdan qaytgan chekda '@' yo'q bo'lishi mumkin)
- [x] `receivedClick/Payme/Uzum` faqat Pass/Go bo'lganda true (`FiscalPaymentSplit.hasPass`)
  → receipt_singleton_4.dart `saleOnOFD` params
  → Sabab: QR'da provayder to'lov ID'si yo'q; `UzumService.paymentId` / `ClickService.paymentId` oldingi to'lovdan qolgan bo'lsa, boshqa to'lovga fiskal URL ketardi. `receipt.hasClick` o'zgartirilmadi — serverga `has_click` bo'lib ketadi.
- [x] Testlar: test/receipt_vat_test.dart (30 ta), to'liq suite 1397 ✅, analyze toza

- [x] Keng qamrovli matritsa testi (2026-10-02): 124 test — haqiqiy
  `ReceiptPayments.build` → `saleOnOFD` → modul JSON; 11 to'lov turi × 5 savat
  (12%/0%, chegirma, tarozi yarim so'm, katta summa), 55 juft aralash, sdacha,
  vozvrat, server QR (@ siz), idempotentlik. Mutatsiya: Pass→Other qaytarilsa
  36 test, hasPass QR'ni o'tkazsa 41 test yiqiladi. To'liq suite 1576 ✅
  → test/epay_fiscal_matrix_test.dart

- [x] TUZATISH (2026-10-02, foydalanuvchi qarori: to'liq reliz bilan —
  ObjectBox sxemasi o'zgaradi): elektron to'lov ID'lari CHEKNING O'ZIDA
  - `ReceiptModel4.epayJson` (ObjectBox property 51) + `ReceiptEpay`
    → lib/changes/domain/receipt/receipt_epay.dart (capture/encode/targets)
  - `EpayCapture.forReceipt` chek yig'ilganda (pressPaymentButton,
    pressPaymentButtonOnlyOFD), `EpayCapture.reset` to'lov sahifasi
    ochilganda (initPaymentPageValues)
    → lib/changes/services/payment/epay_capture.dart
  - `saleOnOFD` ExtraInfo chekdan (Pref `epay_*` emas); vozvratda bo'sh
  - `LocalService.sell` provayderga faqat chekdagi ID bilan
    (`ReceiptEpay.targets`); ID yo'q (eski chek) → yuborilmaydi;
    `fromReceipt4ToClick(clickPaymentId:)`, `setFiscalData2(paymeReceiptId:)`
  - nusxalar: `ReceiptApi4.func`, `PreOfdBloc.receiptForResend` (ajratildi)
  - `LocalService.extraInfoFromBody` (ajratildi, tana o'zgarmagan)
  → Sabab: ClickService.post `submit_qrcode` javobida Pref'ni tozalashdan
    keyin qayta yozardi (epayPay_Id=64 qolardi → naqd chekka ham); fiskal
    yiqilsa Pref tozalanmasdi; PreOfd xotiradagi oxirgi ID bilan yuborardi
- [x] Testlar: test/receipt_epay_test.dart (36) + matritsa (124), fixture'lar
  test/support/epay_fixtures.dart. Mutatsiya: 9 ta buzilishning hammasi
  ushlandi

## Keyingi qadamlar (prioritet bo'yicha)
- [x] 2026-10-01: commit (f007377) va `ayyubxon`'ga birlashtirildi, GitLab + GitHub main'ga push; Odoo forkiga ham ko'chirildi
- [ ] O'zgarishlarni alohida branchga (masalan `fix/click-pass-payme-go-received-card`) ko'chirib commit
- [ ] docs/port-changelog.md ga bo'lim (commitdan keyin)
- [ ] Do'kon sinovi: Click Pass va Payme Go chekida fiskal JSON `ReceivedCard` = summa, `Other` = 0, `VAT` > 0; QR chekida eskidek
- [ ] (keyin) `PaymentType` qo'shish masalasi

## Qabul qilingan qarorlar
- QR aniqlash: '@' prefiks YOKI nomda 'QR' — ikkala manbadan kelgan chekni qamraydi
- Qog'oz chek QQS'i o'zgartirilmadi — Click/Payme'ni allaqachon to'liq ko'rsatardi, endi Pass/Go uchun fiskal bilan mos

## Ochiq savollar
- TOPILDI (f007377 dan OLDIN ham bor, regressiya emas): (1) ExtraInfo
  (`epay_Id`/`epayPay_Id`/`epay_phone`) global Pref'dan, faqat fiskal
  MUVAFFAQIYATLI bo'lganda tozalanadi → Pass sotuvida fiskal yiqilsa keyingi
  (hatto naqd) chekka eski QRPaymentID ketadi (receipt_singleton_4.dart:381,
  local_selling_service.dart:163). (2) PreOfd qayta yuborish (preofd_bloc.dart:82)
  Pass chekida provayderga `ClickService.paymentId` / Pref `p_id` — chekniki
  emas, xotiradagi oxirgi to'lov ID'si bilan ketadi. → TUZATILDI 2026-10-02 (yuqorida).
- "Yana nimadur ketadi" — ehtimol `PaymentType` (3 = QR). `ExtraInfo.QRPaymentProvider/QRPaymentID/PhoneNumber` Pass/Go uchun allaqachon ketyapti.

## Rasmiy manbalar tahlili (2026-09-30)
- ГНК: chek bitta, do'kon kassasidan; to'lov ilovasi to'lovi beznal hisoblanadi; chek xaridorga o'sha ilovada ko'rinishi kerak → do'kon fiskal chek ma'lumotini provayderga qaytaradi.
  - Click: `POST /payment/ofd_data/submit_qrcode` (service_id, payment_id, qrcode) — bizda bor (click_service.dart:188)
  - Payme: `receipts.set_fiscal_data` (receipt_id, qr_code_url majburiy) — bizda bor (payme_service.dart setFiscalData2)
- Fiscal Drive: `ExtraInfo.QRPaymentID` + `QRPaymentProvider` (misolda 18), `PhoneNumber` — bizda Pass/Go uchun ketadi (64/141). Rasmiy provayder kodlari ro'yxati ochiq manbada TOPILMADI — OFD/modul vendoridan so'rash kerak.
- `PaymentType`: kodda HECH QACHON bo'lmagan (git tarixida ham yo'q), kommentda emas, bo'sh ham ketmaydi — `FiscalReceipt.toJson` da kalit yo'q. Spetsifikatsiyada majburiyligi yozilmagan.

## Test / Verifikatsiya
- flutter test test/receipt_vat_test.dart — 30/30
- flutter test — 1397 ✅
