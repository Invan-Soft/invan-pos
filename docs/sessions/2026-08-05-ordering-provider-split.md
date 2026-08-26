# Task: OrderingProvider4 ni bosqichma-bosqich ajratish

**Boshlangan:** 2026-08-05
**Holat:** in-progress (Faza 0-8 do'konda tasdiqlangan, Faza 9 rejalashtirilmoqda)
**Oxirgi ish:** 2026-08-26, Faza 9.5 tugadi — **4000 qator maqsadi bajarildi** (do'kon sinovi kutilmoqda)
**Branch:** refactor/ordering-split-2 (ayyubxon'dan, push qilinmagan)
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

- [x] **FAZA 8 — savat qatori yasovchi `SoldItemBuilder` ga** (commit b3aff03)
  → `lib/changes/domain/cart/sold_item_builder.dart`
  → `_createSoldItem` savatga mahsulot qo'shishning yuragi — har skan va
    har bosishda chaqiriladi, lekin private bo'lgani uchun testlanmasdi
  → MXIK qoidalariga `MxikRules` orqali bevosita murojaat qiladi
  → +12 test; 4549 → 4514

## HOZIRGI HOLAT (2026-08-06 holatiga)

| | Boshlanish | Hozir |
|---|---|---|
| `ordering_provider_4.dart` | 5868 | **4514** (−1354, 23%) |
| `shift_singleton_4.dart` | 85 478 | **500** |
| Testlar | 85 (+1 yiqiladigan) | **356** |
| `flutter analyze` | 1018 | **1010** |
| `lib/features/` | — | **hech qachon tegilmagan** |
| Commitlar | — | **15 ta** (`refactor/ordering-split`) |

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

## DO'KON SINOVI

### ✅ Sinalgan va tasdiqlangan (2026-08-06)

Faza 0–6 ni qamraydi. Foydalanuvchi real kassada sinab, **ishlashini
tasdiqladi**:
- mahsulot qo'shish, markirovka, blok, smena, diskontlar
- **to'lov**: karta/terminal, naqd + sdacha, aralash to'lov, chekdagi
  mijoz nomi

### ✅ Faza 7-8 ham tasdiqlandi (2026-08-24)

Foydalanuvchi real Windows sotuvlarida sinab, **hech qanday muammo
chiqmaganini** tasdiqladi. Ya'ni quyidagi ro'yxat (skaner + savatga qo'shish)
yopildi va butun Faza 0-8 zanjiri do'konda ishlaydi.

### ~~⚠️ HALI SINALMAGAN~~ — YOPILDI (2026-08-24)

**Faza 7 va Faza 8 sinovdan KEYIN qo'shilgan.** Ikkalasi ham POS'da eng
ko'p ishlatiladigan yo'llarga tegadi: skaner va savatga qo'shish.

**Skaner (Faza 7 — `BarcodeClassifier`):**
- [ ] Oddiy shtrix-kod skani → mahsulot qo'shiladi
- [ ] SKU qo'lda kiritish → mahsulot topiladi
- [ ] Tarozi yorlig'i — **kilo** (28... bilan, 13 belgi) → og'irlik to'g'ri
- [ ] Tarozi yorlig'i — **dona** (21...) → son to'g'ri
- [ ] Utsenka QR (`{...}`) → chegirmali qator qo'shiladi
- [ ] Noto'g'ri kod: `salom dunyo` yozib Enter → "format noto'g'ri" dialogi,
      mahsulot QO'SHILMASLIGI kerak
- [ ] **ENG MUHIMI:** markirovka dialogi OCHIQ turganda boshqa shtrix-kod
      yoki tarozi yorlig'ini skanerlang → **hech narsa bo'lmasligi kerak**.
      (Ko'chirishda shu tartib buzilayozgan edi, commitdan oldin tuzatildi —
      shuning uchun aynan shu holat tekshirilishi shart.)

**Savatga qo'shish (Faza 8 — `SoldItemBuilder`):**
- [ ] Markirovkali tovar (sigareta/alkogol/suv) → sotib, **chekda soliq
      turi** to'g'ri chiqishini tekshirish
- [ ] Kiloli tovar (tarozidan) → kasr miqdor to'g'ri (masalan 1.256 kg)
- [ ] Oddiy dona tovar → narx va son to'g'ri

Agar biror muammo chiqsa: 15 ta commit alohida, `git revert <hash>` bilan
faqat aybdor faza qaytariladi.

---

## TO'LIQ SINOV XARITASI (2026-08-10)

Savol: *"qaysi modul POS'da qayerda ko'rinadi va nimani sinash kerak?"*
Quyidagi jadval har ko'chgan modulni **ekran + harakat** ga bog'laydi.

### 1. `BarcodeClassifier` — Faza 7 (`ba4e334`) 🔴 ENG YUQORI RISK

**Qayerda:** Bosh ekran, skaner/klaviatura kiritish maydoni. Har skanda ishlaydi.
**Nima qiladi:** kiritilgan kodni tasniflaydi (URL / UUID / utsenka QR / tarozi
kilo / tarozi dona / mahsulot / erkin matn) + muddat (`(17)`) tekshiradi.

- [ ] Oddiy shtrix-kod skani → mahsulot qo'shiladi
- [ ] SKU qo'lda kiritib Enter → mahsulot topiladi
- [ ] Tarozi **kilo** yorlig'i (`28...`, 13 belgi) → og'irlik to'g'ri (1.256 kg)
- [ ] Tarozi **dona** yorlig'i (`21...`) → son to'g'ri
- [ ] Utsenka QR (`{...}`) → chegirmali qator qo'shiladi
- [ ] `salom dunyo` yozib Enter → "format noto'g'ri" dialogi, savat o'zgarmaydi
- [ ] **ENG MUHIMI:** markirovka dialogi OCHIQ turganda boshqa kodni skanerlang →
      **hech narsa bo'lmasligi kerak** (ko'chirishda shu tartib buzilayozgan edi)

### 2. `SoldItemBuilder` — Faza 8 (`b3aff03`) 🔴 YUQORI RISK

**Qayerda:** savatga har qanday mahsulot qo'shilganda (skan ham, bosish ham).
**Nima qiladi:** `ReceiptModelSoldItem4` qatorini yasaydi — `product_type`,
`package_code` (KIZ), `marking` bayrog'i, narx, miqdor.

- [ ] Markirovkali tovar (sigareta/alkogol/suv) → sotilgach **chekda soliq turi**
      to'g'ri
- [ ] Kiloli tovar → kasr miqdor to'g'ri
- [ ] Oddiy dona tovar → narx va son to'g'ri

### 3. `ReceiptBuilder` — Faza 6.1/6.2 (`46d27a4`, `73f6ca9`) 🔴 YUQORI RISK

**Qayerda:** To'lov ekrani → "Yakunlash" tugmasi.
`build()` = odatiy sotuv, `buildOnlyOfd()` = faqat-OFD rejimi (ikki alohida yo'l).

- [ ] Naqd to'lov → chek to'g'ri, sdacha to'g'ri
- [ ] Karta to'lov → chek to'g'ri
- [ ] Aralash to'lov (naqd + karta) → summalar taqsimoti to'g'ri
- [ ] Diskontli sotuv → chekda chegirma satri
- [ ] Mijoz tanlangan sotuv → chekda mijoz nomi/INN
- [ ] Savatdan qator o'chirib sotish → `deleted_items` ketadi, 10.2.1 buzilmaydi
- [ ] **Faqat-OFD rejimida** ham yuqoridagilarni takrorlash (`buildOnlyOfd`
      alohida yo'l — sana `now−5soat`, terminal maydonlari boshqa)

### 4. `TerminalReceiptParser` + `terminal_error_dialog` — Faza 1/6.3 (`bb878dc`, `a5f8713`)

**Qayerda:** karta to'lovi, terminal orqali.

- [ ] Muvaffaqiyatli karta to'lovi → chekda **karta turi** (HUMO/UZCARD/VISA),
      karta raqami, avtorizatsiya kodi to'g'ri chiqadi
- [ ] Muvaffaqiyatsiz to'lov (mablag' yetarli emas / bekor qilish) →
      **xato dialogi** ochiladi, matn uz/ru to'g'ri

### 5. `MarkCleaner` + `MxikRules` + `Gs1` — Faza 1 (`bb878dc`)

**Qayerda:** markirovkali tovar skani va fiskal chekka KM yuborish.

- [ ] Sigareta/alkogol KM skani → dialog qabul qiladi, ONKM tekshiruvi ishlaydi
- [ ] KM ichida `93`/crypto qismi bo'lsa → skan vaqtida kesiladi
- [ ] Sotilgach fiskal chekda `mark` to'g'ri formatda
- [ ] `(17)` muddati o'tgan tovar → ogohlantirish chiqadi

### 6. `CatalogNavigationController` — Faza 2 (`6776ca8`) 🟡

**Qayerda:** Bosh ekran, kategoriya paneli.
**Asosiy risk:** holat o'zgaradi-yu **ekran qayta chizilmaydi** (notify callback).

- [ ] Kategoriya bosish → mahsulotlar ro'yxati **darhol** yangilanadi
- [ ] Subkategoriya bosish → yangilanadi
- [ ] Breadcrumb (path) dagi orqaga qaytish → ishlaydi
- [ ] "Hammasi" → butun katalog qaytadi
- [ ] Kategoriya ichida qidiruv/skan → path tozalanadi

### 7. `PaymentTallyController` — Faza 3 (`67605e0`) 🟡

**Qayerda:** To'lov ekrani (chapdagi to'lov turlari + klaviatura).

- [ ] Summa kiritish → qolgan summa va sdacha jonli yangilanadi
- [ ] "Hammasi" (payByAll) → butun summa tanlangan turga tushadi
- [ ] To'lov turini ro'yxatdan o'chirish → summa qaytadi
- [ ] ↑/↓ strelka bilan to'lov turini almashtirish
- [ ] "Yakunlash" tugmasi to'g'ri paytda aktiv/noaktiv bo'ladi

### 8. `DiscountEffectsController` — Faza 4 (`c919eaa`) 🟡

**Qayerda:** savatga mahsulot qo'shish/o'chirish, mijoz tanlash.

- [ ] Buy X Get Y (masalan 3 olsang 1 tekin) → tekin qator qo'shiladi
- [ ] Free Gift → sovg'a dialogi chiqadi, tanlangani savatga tushadi
- [ ] Buy X Get X → to'g'ri hisoblanadi
- [ ] Mijoz tanlanganda → guruh diskonti qo'llanadi (dialog chiqadi)
- [ ] Mijozni o'chirganda → diskont bekor bo'ladi
- [ ] Savatdan qator o'chirilganda → diskont qayta hisoblanadi
- [ ] **Blok + diskont** birga (aralash savat)

### 9. Lint tozalash — `83c2c37`, `b3050c5` 🟢 PAST RISK

222 fayl, `dart fix` (AST darajasida). Xatti-harakatga tegmaydi, lekin
`sort_child_properties_last` UI daraxtiga tegadi:

- [ ] Har asosiy ekranni bir marta ochib **vizual ko'rik** (bosh, to'lov,
      cheklar, hisobot, sozlamalar, drawer)

Qo'lda ko'rilgan 3 ta null-safety o'zgarishi — aynan shu joylar:
- [ ] MXIK Soliq qidiruvi (`tasnif_service`) → MXIK topiladi
- [ ] Mahsulot qidirish dialogi (`search_dialog_content`) → qidiruv ishlaydi
- [ ] Sozlamalar → Hisobotlar → markirovka "Oxirgi yangilanish" satri ko'rinadi

### 10. Commitlanmagan ish — OFD gating

Ishchi papkada 14 fayl o'zgargan (`docs/sessions/2026-08-07-ofd-off-marking-cashsale-gating.md`).
Uning sinov ro'yxati **o'sha hujjatda**, alohida bajariladi.

---

### Tavsiya etilgan tartib (~1 soatlik smoke)

1. Kategoriya navigatsiyasi (6) → tez, rebuild bug'ini darhol ochadi
2. Skaner varianta-varianta (1) → shu jumladan mark-dialog ochiqda skan
3. Savatga qo'shish: dona / kilo / markirovkali / blok (2)
4. Diskontlar: BuyXGetY, FreeGift, mijoz guruhi (8)
5. To'lov arifmetikasi: kiritish, hammasi, o'chirish (7)
6. Real sotuv: naqd → chek (3)
7. Real sotuv: karta/terminal → chek + xato holati (3, 4)
8. Aralash to'lov + qator o'chirib sotish (3)
9. Faqat-OFD rejimida 1 ta sotuv (3)
10. Ekranlar bo'ylab vizual ko'rik (9)

### Buzilsa — qaysi commitni qaytarish

| Simptom | Revert |
|---|---|
| Skan noto'g'ri ishlaydi | `ba4e334` |
| Savat qatori/soliq turi noto'g'ri | `b3aff03` |
| Chek noto'g'ri yig'ilgan | `46d27a4` / `73f6ca9` |
| Terminal/karta ma'lumoti chekda yo'q | `bb878dc` / `a5f8713` |
| Kategoriya bosilganda ekran yangilanmaydi | `6776ca8` |
| To'lov summasi/sdacha noto'g'ri | `67605e0` |
| Diskont qo'llanmaydi/ikki marta | `c919eaa` |
| UI joylashuvi buzilgan | `83c2c37` |

## 2026-08-24 SESSIYASI — bazaviy holat qayta o'lchandi

`refactor/ordering-split` **ayyubxon'ga merge qilingan**. Undan keyin 15 commit
tushdi, 4 tasi providerga tegdi (cashback, qarz, OFD gating) — fayl
4514 → **4701 qator**ga qaytib o'sdi.

| | Hujjatda (2026-08-06) | Hozir (2026-08-24) |
|---|---|---|
| `ordering_provider_4.dart` | 4514 | **4701** |
| Testlar | 356 | **503** (hammasi yashil) |
| `flutter analyze` | 1010 | **599** |

### Yo'l-yo'lakay topilgan test-infratuzilma xatosi (tuzatildi)

`flutter test` **12 daqiqa osilib**, `cashback_balance_test.dart` ning
`tearDownAll` ida "Test timed out" bilan yiqilardi. 16 ta testning hammasi
o'tardi — muammo faqat tozalashda edi.

**Ildiz sabab:** `PaymentTallyController.removeFromPaymentList` ichidagi
`Pref.setBool(PrefKeys.debtClick, false)` **`await` qilinmaydi**. Bu yozuv
`testWidgets` tanasi ichida boshlanadi, ya'ni FakeAsync zonasida qoladi;
test tugagach zona tashlab yuboriladi va yozuv hech qachon yakunlanmaydi.
Natijada prefs box'ining yozuv navbati bo'shamaydi → `Hive.close()` abadiy
kutadi.

**Tuzatildi:** `test/support/provider_harness.dart` — `tearDownPosTestEnv`
da `Hive.close()` endi 5 soniyalik timeout bilan. To'plam: 12m12s + xato →
**14 soniya, 503/503 yashil**.

Production kodiga TEGILMADI (4-qoida) — `Pref.setBool` ning await'siz
chaqirilishi ilovada normal, faqat test muhitida muammo.

### FAZA 9 NOMZODLARI (qayta o'lchangan)

Hujjatda "oson qismlar tugadi" deyilgan edi, lekin fayl qayta o'lchanganda
**dialogsiz, testlanadigan ~490 qator** topildi:

| Nomzod | Qator | UI nuqtasi |
|---|---|---|
| Reprice / qo'lda-narx klasteri (L1763-1899) | 137 | 0 |
| Guruh tahriri: mark + blok (L2027-2296) | 270 | 0 |
| `_recordDeletedItem` + orphan flag (L2373-2421) | 49 | 0 |
| cashsale / naqd-cheklov getterlari (L619-650) | 32 | 0 |

**MUHIM:** guruh tahriri klasteri Faza 5 da "o'ralashgan" deb rad etilgan
edi, chunki u `findFreeProducts`/`useFreeProducts` ga bog'liq. **O'shanda
`DiscountEffectsController` hali yo'q edi** — endi u bor va kontrollerga
parametr sifatida uzatiladi. Rad etish sababi yo'qoldi.

Rejalashtirilgan uchta mustaqil commit:
1. `domain/cart/row_repricer.dart` — reprice/manual-narx (137)
2. `providers/ordering/group_edit_controller.dart` — mark/blok guruh (270)
3. `domain/cart/deleted_item_recorder.dart` + cashsale qoidalari (81)

Natija taxminan 4701 → **~4200**, dialogli zonalarga (`_markingCheck`,
`type*`) umuman kirmasdan.

## FAZA 9 (2026-08-25) — branch: `refactor/ordering-split-2`

Foydalanuvchi talabi: **avval hamma zonaga to'liq test, keyin bittalab
ko'chirish**, har qadamdan keyin hisobot.

- [x] **9.0 — test bo'shlig'i yopildi (+144 test)** `f3d1f36`
  → `test/cash_restriction_test.dart` (46) — naqd-cheklov getterlari
  → `test/tier_reprice_test.dart` (25) — umumiy dona soni bo'yicha tier
  → `test/manual_price_sync_test.dart` (16) — mavjud 11 testdagi bo'shliqlar
  → `test/group_edit_test.dart` (42) — marka/blok guruh tahriri
  → `test/deleted_item_record_test.dart` (15) — `deleted_items_orderpos`
    (54 test) qamramagan shoxlar
  → `lib/` ga tegilmagan. 503 → 647 test.

- [x] **Test infratuzilmasi tuzatildi** `6af7b0d`
  → `flutter test` 12 daqiqa osilib yiqilardi (yuqoridagi bo'limga qara)
  → 12m12s + xato → **14 soniya, yashil**

- [x] **9.1a — o'lik kod o'chirildi** `e8e9e00`
  → `_repriceAllMarksForProduct` (25 qator) — analizator tasdiqlagan
    `unused_element`. Vazifasini `_repriceProductRowsByTotalUnits` bajaradi.
  → 4701 → 4676

- [x] **9.1b — `RowRepricer` ga ko'chirildi (+21 test)** `a9a1523`
  → `lib/changes/domain/cart/row_repricer.dart`
  → `isKg`, `byTotalUnits`, `syncManualPrice`, `applyExistingManualPrice`
  → Savat ro'yxati va diskont qo'llovchi **parametr** sifatida keladi
  → **FOYDASI:** `applyExistingManualPrice` ni ilgari umuman testlab
    bo'lmasdi (faqat `addProduct`/`addSeperatedProduct`/`_addBoxProduct`
    orqali, ular `BuildContext` talab qiladi). Endi 12 to'g'ridan-to'g'ri test.
  → 4676 → **4577**. Testlar 647 → **668**. analyze 599 → **598**.

- [x] **9.2 — `GroupEditController`** `e95bbed`
  → `lib/changes/providers/ordering/group_edit_controller.dart`
  → `activeMarkIndices`, `activeBoxIndices`, `saveMarkGroup`, `saveBoxGroup`,
    `deleteMarkGroup`, `deleteBoxGroup` + tahrir rejimi bayroqlari
  → **2-qoida:** `ChangeNotifier` EMAS — `notifyListeners` callback.
    Savat, `deleted_items` yozuvi, reprice, manual sinxron, diskont
    effektlari, `showCount` tozalash, qizil-o'chirish bayrog'i ham callback.
  → Maydonlar getter/setter juftligiga aylandi (Faza 3 naqshi) — UI dagi
    `beginMarkGroupEdit`/`endBoxGroupEdit` chaqiruvlari o'zgarishsiz
  → **+25 to'g'ridan-to'g'ri test:** endi SHARTNOMANI ko'rib bo'ladi —
    qaysi shoxda qaysi callback. Masalan "blok guruhida qo'lda narx tier
    reprice O'RNIGA syncManual qiladi" qoidasi ilgari hech qanday test
    bilan qo'riqlanmasdi
  → 4577 → **4374**

- [x] **9.3a — `DeletedItemRecorder`** `ede37c8`
  → `lib/changes/domain/cart/deleted_item_recorder.dart`
  → `record`, `flagOrphansIfCartEmpty`
  → Xodim IDsi endi callback (ilgari `HiveBoxes.getCurrentEmployee` ga
    qattiq bog'langan edi) — modul Hive'siz ishlaydi
  → +22 test; 4374 → **4339**

- [x] **9.3b — `CashRestrictionRules`** `9045cc6`
  → `lib/changes/domain/cart/cash_restriction_rules.dart`
  → `cardOnlyRequired`, `cashHiddenByMarking`, `cashHiddenByCashsale`,
    `bigTotalHidden` + `bigTotalLimit` (25 mln endi nomlangan konstanta)
  → Sozlama bayroqlari parametr — qoidalar Pref'siz testlanadi
  → +23 test; 4339 → **4303**

### Faza 9 holati (9.0–9.3 yakuni)

| | Boshlanish | Hozir |
|---|---|---|
| `ordering_provider_4.dart` | 4701 | **4303** (−398) |
| Testlar | 503 (1 yiqiladigan) | **738** |
| `flutter analyze` | 599 | **598** |
| `lib/features/` | — | **tegilmagan** |
| Commitlar | — | **8 ta** (`refactor/ordering-split-2`) |

### Faza 9 da yaratilgan modullar (4 ta)

```
lib/changes/domain/cart/
├── row_repricer.dart              tier, manual narx sinxroni
├── deleted_item_recorder.dart     deleted_items yozuvi, orphan "-"
└── cash_restriction_rules.dart    naqd tugmasini yashirish qoidalari
lib/changes/providers/ordering/
└── group_edit_controller.dart     marka/blok guruh tahriri
```

### ⚠️ DO'KON SINOVI — 9.1–9.3 uchun

Faza 9 savatning eng issiq yo'llariga tegdi. Windows'da tekshirilishi kerak:

**Narx (RowRepricer — `a9a1523`):**
- [ ] Bir mahsulotdan ko'p urish → tier narxga tushishi (masalan 12 dona)
- [ ] Blok + dona aralash savat → ikkalasi bir xil dona narxda
- [ ] OPD'da narxni qo'lda o'zgartirish → blok/dona qatorlari sinxron
- [ ] Qo'lda narxdan keyin YANGI skan → tier'ga qaytmasligi kerak
- [ ] Kiloli tovar (tarozi) narxi

**Guruh tahriri (GroupEditController — `e95bbed`) 🔴 ENG YUQORI RISK:**
- [ ] Markirovkali tovarni 3 marta skanerlab, OPD'da qty 3→2 → eng OXIRGI
      skan qilingan marka chiqishi kerak
- [ ] Marka guruhining narxini o'zgartirish → hamma markaga tushadi
- [ ] Marka guruhini butunlay o'chirish
- [ ] Blok guruhida qty kamaytirish va narx o'zgartirish
- [ ] Qizil o'chirish rejimida yuqoridagilar (qator savatda qizil qoladi)
- [ ] Guruh o'chirilgach diskont qayta hisoblanishi

**O'chirish qaydi (DeletedItemRecorder — `ede37c8`):**
- [ ] Qator o'chirib sotish → `deleted_items` serverga ketadi
- [ ] PIN bilan o'chirish → `deleted_by` da PIN egasi
- [ ] Savatni sotuvsiz bo'shatish → keyingi chekda "-" bilan ketadi

**Naqd cheklovi (CashRestrictionRules — `9045cc6`):**
- [ ] Alkogol/tamaki savatda → naqd tugmasi yashirinadi
- [ ] `cashsale = 0` mahsulot → naqd yashirinadi
- [ ] 25 mln dan katta qator → naqd yashirinadi
- [ ] OFD o'chirilgan bo'lsa → cheklovlar ishlamaydi (naqd ko'rinadi)

**Skaner (ScannedProductLookup — `298effe`) 🔴 YUQORI RISK:**
- [ ] Oddiy shtrix-kod skani → mahsulot topiladi
- [ ] Markirovkali tovar (GS1 KM) skani → to'g'ri mahsulot + KM biriktiriladi
- [ ] Blok shtrix-kodi skani → blok qatori qo'shiladi
- [ ] SKU qo'lda kiritish → topiladi; noto'g'ri SKU → "topilmadi" dialogi
- [ ] Narxi 0 mahsulot skani → narx dialogi chiqadi

**Onlayn to'lovlar (9.4e — `1e896ab`):**
- [ ] Click / Uzum / Paynet → summa to'g'ri
- [ ] Aralash to'lov (naqd + onlayn)

**Uzcard/Humo (Arcus terminali): TEGILMAGAN** — `61dae9e` bilan asl holiga
qaytarildi (terminal yo'q, sinab bo'lmaydi). Sinov shart emas.

**O'chirish (9.4c — `bc22e81`):**
- [ ] Savatdan bitta qator o'chirish → qolganlar qayta narxlanadi
- [ ] Telegram kanaliga xabar boradi

Muammo chiqsa: har faza alohida commit, `git revert <hash>`.

| Simptom | Revert |
|---|---|
| Skan mahsulot topmayapti / noto'g'ri topyapti | `298effe` |
| Click/Uzum/Paynet summasi noto'g'ri | `1e896ab` |
| Bitta qator o'chirish buzildi | `bc22e81` |
| Telegram xabari ketmayapti | `975b86b` |

### FAZA 9.4 — dialog↔mantiq bo'linishi (2026-08-25)

Maqsad: dialogli metodlar ichidan UI'siz, testlanadigan qismlarni ajratish.
**`lib/features/` ga baribir tegilmadi** — hamma narsa provider ichida
bo'lindi.

- [x] **9.4a — `TelegramNotifier`** `975b86b`
  → `lib/changes/services/telegram_notifier.dart`
  → Tarmoq xabarnomasi savat mantiqiga tegishli emas edi
  → Yo'l-yo'lakay +17 test (`cart_row_delete_test`) — 9.4c dan oldin muzlatish
  → 4303 → **4258**

- [x] **9.4b — `GroupEditController` → `CartEditController`** `a3adae3`
  → Faqat nom. Sabab: OPD dialogining ikki tugmasi uch nishonga tushadi
    (marka guruhi / blok guruhi / bitta qator) — ikkinchi kontroller ochish
    to'qqizta callbackni takrorlash bo'lardi

- [x] **9.4c — bitta-qator o'chirish kontrollerga** `bc22e81`
  → `pressDialogDeleteButton` endi uch qatorlik dispatcher
  → Yangi callbacklar: `currentEmployeeName`, `posNameOf`, `notifyDeleted`
  → **FOYDASI:** `showCount` tozalash sharti ("shu mahsulotdan boshqa qator
    qolmasa") ilgari hech qanday test bilan qo'riqlanmasdi — private `Map`
    edi. Xabarnoma `notify` dan KEYIN ketishi ham mahkamlandi
  → +11 test; 4258 → **4204**

- [x] **9.4d — `ScannedProductLookup`** `298effe`
  → `lib/changes/domain/barcode/scanned_product_lookup.dart`
  → `findBoxProduct`, `find` → `ScannedProductMatch`, `findZeroPriceProduct`
  → **FOYDASI:** ilgari UMUMAN testlab bo'lmasdi — `onBarcodeScanned`
    `GlobalKey<ScaffoldState>` oladi va dialoglar ochadi. Endi 30 test:
    GS1 qavsli/qavssiz format, blok kodining uch variantining ustunlik
    tartibi, SKU fragment-himoyasi, `triedPatterns` yig'ilishi
  → `onBarcodeScanned` 252 → 195; provider 4204 → **4147**

- [x] **9.4e — takrorlangan pul formulalari yig'ildi** `1e896ab`,
  **qisman qaytarildi** `61dae9e`
  → Dastlab olti joydagi ikki formula va `isApproved` yig'ilgan edi
  → **FOYDALANUVCHI QARORI (2026-08-25):** do'konda fizik Arcus terminali
    YO'Q, demak Uzcard/Humo yo'lini sinab bo'lmaydi → u refaktoring
    qilinmasligi kerak. `typeUzcard`, `typeHumo` va ikkalasi chaqiradigan
    `allPaymentType` **bayt-ma-bayt asl holiga qaytarildi**
  → Ishlatilmay qolgani uchun o'chirildi: `amountMinusCurrent`,
    `TerminalReceiptParser.isApproved` (+18 test)
  → QOLDI: `amountIgnoringCurrent` — Click / Uzum / Paynet (ilova ichidagi
    to'lovlar, terminalsiz sinaladi)
  → 4147 → 4119 → **4141**
  → Ish jarayonida **mavjud testlar xatoni darhol ushladi**: `allPaymentType`
    da `currentPaymentValue` formuladan keyin ham ishlatilar ekan, uni
    o'chirish 39 testni yiqitdi

### FAZA 9 YAKUNI

| | Boshlanish | Hozir |
|---|---|---|
| `ordering_provider_4.dart` | 4701 | **4141** (−560, 12%) |
| Testlar | 503 (1 yiqiladigan) | **800** |
| `flutter analyze` | 599 | **596** |
| `lib/features/` | — | **hech qachon tegilmagan** |
| Commitlar | — | **18 ta** (`refactor/ordering-split-2`) |

Yaratilgan modullar (8 ta):
```
lib/changes/domain/cart/
├── row_repricer.dart              tier, qo'lda narx sinxroni
├── deleted_item_recorder.dart     deleted_items, orphan "-"
└── cash_restriction_rules.dart    naqd tugmasini yashirish
lib/changes/domain/barcode/
└── scanned_product_lookup.dart    skan kodidan mahsulot topish
lib/changes/providers/ordering/
└── cart_edit_controller.dart      OPD dialogi: guruh + bitta qator
lib/changes/services/
└── telegram_notifier.dart         o'chirish xabarnomasi
(+ payment_tally_controller va terminal_receipt_parser kengaytirildi)
```

### QOIDA: fizik qurilma talab qiladigan yo'llarga TEGILMAYDI

Uzcard/Humo (Arcus terminali) yo'li do'konda sinab bo'lmaydi — terminal
yo'q. Sinab bo'lmaydigan kodni refaktoring qilish = tekshirilmagan risk.
Shuning uchun bu yo'l (va u chaqiradigan `allPaymentType`) asl holida
qoladi. Xuddi shu qoida `pressPaymentButton*` (fiskal modul) uchun ham
o'ylab ko'rilishi kerak.

### 9.4 da qayd etilgan xatti-harakatlar (4-qoida — tuzatilmadi)

- **Onlayn to'lov formulasi joriy summani ayirmaydi** (`amountIgnoringCurrent`,
  Click/Uzum/Paynet)
  — Click/Payme/Uzum tugmasi ikki marta bosilsa summa oshib ketishi mumkin.
  Cashback'da AYNAN shu xato bo'lgan (`2026-08-12-cashback-overspend-fix.md`).
  Test bilan muzlatildi: `payment_amount_rules_test` — "Ikki formulaning FARQI"
- Qizil o'chirishda `rows` bo'shamaydi, shuning uchun `resetClient`
  chaqirilmaydi — lekin orphan "-" baribir belgilanadi

### FAZA 9.5 (2026-08-26) — 4000 qator maqsadi bajarildi

Avval `fix/marking-flag-ofd-gating` branchi shu branchga merge qilindi
(markirovka bayrog'i xatosi — pastda alohida bo'lim).

- [x] **9.5a — o'lik kod tozalandi** `1a61538`
  → 5 ta ishlatilmaydigan maydon (`_cardEnabled` ... `_debtEnabled`) va
    ularning yozuvlari; `addProduct` dagi 2 ta ishlatilmaydigan lokal
  → Chaqiruvlarni o'chirishdan oldin yon ta'siri tekshirildi:
    `getBuyXGetXDiscountsOnly` savatni faqat O'QIYDI
  → **QAYD:** u ichkarida `forDialogOnly: true` ni QOTIRIB chaqiradi, ya'ni
    o'z parametri e'tiborga olinmaydi — o'chirilgan ikki chaqiruv aslida
    bir xil natija berardi
  → 4109 → **4090**

- [x] **9.5b — `OnkmValidator`** `e180bd8`
  → `lib/changes/services/onkm_validator.dart`
  → `_markingCheck` ichida `http.post` o'rtasida turgan edi
  → **FOYDASI:** so'rov tanasi (kmIds, commitentTin, productCode, packageCode)
    biznes uchun kritik — noto'g'ri ketsa soliq rad javob beradi va kassir
    markirovkali tovarni sota olmaydi. Endi 18 test
  → 4090 → **4064**

- [x] **9.5c — `InvoiceRowBuilder`** `1a94436`
  → `loadInvoiceByBarcodeWithBloc` ichida edi (BuildContext + BLoC stream)
  → `SoldItemBuilder` bilan ATAYLAB birlashtirilmadi — maydon manbalari
    boshqa (nom/miqdor/tannarx invoice dan, MXIK/paket/INN katalogdan)
  → Narx qoidasi muzlatildi: invoice tiers ichidan eng KATTA minQuantity
    ustun; invoice narx bermasa katalogning 1 donalik narxi
  → +19 test; 4064 → **4020**

- [x] **9.5d — `MarkedRowBuilder`** `2efabbc`
  → `addSeperatedProduct` ichida edi (dialog + navigatorKey)
  → `SoldItemBuilder` dan farqlari biznes qoidasi va endi test bilan
    mahkamlangan: miqdor har doim 1 (har donaning o'z KM i), `soldBy` da
    o'lchov birligi, `mark`/`packageName`, `cost` = 0
  → +22 test; 4020 → **3991**

### FAZA 9 YAKUNIY NATIJA

| | Boshlanish | Hozir |
|---|---|---|
| `ordering_provider_4.dart` | 4701 | **3991** (−710, 15%) |
| Testlar | 503 (1 yiqiladigan) | **865** |
| `flutter analyze` | 599 | **589** |
| `lib/features/` | — | **hech qachon tegilmagan** |

**Foydalanuvchi so'ragan 4000 qator chegarasi bajarildi.**

### Yo'l-yo'lakay topilgan va tuzatilgan XATO

`fix/marking-flag-ofd-gating` (`c032a3c`) — alohida branchda, `ayyubxon` dan.

OFD o'chiq bo'lsa ham savat qatoriga `marking: true` qo'yilardi → qator
"markirovka guruhi" deb ko'rsatilib, OPD da qty ni na kamaytirib, na
oshirib bo'lardi (xato ham chiqmasdi).

Ildiz sabab: 2026-08-12 dagi OFD gating ishi tuzatishni `SoldItemBuilder`
ga qo'llagan, lekin O'SHA commit providerdagi delegatsiyani inline qilib
qaytargan. Natijada to'g'ri kod hech qachon chaqirilmagan, `SoldItemBuilder`
o'lik kodga aylangan, uning 12 testi esa ilova ishlatmaydigan kodni sinagan.

Tuzatildi: uch joyda bitta qaror (`MxikRules.isProductMarkable`) +
delegatsiya ustiga izoh (yana inline qilinmasligi uchun) + 6 ta yangi test
(`test/marking_flag_ofd_gating_test.dart`), ular `addProduct` ni real
`BuildContext` bilan chaqiradi — regressiya takrorlansa darhol ushlanadi.

**Saboq:** ajratilgan modul faqat yangi ishlar uni ISHLATGANDA saqlanadi.
Bitta feature commiti chetlab o'tsa, kod jimgina qaytib keladi.

### QOLGANLARI — refaktoring qilinmaydi

| Zona | Qator | Nega tegilmaydi |
|---|---|---|
| `_markingCheck` (qolgani) | ~350 | 24 ta dialog — orkestrator |
| `pressPaymentButtonOnlyOFD` | 270 | fiskal modul, sinab bo'lmaydi |
| `addProduct` | ~200 | dialoglar bilan o'ralashgan |
| `pressPaymentButton` | 142 | fiskal modul |
| `typeUzcard` / `typeHumo` | 190 | **Arcus terminali yo'q** (foydalanuvchi qarori) |

Printsip: **do'konda sinab bo'lmaydigan kodni refaktoring qilmaymiz.**

## Keyingi qadamlar

**Maqsad: 4000 qator** (foydalanuvchi so'ragan), keyin yana sinov.
Hozir 4514 → **−514 qator kerak**.

**MUHIM:** oson qismlar TUGADI. Faza 7 va 8 birgalikda atigi 71 qator
berdi, chunki qolgan toza (UI'siz) nomzodlar kichik. 514 qator uchun
dialogli katta zonalarga kirish shart.

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

**Bu hujjatni o'qib, quyidagi tartibda davom et:**

1. **Branch:** `refactor/ordering-split` (ayyubxon'dan, hali merge
   qilinmagan). 15 commit, oxirgisi `b3aff03`.

2. **Bazaviy holatni tekshir:** `flutter test` → **356/356 yashil**.
   Agar yashil bo'lmasa — davom etma, avval sababini top.

3. **FOYDALANUVCHIDAN SO'RA:** "Faza 7 (skaner) va Faza 8 (savatga
   qo'shish) do'konda sinalganmi?" — "DO'KON SINOVI" bo'limidagi
   ⚠️ ro'yxatga qara. Sinalmagan bo'lsa, **avval sinovni eslatib qo'y**:
   davom etish tekshirilmagan o'zgarishlarni ko'paytiradi.

4. **Ish tartibi (buzilmaydi):**
   avval test yoz → keyin ko'chir → tekshir → commit.
   Faza 4 va 6 shu tartibda ishladi; Faza 4 da testlar **real crash**
   ushladi (nomlash to'qnashuvi, Buy X Get Y sotuvida).

5. **Xavfsizlik qoidalari (yuqorida)** hali kuchda: fasad, notify-callback,
   bitta commitda bitta narsa, bug topilsa tuzatilmaydi (qayd etiladi).

6. **Foydalanuvchini ogohlantir:** ish davomida `ordering_provider_4.dart`
   ni IDE'da ochiq tutmasin — ikki marta "content is newer" konflikti
   bo'lgan. Faza tugagach faylni qayta ochsin (Revert File).

Tekshirish buyruqlari:
```
flutter test                              # 356/356
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
