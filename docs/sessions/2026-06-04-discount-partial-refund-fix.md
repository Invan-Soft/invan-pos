# Task: Diskontli mahsulotni qisman refund'da narx asl narxga qaytishi (bug fix)

**Boshlangan:** 2026-06-04
**Holat:** done
**Branch:** ayyubxon

## Maqsad

Order-level diskont qo'llanilgan chekni qisman refund qilganda, qolgan mahsulotlarning narxi diskontli narx o'rniga asl (chegirmasiz) narxda ko'rsatilardi. Buni to'g'rilash.

## Scope

- `lib/features/get_products/singletons/checks_singleton.dart` — `_globalToLocalSoldItem` metodi
- Scope tashqarisida: API server-side o'zgarishlari, refund POST oqimi.

## Reproduksiya (bug)

1. 4 dona mahsulot (har biri 5,000) sotildi, order-level 50% diskont qo'llandi → effektiv 2,500/unit, jami 10,000 to'landi.
2. Chekka kirib 2 ta refund qilindi — `5,000` (2 × 2,500) ko'rsatildi ✓
3. O'sha chekka qayta kirib refund'ni ochilsa, qolgan 2 ta mahsulot `2 × 5,000 = 10,000` ko'rsatardi ✗

## Bajarilgan

- [x] Bug sababini aniqladim
  → lib/features/checks/features/check_view/bloc/re_update_bloc.dart:42
  → Bloc `value` dan `refundAmount` ni kamaytirib yuboradi, lekin API `total_price` ni o'zgartirmaydi.
  → checks_singleton.dart dagi `orderDiscountRatio = orderTotalPaid / itemsSubtotal` koeffitsiyenti `value` (allaqachon kamaytirilgan) bo'yicha hisoblanardi, shu sababli ikkinchi refund'da ratio buzilardi.

- [x] Fix qo'llandi
  → lib/features/get_products/singletons/checks_singleton.dart:97-110
  → `itemsSubtotal` endi `value + refundAmount` (original qty) bilan hisoblanadi. Bu first refund (refundAmount=0) va second/third refund holatlari uchun ham to'g'ri ishlaydi.

## Qabul qilingan qarorlar

- **Singleton'da fix qilindi (re_update_bloc o'rniga)** — sabab: bloc'dagi `value` reduction boshqa joylarda ham foydalaniladi (UI rendering, refund POST body), uni o'zgartirish keng qamrovli ta'sirga olib kelishi mumkin. Singleton fix ko'lami minimal.
- **`refundAmount + value` formulasi** — sabab: API hozir `total_price` ni original holida qaytaradi (refund'dan keyin kamaytirmaydi). Agar kelajakda server `total_price` ni ham kamaytirsa, bu formula har ikki holatda ham to'g'ri ishlaydi.

## Test / Verifikatsiya

- Manual test ssenariysi:
  1. 4 dona mahsulot order-level diskont bilan sot
  2. 2 ta refund qil → 2 × 2,500 = 5,000 ko'rsatishi kerak ✓
  3. Qayta chekka kirib, qolgan 2 tani ko'r → 2 × 2,500 = 5,000 ko'rsatishi kerak ✓

## Ochiq savollar

- Yo'q. Free gift va order-level diskont kombinatsiyasi alohida sessiyada (free-gift-refund-fix) hal qilindi.

**Yakunlangan:** 2026-06-04
