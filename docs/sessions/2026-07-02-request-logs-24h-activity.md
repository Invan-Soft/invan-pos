# Task: request_logs 24 soatlik rotatsiya + har activity'ni yozish

**Boshlangan:** 2026-07-02
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
`request_logs_of_invan_pos.txt` log fayli faqat oxirgi 24 soatlik ma'lumotni saqlasin
(rolling 24h), keyin tozalanib yangi oynani boshlasin. Shu bilan birga har bir UI/biznes
harakati (savatga qo'shish, sahifa o'tish, to'lov, mijoz tanlash, request body/response)
yozilsin.

## Muhim aniqlash (avvalgi holat)
Eski tozalash mantiqi [log_helper.dart] `fileStats.modified` gap'iga qarab ishlardi:
`now - lastModified >= 1 kun` bo'lsagina tozalardi. Lekin har yozuv lastModified'ni
yangilagani uchun, har kuni ishlaydigan kassada difference deyarli hamma vaqt 0 bo'lib,
fayl **HECH QACHON tozalanmasdi** — log cheksiz to'planardi (haftalab/oylab). Ya'ni
"necha kunlik" belgilanmagan, cheksiz edi.

## Scope
- lib/changes/services/log_helper.dart — rotatsiya + activity() API (asosiy)
- lib/changes/services/log_navigator_observer.dart — YANGI, sahifa o'tishlari
- lib/app/app.dart — navigatorObservers ga observer qo'shildi
- lib/changes/providers/ordering_provider_4.dart — savat/to'lov/mijoz activity'lari
- Scope tashqarisi: har bitta widget bosilishini yozish (faqat asosiy harakatlar)

## Bajarilgan
- [x] Rolling 24h rotatsiya (marker fayl `request_logs_window_start.txt` orqali)
  → lib/changes/services/log_helper.dart:9-40
  → Sabab: fayl kattaligiga bog'liq bo'lmagan, aniq 24 soatlik oyna
- [x] LogHelper.activity(action, details) umumiy API + _short() qisqartirgich
  → lib/changes/services/log_helper.dart (write() dan keyin)
- [x] LogNavigatorObserver (push/pop/replace/remove) + app.dart ga ulash
  → lib/changes/services/log_navigator_observer.dart, lib/app/app.dart:243
- [x] Savat/to'lov activity'lari: CART_ADD, CART_REMOVE_LAST, CART_DELETE_ITEM,
      CLIENT_SELECT, PAYMENT_PRESS
  → ordering_provider_4.dart (addProduct, removeLastAdded, pressDialogDeleteButton,
     selectClient, pressPaymentButton)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows'da real test: fayl 24 soatdan keyin tozalanishini va activity'lar
      yozilishini tekshirish
- [ ] Kerak bo'lsa qo'shimcha activity nuqtalari: chek chop etish, qaytarish (return),
      smena ochish/yopish, diskont qo'llash

## Qabul qilingan qarorlar
- Rolling 24h (kalendar kun emas) — foydalanuvchi tanlovi
- Oyna boshlanishini alohida kichik marker faylda saqlash — har yozuvda katta faylni
  o'qimaslik uchun

## Test / Verifikatsiya
- flutter analyze: yangi kodda error/warning yo'q (faqat oldindan mavjud info-lint)
- Windows runtime testi kutilmoqda
