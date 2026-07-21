# Task: Blok ⇄ dona narx tahriri sinxronligi (OPD)

**Boshlangan:** 2026-07-16
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
OPD (mahsulot tahriri dialogi)da blok qatorining narxi o'zgartirilsa (21 600 →
18 000), shu mahsulotning dona qatorlari ham yangi dona narxiga (18 000/12 =
1 500) tushsin. Teskarisi ham: dona narxi o'zgartirilsa blok qatori dona narx ×
boxValue bo'lsin. Sabab: bu bitta mahsulot, narxi bir xil bo'lishi kerak.

## Kontekst
- OPD narx tahriri: operation_on_product_provider.dart `onlyPriceChanged` (input 5)
  va `onPriceChanged` (input 0, skidka-uslub) → save'da isPriceOnlyChanged=true
- OPD blok qatorida qty o'zgartirish bloklangan, narx tahriri OCHIQ (guard yo'q)
- Saqlash: OrderingProvider4.pressDialogSaveButton → qator almashtiriladi →
  _repriceProductRowsByTotalUnits (tier; isPriceOnlyChanged qatorlarni o'tkazib
  yuboradi)
- Blok qatori savatda: value=1(blok), price=blok narxi, boxValue=dona soni

## Scope
- lib/changes/providers/ordering_provider_4.dart — `_syncManualPriceAcrossProductRows`
  helper + pressDialogSaveButton'ga ulash
- test/box_price_edit_sync_test.dart
- Scope'dan tashqari: markirovka guruh tahriri (_saveMarkGroup yo'li), free gift
  qatorlari (narxi 0 — tegilmaydi)

## Bajarilgan
- [x] `_syncManualPriceAcrossProductRows` helper
  → lib/changes/providers/ordering_provider_4.dart (_repriceProductRowsByTotalUnits
    dan keyin, _addBoxProduct dan oldin)
  → Dona narx bazasi: tahrirlangan qator blok bo'lsa unit = narx/boxValue;
    boshqa qatorlar: dona = unit, blok = unit×boxValue. price/realPrice/
    onlyPrice/singleDiscount/vat proporsional, isPriceOnlyChanged=true,
    auto-diskontlar tozalanadi. isDeleted/isFreeGift/o'zi — o'tkazib yuboriladi
- [x] pressDialogSaveButton'ga ulandi: `item.isPriceOnlyChanged &&
  item.price != oldItem.price` bo'lsagina (ya'ni narx SHU tahrirda o'zgargan)
  → sinxron _repriceProductRowsByTotalUnits'dan OLDIN (u isPriceOnlyChanged
    qatorlarni baribir o'tkazib yuboradi)
- [x] OPD tekshiruvi: blok qatorida narx maydonlari ochiq (guard faqat qty'da);
  narx tahririning 3 yo'li ham (onlyPriceChanged/onPriceChanged/
  onTotalPriceChanged) save'da isPriceOnlyChanged=true qiladi → sinxron ishlaydi
- [x] 5 unit test — test/box_price_edit_sync_test.dart (blok→dona, dona→blok,
  qty-only tahrirda tegilmaslik, free gift himoyasi, 2 blok + dona)
- [x] flutter analyze — yangi xato yo'q; to'liq suite 33 passed (1 fail —
  pre-existing shablon widget_test)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows test: 1 blok + 1 dona savatda, blok narxini o'zgartirish → dona
      narxi mos tushishi; teskarisi; savat jami to'g'ri bo'lishi

## Qabul qilingan qarorlar
- Sinxron faqat narx SHU sessiyada qo'lda o'zgarganda ishlaydi
  (item.isPriceOnlyChanged && price != oldItem.price) — qty-only tahrirda
  boshqa qatorlarga tegilmaydi
- Sinxronlangan qatorlar ham isPriceOnlyChanged=true bo'ladi — tier reprice
  ularni keyin qayta yozib yubormasligi uchun; auto-diskontlari tozalanadi
  (qo'lda narx = diskontsiz sotuv, OPD manual edit semantikasi bilan izchil)

## Ochiq savollar
- (yo'q)

## Test / Verifikatsiya
- Unit test + Windows real test kutilmoqda
