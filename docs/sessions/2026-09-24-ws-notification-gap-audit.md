# Task: Adminkada qo'shilgan mahsulot kassaga yetib bormasligi — notification tirqichlarini yopish

**Boshlangan:** 2026-09-24
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Adminkada yangi mahsulot yaratilgan, kassalarda chiqmagan; faqat qo'lda
"to'liq yangilash"dan keyin topilgan. Sabab noma'lum edi ("WS kelmadimi,
internet pastmi"). Butun notification/sinxron yo'li chuqur tekshirilib,
o'zgarish (mahsulot, narx, kategoriya, diskont) o'tkazib yuboriladigan
BARCHA tirqichlar yopiladi.

## Avvalgi implementatsiya
docs/sessions/archive/2026-08-12-multi-kassa-price-sync-gap.md (Yakunlangan 2026-09-07)
↑ U yerda SyncCursor + CatchUpSync qurilgan (kursor faqat muvaffaqiyatdan
keyin suriladi). Bu hujjat o'sha mexanizmda QOLGAN tirqichlarni yopadi.

docs/sessions/archive/2026-08-21-price-sync-missing-on-some-kassas.md (Yakunlangan 2026-09-07)
↑ U yerda connectivity gate olib tashlangan, `_running` deadlock va
`category_ids` null nomzod sifatida yozib qoldirilgan (tuzatilmagan) edi.

## Muhim fakt (avval noto'g'ri tushunilgan)
**WebSocket butunlay o'chiq** — `connectWebSocket` ning hech bir chaqiruvi
faol emas. "WS notification" deb ataladigan narsa aslida har 1 daqiqada
`GET ws.notification.7i.uz/notifications?...start_date&end_date` **polling**.
Ya'ni "xabar yo'qolishi" = polling oynasi noto'g'ri yoki qo'llashda xato.

## Topilgan tirqichlar (tahlil)

| # | Tirqich | Oqibat | Simptomga mosligi |
|---|---|---|---|
| G1 | **Kassa soati serverdan 2+ daqiqa OLDINDA** bo'lsa: `end = DateTime.now()` kassa soati, kursor shu vaqtga yoziladi, keyingi oyna `kursor-2min` dan boshlanadi — server vaqti bo'yicha oradagi notification'lar HECH QACHON so'ralmaydi. Windows'da timezone noto'g'ri (masalan UTC+3 qo'yilib soat qo'lda to'g'rilangan) bo'lsa UTC 2 soat oldinda → HAMMA notification yo'qoladi, faqat to'liq yuklash ishlaydi | Jim, doimiy yo'qotish | **100%** ("faqat full update qilsa topiladi") |
| G2 | **Bitta buzuq notification butun oynani abadiy bloklaydi.** `images: []` → RangeError, `category_ids: null` → TypeError. `getReceivedWS` butun oynani `failed` deb qaytaradi → kursor joyida → har daqiqa o'sha xato → 14 kungacha yoki qo'lda to'liq yangilashgacha HECH NARSA (narx ham) yangilanmaydi. Barcha kassalarda birdek | Jim, doimiy to'xtash | **100%** (hamma kassa + faqat full update yordam beradi) |
| G3 | type 2 (update) payload'da `shop_prices` bo'lmasa `putItems` mahsulotni to'liq ustidan yozadi → narx yo'qoladi | Narx 0 → barcode skanerida topilmaydi (`barcodeProducts` price>0 talab qiladi) | Yuqori |
| G4 | type 13 (narx) `shopPrices == null` mahsulotga qo'llanmaydi (`editItem` faqat mavjud tier ro'yxatini yangilaydi). Mahsulot avval boshqa do'kon uchun yaratilib keyin shu do'konga narx qo'yilsa — narx hech qachon kelmaydi | Skanerda topilmaydi, faqat full update | Yuqori |
| G5 | type 0 (serverdan "to'liq qayta yukla") ichidagi `import()` yiqilsa ham oyna `done` → kursor suriladi → buyruq yo'qoladi | Ommaviy import kassaga yetmaydi | O'rta |
| G6 | `_running` deadlock: `downloadFile` timeoutsiz (`HttpClient` xom), 43 MB yuklash osilsa `finally` ishlamaydi → har daqiqalik sinxron `return false` — restartgacha | Sinxron butunlay o'ladi | O'rta |
| G7 | `autoUpdate` halqasi `try/catch`siz — Hive yozuvi (Windows'da antivirus/lock) istisno tashlasa halqa o'ladi, faqat internet o'zgarganda qayta tiklanadi | Sinxron o'ladi | O'rta |
| G8 | Har notification'dan keyin `storeProducts()` (57k mahsulotni qayta yuklash) — 500 ta narx o'zgarishi = UI 30-60 s qotadi | Sekinlik | Past |
| G9 | Notification'lar `created_at` bo'yicha tartiblanmaydi — server desc qaytarsa eski create yangi update ustidan yozadi | Eski ma'lumot | O'rta |
| G10 | Timeout 20 s; katta oyna (1000 × 3KB) sekin internetda har safar timeout → o'sha oyna abadiy takrorlanadi | Doimiy to'xtash | O'rta |
| G11 | Qo'lda to'liq yangilash (UpdBloc/SyncBloc/startup) CatchUpSync bilan parallel ishlaydi — yuklash davomida kelgan mahsulot `clearAndPutItems` bilan o'chib, kursor esa o'tib ketishi mumkin | Yuklash paytidagi mahsulot yo'qoladi | Past |
| G12 | Sinxron xatolari faqat `kDebugMode` da print — do'konda hech narsa ko'rinmaydi | Diagnostika yo'q | — |
| G13 | Diskont qo'llash `await`siz — xato yutiladi, kursor baribir suriladi | Diskont yo'qoladi | Past |
| G14 | Yangi kategoriya hali lokalda bo'lmasa `getCategories()` null → mahsulot kategoriyasiz qoladi (id ham saqlanmaydi) | Kategoriya bo'yicha ko'rinmaydi | Past |

### Rad etilgan gipotezalar
- `acceptService` ≠ `storeId` — ikkalasi `selectedStore.id` (apd_bloc_bloc.dart:242,250).
- `internet_connection_checker` boshlang'ich holatni chiqarmaydi — chiqaradi
  (`_lastStatus` null ≠ current → emit), ya'ni startup'da NetworkSuccess bor.
- `offset=1` / `is_read` (08-21 da jonli tekshirilgan).

### Tekshirib bo'lmagan (backend savoli)
- `is_read` GLOBALmi? Admin panel/InVan 1/boshqa klient notification'ni
  "o'qildi" deb belgilasa, `is_read=false` filtri bilan kassa uni ko'rmaydi.
- Server `notifications` ni qaysi tartibda qaytaradi (asc/desc)?
- Mahsulotga tegishli boshqa `type` lar bormi (hozir 0,1,2,3,6,13,20,21,40)?

## Scope
- lib/changes/services/sync/ (server_clock.dart yangi, notification_fetch.dart yangi,
  stream_sync_runner.dart, sync_cursor.dart, catch_up_sync.dart)
- lib/changes/services/web_socket_service/{product,category,discount}/*_ws_service.dart
- lib/features/get_products/singletons/items_singleton.dart (editItem, putItems)
- lib/changes/models/product/item_model.dart (xavfsiz parser)
- lib/changes/services/get_items_service.dart (downloadFile timeout)
- lib/changes/services/api/api_provider.dart (ServerClock hook)
- lib/changes/providers/update_provider.dart, upd_bloc.dart, sync_bloc.dart, wrapper.dart
- Scope'dan tashqari: WebSocket'ni qayta yoqish, backend o'zgarishlari

## Bajarilgan

- [x] G1 — Server soati (`ServerClock`)
  → lib/changes/services/sync/server_clock.dart (yangi)
  → lib/changes/services/api/api_provider.dart (POST/GET/PUT javobidan `date` o'qiladi)
  → lib/changes/services/sync/notification_fetch.dart (notification javobidan ham)
  → lib/utils/constants/pref_keys.dart `serverClockOffsetMs`
  → Sabab: `CatchUpSync.run` endi `end = ServerClock.nowUtc()`; kursor
    `SyncCursor.clamp(end, serverTime)` bilan yoziladi — hech qachon server
    "hozir"idan oldinga o'tmaydi. Farq Pref'da saqlanadi; |farq| ≥ 2 daqiqa
    bo'lsa log'ga `SYNC_CLOCK_SKEW` yoziladi (kassa soatini tuzatish belgisi).
  → `SyncCursor.needsFullReload`: kursor `end + overlap` dan keyinda bo'lsa
    (soat sakragan / eski versiya noto'g'ri soat bilan yozgan) → to'liq yuklash
    va kursor server vaqtiga qaytadi. Yangilanishdan keyingi birinchi
    ishga tushishda o'z-o'zini tuzatadi.

- [x] G2, G9, G10, G12, G13 — yagona notification olish moduli
  → lib/changes/services/sync/notification_fetch.dart (yangi)
  → lib/changes/services/web_socket_service/{product,category,discount}/*_ws_service.dart
    (uchalasi shu modul ustiga qayta yozildi; faqat "bitta notification'ni
    qanday qo'llash" qoldi)
  → Har notification alohida try/catch: xato → `SYNC_APPLY_FAILED` log +
    `applyFailed` bayrog'i; `StreamSyncRunner` shunday oynadan keyin to'liq
    yuklash qiladi va kursorni suradi (`SYNC_FULL_RELOAD why=...`).
  → `created_at` bo'yicha barqaror tartiblash (eski create yangi update
    ustidan yozmasin).
  → Timeout 20 s → 45 s; `TimeoutException` alohida (`timedOut`) — uzun
    oyna (≥30 daqiqa) bir marta ikkiga bo'linadi; oqim bo'lagi doimiy
    yarimlanadi (6 soat → ... → 15 daqiqa, `SyncCursor.chunk`), muvaffaqiyatda
    qaytadi. Sekin internetda "o'sha oyna abadiy timeout" holati yo'q.
  → Diskont qo'llash endi `await` bilan.
  → `storeProducts()` + `CategorySingleton.init()` oyna oxirida BIR marta
    (`afterBatch`), har notification'dan keyin emas (G8).
  → Type 0 (`import()`) yiqilsa `NotifyApply.abort` → oyna failed, kursor
    joyida (G5).
  → Log hodisalari (request_logs_of_invan_pos.txt): SYNC_FETCH_TIMEOUT,
    SYNC_FETCH_ERROR, SYNC_FETCH_HTTP, SYNC_FETCH_PARSE, SYNC_APPLY_FAILED,
    SYNC_APPLY_ABORT, SYNC_APPLIED, SYNC_FULL_RELOAD(_FAILED),
    SYNC_CHUNK_SHRINK, SYNC_RUN_INCOMPLETE, SYNC_CRASH, SYNC_LOOP_ERROR,
    SYNC_STALE_LOCK, SYNC_LOCK_FORCED, SYNC_CLOCK_SKEW.

- [x] G2 — parserlar xavfsiz
  → lib/changes/models/product/item_model.dart `firstImageUrl` (`images: []`
    RangeError yo'q; ikkala WS konstruktor)
  → products_ws_service.dart `categoriesFromIds` (`category_ids: null` TypeError
    yo'q); `getCategories` kategoriya lokalda bo'lmasa ham id'ni saqlaydi va
    `CatchUpSync.requestCategoriesRefresh()` — keyingi tsiklda kategoriya
    oqimi 10 daqiqalik cheklovsiz so'raladi (G14).

- [x] G3 — type 2 payload'da `shop_prices` bo'lmasa narx saqlanadi
  → items_singleton.dart `putItems(keepExistingPriceIfMissing:)`
  → products_ws_service.dart `_upsert` — `data['shop_prices'] == null` bo'lsa true
  → Sabab: `shop_prices` kaliti bor-u, lekin bizning do'kon yo'q bo'lsa —
    bu haqiqiy "narx yo'q" (ustidan yoziladi). Kalit umuman bo'lmasa —
    payload narx haqida gapirmayapti (saqlanadi).

- [x] G4 — type 13 narx `shopPrices == null` mahsulotga ham qo'llanadi
  → items_singleton.dart `editItem` (endi `Future<int>` — nechta yangilandi)
  → Mezon: notification `shop_id == PrefKeys.storeId` (yoki mahsulotdagi
    mavjud do'kon). Tier ro'yxati yo'q bo'lsa o'tkazib yuboriladi.

- [x] G6 — `downloadFile` timeout
  → lib/changes/services/get_items_service.dart: ulanish 30 s, bo'laklar
    orasidagi sukut 90 s (umumiy chegara emas — 43 MB sekin internetda uzoq
    yuklanishi mumkin), `HttpClient` `finally`da yopiladi; `getItems()` endi
    istisno tashlamaydi (`isSuccess=false`).
  → catch_up_sync.dart `staleLock` 20 daqiqa — qulf shundan uzoq band bo'lsa
    keyingi chaqiruv `SYNC_STALE_LOCK` bilan majburan oladi.

- [x] G7 — avto-sinxron halqasi o'lmaydi
  → lib/changes/providers/update_provider.dart: tsikl ichida try/catch +
    `SYNC_LOOP_ERROR`; catch_up_sync.dart `run` ham try/catch (`SYNC_CRASH`).

- [x] G11 — qo'lda/startup to'liq yuklash sinxron qulfi ostida
  → catch_up_sync.dart `exclusive(body, reason:)` (3 daqiqagacha kutadi,
    keyin `SYNC_LOCK_FORCED` bilan davom etadi); qulf endi ticket asosida
    (stale takeover xavfsiz).
  → upd_bloc.dart `_category/_discounts/_items`, sync_bloc.dart `_syncLocked`,
    wrapper.dart `_syncCatalogOnStartup` — hammasi `exclusive` ichida.
  → Startup to'liq yuklashi muvaffaqiyatli bo'lsa mahsulot kursori yuklash
    boshlangan SERVER vaqtiga suriladi (UpdBloc bilan bir xil; ilgari startup
    kursorga tegmas, keyingi tsikl kechagi oynalarni bekorga qayta so'rardi).
  → Barcha kursor commit'lari `ServerClock.toServer(localStart)` — yuklashdan
    KEYIN o'tkaziladi (o'sha paytda farq aniq).

- [x] Testlar (yangi/kengaytirilgan)
  → test/server_clock_test.dart (7) — farq o'rganish, header parse, Pref
  → test/stream_sync_runner_test.dart (+12) — server vaqti qisqartirish,
    soat sakrashi → to'liq yuklash, applyFailed → to'liq yuklash, bo'lingan
    oynada bayroq yo'qolmasligi, timeout bo'lish/bo'lmaslik, moslashuvchan
    bo'lak
  → test/notification_fetch_test.dart (17) — MockClient: tartib, izolyatsiya,
    abort, afterBatch bir marta, URL/token, `date`, timeout vs tarmoq xatosi,
    500, buzuq JSON, null, truncated
  → test/items_singleton_notification_test.dart (15) — editItem narx yaratish/
    boshqa do'kon/tiers yo'q, putItems narx saqlash, images [] / category_ids
    null, kategoriya id saqlanishi

## 2-bosqich: keng qamrovli audit (workflow, 2026-09-24)

Foydalanuvchi so'rovi: "bularsiz muammolar yopildimi — o'chgan/internet
uzilgan/soat noto'g'ri kabi HAMMA holatda ishlashi kerak, biz o'ylamagan
narsa ham bo'lishi mumkin". Ko'p-agentli workflow bilan 48 ta stsenariy
(oflayn N kun, internet uzilishi turlari, soat sakrashi, poyga holatlari,
server holatlari, buzuq payload'lar, ...) har biri kodni qadam-baqadam
kuzatib, 2 ta mustaqil skeptik tomonidan tekshirildi. Natija: 36 ta
`gap`/`partial` (asosan "mos, lekin bitta chekka holat qopqoqsiz"), 12 ta
`handled` (allaqachon to'g'ri ishlaydi, tasdiqlandi).

Eng jiddiy (yuqori) topilganlar — HAMMASI shu sessiyada tuzatildi:

1. **Sekin internetda 15 daqiqalik bo'lak ham timeout bo'lsa oqim ABADIY
   qotib qolardi** (45 s umumiy timeout, bo'lish/kichraytirish tugagach
   hech qanday zaxira yo'q edi).
2. **Token eskirsa (401) sinxron abadiy jim muzlab qolardi** — hech qanday
   kod 401 ni aniqlamasdi, kursor cheksiz joyida qolardi.
3. **Hive fayli buzilsa/bo'shab qolsa** (svet o'chishi, `box.clear()`
   o'rtasida ilova o'lishi) — kursor "hammasi bor" deb turaverar, keyingi
   sinxron hech narsa qilmasdi.
4. **`company_id`/`storeId` bo'sh bo'lsa** — so'rov ma'nosiz ketardi, hech
   qanday tekshiruv yo'q edi.
5. **O'lchov birligi / QQS** faqat aktivatsiya va qo'lda "Servis" bosqichida
   yangilanardi — notification kelgan mahsulotda bular bo'sh obyekt bo'lib
   qolishi mumkin edi.

### Bajarilgan (audit asosida)

- [x] **Timeout arxitekturasi qayta qurildi**
  → notification_fetch.dart: umumiy 45 s o'rniga ulanish+sarlavha (30 s) +
    bo'laklar orasidagi sukut (45 s, `idleTimeout`) — sekin, lekin oqib
    kelayotgan javob endi to'xtamaydi.
  → stream_sync_runner.dart: eng kichik bo'lak (`minChunk`=15 daq) ham
    timeout bo'lsa endi to'liq yuklashga o'tadi (`fullReloadTimeout`=15 daq
    bilan cheklangan holda).
  → Bo'lak kichrayishi (`sawTimeout`) faqat `window.length >= minChunk`
    bo'lganda hisoblanadi — 3 daqiqalik chekka oynaning timeout'i bekorga
    bo'lakni kichraytirmaydi (test bilan tasdiqlangan ikkala uchi).

- [x] **Token/401 ishlov berish**
  → sync_cursor.dart `SyncFetchResult.unauthorized`; notification_fetch.dart
    401/403 ni aniqlaydi va `SYNC_UNAUTHORIZED` yozadi; stream_sync_runner
    qayta urinmasdan to'xtaydi (foydasiz urinishlarni to'xtatadi, lekin
    kursor joyida qoladi — token tuzatilgach avtomatik davom etadi).
  → backend_health.dart `isDocumentRejection`: 401/403/408/429 endi
    "hujjat rad etildi" EMAS (ilgari refund/chek bular tufayli abadiy
    "rad etilgan" deb navbatdan chiqib ketardi va token tuzatilgandan
    keyin ham qayta yuborilmasdi).

- [x] **Katalog/kategoriya yozuvi atom(ga yaqin)laştirildi**
  → items_singleton.dart `clearAndPutItems`: avval yoziladi, keyin eskilar
    o'chiriladi (clear+putAll emas) + `catalogWriteInProgress` marker +
    `box.flush()`. O'rtada ilova o'lsa katalog bo'sh/yarim qolmaydi.
  → category_service.dart va sync_bloc.dart: xuddi shu tartib kategoriya
    uchun.
  → category_service.dart: type 10/11/12 endi **id bo'yicha upsert**
    (`upsertCategories`) — ilgari `box.addAll` bilan 2 daqiqalik overlap
    tufayli bir kategoriya 2-3 marta dublikat bo'lib qo'shilardi.

- [x] **Lokal holat o'z-o'zini tuzatadi** (`CatchUpSync.healCatalogState`,
  har run boshida)
  → to'liq yozuv marker qolgan bo'lsa — mahsulot kursori tashlanadi;
  → `items`/`categories` box bo'sh bo'lsa (Hive buzuq faylni jimgina
    bo'shatib ochadi) — mos kursor tashlanadi → keyingi run to'liq yuklaydi.

- [x] **`company_id`/`storeId` tekshiruvi** — bo'sh bo'lsa `SYNC_CONFIG_MISSING`
  log va sinxron hech narsa yozmasdan to'xtaydi (ma'nosiz so'rov va noto'g'ri
  narx filtri oldi olinadi).

- [x] **Kursor monoton + qulf preemption**
  → sync_cursor.dart `commit(force:)`: oddiy commit ORQAGA yozmaydi (parallel
    qolib ketgan eski run yangi kursorni buzmasin); to'liq yuklash `force`
    bilan qayta o'rnatadi.
  → catch_up_sync.dart: `epoch` (logout/token almashganda oshadi) +
    `shouldContinue`/`owns(ticket)` — qulf majburan olinganda (yoki logout
    bo'lganda) eski run keyingi fetch/commit oldidan o'zini tekshiradi va
    `SYNC_RUN_PREEMPTED` bilan hech narsa yozmasdan to'xtaydi.
  → `CatchUpSync.exclusive(forceAfterWait:)` — startup majburlamaydi (kutadi),
    kassir tugmasi 3 daqiqadan keyin majburlaydi.
  → `CatchUpSync.tryExclusive` — fon ishlari (diskont avto-sinxroni) band
    bo'lsa shunchaki keyingi tsiklga qoladi.

- [x] **Barcha qulfsiz to'liq yuklash yo'llari qulf ostiga olindi**
  → `catalog_refresh_notice.dart` ("baza yangilanmagan" dialogi),
    `discount_auto_sync_service.dart` (10 daqiqalik to'liq ro'yxat),
    `auth_reset.dart` (logout) — hammasi endi `CatchUpSync.exclusive`/
    `tryExclusive` ichida.

- [x] **Startup ikki marta 43 MB yuklamaydi**
  → wrapper.dart: `NetworkSuccess` catch-up allaqachon to'liq yuklagan
    bo'lsa (`lastFullCatalogSyncAt >= startedAt`), startup reload
    o'tkazib yuboriladi.
  → `UpdateProvider.autoUpdate` endi startup'da SHARTSIZ boshlanadi
    (ilgari faqat `NetworkSuccess`ga bog'liq edi — do'kon tarmog'ida
    `internet_connection_checker` probe'lari bloklansa halqa umuman
    ishga tushmasdi, API esa ishlab tursa ham).
  → "Baza yangilanmagan" dialogi endi katalog notification orqali to'liq
    yetib olinganda ham o'chadi (`CatalogRefreshNotice.clearPending`) —
    ilgari faqat to'liq yuklashdan keyin o'char, kassir asossiz 43 MB
    yuklashga undalardi.

- [x] **Parser va qo'llash tuzatishlari**
  → item_model.dart: `ownerType` endi type-1 (yaratish) notification'ida
    ham o'qiladi (ilgari faqat update'da — yangi mahsulot fiskal
    OwnerType'siz qolardi); o'lchov birligi/QQS avval ICHKI obyektdan
    (`json['vat']`/`json['measurement_unit']`, to'liq katalog kabi),
    topilmasa lokal box'dan, topilmasa **null** (bo'sh obyekt EMAS) —
    `putItems(mergeWithExisting)` mavjud qiymatni saqlaydi.
  → `ShopPriceTiers.fromJson`: `min_quantity`/`retail_price` double yoki
    satr kelsa ham yiqilmaydi (bitta buzuq tier butun 57k mahsulotlik
    importni to'xtatardi).
  → items_singleton.dart `putItems`: `is_active` YO'Q (null) bo'lsa endi
    mahsulot O'CHIRILMAYDI (ilgari `!(null ?? false)` → o'chirilardi);
    faqat aniq `false` o'chiradi. `mergeWithExisting`: narx (musbat
    bo'lmasa), ownerType, commissionTin, mark, o'lchov birligi, QQS —
    notification bilmagan/topolmagan maydonlar mavjud yozuvdan olinadi.
  → `parseCatalog` (yangi): to'liq katalogdagi bitta buzuq yozuv endi
    faqat o'zi o'tkazib yuboriladi (57k importni yiqitmaydi); barcha
    chaqiruvchilar (`products_ws_service._import`, `util_functions`,
    `sync_bloc.toHive`) shunga o'tkazildi.
  → products_ws_service.dart: type 3 (`ids` bo'sh/noto'g'ri shakl) va
    type 13 (`product_values` yo'q) endi XATO tashlaydi ("qo'llandi" deb
    yolg'on aytish o'rniga) → to'liq yuklash bilan qoplanadi.
  → **Tiriltirish himoyasi**: bitta oynada avval o'chirilgan mahsulotni
    (type 3) keyinroq kelgan create/update (bir soniya ichida, server
    tartibi teskari bo'lsa) qayta tiklamaydi — `deletedInBatch` xaritasi
    + `created_at` solishtirish.
  → **Type 0 endi oyna ichida emas** — `NotifyApply.fullReload` orqali
    runner'ning yagona to'liq yuklash yo'liga (backoff, timeout, kursor
    hammasi bitta joyda) yo'naltiriladi.

- [x] **Server "hozir"iga yetgach ortiqcha so'rov yo'q** — kassa soati
  oldinda bo'lganda (server vaqti `window.end` dan oldin) qolgan
  "kelajakdagi" oynalar so'ralmaydi (`stream_sync_runner.dart`, server
  javobidagi `date` bilan aniqlanadi).

- [x] **Run ichidagi bo'laklar orasida ham 2 daqiqalik overlap** — ilgari
  faqat alohida run'lar orasida bor edi; endi bitta run ichidagi ketma-ket
  bo'laklar ham (va timeout/limitga urilib bo'lingan yarmilar ham)
  bir-biridan 2 daqiqa ortga cho'ziladi — server chegarani qat'iy
  solishtirsa ham chegaradagi soniya tushib qolmaydi.

- [x] **Server soati host bo'yicha ajratildi**
  → server_clock.dart: sinxron kursori FAQAT notification serveri
    (`ws.notification.7i.uz`) soatiga tayanadi; API serveri (`api.7i.uz`)
    farqi faqat notification farqi hali noma'lum bo'lganda zaxira.
    Ikkala server soati bir-biridan bir necha daqiqa farq qilsa ham
    kursor bittasi tomonidan ikkinchisiga "aralashib" ketmaydi.
  → notification_fetch.dart: `Cache-Control: no-store`/`Pragma: no-cache`
    sarlavhalari — oraliq proksi eski javobni qaytarmasin.
  → `is_read` parametri avval OLIB TASHLANIB so'raladi (boshqa klient
    notification'ni "o'qildi" deb belgilasa ham kassa ko'rishi uchun);
    server buni rad etsa (400/422) BIR MARTA aniqlanadi va keyingi
    so'rovlar `is_read=false` bilan davom etadi (`serverRequiresIsRead`).
  → `created_at`: ISO 8601 dan tashqari epoch (soniya/millisekund, son
    yoki satr) ham o'qiladi; parse bo'lmagan holatlar soni log'ga
    (`SYNC_CREATED_AT_UNPARSED`) yoziladi.

- [x] **Kursor sxema migratsiyasi** — `SyncCursor.migrateIfNeeded()`
  (main.dart, har narsadan oldin): eski (kassa soatida yozilgan) kursorlar
  bu relizga yangilanishda BIR MARTA tashlanadi, uchala oqim to'liq
  yuklanadi va server-vaqt sxemasiga o'tadi (aks holda kassa soati oldinda
  bo'lgan eski kursor "kelajak"da qolib, birinchi run'da aniqlanmasligi
  mumkin edi — bu holat tahlil qilinib, migratsiya bilan yopildi).

- [x] **43 MB yuklashning o'zi isolate'da ochiladi** (`Isolate.run`,
  get_items_service.dart) — gzip+JSON parse UI oqimini endi qotirmaydi.

- [x] **tasnif.soliq.uz so'roviga timeout** (15 s) — ilgari timeout'siz edi
  va har to'liq yuklash undan boshlanardi; server javob bermasa BUTUN
  sinxron qulfi 20 daqiqagacha band bo'lib qolardi.

- [x] **DEV/PRO manzil yagona manbadan** — `Urls.baseNotificationUrl`/
  `baseSocketUrl` endi `ApiProvider.currentEnv`dan hisoblanadi (ilgari
  ikkita mustaqil konstanta edi — API DEV'da, notification PRO'da qolib
  ketishi mumkin edi, aynan shu holat ish daraxtida topildi va tuzatildi).

- [x] Testlar: +51 → **jami 1283 ta, hammasi o'tdi** (`flutter test`,
  2026-09-24). Yangi: category_ws_idempotent_test.dart (6); kengaytirilgan
  stream_sync_runner_test.dart (+~40: monoton kursor, preemption, server
  "hozir", 401, type 0, backoff, minChunk chegarasi, migratsiya),
  notification_fetch_test.dart (+~10: is_read fallback, 401, type 0,
  xato tana, epoch), items_singleton_notification_test.dart (+~15: merge
  semantikasi, is_active, ownerType/QQS saqlanishi, parseCatalog).
  `flutter analyze lib test` — 0 xato (yangi warning yo'q).

### Ataylab tuzatilmagan (audit topgan, past ustuvorlik yoki backend kerak)

- **DNS-only uzilish "server o'chgan" deb noto'g'ri tasniflanishi mumkin**
  (`BackendHealth._defaultProbe` hostname bo'yicha so'raydi) — DNS bilan
  server holatini ishonchli ajratish qo'shimcha tarmoq API kerak qiladi,
  bu safar qo'shilmadi.
- **Drawer "Sinxronizatsiya"** kategoriya kursorini commit qilmaydi (faqat
  samaradorlik — keyingi avto-sinxron ortiqcha oyna so'raydi, ma'lumot
  yo'qolmaydi).
- **Hive haqiqiy `fsync`** qilmaydi (`box.flush()` — Hive 2.2.3 ning eng
  yaxshi vositasi, OS darajasidagi kafolat yo'q). Qattiq svet o'chishida
  nazariy jihatdan bir necha soniyalik oyna qoladi; `beforeCommit` orqali
  ma'lumot kursordan OLDIN yoziladi — bu asosiy xavfni yopadi.
- **Backend savollari** (o'zgarmadi, pastga qarang) — `is_read` global
  semantikasi, notification tartibi, mahsulotga tegishli boshqa turlar
  bormi.

## 3-bosqich: qo'shimcha fon audit — bugungi tuzatishlarning O'ZIDAGI kamchiliklar (2026-09-24)

Birinchi audit tugagach, xuddi shu workflow foydalanuvchi so'rovi bilan
tezlashtirilgan holda qayta ishga tushirildi (48 stsenariy + 7 linzali
kashfiyot). Bu safar maqsad boshqacha edi: 2-bosqichda yozilgan YANGI
kodning O'ZI xato kiritmaganini tekshirish. Model sessiya limitiga urilib
sintez (yakuniy hisobot) tugallanmadi, lekin xom topilmalar (find/refute
jurnali) qo'lda o'qib chiqildi va HAR BIR muhim da'vo kod bo'ylab qayta
tekshirildi (workflow natijasiga ko'r-ko'rona ishonilmadi).

**Eng jiddiy topilma — KRITIK regressiya:** 2-bosqichda G7 ("avto-sinxron
NetworkSuccess'ga bog'liq") ni yopish uchun wrapper.dart'ga qo'shilgan
`unawaited(updateProvider.autoUpdate(context, mounted))` chaqiruvi
Wrapper'ning TEZDA unmount bo'ladigan context'i bilan ishga tushirilgan
edi — bu halqani birinchi tsikldayoq abadiy o'ldirar, `_autoUpdateRunning`
bayrog'i band qolib, TO'G'RI (NetworkSuccess) chaqiruvni ham bloklardi.
Ya'ni **butun sessiya davomida avtomatik sinxron umuman ishlamasligi**
mumkin edi — aynan shu hujjatning butun maqsadiga zid. Tuzatildi:
`update_provider.dart`, halqa endi har tsiklda `AppNavigation.navigatorKey.
currentContext` orqali yangi, doimiy context oladi.

**Qo'shimcha tasdiqlangan va tuzatilgan:**
- To'liq katalog yuklashda parse bo'lmagan (bitta buzuq maydonli) yozuv
  `clearAndPutItems`ning yangi "stale = yo'q bo'lganlarni o'chir" mantig'i
  tomonidan "serverda yo'q" bilan aralashtirilib O'CHIRILARDI —
  `parseCatalog` uni shunchaki o'tkazib yuborgani uchun. `preserveIds`
  bilan tuzatildi (items_singleton.dart + 3 chaqiruv joyi).
- Narx birlashtirish mezoni QIYMATGA (narx ≤0) emas, `shop_prices`
  KALITI borligiga asoslanadi — server ataylab narxni 0/olib tashlagan
  bo'lsa endi hurmat qilinadi.
- `total_count` javobda o'qiladi (server `limit`dan kichik sahifa
  cheklovi qo'ygan bo'lsa ham kesilish aniqlanadi).
- `is_read` parametrini olib tashlash TAJRIBASI BEKOR QILINDI — faqat
  2026-08-21'da jonli tekshirilgan `is_read=false` qoldirildi (tekshirilmagan
  so'rov shakli aynan yopmoqchi bo'lgan xato turini qaytarishi mumkin edi).
- To'liq yuklash 15 daqiqada `Future.timeout` bilan "to'xtatilsa" ham,
  Dart'da bu asl HttpClient ishini to'xtatmaydi — endi haqiqatan bekor
  qilinadi (`OrdersService.cancelCatalogDownload`).
- Type-1 notification parseri `categories` maydonini faqat sof id
  ro'yxati deb kutgan (type-2/bulk esa obyekt ro'yxati) — mos kelmasa
  butun notification yiqilardi. Ikkala shakl ham endi xatosiz o'qiladi.
- Drawer "Sinxronizatsiya" (qo'lda tugma) o'zining kamroq to'g'ri yozuv
  yo'liga ega edi (eski mahsulot o'chirilmasdi, kategoriya daraxti
  tekislanmasdi). Endi tekshirilgan umumiy metodlarga delegatsiya qiladi.

**Tasdiqlanmagan/rad etilgan da'volar (qo'lda tekshirilib, real emas yoki
allaqachon qoplangan deb topildi):** to'liq yuklash backoff vaqti hisobi,
ServerClock offset o'lchash vaqti, startup reload local-clock taqqoslash,
manual reload force commit, bo'sh katalogli kompaniya cheksiz reload,
Hive compaction xavfi, drawer sync stale delete (2-marta topilgan, allaqachon
tuzatilgan).

**Ataylab tuzatilmagan (past ustuvorlik yoki 2-bosqichdan OLDIN ham mavjud
bo'lgan xulq, regressiya emas):**
- `isMarking=true` mahsulotda abadiy "yopishib qoladi" (adminka uni false
  qilsa ham notification orqali qaytmaydi) — bu 2-bosqichdan OLDIN ham
  shunday edi (isMarking alohida soliq-MXIK moslashtirish job'iga
  ishonilgani uchun ataylab qilingan bo'lishi mumkin).
- Notification yo'lida faqat BITTA kategoriya (`category_ids.first`)
  saqlanadi, to'liq katalog esa butun ierarxiyani beradi — grid tilida
  mahsulot to'liq yuklashdan keyin boshqa katakka "sakrashi" mumkin.
  Bu ham OLDINDAN mavjud xulq.
- Bir soniya ichida type 13 (narx) type 1 (yaratish)dan OLDIN kelsa (server
  tartibi noma'lum) narx qo'llanmay qoladi — tor chekka holat.
- Qulf majburan olinganda (`exclusive` force, stale-lock, logout) eski
  run'ning JORIY oynasidagi qo'llash tsikli darhol to'xtamaydi (faqat
  keyingi fetch/commit oldidan tekshiriladi) — kengroq mavjud himoya
  (monoton kursor, epoch) asosiy xavfni yopadi, qolgani nozik race.

Xulosa: bu 3-bosqich ayni "avtomatik sinxron doim ishlaydi" da'vosini
tekshirish uchun zarur bo'ldi — 2-bosqichning o'zi bitta jiddiy regressiya
kiritgan edi. Endi hamma narsa qayta test qilindi (1290/1290).

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Do'kon sinovi (Windows, 2 kassa) — pastdagi "Test / Verifikatsiya" (RELIZDAN KEYIN BIRINCHI TEKSHIRUV)
- [ ] Backend jamoasidan `is_read` semantikasi va notification tartibi haqida
      javob olish (ochiq savollar)
- [ ] Do'kondagi kassalar soati/timezone tekshiruvi — log'da `SYNC_CLOCK_SKEW`
      chiqsa kassa soatini tuzatish (fiskal chek vaqtiga ham ta'sir qiladi)

## Qabul qilingan qarorlar
- Server vaqti HTTP `date` sarlavhasidan olinadi (ws.notification.7i.uz va
  api.7i.uz ikkalasi ham beradi — curl bilan tekshirildi). Kursor hech qachon
  server vaqtidan oldinga o'tmaydi.
- Buzuq notification oynani bloklamaydi: alohida log + oyna oxirida to'liq
  yuklash (fallback). Sabab: parser tushunmagan payload'ni to'liq yuklash
  (`fromJson`, boshqa endpoint) deyarli har doim to'g'ri qoplaydi.
- `is_read=false` filtri O'ZGARTIRILMADI — server parametrsiz 400 qaytarsa
  butun sinxron o'lardi; avval backend jamoasi tasdiqlashi kerak.

## Ochiq savollar
- Backend: `is_read` global yoki qurilma bo'yichami? — foydalanuvchi/backend
- Backend: notification tartibi va to'liq `type` ro'yxati — backend
- Do'kondagi kassalarda `w32tm /query /status` yoki soat/timezone tekshiruvi —
  G1 ni tasdiqlash uchun (log'da `SYNC_CLOCK_SKEW` chiqadi)

## Test / Verifikatsiya
- `flutter analyze lib test` — 0 xato (faqat avvaldan mavjud warning'lar)
- `flutter test` — **1247/1247 o'tdi** (2026-09-24; shundan 51 tasi yangi:
  server_clock 7, stream_sync_runner +12, notification_fetch 17,
  items_singleton_notification 15)
- Jonli API tekshiruvi qilinmadi (token olish rad etildi) — server tartibi va
  `is_read` semantikasi Alice orqali kassada ko'riladi.

### Do'kon sinovi rejasi (Windows, 2 kassa)
Kuzatish: Alice (Sozlamalar → PIN = hozirgi soat `HHmm`) va
`Documents\request_logs_of_invan_pos.txt` ichida `SYNC_` qatorlari.

| # | Case | Qadamlar | Kutilgan |
|---|---|---|---|
| A1 | Yangilanishdan keyin birinchi ochilish | Yangi versiyani o'rnatib och | Log'da `SYNC_FULL_RELOAD why=kursor eskirgan yoki soat sakragan` (bir marta), keyin oddiy oynalar |
| A2 | **Asosiy** — rasmsiz yangi mahsulot | Adminkada rasmsiz, kategoriyasiz mahsulot yarat, narx qo'y | 1-2 daqiqada kassada skanerda topiladi; log'da `SYNC_APPLIED stream=Product applied=1` (yoki `SYNC_APPLY_FAILED` + `SYNC_FULL_RELOAD` — ikkalasida ham mahsulot keladi) |
| A3 | Kassa soati oldinda | Kassa soatini 10 daqiqa OLDINGA sur → adminkada narx o'zgartir | 1-2 daqiqada narx keladi; log'da `SYNC_CLOCK_SKEW kassa_minus_server_s=600` |
| A4 | Kassa soati orqada | Soatni 10 daqiqa ORQAGA sur → narx o'zgartir | 1-2 daqiqada keladi (ilgari 10 daqiqa kechikardi) |
| A5 | Timezone noto'g'ri | Windows timezone'ni UTC+3 ga o'zgartirib soatni qo'lda to'g'rila → narx o'zgartir | Baribir 1-2 daqiqada keladi; `SYNC_CLOCK_SKEW ≈ 7200` |
| A6 | Faqat nom o'zgarishi | Adminkada mahsulot nomini o'zgartir (narxga tegma) | Kassada yangi nom, narx JOYIDA (0 bo'lib qolmaydi) |
| A7 | Boshqa do'kon mahsulotiga narx | Mahsulotni B do'kon uchun yaratib keyin A do'konga narx qo'y | A kassada skanerda topiladi |
| B1 | Qo'lda "Yangilash" sinxron ketayotganda | Avto-sinxron paytida galochkali yangilashni bos | Kutadi (≤3 daqiqa) va bajaradi; log'da `SYNC_LOCK_FORCED` YO'Q |
| B2 | Internet uzilishi | Kabelni 5 daqiqa uz, ula | Kursor joyida, ulangach yetib oladi; `SYNC_FETCH_ERROR` keyin `SYNC_APPLIED` |
| B3 | Katta ommaviy narx o'zgarishi | Adminkada 1500 mahsulot narxini bir vaqtda o'zgartir | `SYNC_FULL_RELOAD why=oyna limitga urildi`, keyin barcha narx to'g'ri; UI qotmaydi |
| C1 | Regressiya — kategoriya/diskont | Kategoriya/diskont yarat | 10 daqiqa ichida keladi (kategoriya — yangi mahsulot uni ko'rsatsa 1 daqiqada) |
| C2 | Regressiya — o'chirish (type 3) | Mahsulotni o'chir | 1 daqiqada yo'qoladi |
| C3 | Regressiya — to'lov turi (type 40) | CLICK ni yoq/o'chir | 1 daqiqada to'lov ekranida o'zgaradi |
