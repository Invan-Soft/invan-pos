# Task: Smena navbati FIFO — oflayn ochish/yopish tartibi va "bir marta yopish" cheklovi

**Boshlangan:** 2026-10-02
**Holat:** in-progress (relizda — 1.1.2+129, PRO, 2026-10-02; Windows va do'kon sinovi kutilmoqda)
**Branch:** fix/smena-navbat-fifo → `ayyubxon` (commit `a24d0c9`, merge `7b3d01b`, reliz `c4e42e1`)

## Maqsad
Server yoki internet yo'qligida bajarilgan smena ochish/yopishlari serverga
TO'LIQ va AYNAN sodir bo'lgan tartibda yetsin. Eski navbatda ochish va yopish
uchun bittadan joy bor edi: ikkinchi oflayn ochish birinchisining vaqtini
o'chirardi (server qaytganda navbat tiqilardi), ikkinchi oflayn yopish esa
umuman bloklanardi.

## Avvalgi implementatsiya
docs/sessions/archive/2026-08-13-shift-diagnostics-warnings.md (Yakunlangan 2026-09-07)
↑ U yerda navbatda bitta yopish uchun joy qoldirilgan va `blockingCloseIssue`
qo'shilgan edi. Sabab: ikkinchi yopish birinchisining sanasini o'chirardi.
Endi navbat ro'yxatga aylanadi — cheklov kerak emas.

docs/sessions/2026-09-02-backend-health-offline-mode.md (in-progress)
↑ U yerda `ShiftSyncQueue._openBeforeClose` qo'shilgan (ochish/yopish vaqt
tartibida). Endi tartib ro'yxatning o'zida saqlanadi.

## Bug (aniq stsenariy)
Server ertalabdan o'chiq: 08:00 oflayn ochish → 14:00 yopish → 14:05 qayta
ochish. `openedDate` 08:00 → 14:05 ga almashadi. Server qaytganda navbatda
"yopish 14:00, ochish 14:05" qoladi → avval yopish ketadi. Dastlab
arxivdagi da'voga (2026-08-13, 171-qator: "server rad etadi") tayanib
"navbat tiqiladi" deb baholangan edi; jonli dev sinovi buni INKOR qildi —
server yopiq kassani yopishga 200 qaytaradi. Haqiqiy oqibat: 08:00–14:00
smenasi serverga UMUMAN yetmaydi (ochilishi o'chib ketgan, yopilishi bekor).

Shu holat "smena ONLAYN ochilgan, yopilishi navbatda, keyin yangisi oflayn
ochilgan" holati bilan Pref'da BIR XIL ko'rinadi — ikki slotli navbat ularni
ajrata olmaydi (ikkinchisida "avval yopish" to'g'ri,
test/server_down_behaviour_test.dart:507).

Qo'shimcha kamchiliklar:
- `user_id` yuborish paytidagi kassirdan olinardi (`PrefKeys.userId` — PIN
  bilan kirgan xodim) → Alining smenasi Vali nomidan ketardi.
- Onlayn ochish POST'i yiqilsa (fire-and-forget) navbatga tushmasdi.
- "Yopishni yuborish" tugmasi yopish-oldi dialogidan bosilsa `shiftsOpened`
  ni `false` qilardi — joriy (ochiq) smena Pref'da yopiq bo'lib qolardi.

Ehtimollik past (uzilish odatda 2-3 soat, smena uzoqroq), lekin kelgusi
versiyalar uchun tuzatildi (foydalanuvchi qarori, 2026-10-02).

## Scope
- lib/changes/services/shift/shift_sync_queue.dart — qayta yoziladi (FIFO)
- lib/changes/services/shift_api_4.dart — `openShift`/`closeShift` vaqt va
  `user_id` ni parametr sifatida oladi; `closeShift` haqiqiy status qaytaradi
- lib/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart
  — `openShift`/`closeShift` navbatga yozadi
- lib/changes/services/shift/shift_diagnostics.dart — snapshot navbatdan;
  `canCloseOffline`, `blockingCloseIssue`, `offlineCloseBlockedByPendingClose`
  olib tashlanadi
- lib/changes/providers/open_shift_provider.dart — yopish-oldi flush,
  "Yopishni yuborish" = navbatni yuborish
- lib/features/home/components/offline_mode_badge.dart — voqealar soni
- lib/utils/constants/pref_keys.dart — yangi kalit `shift_sync_queue`
- test/shift_close_guard_test.dart, test/server_down_behaviour_test.dart
- Scope dan tashqari: `_ofd()` o'lik kodi ("Потолок" matni), onlayn ochish
  POST'ini kutish (fire-and-forget qoladi)

## Bajarilgan
- [x] Tahlil: eski xatti-harakat matritsasi, screenshot "Потолок открыть
  невозможно." faqat ≤ v1.1.2+119 da (`_simple()`), +120 da `023ac8f` bilan
  diagnostika dialogiga almashgan
  → Sabab: kassa eski versiyada — kodni o'zgartirish shart emas, yangilash kerak

- [x] `ShiftSyncQueue` qayta yozildi — FIFO ro'yxat (`ShiftQueueEvent`:
  method/at/user_id), `enqueueOpen/Close`, qat'iy tartibli `flush`, rad
  etilgan voqea olib tashlanadi + Telegram (force), eski kalitlardan
  ko'chirish (`_legacyEvents`, takrorlanmaydi, `_save` da tozalanadi)
  → lib/changes/services/shift/shift_sync_queue.dart
  → Sabab: ikki slot B stsenariyni ajrata olmasdi; rad etish qoidasi
    cheklar/vozvrat bilan bir xil (`BackendHealth.isDocumentRejection`)

- [x] `ShiftApi4.openShift/closeShift({openedAt|closedAt, userId})`;
  `closeShift` xatoda ham haqiqiy `statusCode` qaytaradi
  → lib/changes/services/shift_api_4.dart
  → Sabab: navbatdan yuborilganda vaqt/kassir voqea paytidagisi bo'lishi
    kerak; navbat "rad etdi" va "javob bermadi"ni status bo'yicha ajratadi

- [x] `ShiftSingleton4.openShift`: vaqt/kassir bir marta olinadi; onlayn
  bo'lsa avval `flush('before-open')`; oflayn/server yiqilgan → navbatga;
  navbat bo'sh bo'lmasa to'g'ridan-to'g'ri POST yo'q; onlayn POST yiqilsa
  ham navbatga. `closeShift`: oflayn yoki navbat bo'sh emas → navbatga
  (+ `flush('after-close')`); onlayn non-200 → navbatga
  → lib/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart
  → Sabab: qat'iy FIFO; oflayn yopish cheklovi yo'q

- [x] `ShiftDiagnostics`: snapshot navbatdan (eng eski vaqtlar, sonlar,
  `queueSummary` → Telegram'da "Smena navbati: ..."); `canCloseOffline`,
  `blockingCloseIssue`, `offlineCloseBlockedByPendingClose` olib tashlandi;
  `noInternet` matnidan "keyingi smenani yopib bo'lmaydi" olib tashlandi
  → lib/changes/services/shift/shift_diagnostics.dart

- [x] `OpenShiftProvider`: yopish-oldi flush `hasPending` bo'yicha, bloklovchi
  dialog olib tashlandi; "Yopishni yuborish" = `markUserInitiatedAction` +
  `flush('manual')`, `shiftsOpened` ga tegmaydi; yopilgandan keyingi
  ogohlantirish `hasPendingClose` bo'yicha
  → lib/changes/providers/open_shift_provider.dart
  → Sabab: eski tugma joriy ochiq smenani Pref'da yopiq qilib qo'yardi

- [x] Badge navbatdagi voqealar sonini qo'shadi
  → lib/features/home/components/offline_mode_badge.dart

- [x] Testlar: test/server_down_behaviour_test.dart — smena guruhi yangi
  navbatga o'tkazildi + 6 yangi test (B stsenariy, ikki marta yopish, 401,
  rad etish → keyingisi ketadi, user_id, eski kalitlar); yangi
  `ServerMode.rejectShiftClose`. test/shift_close_guard_test.dart — to'siq
  testlari olib tashlandi, `noInternet` matni testi qo'shildi

- [x] Arxiv 2026-08-13 hujjatiga "Superseded by", 2026-09-02 hujjatiga
  ko'rsatma qatori qo'shildi

- [x] Screenshot kassasining logi (foydalanuvchi keltirdi): versiya
  `1.1.2+110`, 07:17–07:18 da `GET shift_statuses → 500 "Error fetching
  cashboxes from PostgreSQL"` (DB `65.21.108.167:30032` connection refused,
  ~07:06–07:19). +110 da 500 → `isReturn=false` → "Потолок" snackbar.
  → Sabab 100% tasdiqlandi: eski versiya + haqiqiy server (DB) uzilishi;
    4xx gipotezasi inkor qilindi. Kod o'zgarishi kerak emas — kassani yangilash.

### Stend sinovi (foydalanuvchi: "har xil caselar bilan sinab ko'r")
- [x] test/shift_queue_scenarios_test.dart — kassa holatini ESLAYDIGAN soxta
  backend (noto'g'ri o'tishni rad etadi, rad etish kodi sozlanadi) + uzilish
  in'ektsiyasi (500, internet yo'q, Wi-Fi login HTML, 401, javob yo'qolishi,
  bir lahzalik 500/502/503/404). Ilovaning HAQIQIY kodi ishlaydi
  (`openShift`, `syncCloseToServer`, navbat, ApiProvider, BackendHealth).
  Talab: navbat bo'sh + server holati = kassa holati + server qabul qilgan
  amallar = kassir amallari (tartib, vaqt, bir martadan). 24 aniq stsenariy
  + tasodifiy (4 server xulqi × N ketma-ketlik × 25 qadam).
  → Haqiqiy API sinovi dastlab rad etildi (token o'qish — auto mode);
    foydalanuvchi auto rejimdan chiqib ruxsat berdi (quyida).

### Jonli dev API sinovi (2026-10-02, kassa "asda", ilovaning o'z kodi)
Vaqtinchalik test (ilova kodi: `syncCloseToServer`, `ShiftSyncQueue`,
`ShiftApi4`, `ApiProvider`) haqiqiy `dev.api.7i.uz` ga; boshlang'ich holat
(ochiq, Mansr) oxirida tiklandi; token va test fayli o'chirildi.
| Sinov | Server javobi |
|---|---|
| Onlayn yopish (navbat bo'sh) | 200, yopildi |
| Navbatdan o'tgan vaqtli 4 voqea ketma-ket (ochish/yopish ×2) | hammasi 200, holat to'g'ri |
| Takror yopish (yopiq kassa) / takror ochish (ochiq kassa) | 200 "OK", holat o'zgarmaydi (idempotent) |
| Teskari vaqt (yopish < ochish), kechagi vaqt | 200 — vaqt tartibi tekshirilmaydi |
| Mavjud bo'lmagan `user_id` | 500 "sql: no rows in result set", qabul qilinmaydi |
| Yaroqsiz token | 403 (401 emas) |
| Navbat orqali o'chirilgan kassir | 5 urinish saqlandi, 1 soatdan keyin olib tashlandi |
- `shift_statuses` da vaqt maydonlari yo'q, yopiq holat `"close"` (kod
  `close`/`closed` ikkalasini qabul qiladi).
- TUZATISH (oldingi da'vo): eski B stsenariyda navbat tiqilmasdi — server
  yopiq kassani yopishga 200 qaytaradi; oqibat — 1-smena (08:00–14:00)
  serverga UMUMAN yetmasdi (yozuv yo'qolardi).

- [x] Zaharli voqea qoidasi (jonli sinov topgan: o'chirilgan kassir → 500
  doimiy): server tirik bo'lib voqeani ≥5 marta va ≥1 soat qabul qilmasa —
  majburiy Telegram hisoboti bilan olib tashlanadi; hisob voqea JSON'ida
  (`failures`, `first_failure_at`). Uzilishda (holat noma'lum) sanalmaydi.
  → shift_sync_queue.dart (`poisonAttempts`, `poisonAfter`, `_replace`)
- [x] Fuzz seed 247 muvaffaqiyatsizligi — stend artefakti (fon tekshiruvi
  o'chiq testda eskirgan probe `BackendHealth`ni `down` qoldirardi); ilovada
  probe 30 s da tiklaydi. `deliverAll` shunga moslandi.

- [x] TOPILGAN VA TUZATILGAN (stend/tahlil natijasi):
  1. Server bir lahza 500 qaytarib darhol tirilsa, "rad etildi" deb HAQIQIY
     yopilish tashlab yuborilardi (`isDocumentRejection` probe'i tirik
     serverni ko'rardi) — tasodifiy test seed 26 da topildi. Endi voqea faqat
     `shift_statuses` dagi kassa holati unga allaqachon mos bo'lsa olinadi
     (`ShiftSyncQueue._alreadyApplied`); javob kodiga ishonilmaydi.
     → lib/changes/services/shift/shift_sync_queue.dart
  2. Navbat tiqilgan, server bizning yopilishimizni bilmay kassani "ochiq"
     ko'rsatsa — ochish bloklanardi. Endi before-open flush'dan keyin ham
     navbat bo'sh bo'lmasa smena lokal ochiladi (server holati eskirgan).
     → shift_singleton_4.dart `openShift`
  3. Onlayn ochish POST'i kutilmasdi (ochib-darhol-yopishda tartib
     buzilishi mumkin edi) — endi kutiladi.
  4. Har voqea o'z `cashbox_id`si bilan (kassa qayta aktivlashtirilsa).
  5. Logout butun Pref'ni (navbatni ham) tozalaydi — endi chiqishdan oldin
     navbat yuboriladi, ketmasa chiqish to'xtatiladi.
     → lib/features/settings/features/child_settings/view/child_settings_content.dart
  6. `ShiftApi4.closeShift` 200 javobi Map bo'lmasa istisno → "xato" deb
     hisoblanardi; 201 ham muvaffaqiyat. `isCashboxFullyClosed` umumiy helper.
  7. `ShiftSingleton4.clock` (test seam), `syncCloseToServer` ajratildi
     (ObjectBox'siz sinash uchun)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows'da qo'lda sinov (server o'chirilgan holda) — "Test /
  Verifikatsiya" dagi ro'yxat bo'yicha
- [ ] Commit (foydalanuvchi aytganda) → port-changelog bo'limi (CLAUDE.md
  7-qadam) + Odoo forki qarori
- [ ] MR: fix/smena-navbat-fifo → ayyubxon

## Qabul qilingan qarorlar
- Navbat = Pref'dagi JSON ro'yxat (`shift_sync_queue`); har voqea: `method`,
  `at` (UTC, `yyyy-MM-dd HH:mm:ss`), `user_id` — Pref allaqachon smena
  holati uchun ishlatiladi, ObjectBox sxemasi o'zgarmaydi.
- Qat'iy FIFO: navbat bo'sh bo'lmasa voqea to'g'ridan-to'g'ri onlayn
  yuborilmaydi — navbat oxiriga qo'shiladi.
- ~~Server rad etsa (`isDocumentRejection`) voqea tashlanadi~~ — BEKOR
  QILINDI (stend testi xavfni ko'rsatdi). Yangi qoida: 200/201 bo'lmasa
  `shift_statuses` so'raladi; kassa holati voqea kutgan holatda bo'lsagina
  (ochish → ochiq, yopish → to'liq yopiq) voqea olinadi, aks holda navbatda
  qoladi va yuborish to'xtaydi. Sabab: status kodi "rad etdi" bilan "bir
  lahza yiqildi"ni ajrata olmaydi; haqiqiy amalni tashlash serverni kassadan
  ajratadi, kutish esa faqat kechiktiradi (Telegram'da ko'rinadi).
- Navbatda yetmagan voqea bo'lsa, ochish server holatiga qaramay lokal
  bajariladi (401 da ham). Navbat bo'sh + 401 → avvalgidek bloklanadi.
- Zaharli voqea: server tirik + holat mos emas + ≥5 rad + ≥1 soat → olib
  tashlanadi (hisobot bilan). Sabab: bitta buzuq voqea (o'chirilgan kassir)
  navbatni va logout'ni abadiy to'smasin; 1 soat — qisqa qisman uzilishda
  haqiqiy voqea tashlanmasligi uchun.
- Eski kalitlar (`opened/closed Date/Count`) o'qishda ro'yxat OXIRIGA
  qo'shiladi (oddiy yangilanishda ro'yxat bo'sh — farqi yo'q; Shorebird
  rollback'dan keyin ular ro'yxatdan yangiroq), birinchi yozishda tozalanadi.
- Oflayn yopish cheklovi olib tashlanadi.

## Ochiq savollar
- ~~Server takrorga qanday javob beradi?~~ — jonli: 200 "OK" (idempotent).
- ~~"Baribir chiqish" varianti kerakmi?~~ — KERAK EMAS (foydalanuvchi,
  2026-10-02). Logout tartibi eskicha: avval "Ochiq smenani yopishingiz
  kerak" (smena ochiq bo'lsa), so'ng — smena yopiq bo'lsa — navbat
  tekshiruvi ("Smena ma'lumotlari serverga hali yuborilmagan...").
- Smena ochilgan kassa +110 da edi — avtomatik yangilanish nega yetmagan?
  Backend `cashbox_version` bo'yicha eski kassalar ro'yxati.
- Odoo forkiga: commit paytida qaror (shift_pos — InVan backend endpointi).

## Test / Verifikatsiya
- `flutter test` — 1424/1424 o'tdi (2026-10-02, macOS, yakuniy kod)
- `flutter analyze lib test` — 0 error; o'zgargan fayllarda yangi
  ogohlantirish yo'q
- Stend (test/shift_queue_scenarios_test.dart): 28 test; og'ir rejim
  `--dart-define=SHIFT_FUZZ_SEEDS=2000` — 8000 ketma-ketlik × 25 qadam,
  hammasi o'tdi (15 daqiqa)
- Jonli dev API — yuqoridagi jadval (ikki marta, yakuniy kod bilan ham)
- Qo'lda sinov (foydalanuvchi, Mac, dev, 2026-10-02): 4-5 marta ochish/
  yopish, orada sotuv, so'ng internetsiz ochish/yopish — hammasi ishladi.
  Alice: internet qaytgach `shift_pos` ×7+ ikki soniya ichida, hajmlari
  210/212 B almashib (ochish/yopish tartibi saqlangan), hammasi 200
  `{"message":"OK"}`, oxirgisi ochish; keyin `order_pos` 201 ×2.
  → Windows'da sinov hali qilinmagan (asosiy platforma).
- Qo'lda sinov (Windows, HALI QILINMAGAN):
  1. Server ishlayotganda smena ochish/yopish — avvalgidek (navbat bo'sh,
     to'g'ridan-to'g'ri POST).
  2. Internetni uzib (yoki server o'chiq holda): ochish → yopish → ochish →
     yopish — hammasi o'tishi, ikkinchi yopishda "Smena yopilmadi" dialogi
     CHIQMASLIGI, oflayn belgida 4 ta voqea.
  3. Internet/server qaytgach — Alice'da `shift_pos` ×4 aynan shu tartibda
     (open, close, open, close), har birida o'z `opened_at`/`closed_at`;
     belgi 0.
  4. +128 da navbat to'la holda yangilash (eski kalitlar) — navbat
     yo'qolmasligi va yuborilishi.
  5. Yopish-oldi dialogida "Yopishni yuborish" — joriy smena OCHIQ qolishi.
