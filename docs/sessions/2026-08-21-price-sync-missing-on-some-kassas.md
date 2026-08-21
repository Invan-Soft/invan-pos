# Task: Narx o'zgarishi 5 kassadan 2 tasiga yetib bormasligi

**Boshlangan:** 2026-08-21
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Do'konda mahsulot yaratilgan va narxlar o'zgartirilgan; o'zgarish 3 kassaga
yetib borgan, 2 tasiga yo'q. Versiyalar bir xil, kompyuterlar yoqiq,
internet ishlagan, API'da ma'lumot bor. Ildiz sababni topish.

## Avvalgi implementatsiya
docs/sessions/2026-08-12-multi-kassa-price-sync-gap.md
↑ U yerda SyncCursor + CatchUpSync qurilgan edi (kursor faqat muvaffaqiyatdan
keyin suriladi). Bu hujjat o'sha mexanizm chiqqandan KEYIN paydo bo'lgan
hodisani tekshiradi.

## Bajarilgan
- [x] Davriy sinxrondagi `connectivity_plus` gate'i olib tashlandi
  → lib/changes/providers/update_provider.dart:38
  → Sabab: Windows'da `checkConnectivity()` adapterni emas, Windows'ning NCSI
    hukmini (`IsConnectedToInternet`) qaytaradi
    (connectivity_plus-4.0.2/windows/network_manager.cpp:123). Do'kon
    tarmog'ida Microsoft probe'lari bloklansa Windows "internet yo'q" deydi,
    API esa ishlayveradi → davriy sinxron o'sha mashinada jimgina o'chib
    qolardi. Tekshiruv himoya bermasdi: offline holatda so'rov timeout bo'lib
    `failed` qaytaradi va kursor joyida qoladi.
  → Testlar: 38/38 (sync_window, sync_cursor, stream_sync_runner), analyze toza

- [x] "Katalog yangilanmagan" ogohlantirishi qo'shildi
  → lib/changes/services/catalog_refresh_notice.dart (yangi)
  → lib/utils/util_functions.dart:247,254 — fullUpdateProduct muvaffaqiyat/
    yiqilishda bayroqni qo'yadi/oladi (yagona choke point, barcha
    chaqiruvchilar qamraladi: wrapper startup, UPD dialogi, POS aktivatsiyasi)
  → lib/changes/services/web_socket_service/product/products_ws_service.dart —
    `import()` muvaffaqiyatida ham bayroq olinadi
  → lib/changes/services/sync/catch_up_sync.dart — `finally` ichida
    `unawaited(maybeShow())`. `await` QILINMAYDI: dialog modal, kutilsa
    `_running` qulfi dialog yopilguncha band bo'lib qolardi.
  → lib/idle_service.dart — `isOnLockPage` / `isOnCriticalAuthPage` getterlari
    (dialog PIN va auth sahifalari ustiga chiqmasligi uchun)
  → lib/utils/constants/pref_keys.dart — `catalogRefreshPending`,
    `lastFullCatalogSyncAt`
  → l10n: `katalog_yangilanmagan_sarlavha`, `katalog_yangilanmagan_matn`,
    `keyinroq` (uz + ru, gen-l10n bajarildi)
  → Sabab: internet yo'q holatda startup yuklashi jimgina yiqilardi va kassir
    eski narx bilan sotishda davom etardi. Mantiq o'zgarmadi — ilova baribir
    eski baza bilan ochilaveradi — endi bu holat ko'rinadigan bo'ldi.
  → Xulq: "Keyinroq" bosilsa 30 daqiqa qayta chiqmaydi (xotirada, ilova
    qayta ochilsa noldan). Muvaffaqiyatli yangilashdan keyin butunlay o'chadi.

## Ma'lumot bilan RAD ETILGAN gipotezalar (qayta tekshirmaslik uchun)
- **`editItem` sharti (shopPrices/tiers null)** — jonli test: adminkada narxsiz
  mahsulot yaratilib keyin narx qo'yildi; `type 1` payloadida `shop_prices`
  kassaning shop_id si bilan va `shop_price_tiers:[{min_quantity:1}]` bilan
  keldi → shartlar bajarildi, narx qo'llandi (CART_ADD price=12300).
- **`offset=1` notification yo'qotadi** — jonli test: `total_count:1`, 1 ta
  so'raldi, 1 tasi qaytdi.
- **`is_read` ni kimdir iste'mol qilyapti** — jonli test: bir xil notification
  ketma-ket ikki pollingda ham qaytdi (2 daqiqalik overlap).
- **`autoSyncInterval` birlik chalkashligi (ms vs daqiqa)** — auto_sync_dialog
  ms yozadi, update_provider daqiqa deb o'qiydi, LEKIN dialog UI'ga ulanmagan
  va main.dart:88-93 har startupda qiymatni 1 ga majburan qaytaradi.
- **Sana formati (dd-mm-yy vs mm-dd-yy)** — barcha sinxron vaqtlari aniq
  `DateFormat('yyyy-MM-dd HH:mm:ss')` pattern bilan, locale'ga bog'liq
  skeleton yoki parse yo'q. Foydalanuvchi kassalarda tekshirdi: bir xil.
- **Kursorning oldinga sakrashi** — barcha to'liq yuklash yo'llari kursorni
  yuklash BOSHLANGAN vaqtga suradi (catch_up_sync, upd_bloc, sync_bloc).
- **Mahalliy katalog buzuqligi** — mac'dagi real bazadan o'qildi: 57 493
  mahsulotdan 57 483 tasida shopId to'g'ri, tiers to'liq.

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] **Do'kondan asosiy savol:** o'sha 2 kassada narx keyin O'Z-O'ZIDAN
      to'g'rilandimi yoki faqat restart / "Yangilash" dan keyinmi?
      → o'zi to'g'rilangan bo'lsa: vaqtinchalik blok (ma'lumot yo'qolmaydi)
      → faqat qo'lda: sinxron butunlay o'lgan (deadlock yoki doimiy NCSI blok)
- [ ] Har 5 kassada: `Get-NetConnectionProfile` → `IPv4Connectivity`
- [ ] Har 5 kassada log: `products_json_gzip | notifications | order_pos`
      izini solishtirish (Documents\request_logs_of_invan_pos.txt, 24 soat)
- [ ] `downloadFile` deadlock'ini tuzatish (quyida)

## Tekshirilmagan, kuchli qolgan nomzod: `_running` deadlock
`CatchUpSync._running` static; `import()` → `getItems()` → `downloadFile()`
(get_items_service.dart:85) xom `HttpClient` bilan, **timeout yo'q**. 43 MB
yuklash o'rtada qotsa `await response.forEach` abadiy osiladi → `finally`
ishlamaydi → `_running` abadiy true → har daqiqalik sinxron darhol
`return false` qiladi, izsiz. Kassa restartgacha muzlaydi.
To'liq yuklash kun o'rtasida `type 0` da yoki oyna 1000 ga urilganda ishga
tushadi — ya'ni ommaviy mahsulot yaratish/narx o'zgartirishda.
Log imzosi: oxirgi `products_json_gzip` POST'idan keyin bironta ham
`notifications` GET yo'q, lekin `order_pos` POST'lari davom etadi.

## Yo'l-yo'lakay topilgan, alohida tuzatishga arziydigan nuqsonlar
- `products_ws_service.dart` type 1/2: `(ws['data']['category_ids'] as List)`
  — null kelsa TypeError → butun oyna yiqiladi, kursor qotadi.
- Mahalliy bazada 10 ta mahsulotda `shopPrices.shID == null` → ularga hech
  qachon narx qo'llanmaydi.
- `auto_sync_dialog.dart:100` ms/daqiqa chalkashligi (hozir otilmaydi).
- Sinxron nosozliklari faqat `kDebugMode` da print bo'ladi — do'konda umuman
  ko'rinmaydi. Doimiy logga yozish kerak.

## Test / Verifikatsiya
- `flutter test` (sync_window, sync_cursor, stream_sync_runner,
  items_bulk_write) → 43/43
- `flutter analyze lib` → 0 xato
- Ogohlantirishni DEBUG'da sinash retsepti (startup yuklashi debug'da
  `if (!kDebugMode)` sabab ishlamaydi):
  1. Internetni o'chiring
  2. UPD dialogini oching (u `UtilFunctions.fullUpdateProduct()` ni chaqiradi)
     → mahsulot qadami yiqiladi → bayroq qo'yiladi
  3. Internetni yoqing
  4. 1 daqiqa ichida CatchUpSync tugagach ogohlantirish dialogi chiqadi
- Do'kon sinovi: kutilmoqda
