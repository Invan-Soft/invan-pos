# Task: Mijoz tepadan o'chirilganda customer-group diskont bekor bo'lsin

**Boshlangan:** 2026-06-13
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad

Faqat ma'lum mijozlar (customer group / do'kon klientlari) uchun yaratilgan diskont savatga qo'llangach, payment'ga o'tmasdan oldin foydalanuvchi tepadan o'sha mijozni o'chirib tashlasa — o'sha diskont **bekor bo'lishi** kerak. Faqat customer-restricted diskontlar uchun; `isForAllClients` diskontlar saqlanadi. Qo'lda narx o'zgartirilgan (utsenka) qatorlarga tegmaydi.

Misol: Free Gift'da tekin berilgan 10,000 li product, mijoz o'chirilganda yana 10,000 ga qaytishi kerak.

## Bug tahlili

- Diskontlar `getClientGroupId` bo'yicha filtrlanadi (`_checkOptions`). Mijoz o'chirilsa group bo'sh bo'ladi — customer-group diskont qondirilmaydi.
- Mijoz tepadan o'chirilganda ([ordering_provider_4.dart onDelClientPressed](../../lib/changes/providers/ordering_provider_4.dart)) faqat `selectedClient = null` + `setNewClientDiscountPercentage(0)` (flat-rate revert) chaqirilardi. Customer-group avtomatik diskontlar (Free Gift, customer-group product/category, BuyXGetX/Y) qayta hisoblanmasdi → tekin product 0 bo'lib qolardi.
- `onClientSearchButtonPressed` ichida dialog yopilgandan keyin `if (getClientGroupId.isNotEmpty)` bloki product/category diskontni qayta qo'llaydi — lekin mijoz o'chirilganda group bo'sh, bu skip qilinadi.
- `addDiscountOnProduct` (`_applyDiscounts`) joriy `price` dan boshlaydi (`_price = product.price`), shuning uchun u eski diskontni "ortga qaytara olmaydi" — faqat ustiga qo'shadi. Demak revert uchun avval `price = realPrice` ga reset qilish shart.

## Bajarilgan

- [x] `recalcDiscountsAfterClientRemoved()` metodi qo'shildi
  → [lib/changes/providers/ordering_provider_4.dart](../../lib/changes/providers/ordering_provider_4.dart) (recheckDiscountsAfterClientChanged dan keyin)
  → Avtomatik diskont holatini tozalaydi (`_returnedProducts`, `_returnedFreeGiftProducts`, `_returnedBuyXGetX`, `_giftProducts`, `_showCount`, `_showCountFreeGift`, `DiscountSingleton.resetAll/maxPrice`). Har bir non-manual qatorni `price = realPrice` ga reset qilib, diskontlarni tozalaydi, keyin `_applyDiscounts` (faqat isForAllClients product/category mos keladi) + `findFreeProducts` + `useFreeProducts/useFreeGiftProducts/useBuyXGetXProducts`.
  → `isPriceOnlyChanged` (utsenka, qo'lda narx) qatorlar o'tkazib yuboriladi.
- [x] `onDelClientPressed` da metod chaqirildi
  → [lib/changes/providers/ordering_provider_4.dart onDelClientPressed](../../lib/changes/providers/ordering_provider_4.dart) — `setNewClientDiscountPercentage(0)` dan keyin, `AppNavigation.pop()` dan oldin.

## Qabul qilingan qarorlar

- **Revert uchun avval `price = realPrice` ga reset** — `addDiscountOnProduct` joriy narxdan boshlaganligi uchun u o'zi diskontni undo qila olmaydi. Reset + qayta qo'llash yagona to'g'ri yo'l.
- **`_giftProducts` tozalansa ham** Free Gift revert ishlaydi — chunki manual reset (`price = realPrice`) holatning yagona manbai; `useFreeGiftProducts` empty-branch (`_giftProducts.containsKey`) endi no-op.
- **`isPriceChanged = false`** reset qilinadi (faqat non-manual qatorlar) — `setNewClientDiscountPercentage(0)` uni `true` qoldiradi, bu `useFreeProducts` filtrida (`!isPriceChanged`) for-all-client BuyXGetY ni bloklamasligi uchun.

## Keyingi qadamlar (prioritet bo'yicha)

- [ ] UI test: customer-group Free Gift → mijoz qo'sh (tekin product berildi) → mijozni tepadan o'chir → product narxi realPrice (10,000) ga qaytishini ko'r
- [ ] UI test: isForAllClients diskont → mijoz o'chirilganda o'zgarmasligini ko'r
- [ ] UI test: customer-group Product/Category % → mijoz o'chirilganda bekor bo'lishini ko'r
- [ ] UI test: utsenka (qo'lda narx) product → mijoz o'chirilganda tegilmasligini ko'r
- [ ] UI test: oddiy diskontsiz savat → mijoz o'chirilganda crash/o'zgarish bo'lmasligi

## Ochiq savollar

- `recheckDiscountsAfterClientChanged` (mijoz qo'shilganda) va `recalcDiscountsAfterClientRemoved` (o'chirilganda) bir-biriga juda yaqin — kelajakda umumlashtirish mumkin, lekin hozir alohida (biri dialog ko'rsatadi + reset qilmaydi, ikkinchisi to'liq reset + dialogsiz).

## Test / Verifikatsiya

- `flutter analyze` — yangi xato yo'q.
- Foydalanuvchi UI da real customer-group Free Gift + mijoz qo'shib-o'chirib tekshiradi.
