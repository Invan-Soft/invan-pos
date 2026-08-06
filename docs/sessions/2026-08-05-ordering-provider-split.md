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

- [x] **FAZA 3 — to'lov arifmetikasi kontrollerga chiqarildi**
  → `lib/changes/providers/ordering/payment_tally_controller.dart`
  → Ko'chdi (holat): `paymentsMap`, `selectedPaymentType`,
    `selectedPaymentIndex`, `totalPrice`, `mustPay`, `sdacha`,
    `zdachaToCashBack`, `isButtonEnabled`
  → Ko'chdi (metod): `checkButtonIsEnable`, `getAvailableSumma`,
    `getSelectedPaymentSumma`, `payByAll`, `removeFromPaymentList`,
    `selectPaymentIndex`, `changeTheSelectedPaymentIndex`
  → **Muhim yondashuv:** providerdagi maydonlar o'chirilmadi, balki
    **getter/setter juftligiga** aylantirildi
    (`double get _mustPay => _tally.mustPay;` va h.k.). Shu sababli sinf
    ichidagi ~100 murojaat va UI kodidagi `provider.paymentsMap` ning
    barchasi **o'zgarishsiz** ishlayveradi
  → `allPaymentType` fasadda qoldi va **tanasi umuman tegilmadi** — u
    `controller.text` (TextEditingController) bilan ishlaydi; ichidagi
    primitivlar delegatsiyaga aylangani uchun o'zi o'zgarishsiz ishlaydi
  → `_checkButtonIsEnable` delegatsiyasi olib tashlandi — uni faqat
    `_payByAll` va `removeFromPaymentList` chaqirardi, ikkalasi ham ko'chdi
  → Yangi testlar: `notifyListeners` ulanishi uchun 4 ta (+4)

**TEGILMADI (ataylab):** `pressPaymentButton`, `pressPaymentButtonOnlyOFD`,
`typeUzcard`/`typeHumo`/`typeClick`/`typePayme`/`typeUzum`/`typePaynet` —
tarmoq, fiskal modul va dialoglar bilan ishlaydi.

**Faza 3 natijasi:** 5557 → **5485 qator**. Testlar 225 → **229**.
`flutter analyze` 1012 (o'zgarmadi). `lib/features/` ga tegilmagan.

---

## FAZA 0-3 YAKUNIY NATIJA

| | Boshlanish | Yakun |
|---|---|---|
| `ordering_provider_4.dart` | 5868 | **5485** (−383) |
| Testlar | 85 (+1 yiqiladigan) | **229** |
| `flutter analyze` | 1018 | **1012** |
| `lib/features/` | — | **hech qachon tegilmagan** |

Yangi fayllar: `domain/marking/` (3), `domain/terminal/` (1),
`providers/ordering/` (2).

- [x] **FAZA 4 — diskont effektlari kontrollerga chiqarildi**

  **4.0 — avval test bo'shlig'i yopildi (+30 test)**
  → Boshlashda aniqlandi: ko'chadigan metodlar UMUMAN qoplanmagan edi.
    `discount_apply_test.dart` boshqa faylni (`discount_helpers.dart`)
    tekshirar ekan, providerni emas.
  → `discount_free_products_test.dart` (10) — Buy X Get Y
  → `discount_free_gift_test.dart` (10) — Free Gift
  → `discount_buy_x_get_x_test.dart` (10) — Buy X Get X

  **4.1 — ko'chirish**
  → `lib/changes/providers/ordering/discount_effects_controller.dart`
  → Holat (7 maydon): `showCount`, `showCountFreeGift`, `returnedProducts`,
    `returnedFreeGiftProducts`, `returnedBuyXGetX`, `giftProducts`,
    `freeGiftDialogCount` — providerda getter/setter fasad
  → Metodlar: `findFreeProducts`, `findFreeGiftProducts`,
    `findBuyXGetXProducts`, `useFreeProducts`, `useFreeGiftProducts`,
    `useBuyXGetXProducts`, `resetItemDiscount`, `addDiscountForReceipt`
  → Savat ro'yxati va mijoz guruhi **parametr** sifatida uzatiladi

  **FAZA 1-3 DAN FARQI:** bu kontroller savatga BOG'LIQ — u savat
  qatorlarini o'zgartiradi (narx, chegirma). Toza "mustaqil modul" emas,
  balki "savatga effekt qo'llovchi". Savat egaligi providerda qoladi.

  **TESTLAR BITTA REAL XATONI USHLADI:** ko'chirishda `_returnedProducts`
  → `returnedProducts` nomlash o'zgarishi metod ichidagi lokal ro'yxat
  (`returnedProducts`) bilan to'qnashdi — map o'rniga ro'yxat String bilan
  indekslandi (`type 'String' is not a subtype of type 'int'`). 8 ta test
  yiqildi, lokal o'zgaruvchi `found` deb qayta nomlandi. Testlarsiz bu xato
  do'konda, Buy X Get Y sotuvida chiqardi.

**Faza 4 natijasi:** 5485 → **5096 qator** (389 qator ko'chdi).
Testlar 229 → **259**. `flutter analyze` 1012 → **1011**.
`lib/features/` ga tegilmagan.

---

- [x] **Blok + diskont test bo'shlig'i yopildi** (+9 test, commit 581d247)
  → `test/discount_box_test.dart`
  → Bo'shliq: ko'chgan diskont kodida blok mantiqi 11 joyda, lekin diskont
    testlari dona hisobida, blok testlari esa diskontsiz edi
  → **QAYD:** aralash savatda (blok+dona) BuyXGetX `perSetSize = buy × 2`
    deb hisoblaydi, ya'ni `get == buy` deb faraz qiladi. `get != buy` da
    (masalan 10+2) blok qatoriga chegirma TEGMAYDI. Refaktoringdan oldin
    ham shunday edi (ayyubxon bilan bayt-ma-bayt solishtirildi)

- [x] **FAZA 5 — TAHLIL QILINDI, KO'CHIRILMADI**
  → Dastlabki baho "~1100 qator ko'chadi" edi — tahlil buni RAD ETDI:
    `_markingCheck` 417 qator / 59 UI nuqtasi (dialog orkestratori),
    guruh save/delete metodlari esa diskont oqimiga, `Pref` ga va savat
    holatiga ulanib ketgan (`findFreeProducts`, `_showCount` ...)
  → Ko'chirishga urinildi, yarim ishlaydigan kod qoldirmaslik uchun bekor
    qilindi. Faqat reprice/manual-narx klasteri (137 qator) toza edi

- [x] **FAZA 6.1 — chek yig'ish `ReceiptBuilder` ga** (commit 46d27a4)
  → `lib/changes/domain/receipt/receipt_builder.dart` — `build()`
  → **Chok kodning o'zida bor edi:** `pressPaymentButton` ikkita ish
    qilardi va chegara `if (receiptModel4.payment.isNotEmpty && ...)`
    qatorida — undan oldingisi sof yig'ish, keyingisi ObjectBox saqlash
  → **TOPILMA:** `pressPaymentButton(BuildContext context)` da `context`
    UMUMAN ishlatilmaydi, faqat imzoda turadi
  → +26 test (`test/receipt_builder_test.dart`) — ilgari bu kodni testlab
    bo'lmasdi (BuildContext + ObjectBox)
  → 5096 → 4950

- [x] **FAZA 6.2 — OFD cheki ham** `buildOnlyOfd()` (commit 73f6ca9)
  → `build` bilan ATAYLAB birlashtirilmadi. Farqlari: terminal maydonlari
    (cardType/cardNumber/pptId), `createdDate` UTC emas `now−5soat`,
    chegirma normalizatsiyasida `price == onlyPrice` sharti, `isDonate`
    Pref dan. Ikki pul yo'lini qo'shish xato manbai bo'lardi
  → +9 test; 4950 → 4784

- [x] **FAZA 6.3 — terminal xato dialogi ajratildi** (commit a5f8713)
  → `lib/changes/dialogs/terminal_error_dialog.dart` (199 qator)
  → U provider holatiga UMUMAN tegmasdi — sof UI edi
  → **`type*` KO'CHIRILMADI:** typeUzcard(80/9 UI), typeHumo(106/9),
    typeClick(61/12), typePaynet(59/10), typeUzum(47/9),
    typeFromCashbackBalance(43/10), typePayme(37/9) — ular dialog
    orkestratorlari va BLoC dispatcherlari, biznes mantiq emas
  → 4784 → 4585

- [x] **FAZA 7 — skaner kodi tasnifi `BarcodeClassifier` ga** (commit ba4e334)
  → `lib/changes/domain/barcode/barcode_classifier.dart`
  → `sanitize()`, `classify()` → `ScannedCodeKind`, `parseExpiry()`, `isExpired()`
  → **TARTIB MUHIM:** bo'sh → URL → `isMarkingDialogDisplaying` → UUID →
    utsenka QR → erkin matn → raqamsiz → tarozi(kilo) → tarozi(dona) →
    mahsulot. `isMarkingDialogDisplaying` klassifikatorga kirmadi (dialog
    holati), lekin ASL JOYIDA qoldi — boshqa joyga qo'yilsa markirovka
    dialogi ochiqligida tarozi kodi ishlanib ketardi (bu xato yo'l qo'yildi
    va commitdan oldin tuzatildi)
  → **`switch` emas `if`-zanjiri:** switch Dart'ning BuildContext oqim
    tahlilini o'zgartirib 4 ta yangi ogohlantirish chiqargan edi
  → +41 test; 4585 → 4549

## YAKUNIY NATIJA (Faza 0-7)

| | Boshlanish | Hozir |
|---|---|---|
| `ordering_provider_4.dart` | 5868 | **4549** (−1319, 22%) |
| `shift_singleton_4.dart` | 85 478 | **500** |
| Testlar | 85 (+1 yiqiladigan) | **344** |
| `flutter analyze` | 1018 | **1010** |
| `lib/features/` | — | **hech qachon tegilmagan** |

### Yaratilgan modullar (7 ta)

```
lib/changes/domain/
├── marking/mark_cleaner.dart        scanTime, forFiscal
├── marking/mxik_rules.dart          MXIK → markirovka/product_type
├── marking/gs1.dart                 parseDate
├── terminal/terminal_receipt_parser.dart
├── receipt/receipt_builder.dart     build, buildOnlyOfd
└── barcode/barcode_classifier.dart  sanitize, classify, parseExpiry
lib/changes/providers/ordering/
├── catalog_navigation_controller.dart
├── payment_tally_controller.dart
└── discount_effects_controller.dart
lib/changes/dialogs/terminal_error_dialog.dart
```

## DO'KON SINOVI (2026-08-06)

Foydalanuvchi real kassada sinab, **ishlashini tasdiqladi**:
mahsulot qo'shish, markirovka, blok, smena, diskontlar, **to'lov**
(karta/terminal, naqd+sdacha, aralash to'lov, chekdagi mijoz nomi).

Faza 7 (skaner tasnifi) sinovdan KEYIN qo'shilgan — u hali sinalmagan.

## Keyingi qadamlar

**Maqsad: 4000 qator** (foydalanuvchi so'ragan), keyin yana sinov.
Hozir 4549 → **−549 qator kerak**.

Qolgan yirik zonalarning HAMMASI bir turdagi: dialog va mantiq o'ralashgan.

| Zona | Qator | UI nuqtalari |
|---|---|---|
| `type*` (7 metod) | 460 | 68 |
| `_markingCheck` | 417 | 59 |
| `addSeperatedProduct` | 231 | 22 |
| `addProduct` | 196 | 15 |

Ularni ajratish uchun har bir metodni ikkiga bo'lish kerak: "nima qilish
kerakligini hal qiladi" (testlanadi) va "dialogni ko'rsatadi" (UI).
Bu `lib/features/` ga tegishni talab qilishi mumkin — ya'ni hozirgacha
saqlangan "UI ga tegmaslik" qoidasi tugaydi.

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

## YANGI CHAT UCHUN: qayerdan davom etish

1. Branch: `refactor/ordering-split` (ayyubxon'dan, hali merge qilinmagan)
2. `flutter test` -> 344/344 yashil bo'lishi kerak (bazaviy holat)
3. Shu hujjatning "Keyingi qadamlar" bo'limidan davom et
4. **Xavfsizlik qoidalari (yuqorida)** hali ham kuchda — ayniqsa:
   fasad, notify-callback, bitta commitda bitta narsa, bug topilsa
   tuzatilmaydi (qayd etiladi)
5. Har faza tartibi: **avval test yoz -> keyin ko'chir -> tekshir -> commit**
   (Faza 4 va 6 shu tartibda ishladi; Faza 4 da testlar real crash ushladi)

Tekshirish buyruqlari:
```
flutter test                              # 344/344
flutter analyze                           # 1010 dan oshmasin
git status --porcelain -- lib/features/   # bo'sh bo'lishi shart
wc -l lib/changes/providers/ordering_provider_4.dart
```

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

- **BuyXGetX aralash savatda (blok+dona):** `perSetSize = buyAmount × 2`,
  ya'ni `get == buy` deb faraz qilinadi. `get != buy` bo'lsa (10 olsang 2
  tekin) blok qatoriga chegirma tegmaydi.
  `test/discount_box_test.dart` — "QAYD: get != buy ..."

- **`Gs1.parseDate` oy/kun chegarasini tekshirmaydi:** `(17)999999` uchun
  `DateTime(1999,99,99)` Dart tomonidan normallashadi -> 2007-06-07
  (null emas). Amalda xavfsiz tomonga xato.
  `test/barcode_classifier_test.dart` — "QAYD: chegaradan oshgan sana ..."

## Test / Verifikatsiya

Har faza uchun:
1. `flutter test` — barcha testlar yashil
2. `flutter analyze` — issue soni oshmasin (bazaviy: 1018)
3. `git diff --stat` da `lib/features/` o'zgarmagan (fasad qoidasi isboti)
4. Windows build + do'kon smoke testi: naqd/karta/aralash to'lov, sdacha, diskont, markirovka, blok, qaytarish, smena, chek, kategoriya navigatsiyasi
