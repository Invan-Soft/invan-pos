# Task: Ko'p kassali do'konda narx o'zgarishi bitta kassaga yetib bormasligi

**Boshlangan:** 2026-08-12
**Holat:** in-progress
**Branch:** chore/lint-cleanup

## Maqsad
Bir do'konda bir necha kassa bo'lganda, mahsulot narxi o'zgarganda o'sha paytda
o'chiq/oflayn turgan kassa o'zgarishni **hech qachon** olmasdan qolib ketardi —
eski narx bilan sotishda davom etardi. Sabab: notification catch-up oynasi
noto'g'ri hisoblanardi. Sinxron mexanizmi bitta ishonchli kursor atrofida
qayta qurildi.

## Muammoning ildizi (tahlil)

1. **Startup catch-up mahsulotni umuman qamramasdi.**
   `app.dart` NetworkSuccess blokida faqat `CategoriesWsService` (type 10,11,12)
   va `DiscountWsService` (type 15,16,17) chaqirilardi. `ProductsWsService`
   (type 0,1,2,3,**13**,20,21,40 — narx o'zgarishi 13) faqat kommentga
   olingan blokda qolgan edi.

2. **WS catch-up oynasi ≈ 0 soniya edi.**
   `WsService.startTime`/`endTime` — static maydonlar, Dart'da birinchi
   murojaatda (ilova ishga tushganda) `DateTime.now()` bo'lardi. Ya'ni
   `start_date ≈ end_date ≈ hozir`.

3. **Har daqiqalik auto-sync gap'ni yopmasdi.**
   Oyna `lastSyncTime - 5 daqiqa` edi, lekin `app.dart:221` startup'da
   `lastSyncTime = now` qilib qo'yardi — mahsulot bir marta ham
   sinxronlanmasidan oldin. Kassa o'chiq turgan davr abadiy o'tkazib
   yuborilardi.

4. **Natija tekshirilmasdi.** `getReceivedWS` `void` qaytarardi; timeout yoki
   500 bo'lsa ham chaqiruvchi vaqtni oldinga surardi → o'sha oyna butunlay
   yo'qolardi. Bundan tashqari istisno `app.dart` listenerini yiqitib,
   `autoUpdate` umuman ishga tushmay qolishi mumkin edi.

5. **`autoUpdate2`** (60 daqiqada bir, 65 daqiqalik zaxira oyna) hech qayerdan
   chaqirilmasdi — o'lik kod.

6. **WebSocket butunlay o'chiq.** `WsService.connectWebSocket` ning barcha
   chaqiruv joylari kommentda (`app.dart:280-306`, `access_level_page:29-40`,
   `connect_bloc:22`). Ya'ni jonli `type: 13` xabari umuman kelmaydi —
   yagona mexanizm polling. Shu sababli catch-up to'g'ri ishlashi kritik.

## Scope
- `lib/changes/services/sync/` (yangi)
- 3 ta `*_ws_service.dart` — natija qaytarish
- `app.dart`, `update_provider.dart`, `sync_button_home.dart`, `ws_service.dart` — chaqiruvlar
- Scope dan tashqari: backend `offset=1` semantikasi, WebSocket'ni qayta yoqish

## Bajarilgan

- [x] Turg'un sinxron kursori
  → lib/changes/services/sync/sync_cursor.dart
  → `SyncStream` (categories/products/discounts), `SyncCursor`, `SyncWindow`,
    `SyncFetchResult`
  → Sabab: oyna endi chaqiruv joyida emas, bitta joyda hisoblanadi va Hive'da
    saqlanadi. Kursor **faqat muvaffaqiyatli** sinxrondan keyin suriladi, shuning
    uchun har qanday uzilish keyingi urinishda o'z-o'zidan yopiladi.
  → 2 daqiqalik `overlap` (soat farqi uchun), 14 kunlik `maxLookback`.

- [x] Yagona koordinator
  → lib/changes/services/sync/catch_up_sync.dart
  → `CatchUpSync.run(context, mounted, reason:)` — barcha 4 chaqiruv nuqtasi
    shu yerdan o'tadi. Tartib: kategoriya → mahsulot → diskont (mahsulot
    kategoriya id'siga tayanadi).
  → Uzun oyna 6 soatlik bo'laklarga bo'linadi, har bo'lakdan keyin kursor
    saqlanadi (yarmida uzilsa bajarilgani qayta so'ralmaydi).
  → Bo'lak server limitiga (1000) urilsa — avval ikkiga bo'lib qayta so'raladi
    (3 marotabagacha), u ham yetmasa to'liq qayta yuklash.
  → Reentrancy guard: bir vaqtda bitta sinxron.

- [x] Yangilanishdan keyin bir martalik to'liq tenglashtirish
  → sync_cursor.dart `needsFullReload` — kursor yo'q bo'lsa ham true
  → Sabab: yangilanishgacha o'tkazib yuborilgan o'zgarishlarni notification'dan
    tiklab bo'lmaydi. Shu versiya birinchi marta ishga tushganda har bir kassa
    mahsulot/kategoriya/diskontni to'liq qayta yuklaydi va bir xil holatga
    keladi. Keyin kursor ishlaydi.

- [x] `getReceivedWS` endi `SyncFetchResult` qaytaradi (ok / received / truncated)
  → products_ws_service.dart:66, categories_ws_service.dart:21,
    discount_ws_service.dart:20
  → Butun tanasi try/catch ichida — timeout/parse xatosi endi chaqiruvchini
    yiqitmaydi, shunchaki `ok=false` bo'ladi va kursor joyida qoladi.

- [x] Chaqiruv joylari yangilandi
  → app.dart:207 (startup/NetworkSuccess) — endi mahsulot ham qamraladi
  → update_provider.dart:38 (har N daqiqa) — oyna hisobi olib tashlandi
  → sync_button_home.dart:64 (qo'lda "Yangilash")
  → ws_service.dart:112 (WS ulanganda, agar keyinchalik yoqilsa)

- [x] `autoUpdate` ikki marta ishga tushmaydi
  → update_provider.dart:17 `_autoUpdateRunning`
  → Sabab: har NetworkSuccess da yangi cheksiz `while(true)` halqa
    qo'shilib borardi. `interval <= 0` da umuman ishga tushmaydi
    ("Незачем" tanlanganda tight loop bo'lish xavfi ham yopildi).

- [x] O'lik kod tozalandi: `autoUpdate2`, `AppState.startTime/endTime`,
  `WsService.startTime/endTime`, `lastTimeForDisAndCat`, `previousDay`

- [x] Qo'lda to'liq yangilash kursorni surib qo'yadi
  → upd_bloc.dart:305 `_advanceCursor` (galochkali dialog: Mahsulotlar /
    Kategoriya / Chegirmalar)
  → sync_bloc.dart:83 (drawer'dagi sinxronizatsiya — faqat mahsulot)
  → Sabab: bu dialoglar ma'lumotni to'liq qayta tortadi, notification
    tarixiga ehtiyoj qolmaydi. Ilgari kursor joyida qolib, keyingi
    avto-sinxron allaqachon qo'llangan eski notification'larni qayta
    o'qirdi — bekorga ish va (agar biror o'zgarish notification bermagan
    bo'lsa) eski qiymat ustidan yozilib qolish xavfi.
  → Kursor yuklash **boshlangan** vaqtga suriladi, tugagan vaqtga emas:
    yuklash davomidagi o'zgarishlar notification orqali kelishi kerak.
  → `SyncBloc` da faqat mahsulot kursori suriladi — u yerdagi `_category()`
    xatoni yutib yuboradi, muvaffaqiyatiga ishonib bo'lmaydi.

- [x] Sekin oqimlar uchun 10 daqiqalik cheklov
  → stream_sync_runner.dart `minInterval`, catch_up_sync.dart
    `slowStreamInterval`
  → Mahsulot (narx, type 13) — cheklovsiz, har daqiqada. Kategoriya va
    diskont — 10 daqiqada bir.
  → Sabab: uchala oqimni har daqiqada so'rash backend yukini 3 barobar
    oshirardi. Kategoriya/diskont bunchalik tez o'zgarmaydi.
  → `force: true` — ilova ochilganda, tarmoq tiklanganda, qo'lda
    "Yangilash"da va WS ulanganda cheklov chetlab o'tiladi.
  → Kursor umuman yo'q bo'lsa ham cheklov ushlab turmaydi (birinchi
    to'liq yuklash kechikmasin).
  → Diskont bundan tashqari `DiscountAutoSyncService` orqali ham har 10
    daqiqada to'liq ro'yxat bilan tenglashtiriladi — qarang "Ochiq savollar".

- [x] Kursor mantig'i `BuildContext`dan ajratildi
  → lib/changes/services/sync/stream_sync_runner.dart
  → Sabab: asosiy kafolatni ("kursor faqat muvaffaqiyatdan keyin suriladi")
    testda tekshirish uchun HTTP va UI dan mustaqil bo'lishi kerak edi.
    `CatchUpSync` endi faqat simlarni ulaydi.

- [x] Testlar — 36 ta yangi
  → test/sync_window_test.dart (6) — bo'laklash uzluksizligi, chegaradan
    oshmaslik, maxChunks, noto'g'ri parametrlarda cheksiz halqa yo'qligi
  → test/sync_cursor_test.dart (12) — **vaqt konvensiyasi**: format UTC
    devor-soatini beradi (mahalliy emas), commit/raw instant buzilmaydi,
    oqimlar bir-birini bosmaydi, overlap va maxLookback
  → test/stream_sync_runner_test.dart (20) — kursor yiqilganda surilmaydi,
    keyingi chaqiruv uzilgan joydan davom etadi, "kassa 3 kun o'chiq turdi"
    stsenariysi, limitga urilish → bo'lish → to'liq yuklash, qo'lda to'liq
    yangilashdan keyin eski oyna qayta so'ralmasligi, 10 daqiqalik cheklov
    va `force` bilan chetlab o'tish
  → test/items_bulk_write_test.dart (5) — **katta hajm**: 30 000 mahsulot,
    takroriy yuklashda ikkilanmaslik, o'chirilgan mahsulot yo'qolishi,
    5000 lik notification paketi, barcode keshi filtri

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] **Windows do'kon sinovi (asosiy):** 2 kassa. A kassa yopiladi →
      B kassada (yoki adminkada) narx o'zgartiriladi → A ochiladi →
      1-2 daqiqada yangi narx tushishi kerak.
- [ ] Log'dan tekshirish: `GET /notifications?...type=...13...` so'rovida
      `start_date` kassa o'chgan vaqtga yaqin bo'lishi kerak (ilgari
      `start_date ≈ end_date` edi). Log 24 soatda o'chadi — sinov kunida qarash kerak.
- [ ] Backend'dan `offset=1` semantikasini aniqlash (qator siljishimi yoki
      1-sahifami). Agar qator siljishi bo'lsa — har so'rovda 1 ta notification
      tushib qolyapti, `offset=0` bo'lishi kerak.
- [ ] WebSocket'ni qayta yoqish masalasini hal qilish (hozir butunlay o'chiq —
      jonli yangilanish yo'q, faqat 1 daqiqalik polling).

## Qabul qilingan qarorlar
- **Kursor per-stream, umumiy emas** — bir oqim yiqilsa, boshqasi to'xtamasin.
- **Kursor faqat muvaffaqiyatdan keyin suriladi** — bu butun tuzatishning o'zagi.
- **Overlap 2 daqiqa** — kassa/server soat farqida chegaradagi notification
  tushib qolmasligi uchun. Takror qo'llash xavfsiz: barcha amallar id bo'yicha
  `put`/`delete` (idempotent).
- **maxLookback 14 kun** — bundan eski kursorda notification o'rniga to'liq
  qayta yuklash.
  ⚠️ Dastlab sabab "server tarixni saqlamasligi mumkin" deb o'ylangan edi.
  2026-08-12 da aniqlandi: **server notification'larni o'chirmaydi**
  (foydalanuvchi tasdiqladi). Ya'ni chegara endi ishonchlilik uchun emas,
  **tezlik uchun**: 14 kunlik gap = 56 oyna × 3 oqim ≈ 168 so'rov, to'liq
  yuklash esa 3 so'rov. Kerak bo'lsa chegarani pasaytirish mumkin
  (masalan 3 kun ≈ 36 so'rov) — qarang "Ochiq savollar".
- **Bo'lak 6 soat** — bitta so'rov limitga urilmasligi va progress saqlanishi
  o'rtasidagi muvozanat.
- **`lastSyncTime`** endi faqat to'liq muvaffaqiyatli sinxrondan keyin yoziladi —
  bosh ekrandagi ko'rsatkich haqiqatni ko'rsatadi.

## So'rov yuki (o'zgarishdan keyin)

| Holat | Ilgari | Endi |
|---|---|---|
| Oddiy rejim (daqiqasiga) | 1 (faqat mahsulot) | 1 + har 10 daq. 2 ta ≈ **1.2** |
| Ilova ochilganda | 2 (kategoriya + diskont) | 3 (yoki gap bo'lsa ko'proq) |
| 1 kunlik gap (bir martalik) | — (umuman olinmasdi) | ~15 (5 oyna × 3 oqim) |

Kategoriya va diskont ilgari ish kuni davomida **umuman** yangilanmasdi
(faqat ilova qayta ochilganda) — endi 10 daqiqada bir yangilanadi.

## Yopilgan savollar
- ✅ **Server notification'larni o'chiradimi?** — YO'Q, saqlanib qoladi
  (foydalanuvchi 2026-08-12 da tasdiqladi). Ya'ni kassa qancha vaqt o'chiq
  tursa ham, o'sha davrdagi notification'lar joyida turadi va kursor
  bo'yicha so'ralganda qaytadi. Bu — catch-up yo'lining ishonchliligi
  bo'yicha eng katta noma'lum edi.

## Ochiq savollar
- `maxLookback` ni pasaytirish kerakmi? Server tarixni saqlagani uchun
  chegara faqat tezlik masalasi bo'lib qoldi. 14 kun = ~168 so'rov,
  3 kun = ~36 so'rov + to'liq yuklash. Do'kon internetining tezligiga
  qarab qaror qilinadi.
- `offset=1` — backend semantikasi noaniq (yuqoriga qarang).
- WebSocket ataylab o'chirilganmi yoki tasodifanmi? — foydalanuvchi/jamoa
  javob berishi kerak.
- `ProductsWsService.import()` mahsulotlar ro'yxati bo'sh bo'lsa `false`
  qaytaradi (xato bilan bo'sh natijani ajratmaydi). Do'konda 0 ta mahsulot
  bo'lsa kursor commit bo'lmay, har sinxronda to'liq import takrorlanadi.
  Amalda uchramaydi, lekin `import()` natija turini aniqlashtirish kerak.
- **Diskont ikki marta qoplangan.** `DiscountAutoSyncService` har 10 daqiqada
  to'liq ro'yxatni olib diff-merge qiladi (bu notification'dan kuchliroq —
  serverda yo'q diskontni ham o'chiradi). Shu bilan birga catch-up ham
  diskont notification'ini 10 daqiqada bir so'raydi. Davriy holat uchun bu
  ortiqcha. Variant: diskontni davriy catch-up dan butunlay chiqarib,
  faqat `force` (ilova ochilganda / qo'lda) holatida qoldirish.
  Qaror foydalanuvchida.
- `sendReceivedWS` (DELETE /notifications = o'qildi belgilash) kommentda.
  Kursor bo'lgani uchun endi shart emas, lekin server tomonda notification'lar
  cheksiz to'planib boradi.

## Test / Verifikatsiya
- `flutter analyze` — 0 error (yangi warning yo'q)
- `flutter test` — **412/412 o'tdi** (shundan 43 tasi yangi)

### Vaqt konvensiyasi (tekshirilgan)
Hamma joyda **UTC**, mahalliy vaqt hech qayerda so'rovga tushmaydi:
- kursor Hive'da `millisecondsSinceEpoch` sifatida saqlanadi — bu absolyut
  instant, zonaga bog'liq emas (`DateTime.now().millisecondsSinceEpoch` ==
  `DateTime.now().toUtc().millisecondsSinceEpoch`)
- o'qishda `fromMillisecondsSinceEpoch(..., isUtc: true)`, `add`/`subtract`
  UTC belgisini saqlaydi
- `SyncCursor.format` UTC devor-soatini beradi — test buni Toshkent zonasida
  ham tekshiradi (`09:30` UTC `14:30` bo'lib ketmaydi)

Backend UTC kutishining dalili: eski kod ham `toUtc()` ishlatgan va har
daqiqalik polling ishlaydigan kassalarda ishlab turgan. Agar server mahalliy
vaqt kutganda edi (+5 soat), 5 daqiqalik oyna hech qachon natija
qaytarmasdi va **hech bir** kassa yangilanmasdi.

`"timezone": "-300"` header'i o'zgartirilmadi — u eski kodda ham shunday edi.

### Katta hajm (o'lchangan, macOS/Hive)
- `clearAndPutItems(30 000)` + `storeProducts()` — **~165 ms**
- `putItems(5 000)` + `storeProducts()` — **~16 ms**
- Takroriy to'liq yuklash katalogni ikkilantirmaydi (`box.putAll` id bo'yicha)
- To'liq yuklash serverdan o'chirilgan mahsulotni lokaldan ham o'chiradi
  (`box.clear()` + `putAll`)
- Windows'da sekinroq bo'lishi mumkin, lekin tartib (order of magnitude)
  bir xil — sinxron UI ni bloklamaydi

### Qolgan sinov
- Do'kon sinovi (2 kassa) — kutilmoqda, reja pastda

## Qo'lda sinov rejasi (Windows kassa)

**Qanday kuzatiladi:** Alice network inspector — Sozlamalar → PIN (hozirgi
soat `HHmm` ko'rinishida, masalan 14:35 bo'lsa `1435`). U yerda
`GET .../notifications?...` so'rovlarining `start_date` / `end_date`
parametrlari va javoblari ko'rinadi. Bosh ekrandagi "oxirgi yangilanish"
vaqti esa `lastSyncTime` ni ko'rsatadi.

### A. Kritik — bularsiz relizga chiqarmaslik

| # | Case | Qadamlar | Kutilgan natija |
|---|---|---|---|
| A1 | Yangilanishdan keyin birinchi ochilish | Yangi versiyani o'rnatib ilovani och | Katalog to'liq qayta yuklanadi (notification so'rovi emas, `getItems`). Mahsulotlar soni to'g'ri, dublikat yo'q. Narxlar adminka bilan bir xil |
| A2 | **Asosiy stsenariy** — kassa o'chiq turdi | A kassani yop → adminkada narx o'zgartir → 1-2 soatdan keyin A ni och | 1-2 daqiqada yangi narx savatda ko'rinadi. Alice'da `type=...13...` so'rovi, `start_date` ≈ kassa o'chgan vaqt |
| A3 | Bir kunlik uzilish | A kassani kechqurun yop → ertasi ertalab och | Alice'da bir nechta ketma-ket so'rov (~5 ta), oynalar uzluksiz. Narx to'g'ri |
| A4 | Internet uzilishi | Sinxron ketayotganda kabelni uz → 2 daqiqadan keyin ula | Kursor orqaga ketmaydi, uzilgan joydan davom etadi. Bir xil oyna qayta-qayta so'ralavermaydi |
| A5 | Savat ochiq holda sinxron | Savatga 3-4 mahsulot qo'sh → 1 daqiqa kut (avto-sinxron) | Savat tozalanmaydi, narxlar o'zgarmaydi, ekran sakramaydi |

### B. Muhim — funksional

| # | Case | Qadamlar | Kutilgan natija |
|---|---|---|---|
| B1 | Qo'lda "Yangilash" (bosh ekrandagi InVan logotipi) | Logotipni bos → Yangilash | Uchala oqim ham so'raladi (kategoriya + mahsulot + diskont), 10 daqiqalik cheklov ishlamaydi |
| B2 | Galochkali to'liq yangilash | Mahsulotlar galochkasini qo'yib Yangilash | To'liq yuklanadi. **Keyin** avto-sinxron eski oynani qayta so'ramaydi — Alice'da qisqa oyna ko'rinadi |
| B3 | Drawer → Sinxronizatsiya | Drawer'dan sinxronni ishga tushir | Mahsulotlar yangilanadi, keyingi avto-sinxron oynasi qisqaradi |
| B4 | Kategoriya ish kuni davomida | Adminkada kategoriya qo'sh/o'zgartir | 10 daqiqa ichida kassada ko'rinadi (ilgari faqat qayta ochilganda ko'rinardi) |
| B5 | Diskont ish kuni davomida | Adminkada diskont yarat | 10 daqiqa ichida qo'llanadi |
| B6 | 10 daqiqalik cheklov | Alice'ni ochib 5 daqiqa kuzat | Mahsulot so'rovi har daqiqada, kategoriya/diskont — 10 daqiqada bir |

### C. Regressiya — tegilgan joylar buzilmaganini tekshirish

| # | Case | Qadamlar | Kutilgan natija |
|---|---|---|---|
| C1 | Avto-sinxron halqasi | Ilovani ochib 5 daqiqa kuzat | Har daqiqada bitta mahsulot so'rovi. To'xtab qolmaydi, ikkilanmaydi |
| C2 | "Oxirgi yangilanish" ko'rsatkichi | Bosh ekranda vaqtga qara | Har muvaffaqiyatli sinxrondan keyin yangilanadi. Internet yo'q bo'lsa **qotib turadi** (ilgari yolg'on yangilanardi) |
| C3 | Mahsulot o'chirish (type 3) | Adminkada mahsulot o'chir | 1 daqiqada kassadan yo'qoladi |
| C4 | Yangi mahsulot (type 1/2) | Adminkada mahsulot qo'sh | 1 daqiqada kassada paydo bo'ladi, kategoriyasi to'g'ri |
| C5 | To'lov turi (type 40) | Adminkada CLICK yoki UZUM ni yoq/o'chir | 1 daqiqada to'lov ekranida o'zgaradi |
| C6 | MXIK yangilanishi (type 20/21) | MXIK o'zgarishini ishga tushir | Markirovkali mahsulot MXIK'i yangilanadi |
| C7 | Katta katalog | 10 000+ mahsulotli do'konda och | Ochilish sezilarli sekinlashmaydi, UI qotmaydi |
| C8 | Ikki marta bosish | Yangilash tugmasini ketma-ket 3 marta bos | Bitta sinxron ketadi (guard), so'rovlar takrorlanmaydi |
