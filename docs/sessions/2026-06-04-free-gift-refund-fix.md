# Task: Free gift va order-level diskontli chekni refund'da narxlar xato taqsimlanishi

**Boshlangan:** 2026-06-04
**Holat:** done
**Branch:** ayyubxon

## Maqsad

Free Gift diskonti qo'llanilgan chekni refund'ga ochganda, sovg'a mahsulot 0 so'm o'rniga proportional taqsimlangan narxda (masalan 10,000), oddiy mahsulot esa o'z narxidan kam ko'rsatilardi. Buni to'g'rilash.

## Scope

- `lib/features/checks/return_page/return_page.dart` — `_copyWith()` va yangi `_getOriginalItemsFromLocalDB` helper
- Scope tashqarisida: `checks_singleton.dart` da fallback ratio mexanizmi (boshqa ssesiyada to'g'rilangan, cross-POS holati uchun).

## Reproduksiya (bug)

1. Free Gift diskonti qo'shilgan: 50,000 dan ortiq xarid bo'lsa, MARTCHOTASI mahsuloti tekin.
2. Sotuv: NewOR × 6 (= 60,000) + MARTCHOTASI × 1 (= tekin) → to'lov 60,000.
3. Chekka kirib Qaytarish bosildi.
4. Refund sahifa ko'rsatdi:
   - NewOR × 6 = **50,000** (60,000 emas) ✗
   - MARTCHOTASI × 1 = **10,000** (0 emas) ✗
   - Jami = 60,000 (to'g'ri, lekin per-item taqsimot xato)

## Bajarilgan

- [x] Bug sababini aniqladim
  → API GET javobida (api/v1/order?search=...) per-item `single_item_discount` saqlanmaydi (singleDiscount=0 qaytadi)
  → `checks_singleton.dart` ratio mexanizmi diskontni proportional taqsimladi: ratio = orderTotalPaid (60,000) / itemsSubtotal (72,000) = 0.833
  → Natijada NewOR.price = 10,000 × 0.833 = 8,333 va MARTCHOTASI.price = 12,000 × 0.833 = 10,000

- [x] Local DB fallback yondashuvi tanlandi
  → Sotuv momentida ObjectBox'ga saqlangan original receipt'da har bir item'ning aniq `price`, `realPrice`, `singleDiscount` mavjud
  → Buni API qiymatlaridan oldin tekshirish

- [x] Helper qo'shildi
  → lib/features/checks/return_page/return_page.dart:86-104
  → `_getOriginalItemsFromLocalDB(externalId)` → `Map<productId, ReceiptModelSoldItem4>` qaytaradi

- [x] `_copyWith` yangilandi
  → lib/features/checks/return_page/return_page.dart:128-185
  → Har bir item uchun local DB'dan `price`, `realPrice`, `onlyPrice`, `singleDiscount` olinadi.
  → Local DB topilmasa API qiymatlariga qaytamiz (cross-POS holati uchun).

## Qabul qilingan qarorlar

- **Local DB'ga ishonish (API o'rniga)** — sabab: sotuv momentidagi diskont qo'llash mantig'i (free gift, buy x get x, order-level) lokal kodda kechadi va natija to'liq saqlanadi. API GET javobi esa diskont strukturasini saqlamasligi mumkin (server limitatsiyasi).
- **API fallback saqlandi** — sabab: cross-POS refund (sotuv POS A'da, refund POS B'da) holatida lokal DB topilmasligi mumkin. Bu holda ratio mexanizmiga qaytamiz (free gift uchun cross-POS hali ham noaniq, lekin standart oqim ishlaydi).

## Cheklovlar

- **Cross-POS free gift:** Sotuv boshqa POS'da bo'lsa, lokal DB topa olmaydi → API ratio fallback'ga o'tadi → free gift narxi proportional taqsimlanadi (yana xato). Bu kelajakda `it.discount.price` field'i orqali aniqlanishi mumkin (server tomon kerakli ma'lumotni qaytarsa).
- **Bir chekda bitta productId bir necha qator:** Map productId bo'yicha yuritiladi, oxirgi qatorning narxi qoladi.

## Test / Verifikatsiya

- Manual test ssenariysi:
  1. Free Gift diskonti yaratish (threshold 50,000, sovg'a — bitta mahsulot)
  2. Sovg'a triggerini ishga tushirish (NewOR × 6 = 60,000)
  3. Sotuvni yakunlash
  4. Chekka kirib Qaytarish: MARTCHOTASI = 0, NewOR × 6 = 60,000 ko'rsatishi kerak ✓

- Boshqa stsenariylar (regression):
  - Single product percentage discount → local DB price aniq, refund to'g'ri
  - Single product numeric discount → local DB price aniq, refund to'g'ri
  - Order-level discount qisman refund → birinchi sessiyadagi singleton fix ishlaydi (lokal DB topilsa qo'shimcha tasdiq)

## Ochiq savollar

- Yo'q.

**Yakunlangan:** 2026-06-04
