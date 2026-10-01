# Task: Click Pass / Payme Go — fiskalda ReceivedCard, QQS to'liq

**Boshlangan:** 2026-09-30
**Holat:** in-progress
**Branch:** fix/is-marking-false-sinxron (working tree, commit qilinmagan — alohida branchga ko'chirish kerak)

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
