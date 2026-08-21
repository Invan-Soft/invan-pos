# Task: Chegirma oqimlarida "eski holat" (stale state) — shart buzilgach tekin narx qolib ketishi

**Boshlangan:** 2026-08-21
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad

"A olsang B tekin" (Buy X Get Y) chegirmasida A savatdan o'chirilganda B yana
pulli bo'lishi kerak. Hozir bu faqat savatda **boshqa hech narsa bo'lmaganda**
ishlaydi. A ni o'chirishdan oldin savatga chegirmaga aloqasi yo'q boshqa
product qo'shilgan bo'lsa, A o'chirilgandan keyin ham B tekinligicha qolib
ketadi va chek kam summaga yopiladi.

## Takrorlash qadamlari (bug)

1. A (buy product) × 2 qo'shiladi
2. B (get product) × 1 qo'shiladi → B narxi 0 bo'ladi ✔
3. Savatga C (chegirmaga aloqasi yo'q har qanday product) qo'shiladi
4. A o'chiriladi
5. **Kutilgan:** B yana o'z narxida. **Amalda:** B hali ham 0 ❌

Agar 3-qadam bajarilmasa (savatda faqat A va B bo'lsa) bug ko'rinmaydi.

## Scope

- `lib/changes/providers/ordering/discount_effects_controller.dart`
  → `findFreeProducts`, `useFreeProducts`
- `lib/changes/singletons/discounts/discount_helpers.dart`
  → `_getProductIdAndQty` (red-delete filtri)
- `test/discount_free_products_test.dart` (regressiya testlari)
- `test/discount_buy_x_get_x_test.dart`, `test/discount_free_gift_test.dart`
  (keng qidiruvdan keyin qo'shildi — pastga qarang)
- Scope dan tashqari: product/kategoriya foizli chegirmalari, BonusPoint

## Ildiz sabab

Ikkita mustaqil nuqson birgalikda bug'ni yuzaga keltirgan.

### 1. `returnedProducts` xaritasi hech qachon tozalanmagan (asosiy sabab)

`findFreeProducts` ([discount_effects_controller.dart:63-79](../../lib/changes/providers/ordering/discount_effects_controller.dart#L63-L79)):

```dart
final found = DiscountSingleton.buyXGetYOrFreeGifts(...) ?? [];
if (found.isEmpty) return;          // ← eski yozuv xaritada QOLADI
for (final product in found) { returnedProducts[discountId] = product; }
```

A savatdan chiqarilgach `DiscountHelpers._getProductIdAndQty` to'g'ri `null`
qaytaradi (`length1 != productsToBuy.length`), demak `found` bo'sh bo'ladi.
Ammo erta `return` tufayli avvalgi yozuv `returnedProducts` da qolib ketadi va
`useFreeProducts` o'sha eski yozuv bo'yicha B ni tekin qilishda davom etadi.

Diqqat: `findFreeGiftProducts` va `findBuyXGetXProducts` ro'yxatni har safar
to'liq qayta tayinlaydi — shuning uchun nuqson faqat Buy X Get Y da.

### 2. Himoya sharti PUL summasini DONA soni bilan solishtirgan

`useFreeProducts` dagi `isSameProduct == false` shoxi:

```dart
final nonGiftTotal = orderedProducts
    .where((p) => p.productId != returnedProductId && !p.isPriceOnlyChanged)
    .fold<num>(0, (sum, p) => sum + p.realPrice * p.value);  // ← PUL
thresholdMet = nonGiftTotal >= mustQty;                       // ← DONA soni
```

`mustQty` = `buyProductsAmount` (masalan 2 dona). `nonGiftTotal` esa savatdagi
**barcha boshqa** productlarning **so'mdagi** summasi. Savatda 15 000 so'mlik
aloqasiz product bo'lishi kifoya: `15000 >= 2` → shart "bajarilgan".

Bu himoya (1) nuqsonni faqat savat bo'sh bo'lgandagina ushlab qolardi
(`nonGiftTotal = 0 >= 2` → false) — shuning uchun bug "boshqa product qo'shilsa"
degan g'alati shartga bog'liq ko'rinardi.

### 3. Red-delete rejimi (yondosh nuqson)

`_getProductIdAndQty` savatdagi qatorlarni sanaganda `isDeleted` ni
tekshirmasdi. Red-delete yoqilgan kassalarda o'chirilgan qator savatda qoladi
(`isDeleted = true`) va chegirma shartini qondirishda davom etardi.

## Keng qidiruv — o'xshash nuqsonlar (2-bosqich)

Asosiy bug tuzatilgach "shu nuqson sinfi boshqa qayerda bor?" degan savol
bo'yicha uch oqimga 10 ta zond (probe) testi yozildi. **4 tasi yiqildi** —
hammasi bir xil sabab: *shart buzilgach savat qatorini hech kim tiklamaydi.*

| # | Oqim | Stsenariy | Natija |
|---|------|-----------|--------|
| P2 | Buy X Get X | diskont bazadan o'chirildi (WS type 17 / muddat tugashi) | qator 8 000 da qotib qoldi |
| P4 | Buy X Get Y | diskont bazadan o'chirildi | B 0 so'mda qoldi |
| P9 | Free Gift | ikki bosqich, yuqori bosqich tushib qoldi | yuqori sovg'a tekinligicha qoldi |
| P10 | Free Gift | red-delete: asosiy tovar o'chirildi | sovg'a tekinligicha qoldi |

O'tgan zondlar: P1 (BXGX qty kamayishi), P3 (BXGX red-delete), P5 (ikkita
buy-product, bittasi o'chirildi), P6 (same-product BXGY qty kamayishi),
P7/P8 (Free Gift diskont o'chirilishi / asosiy tovar chiqarilishi).

### P4 — eng xavflisi: query funksiyasi savatni buzib tashlardi

`DiscountHelpers.buyXGetYOrFreeGifts` boshida:

```dart
if (box.isEmpty) {
  for (var p in products) {
    p.discount.clear();
    p.productDiscount.clear();   // ← belgi YO'Q QILINADI
    p.singleDiscount = 0;
  }
  return null;                    // ← lekin `price` TIKLANMAYDI
}
```

Ya'ni barcha diskontlar o'chirilganda: narx chegirmali holicha qoladi, ustiga
`productDiscount` tozalangani uchun kontroller uni "eski chegirma" deb taniy
ham olmaydi. 1-bosqichdagi `_clearStale` tuzatishi ham bu holatda ishlamasdi —
belgisi allaqachon o'chirilgan bo'lardi.

### P9 — bekor qilish faqat "ro'yxat butunlay bo'sh" bo'lganda ishlardi

`useFreeGiftProducts` da eski bekor qilish sharti
`if (returnedFreeGiftProducts.isEmpty)` edi. Bosqichlar bo'lganda (50k → B,
100k → G) savat 100k dan pastga tushsa ro'yxat bo'sh bo'lmasdi (pastki bosqich
qoladi) va G tekinligicha qolib ketardi.

## Bajarilgan

- [x] Bug xarakteristik test bilan takrorlandi (BASELINE o'tadi, bug case yiqiladi)
  → `test/discount_free_products_test.dart`
  → Sabab: "faqat A+B" holati ishlagani uchun ildiz sabab noaniq edi — ikkala
    stsenariyni yonma-yon qo'yish (1) nuqsonni (2) dan ajratib berdi

- [x] `findFreeProducts` xaritani har safar noldan qayta quradi
  → [discount_effects_controller.dart:63-85](../../lib/changes/providers/ordering/discount_effects_controller.dart#L63-L85)
  → Sabab: erta `return` o'rniga `rebuilt` xaritasini tayinlash — eski yozuvlar
    o'z-o'zidan yo'qoladi, qo'shimcha "invalidate" mantig'i kerak emas

- [x] `useFreeProducts` amal qilmay qolgan qatorlarni tozalaydi
  → [discount_effects_controller.dart:116-119](../../lib/changes/providers/ordering/discount_effects_controller.dart#L116-L119)
    (`_clearStaleBuyXGetY`, [:496](../../lib/changes/providers/ordering/discount_effects_controller.dart#L496))
  → Sabab: xarita bo'shatilgandan keyin `if (returnedProducts.isEmpty) return;`
    ishga tushadi va savatdagi tekin qator hech kim tomonidan tiklanmay qolardi.
    Tozalash shu erta `return` dan OLDIN bajarilishi shart.
  → Chegirma yozuvi `productDiscount` dagi `typeName == 'Buy X Get Y'` bo'yicha
    aniqlanadi; `resetItemDiscount` bu faylning boshqa joylarida ham xuddi shu
    maqsadda ishlatiladi

- [x] Threshold sharti dona-hisobga o'tkazildi
  → [discount_effects_controller.dart:148-167](../../lib/changes/providers/ordering/discount_effects_controller.dart#L148-L167)
    (`_cartQtyOf`, [:485](../../lib/changes/providers/ordering/discount_effects_controller.dart#L485))
  → Sabab: `_getProductIdAndQty` dagi asl shart bilan mos bo'lishi kerak — har
    bir `productsToBuy` savatda `buyProductsAmount` dona bo'lishi. Pul summasi
    bu chegirma turiga umuman aloqador emas edi.

- [x] Red-delete: `isDeleted` qatorlar qty hisobidan chiqarildi
  → [discount_helpers.dart:216-222](../../lib/changes/singletons/discounts/discount_helpers.dart#L216-L222)
  → Sabab: o'chirilgan qator sotilmaydi, demak chegirma shartini ham
    qondirmasligi kerak

- [x] 5 ta regressiya testi qo'shildi
  → `test/discount_free_products_test.dart` → group "Buy productni savatdan chiqarish"

### 2-bosqich (keng qidiruvdan keyin)

- [x] P4: `buyXGetYOrFreeGifts` endi savatni O'ZGARTIRMAYDI (faqat o'qiydi)
  → [discount_helpers.dart:117-135](../../lib/changes/singletons/discounts/discount_helpers.dart#L117-L135)
  → Sabab: savatni tozalash kontroller zimmasida. Query funksiyasining
    yon ta'siri belgini yo'q qilib, tiklashning oldini olardi.

- [x] P2: `useBuyXGetXProducts` erta `return` dan oldin eski qatorlarni tozalaydi
  → [discount_effects_controller.dart:341-345](../../lib/changes/providers/ordering/discount_effects_controller.dart#L341-L345)

- [x] `_clearStaleBuyXGetY` → umumiy `_clearStale(cart, typeName, activeIds)`
  → [discount_effects_controller.dart:506](../../lib/changes/providers/ordering/discount_effects_controller.dart#L506)
  → Sabab: BuyXGetY va BuyXGetX uchun bir xil mantiq — ikki nusxa saqlanmadi

- [x] P9: Free Gift bekor qilish "faol sovg'alar to'plami" bo'yicha ishlaydi
  → [discount_effects_controller.dart:257-277](../../lib/changes/providers/ordering/discount_effects_controller.dart#L257-L277)
  → Sabab: `isEmpty` sharti bosqichli diskontlarda yetarli emas. Yangi mantiq
    `isEmpty` holatini ham o'z ichiga oladi (faol to'plam bo'sh bo'ladi).

- [x] P10: o'chirilgan (red-delete) qatorlar barcha hisob-kitoblardan chiqarildi
  → `totalPriceForAll`, `nonGiftTotal`, `giftItems`, `eligibleItems`,
    BuyXGetX `items`, `_getBuyXGetXAsGift` totalQty

- [x] 7 ta regressiya testi qo'shildi (zond testlari doimiy fayllarga ko'chirildi)
  → `test/discount_buy_x_get_x_test.dart` → group "Shart buzilgach tekin ulush bekor bo'ladi" (3 ta)
  → `test/discount_free_gift_test.dart` → group "Shart buzilgach sovg'a bekor bo'ladi" (4 ta)

## Keyingi qadamlar (prioritet bo'yicha)

- [ ] Windows'da real do'kon sinovi: A+B → C qo'shish → A o'chirish → B narxi tiklanishi
- [ ] Red-delete yoqilgan kassada ham shu stsenariy (BXGY, BXGX, Free Gift)
- [ ] Bosqichli Free Gift (50k/100k): summani pasaytirib yuqori sovg'a bekor bo'lishi
- [ ] Blok (saleType == 2) va markirovkali A bilan tekshirish
- [ ] Sinovdan keyin commit + release

## Qabul qilingan qarorlar

- **Xaritani invalidate qilish emas, qayta qurish.** `returnedProducts` ni har
  `findFreeProducts` da noldan yig'ish — "qachon eskiradi?" degan savolni
  butunlay yo'q qiladi. Nuqtali invalidatsiya har yangi o'chirish/tahrirlash
  yo'lida yana unutilishi mumkin edi.
- **`resetItemDiscount` ishlatildi** (faqat Buy X Get Y yozuvini olib tashlash
  emas). Sabab: bu faylning mavjud `!thresholdMet` shoxi ham aynan shunday
  qiladi — izchillik saqlandi. Cheklovi: qatorda boshqa product/kategoriya
  chegirmasi ham bo'lsa u ham tozalanadi (mavjud xatti-harakat).
- **Query funksiyasi savatni o'zgartirmaydi.** `buyXGetYOrFreeGifts` faqat
  o'qiydi; savatni tozalash bir joyda — kontrollerda. Yon ta'sirli "tozalash"
  aynan tiklanishning oldini olgan edi.
- **Bitta umumiy `_clearStale`** BuyXGetY va BuyXGetX uchun — belgi sifatida
  `productDiscount.typeName` ishlatiladi.
- **Free Gift bekor qilish "faol to'plam" bo'yicha**, `isEmpty` bo'yicha emas —
  bosqichli diskontlar uchun yagona to'g'ri variant.

## Ochiq savollar

- `resetItemDiscount` qatordagi BARCHA `productDiscount` yozuvlarini tozalaydi.
  Agar qatorda bir vaqtda product/kategoriya foizli chegirmasi ham bo'lsa, u ham
  yo'qoladi va faqat `_repriceProductRowsByTotalUnits` chaqirilgan yo'llarda
  qayta tiklanadi. Bu mavjud xatti-harakat (o'zgartirilmadi) — do'kon sinovida
  shunday holat uchrasa alohida task ochiladi.

## Test / Verifikatsiya

- `flutter test test/discount_free_products_test.dart` → 15/15 o'tdi
  (10 ta eski + 5 ta yangi)
- `flutter analyze` (o'zgargan 3 fayl) → yangi ogohlantirish yo'q
  (bitta info oldin ham bor edi: `avoid_function_literals_in_foreach_calls`,
  `findBuyXGetXProducts` dagi bo'sh `forEach`)
- Uch chegirma fayli → 42/42 o'tdi (10 ta eski + 12 ta yangi regressiya + ...)
- `flutter test` (29 fayl, cashback'dan tashqari) → **476/476 o'tdi**
- To'liq `flutter test` → 460 o'tdi, 1 ta yiqilish:
  `cashback_balance_test.dart` `tearDownAll` (Hive yopilishida osilib qoladi).
  Bu yiqilish **bu task'ga aloqasi yo'q** — o'zgarishlar `git stash` qilinganda
  ham aynan takrorlanadi. O'sha fayldagi 16 ta testning hammasi o'tadi.
