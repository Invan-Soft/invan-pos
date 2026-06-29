# Task: BonusPoint (keshbek) discount turini qo'llab-quvvatlash

**Boshlangan:** 2026-06-19
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Backendda yangi discount turi bor — **BonusPoint** (xariddan mijozga keshbek beradi).
Hozir POS uni umuman bilmaydi. Bosqichma-bosqich qo'llab-quvvatlash qo'shamiz.

## BonusPoint JSON ko'rinishi (backenddan)
```
discount_type.id        = 2a221918-85b0-44ec-8d93-40f475e4eb4d  (label: BonusPoint)
discount_group_type.id  = 141432e1-9d71-45a2-91c1-1f8c7c92b39b  (label: BonusPoint)
bonus_discount_value    = 5000   ← keshbek summasi (yangi maydon)
buy_x_get_y / buy_x_get_x / gifts = null
```

## Scope
- 1-bosqich (HOZIR): BonusPoint'ni lokalga (Hive) saqlash — `bonus_discount_value` maydonini
  model parse qilsin va persist qilsin. Boshqa discountlardek.
- Keyingi bosqichlar (KEYIN): qo'llash logikasi (keshbekni mijoz balansiga qo'shish),
  UI, chek, backend sync. Hozircha SCOPE'dan tashqari.

## Avvalgi holat
- BonusPoint hech qachon kodga qo'shilmagan (git tarix bo'yicha tasdiqlangan).
- Discountlar `DiscountService.discounts()` da turidan qat'i nazar Hive'ga saqlanadi
  (discount_service.dart:41-46: box.clear → box.put). Ya'ni BonusPoint allaqachon
  DiscountItem sifatida saqlanmoqda, faqat bonus_discount_value parse qilinmaydi.
- Kodda "cashback" bor, lekin u BOSHQA tizim (mijoz keshbek balansi = to'lov usuli).

## Bajarilgan
- [x] (1-bosqich) DiscountItem modelga `@HiveField(21) int? bonusDiscountValue` qo'shildi
      → discounts_response.dart: field + ctor + fromJson (`json['bonus_discount_value']`) + toJson
- [x] Hive adapter yangilandi → discounts_response.g.dart: read `fields[21]`, write byte 21,
      writeByte count 21→22 (typeId 117 o'zgarmadi — backward compatible)
- [x] flutter analyze — 0 error/warning
- [x] Saqlash oqimi tekshirildi: DiscountService.discounts() barcha turdagi discountni Hive'ga
      saqlaydi (filtr yo'q) → BonusPoint endi bonus_discount_value bilan birga lokalda saqlanadi

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] (keyingi sessiya) BonusPoint qo'llash logikasi: keshbekni hisoblash + mijoz balansiga qo'shish
      (discount_helpers.dart da group 141432e1-... ni handle qilish, hozir e'tiborsiz qoldiriladi)
- [ ] Keshbek mijozga bog'lanishi (cashback_client_model / typeFromCashbackBalance bilan integratsiya?)
- [ ] UI/chekda ko'rsatish, backend sync

## Qabul qilingan qarorlar
- Hive field qo'shish backward-compatible (typeId 117 o'zgarmaydi, eski yozuvlar null bo'ladi) —
  box wipe / migration kerak emas.

## Ochiq savollar
- Keshbek mijozga bog'lanadimi (mijoz tanlanmasa qo'llanmaydimi)? — keyingi bosqichda aniqlanadi
- bonus_discount_value foizmi yoki qat'iy summami? JSON'da 5000 (summa ko'rinadi) — tasdiqlash kerak

## Test / Verifikatsiya
- 1-bosqich: discount sync'dan keyin Hive'da BonusPoint DiscountItem'ida bonusDiscountValue=5000 saqlanishi.
