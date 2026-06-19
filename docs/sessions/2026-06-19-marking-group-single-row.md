# Task: Markirovkali mahsulotni savatda 1 qator (guruhlangan) qilib ko'rsatish

**Boshlangan:** 2026-06-19
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Markirovkali mahsulot qo'shilganda hozir har bir dona alohida qator bo'lib qo'shiladi
(10 ta suv = 10 qator). Buni savatda 1 qator + qty=10 qilib ko'rsatish. Ma'lumot
modeli (har mark alohida `ReceiptModelSoldItem4`, o'z mark kodi bilan) O'ZGARMAYDI —
fiskal/OFD/qaytarish logikasi hozirgidek qoladi. Faqat UI guruhlaydi.

## Scope
- UI guruhlash: home savat (order_list) + to'lov ekrani chek ro'yxati (receipt_list).
- Guruh qatorini tahrirlash: qty kamaytirilsa eng oxirgi (eng yangi) markalardan o'chiriladi;
  ko'paytirish bloklangan; delete butun guruhni o'chiradi.
- SCOPE'dan tashqari: fiskal yuborish, mark tekshirish, check_view, return — tegilmaydi.

## Qabul qilingan qarorlar
- Data model o'zgarmaydi (har mark alohida item) — fiskalga har mark kodi kerak.
- Guruh qatorini bosish: qty kamaytirish (oxiridan), ko'paytirib bo'lmaydi (yangi skan kerak),
  delete = butun guruh. (User tanladi 2026-06-19)
- Qamrov: asosiy savat + to'lov ekrani. (User tanladi 2026-06-19)
- "+" allaqachon bloklangan: operation_on_product_provider.dart:109
  `if (target.marking && markCheckWithOfd) return;` — qo'shimcha save'da clamp qilamiz.
- Faqat NON-DELETED markirovka itemlari guruhlanadi; red-delete bo'lgan (isDeleted) markalar
  alohida qator bo'lib qoladi (audit ko'rinishi saqlanadi).

## Bajarilgan
- [x] Kod o'rganildi: addProduct marking path har markni insert(0) qiladi
  → ordering_provider_4.dart marking add (har mark value:1, insert(0))
  → order_list.dart index-based selection/edit/delete
  → operation_on_product_provider.dart:109 increase blocked for marking
- [x] Yangi fayl: BasketRow + groupBasketRows() (faqat aktiv markalar guruhlanadi)
  → lib/features/home/features/home_orders/order_list/basket_grouping.dart
- [x] order_list.dart — rows = groupBasketRows(...), itemCount/arrow/scroll = rows.length,
  _openRowEditor() (guruh: beginMarkGroupEdit→dialog→endMarkGroupEdit)
- [x] order_list_item.dart — overrideValue param (qty + total guruh qiymati bilan)
- [x] receipt_list.dart (payment) — grouped rows, displayValue (read-only)
- [x] operation_on_product.dart — displayValue param (focusedItem.value override)
- [x] ordering_provider_4.dart — _markGroupEditProductId + beginMarkGroupEdit/endMarkGroupEdit
  + _activeMarkIndices/_saveMarkGroup/_deleteMarkGroup
  + pressDialogSaveButton/pressDialogDeleteButton boshida guruh branch
  → Sabab: data model o'zgarmaydi, UI guruhlaydi; save qty kamayganda eng yangi
    (eng past indeks) markalarni o'chiradi, narx o'zgarishi barcha markalarga.
- [x] flutter analyze (touched files) — 0 error (faqat pre-existing warning/info)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows real test: 10 ta marking skan → 1 qator qty 10
- [ ] Guruh qatorini bosib qty kamaytirish (eng yangi markalar o'chishi)
- [ ] Guruh delete (red-delete ON/OFF) tekshirish
- [ ] To'lov ekranida ham 1 qator ko'rinishi

## Ochiq savollar
- pressDialogSaveButton group branch oxirida cashsale/bigTotal warning dialoglari
  ishlamaydi (normal path da bor). Marking edit kam holat; payment'da baribir chiqadi.
  Kerak bo'lsa keyin qo'shiladi.

## Test / Verifikatsiya
- Windows test: 10 ta marking skan → 1 qator qty 10; qty kamaytirish; delete; to'lov ekrani.
- Kod: flutter analyze 0 error.
