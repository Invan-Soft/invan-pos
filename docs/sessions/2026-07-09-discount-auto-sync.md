# Task: Kompaniya diskontlarini har 10 daqiqada fonda avto-sinxronlash

**Boshlangan:** 2026-07-09
**Holat:** in-progress (kod tayyor, Windows test kutilmoqda)
**Branch:** ayyubxon

## Maqsad
Diskontlar odatda WebSocket (type 15/16/17) orqali jonli keladi, lekin WS
uzilsa/xabar yo'qolsa yangi diskont kassaga yetib bormaydi. Har 10 daqiqada
`company_discounts_for_pos` dan to'liq ro'yxat olinib, lokal Hive box bilan
JIMGINA (dialog/UI'siz) sinxronlanadi. Boshqa hech narsaga ta'sir qilmasligi kerak.

## Scope
- Yangi: lib/changes/services/discount_auto_sync_service.dart
- O'zgargan: lib/app/wrapper/wrapper.dart (initState'da start())
- Scope'dan tashqari: savatdagi joriy chegirmalarni qayta hisoblash, UI

## Bajarilgan
- [x] `DiscountAutoSyncService` singleton — Timer.periodic(10 min)
  → lib/changes/services/discount_auto_sync_service.dart
  → Sabab: WS'ga bog'liq bo'lmagan mustaqil qoplama kanal
- [x] Diff-merge (clear+repopulate EMAS): yangi → put, mavjud → put (yangilash),
  serverda yo'q → delete (WS type 17 semantikasi bilan bir xil)
  → Sabab: `DiscountService.discounts()` dagi `box.clear()` oynasida savatga
    qo'shilgan mahsulot diskontsiz qolishi mumkin edi
- [x] Himoyalar:
  * `onDiscountsCleared` (savatni tozalaydigan callback) ATAYIN chaqirilmaydi
  * `_syncing` flag — parallel ishga tushmaydi; token/shopId guard har tsiklda
  * xatolar yutiladi, faqat LogHelper.activity('DISCOUNT_AUTO_SYNC*') ga yoziladi
- [x] wrapper.dart initState'da shartsiz `start()` — login bo'lmaguncha guard
  tufayli no-op; login flow orqali kirgan sessiyada ham ishlaydi
- [x] flutter analyze — 0 error

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows test: admin panelda yangi diskont yaratish → WS'ni o'chirib
  (yoki e'tiborsiz) 10 daqiqa kutish → diskont kassada paydo bo'lishi;
  request_logs'da DISCOUNT_AUTO_SYNC yozuvi (added/updated/deleted).
- [ ] Diskont o'chirilganda 10 daqiqadan keyin lokaldan yo'qolishi.
- [ ] Sotuv o'rtasida sync bo'lganda savatga ta'sir yo'qligini tekshirish.

## Qabul qilingan qarorlar
- To'liq ro'yxat (company_discounts_for_pos) ishlatildi, notifications
  endpoint emas — is_read holatiga va WS'ga bog'liq emas, idempotent.
- Interval 10 daqiqa (foydalanuvchi talabi), sozlama qilinmadi.
- (2026-07-09, foydalanuvchi talabi) Responseda qaytmagan diskont = o'chirilgan
  → lokaldan ham o'chiriladi, server BO'SH ro'yxat qaytarsa ham. Avvalgi
  "bo'sh-javob himoyasi" olib tashlandi — server xato bo'sh qaytargan taqdirda
  keyingi tsiklda diskontlar qaytadan yozilib o'z-o'zini tuzatadi.
- Debug printlar qo'shildi (🔖 prefiks): kelgan ro'yxat nomma-nom, yangi
  yozilganlar (🆕), o'chirilganlar (🗑).

## Ochiq savollar
- (yo'q)

## Test / Verifikatsiya
- flutter analyze toza; real 10-daqiqalik tsikl testi Windows'da kutilmoqda.
