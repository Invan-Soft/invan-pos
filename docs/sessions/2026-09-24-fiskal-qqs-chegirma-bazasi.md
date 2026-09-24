# Task: Fiskal chekda QQS bazasi chegirmadan keyingi summa bo'lishi (Price − Discount − Other)

**Boshlangan:** 2026-09-24
**Holat:** in-progress
**Branch:** fix/fiskal-qqs-chegirma-bazasi

## Maqsad
Chegirmali tovarda fiskal modulga (soliqqa) QQS chegirmaSIZ narxdan ketardi: 50 000 so'mlik tovar
30 000 chegirma bilan 20 000 ga sotilsa, `VAT` 50 000 dan (5 357 so'm) hisoblanardi, to'g'risi
20 000 dan (2 143 so'm). Qog'oz chek va ekran esa 2 143 ko'rsatardi — fiskal va chek mos emas edi.
Cashback bilan to'langan qism (`Other`) allaqachon bazadan chiqarilgan edi, u shunday qoladi.

## Avvalgi implementatsiya
docs/sessions/archive/2026-06-24-ofd-1021-electronic-payment-rounding.md (Yakunlangan 2026-09-07)
↑ U yerda `_countVat = (price − other) × p/(100+p)` "app formulasiga mos" deb qabul qilingan va
`_build1021Diag` shu formulaga moslangan edi. Sabab: 100% elektron to'lovda VAT=0 to'g'ri chiqishi.
Endi: chegirma ham bazadan ayriladi — `(price − discount − other)`. Rasmiy FiscalDriveService
misoli buni tasdiqlaydi: Price 100000, Discount 50000, VATPercent 12 → VAT 5357 = 50000 × 12/112.
`docs/fiscal-sale-integration.md:217` da "Price − Discount dan EMAS" deb yozilgan qoida noto'g'ri edi.

## Scope
- `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart`
  — `_countVat` va uning 4 chaqiruvi (item qurish + `_enforce1021Balance` 3 yo'li)
- `lib/fiscal_service/base_service.dart` — `_build1021Diag` kutilgan VAT formulasi (Telegram log)
- `docs/fiscal-sale-integration.md`, `docs/fiscal-sale-integration.ru.md` — VAT qoidasi
- `test/fiscal_vat_base_test.dart` — yangi
- Scope dan tashqari: Click/Payme/Uzum `Other` orqali ketishi; qog'oz chek/ekran/server `vat`
  maydonida cashback ulushi (pastda "Ochiq savollar")

## Tahlil (2026-09-24)
- Fiskal item: `Price = realPrice × qty` (chegirmasiz, `_countPrice`), `Discount = (realPrice − price) × qty`
  (`_countDiscountOFD`), `Other` = qatorga tushgan cashback ulushi (`_countOtherOFD`, chegirmali
  narx nisbatida → `Other ≤ Price − Discount`).
- Eski `VAT = (Price − Other) × p/(100+p)` — `Discount` yo'q. 2026-05-16 (b9caffb) dan beri shunday.
- Diskont qo'llanganda `price` kamayadi, `realPrice` asl narxda qoladi (discount_helpers.dart:73-105),
  shuning uchun barcha diskont turlari (foiz, summa, kategoriya, BuyXGetY, utsenka QR) shu yo'ldan o'tadi.
- Fiskal modul VAT summasini tekshirmaydi (faqat `Price − Discount − Other` balansini), shuning uchun
  chek rad etilmagan, lekin OFD'ga ortiqcha QQS ketgan.
- Yangi baza `Price − Discount − Other` = `_enforce1021Balance` dagi δ. 100% cashback → 0, 100% chegirma → 0.
- Barcha fiskal yo'llar (sotuv, vozvrat, INCOM/lokal) `saleOnOFD` orqali — bitta joy.

## Bajarilgan
- [x] `_countVat(price, nds, {discount, other})` → `(price − discount − other) × nds/(100+nds)`, manfiy → 0
    → receipt_singleton_4.dart `_countVat` (named required parametrlar — chaqiruvda unutib bo'lmaydi)
    → Sabab: rasmiy misol va Soliq kodeksi mantiqi (baza = qo'llangan narx, ya'ni chegirmadan keyingi)
- [x] 4 chaqiruv yangilandi: item qurish; per-item qirqish (`discount: d`); residual > 0 (Price kamaytirish);
      residual < 0 (Other kamaytirish) — ikkalasida `discount: discountOf(it)`
    → receipt_singleton_4.dart (`_enforce1021Balance`)
- [x] `_build1021Diag` kutilgan VAT: `(price − disc − other)` — aks holda har chegirmali qator
      Telegram logida "VAT mos emas" false positive berardi
    → lib/fiscal_service/base_service.dart
- [x] Hujjat qoidasi tuzatildi (uz + ru)
    → docs/fiscal-sale-integration.md:217, docs/fiscal-sale-integration.ru.md:217
- [x] `test/fiscal_vat_base_test.dart` — 18 ta test: foydalanuvchi misoli (50 000/30 000 → 214 285 tiyin),
      rasmiy misol (→ 5357), chegirmasiz regressiya, qty > 1, 100% chegirma, QQS 0%, vozvrat, ko'p qator;
      cashback 100% / qisman / chegirma bilan / ko'p qatorga taqsimot; `_enforce1021Balance` uchala yo'li

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Do'kon sinovi (Windows, haqiqiy fiskal modul): chegirmali tovar sotib, ofd.soliq.uz chekida
      QQS chegirmadan keyingi narxdan ekanini tekshirish; chegirma + cashback aralash chek; vozvrat
- [ ] Keyingi relizga kiritish (release pipeline)

## Qabul qilingan qarorlar
- QQS bazasi `Price − Discount − Other` — rasmiy FiscalDriveService misoli (Price 100000, Discount 50000
  → VAT 5357) va Soliq kodeksi (baza = tomonlar qo'llagan narx). Cashback `Other`da qoladi (xaridordan
  olinmagan pul, "прочие"), u ham bazadan chiqadi — foydalanuvchi talabi.
- VAT yaxlitlash o'zgartirilmadi (kasr `.toInt()` bilan kesiladi, avvalgidek) — bu bug'ga aloqasi yo'q,
  rasmiy misolda ham 5357.14 → 5357.

## Ochiq savollar
- Click/Payme/Uzum `Other` orqali ketadi (QQS 0) — rasmiy talab `ReceivedCard` + `QRPayment*`.
  Alohida task: docs/fiskal-tolov-turlari-va-qqs.md §6.1
- Qog'oz chek, ekran va server `order_pos.vat` cashback ulushini ayirmaydi (chegirmani ayiradi).
  Bu fix'dan keyin chegirma bo'yicha fiskal va chek mos; cashback bo'yicha hali farq bor:
  docs/fiskal-tolov-turlari-va-qqs.md §4.2

## Test / Verifikatsiya
- `flutter test test/fiscal_vat_base_test.dart` — 18/18 o'tdi (2026-09-24)
- `flutter test` to'liq to'plam — 1212/1212 o'tdi, regressiya yo'q (2026-09-24)
- `dart analyze` o'zgargan fayllarda: yangi xato yo'q. receipt_singleton_4.dart dagi 3 ta eski
  warning (:265 dead_null_aware, :310 unused `itemsLen`, :299 print) tegilmadi — bu fix'ga aloqasi yo'q
- Do'kon sinovi (haqiqiy fiskal modul) hali qilinmadi — "Keyingi qadamlar"
