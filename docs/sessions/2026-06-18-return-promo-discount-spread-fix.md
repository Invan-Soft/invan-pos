# Task: Promo-diskontli chekni qaytarishda narx hammaga yoyilishi (bug fix)

**Boshlangan:** 2026-06-18
**Holat:** in-progress
**Branch:** ayyubxon

## Avvalgi implementatsiya
docs/sessions/2026-06-04-discount-partial-refund-fix.md (Yakunlangan 2026-06-04)
↑ U yerda `_globalToLocalSoldItem` ga `orderDiscountRatio` qo'shilgan edi (order-darajali diskontni qisman refundda to'g'ri saqlash uchun). Sabab: order-level diskontda refund asl narxda ketardi. Endi ma'lum bo'ldiki, ratio item-darajali (promo) diskontni hammaga yoyib yuboradi — chunki asl sabab boshqa joyda.

## Maqsad
Promo (kampaniya) diskontli chekni qaytarishda diskont faqat o'z item'ida qolsin, hamma productga proporsional yoyilmasin.

## Sabab (tasdiqlangan — real API javobi bilan)
Chek AC50947: Achchiq item'ida server `"single_order_discount": 19995` yuboradi, lekin model `ItemsGTR.fromJson` `json['single_item_discount']` ni o'qiydi (bunday maydon javobda YO'Q) → `singleDiscount = 0`.
→ `itemsSubtotal = 103,980` > `orderTotalPaid 63,990` → `ratio = 0.6154` → diskont hammaga yoyiladi.

To'g'ri o'qilsa: `itemsSubtotal = 63,990` = paid → `ratio = 1.0` → yoyilmaydi.

## Scope
- `lib/changes/models/receipts_get_model.dart` — `ItemsGTR.fromJson`/`toJson` maydon nomi
- Scope tashqarisida: `_globalToLocalSoldItem` ratio mantiqi (o'zgarmaydi — fallback bo'lib qoladi), sotuv kodi, server.

## Muhim faktlar (yon ta'sir yo'q)
- `ItemsGTR.singleDiscount` faqat return yo'lida ishlatiladi (return_page_provider, checks_singleton).
- `ItemsGTR.toJson`/`ReceiptsGetModel.toJson` refund POST yoki cache'da ishlatilmaydi.
- return_page.dart avval lokal DB'dan original narxni oladi (`local?.price ?? e.price`); API faqat fallback. Refund `price` (effektiv) ni ishlatadi, `realPrice−singleDiscount` emas → ikki marta ayirish yo'q.
- Umumiy refund summasi O'ZGARMAYDI (105 da ratio allaqachon to'g'ri). Fix faqat per-item taqsimotni to'g'rilaydi (ko'p itemli chek + diskont bittasida bo'lganda).

## Bajarilgan
- [x] Sabab real API javobi bilan tasdiqlandi (single_order_discount vs single_item_discount)
- [x] Yon ta'sir tahlili (return_page lokal DB fallback, ikki marta ayirish yo'qligi)

- [x] fromJson: `single_order_discount ?? single_item_discount` (orqaga moslik), toJson: `single_order_discount`
  → lib/changes/models/receipts_get_model.dart:363, 387
- [x] flutter analyze: No issues found

## Keyingi qadamlar
- [ ] Verifikatsiya (real qurilmada): AC50947 ni qaytarishda Achchiq=19995, Kimpab=23450, Paket=550 (jami 63,990)
- [ ] Order-darajali diskont (ratio fallback) holati buzilmaganini tekshirish

## Test / Verifikatsiya
- Lokal DB'da original bo'lmagan holatda (boshqa PC yoki cache tozalangan) AC50947 qaytarilsa per-item to'g'ri chiqsin.
- Order-darajali diskont (ratio) holati buzilmaganini tekshirish.
