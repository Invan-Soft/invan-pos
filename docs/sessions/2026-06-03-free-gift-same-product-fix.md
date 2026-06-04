# Task: Free Gift discount — sovg'a producti yagona/asosiy product bo'lganda ham ishlasin

**Boshlangan:** 2026-06-03
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad

Free Gift discountida (masalan: "55,000 dan ortiq harid qilsa, X productdan 1 ta tekin") agar savatda **faqat sovg'a productning o'zi** bo'lsa, hozir discount qo'llanmaydi. Foydalanuvchi tasdiqlagan kutilgan xulq: chek umumiy summasi (sovg'a qiymati ayrilgandan keyin ham) `buyAmount` dan oshsa, sovg'a berilishi kerak — xuddi avval boshqa product qo'shib keyin sovg'a productini orttirganda ishlagani kabi.

## Scope

- O'zgartiriladi: `lib/changes/providers/ordering_provider_4.dart` → `useFreeGiftProducts()` (taxminan 1139-1210 qatorlar) ichidagi threshold tekshiruvi
- O'zgartirilmaydi:
  - `lib/changes/singletons/discounts/discount_helpers.dart` → `_getFreeGift` (umumiy `totalPrice` ni to'g'ri tekshiradi, bug bu yerda emas)
  - BuyXGetY / BuyXGetX logikasi (ularda `isSameProduct` shoxi allaqachon bor)
- Scopedan tashqari: BonusPoint discount turi (alohida task)

## Bug tahlili

### Hozirgi kod ([ordering_provider_4.dart:1159-1170](../../lib/changes/providers/ordering_provider_4.dart#L1159-L1170))

```dart
final nonGiftTotal = orderedProducts
    .where((p) => p.productId != giftProductId && !p.isPriceOnlyChanged)
    .fold<num>(0, (sum, p) => sum + p.realPrice * p.value);

final giftItems = orderedProducts
    .where((item) =>
        item.productId == giftProductId &&
        !item.isPriceOnlyChanged &&
        !item.isPriceChanged)
    .toList();

if (nonGiftTotal >= gift.buyAmount) {
  // sovg'a qo'llanadi
}
```

**Muammo:** `nonGiftTotal` sovg'a productini **chiqarib tashlab** hisoblaydi. Agar savatda faqat sovg'a producti bo'lsa, `nonGiftTotal = 0`, demak threshold qondirilmaydi.

### Misol

- Savatda faqat MARTCHOTASI 9,000 × 8 = 72,000
- Sovg'a: 55,000+ harid uchun 1 MARTCHOTASI tekin
- `nonGiftTotal = 0` → 0 >= 55,000 false → sovg'a qo'shilmaydi ❌

Ammo foydalanuvchi kutadi: 72,000 − 9,000 (tekin qism) = 63,000 to'lanadi, bu 55,000 dan oshadi, demak 1 ta tekin berilishi kerak.

### BuyXGetY da bu allaqachon to'g'ri qilingan

[ordering_provider_4.dart:1040-1053](../../lib/changes/providers/ordering_provider_4.dart#L1040-L1053) — `useFreeProducts` da `isSameProduct` shoxi bor. Free Gift uchun unutilgan.

## Yechim

Threshold formulasi:

```
to'lanadigan_summa = (sovg'a_productdagi_total) + (boshqa_productlar_total) − (tekin_beriladigan_qism)
                   = giftProductInCartValue + nonGiftTotal − (gift.getProductAmount × realPrice)
```

`to'lanadigan_summa >= gift.buyAmount` bo'lsa, sovg'a beriladi.

Kod o'zgarishi `useFreeGiftProducts` ichida `if (nonGiftTotal >= gift.buyAmount)` qatoridan oldin:

```dart
final giftProductInCartValue = giftItems
    .fold<num>(0, (sum, p) => sum + p.realPrice * p.value);

final giftRealPrice = giftItems.isNotEmpty ? giftItems.first.realPrice : 0;
final freeValue = giftRealPrice * gift.getProductAmount;

final effectivePaidTotal =
    nonGiftTotal + giftProductInCartValue - freeValue;

if (effectivePaidTotal >= gift.buyAmount) {
  // ... mavjud sovg'a qo'llash bloki
} else {
  // ... mavjud reset bloki
}
```

### Tekshiruv stsenariylari

| Savat | nonGiftTotal | giftProductInCartValue | freeValue | effectivePaid | Natija |
|---|---|---|---|---|---|
| MARTCHOTASI 8×9000 (yagona) | 0 | 72,000 | 9,000 | 63,000 | ✅ 1 tekin |
| MARTCHOTASI 6×9000 (yagona) | 0 | 54,000 | 9,000 | 45,000 | ❌ tekin yo'q |
| MARTCHOTASI 7×9000 (yagona) | 0 | 63,000 | 9,000 | 54,000 | ❌ tekin yo'q |
| MARTCHOTASI 8×9000 (yagona) | 0 | 72,000 | 9,000 | 63,000 | ✅ 1 tekin |
| NewOR 60,000 + MARTCHOTASI 4×9000 | 60,000 | 36,000 | 9,000 | 87,000 | ✅ 1 tekin (hozir ham ishlaydi) |
| Faqat NewOR 60,000 (sovg'a yo'q) | 60,000 | 0 | 0 | 60,000 | ✅ (giftItems bo'sh — loop ishlamaydi) |

## Bajarilgan

- [x] `useFreeGiftProducts` ichidagi threshold tekshiruvi yangi formulaga almashtirildi
  → [lib/changes/providers/ordering_provider_4.dart:1170-1180](../../lib/changes/providers/ordering_provider_4.dart#L1170-L1180)
  → Sabab: BuyXGetY (`useFreeProducts`) da allaqachon mavjud `isSameProduct` mantiqi Free Gift ga ko'chirildi. Endi sovg'a productning to'lanadigan qismi ham threshold ga kiradi.

## Keyingi qadamlar (prioritet bo'yicha)

- [ ] UI test: faqat MARTCHOTASI 8 dona savatda — 1 ta tekin bo'lishini ko'rish (chegirma 12.5%, summa 63,000)
- [ ] UI test: faqat MARTCHOTASI 6 dona savatda — chegirma yo'qligini ko'rish (54,000 − 9,000 = 45,000 < 55,000)
- [ ] UI test: aralash savat (NewOR 60,000 + MARTCHOTASI 4×9,000) avvalgidek ishlashi
- [ ] UI test: faqat NewOR 60,000 + sovg'a producti savatda yo'q — hech narsa o'zgarmasligi

## Qabul qilingan qarorlar

- **`giftRealPrice` ni `giftItems.first.realPrice` dan olamiz** — chunki bir productning narxi savatdagi barcha qatorlarda bir xil bo'lishi kerak. Agar narx box vs unit bilan farqlasa, bu o'zi alohida masala (qisman boxed productlar uchun bu konvensiya allaqachon `nonGiftTotal` hisoblashida `p.realPrice * p.value` formatida ishlatilgan).
- **`else` (reset) shoxi o'zgarmaydi** — chunki bu sovg'a holatini tozalash; faqat threshold kondisiyasi yangilanadi.

## Ochiq savollar

- Bir vaqtning o'zida tier-li sovg'alar (Tier1: 50k → 1 ta, Tier2: 100k → 2 ta) mavjud bo'lsa, ular cross-effect berishi mumkinmi? Hozirgi `_getFreeGift` da `_maxPrice` orqali bir-biriga to'sqinlik qiladi. Bu fix doirasidan tashqari, lekin tekshirish kerak bo'lishi mumkin.

## Test / Verifikatsiya

- Foydalanuvchi UI da real Free Gift discount bilan tekshiradi (faqat MARTCHOTASI 8 dona, keyin 6 dona, keyin aralash).
