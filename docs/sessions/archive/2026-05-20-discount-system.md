# Task: Diskont (chegirma) tizimi — to'liq texnik hujjati

**Boshlangan:** ~2025-01 (DiscountService — 2025-01-25, DiscountHelpers — 2025-01-29, DiscountSingleton — 2025-09-26 dan beri Suxrob Sattorov)
**Holat:** done
**Yakunlangan:** 2026-05-20
**Branch:** main

## Maqsad

InVan 2 POS dagi barcha chegirma turlarini boshqarish: foiz/raqamli chegirmalar (mahsulot va kategoriya bo'yicha), Buy X Get Y, Buy X Get X, Free Gift, mijoz darajasidagi chegirma, chek darajasidagi chegirma (summa yoki foiz). Tizim **lokal Hive ga keshlangan** chegirmalar bazasi orqali ishlaydi, real-time WebSocket bilan sinxronlanadi va savatdagi har bir mahsulotga avtomatik qo'llanadi.

Hozir tizim **stabil, prodda ishlaydi** — keyinchalik bug-fix yoki yangi talab paydo bo'lsa yangi sessiya hujjati ochib davom etiladi (Superseded pattern). Bu hujjat **mukammal arxitektura referensi** sifatida saqlanadi.

## Asosiy fayllar va satr hisobi

| Fayl | Qator | Vazifa |
|------|-------|--------|
| `lib/changes/singletons/discounts/discount_singleton.dart` | 114 | Public facade (8 metod) + ReturnedProduct/ReturnedGift/ReturnedGiftX model'lari |
| `lib/changes/singletons/discounts/discount_helpers.dart` | 910 | Asosiy diskont logikasi — barcha hisob va eligibility |
| `lib/features/get_discounts/model/discounts_response.dart` | 511 | Backend response + Hive entity (DiscountItem va 13 ta yordamchi sinflar) |
| `lib/changes/services/discount_service.dart` | 73 | Backend dan diskont olish, CRUD, callback boshqaruvi |
| `lib/changes/services/web_socket_service/discount/discount_ws_service.dart` | 81 | Real-time WS sync (type 15/16/17) |
| `lib/changes/providers/ordering_provider_4.dart` | 4550 | Integratsiya — `addProduct`, `findFreeProducts`, `useFreeProducts`, `useFreeGiftProducts`, `useBuyXGetXProducts`, `freeGiftDialog`, va h.k. |
| `lib/changes/models/discount_model.dart` | 38 | ObjectBox entity (chek darajasidagi diskont) |
| `lib/changes/models/product_discount_model.dart` | 44 | ObjectBox entity (mahsulot darajasidagi diskont) |
| `lib/changes/dialogs/contains_discount_item_dialog.dart` | 155 | Buy X Get Y ogohlantirish dialog |
| `lib/changes/dialogs/contains_discount_item_dialog_2.dart` | 76 | Buy X Get X / Free Gift ogohlantirish dialog |
| `.../total_price_dialog/discount_type_status.dart` | 10 | Chek darajasidagi diskont turi (summa vs foiz) — global static |
| `.../total_price_dialog/discount_percent.dart` | 95 | Chek diskonti UI (TpBloc bilan) |

## Diskont turlarining UUID-konstantalari

Backend bizga diskontlarni UUID orqali tasniflaydi — kod ichida hard-coded:

### `discountGroupType.id`
| UUID | Turi |
|------|------|
| `22e778e1-e562-4649-b47e-b720a28d831c` | **Product** (mahsulot) |
| `847808d6-5113-4235-a5aa-f5edb044f837` | **Category** (kategoriya) |
| `86951e75-960f-45d7-9505-9b9cd2ce17a7` | **Buy X Get Y** |
| `316b623e-3bb7-43e2-b6d5-1028c927caba` | **Buy X Get X** |
| `e13e3ed0-2d03-42f2-8c5f-43bcb3b3c8e9` | **Free Gift** |

### `discountType.id`
| UUID | Turi |
|------|------|
| `e908c52f-4c6f-46d8-b765-16e074425cd9` | **Percentage (%)** |
| `b78fd1a6-38ed-45a6-b002-caac5de6ebe6` | **Numeric** (raqamli) |
| `a9f3ceb1-4fa3-4f71-ab81-00889e26616b` | **Buy X Get Y** sub-tipi |
| `90d1f774-44bd-49be-9bbf-2e9a44558377` | **Buy X Get X** sub-tipi |

### Chek darajasidagi diskont ID-lar (ordering_provider_4 ichida)
| UUID | Maqsad |
|------|--------|
| `9a2aa8fe-806e-44d7-8c9d-575fa67ebefd` | Default (mijoz tanlanmagan) |
| `9fb3ada6-a73b-4b81-9295-5c1605e54552` | Total **summa** orqali diskont (DiscountTypeStatus.summa) |
| `1fe92aa8-2a61-4bf1-b907-182b497584ad` | Total **foiz** orqali diskont (`_currentClient.discountPercent`) |

[ordering_provider_4.dart:2643-2654, 2882-2890](../../lib/changes/providers/ordering_provider_4.dart#L2643-L2654)

## Ma'lumotlar arxitekturasi

### Backend response — DiscountsResponse / DiscountItem
[discounts_response.dart:11-215](../../lib/features/get_discounts/model/discounts_response.dart#L11-L215)

Asosiy `DiscountItem` maydonlari (HiveType: `discountData`):
- `id, name, displayName` — identifikator va UI nomi
- `discountType` — Percentage/Numeric/BuyXGetY/BuyXGetX
- `discountGroupType` — Product/Category/BuyXGetY/BuyXGetX/FreeGift
- `discountValue` — foiz qiymati (0-100) yoki raqamli summa
- `isExpirable, startDate, expireDate` — vaqt validligi
- `isWholeDay` + `discountSchedules` (`day_of_week, startTime, endTime`) — kun/soat bo'yicha cheklov
- `isAllProducts, productIds, categoryIds` — mahsulot/kategoriya filtri
- `customerGroups, isForAllClients` — mijoz guruhi filtri
- `shopIds` — do'kon filtri
- `buyXGetY` (`productsToBuy, buyProductsAmount, productToGet, getProductsAmount`)
- `buyXGetX` (`productsToBuy, buyProductsAmount, getProductsAmount`)
- `gifts: List<Gifts>` (`buyAmount, getProduct, getProductAmount`)
- `isRepeatable` — diskont qayta-qayta qo'llaniladimi (har set'da)

### Hive bo'limlari
- `HiveBoxes.getDiscounts()` — `Map<String, DiscountItem>`, kalit = `discount.id`
- HiveType ID-lari (`hive_types.dart`): `discounts`, `discountData`, `discountType`, `discountGroupType`, `discountSchedules`, `discountByProduct`, `discountByCategory`, `discountByCustomers`, `discountByShops`, `discountBuyXGetY`, `discountBuyXGetX`, `discountProductsToBuy`, `discountProductsToGet`, `gifts`

### ObjectBox entity'lar (cheklar saqlanadigan store)
- `DiscountModel` (`lib/changes/models/discount_model.dart`) — chekdagi har bir diskont qatori (`idd, name, type, value, total`). `type = "sum"` yoki `name = "single"` ko'rinishida saqlanadi
- `ProductDiscountModel` (`lib/changes/models/product_discount_model.dart`) — mahsulotga qo'llangan diskont (`idd, typeId, typeName, name, value, total`). `ReceiptModelSoldItem4.productDiscount` ro'yxatida saqlanadi

### ReceiptModelSoldItem4 ning diskontga aloqador maydonlari
- `realPrice` — asl narx (chegirmasiz). **Hech qachon o'zgartirilmaydi** (faqat narxning qo'lda o'zgartirilishi yoki box hisoblari uchun)
- `onlyPrice` — bazaviy narx (`finalPrice`/`onePrice` natijasi)
- `price` — joriy narx (chegirma qo'llangandan keyingi)
- `singleDiscount` — bir donadagi chegirma summasi
- `discountPercent` — chegirma foizi (`100 - (price * 100 / realPrice)`)
- `discount: List<DiscountModel>` — chek modeliga yoziluvchi diskont qatorlari
- `productDiscount: List<ProductDiscountModel>` — bu mahsulotga qo'llangan barcha diskont turlarining tarixi
- `isPriceChanged` — narx qo'lda o'zgartirilgan (klient diskonti orqali ham)
- `isPriceOnlyChanged` — narx faqat foydalanuvchi tomonidan o'zgartirilgan (chegirma umuman qo'llanmaydi)
- `saleType, boxValue, boxQuantity` — box mahsulot uchun

## DiscountSingleton — Public Facade
[discount_singleton.dart](../../lib/changes/singletons/discounts/discount_singleton.dart)

8 ta static metod, barchasi `DiscountHelpers` ga delegatsiya qiladi. Bu fasad pattern — tashqi kod faqat `DiscountSingleton` orqali ishlaydi, helpers ichki implementatsiya.

| Metod | Vazifa |
|-------|--------|
| `addDiscountOnProduct(product, categoryId, clientGroupId)` | Bir mahsulotga avtomatik Product+Category diskontlarini qo'llash |
| `buyXGetYOrFreeGifts(products, clientGroupId, totalPrice, isGift)` | BuyXGetY (isGift=false) yoki FreeGift (isGift=true) ro'yxatini qaytarish |
| `getBuyXGetXDiscounts(products, clientGroupId, {forDialogOnly})` | BuyXGetX ro'yxatini qaytarish |
| `addDiscountForProduct(product)` | `ItemsSingleton.discounter` orqali DiscountModel yaratish va `product.discount` ga qo'shish |
| `hasBuyXGetXForProduct(productId, clientGroupId)` | Berilgan mahsulot uchun BuyXGetX diskonti mavjudligini tekshirish |
| `availableDiscount` (getter) | Oxirgi `_getProductIdAndQty` chaqiruvida topilgan ReturnedProduct (UI dialog uchun) |
| `productId(value)` | `_productId` global'ni o'rnatish (qaysi mahsulot UI uchun ko'rsatilishini aniqlash) |
| `maxPrice()` | `_maxPrice` ni 0 ga reset (FreeGift threshold qayta hisoblanishi uchun) |
| `resetAll()` | Hamma static state'ni tozalash |

### ReturnedProduct / ReturnedGift / ReturnedGiftX modellari
[discount_singleton.dart:57-114](../../lib/changes/singletons/discounts/discount_singleton.dart#L57-L114)

Helpers'dan UI ga keladigan natijalar:
- **ReturnedProduct** — BuyXGetY: `availableProducts, returnedProductId, returnedProductQuantity, mustProductQuantity, discountId, discountName, discountGroupType`
- **ReturnedGift** — FreeGift: `buyAmount, getProduct, getProductAmount, isGetX, discountId, discountName, discountGroupType`
- **ReturnedGiftX** — BuyXGetX (yangi qo'shilgan `isRepeatable` maydoni bilan): `buyAmount, getProduct, getProductAmount, isRepeatable, discountId, discountName, discountGroupType`

## DiscountHelpers — Asosiy logika
[discount_helpers.dart](../../lib/changes/singletons/discounts/discount_helpers.dart)

### Global static state (910 qatorlik fayl uchun zaruriy yomon)

```dart
static double _priceCat = 0;    // Category narxining hozirgi qiymati (oqim ichida)
static double _priceProd = 0;   // Product narxining hozirgi qiymati (oqim ichida)
static double _price = 0;       // Yakuniy narx (qaytariladi)
static String _productId = '';  // UI uchun "qaysi mahsulot dialog ko'rsatadi"
static num _maxPrice = 0;       // FreeGift threshold (eng katta bo'sag'a kuzatuvi)
static ReturnedProduct _availableDiscount = ReturnedProduct();
// + 16 ta sana/vaqt cache state'lari (_currentYear, _startMonth, va h.k.)
```

⚠️ **Eslatma:** Static state global tarzda qayta ishlatiladi — har `addDiscountOnProduct` chaqirig'idan oldin `_priceCat`, `_priceProd`, `_price` qayta initsializatsiya qilinadi (qator 78-80).

### `addDiscountOnProduct` — bir mahsulotga diskont qo'llash
[discount_helpers.dart:62-110](../../lib/changes/singletons/discounts/discount_helpers.dart#L62-L110)

Oqim:
1. **Bo'sh bo'lsa tozalash:** Hive box bo'sh — barcha diskont maydonlarini tozalab `realPrice` ga qaytarish
2. **`_price = product.price`** dan boshlash
3. Hive dagi har bir `DiscountItem` ustidan iteratsiya:
   - `dis.isExpirable == null` — buzilgan ma'lumot, o'tkazib yuborish
   - `_checkOptions(dis, clientGroupId)` — barcha eligibility chekni o'tkazish (sana, hafta, do'kon, mijoz guruhi)
   - **Category guruhi** bo'lsa → `_notAllProducts(product, dis, categoryId)`
   - **Product guruhi** bo'lsa → `_isAllProductsCheckAndLogic(product, dis)`
4. Yakuniy `product.price = _price`, `product.discountPercent = 100 - (100 * price / realPrice)`

### Diskont turi qo'llash funksiyalari

**Category:**
- `_notAllProducts` ([454](../../lib/changes/singletons/discounts/discount_helpers.dart#L454)) — `isAllProducts=false` va `categoryIds` ichida joriy mahsulot kategoriyasi bormi — agar ha, `_categoryPercentage` va `_categoryNumeric` ni chaqiradi
- `_categoryPercentage` ([501](../../lib/changes/singletons/discounts/discount_helpers.dart#L501)) — `_priceCat` ni `(realPrice * (1 - %))` qiladi, `_addDiscount(false)` (= percentage)
- `_categoryNumeric` ([539](../../lib/changes/singletons/discounts/discount_helpers.dart#L539)) — `_priceCat -= discountValue`, `_addDiscount(true)` (= numeric)

**Product:**
- `_isAllProductsCheckAndLogic` ([476](../../lib/changes/singletons/discounts/discount_helpers.dart#L476)) — `isAllProducts=true` yoki `productIds` ichida joriy mahsulot bormi
- `_productPercentage` ([577](../../lib/changes/singletons/discounts/discount_helpers.dart#L577)) — `_priceProd` ni hisoblaydi, agar avval `_priceCat` qo'llangan bo'lsa undan boshlaydi (zanjirli diskont — category dan keyin product)
- `_productNumeric` ([650](../../lib/changes/singletons/discounts/discount_helpers.dart#L650)) — `_priceProd -= discountValue`

### Diskontlar zanjiri (kombinatsiya)

Agar mahsulotga **ham category, ham product** diskonti tegishli bo'lsa:
1. Avval category qo'llanadi: `_priceCat = realPrice * (1 - %)` yoki `_priceCat = realPrice - discountValue`
2. Keyin product `_priceCat` dan boshlab qo'llanadi: `_priceProd = _priceCat * (1 - %)`
3. Yakuniy `_price = _priceProd`

Bu `_priceCat > 0` va `_priceProd <= 0` shartlari orqali aniqlanadi ([qator 595-610](../../lib/changes/singletons/discounts/discount_helpers.dart#L595-L610)).

### `_addDiscount` — diskont yozuvini qo'shish
[discount_helpers.dart:694-721](../../lib/changes/singletons/discounts/discount_helpers.dart#L694-L721)

- `disSum` ni hisoblaydi: numeric uchun `discountValue` ga teng, percentage uchun `price * value / 100`
- `ProductDiscountModel` ni `product.productDiscount` ga qo'shadi (eski idd o'chiriladi, yangi qo'shiladi)
- `addDiscountForProduct(product)` ni chaqiradi — `ItemsSingleton.discounter` orqali `DiscountModel(name: "single", type: "sum")` yaratib `product.discount` ga qo'shadi

### BuyXGetY logikasi
`_getProductIdAndQty` ([197-311](../../lib/changes/singletons/discounts/discount_helpers.dart#L197-L311))

Buy X Get Y kabi murakkab:
- Markirovkali mahsulot **bir xil productId bilan alohida entry** (har biri value=1)
- Box mahsulot **boxValue ga ko'paytirilgan effective qty**
- `totalQtyByProductId` Map orqali umumiy son hisoblanadi
- **Ikki holat:** `productToGet` boshqa mahsulotmi (length1) yoki sotib olinayotgan mahsulot o'zi bilan birga tekin (length2)
- **isRepeatable=true** holatda har `(buy + get)` set uchun get ta tekin (`(totalQty/setSize).floor() * get`)
- **isRepeatable=false** holatda faqat birinchi set uchun

### BuyXGetX logikasi
`_getBuyXGetXAsGift` ([346-414](../../lib/changes/singletons/discounts/discount_helpers.dart#L346-L414))

`forDialogOnly: true` — bo'sag'a yaqinlashganda dialog ko'rsatish uchun (`totalQty + 1 >= buyProductsAmount`). `forDialogOnly: false` — haqiqiy tekin qiymat hisobi (faqat `totalQty >= buy + get` bo'lganda).

`isRepeatable`:
- `true`: `freeQty = (totalQty / (buy + get)).floor() * get`
- `false`: `totalQty >= buy + get` bo'lsa `freeQty = get`, aks holda 0

### Free Gift logikasi
`_getFreeGift` ([416-452](../../lib/changes/singletons/discounts/discount_helpers.dart#L416-L452))

Threshold-based: agar `totalPrice > gift.buyAmount` va `buyAmount > _maxPrice` (eng katta bo'sag'a kuzatuvi — kichiklarini takror chiqarmaslik uchun) bo'lsa, sovg'a ro'yxatga olinadi va `_maxPrice = buyAmount` ga yangilanadi.

### Eligibility tekshiruvlari

**`_checkOptions(dis, clientGroupId)`** ([qator 864](../../lib/changes/singletons/discounts/discount_helpers.dart#L864)) — uchta shart birgalikda:
1. `_checkTheDate(dis)` — sana va vaqt validmi
2. `_checkShopId(dis.shopIds)` — joriy `PrefKeys.storeId` mavjudmi shu diskontning do'kon ro'yxatida
3. Mijoz: `isForAllClients=true` yoki `_checkCustomerGroups(customerGroups, clientGroupId)`

**`_checkTheDate`** ([qator 724](../../lib/changes/singletons/discounts/discount_helpers.dart#L724)):
- `isExpirable=false` bo'lsa har doim true (lekin baribir `startDate` shart)
- `startDate`/`expireDate` ni `T` bilan ajratib, `YYYY-MM-DD` ni parse qiladi
- Yil/oy/kun bo'yicha qatlamli taqqoslash
- Keyin `_checkTheWeek(dis)` ga o'tadi

**`_checkTheWeek`** ([qator 791](../../lib/changes/singletons/discounts/discount_helpers.dart#L791)):
- `discountSchedules` bo'sh — har doim true
- Har schedule uchun `dayOfWeek + 1 == currentWeekday` ni tekshiradi (backend 0-based, Dart 1-based)
- `isWholeDay=false` bo'lsa `startTime`/`endTime` ni soat/minut bo'yicha taqqoslaydi

## OrderingProvider4 integratsiyasi

### State (chegirma uchun)
[ordering_provider_4.dart:970-979](../../lib/changes/providers/ordering_provider_4.dart#L970-L979)

```dart
Map<String, int> _showCount = {};                          // BuyXGetY dialog 1 marta ko'rsatish
Map<String, int> _showCountFreeGift = {};                  // BuyXGetX/FreeGift dialog 1 marta ko'rsatish
Map<String, ReturnedProduct> _returnedProducts = {};       // discountId -> BuyXGetY natija
List<ReturnedGift> _returnedFreeGiftProducts = [];         // FreeGift ro'yxati
List<ReturnedGiftX> _returnedBuyXGetX = [];                // BuyXGetX ro'yxati
Map<String, String> _giftProducts = {};                    // productId -> discountId (joriy gift status)
int _freeGiftDialogCount = 0;
double _newClientPersentageDiscount = 0;                   // Yangi mijoz uchun foiz (clientPercent)
```

### Konstruktorda callback registratsiya
[ordering_provider_4.dart:130-132](../../lib/changes/providers/ordering_provider_4.dart#L130-L132)

```dart
OrderingProvider4() {
  DiscountService.onDiscountsCleared = clearAllDiscountEffects;
}
```

Server'dan barcha diskontlar o'chirilganda (`box.isEmpty`), `DiscountService.discounts()` shu callback'ni chaqiradi va savatdagi har bir mahsulotning chegirmasini tozalaydi.

### `addProduct` oqimi — diskont integratsiyasi
[ordering_provider_4.dart:352-533](../../lib/changes/providers/ordering_provider_4.dart#L352-L533)

```
addProduct() boshlandi:
1. Savat bo'sh bo'lsa — barcha gift state'larni tozala, DiscountSingleton.maxPrice()
2. Markirovkali bo'lsa → marking() ga o'tadi (qaytariladi)
3. Aks holda: _handleRegularProduct()
   ├─ _updateExistingProduct() yoki _addNewProduct()
   └─ _applyDiscounts(product, soldItem)
      ├─ isPriceOnlyChanged bo'lsa — qaytariladi (qo'lda narx o'zgartirilgan)
      ├─ DiscountSingleton.addDiscountOnProduct(soldItem, categoryId, getClientGroupId)
      └─ Agar _newClientPersentageDiscount > 0 — yangi mijoz foizini qo'llash
4. DiscountSingleton.productId(product.id)  ← UI dialog uchun
5. findFreeProducts() chaqirilib:
   ├─ DiscountSingleton.maxPrice()
   ├─ _findFreeGiftProducts() → DiscountSingleton.buyXGetYOrFreeGifts(...isGift=true)
   ├─ _findBuyXGetXProducts() → DiscountSingleton.getBuyXGetXDiscounts(...)
   └─ BuyXGetY ro'yxatini _returnedProducts ga yozish
6. UI dialoglar:
   ├─ "Buy X Get Y" — DiscountSingleton.availableDiscount mavjud bo'lsa → ContainsDiscountItemDialog
   └─ "Buy X Get X" — _returnedBuyXGetX da product.id mavjud bo'lsa → ContainsDiscountItemDialog2
7. freeGiftDialog() — _returnedFreeGiftProducts bo'yicha FreeGift dialog
8. Diskontlarni amalda qo'llash:
   ├─ useFreeProducts()      (BuyXGetY narxni o'zgartiradi)
   ├─ useFreeGiftProducts()  (FreeGift narxni o'zgartiradi)
   └─ useBuyXGetXProducts()  (BuyXGetX narxni o'zgartiradi)
```

### `useFreeProducts` — BuyXGetY ni amalda qo'llash
[ordering_provider_4.dart:1033-1146](../../lib/changes/providers/ordering_provider_4.dart#L1033-L1146)

Eng murakkab algoritm:
1. Har bir BuyXGetY uchun:
   - `isSameProduct` (X va Y bir xil mahsulotmi) ni aniqlash
   - **Threshold check:** bir xil mahsulot bo'lsa `totalQty >= mustQty + returnedQty`, boshqa bo'lsa `nonGiftTotal >= mustQty`
2. Agar threshold qondirilmagan — shu productId qatorlaridagi diskontni tozalash
3. **`firstTierPrice`** — `onePrice(shopPrices)` orqali olinadi (1-chi minQuantity narxi). BuyXGetY da pog'onali narx **bekor qilinadi** — 1-chi tier narxidan hisoblanadi
4. **Box-aware sort:** `saleType=2` box itemlar oldin (katta effectiveQty), keyin oddiy itemlar
5. **Free quota taqsimoti:**
   - Har item uchun `itemQty = saleType==2 ? value*boxValue : value`
   - `effectiveFree = min(freeLeft, itemQty)`
   - `paidQty = itemQty - effectiveFree`
   - `price = realPrice * (paidQty/itemQty)`
   - `singleDiscount = realPrice * effectiveFree / itemQty`
   - `discountPercent = 100 - (paidQty/itemQty) * 100`
6. `ProductDiscountModel(typeName: 'Buy X Get Y')` yoziladi

### `useBuyXGetXProducts` — BuyXGetX ni amalda qo'llash
[ordering_provider_4.dart:1220-1364](../../lib/changes/providers/ordering_provider_4.dart#L1220-L1364)

Ikki holatga ajratilgan:
- **Bitta qator (oddiy mahsulot):** `setSize = buy + get`, isRepeatable bo'lsa har set uchun, aks holda faqat 1 set
- **Bir nechta qator (markirovka yoki bir nechta box):** teskari iteratsiya, har item uchun **naturalCap** — box uchun `(itemQty / perSetSize).floor() * perSetGet` (toshib ketgan free slot'lar individual item'larga uzatiladi)

`firstTierPrice` ham shu yerda 1-talik narxga qaytariladi (3-talik chegirma yo'qoladi BuyXGetX bilan).

### `useFreeGiftProducts` — Free Gift ni amalda qo'llash
[ordering_provider_4.dart:1147-1218](../../lib/changes/providers/ordering_provider_4.dart#L1147-L1218)

- `_returnedFreeGiftProducts` bo'sh bo'lsa — `_giftProducts` Map'ida bor itemlarni reset
- Har gift uchun `nonGiftTotal` (gift mahsuloti bo'lmagan boshqalar yig'indisi) hisoblanadi
- `nonGiftTotal >= gift.buyAmount` bo'lsa — `gift.getProductAmount` ta tekin beriladi
- Threshold qondirilmasa — gift itemlarni reset

### `freeGiftDialog` — sovg'a ogohlantirish UI
[ordering_provider_4.dart:2380-2432](../../lib/changes/providers/ordering_provider_4.dart#L2380-L2432)

- Har gift uchun bitta marta `ContainsDiscountItemDialog2` ko'rsatiladi (`_showCount[productId]` orqali)
- `gift.isGetX` flag'i orqali matn farqlanadi
- Foydalanuvchi gift mahsulotini qo'shganda dialog qaytib chiqmaydi (count == 1)

### `removeLastAdded` va `pressDialogDeleteButton` — diskont state cleanup
[ordering_provider_4.dart:304-346, 2279-2370](../../lib/changes/providers/ordering_provider_4.dart#L304-L346)

Mahsulot o'chirilganda: agar shu `productId` dan boshqa qatorlar qolmagan bo'lsa, `_showCount` va `_showCountFreeGift` Map'laridan ham o'chiriladi (dialog yana ko'rsatilishi uchun, agar mahsulot keyin qaytadan qo'shilsa).

### `pressDialogSaveButton` — tahrirdan keyin qayta hisoblash
[ordering_provider_4.dart:2241-2253](../../lib/changes/providers/ordering_provider_4.dart#L2241-L2253)

Mahsulot tahrir qilingach (`OperationOnProduct` dialog'idan keyin):
```dart
findFreeProducts();
useFreeProducts();
useFreeGiftProducts();
useBuyXGetXProducts();
```
Bu **diskont qayta hisoblash uchun standart 4-qadam ketma-ketlik** — savatga ta'sir qiluvchi har bir operatsiyadan keyin chaqiriladi.

## Box mahsulot diskonti
[ordering_provider_4.dart:2150-2231](../../lib/changes/providers/ordering_provider_4.dart#L2150-L2231)

Box mahsulot (`saleType: 2`):
- `boxValue` = ichidagi donalar soni (`boxBarcodeQuantity`)
- `boxPrice = unitPrice * boxValue`
- `value: 1` (bitta box), `boxQuantity: existingCount + 1`
- Box qo'shilgach `findFreeProducts → useFreeProducts/FreeGift/BuyXGetX` ketma-ketligi chaqiriladi
- Diskont hisoblarida `effectiveQty = saleType==2 ? value*boxValue : value` — bu butun fayl bo'ylab takrorlanadi

**Box-aware sort** — `useFreeProducts`'da box itemlar avval ishlanadi (katta qty), individual itemlar keyin. Bu free quota'ni eng samarali taqsimlash uchun.

## DiscountService — backend bilan integratsiya
[discount_service.dart](../../lib/changes/services/discount_service.dart)

| Metod | Vazifa |
|-------|--------|
| `findDiscounts()` | `GET /api/v1/company_discounts_for_pos?shop_ids=<storeId>` |
| `discounts()` | Backend dan olib Hive `box.clear() → box.put(id, item)`. `box.isEmpty` bo'lsa `onDiscountsCleared` callback |
| `createDiscount(item)` | `box.put(id, item)` |
| `updateDiscount(item)` | `containsKey` bo'lsa `put` |
| `deleteDiscount(id)` | `box.delete(id)` |

`onDiscountsCleared` callback — `OrderingProvider4` ga ulanadi (`clearAllDiscountEffects`).

## DiscountWsService — real-time sync
[discount_ws_service.dart](../../lib/changes/services/web_socket_service/discount/discount_ws_service.dart)

Notification API'dan WebSocket-style polling:
- `GET {baseNotificationUrl}notifications?company_id=...&type=15,16,17&is_read=false&start_date=...&end_date=...`
- **Type 15:** yangi diskont yaratish → `DiscountService.createDiscount`
- **Type 16:** diskont yangilanish → `DiscountService.updateDiscount`
- **Type 17:** diskont o'chirish → `DiscountService.deleteDiscount`

## Chek darajasidagi diskont (chek total chegirmasi)
[discount_type_status.dart](../../lib/features/home/features/home_orders/calculation_part/total_price_dialog/discount_type_status.dart) + [pressPaymentButton](../../lib/changes/providers/ordering_provider_4.dart#L2643-L2654)

Foydalanuvchi to'lov ekranida butun chekka diskont qo'shishi mumkin:
- **`DiscountTypeStatus.disTypeStatus = TpStatus.summa`** — total summa kiritiladi (`DiscountTypeStatus.summa`). Diskont = `summa - totalPrice` (manfiy bo'lsa qarz qoldiq deb hisoblanadi)
- **`DiscountTypeStatus.disTypeStatus = TpStatus.discount`** — foiz kiritiladi (`_currentClient.discountPercent`)
- Default: `TpStatus.discount`, `discountID = "9a2aa8fe-..."` (default placeholder)

Sotuv tugagach `DiscountTypeStatus.disTypeStatus = TpStatus.discount` ga qaytariladi (qator 2655, 2892).

## Mijoz darajasidagi diskont

### Mijoz tanlanganda
[ordering_provider_4.dart:3145](../../lib/changes/providers/ordering_provider_4.dart#L3145)

```dart
String get getClientGroupId => _currentClient.selectedClient?.groupId ?? "";
```

Mijoz tanlangach uning `groupId` `addDiscountOnProduct` va `buyXGetYOrFreeGifts` ga `clientGroupId` sifatida uzatiladi → faqat shu mijoz guruhi uchun mo'ljallangan diskontlar qo'llanadi.

### "Yangi mijoz" diskonti (manual percentage)
[ordering_provider_4.dart:177-203](../../lib/changes/providers/ordering_provider_4.dart#L177-L203)

`setNewClientDiscountPercentage(double percentage)`:
- Savatdagi har mahsulotda `discount.type == "sum"` ni olib tashlaydi
- Yangi diskontni `DiscountFromWhere.client` bilan qo'shadi
- `price = (price/100) * (100 - percentage)`
- `isPriceChanged = true` (chegirma endi avtomatik qayta hisoblanmaydi)

Bu maxsus diskont **avtomatik diskontlardan keyin** qo'llanadi (`_applyDiscounts` ichida).

## Qabul qilingan qarorlar

- **UUID-based discount classification:** chegirma turi enum o'rniga backend UUID'lari bilan tanib olinadi. Sabab: backend istalgan vaqtda yangi tur qo'shishi mumkin va frontend recompilation kerak emas. Lekin yangi tur qo'shilsa kodga manual UUID qo'shish zarur (hozircha ro'yxat statik).
- **Static state in DiscountHelpers (`_priceCat`, `_priceProd`, `_price`)** — multi-threading risk yo'q (UI thread only) va bitta `addDiscountOnProduct` chaqiruvi atomar. Lekin **sinov qiyin** — refactor kelajakda kerak bo'lishi mumkin.
- **`isPriceOnlyChanged` qo'lda narx o'zgartirilgan mahsulotlar uchun diskont qo'llanmaydi** — sabab: kassir aniq narx kiritsa, undan tushum o'zgarmasligi kerak. `_applyDiscounts` ichida birinchi tekshiruv.
- **BuyXGetY va BuyXGetX `firstTierPrice` ga qaytadi** ([useFreeProducts:1072-1075, useBuyXGetXProducts:1253-1258](../../lib/changes/providers/ordering_provider_4.dart#L1072-L1075)) — sabab: agar 3 ta olganda 5000 so'mga tushadigan pog'onali narx bo'lsa va 3 dan birini tekin bersak, qolgan 2 tasi 1-talik narxda hisoblansin (aks holda diskont noto'g'ri ishlaydi).
- **`isRepeatable` qator: backend opsiyasi** — BuyXGetY/BuyXGetX/FreeGift uchun "har takror set'da yana sovg'a beriladimi" ni belgilaydi. Agar `true` bo'lsa, masalan 10 ta sotib olinsa va `buy=2, get=1` bo'lsa, 3 ta tekin (har 3 talik set'da 1 ta).
- **Free Gift uchun `_maxPrice` kuzatuvi** — bir nechta bo'sag'a (5000+, 10000+) bor bo'lsa, eng kattasi qo'llanadi (kichigi avval qondiriladi, lekin keyin kattasi qondirilganda kichigi takror chiqarilmaydi).
- **Dialog 1 marta ko'rsatish (`_showCount`, `_showCountFreeGift`)** — har mahsulot uchun bir marta. Mahsulot savatdan butunlay olib tashlansa, hisob reset (kassir uni qaytadan qo'shsa yana ko'rinadi).

## Diqqatga loyiq joylar

- **`addDiscountOnProduct` har mahsulot qo'shilganda chaqiriladi** — N mahsulot uchun N × M diskont iteratsiya, ya'ni O(N×M). 100 diskont + 50 mahsulot uchun 5000 ta loop iteratsiya. Hozircha samarali, lekin diskontlar 500+ ga yetsa, optimallashtirish (index by product/category) o'ylash mumkin.
- **`_priceCat`, `_priceProd` har chaqiruvda 0 ga reset qilinmaydi avtomatik** — `addDiscountOnProduct` ichida explicit `_priceCat = 0; _priceProd = 0;` ([qator 78-79](../../lib/changes/singletons/discounts/discount_helpers.dart#L78-L79)). Agar yangi diskont turi qo'shilsa, bu reset ham yangilanishi kerak.
- **`_addDiscount` ichida `disSum = isNumeric ? discountValue : product.price * discountValue / 100`** ([qator 702](../../lib/changes/singletons/discounts/discount_helpers.dart#L702)) — `product.price` bu yerda `_price` ga teng emas, bu mahsulotning chaqiruvgacha bo'lgan narxi. Tekshirib turish kerak.
- **`marking()` oqimida ham diskontlar qo'llanadi** — markirovkali mahsulot bir xil productId bilan ko'p marta qo'shiladi (har biri value=1). BuyXGetY va BuyXGetX algoritmlari buni hisobga oladi (`saleType==1` uchun jami qty ni hisoblaydi).
- **`isPriceChanged` va `isPriceOnlyChanged` farqi:**
  - `isPriceChanged` — narx o'zgartirilgan (klient diskonti yoki manual), lekin avtomatik diskontlar baribir qo'llanishi mumkin
  - `isPriceOnlyChanged` — narx **faqat** foydalanuvchi tomonidan o'zgartirilgan (uchenkadan), avtomatik diskontlar **qo'llanmaydi**
- **Hardcoded UUID-larning kelajagi** — agar backend yangi diskont turi (masalan "Pre-order discount") qo'shsa, kod yangilanmasa diskont ishlamaydi. Bu **texnik qarz** lekin hozircha amaliy.

## Test / Verifikatsiya

**Stabil ishlaydi prodda (deyarli 1 yil):**
- Mahsulot diskonti (foiz va raqamli) — har xil kombinatsiyalarda
- Kategoriya diskonti — `isAllProducts=false` filtri bilan
- Buy X Get Y — bir xil va boshqa mahsulot, `isRepeatable` bilan ham
- Buy X Get X — oddiy va markirovkali, box mahsulot bilan
- Free Gift — bir nechta bo'sag'a
- Sana/hafta/soat eligibility
- Mijoz guruhi filtri
- Box mahsulot bilan diskont — `boxValue * value` to'g'ri hisoblanadi
- WebSocket real-time sync (15/16/17)
- Server'dan barcha diskontlar o'chirilganda savat tozalanishi

**Kelajakda ehtimoliy savollar (bugfix bo'lsa yangi sessiya hujjati):**
- Yangi diskont turi qo'shilsa (UUID + helper metodlari)
- 500+ diskont uchun performance optimallashtirish
- Static state'dan instance-based ga refactor
- Diskont kombinatsiyasi (zanjirli) uchun yanada aniq priority qoidalari

---

**Bu hujjat read-only arxiv.** Diskont tizimida muammo yoki o'zgarish kerak bo'lsa, **yangi sessiya hujjati ochiladi** (`docs/sessions/YYYY-MM-DD-discount-<konkret-task>.md`), uning `## Avvalgi implementatsiya` bo'limida shu faylga link beriladi, va bu fayl yuqorisiga `⚠️ Superseded by: ...` qatori qo'shiladi.
