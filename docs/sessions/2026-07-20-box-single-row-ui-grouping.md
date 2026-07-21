# Task: Blok sotuvni savatda 1 qatorga guruhlash + blok qty ko'rsatish

**Boshlangan:** 2026-07-20
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Blok (saleType==2) sotilganda hozir har blok savatda alohida qator bo'lib qo'shiladi
(3 blok = 3 qator). Buni markirovkadagidek UI da 1 qator + qty=blok soni qilib
ko'rsatish. Kassirlar blokda nechta dona borligini ko'ra olmaydi — operation dialogda
"N blokda M ta" ko'rsatiladi. Chek/tarixda ham blok qty chiqadi. Data/fiskal/vozvrat
logikasi O'ZGARMAYDI — faqat UI guruhlaydi (markirovka naqshining aynan o'zi).

## Scope
- UI guruhlash: savat (order_list) + to'lov ekrani (receipt_list).
- Operation dialog: blok uchun "N blokda M ta" (blok soni × boxValue).
- Bosilgan chek (sold_api_components): blok qty (4 blok × blok narx), aralashsa "+ M dona".
- Tarix (check_view): ALLAQACHON blok ko'rsatadi — tegilmaydi.
- SCOPE'dan tashqari: fiskal/soliq (saleOnOFD), konsolidatsiya, vozvrat — tegilmaydi.

## Qabul qilingan qarorlar
- UI guruhlash, data model O'ZGARMAYDI (har blok alohida value=1 item). Sabab: butun blok
  konveyeri (vozvrat, blok⇄dona narx sinxron, konsolidatsiya) "har blok = value=1 qator"
  deb qurilgan; merge qilsak hammasi buziladi. (User tasdiqladi 2026-07-20)
- Savat qatori: qty = blok soni, narx = blok narxi, jami = blok×narx.
- boxValue SKU yonida EMAS — operation dialogda "N blokda M ta" (User tuzatdi 2026-07-20).
- Fiskal/soliq TEGILMAYDI: LocalService.sell → saleOnOFD konsolidatsiyadan OLDIN xom
  savat bilan ishlaydi, har blok 1 dona × blok narx ketadi (tasdiqlangan).
- Chek + tarix blok qty ko'rsatsin (User tanladi 2026-07-20). Tarix allaqachon qiladi.
- Aralash (blok+dona) bitta qatorda: "4 blok + 3 dona" (User tanladi 2026-07-20).

## Bajarilgan
- [x] basket_grouping.dart — saleType==2 uchun blok-guruh shoxi (productId bo'yicha)
  → lib/features/home/features/home_orders/order_list/basket_grouping.dart
  → BasketRow ga isBoxGroup + boxValue + totalUnits getter; markGroupRowIndex va
    boxGroupRowIndex ALOHIDA maplar (bir mahsulot ham marka, ham blok bo'lsa 2 qator)
  → Sabab: marka `marking && saleType!=2`, blok `saleType==2` — ajratilgan
- [x] ordering_provider_4.dart — blok guruh tahrir metodlari
  → _boxGroupEditProductId + beginBoxGroupEdit/endBoxGroupEdit (2374 atrofida)
  → _activeBoxIndices/_saveBoxGroup/_deleteBoxGroup (_deleteMarkGroup dan keyin)
  → pressDialogSaveButton/pressDialogDeleteButton boshida blok branch (marka'dan oldin)
  → Sabab: _saveMarkGroup naqshi; qty kamaytir = eng yangi bloklar o'chadi; narx
    qo'lda o'zgarsa _syncManualPriceAcrossProductRows (blok⇄dona sinxron saqlanadi),
    aks holda _repriceProductRowsByTotalUnits
- [x] order_list.dart — group:(isMarkGroup||isBoxGroup)?row:null; _openRowEditor blok branch
  (displayValue = row.totalValue = blok soni)
- [x] opd_top.dart — saleType==2 && boxValue>0 bo'lsa "N blokda M ta" yorlig'i (nom ostida)
- [x] receipt_list.dart — isGroup=isMarkGroup||isBoxGroup uchun guruh qiymatlari
- [x] sold_api_components.dart — blok item: nom oxiriga " blok" qo'shiladi; o'ng
  tomon FAQAT "blokSoni*blokNarx" (jamisiz, "= total" olib tashlandi); Narxi qatori
  blok narxida. value/price O'ZGARMAYDI (faqat display).
- [x] sold_api_components.dart — ARALASH (blok+dona) chekda IKKI qatorga bo'linadi:
  ProductPortion enum (full/blockOnly/looseOnly) + buildProductList.expand; blok qatori
  "N blok" + dona qatori alohida "M*donaNarx = jami". VAT/chegirma effectiveValue bo'yicha
  bo'linadi (yig'indisi butun itemga teng — halol). (User tanladi 2026-07-20)
  → MUHIM: bu ajratish FAQAT UI/bosilgan chekda. API (order_pos) va fiskal blok+dona'ni
    BITTA konsolidatsiyalangan item sifatida oladi. SoldApiComponents faqat printing'da
    ishlatiladi (receipt_api_4.dart/toJson'ga tegmaydi) — tasdiqlangan. (User: 2026-07-20)
- [x] Test: test/box_ui_grouping_test.dart (5 test) — 3 blok→1 qator, blok+dona 2 qator,
  o'chirilgan chetlashtiriladi, blok≠marka guruh, turli mahsulot alohida
- [x] flutter analyze (touched) — 0 error; box+deleted testlar (38) — All passed

- [x] BUG FIX (dialog tier narx): aralash (blok+dona) mahsulotda dona qatorini
  bosib qty kamaytirilsa, dialog narxni FAQAT lokal qty bo'yicha hisoblab noto'g'ri
  tier ko'rsatardi (masalan 27→2,750 to'g'ri, lekin dialog 26 o'rniga 2 dona bo'yicha
  2,850 ko'rsatardi). Saqlangach _repriceProductRowsByTotalUnits to'g'rilardi, lekin
  preview chalg'itardi. Tuzatildi: dialog tier narxni UMUMIY dona bo'yicha hisoblaydi.
  → operation_on_product_provider.dart: baseUnitsFromOtherRows maydoni + _tierUnits()
    helper; 5 ta finalPrice chaqiruvi target.value.toInt() → _tierUnits()
  → operation_on_product_dialog.dart: _baseUnitsFromOtherRows(context,item) — savatdagi
    boshqa qatorlar (blok value×boxValue) donasi, tahrirlanayotgan qatordan tashqari
  → Sabab: oldindan bor edi (tier by total-units 2026-07-10 vs dialog local-qty).
    baseUnits=0 bo'lsa (bitta qatorli mahsulot) avvalgi xatti-harakat aynan saqlanadi.
    Saqlash logikasi (allaqachon to'g'ri) tegilmadi — faqat preview to'g'rilandi.

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows real test: 3 blok skan → 1 qator qty 3; dialog "3 blokda 36 ta";
  bosilgan chek "3 blok*21,600"; blok+dona aralash "4 blok + 3 dona"
- [ ] Blok guruhini bosib qty kamaytirish (eng yangi bloklar o'chishi) + tier reprice
- [ ] Blok guruh delete (red-delete ON/OFF)
- [ ] To'lov ekranida 1 qator + fiskalga blok baribir dona-qator×blok narx (o'zgarmagan)

## Ochiq savollar
- (yo'q)

## Test / Verifikatsiya
- flutter analyze (touched files) — 0 error.
- Windows real test: 3 blok skan → 1 qator qty 3; dialog "3 blokda 36 ta"; chek "3 blok".
- Blok+dona aralash: chekda "4 blok + 3 dona".
- Fiskalga blok baribir dona-qator × blok narx ketishi (o'zgarmagan).
