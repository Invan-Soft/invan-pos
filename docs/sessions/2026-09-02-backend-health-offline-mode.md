 # Task: Server o'chganda kassa ishlashda davom etsin (BackendHealth)

**Boshlangan:** 2026-09-02
**Holat:** in-progress (kod `ayyubxon` da — `3527ef0`, Windows testi kutilmoqda)
**Branch:** ayyubxon (2026-09-07 da `refactor/ordering-split-2` dan merge qilindi)

## Maqsad
Backend server yiqilganda (5xx yoki umuman javob bermaganda) kassa xuddi
internet uzilgandagi kabi to'liq ishlashda davom etsin: sotuv, qaytarish,
smena, fiskal chek — hammasi lokal ketsin, serverga yuborish navbatga tushsin.
Faqat serverdan ma'lumot **olish** (katalog/xodim yangilash) to'xtaydi.

## Ildiz sabab (tahlil natijasi)

Loyihada "oflayn" tushunchasi `InternetConnectionChecker().hasConnection`
ga bog'langan — bu 1.1.1.1 / 8.8.8.8 ga ping, ya'ni *internet bormi?*.
Kerakli savol esa *bizning server javob beryaptimi?*.

Server o'chganda internet BOR → ilova "onlayn" deb hisoblaydi → hamma joyda
onlayn shox tanlanadi → har so'rov 500/timeout bilan yiqiladi.
**Natija: server o'lishi internet o'lishidan yomonroq kechadi.**

`hasConnection` ishlatiladigan joylar (hammasi almashtirilishi kerak):
- lib/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart:128
- lib/changes/providers/ordering_provider_4.dart:996
- lib/features/checks/features/checks_app_bar/bloc/usr_bloc.dart:51, :167
- lib/features/checks/features/check_view/bloc/pre_ofd/preofd_bloc.dart:73
- lib/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart:122
- lib/changes/bloc/client_search/client_search_bloc.dart:39
- lib/changes/services/catalog_refresh_notice.dart:152
- lib/changes/services/shift/shift_diagnostics.dart:152
- lib/app/wrapper/wrapper.dart:74 (bu qoladi — internet listeneri)

### Aniqlangan konkret nuqsonlar

1. **Smena ocholmaydi (eng ehtimolli to'xtash sababi).**
   shift_singleton_4.dart:128-138 — internet bor → `shift_statuses` 5xx →
   `isReturn = false` → smena ochilmaydi → kassa umuman sotolmaydi.
   Internet yo'q bo'lganda `else` shoxi lokal ochib navbatga qo'yadi.

2. **GET so'rovlarida timeout YO'Q.**
   api_provider.dart:139 — post/put da 30s bor, `getResponse` da yo'q.
   Server TCP qabul qilib javob bermasa Future hech qachon tugamaydi.

3. **Startup muzlaydi.**
   wrapper.dart:130-148 — xodimlar va katalog yangilanishi `await` qilinadi
   va xato bo'lsa YANA BIR MARTA takrorlanadi. Timeout'siz GET bilan
   birga: splash ekranda cheksiz qotish, lokal katalog joyida bo'lsa ham.

4. **Qisman ishlagan serverda xodim ruxsatlari yo'qoladi.**
   util_functions.dart:36 — `box.clear()` birinchi so'rovdan keyin, rollar
   (`getRoleWithPermissions`) esa keyin so'raladi. Rollar 5xx bersa xodimlar
   `access = null` bilan saqlanadi → pin_bloc.dart:138 `element.access!`
   null crash / ruxsatlar yo'qoladi. Yozuv atomik emas.

5. **Xato bo'roni o'zini kuchaytiradi.**
   Har 5xx → `LogRepository.requestSend` → Telegramga alohida POST
   (log_repository.dart:238). Ustiga WS har 5s reconnect, `autoUpdate` har
   1 daqiqa, diskont sinxroni har 10 daqiqa.

6. **Qaytarish oflayn umuman ishlamaydi.**
   return_bloc.dart:122 — internet yo'q bo'lsa darhol `ReturnNoInternetState`.
   Server 200 qaytarmaguncha fiskal qaytarish ham bajarilmaydi
   (return_bloc.dart:134 `refundResponse.statusCode == 200` sharti).

### Allaqachon mavjud poydevor (qayta yozilmaydi)
- Cheklar navbati: ObjectBox `ReceiptModel4.uploaded/rejected` + `UsrBloc`
- Smena navbati: `ShiftSyncQueue` (lib/changes/services/shift/shift_sync_queue.dart)
- Katalog catch-up: `CatchUpSync` + `SyncCursor`
- Fiskal modul lokal (localhost:8080), katalog Hive'da
- Barcha 45 ta so'rov bitta `ApiProvider` dan o'tadi ← health gate uchun ideal nuqta

## Scope

Kiradi:
- Yangi: `BackendHealth` (circuit breaker) + `ApiProvider` integratsiyasi
- Yuqoridagi 8 joyda `hasConnection` → `BackendHealth.isUsable`
- Startup bloklanmasligi (wrapper.dart)
- Xodimlar yangilanishi atomik (util_functions.dart) + `access!` null-safe
- Qaytarishning oflayn shoxi (return_bloc.dart) — YANGI funksionallik
- ONKM validatoriga timeout (onkm_validator.dart)
- Log/Telegram bo'ronini bosish
- Kassirga ko'rinadigan holat indikatori

Kirmaydi:
- Mijozlarni lokal keshlash (oflayn telefon raqami bo'yicha qidiruv) —
  hozir bunday kesh umuman yo'q (`ClientsSingleton` main.dart:109 da
  kommentda). Alohida task.
- Arcus terminal (Uzcard/Humo) yo'llari — qurilma yo'q, tegilmaydi.
- Click/Payme/Uzum/Paynet — ular bizning server emas, o'z holicha qoladi.

## Qabul qilingan qarorlar (2026-09-02, foydalanuvchi bilan kelishildi)

1. **Server o'chganda smena LOKAL ochiladi** — internet uzilgandagi kabi,
   `ShiftSyncQueue` navbatiga tushadi. Duplikat smena xavfi qabul qilindi
   (`ShiftDiagnostics` bu holatni allaqachon qayd qiladi).
2. **Barcha sotuv amallari oflayn ishlaydi** — naqd/karta sotuv, qaytarish,
   qarzga sotuv, cashback. Faqat serverdan ma'lumot **olish** to'xtaydi
   (katalog, xodimlar, mijoz qidiruvi) — sabab: ular baribir server'siz
   hech narsa ololmaydi.
3. **Bir yo'la to'liq BackendHealth** — bosqichlarga bo'linmaydi.
4. **Mijozlar keshi QILINMAYDI** (2026-09-02) — mijoz oflayn holatda xuddi
   internetsizdagi kabi ishlaydi: QR/karta (36-belgili ID) orqali topiladi,
   telefon raqami bo'yicha qidiruv ishlamaydi. Amalda do'konlarda mijoz
   telefon raqami bilan deyarli qidirilmaydi — QR kod ishlatiladi.
   Oqibati (qabul qilingan): oflayn mijozda ism/foizli chegirma/cashback
   balansi bo'lmaydi — client_search_bloc.dart:39 dagi mavjud shox qanday
   bo'lsa shunday qoladi.
5. **ONKM validatoriga ham timeout qo'yiladi** (2026-09-02) — u bizning
   server emas (soliq), lekin timeout'siz bo'lgani uchun osilib qolsa kassir
   markirovka skanerlashda muzlaydi. Scope'ga kiritildi.

## Dizayn

### BackendHealth (yangi: lib/changes/services/health/backend_health.dart)

Holat: `up` | `down`. `ValueNotifier` orqali UI kuzatadi.

Nima "server yiqildi" deb hisoblanadi:
- `TimeoutException`, `SocketException`, `ClientException`, `HandshakeException`
- statusCode >= 500 (500/502/503/504)
- `ApiProvider` ning ichki xato kodlari (-1, -2)

Nima hisoblanMAYdi (server tirik degani, holatni buzmaydi):
- 400, 401, 403, 404, 409, 422 — biznes/auth xatolari

Qoidalar:
- Ketma-ket 3 ta xato → `down`
- `down` holatida so'rovlar tarmoqqa CHIQMAYDI, darhol
  `HttpResult(isSuccess: false, statusCode: -3)` qaytadi (kassir kutmaydi)
- Har 30 soniyada bitta so'rov o'tkaziladi (half-open probe); muvaffaqiyat →
  `up` + navbatlarni flush qilish triggeri
- Foydalanuvchi qo'lda boshlagan amal (login, refresh tugmasi) `force: true`
  bilan darhol probe qila oladi
- Bitta muvaffaqiyat → `up` (hisoblagich nolga tushadi)

`BackendHealth.isUsable` = internet bor VA holat `up`.
Mavjud `hasConnection` chaqiruvlari shunga almashtiriladi → mavjud oflayn
shoxlar avtomatik ishga tushadi, yangi oflayn mantiq yozilmaydi.

### Qaytarishning oflayn shoxi (yangi funksionallik)

Hozir: server 200 → fiskal qaytarish → ObjectBox.
Bo'ladi: ObjectBox (`uploaded = false`) → fiskal qaytarish lokal →
serverga yuborish `UsrBloc` navbatiga qoladi.
Tekshirish kerak: `UsrBloc._find10` filtri refund cheklarni ham oladimi
(`isRefund = true`), va ular `receiptCreateGroup` bilan to'g'ri ketadimi
yoki `receiptCreateGrouppForRefund` kerakmi.

## Bajarilgan

- [x] `BackendHealth` — circuit breaker (holat: up/down, 3 xato → down,
      har 30s half-open probe, tiklanganda `onRecovered`)
    → lib/changes/services/health/backend_health.dart
    → test/backend_health_test.dart — 20 ta test
    → Sabab: barcha so'rovlar bitta `ApiProvider` dan o'tadi, shuning uchun
      "server tirikmi" degan bilim ham bitta joyda turishi kerak.

- [x] `ApiProvider` ga darvoza + natijalarni qayd etish + **GET timeout (15s)**
    → lib/changes/services/api/api_provider.dart (post/get/put)
    → `down` holatida so'rov tarmoqqa CHIQMAYDI, darhol statusCode -3 qaytadi
    → Sabab: GET'da timeout umuman yo'q edi — server javob bermay qo'ysa
      Future hech qachon tugamasdi.

- [x] `hasConnection` → `BackendHealth.isUsable()` (BIZNING serverga tegishli
      joylarda): shift_singleton_4, usr_bloc (2 joy), catalog_refresh_notice,
      shift_diagnostics, client_search_bloc
    → ONKM (tasnif.soliq.uz) va PreOFD ATAYLAB tegilmadi — ular boshqa
      serverlar, bizning backend yiqilishi ularga aloqador emas.

- [x] Smena OCHISH server yiqilganda lokal ochiladi + navbatga tushadi
    → shift_singleton_4.dart (openOffline + `isServerFailureStatus` tekshiruvi)
    → Muhim nuance: `BackendHealth` hali `down` ga o'tmagan bo'lishi mumkin
      (3 xato kerak), shuning uchun status kodining O'ZI ham tekshiriladi —
      aks holda outage boshidagi birinchi urinish baribir yiqilardi.

- [x] Smena YOPISH server yiqilganda navbatga tushadi (yangi shox)
    → shift_singleton_4.dart closeShift
    → Ilgari: server 500 bersa Hive'da "yopilgan" bo'lib qolar, `closedCount`
      esa 0 bo'lgani uchun `ShiftSyncQueue` navbati HOSIL BO'LMASDI —
      yopilish serverga hech qachon yetmasdi.

- [x] Startup bloklanmasligi
    → lib/app/wrapper/wrapper.dart `_syncCatalogOnStartup` (25s budjet,
      takroriy urinish olib tashlandi, server yiqilgan bo'lsa umuman urinmaydi)

- [x] Xodimlar yangilanishi ATOMIK + `access!` null-safe
    → lib/utils/util_functions.dart fullUpdateEmployee (ikkala so'rov
      muvaffaqiyatli bo'lgandan keyingina `box.clear()`)
    → lib/features/lock/access_level/bloc/pin/pin_bloc.dart:138

- [x] OFLAYN QAYTARISH (yangi funksionallik)
    → lib/changes/services/receipt/refund_upload_queue.dart — yangi navbat
    → return_bloc.dart — `finishRefund(uploaded:)` bilan qayta qurildi
    → Kashfiyot: qaytarish uchun navbat UMUMAN yo'q edi.
      `receiptCreateGroup` refund cheklarini `jsonListFromRefund` ga yig'adi-yu
      hech qayerga yubormaydi, `UsrBloc` esa 201 dan keyin faqat
      `isRefund == false` cheklarni `uploaded` qiladi.
    → Qoida: internet YO'Q → qaytarish baribir mumkin emas (fiskal chek OFD
      ga yozilishi kerak). Internet BOR, server yiqilgan → lokal + fiskal
      bajariladi, serverga yuborish navbatga tushadi.

- [x] ONKM validatoriga timeout (10s) + osilib qolgan `isLoading` tuzatildi
    → lib/changes/services/onkm_validator.dart
    → lib/changes/providers/ordering_provider_4.dart (catch ichida
      `isLoading = false`) — ilgari xato bo'lsa kassa markirovka
      skanerlashda muzlab qolardi.

- [x] Telegram bo'roni bosildi — server yiqilgan davrda 5 daqiqada 1 xabar
    → lib/changes/repository/log_repository.dart

- [x] Foydalanuvchi qo'lda bosgan amallar darvozadan o'tadi
    → auth_api.dart (login/verify/get_shops → `force: true`)
    → sync_button_home.dart (`markUserInitiatedAction()`)

- [x] Kassirga ko'rinadigan "Oflayn rejim" belgisi + navbat soni
    → lib/features/home/components/offline_mode_badge.dart
    → lib/features/home/home_page.dart (appBar actions)

- [x] Navbat triggerlari: startup, tarmoq tiklanganda, SERVER tiklanganda
    → wrapper.dart (`BackendHealth.onRecovered`), app.dart


### Test bosqichida topilgan va tuzatilgan qo'shimcha nuqsonlar (2026-09-02)

- [x] **Outage kunida ochilgan smenani kechqurun YOPIB BO'LMASDI.**
    `blockingCloseIssue` navbatda ochish turgan bo'lsa yopishni bloklardi
    (sabab: navbat ochish+yopishni birga ko'tara olmasdi).
    → `ShiftSyncQueue.flush` endi vaqt tartibida yuboradi (`_openBeforeClose`):
      ertalab ochilgan bo'lsa avval OCHISH, keyin YOPISH. Birinchisi yiqilsa
      ikkinchisi urinilmaydi — ochilmagan smenani yopish ma'nosiz.
    → `closeOffline` sharti `closedCount == 0` ga yumshatildi.
    → `canCloseOffline` → `closedCount == 0`.
    → test/shift_close_guard_test.dart yangi qoidaga ko'chirildi.

- [x] **Qaytarishlar sotuv navbatiga tushib, HAQIQIY SOTUVLARNI ham
      "rad etilgan" qilib qo'yishi mumkin edi.**
    Oflayn qaytarish `uploaded=false` bo'lgani uchun endi `UsrBloc._find10`
    ularni ham olardi. `receiptCreateGroup` refundlarni yubormaydi → guruh
    bo'sh/qisman ketardi → server 4xx qaytarsa GURUHDAGI HAMMA chek
    `rejected=true` bo'lib, avtomatik navbatdan chiqib ketardi.
    → `_find10` va `_findIsRejected10` ga `isRefund.equals(false)` qo'shildi.
    → Rad etilgan qaytarishlarni qo'lda qayta yuborish: cheklar sahifasidagi
      refresh tugmasi `RefundUploadQueue.flush(includeRejected: true)`.

## Keyingi qadamlar (prioritet bo'yicha)
- [x] Commit + `ayyubxon` ga merge + push (2026-09-07, `3527ef0`)
      → gitlab/ayyubxon va origin/main sinxron, 1076/1076 test yashil
- [ ] Windows'da test (quyidagi stsenariylar bo'yicha)
- [ ] Test tasdiqlansa → relizga kiritish + Holat: done

## Qabul qilingan qarorlar (2026-09-02, foydalanuvchi bilan kelishildi)

1. **Server o'chganda smena LOKAL ochiladi** — internet uzilgandagi kabi,
   `ShiftSyncQueue` navbatiga tushadi. Duplikat smena xavfi qabul qilindi
   (`ShiftDiagnostics` bu holatni allaqachon qayd qiladi).
2. **Barcha sotuv amallari oflayn ishlaydi** — naqd/karta sotuv, qaytarish,
   qarzga sotuv, cashback. Faqat serverdan ma'lumot **olish** to'xtaydi
   (katalog, xodimlar, mijoz qidiruvi) — sabab: ular baribir server'siz
   hech narsa ololmaydi.
3. **Bir yo'la to'liq BackendHealth** — bosqichlarga bo'linmaydi.
4. **Mijozlar keshi QILINMAYDI** (2026-09-02) — mijoz oflayn holatda xuddi
   internetsizdagi kabi ishlaydi: QR/karta (36-belgili ID) orqali topiladi,
   telefon raqami bo'yicha qidiruv ishlamaydi. Amalda do'konlarda mijoz
   telefon raqami bilan deyarli qidirilmaydi — QR kod ishlatiladi.
   Oqibati (qabul qilingan): oflayn mijozda ism/foizli chegirma/cashback
   balansi bo'lmaydi — client_search_bloc.dart:39 dagi mavjud shox qanday
   bo'lsa shunday qoladi.
5. **ONKM validatoriga ham timeout qo'yiladi** (2026-09-02) — u bizning
   server emas (soliq), lekin timeout'siz bo'lgani uchun osilib qolsa kassir
   markirovka skanerlashda muzlaydi. Scope'ga kiritildi.

## Dizayn

### BackendHealth (yangi: lib/changes/services/health/backend_health.dart)

Holat: `up` | `down`. `ValueNotifier` orqali UI kuzatadi.

Nima "server yiqildi" deb hisoblanadi:
- `TimeoutException`, `SocketException`, `ClientException`, `HandshakeException`
- statusCode >= 500 (500/502/503/504)
- `ApiProvider` ning ichki xato kodlari (-1, -2)

Nima hisoblanMAYdi (server tirik degani, holatni buzmaydi):
- 400, 401, 403, 404, 409, 422 — biznes/auth xatolari

Qoidalar:
- Ketma-ket 3 ta xato → `down`
- `down` holatida so'rovlar tarmoqqa CHIQMAYDI, darhol
  `HttpResult(isSuccess: false, statusCode: -3)` qaytadi (kassir kutmaydi)
- Har 30 soniyada bitta so'rov o'tkaziladi (half-open probe); muvaffaqiyat →
  `up` + navbatlarni flush qilish triggeri
- Foydalanuvchi qo'lda boshlagan amal (login, refresh tugmasi) `force: true`
  bilan darhol probe qila oladi
- Bitta muvaffaqiyat → `up` (hisoblagich nolga tushadi)

`BackendHealth.isUsable` = internet bor VA holat `up`.
Mavjud `hasConnection` chaqiruvlari shunga almashtiriladi → mavjud oflayn
shoxlar avtomatik ishga tushadi, yangi oflayn mantiq yozilmaydi.

### Qaytarishning oflayn shoxi (yangi funksionallik)

Hozir: server 200 → fiskal qaytarish → ObjectBox.
Bo'ladi: ObjectBox (`uploaded = false`) → fiskal qaytarish lokal →
serverga yuborish `UsrBloc` navbatiga qoladi.
Tekshirish kerak: `UsrBloc._find10` filtri refund cheklarni ham oladimi
(`isRefund = true`), va ular `receiptCreateGroup` bilan to'g'ri ketadimi
yoki `receiptCreateGrouppForRefund` kerakmi.

## Bajarilgan

- [x] `BackendHealth` — circuit breaker (holat: up/down, 3 xato → down,
      har 30s half-open probe, tiklanganda `onRecovered`)
    → lib/changes/services/health/backend_health.dart
    → test/backend_health_test.dart — 20 ta test
    → Sabab: barcha so'rovlar bitta `ApiProvider` dan o'tadi, shuning uchun
      "server tirikmi" degan bilim ham bitta joyda turishi kerak.

- [x] `ApiProvider` ga darvoza + natijalarni qayd etish + **GET timeout (15s)**
    → lib/changes/services/api/api_provider.dart (post/get/put)
    → `down` holatida so'rov tarmoqqa CHIQMAYDI, darhol statusCode -3 qaytadi
    → Sabab: GET'da timeout umuman yo'q edi — server javob bermay qo'ysa
      Future hech qachon tugamasdi.

- [x] `hasConnection` → `BackendHealth.isUsable()` (BIZNING serverga tegishli
      joylarda): shift_singleton_4, usr_bloc (2 joy), catalog_refresh_notice,
      shift_diagnostics, client_search_bloc
    → ONKM (tasnif.soliq.uz) va PreOFD ATAYLAB tegilmadi — ular boshqa
      serverlar, bizning backend yiqilishi ularga aloqador emas.

- [x] Smena OCHISH server yiqilganda lokal ochiladi + navbatga tushadi
    → shift_singleton_4.dart (openOffline + `isServerFailureStatus` tekshiruvi)
    → Muhim nuance: `BackendHealth` hali `down` ga o'tmagan bo'lishi mumkin
      (3 xato kerak), shuning uchun status kodining O'ZI ham tekshiriladi —
      aks holda outage boshidagi birinchi urinish baribir yiqilardi.

- [x] Smena YOPISH server yiqilganda navbatga tushadi (yangi shox)
    → shift_singleton_4.dart closeShift
    → Ilgari: server 500 bersa Hive'da "yopilgan" bo'lib qolar, `closedCount`
      esa 0 bo'lgani uchun `ShiftSyncQueue` navbati HOSIL BO'LMASDI —
      yopilish serverga hech qachon yetmasdi.

- [x] Startup bloklanmasligi
    → lib/app/wrapper/wrapper.dart `_syncCatalogOnStartup` (25s budjet,
      takroriy urinish olib tashlandi, server yiqilgan bo'lsa umuman urinmaydi)

- [x] Xodimlar yangilanishi ATOMIK + `access!` null-safe
    → lib/utils/util_functions.dart fullUpdateEmployee (ikkala so'rov
      muvaffaqiyatli bo'lgandan keyingina `box.clear()`)
    → lib/features/lock/access_level/bloc/pin/pin_bloc.dart:138

- [x] OFLAYN QAYTARISH (yangi funksionallik)
    → lib/changes/services/receipt/refund_upload_queue.dart — yangi navbat
    → return_bloc.dart — `finishRefund(uploaded:)` bilan qayta qurildi
    → Kashfiyot: qaytarish uchun navbat UMUMAN yo'q edi.
      `receiptCreateGroup` refund cheklarini `jsonListFromRefund` ga yig'adi-yu
      hech qayerga yubormaydi, `UsrBloc` esa 201 dan keyin faqat
      `isRefund == false` cheklarni `uploaded` qiladi.
    → Qoida: internet YO'Q → qaytarish baribir mumkin emas (fiskal chek OFD
      ga yozilishi kerak). Internet BOR, server yiqilgan → lokal + fiskal
      bajariladi, serverga yuborish navbatga tushadi.

- [x] ONKM validatoriga timeout (10s) + osilib qolgan `isLoading` tuzatildi
    → lib/changes/services/onkm_validator.dart
    → lib/changes/providers/ordering_provider_4.dart (catch ichida
      `isLoading = false`) — ilgari xato bo'lsa kassa markirovka
      skanerlashda muzlab qolardi.

- [x] Telegram bo'roni bosildi — server yiqilgan davrda 5 daqiqada 1 xabar
    → lib/changes/repository/log_repository.dart

- [x] Foydalanuvchi qo'lda bosgan amallar darvozadan o'tadi
    → auth_api.dart (login/verify/get_shops → `force: true`)
    → sync_button_home.dart (`markUserInitiatedAction()`)

- [x] Kassirga ko'rinadigan "Oflayn rejim" belgisi + navbat soni
    → lib/features/home/components/offline_mode_badge.dart
    → lib/features/home/home_page.dart (appBar actions)

- [x] Navbat triggerlari: startup, tarmoq tiklanganda, SERVER tiklanganda
    → wrapper.dart (`BackendHealth.onRecovered`), app.dart


### Test bosqichida topilgan va tuzatilgan qo'shimcha nuqsonlar (2026-09-02)

- [x] **Outage kunida ochilgan smenani kechqurun YOPIB BO'LMASDI.**
    `blockingCloseIssue` navbatda ochish turgan bo'lsa yopishni bloklardi
    (sabab: navbat ochish+yopishni birga ko'tara olmasdi).
    → `ShiftSyncQueue.flush` endi vaqt tartibida yuboradi (`_openBeforeClose`):
      ertalab ochilgan bo'lsa avval OCHISH, keyin YOPISH. Birinchisi yiqilsa
      ikkinchisi urinilmaydi — ochilmagan smenani yopish ma'nosiz.
    → `closeOffline` sharti `closedCount == 0` ga yumshatildi.
    → `canCloseOffline` → `closedCount == 0`.
    → test/shift_close_guard_test.dart yangi qoidaga ko'chirildi.

- [x] **Qaytarishlar sotuv navbatiga tushib, HAQIQIY SOTUVLARNI ham
      "rad etilgan" qilib qo'yishi mumkin edi.**
    Oflayn qaytarish `uploaded=false` bo'lgani uchun endi `UsrBloc._find10`
    ularni ham olardi. `receiptCreateGroup` refundlarni yubormaydi → guruh
    bo'sh/qisman ketardi → server 4xx qaytarsa GURUHDAGI HAMMA chek
    `rejected=true` bo'lib, avtomatik navbatdan chiqib ketardi.
    → `_find10` va `_findIsRejected10` ga `isRefund.equals(false)` qo'shildi.
    → Rad etilgan qaytarishlarni qo'lda qayta yuborish: cheklar sahifasidagi
      refresh tugmasi `RefundUploadQueue.flush(includeRejected: true)`.

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] `BackendHealth` klassi + testlari
- [ ] `ApiProvider` ga gate + `getResponse` ga timeout (api_provider.dart:139)
- [ ] 8 ta `hasConnection` chaqiruvini almashtirish
- [ ] Startup: wrapper.dart:130-148 bloklanmasligi, ikki martalik retry olib tashlash
- [ ] `fullUpdateEmployee` atomik yozuv (util_functions.dart:28) + `access!` null-safe
- [ ] Qaytarishning oflayn shoxi (return_bloc.dart:122) + navbat tekshiruvi
- [ ] ONKM validatorga timeout (onkm_validator.dart:80) — 10s, timeoutda
      validatsiyasiz o'tkazish (`validation_onkm = false` shoxi kabi)
- [ ] Telegram log dedup (log_repository.dart:238)
- [ ] UI: oflayn indikator + navbatdagi cheklar soni
- [ ] Windows'da test

## Ochiq savollar
- Yo'q (2026-09-02 holatiga).



### Savoldan kelib chiqqan tuzatishlar (2026-09-02, foydalanuvchi savoli)

Savol: *"3 marta 500 — bu bitta API'gami yoki umumanmi? Bitta sotuv 500
qaytarsa, uni qayta yuborganda yana 500 kelishi mumkin, shunda chek 'rad
etilgan' bo'lib qolmaydimi?"*

Ikkala xavf ham real edi va tuzatildi:

- [x] **Hisoblagich umumiy edi** — bitta "buzuq" so'rov (masalan serverda
      ishlov berilmayotgan chek) 3 marta 500 bersa, server SOG'LOM bo'lsa ham
      butun kassa oflayn rejimga o'tardi.
    → Endi chegaraga yetilganda qaror darhol qabul qilinmaydi: avval
      TASDIQLOVCHI so'rov yuboriladi (`_confirmThenDecide`). Server javob
      bersa (5xx dan boshqa har qanday kod, 401 ham) — holat `up` bo'lib
      qoladi, hisoblagich nolga tushadi, hodisa `lastFalseAlarm` da
      muammoli endpoint bilan qayd etiladi.
    → Tasdiqlovchi so'rov ATAYLAB sayt ildiziga emas, haqiqiy API
      endpointiga boradi (`api/v1/shift_statuses`): ildizni proksi/CDN
      o'zi qaytarishi va backend o'lgan bo'lsa ham 200 berishi mumkin.

- [x] **500 da chek "rad etilgan" deb belgilanishi — endi SERVERDAN
      so'rab hal qilinadi** (`BackendHealth.isDocumentRejection`).
    Muammo ikki tomonlama edi:
      • Ilgari `statusCode >= 400` — ya'ni 5xx ham rad etish. Server o'chgan
        paytda birinchi yuklash urinishi 500 olsa, guruhdagi 10 tagacha
        SOG'LOM chek avtomatik navbatdan butunlay chiqib ketardi.
      • Lekin 5xx ni butunlay rad etish emas deb hisoblash ham xato:
        chekning O'ZIDA muammo bo'lsa (serverda ishlov berilmayapti) ham
        500 keladi — bunday chek abadiy qayta yuborilaverar va kassir uni
        "Rad etilgan cheklar" ro'yxatida HECH QACHON ko'rmasdi.
    → Yechim (foydalanuvchi A variantini tanladi):
        `< 400` (timeout/ulanmadi/darvoza) → rad etish emas, navbatda qoladi
        `4xx` → rad etilgan
        `5xx` → serverga tekshiruv so'rovi yuboriladi:
                tirik javob berdi → ayb hujjatda → rad etilgan
                javob bermadi → yiqilgan → navbatda qoladi
    → Bir xil qoida qaytarishlarga ham qo'llanadi (RefundUploadQueue).
    → Yon foyda: server o'lgani shu yerda aniqlansa oflayn rejimga DARHOL
      o'tiladi — 3 ta xato chegarasi kutilmaydi.

## Kassir amallari — server o'chganda (to'liq ro'yxat)

| Amal | Server 500 / javobsiz | Qayerda ta'minlanadi |
|------|----------------------|----------------------|
| Ilova ochilishi | ✅ ochiladi (≤25s), eski katalog bilan | wrapper.dart `_syncCatalogOnStartup` |
| PIN bilan kirish | ✅ lokal Hive | pin_bloc.dart (serverga so'rov yo'q) |
| Smena ochish | ✅ lokal + navbat | shift_singleton_4.dart `openOffline` |
| Smena yopish | ✅ lokal + navbat | shift_singleton_4.dart `closeOffline` |
| Mahsulot qidirish / savat / diskont | ✅ lokal | ItemsSingleton, Hive |
| Chek raqami | ✅ lokal hisoblagich | receipt_singleton_4.dart:211 |
| Naqd/karta sotuv | ✅ lokal + fiskal + navbat | pressPaymentButtonOnlyOFD |
| Fiskal chek, X/Z-report | ✅ localhost:8080 | fiscal_service (bizning server emas) |
| Chek chop etish | ✅ lokal printer | — |
| Qaytarish | ✅ lokal + fiskal + navbat (YANGI) | return_bloc + RefundUploadQueue |
| Qarzga sotuv | ✅ chek navbatga tushadi | order_pos navbati |
| Cashback ishlatish | ✅ chek navbatga tushadi | `pay_by_loyalty` yuklashda ketadi |
| Mijoz (QR/karta) | ✅ ID bilan ishlaydi (ism/chegirmasiz) | client_search_bloc.dart:39 |
| Cheklar tarixi, chekni ko'rish | ✅ lokal ObjectBox | — |
| Markirovka skanerlash | ✅ (ONKM boshqa server; timeout 10s) | onkm_validator.dart |
| Mijozni telefon raqami bilan qidirish | ❌ ishlamaydi | qasddan — kesh yo'q |
| Yangi mijoz qo'shish | ❌ aniq xabar beradi | addclient_bloc |
| Katalog / xodim yangilash | ❌ o'tkazib yuboriladi + ogohlantirish | CatalogRefreshNotice |
| Yangi mahsulot, tovar qabul, Perechisleniya | ❌ aniq xabar (darhol) | ApiProvider darvozasi |
| Click / Payme / Uzum / Paynet | ⚪ o'z serverlariga bog'liq | tegilmadi |

Muhim: ❌ belgilangan amallar ham **osilib qolmaydi** — darvoza tufayli darhol
"Server bilan aloqa yo'q" javobini qaytaradi (30 soniya kutish yo'q).

Ma'lumot yo'qolmasligi tekshirildi:
- Ketmagan cheklar `rejected` qilinmaydi: na darvoza javobida (-3), na
  server 5xx bersa — faqat 4xx haqiqiy rad etish (usr_bloc)
- Sinxron kursori (`SyncCursor`) muvaffaqiyatsiz javobda oldinga surilmaydi
- Smena yopilishi navbatga tushadi (ilgari yo'qolardi)

## Test / Verifikatsiya

Avtomatik:
- `flutter test` — 1061/1061 o'tdi, `flutter analyze lib` — 0 xato
- test/backend_health_test.dart — 30 ta birlik testi
- test/server_down_behaviour_test.dart — 17 ta UCHDAN-UCHGA test.
  Bu testlar mock EMAS: lokal `HttpServer` ko'tariladi va `HttpOverrides`
  orqali ilovaning barcha so'rovlari o'sha serverga yo'naltiriladi, ya'ni
  `ApiProvider` o'zgartirilmagan holda sinaladi. Qamrab olingan holatlar:
    • server 500 qaytaradi → 3 xatodan keyin oflayn rejim
    • oflayn rejimda 20 ta so'rov serverga UMUMAN bormaydi va <1s da javob
    • server javob BERMAYDI (osilgan ulanish) → GET 15s da tugaydi
      (ilgari cheksiz osilardi — startup shu sababdan muzlardi)
    • ulanish rad etilishi (port yopiq) → oflayn rejim
    • 401 lar oflayn rejimga O'TKAZMAYDI (server tirik)
    • server tiklanishi → probe → navbat callback'i
    • kassir qo'lda bosgan amal (login) darvozadan darhol o'tadi
    • server QISMAN ishlaganda (xodimlar 200, rollar 500) lokal baza
      tegilmaydi — ruxsatlar yo'qolmaydi
    • smena navbati vaqt tartibida ketadi (ochish→yopish va yopish→ochish)
    • server hali o'chiq bo'lsa navbat saqlanadi
    • BITTA endpoint 500 beradi, qolgan server sog'lom → kassa oflayn
      rejimga O'TMAYDI va boshqa amallar to'silmaydi
    • o'sha 500 chek uchun "rad etilgan" deb belgilanadi (server tirik),
      lekin server butunlay o'chganda XUDDI SHU 500 rad etish hisoblanmaydi

Windows'da qo'lda tekshirilishi kerak:
  1. Server 500 qaytaradi → smena ochiladi, sotuv ketadi, chek navbatda
  2. Server javob bermaydi (hang) → startup 20s ichida ochiladi
  3. Server qisman ishlaydi (employees 200, roles 500) → ruxsatlar yo'qolmaydi
  4. Server tiklanadi → navbatlar avtomatik ketadi
  5. Oflayn qaytarish → fiskal chek chiqadi, server tiklangach yuklanadi
