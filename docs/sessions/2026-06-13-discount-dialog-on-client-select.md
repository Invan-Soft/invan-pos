# Task: Diskont dialogi mijoz tanlangan zahoti chiqsin (yangi product kutmasdan)

**Boshlangan:** 2026-06-13
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad

Maxsus mijozlar uchun yaratilgan diskont (masalan Free Gift "savat 50 mingdan oshsa") savat allaqachon shartni qondirgan holatda, mijoz QR scan / person-icon qidiruv orqali qo'shilganda diskont dialogi **darhol** chiqishi kerak. Hozir dialog faqat keyingi product urilganda chiqadi.

## Bug tahlili

- Diskontlar `getClientGroupId` bo'yicha filtrlanadi (`DiscountHelpers._checkOptions` → `_checkCustomerGroups`). Mijoz tanlanmaguncha group bo'sh ("") — maxsus-mijoz diskonti topilmaydi.
- Diskont topish + dialog ko'rsatish oqimi (`findFreeProducts` → `freeGiftDialog` + `useFreeProducts`/`useFreeGiftProducts`/`useBuyXGetXProducts`) faqat `addProduct` va shunga o'xshash product-qo'shish oqimlari ichida chaqiriladi.
- Mijoz tanlanganda (`ClientFoundState` → `initClientByBloc`) bu oqim qayta ishga tushmaydi → shuning uchun dialog faqat keyingi product urilganda chiqardi.

## Bajarilgan

- [x] `recheckDiscountsAfterClientChanged()` metodi qo'shildi
  → [lib/changes/providers/ordering_provider_4.dart:2449-2487](../../lib/changes/providers/ordering_provider_4.dart#L2449)
  → Savatdagi qatorlarga product/category chegirmasini yangi client group bilan qayta qo'llaydi (qo'lda narx/chegirma o'zgartirilgan — `isPriceOnlyChanged`/`isPriceChanged` — qatorlarga tegmaydi), keyin `findFreeProducts` + `freeGiftDialog` + `useFreeProducts`/`useFreeGiftProducts`/`useBuyXGetXProducts` ni ishga tushiradi.
  → Sabab: `addProduct` ichidagi diskont oqimini takrorlaydi, lekin yangi product urilishini kutmasdan.
- [x] Client search success handler'da metod chaqirildi (`AppNavigation.pop()` dan keyin)
  → [lib/changes/dialogs/client_search/client_search_dialog_with_bloc.dart:76-99](../../lib/changes/dialogs/client_search/client_search_dialog_with_bloc.dart#L76)
  → Provider reference avval olib qo'yildi (`orderingProvider`), chunki pop'dan keyin dialog `context` defunct bo'lishi mumkin. Metod `AppNavigation.navigatorKey.currentContext` orqali dialog ko'rsatadi — pop'dan keyin home/payment ekran ustida chiqadi.
  → QR scan ham shu `ClientFoundState` yo'lidan o'tadi, demB alohida joy kerak emas.

## Qabul qilingan qarorlar

- **Faqat `freeGiftDialog()` dialogi ko'rsatiladi**, BuyXGetY (`ContainsDiscountItemDialog`) emas — chunki BuyXGetY dialogi aniq scan qilingan "buy" productga (`_productId`) bog'liq; mijoz tanlashda bunday product yo'q. Lekin `useBuyXGetXProducts`/`useFreeProducts` chaqirilgani uchun barcha diskont turlarining **summasi** baribir to'g'ri qo'llanadi — faqat BuyXGetX/Y dialogi chiqmaydi (foydalanuvchi bu turlarni shikoyat qilmadi; kerak bo'lsa keyingi task).
- **`_applyDiscounts` qatma-qator qayta qo'llanadi** — box product oqimidagi ([ordering_provider_4.dart:2010-2018](../../lib/changes/providers/ordering_provider_4.dart#L2010)) yondashuv bilan bir xil. `isPriceChanged` qatorlar (flat-rate mijoz diskonti) o'tkazib yuboriladi.

## Keyingi qadamlar (prioritet bo'yicha)

- [ ] UI test: savat 50k+ qil → mijozni QR/person-icon orqali qo'sh → Free Gift dialogi **darhol** chiqishini ko'r (yangi product urmasdan)
- [ ] UI test: oddiy mijoz (diskontsiz) qo'shilganda dialog chiqmasligi, xato bo'lmasligi
- [ ] UI test: flat-rate mijoz qo'shilganda avvalgidek 0.5% (yoki tegishli %) ishlashi, qo'shimcha dialog chiqmasligi
- [ ] UI test: payment ekranida mijoz qo'shilganda crash/g'alati dialog bo'lmasligi

## Ochiq savollar

- BuyXGetX/BuyXGetY uchun ham mijoz-tanlashda dialog kerakmi? Hozir summa qo'llanadi, dialog chiqmaydi. Foydalanuvchi tasdiqlasin.

## Test / Verifikatsiya

- `flutter analyze` — yangi xato yo'q (faqat oldindan mavjud warning'lar).
- Foydalanuvchi UI da real Free Gift diskont + maxsus mijoz bilan tekshiradi.
