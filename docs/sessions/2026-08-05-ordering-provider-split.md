# Task: OrderingProvider4 ni bosqichma-bosqich ajratish

**Boshlangan:** 2026-08-05
**Holat:** in-progress
**Branch:** refactor/ordering-split (ayyubxon'dan)

## Maqsad

`lib/changes/providers/ordering_provider_4.dart` (5868 qator, 108 metod, 94 maydon, 6 xil mas'uliyat) ni **xatti-harakatni umuman o'zgartirmasdan** kichikroq, testlanadigan bo'laklarga ajratish. So'nggi 3 oyda shu faylga 30 commit tushgan — har o'zgarish boshqa narsani sindirish riskini olib keladi.

Bu bosqichda faqat **eng xavfsiz zonalar** qamraladi. Savat, diskont va to'lov ijrosi mantiqiga **tegilmaydi**.

## Scope

**Ta'sirlanadi:**
- `test/` — yangi umumiy harness + keng qamrovli xarakteristik testlar (Faza 0)
- `lib/changes/domain/marking/`, `lib/changes/domain/terminal/` — yangi sof funksiyalar (Faza 1)
- `lib/changes/providers/ordering/` — yangi kontrollerlar (Faza 2-3)
- `lib/changes/providers/ordering_provider_4.dart` — fasadga aylanadi (delegatsiya)

**Scope'dan tashqari:**
- `lib/features/` — bitta ham UI fayli o'zgarmaydi (fasad qoidasi)
- `pressPaymentButton`, `pressPaymentButtonOnlyOFD`, `type*` to'lov metodlari
- Diskont mantiqi (Faza 4), markirovka/blok (Faza 5) — alohida rejada
- Hech qanday bug tuzatilmaydi (4-qoida)

## Xavfsizlik qoidalari (buzilmaydi)

1. **Fasad:** `OrderingProvider4` nomi va barcha public a'zolari o'zgarmaydi. 46 UI fayli / 166 chaqiruvga tegilmaydi.
2. **notifyListeners:** ajratilgan bo'laklar `ChangeNotifier` EMAS — konstruktorda `void Function() notify` oladi. Aks holda UI jimgina qayta chizilmay qoladi.
3. **Bitta commitda bitta narsa:** ko'chirish va mantiq o'zgartirish hech qachon birga emas.
4. **Bug topilsa tuzatilmaydi** — qayd etiladi, xatti-harakat test bilan muzlatiladi.
5. **Har faza — alohida MR**, do'kon sinovidan keyin keyingisi.

## Bajarilgan

- [x] Chuqur tahlil: zonalar, bog'liqliklar, testlanish qobiliyati aniqlandi
  → Natija: 108 metoddan 89 tasi `BuildContext` talab qilmaydi
  → Sabab: ko'chirish chegaralarini dalilga asoslab tanlash uchun

- [x] Bazaviy holat o'lchandi: 85 ta haqiqiy test o'tadi, 1 tasi yiqiladi
  → Yiqilayotgani: `test/widget_test.dart` — Flutter shabloni ("Counter increments smoke test"), loyihaga aloqasi yo'q
  → `flutter analyze`: 1018 issue (0 error, 158 warning)

- [x] Branch ochildi: `refactor/ordering-split`

- [x] **0.1 — Yashil bazaviy holat**
  → `test/widget_test.dart` o'chirildi
  → Sabab: Flutter shabloni edi, `pumpWidget` ham izohga olingan — hech narsani
    tekshirmasdan yiqilardi. 85/85 yashil bo'ldi.

- [x] **0.2 — Umumiy test harness**
  → `test/support/provider_harness.dart` (yangi)
  → 4 ta testdagi takrorlangan Hive setup bitta joyga yig'ildi
  → `makeSoldItem()` — yangi testlar uchun umumiy qator yasovchi
  → Adapterlar guard bilan (`Hive.isAdapterRegistered`) ro'yxatdan o'tadi

- [x] **0.3 — Xarakteristik testlar (+87 ta yangi test)**
  → `test/payment_tally_test.dart` (19) — Faza 3 nishoni
  → `test/catalog_navigation_test.dart` (12) — Faza 2 nishoni
  → `test/terminal_receipt_test.dart` (20) — Faza 1 nishoni
  → `test/discount_apply_test.dart` (14) — diskont matematikasi
  → `test/cart_basic_test.dart` (12) — savat asoslari
  → `test/multi_client_test.dart` (10) — 6-slot rejimi va orphan yozuvlar
  → Sabab: ko'chirishdan OLDIN hozirgi xatti-harakat muzlatilishi shart;
    aks holda ko'chirish to'g'riligini isbotlab bo'lmaydi

**Faza 0 natijasi:** 85 → **172 test**, hammasi yashil. `lib/` ga bitta ham
o'zgarish kiritilmagan. `flutter analyze`: 1018 → 1017 (widget_test'ning
`unused_import` ogohlantirishi yo'qoldi).

- [x] **FAZA 1 — sof funksiyalar `lib/changes/domain/` ga chiqarildi**
  → `domain/terminal/terminal_receipt_parser.dart` — `parseTerminalReceipt`,
    `terminalErrorMessage`
  → `domain/marking/mark_cleaner.dart` — `scanTime` (eski `_markirovka`),
    `forFiscal` (eski `cleanMarkForFiscal`)
  → `domain/marking/mxik_rules.dart` — MXIK/markirovka qoidalari (6 funksiya)
  → `domain/marking/gs1.dart` — `parseDate`
  → Providerda bir qatorli delegatsiya qoldi; `cleanMarkForFiscal` imzosi
    aynan saqlandi (test uni to'g'ridan-to'g'ri chaqiradi)
  → `_getProductType` delegatsiyasi olib tashlandi — yagona chaqiruvchisi
    `_resolveProductType` edi, u endi bevosita MxikRules ga boradi
  → Yangi testlar: `mxik_rules_test` (24), `gs1_test` (13),
    `mark_cleaner_scan_test` (12) — bular ilgari `private` bo'lgani uchun
    umuman testlab bo'lmasdi; ajratishning bevosita foydasi shu

**Faza 1 natijasi:** `ordering_provider_4.dart` 5868 → **5660 qator**
(208 qator ko'chdi). Testlar 172 → **221**, hammasi yashil.
`flutter analyze` 1017 → **1012**. `lib/features/` ga tegilmagan (fasad
qoidasi isboti).

**Bitta ataylab qilingan chetlanish (3-qoida):** `parseTerminalReceipt` dagi
`cardType` uchun `if/else if` qavssiz shaklda edi — ko'chirishda qavsga
olindi (`curly_braces_in_flow_control_structures` lintini yopadi).
Xatti-harakat bir xil, HUMO/UZCARD/VISA va ustunlik tartibi testlar bilan
qoplangan.

- [x] **FAZA 2 — kategoriya navigatsiyasi kontrollerga chiqarildi**
  → `lib/changes/providers/ordering/catalog_navigation_controller.dart`
  → Ko'chdi: `_items`, `_pathList` maydonlari; `getItems`, `getPathList`,
    `pressCategory`, `pressSubCategory`, `pressPath`, `pressAllPath`,
    `clearPathList`, `changeGridviewItems`, `_collectItemsByCategory`,
    `_collectItemsBySubCategory`
  → Fasadda qoldi: `pressProduct` — u `addProduct` ni chaqiradi, ya'ni savat
    mantiqiga tegishli ko'prik
  → **2-qoida amalda:** kontroller `ChangeNotifier` EMAS, konstruktorda
    `notifyListeners` ni callback sifatida oladi
    (`CatalogNavigationController(notifyListeners)`)
  → Yangi testlar: `notifyListeners` ulanishini tekshiruvchi 4 ta test —
    aynan shu zonaning asosiy xavfi (holat o'zgaradi-yu ekran qayta
    chizilmaydi) endi test bilan qoplangan

**Faza 2 natijasi:** 5660 → **5557 qator** (103 qator ko'chdi).
Testlar 221 → **225**. `flutter analyze` 1012 (o'zgarmadi).
`lib/features/` ga tegilmagan.

## Keyingi qadamlar (prioritet bo'yicha)

- [ ] Faza 3 — to'lov arifmetikasi → `PaymentTallyController`
      Ko'chadi: `_checkButtonIsEnable`, `getAvailableSumma`,
      `getSelectedPaymentSumma`, `_payByAll`, `allPaymentType`,
      `removeFromPaymentList` + `paymentsMap`, `_mustPay`, `_sdachaa`,
      `_isButtonEnabled`, `_selectedPaymentType`, `_zdachaToCashBack`
      Tegilmaydi: `pressPaymentButton`, `pressPaymentButtonOnlyOFD`, `type*`
      Himoya: `test/payment_tally_test.dart` (19 test)

## Qabul qilingan qarorlar

- **Fasad naqshi (ChangeNotifier o'rniga notify callback)** — UI ga umuman tegmaslik va jimgina rebuild yo'qolishining oldini olish uchun
- **Test avval, ko'chirish keyin** — production POS kodida ko'chirish to'g'riligini boshqa yo'l bilan isbotlab bo'lmaydi
- **Keng qamrovli test to'plami** (minimal harness emas) — testlar kundalik bug-fix ishlarini ham himoya qiladi
- **Faza 0-3 bilan cheklanish** — savat/diskont/to'lov mantiqiga tegmaslik; asosiy foyda Faza 4-5 da, lekin ular poydevor tayyor bo'lgandan keyin

## Ochiq savollar

- **Sof funksiyalarning aksariyati `private`** (`_isMxikMarking`,
  `_getProductType`, `_parseGS1Date`, `_markirovka`) — ularni bugun
  to'g'ridan-to'g'ri testlab bo'lmaydi. Faza 1 da sinfdan chiqarilgach public
  bo'ladi va o'sha zahoti test yoziladi. Ko'chirishning to'g'riligi esa
  diff'ni ko'zdan kechirish bilan tasdiqlanadi (tana bayt-ma-bayt bir xil).

- **`addProduct` `BuildContext` talab qiladi** → savat testlari mahsulotni
  to'g'ridan-to'g'ri `orderedProducts` ga qo'shadi. Bu mavjud testlardagi
  naqsh, o'zgartirilmadi.

## Qayd etilgan xatti-harakatlar (4-qoida — tuzatilmadi)

- `DiscountHelpers._productPercentage` / `_productNumeric`: `singleDiscount`
  faqat `product.value == 1` bo'lganda to'ldiriladi. `value > 1` da narx
  tushadi, lekin `singleDiscount` 0 qoladi
  (`test/discount_apply_test.dart` — "Miqdor (value) ta'siri").
  Bu hozirgi xatti-harakat sifatida muzlatildi; to'g'ri yoki noto'g'ri ekani
  alohida ko'rib chiqilishi kerak.

- `ShiftSingleton4._removeUploadedShiftReceipts({from, to})`: `from` va `to`
  parametrlari tanada UMUMAN ishlatilmaydi — metod barcha `uploaded == true`
  cheklarni o'chiradi. Chaqiruvda ham `to: DateTime.now().millisecond`
  (millisekund, `millisecondsSinceEpoch` emas). Bu task doirasidan tashqari,
  lekin qayd etib qo'yildi.

## Test / Verifikatsiya

Har faza uchun:
1. `flutter test` — barcha testlar yashil
2. `flutter analyze` — issue soni oshmasin (bazaviy: 1018)
3. `git diff --stat` da `lib/features/` o'zgarmagan (fasad qoidasi isboti)
4. Windows build + do'kon smoke testi: naqd/karta/aralash to'lov, sdacha, diskont, markirovka, blok, qaytarish, smena, chek, kategoriya navigatsiyasi
