# Task: Blok (box) sotishda tier narx ishlashi

**Boshlangan:** 2026-07-10
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Blok shtrix-kodi skanerlanganda narx doim 1-tier (1 dona narxi) dan hisoblanardi.
Misol: tier'lar 1 ta→5000, 2 ta→3000, 4+→2000 bo'lsa, 6 talik blok 6×5000=30000
bo'lib tushardi. To'g'risi: blok ichidagi dona soni (6) qaysi tier'ga tushsa
(4+ → 2000), har bir dona o'sha narxdan → 6×2000=12000.

## Scope
- `_addBoxProduct()` — blok qo'shishda tier tanlash (asosiy fix)
- `ItemsSingleton.getBaseTotalPrice()` / `getItemBasePrice()` — blok qatorini
  (saleType == 2) hisobga olish, aks holda SKIDKA ko'rsatkichi va umumiy-diskont
  dialogi noto'g'ri baza olardi
- Scope'dan tashqari: OPD (tahrirlash dialogi) blok qatorini qayta narxlashi —
  alohida pre-existing muammo (pastda, Ochiq savollar)

## Bajarilgan
- [x] Blok qo'shishda tier blok ichidagi dona soni bo'yicha tanlanadi
  → lib/changes/providers/ordering_provider_4.dart:~2200 (`_addBoxProduct`)
  → Sabab: `finalPrice(freshProduct, 1, isKg)` doim 1-tier qaytarardi;
    endi `finalPrice(freshProduct, boxValue, isKg)` — boxValue dona uchun tier
- [x] getBaseTotalPrice blok-qatorga moslandi (units = value × boxValue)
  → lib/features/get_products/singletons/items_singleton.dart:~131
  → Sabab: SKIDKA (calculation_part.dart:38) va tp_bloc baza narxni blok uchun
    1 dona deb hisoblardi → manfiy/noto'g'ri skidka ko'rsatilardi
- [x] getItemBasePrice blok-qatorga moslandi (tier(units) × boxValue)
  → lib/features/get_products/singletons/items_singleton.dart:~147
  → Sabab: tp_bloc.dart:106 diskont bekor qilinganda narxni shu helper'dan
    tiklaydi — blok qatori 1 dona narxiga tushib qolardi
- [x] flutter analyze — yangi xato yo'q (faqat pre-existing info-lintlar)
- [x] OPD dialogida blok qatori qty'sini oshirish butunlay bloklandi
  → lib/changes/providers/operation_on_product_provider.dart (`increaseQuantity`
    va `onCountChanged` boshida `saleType == 2` guard)
  → lib/features/home/features/operation_on_product/opd_center/components/opd_value.dart
    (+ tugma blok qatorida disabled)
  → Sabab: qty o'zgarsa OPD narxni `finalPrice(item, value)` bilan qayta
    hisoblab blok narxini 1 dona narxiga buzardi. Foydalanuvchi qarori:
    blok qty'si umuman oshirilmaydi, yangi blok skanerlanadi
- [x] Minus tugma blok qatorini o'chiradi — allaqachon shunday ishlardi
  (opd_value.dart:110: value <= 1 → pressDialogDeleteButton), o'zgartirilmadi
- [x] OPD nusxasiga saleType/boxValue/boxQuantity ko'chirildi
  → lib/features/home/features/operation_on_product/operation_on_product.dart
  → Sabab: nusxada bu maydonlar yo'q edi — blok qatori tahrirlanib saqlansa
    oddiy qatorga (saleType=1, boxValue=0) aylanib qolardi
- [x] Saqlashda blok qatoriga _applyDiscounts qayta qo'llanmaydi
  → lib/changes/providers/ordering_provider_4.dart (`pressDialogSaveButton`,
    `item.saleType != 2` sharti)
  → Sabab: _addBoxProduct blok qo'shishda _applyDiscounts chaqirmaydi —
    saqlashda ham izchil bo'lishi kerak

- [x] Tier endi savatdagi UMUMIY son bo'yicha (yangi biznes qoida, foydalanuvchi
  screenshot case'i: 3 blok(12) + 1 dona → dona ham 3-tier 1800 bo'lishi kerak)
  → lib/changes/providers/ordering_provider_4.dart (`_repriceProductRowsByTotalUnits`
    markaziy helper, _addBoxProduct dan oldin joylashgan)
  → Ulangan joylar: addProduct (dona qo'shish), _addBoxProduct (blok qo'shish),
    pressDialogSaveButton (OPD saqlash), pressDialogDeleteButton, _deleteMarkGroup,
    _saveMarkGroup (qty kamaytirish), removeLastAdded (2 branch), markirovka add
    oqimi (eski 2 ta loop shu helper bilan almashtirildi)
  → Qoida: umumiy son = Σ(dona value + blok value×boxValue); tierUnit shu songa;
    dona qatoriga tierUnit, blok qatoriga tierUnit×boxValue; isPriceOnlyChanged
    qatorlarga tegilmaydi; dona qatorlariga _applyDiscounts qayta qo'llanadi
- [x] KRITIK yashirin bug: dona skani blok qatoriga qo'shilib ketishi mumkin edi
  → _handleRegularProduct indexWhere ga `e.saleType != 2` qo'shildi
  → Sabab: blok qatori (isPriceOnlyChanged=false) merge shartiga tushardi —
    dona skanida blok value=2 bo'lib narxi buzilardi
- [x] getBaseTotalPrice/getItemBasePrice umumiy-son qoidasiga o'tkazildi
  → items_singleton.dart (_rowUnits + _totalUnitsOf helperlar,
    getItemBasePrice ga ixtiyoriy allRows param)
  → Callerlar yangilandi: setNewClientDiscountPercentage, tp_bloc:106
- [x] flutter analyze — yangi xato yo'q

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows'da real test: tier'li mahsulot blok shtrix-kodini skanerlash →
      narx blok ichidagi soniga mos tier'dan bo'lishi kerak (6 ta × 2000 = 12000)
- [ ] Test: blok savatda ekanida SKIDKA ko'rsatkichi 0 bo'lishi (avval manfiy chiqardi)
- [ ] Test: umumiy diskont dialogida diskont qo'yib keyin 0 qilinsa blok narxi
      to'g'ri tiklanishi (tp_bloc.dart:106)
- [ ] Test: blok qatorini OPD da ochish — + tugma disabled, klaviaturadan qty
      kiritilmaydi, minus bosilsa qator o'chadi, saqlansa blok narxi o'zgarmaydi
- [ ] Test (screenshot case): 3 blok(12) skanerlash + 1 dona skanerlash →
      dona 1800 bo'lishi (2000 emas); teskari tartibda ham (dona → blok →
      dona 2000→1800 ga tushishi)
- [ ] Test: blok o'chirilganda qolgan dona narxi qayta ko'tarilishi (1800→2000)
- [ ] Test: umumiy son chegara: 11 dona=2-tier, 12-chi dona qo'shilganda
      hammasi 3-tier ga tushishi

## Qabul qilingan qarorlar
- ~~Tier har blok-qator o'zicha (boxValue bo'yicha)~~ **BEKOR — yangi qoida:**
  tier mahsulotning savatdagi UMUMIY doni bo'yicha (dona qatorlari + barcha
  blok donalari jamlanadi). Foydalanuvchi screenshot case bilan aniqlashtirdi:
  3 blok(12)+1 dona=37 → dona ham 3-tier. Bitta blok uchun natija avvalgi
  qoida bilan bir xil (totalUnits=boxValue).

## Qabul qilingan qarorlar (davomi)
- Blok qatori qty'si OPD da umuman oshirilmaydi (foydalanuvchi qarori) —
  ko'proq kerak bo'lsa yangi blok skanerlanadi. Kamaytirish = minus tugma =
  butun qator o'chadi (value=1 bo'lgani uchun mavjud delete oqimi ishlaydi).

## Ochiq savollar
- `_repriceAllMarksForProduct` (ordering_provider_4.dart:2138) — o'lik kod,
  hech qayerdan chaqirilmaydi. Tozalash mumkin.
- `getProductByBoxBarcode` (items_singleton.dart:270) — `List<String>` ni
  `String` bilan solishtiradi (doim false), lekin faqat kommentda chaqirilgan.
  O'chirish mumkin.

## Test / Verifikatsiya
- flutter analyze o'tdi (yangi xato yo'q)
- Windows'da real skaner testi kutilmoqda (yuqoridagi 3 stsenariy)
