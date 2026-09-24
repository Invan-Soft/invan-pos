# Task: Fiskal chekda QQS bazasi chegirmadan keyingi summa bo'lishi (Price − Discount − Other)

**Boshlangan:** 2026-09-24
**Holat:** in-progress
**Branch:** fix/fiskal-qqs-chegirma-bazasi

## Maqsad
Chegirmali tovarda fiskal modulga (soliqqa) QQS chegirmaSIZ narxdan ketardi: 50 000 so'mlik tovar
30 000 chegirma bilan 20 000 ga sotilsa, `VAT` 50 000 dan (5 357 so'm) hisoblanardi, to'g'risi
20 000 dan (2 143 so'm). Qog'oz chek va ekran esa 2 143 ko'rsatardi — fiskal va chek mos emas edi.
Cashback bilan to'langan qism (`Other`) fiskalda allaqachon bazadan chiqarilgan edi, u shunday qoladi.
Ikkinchi qism (foydalanuvchi so'rovi): 100% cashback chekida fiskalga VAT 0 ketsa ham qog'oz chek
"sh.j QQS" ni 12% ko'rsatardi — chek ham fiskal bilan bir qoidadan hisoblansin.

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
- `lib/changes/domain/receipt/receipt_vat.dart` — yangi: `FiscalPaymentSplit` (to'lov tasnifi) va
  `ReceiptVat` (qator/chek QQS'i, cashback ulushi) — fiskal va qog'oz chek uchun bitta manba
- `lib/features/printing/api/components/sold_api_components.dart` — "sh.j QQS" (qator) va
  "shu jumladan QQS" (jami) `ReceiptVat` dan; `lib/features/printing/api/print_sold_api.dart` — receipt uzatiladi
- `test/receipt_vat_test.dart` — yangi
- Scope dan tashqari: Click/Payme/Uzum `Other` orqali ketishi; to'lovdan OLDINGI chop (payment page,
  ruscha "В том числе НДС") va bosh ekrandagi jami QQS (to'lov hali yo'q — cashback noma'lum);
  serverga ketadigan `order_pos` qator `vat` maydoni (pastda "Ochiq savollar")

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
- [x] `test/fiscal_vat_base_test.dart` — 16 ta test: foydalanuvchi misoli (50 000/30 000 → 214 285 tiyin),
      rasmiy misol (→ 5357), chegirmasiz regressiya, qty > 1, 100% chegirma, QQS 0%, vozvrat, ko'p qator;
      cashback 100% / qisman / chegirma bilan / ko'p qatorga taqsimot; `_enforce1021Balance` uchala yo'li
- [x] `test/fiscal_vat_discount_types_test.dart` — 28 ta test, HAQIQIY diskont mexanizmi orqali
      (SoldItemBuilder → DiscountSingleton.addDiscountOnProduct → findFreeProducts/useFreeProducts/
      useFreeGiftProducts/useBuyXGetXProducts → setNewClientDiscountPercentage → ReceiptBuilder.build →
      saleOnOFD → modul JSON): mahsulot foiz/summa, kategoriya, kategoriya+mahsulot zanjiri, mijoz guruhi,
      QQS 0% tovar, 100%; Buy X Get X 3+1, 1+1 takrorlanuvchi (6 va 5 dona), markirovkali 4 KM, shart
      bajarilmagan; Buy X Get Y (to'liq va yarim tekin); Free Gift; tepa foiz (yakka va mahsulot % ustiga);
      utsenka QR, dialogda narx override, dialogda chegirma; tarozi 0.29 kg + 10%, blok 12 dona + 10+2;
      chegirma+cashback, 3+1 + 100% cashback, sovg'a + cashback, red-delete, 6 qatorli aralash chek.
      Har holatda har qatorda: Price/Discount/Amount/VATPercent savat bilan mos, VAT net formuladan,
      chegirmali qatorda VAT < chegirmasiz formula, §10.2.1 balans.
    → Sabab: foydalanuvchi talabi — "diskont turlari ko'p (1+1, 1+3 ...), hammasida QQS muammosiz ishlashi kerak";
      Mac'da fiskal modul yo'q, shuning uchun modulga ketadigan JSON'ning o'zi tekshiriladi

- [x] `ReceiptVat` / `FiscalPaymentSplit` — to'lov tasnifi (naqd/karta/cashback/Click-Payme-Uzum) va
      qatorga tushadigan cashback ulushi bitta domain sinfida; `saleOnOFD` shu tasnifdan foydalanadi
      (`receivedCash/Card` endi butun tiyinga yaxlitlanadi — `.toInt()` kesishida 1 tiyin yo'qolmasin),
      `_countOtherOFD` → `ReceiptVat.otherShare × 100`
    → lib/changes/domain/receipt/receipt_vat.dart; receipt_singleton_4.dart (`saleOnOFD`, `_countOtherOFD`)
    → Sabab: chek va fiskal ikki joyda alohida hisoblanardi va farq qilardi; endi bitta qoida
- [x] Qog'oz chek: qator "sh.j QQS" = (narx × miqdor − cashback ulushi) × p/(100+p); jami "shu jumladan QQS"
      = `ReceiptVat.total`. Blok/dona bo'lib chizilganda ulush qism miqdoriga mos. 100% cashback → 0.
    → sold_api_components.dart `buildProductList` (`receipt:` parametri), `buildProduct` (`otherShare`),
      `buildBottom`; print_sold_api.dart (57 va 80 mm) `receipt: receiptsCreateGroup`
    → Qaror: chekda FAQAT cashback ayriladi. Click/Payme/Uzum fiskalda hozircha Other (VAT 0), lekin
      rasmiy talab karta (QQS to'liq) — chek shu to'g'ri holatni ko'rsatadi, fiskal tuzatilganda mos keladi.
      Foydalanuvchi: Click/Payme hozircha tegilmasin.
- [x] `test/receipt_vat_test.dart` — 23 ta test: tasnif fiskal body bilan aynan bir xil (nom/ID/fallback/
      vozvrat/aralash), chek jami QQS = fiskal ΣVAT (cashback 100%/qisman, chegirma, ko'p qator, QQS 0%,
      vozvrat, tarozi kasr), qator raqamlari, blok/dona yig'indisi, Click farqi QAYD

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Do'kon sinovi (Windows, haqiqiy fiskal modul): chegirmali tovar sotib, ofd.soliq.uz chekida
      QQS chegirmadan keyingi narxdan ekanini tekshirish; chegirma + cashback aralash chek; vozvrat;
      100% cashback chekini chop etib "sh.j QQS" 0 ekanini ko'rish
- [ ] Keyingi relizga kiritish (release pipeline)

## Qabul qilingan qarorlar
- QQS bazasi `Price − Discount − Other` — rasmiy FiscalDriveService misoli (Price 100000, Discount 50000
  → VAT 5357) va Soliq kodeksi (baza = tomonlar qo'llagan narx). Cashback `Other`da qoladi (xaridordan
  olinmagan pul, "прочие"), u ham bazadan chiqadi — foydalanuvchi talabi.
- VAT yaxlitlash o'zgartirilmadi (kasr `.toInt()` bilan kesiladi, avvalgidek) — bu bug'ga aloqasi yo'q,
  rasmiy misolda ham 5357.14 → 5357.

## Ochiq savollar
- **Diskont mexanizmi xatosi (QQS'ga aloqasi yo'q, bu branch'da tuzatilmadi):** bir mahsulot bir nechta
  qatorda bo'lsa (markirovka: har KM value=1, yoki bir nechta blok), takrorlanuvchi Buy X Get X faqat
  `get` dona tekin beradi, har set uchun emas. Sabab: `getBuyXGetXDiscountsOnly` doim
  `_getBuyXGetXAsGift(..., forDialogOnly: true)` chaqiradi (lib/changes/singletons/discounts/discount_helpers.dart:192-193),
  shunda `ReturnedGiftX.getProductAmount` = xom "get" (1), hisoblangan `floor(totalQty/(buy+get))×get` emas;
  `useBuyXGetXProducts` ning ko'p qatorli yo'li aynan shu sonni ishlatadi
  (lib/changes/providers/ordering/discount_effects_controller.dart, `freeQtyLeft = gift.getProductAmount`).
  Bitta qatorda 4 dona → 2 tekin (to'g'ri); 4 ta KM qator → 1 tekin. Test: fiscal_vat_discount_types_test.dart
  "QAYD: 1+1 markirovkali". Alohida task ochilsin.
- Click/Payme/Uzum `Other` orqali ketadi (QQS 0) — rasmiy talab `ReceivedCard` + `QRPayment*`.
  Alohida task: docs/fiskal-tolov-turlari-va-qqs.md §6.1
- Qog'oz sotuv cheki endi fiskal bilan mos (cashback ham). Hali tegilmagan joylar:
  (a) to'lovdan OLDINGI chop — payment page ruscha "В том числе НДС" (print_payment_page_api.dart:637) va
  bosh ekrandagi jami QQS (items_singleton.dart `getNDS`) — bu paytda to'lov/cashback hali yo'q, chegirmadan
  keyingi narxdan ko'rsatadi; (b) serverga ketadigan `order_pos` qator `vat` maydoni (receipt_model_4.dart
  `"vat": vat`) — `SoldItemBuilder` da chegirmasiz narxdan yoziladi va avto-chegirma qo'llanganda
  YANGILANMAYDI (faqat tier reprice / qo'lda tahrirda), cashback ham hisobga olinmaydi. Backend hisobotlari
  shu maydonga tayansa noto'g'ri; backend bilan kelishib alohida tuzatish kerak.

## Test / Verifikatsiya
- `flutter test test/fiscal_vat_base_test.dart` — 16/16 o'tdi (2026-09-24)
- `flutter test test/fiscal_vat_discount_types_test.dart` — 28/28 o'tdi (2026-09-24)
- `flutter test test/receipt_vat_test.dart` — 23/23 o'tdi (2026-09-24)
- `flutter test` to'liq to'plam — 1212/1212 o'tdi, regressiya yo'q (2026-09-24)
- `dart analyze` o'zgargan fayllarda: yangi xato yo'q. receipt_singleton_4.dart dagi 3 ta eski
  warning (:265 dead_null_aware, :310 unused `itemsLen`, :299 print) tegilmadi — bu fix'ga aloqasi yo'q
- Do'kon sinovi (haqiqiy fiskal modul) hali qilinmadi — "Keyingi qadamlar"
