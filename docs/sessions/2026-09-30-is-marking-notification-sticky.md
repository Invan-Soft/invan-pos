# Task: is_marking true→false o'zgarishi kassaga o'tmasligi (sticky isMarking)

**Boshlangan:** 2026-09-30
**Holat:** in-progress (relizda — 1.1.2+129, PRO, 2026-10-02, commit `a83668c` + `d31e4df`; do'kon sinovi kutilmoqda)
**Branch:** fix/is-marking-false-sinxron → `ayyubxon` (merge `1e96fc5`)

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
- "False ishlab turib keyin yana so'rab qoldi" — kod bo'yicha ISBOTLANMAGAN.
  Dastlab `updateMarkingStatusFromSoliq` deb taxmin qilingan edi, lekin
  (to'g'rilash, 2026-09-30): qimiz notification'ida `mxik_code` BO'SH keldi
  (01704... — Konfet/Ponchiki MXIKi edi, adashilgan), lokalda org default
  MXIK bo'ladi; Soliq ro'yxati box'i esa faqat hozir kommentdagi sozlama
  tugmasi orqali to'ldirilgan. Demak u yo'l ehtimoldan uzoq. Qolgan
  nomzodlar "Ochiq savollar"da.

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
- [x] End-to-end verifikatsiya (foydalanuvchi so'rovi: "yaxshilab test qildingmi")
  → test/is_marking_sync_e2e_test.dart (15 test, COMMIT QILINMAGAN)
  → Alice'dagi aynan o'sha 4 notification MockClient orqali:
    HTTP → NotificationFetch → parser → putItems → Hive → skaner keshi →
    MxikRules qarori (OFD + avto-aniqlash yoqiq, eng og'ir holat).
    SYNC_WINDOW: received=4, applied=4, failed=false — hodisadagi batch
    parse/qo'llashda yiqilmaydi.
  → ESKI kodda (ayyubxon) 11 ta yiqiladi, 4 ta o'tadi (false→true, to'liq
    yuklash) — test hodisani aniq qayta ishlab chiqaradi. "Qimiz yolg'iz
    kelsa" testi ham eski kodda yiqiladi: batch/bitta farqi yo'qligi isbot.
  → Qamrov: desc tartib, overlap qayta so'rov, bir oynada ziddiyatli
    notification'lar, type 13, type 20 (markirovka MXIKiga o'tish), kalitsiz
    va null is_marking, Soliq job, to'liq yuklash, false→true.
  → To'liq suite 1380/1380.
- [x] Kod auditi (test qilinmagan qismlar)
  → products box'ga yozuvchi 10 joy — hammasi Hive'dan yangi o'qiydi, eski
    obyektni qayta yozish (stale write-back) yo'q
  → dialog kirish nuqtalari 2 ta (addProduct:386, skaner:2954) — ikkalasi
    saqlangan isMarking/MxikRules'ga bog'liq
  → grid (`CatalogNavigationController._items`) eski ItemModel'larni
    ushlaydi, lekin har sinxron tsikli oxirida `_refreshUi` → HomeSyncState →
    `pressAllPath()` qayta quradi (catch_up_sync.dart:252, home_page.dart:95)
  → eski WebSocket yo'li (ws_service putItems) kommentda — faol emas

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
- [x] 2026-10-01: commit (a83668c, e2e test d31e4df) va `ayyubxon`'ga birlashtirildi, GitLab + GitHub main'ga push; Odoo forkiga ham ko'chirildi
- [ ] Foydalanuvchi qarori: test/is_marking_sync_e2e_test.dart ni commit
  qilish + `SYNC_MARKING_CHANGED` logini clearAndPutItems/Soliq job'ga
  kengaytirish (items_singleton.dart:455, get_items_service.dart:307)
- [ ] Hozir (relizsiz) ajratuvchi tajriba: kassada "To'liq yangilash" →
  qimiz skan; adminkada 4673741534682 dublikat qidiruvi
- [ ] Foydalanuvchi MR orqali ayyubxon'ga merge qiladi (branch: fix/is-marking-false-sinxron)
- [ ] Reliz + do'kon sinovi: adminkada is_marking true→false qilib, kassada
  to'liq yangilashsiz (notification orqali) darrov qo'llanishini tekshirish;
  keyin Servis'da qo'lda yangilash qilib false qaytib ketmasligini tekshirish
- [ ] Logda `SYNC_MARKING_CHANGED` qatorini kuzatish

## Ochiq savollar
- `switchMarking` pref'i qaysi kassalarda true qolgan (UI tugmasi kommentda) —
  do'kon sinovida aniqlanadi; fix bilan endi xavfsiz.
- "Bir kassada false ishlab turib keyin yana so'rab qoldi" — sababi kod
  bo'yicha topilmadi. Nomzodlar (hammasi ma'lumot/server tomoni):
  (1) keyinroq qimiz uchun `is_marking: true` bilan notification kelgan;
  (2) to'liq katalog (`products_json_gzip`, masalan ertalabki restart'dagi
  startup yuklash) qimizni `true` bilan bergan; (3) adminkada shu barcode
  bilan ikkinchi (dublikat) mahsulot kartochkasi bor. Ajratuvchi tajriba:
  kassada "To'liq yangilash" → qimizni skan qilish; baribir so'rasa — server
  katalogi true beryapti yoki dublikat bor. Adminkada 4673741534682 bo'yicha
  qidirish. Kassa logida c2fc90bf... bo'yicha keyingi notification'lar.
- Kuzatuv tirqichi: `SYNC_MARKING_CHANGED` faqat notification yo'lida.
  To'liq yuklash (`clearAndPutItems`) va Soliq job'idagi o'zgarishlar
  log'lanmaydi — takrorlansa qaysi yo'l qaytarganini bilib bo'lmaydi.
  Taklif: shu ikki joyga ham xuddi shu log (foydalanuvchi ruxsati kutilmoqda).
- Ochiq savatdagi (6 ta mijozdan birida) allaqachon turgan qator eski
  `marking` bayrog'i bilan qoladi — faqat yangi qo'shishlar yangi qiymatni
  oladi. Kutilgan xulq, lekin do'kon sinovida e'tibor berish kerak.

## Test / Verifikatsiya
- flutter test — 1365/1365 o'tdi (2026-09-30)
- flutter analyze (o'zgargan fayllar) — yangi issue yo'q (3 ta eski ogohlantirish)
- Jonli tekshiruv rejasi yuqorida (Keyingi qadamlar)
