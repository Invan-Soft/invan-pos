# Task: is_marking true→false o'zgarishi kassaga o'tmasligi (sticky isMarking)

**Boshlangan:** 2026-09-30
**Holat:** in-progress
**Branch:** fix/is-marking-false-sinxron

## Maqsad
Adminkada mahsulot markirovkasi o'chirilsa (`is_marking` true→false), notification
kassaga yetib kelsa ham qiymat yozilmasdi — kassa markirovka so'rayverardi
(jonli hodisa: "Qimiz KumИs & Med Yashil 500ml", barcode 4673741534682,
2026-09-30, Tiin Optom, barcha kassada). Server yuborgan aniq qiymat lokalda
ustun bo'lishi ta'minlanadi.

## Avvalgi implementatsiya
docs/sessions/2026-09-11-fiskal-mxik-fallback-markirovkasiz.md (in-progress)
↑ U yerda "is_marking — birinchi mezon" qoidasi O'QISH tomonida (MxikRules,
dialog qarori) joriy qilingan. YOZISH tomonida esa eski "bir marta true —
doim true" kodi qolib ketgan edi — bu task o'shani yopadi.

docs/sessions/2026-09-24-ws-notification-gap-audit.md (in-progress)
↑ Notification olish/qo'llash yo'li (NotificationFetch) to'g'ri ishlagan —
muammo fetch'da emas, `putItems` saqlash qatlamida edi.

## Diagnoz (Alice skrinshotlari, 2026-09-30 11:13)
- 4 ta type=2 notification bitta oynada kelgan, hammasi qabul qilingan
  (narx/nom qo'llangan) — faqat `is_marking: false` maydoni yutilgan.
- Foydalanuvchi taxmini "batch bo'lsa olmayapti, bitta bo'lsa olyapti" —
  tasodif: qayta update paytida kassa oradagi to'liq yuklashdan false olib
  bo'lgan edi (to'liq yuklash `clearAndPutItems` sticky'siz yozadi).
- "False ishlab turib keyin yana so'rab qoldi" — `updateMarkingStatusFromSoliq`
  (Servis'dagi qo'lda yangilash, `switchMarking` pref) false'ni ham true
  qilar edi; qimiz MXIKi (01704... sut) Soliq markirovka ro'yxatida.

## Bajarilgan
- [x] `putItems` sticky isMarking → null-only saqlash
  → lib/features/get_products/singletons/items_singleton.dart:549-562
  → Sabab: `_mergeFromExisting` printsipi bilan bir xil — "kelgan qiymat
    null bo'lsagina eskisini saqla". Serverning aniq true/false'i har doim
    ustun. O'zgarish `SYNC_MARKING_CHANGED` (id, from, to) bilan log'lanadi.
- [x] `updateMarkingStatusFromSoliq` — avto-true faqat `isMarking == null` ga
  → lib/changes/services/get_items_service.dart:302-310
  → Sabab: "is_marking birinchi mezon" (2026-09-11): adminka aniq false
    degan mahsulot MXIK ro'yxatda bo'lsa ham markirovkali qilinmaydi.
- [x] Testlar: 6 yangi/yangilangan (jami suite 1365, hammasi o'tdi)
  → test/items_singleton_notification_test.dart
  → true→false yoziladi (merge va merge'siz), null → mavjud true/false
    saqlanadi, false→true darrov, Soliq ro'yxati faqat null'ni to'ldiradi.
  → Eski "isMarking saqlanishi buzilmagan" testi buggy xulqni qulflab
    turgan edi — teskarisiga yangilandi.

## Qabul qilingan qarorlar
- Sticky o'rniga null-only saqlash `putItems`ning O'ZIDA (mergeWithExisting
  bayrog'idan tashqarida) — chunki eski sticky ham hamma chaqiruvchiga
  ta'sir qilardi; merge'siz yo'llar (create-product va h.k.) ham serverning
  aniq qiymatini olishi kerak.
- Bo'sh `mxik_code` kelganda org default bilan to'ldirish (addPackageCode-
  AndMxikCode) O'ZGARTIRILMADI: to'liq yuklash ham xuddi shunday qiladi,
  ikkala yo'l izchil. Notification yo'lini alohida "eski MXIKni saqla"
  qilish yo'llarni ajratib yuborardi.
- `uniqueMxiks` o'lik o'zgaruvchisi va `print` (eski analyzer ogohlantirishlari)
  tegilmadi — diff faqat fix.

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Foydalanuvchi MR orqali ayyubxon'ga merge qiladi (branch: fix/is-marking-false-sinxron)
- [ ] Reliz + do'kon sinovi: adminkada is_marking true→false qilib, kassada
  to'liq yangilashsiz (notification orqali) darrov qo'llanishini tekshirish;
  keyin Servis'da qo'lda yangilash qilib false qaytib ketmasligini tekshirish
- [ ] Logda `SYNC_MARKING_CHANGED` qatorini kuzatish

## Ochiq savollar
- `switchMarking` pref'i qaysi kassalarda true qolgan (UI tugmasi kommentda) —
  do'kon sinovida aniqlanadi; fix bilan endi xavfsiz.

## Test / Verifikatsiya
- flutter test — 1365/1365 o'tdi (2026-09-30)
- flutter analyze (o'zgargan fayllar) — yangi issue yo'q (3 ta eski ogohlantirish)
- Jonli tekshiruv rejasi yuqorida (Keyingi qadamlar)
