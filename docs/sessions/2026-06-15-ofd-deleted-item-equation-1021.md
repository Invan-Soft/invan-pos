# Task: OFD 10.2.1 xatosi — o'chirilgan (red-delete) item fiskal chekka ketishi

**Boshlangan:** 2026-06-15
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Katta sotuvda OFD "В переданном чеке есть ошибочные параметры ... раздел 10.2.1" xatosi.
Sabab: red-delete rejimida o'chirilgan mahsulot (isDeleted=true) listda qoladi va fiskal
chek itemlariga ketadi, lekin to'langan summaga (cash) kirmaydi → items jami ≠ to'lov → 10.2.1 buziladi.

## Sabab (isbotlangan)
- Log: receivedCash = 40 629 000 tiyin = 1–14 itemlar net jami.
- 15-item (Tarvuz Kg, 4 604 600 tiyin) OFD items'da bor, lekin cash'da yo'q. Farq = aniq Tarvuz qatori.
- VAT bilan bog'liq emas (item-darajadagi VAT tenglamasi to'g'ri: Price × stavka/(100+stavka)).

### Kod zanjiri
- removeLastAdded() red-delete'da faqat isDeleted=true qiladi → ordering_provider_4.dart:310
- getTotalPrice (kassir totali) isDeleted'ni chiqaradi → items_singleton.dart:35
- chek soldItemList.addAll(orderedProducts) — deleted bilan birga → ordering_provider_4.dart:2813 va 3058
- saleOnOFD / getOfdTotalPrice / ReceiptApi4.func — isDeleted filtri yo'q edi

## Bajarilgan
- [x] Chek qurishda isDeleted itemlarni filtrlash (variant 1: OFD+server+qog'oz chek — hamma joydan chiqarish)
  → lib/changes/providers/ordering_provider_4.dart:2813 va :3058
  → `orderedProducts.where((p) => !(p.isDeleted ?? false))`
  → Sabab: bitta manba (soldItemList) uchchala oqimni (fiskal, server, PDF chek) ta'minlaydi.
    Manbada filtrlash eng toza va totalPrice (getTotalPrice — allaqachon deletedni chiqaradi) bilan mos.

## Keyingi qadamlar
- [ ] Windows'da test: red-delete YONIQ holatda item qo'shib, o'chirib, OFD bilan sotuv → 10.2.1 chiqmasligi kerak; o'chirilgan item qog'oz chekда ham ko'rinmasligi kerak.

## Ochiq savollar
- Eski saqlangan/pending cheklarda deleted item baked bo'lsa, qayta yuborishda muammo bo'lishi mumkin.
  Hozir oqim har safar orderedProducts'dan qayta quradi (filtrlangan), shuning uchun yangi sotuvlar xavfsiz.

## Test / Verifikatsiya
- flutter analyze: yangi xato yo'q (faqat avvaldan mavjud info/warninglar).
