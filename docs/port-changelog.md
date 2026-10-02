# Port hujjati: BHM taskidan boshlab qilingan barcha o'zgarishlar

**Manba loyiha:** InVan 2 POS — `pos-invan-2`, branch `ayyubxon`, versiya `1.1.2+129` (2026-10-02)
**Hujjat holati:** 2026-10-02 (1–6-tasklar 1.1.2+127 relizida; 7–12-tasklar 1.1.2+129 relizida; ikkalasi PRO backendga yuklangan)
**Kimga:** shu loyihaning boshqa nusxasini (boshqa ERP bilan integratsiya qilinayotgan nusxa — "InVan 1") InVan 2 bilan bir xil holatga keltiradigan dasturchi yoki Claude.

## Bu hujjat nima

2026-09-10 dan boshlab — naqd to'lov chegarasi kodga qattiq yozilgan `25 000 000` dan Soliq API'dagi `400 × BHM` ga o'tkazilgan taskdan — InVan 2 da qilingan **barcha** o'zgarish va tuzatishlar bitta faylda, xronologik tartibda. Har task uchun: nima va nima uchun, qanday ishlaydi, qaysi fayllar, qo'llash tartibi, kodning o'zi (yangi fayl to'liq, o'zgargan fayl diff), testlar, ochiq savollar.

Undan OLDINGI tasklar (masalan BackendHealth oflayn rejim 2026-09-02, OrderingProvider4 ajratish, narx sinxron kursor va h.k.) bu hujjatga kirmaydi — ular `docs/sessions/archive/INDEX.md` va `docs/sessions/` da. Qaysi tasklar o'sha oldingi ishlarga bog'liq bo'lsa, har bo'limning "Bog'liqliklar" qismida aytilgan.

## Boshqa nusxada (InVan 1) Claude uchun ko'rsatma

1. Avval shu hujjatni boshidan oxirigacha o'qing. Tasklar tartibda qo'llanadi: 1 → 2 → … → 12. 3-task 1-2 ga bog'liq emas; 4-task 3-taskdagi vozvrat oqimiga tegishli (lekin undan mustaqil qo'llasa ham bo'ladi); 5-task fiskal item quruvchiga tegishli, 2-task bilan bir faylda (`receipt_singleton_4.dart`); 6-task boshqalardan MUSTAQIL (notification/sinxron qatlami) — istalgan tartibda, hatto birinchi bo'lib qo'llash mumkin, lekin o'zining ICHIDA 2026-08-12 taskiga (undan TASHQARIDA) bog'liq — 6-taskning "4. Bog'liqliklar" bo'limiga qarang. 7-task 6-taskdan keyin qo'llanadi (o'sha qatlam; 2-task qoidasining yozish tomoni). 8-task (Shorebird code push) mustaqil; 12-task (Telegram hisobot) faqat 8-taskdan keyin. 9-task 5-taskdagi `FiscalPaymentSplit` ga tayanadi va **ObjectBox sxemasini o'zgartiradi** (faqat to'liq reliz bilan; InVan 1 ObjectBox'ni o'zi generatsiya qiladi). 10-task (savat, multi-klient) va 11-task (smena navbati) boshqalardan mustaqil.
2. 1–6-tasklar commit qilingan va 1.1.2+127 relizida PRO backendga yuklangan (2026-09-24) — hech biri WIP emas. 7–12-tasklar (2026-09-30 — 2026-10-02) commit qilingan va 1.1.2+129 relizida PRO backendga yuklangan (2026-10-02). Hech biri do'konda haqiqiy tarmoq/fiskal modul bilan sinalmagan (pastda har taskning "Holat"iga qarang) — port qilsa bo'ladi, lekin bu bilib qo'llanadi. 7-task 6-taskning davomi: 6-task oxiridagi "Ataylab tuzatilmagan" ro'yxatidagi `isMarking` bandi 7-taskda bekor qilinadi.
3. Har taskning "Qo'llash tartibi" bo'limida InVan 1 da nimani qidirish kerakligi yozilgan. InVan 1 da InVan 2 dagi domen sinflari (`CashRestrictionRules`, `MxikRules`, `SoldItemBuilder`, `RefundUploadQueue`, `BackendHealth`, `SyncCursor`) bo'lmasligi mumkin — bunday holatlar har bo'limda alohida ko'rsatilgan.
4. **Port qilinMAYdigan** narsalar: `pubspec.yaml` versiya bump'lari, `api_provider.dart` dagi DEV/PRO almashinuvi (release commitlarida bo'ladi), `docs/` fayllari.
5. Testlar `test/support/provider_harness.dart` ga tayanadi (`setUpPosTestEnv`, `tearDownPosTestEnv`, `kCashierId`, `kUserId`, `kCashierName`, `makeSoldItem`). InVan 1 da bo'lmasa — InVan 2 dan nusxa oling (203 qator: Hive + Pref + ObjectBox test muhiti, adapterlar) yoki testlarni moslang. Testsiz port ham mumkin, lekin tavsiya etilmaydi: har taskning testi aynan "nima buzilmasligi kerak"ni mixlaydi.
6. Har qadamdan keyin `dart analyze` va `flutter test`.

## Tasklar ro'yxati

| # | Sana | Task | InVan 2 reliz | Holat (2026-10-02) | Commit |
|---|---|---|---|---|---|
| 1 | 2026-09-10 | Naqd chegarasi: 25 mln statik → Soliq API'dan `400 × BHM` (hozir 176 mln) | 1.1.2+123, +124 | Relizda; do'kon sinovi kutilmoqda | `cc66526`, `c0ae23a` |
| 2 | 2026-09-11 | `is_marking=false`: markirovka dialogi yo'q, fiskalga statik MXIK + bo'sh barcode | 1.1.2+125 | Relizda; do'kon sinovi kutilmoqda | `347813b` |
| 3 | 2026-09-22 | Vozvrat: serverga vozvratning O'Z fiskal URL'i (tartib fiskal → lokal → server) | 1.1.2+126 | Relizda; do'kon sinovi kutilmoqda | `fa2d395` |
| 4 | 2026-09-24 | Vozvrat fiskal chekida `OwnerType` va komitent STIR sotuv bilan bir xil (katalogdan) | **1.1.2+127** | Relizda; do'kon sinovi kutilmoqda | `c853b27` |
| 5 | 2026-09-24 | Fiskal QQS bazasi chegirmadan keyin: `VAT = (Price − Discount − Other) × p / (100 + p)` | **1.1.2+127** | Relizda (`fix/fiskal-qqs-chegirma-bazasi` → `ayyubxon`ga birlashtirildi); do'kon sinovi kutilmoqda | `85199e6` (merge `7e01ce8`) |
| 6 | 2026-09-24 | Notification (polling) sinxron tirqichlari: server soati, buzuq notification, timeout, qulf | **1.1.2+127** | Relizda; do'kon sinovi kutilmoqda | `bfc4929`..`80f88d7` |
| 7 | 2026-09-30 | `is_marking` true→false o'zgarishi kassaga o'tmasligi: `putItems` sticky + Soliq avto-true endi aniq false'ni yengmaydi | **1.1.2+129** | Relizda; do'kon sinovi kutilmoqda | `a83668c`, `d31e4df` (merge `1e96fc5`) |
| 8 | 2026-09-30 | Shorebird code push: patch `.exe` siz, kassir bir ochilishda; "Yangilanish tayyor" tugmasi; xato ekrani; Windows qayta yonish | 1.1.2+128 (CI), **1.1.2+129** | Relizda; Mac'da sinalgan, Windows prod sinovi kutilmoqda | `7db61a9`, `3154158`, `df6ef7c`, `919e601`, `d16df8a`, `40bc8c2`, `5112b2b` |
| 9 | 2026-10-01 | Click Pass / Payme Go → `ReceivedCard` (QQS to'liq) + elektron to'lov ID'lari chekda (**ObjectBox +1**) | **1.1.2+129** | Relizda; qurilmada (haqiqiy Pass/Go + fiskal) sinov kutilmoqda | `f007377`, `e5ba429` |
| 10 | 2026-10-01 | Multi-klient orqali access-siz mahsulot o'chirish yopildi | **1.1.2+129** | Relizda; do'kon sinovi kutilmoqda | `a3a69a9` |
| 11 | 2026-10-02 | Smena navbati FIFO: server/internet yo'qligida har ochish/yopish serverga tartib bilan | **1.1.2+129** | Relizda; Mac + jonli dev API'da sinalgan, Windows sinovi kutilmoqda | `a24d0c9` |
| 12 | 2026-10-02 | Shorebird build/patch olingani Telegram kanalga hisobot | **1.1.2+129** | Relizda; Mac sinov relizida kanalga yetgani tasdiqlangan | `f21c8d8` (+ `40bc8c2`) |

Kod o'zgarishisiz hujjatlar (oxirgi bo'limda): `docs/fiskal-tolov-turlari-va-qqs.md` (tahlil, 5-taskka olib keldi), `docs/invan1-mac-github-release-port.md` (InVan 1 uchun Mac + GitHub Actions reliz tartibi), `docs/fiscal-sale-integration.md` (fiskal spec, VAT formulasi yangilandi), `docs/sessions/2026-09-24-ws-notification-gap-audit.md` (6-taskning to'liq tahlili), `docs/shorebird-qoidalari.md` (8-task: patch chiqarish qoidalari, rollback), `docs/fiskal-tolov-turlari-qisqa.md` (9-task: to'lov turlari → fiskal maydon, qisqa jadval).

## Commit xronologiyasi (`ayyubxon`, `cc66526..HEAD`)

```
cc66526 2026-09-10 feat(naqd): chegara 400 × BHM Soliq API'dan olinadi                     ← 1-task
f1b3b27 2026-09-10 release: 1.1.2+123 (pubspec, api_provider PRO)                           (port qilinmaydi)
c0ae23a 2026-09-10 feat(naqd): BHM "To'liq yangilash"da olinadi, so'rovlar Alice'da         ← 1-task
efa4727 2026-09-10 release: 1.1.2+124                                                        (port qilinmaydi)
347813b 2026-09-11 feat(markirovka): is_marking=false — dialog yo'q, fiskalga statik MXIK   ← 2-task
f0eefff 2026-09-11 release: 1.1.2+125                                                        (port qilinmaydi)
fa2d395 2026-09-22 fix(vozvrat): serverga vozvratning o'z fiskal URL'i                      ← 3-task
1b11eca 2026-09-22 release: 1.1.2+126                                                        (port qilinmaydi)
c853b27 2026-09-24 fix(vozvrat): fiskal OwnerType va komitent STIR sotuv bilan bir xil      ← 4-task
8464be3 9cf4f06 3a3afdf 2026-09-24 docs: faqat sessiya hujjati                              (port qilinmaydi)
85199e6..0b3114c 2026-09-24 fix/test/chore(fiskal): QQS bazasi + qog'oz chek + o'lik kod    ← 5-task
                            [branch fix/fiskal-qqs-chegirma-bazasi, 5 commit]
bfc4929 2026-09-24 fix(sync): mahsulot/narx/kategoriya/diskont notification'lari            ← 6-task
02ab30e 2026-09-24 fix(env): API muhiti PRO; ServerClock ApiProvider javoblaridan ham       ← 6-task
e85c52e 2026-09-24 test(sync): notification/katalog sinxroni uchun testlar (+51)            ← 6-task
8a86b15 2026-09-24 docs: notification sinxron auditi hujjati                                (port qilinmaydi)
03a9227 2026-09-24 fix(sync): KRITIK — avto-sinxron halqasi Wrapper unmount bo'lgach o'lardi ← 6-task
c264890 2026-09-24 fix(sync): qo'shimcha audit topilmalari — parse/narx/kategoriya           ← 6-task
80f88d7 2026-09-24 test(sync): yuqoridagi qo'shimcha tuzatishlar uchun testlar               ← 6-task
777ff5b 2026-09-24 docs: 3-bosqich audit qo'shimchasi                                        (port qilinmaydi)
36a2f6f 2026-09-24 release: 1.1.2+127 (pubspec)                                              (port qilinmaydi)
7e01ce8 2026-09-24 merge: fix/fiskal-qqs-chegirma-bazasi → ayyubxon (5-task shu yerda qo'shildi)
7e2d6e9 2026-09-24 docs: 1.1.2+127 PRO backend'ga yuklandi                                   (port qilinmaydi)
44f3888 2026-09-24 docs(port): 6-task to'liq yozildi                                         (port qilinmaydi)
7db61a9 2026-09-30 release: 1.1.3+128 — Shorebird CI (release.yml → shorebird, patch.yml)   ← 8-task (CI)
3154158 2026-09-30 ci(shorebird): Windows runner'da git long paths                          ← 8-task (CI)
84a262e 2026-09-30 release: 1.1.2+128 — Shorebird code push                                 (port qilinmaydi)
df6ef7c 2026-09-30 feat(shorebird): patch bir ochilishda + "Yangilanish tayyor" tugmasi     ← 8-task
919e601 2026-09-30 fix(shorebird): tugma faqat 6 ta savat bo'sh bo'lganda                   ← 8-task
a83668c 2026-09-30 fix(sync): is_marking — server qiymati lokal true'ni yengadi              ← 7-task
b938f5c 2026-09-30 docs(port): 7-task to'liq yozildi                                        (port qilinmaydi)
f007377 2026-10-01 fix(fiskal): Click Pass / Payme Go → ReceivedCard, QR → Other            ← 9-task
a3a69a9 2026-10-01 fix(savat): multi-klient orqali access-siz o'chirish yopildi             ← 10-task
d31e4df 2026-10-01 test(sync): is_marking true→false e2e stsenariy                          ← 7-task
b59d371 2026-10-01 docs: sessiya hujjatlari, fiskal to'lov turlari tahlili                  (port qilinmaydi)
1e96fc5 2026-10-01 merge: fix/is-marking-false-sinxron → ayyubxon (7, 9, 10-task shu yerda qo'shildi)
d16df8a 2026-10-01 fix(shorebird): qayta ishga tushirish himoyasi                           ← 8-task
a24d0c9 2026-10-02 fix(smena): navbat FIFO ro'yxat                                          ← 11-task
f21c8d8 2026-10-02 feat(shorebird): Telegram kanalga hisobot (PatchReporter)                ← 12-task
40bc8c2 2026-10-02 fix(shorebird): bir ochilishda, tez ochilish, xato ekrani                ← 8-task (+12 ulanishi)
5112b2b 2026-10-02 fix(windows): o'zi qayta yongan nusxa eski nusxani kutadi                ← 8-task
e5ba429 2026-10-02 fix(fiskal): elektron to'lov ID'lari chekda (ObjectBox +1)               ← 9-task
7b3d01b 2026-10-02 merge: fix/smena-navbat-fifo → ayyubxon (8, 9, 11, 12-task)
c4e42e1 2026-10-02 release: 1.1.2+129                                                       (port qilinmaydi)
```

InVan 2 repo'si qo'lda bo'lsa diffni bevosita olish mumkin: `git show <commit> -- lib/ test/` yoki 6-task uchun `git diff 3a3afdf..7e2d6e9 -- <fayl>`. Bo'lmasa — quyidagi bo'limlar yetarli.

---

# 1-TASK — Naqd chegarasi `400 × BHM` Soliq API'dan (1.1.2+123 / +124)

> **Commitlar:** `cc66526` (servis, qoida, hooklar, testlar) + `c0ae23a` ("To'liq yangilash" dialogiga ko'chirildi, Alice). Reliz 1.1.2+123 (2026-09-10) va 1.1.2+124 (2026-09-10).
> **Sessiya hujjati:** `docs/sessions/2026-09-10-bhm-naqd-chegara-api.md`.
> **Manba:** `docs/bhm-naqd-chegara-port.md` (2026-09-10) — quyida to'liq kiritilgan, sarlavhalar bir daraja pastga tushirilgan.
> **Holat 2026-09-24:** relizda; do'konda real API bilan sinov hali tasdiqlanmagan. Ochiq savollar: chegara qator bo'yicha (hozirgi) yoki chek jami bo'yicha; API javobidagi `cashSaleAllowed` maydoni.

## BHM naqd chegarasi: port qilish qo'llanmasi

**Manba:** `ayyubxon` branch, commitlar `cc66526` (BHM servis) va `c0ae23a` (to'liq yangilash + Alice), reliz 1.1.2+124 (2026-09-10).
**Diff bazasi:** `11a4770` → `efa4727` (faqat feature fayllari, `api_provider.dart` PRO almashuvi va `pubspec` kirmaydi).

Bu hujjat o'zgarishlarni **xuddi shu loyihaning boshqa nusxasiga** qo'lda ko'chirish uchun yozilgan. Yangi fayllar to'liq, o'zgargan fayllar diff ko'rinishida berilgan.

---

### 1. Nima va nima uchun

2026-07-20 393-son qaror va 2026-08-27 PF-175-son Farmon: **narxi BHMning 400 baravaridan oshadigan tovar/xizmat uchun naqd to'lov taqiqlanadi**, faqat karta yoki elektron to'lov.

Ilgari POS'da bu chegara kodga qattiq yozilgan edi (25 mln, `CashRestrictionRules.bigTotalLimit`). Endi:

- BHM (bazaviy hisoblash miqdori, ruscha БРВ) Soliq qo'mitasining ochiq API'sidan olinadi.
- Chegara = **BHM × 400**. 2026-09-10 holatiga BHM = 440 000 so'm → chegara **176 000 000** so'm.
- Qiymat lokalga (Hive `prefs`) saqlanadi, cheklov qoidasi faqat lokaldan o'qiydi.
- Yangilash kam bo'ladigan amalga bog'langan: "To'liq yangilash" dialogi (Сервис bosqichi) + startup (24 soat TTL).
- Har so'rov Alice'da ko'rinadi.

### 2. Soliq API

```
GET https://txkm.soliq.uz/api/txkm-api/ccm-api/info/check/is-vat/<STIR>
accept: */*
```
Javob (2026-09-10):
```json
{"success":true,"reason":"So'rov bajarildi","data":true,"percent":12,
 "cashSaleAllowed":false,"fractionalSale":false,"baseCalculationAmount":440000}
```
- Auth kerak emas. Javob ~0.06 s.
- `<STIR>` — tashkilotning soliq raqami (`tax_payer_id`). POS'da u `PrefKeys.organizationINN` (`organization_inn`) Pref'ida turadi, `OrganizationSingleton.setOrgPrefs` yozadi (aktivlashtirish va "To'liq yangilash" → Организация bosqichi).
- Bizga faqat `baseCalculationAmount` kerak. `cashSaleAllowed`, `percent`, `data` hozircha ishlatilmaydi.
- STIR bo'sh bo'lsa (`tax_payer_id: ""`) so'rov yuborilmaydi, fallback ishlaydi.

### 3. Qanday ishlaydi

```
"To'liq yangilash" → Обновить
   Скидки → Товары → Категория → Организация (STIR Pref'ga yoziladi) → Сотрудники → Сервис
                                                                                      │
                                                                  BhmService.refresh('full-update')
                                                                                      │
                                    GET .../is-vat/<STIR> ──► 200 + baseCalculationAmount
                                                                                      │
                                                Pref: bhm_amount = 440000, bhm_fetched_at = now
                                                                                      │
Ilova startup (auth'dan keyin) ── refreshIfStale('startup') ── kesh 24 soatdan eski bo'lsagina ──┘

Sotuv paytida (tarmoqsiz):
   BhmService.cashLimit = (Pref bhm_amount > 0 ? bhm_amount : 440000) × 400
   CashRestrictionRules.bigTotalHidden(rows, ofdOn, cashsaleCheckOn, limit: cashLimit)
      → cashsale == 1 mahsulot qatorida price × qty > limit  →  naqd tugmasi yopiladi + ogohlantirish
```

**Hisoblash:** `cashLimit = bhm × multiplier`, `multiplier = 400`. Qat'iy `>`: aynan 176 000 000 ruxsat, 176 000 001 taqiq. Chegara **qator bo'yicha** (price × qty), chek jami bo'yicha emas (oldingi xatti-harakat saqlangan).

**Xato holatlari** (hammasi `false` qaytaradi, kesh O'ZGARMAYDI, exception chiqmaydi):
- STIR bo'sh → so'rov yuborilmaydi.
- HTTP ≠ 200, `success:false`, buzuq JSON, `baseCalculationAmount` yo'q yoki 0.
- Timeout (10 s), tarmoq yo'q.
- Xatoda `bhm_fetched_at` yangilanmaydi → kesh "eskirgan" qoladi → keyingi startup/to'liq yangilashda yana urinadi.

**Kesh bo'sh bo'lsa** (yangi o'rnatilgan, hech qachon so'ralmagan): `fallbackBhm = 440000` → chegara baribir 176 mln. Hech qachon 0 yoki eski 25 mln bo'lmaydi.

**Alice:** `BackendHealth` kabi qo'lda `alice.onHttpResponse(res)`. Javob kelmasa yoki STIR bo'sh bo'lsa **status 599** bilan sun'iy yozuv (tanasida sabab). 0 ishlatib bo'lmaydi: `http` 1.6.0 `statusCode < 100` ni `ArgumentError` bilan rad etadi.

### 4. O'zgarishlar ro'yxati

| Fayl | Tur | Nima |
|---|---|---|
| `lib/changes/services/cash_limit/bhm_service.dart` | YANGI | Servis: API → Pref kesh, `cashLimit`, fallback, TTL, in-flight guard, Alice, test inyeksiyalari |
| `test/bhm_service_test.dart` | YANGI | 19 test: fallback/kesh, refresh xato holatlari, TTL, parseAmount |
| `lib/utils/constants/pref_keys.dart` | o'zgargan | Ikkita yangi Pref kaliti (`bhm_amount`, `bhm_fetched_at`). |
| `lib/changes/domain/cart/cash_restriction_rules.dart` | o'zgargan | Qattiq `bigTotalLimit` konstantasi olib tashlandi, `bigTotalHidden` ga `required double limit` parametri qo'shildi. Sinf Pref'ga bog'lanmaydi. |
| `lib/changes/providers/ordering_provider_4.dart` | o'zgargan | `isBigTotalHidden` getteri `limit: BhmService.cashLimit` uzatadi. Import qo'shildi. |
| `lib/features/home/features/home_orders/order_list/order_list_item.dart` | o'zgargan | Savat qatoridagi takroriy qattiq son o'rniga `BhmService.cashLimit`. |
| `lib/changes/dialogs/upd/bloc/upd_bloc.dart` | o'zgargan | "To'liq yangilash" dialogining Сервис bosqichida `BhmService.refresh(reason: 'full-update')`. ASOSIY yangilash nuqtasi. |
| `lib/app/wrapper/wrapper.dart` | o'zgargan | Startup'da (auth'dan keyin, navbatlar flush'i yonida) `refreshIfStale` — 24 soat TTL bilan xavfsizlik to'ri. |
| `lib/utils/l10n/app_uz.arb` | o'zgargan | Ogohlantirish matni raqamsiz (eskirmaydi). Keyin `flutter gen-l10n`. |
| `lib/utils/l10n/app_ru.arb` | o'zgargan | Xuddi shu, ruscha. |
| `test/cash_restriction_rules_test.dart` | o'zgargan | `bigTotalHidden` guruhiga `limit:` parametri, qiymatlar 176 mln ga. |
| `test/cash_restriction_test.dart` | o'zgargan | Provider testlari 176 mln ga, `BhmService.clearCache()` setUp'da, Pref'dagi BHM chegarani boshqarishi testi. |

**Olib tashlangan:** `CashRestrictionRules.bigTotalLimit` konstantasi va `order_list_item.dart` dagi takroriy `25000000`.

**Bog'liqliklar:** yangi paket yo'q. `http` (mavjud), `alice` 0.4.2 (mavjud, `lib/alice_service.dart` dagi global `alice`), `LogHelper` (mavjud). Agar nusxada `lib/changes/domain/cart/cash_restriction_rules.dart` bo'lmasa (Faza 9.3 gacha), chegara `OrderingProvider4.isBigTotalHidden` ichida bo'ladi: u yerda `> 25000000` ni `> BhmService.cashLimit` ga almashtiring.

### 5. Qo'llash tartibi

1. `lib/utils/constants/pref_keys.dart` ga ikkita kalit qo'shing (diff 6.3).
2. `lib/changes/services/cash_limit/bhm_service.dart` ni to'liq yarating (6.1).
3. `cash_restriction_rules.dart` da konstantani olib, `limit` parametrini qo'shing (6.4). Chaqiruvchilar: `ordering_provider_4.dart` (6.5), `order_list_item.dart` (6.6).
4. `upd_bloc.dart` Сервис bosqichiga `refresh` (6.7). `wrapper.dart` startup'ga `refreshIfStale` (6.8).
5. l10n arb matnlari (6.9, 6.10), keyin `flutter gen-l10n`.
6. Testlar: `test/bhm_service_test.dart` (6.2), ikkita cheklov testi (6.11, 6.12). Testlar `test/support/provider_harness.dart` (`setUpPosTestEnv`, `makeSoldItem`) ga tayanadi.
7. `dart analyze` va `flutter test`.
8. Loyihada eski `25000000` / `bigTotalLimit` qolmaganini tekshiring: `grep -rnE "25000000|bigTotalLimit" lib test`.

### 6. Kod

#### 6.1. YANGI: `lib/changes/services/cash_limit/bhm_service.dart`

```dart
/*
    BHM (Bazaviy Hisoblash Miqdori) — naqd to'lov chegarasining manbai.

    Qonun (2026-07-20 393-son qaror, 2026-08-27 PF-175 Farmon): narxi
    400 × BHM dan oshadigan tovar/xizmat uchun naqd to'lov taqiqlanadi.
    BHM qiymati kodga qattiq yozilmaydi — Soliq qo'mitasining ochiq
    API'sidan olinadi (auth talab qilinmaydi, tashkilot STIR'i URL'ga
    qo'shiladi):

      GET https://txkm.soliq.uz/api/txkm-api/ccm-api/info/check/is-vat/<STIR>
      → {"success":true, ..., "baseCalculationAmount":440000}

    Oqim:
      1. API'dan olingan qiymat darhol Pref'ga yoziladi
         (`bhm_amount` + `bhm_fetched_at`).
      2. Cheklov qoidasi (`CashRestrictionRules.bigTotalHidden`) faqat
         Pref'dagi qiymatdan hisoblangan [cashLimit] ni oladi — sotuv
         paytida tarmoqqa hech qachon chiqilmaydi.
      3. Yangilash ikki joyda:
         - "To'liq yangilash" dialogining "Сервис" bosqichi (`UpdBloc`) —
           har doim so'raydi. "Организация" bosqichi STIR'ni yozib
           bo'lgan, va bu kassir ataylab bosadigan kam uchraydigan amal.
         - Ilova ishga tushganda (`Wrapper`) — [refreshInterval] TTL bilan,
           xavfsizlik to'ri sifatida.
         BHM yiliga bir-ikki marta o'zgaradi, tez-tez so'rash shart emas.
      4. Kesh bo'sh bo'lsa (birinchi ishga tushish, oflayn) [fallbackBhm]
         ishlatiladi — 2026-09-10 holatiga ko'ra API bergan qiymat.
      5. Har so'rov Alice'da ko'rinadi (`BackendHealth` kabi qo'lda qayd
         etiladi, chunki bu so'rov `ApiProvider` dan o'tmaydi). Javob umuman
         kelmasa status 599 bilan sun'iy yozuv qo'shiladi — aks holda
         tashqaridan "kassa hech narsa so'ramadi" bo'lib ko'rinardi.
*/

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:invan2/alice_service.dart';
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class BhmService {
  BhmService._();

  /// Soliq API. Oxiriga tashkilot STIR'i qo'shiladi.
  static const String endpoint =
      'https://txkm.soliq.uz/api/txkm-api/ccm-api/info/check/is-vat/';

  /// Kesh bo'sh bo'lganda ishlatiladigan BHM (so'm).
  ///
  /// 2026-09-10 da API qaytargan qiymat. Yangi BHM e'lon qilinsa buni ham
  /// yangilab qo'yish foydali, lekin shart emas — birinchi muvaffaqiyatli
  /// so'rov keshni to'ldiradi va shundan keyin bu son ishlatilmaydi.
  static const int fallbackBhm = 440000;

  /// Naqd chegarasi = BHM × shu ko'paytma (qonunda 400).
  static const int multiplier = 400;

  /// Keshdagi qiymat shu muddatdan eski bo'lsa qayta so'raladi.
  static const Duration refreshInterval = Duration(hours: 24);

  /// So'rov timeouti — fonda ketadi, kassirni kutdirmaydi.
  static const Duration requestTimeout = Duration(seconds: 10);

  /// Alice'dagi sun'iy yozuv uchun status: javob umuman kelmadi.
  /// 599 — "Network Connect Timeout Error" (norasmiy, lekin keng tarqalgan);
  /// haqiqiy server kodlari bilan aralashmaydi va Alice'da qizil ko'rinadi.
  static const int noResponseStatus = 599;

  /// Test uchun almashtiriladigan HTTP so'rov.
  static Future<http.Response> Function(Uri uri) request = _defaultRequest;

  /// Test uchun almashtiriladigan soat.
  static DateTime Function() now = DateTime.now;

  static Future<http.Response> _defaultRequest(Uri uri) =>
      http.get(uri, headers: const {'accept': '*/*'}).timeout(requestTimeout);

  /// Bir vaqtda ikki so'rov ketmasin (startup va smena ochilishi ustma-ust
  /// tushishi mumkin) — ikkinchisi birinchisining natijasini kutadi.
  static Future<bool>? _inFlight;

  /// Joriy BHM (so'm): keshdan, u bo'lmasa [fallbackBhm].
  static int get bhm {
    final cached = Pref.getInt(PrefKeys.bhmAmount, 0);
    return cached > 0 ? cached : fallbackBhm;
  }

  /// Naqd to'lov chegarasi (so'm) = [bhm] × [multiplier].
  static double get cashLimit => (bhm * multiplier).toDouble();

  /// Keshda API'dan olingan qiymat bormi.
  static bool get hasCached => Pref.getInt(PrefKeys.bhmAmount, 0) > 0;

  /// Oxirgi muvaffaqiyatli so'rov vaqti; hech qachon olinmagan bo'lsa null.
  static DateTime? get fetchedAt {
    final ms = Pref.getInt(PrefKeys.bhmFetchedAt, 0);
    return ms > 0 ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  /// Kesh yo'q yoki [refreshInterval] dan eski.
  static bool get isStale {
    final at = fetchedAt;
    if (at == null) return true;
    return now().difference(at) >= refreshInterval;
  }

  /// Kesh eskirgan bo'lsagina API'ga boradi. Qaytaradi: kesh yangilandimi.
  static Future<bool> refreshIfStale({required String reason}) {
    if (!isStale) return Future.value(false);
    return refresh(reason: reason);
  }

  /// API'dan BHM olib keshga yozadi.
  ///
  /// Har qanday xatoda kesh O'ZGARMAYDI va `false` qaytadi — chaqiruvchi
  /// tomonga exception chiqmaydi, chunki bu fon amali va uning yiqilishi
  /// smena ochilishi yoki startup'ni to'xtatmasligi kerak.
  static Future<bool> refresh({required String reason}) {
    final running = _inFlight;
    if (running != null) return running;
    final f = _refresh(reason).whenComplete(() => _inFlight = null);
    _inFlight = f;
    return f;
  }

  static Future<bool> _refresh(String reason) async {
    final stir = Pref.getString(PrefKeys.organizationINN, '').trim();
    final uri = Uri.parse('$endpoint$stir');
    if (stir.isEmpty) {
      // Tashkilotda `tax_payer_id` bo'sh — so'rov yuborib bo'lmaydi.
      // Alice'da ham ko'rinsin, aks holda "nega so'ramadi" degan savol
      // tashqaridan javobsiz qoladi.
      _toAlice(http.Response(
        'BHM ($reason): tashkilot STIR\'i (tax_payer_id) bo\'sh, so\'rov yuborilmadi. '
        'Fallback: $fallbackBhm × $multiplier = ${fallbackBhm * multiplier}',
        noResponseStatus,
        request: http.Request('GET', uri),
      ));
      await _log(LogLevel.warn, 'BHM ($reason): STIR yo\'q, so\'rov yuborilmadi');
      return false;
    }
    try {
      final res = await request(uri);
      _toAlice(res);
      if (res.statusCode != 200) {
        await _log(LogLevel.warn, 'BHM ($reason): HTTP ${res.statusCode}');
        return false;
      }
      final amount = parseAmount(jsonDecode(res.body));
      if (amount == null) {
        await _log(LogLevel.warn,
            'BHM ($reason): javobda baseCalculationAmount yo\'q: ${res.body}');
        return false;
      }
      final previous = Pref.getInt(PrefKeys.bhmAmount, 0);
      await Pref.setInt(PrefKeys.bhmAmount, amount);
      await Pref.setInt(PrefKeys.bhmFetchedAt, now().millisecondsSinceEpoch);
      await _log(LogLevel.info,
          'BHM ($reason): $previous → $amount, naqd chegarasi ${amount * multiplier}');
      return true;
    } catch (e) {
      // Javob UMUMAN kelmadi (timeout, ulanish yo'q, DNS). Alice faqat
      // haqiqiy javobni ko'rsata oladi — sun'iy yozuv, tanasida sabab.
      // Status [noResponseStatus]: `http` paketi 100 dan kichik kodni
      // (masalan 0) qabul qilmaydi — `ArgumentError: Invalid status code`.
      _toAlice(http.Response(
        'BHM ($reason): Soliq API javob bermadi\n$e',
        noResponseStatus,
        request: http.Request('GET', uri),
      ));
      await _log(LogLevel.warn, 'BHM ($reason): so\'rov yiqildi: $e');
      return false;
    }
  }

  /// Alice'ga qayd etadi. Alice `request` maydoni bo'sh javobni (testlardagi
  /// sun'iy javob) o'zi o'tkazib yuboradi; boshqa har qanday xato ham asosiy
  /// oqimni to'xtatmasligi kerak.
  static void _toAlice(http.Response res) {
    try {
      alice.onHttpResponse(res);
    } catch (_) {}
  }

  /// API javobidan BHM ni ajratadi. Shakl noto'g'ri bo'lsa null.
  static int? parseAmount(dynamic body) {
    if (body is! Map) return null;
    if (body['success'] == false) return null;
    final raw = body['baseCalculationAmount'];
    if (raw is! num) return null;
    final v = raw.toInt();
    return v > 0 ? v : null;
  }

  /// Keshni tozalaydi (testlar uchun).
  static Future<void> clearCache() async {
    await Pref.removeWithKey(PrefKeys.bhmAmount);
    await Pref.removeWithKey(PrefKeys.bhmFetchedAt);
  }

  static Future<void> _log(LogLevel level, String msg) async {
    try {
      await LogHelper.write(level, msg);
    } catch (_) {
      // Log yozilmasa ham asosiy oqim to'xtamasin.
    }
  }
}
```

#### 6.2. YANGI: `test/bhm_service_test.dart`

```dart
// BhmService — naqd chegarasi (400 × BHM) manbai testlari.
//
// Nega kerak: bu qiymat noto'g'ri bo'lsa kassa yo qonunga zid naqd qabul
// qiladi, yo ruxsat etilgan sotuvda naqdni yopib qo'yadi. Shuning uchun
// fallback, kesh, TTL va xato holatlarida keshning buzilmasligi mixlanadi.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kStir = '200523221';

/// Soliq API'ning 2026-09-10 dagi real javob shakli.
http.Response okResponse(int amount) => http.Response(
      jsonEncode({
        'success': true,
        'reason': "So'rov bajarildi",
        'data': true,
        'percent': 12,
        'cashSaleAllowed': false,
        'fractionalSale': false,
        'baseCalculationAmount': amount,
      }),
      200,
    );

void main() {
  setUpAll(() => setUpPosTestEnv('bhm_service_test', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  late List<Uri> calls;

  setUp(() async {
    calls = [];
    await BhmService.clearCache();
    await Pref.setString(PrefKeys.organizationINN, kStir);
    BhmService.now = DateTime.now;
    BhmService.request = (uri) async {
      calls.add(uri);
      return okResponse(440000);
    };
  });

  group('fallback va kesh', () {
    test('kesh bo\'sh → fallback 440 000, chegara 176 mln', () {
      expect(BhmService.hasCached, isFalse);
      expect(BhmService.bhm, 440000);
      expect(BhmService.cashLimit, 176000000);
    });

    test('keshda qiymat bo\'lsa u ustun', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 500000);
      expect(BhmService.bhm, 500000);
      expect(BhmService.cashLimit, 200000000);
    });

    test('keshda 0 bo\'lsa fallback', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 0);
      expect(BhmService.hasCached, isFalse);
      expect(BhmService.bhm, 440000);
    });
  });

  group('refresh', () {
    test('muvaffaqiyat → kesh va vaqt yoziladi, URL STIR bilan', () async {
      final fixed = DateTime(2026, 9, 10, 12);
      BhmService.now = () => fixed;
      BhmService.request = (uri) async {
        calls.add(uri);
        return okResponse(450000);
      };

      expect(await BhmService.refresh(reason: 'test'), isTrue);
      expect(calls.single.toString(), '${BhmService.endpoint}$kStir');
      expect(BhmService.bhm, 450000);
      expect(BhmService.cashLimit, 180000000);
      expect(BhmService.fetchedAt, fixed);
    });

    test('STIR yo\'q → so\'rov yuborilmaydi', () async {
      await Pref.setString(PrefKeys.organizationINN, '');
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(calls, isEmpty);
      expect(BhmService.hasCached, isFalse);
    });

    test('HTTP 401 → kesh o\'zgarmaydi', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 430000);
      BhmService.request = (_) async => http.Response('{"status":401}', 401);
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.bhm, 430000);
    });

    test('success:false → kesh o\'zgarmaydi', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 430000);
      BhmService.request = (_) async => http.Response(
          jsonEncode({'success': false, 'baseCalculationAmount': 999999}),
          200);
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.bhm, 430000);
    });

    test('JSON buzuq → kesh o\'zgarmaydi', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 430000);
      BhmService.request = (_) async => http.Response('<html>', 200);
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.bhm, 430000);
    });

    test('so\'rov exception tashlasa → false, exception chiqmaydi', () async {
      BhmService.request = (_) async => throw Exception('timeout');
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.hasCached, isFalse);
    });

    test('amount 0 → rad etiladi', () async {
      BhmService.request = (_) async => okResponse(0);
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.hasCached, isFalse);
    });

    test('parallel ikki chaqiruv → bitta so\'rov', () async {
      final results = await Future.wait([
        BhmService.refresh(reason: 'a'),
        BhmService.refresh(reason: 'b'),
      ]);
      expect(results, [true, true]);
      expect(calls.length, 1);
    });
  });

  group('refreshIfStale', () {
    test('kesh yo\'q → so\'raydi', () async {
      expect(await BhmService.refreshIfStale(reason: 'test'), isTrue);
      expect(calls.length, 1);
      expect(BhmService.hasCached, isTrue);
    });

    test('kesh yangi (TTL ichida) → so\'ramaydi', () async {
      final t0 = DateTime(2026, 9, 10, 8);
      BhmService.now = () => t0;
      await BhmService.refresh(reason: 'seed');
      calls.clear();

      BhmService.now = () => t0.add(const Duration(hours: 23));
      expect(await BhmService.refreshIfStale(reason: 'test'), isFalse);
      expect(calls, isEmpty);
    });

    test('kesh TTL dan eski → qayta so\'raydi', () async {
      final t0 = DateTime(2026, 9, 10, 8);
      BhmService.now = () => t0;
      await BhmService.refresh(reason: 'seed');
      calls.clear();

      BhmService.now = () => t0.add(BhmService.refreshInterval);
      expect(await BhmService.refreshIfStale(reason: 'test'), isTrue);
      expect(calls.length, 1);
    });

    test('yangilash yiqilsa eski kesh qoladi, keyingi safar yana urinadi',
        () async {
      final t0 = DateTime(2026, 9, 10, 8);
      BhmService.now = () => t0;
      await BhmService.refresh(reason: 'seed');
      BhmService.now = () => t0.add(const Duration(days: 2));
      BhmService.request = (_) async => throw Exception('offline');

      expect(await BhmService.refreshIfStale(reason: 'test'), isFalse);
      expect(BhmService.bhm, 440000);
      expect(BhmService.fetchedAt, t0);
      expect(BhmService.isStale, isTrue);
    });
  });

  group('parseAmount', () {
    test('to\'g\'ri javob', () {
      expect(
        BhmService.parseAmount(
            {'success': true, 'baseCalculationAmount': 440000}),
        440000,
      );
    });

    test('double ham qabul qilinadi', () {
      expect(BhmService.parseAmount({'baseCalculationAmount': 440000.0}),
          440000);
    });

    test('string rad etiladi', () {
      expect(
          BhmService.parseAmount({'baseCalculationAmount': '440000'}), isNull);
    });

    test('Map emas → null', () {
      expect(BhmService.parseAmount([1, 2]), isNull);
      expect(BhmService.parseAmount(null), isNull);
    });
  });
}
```

#### 6.3. `lib/utils/constants/pref_keys.dart`

Ikkita yangi Pref kaliti (`bhm_amount`, `bhm_fetched_at`).

```diff
diff --git a/lib/utils/constants/pref_keys.dart b/lib/utils/constants/pref_keys.dart
index 1cd90a6..5c868b8 100644
--- a/lib/utils/constants/pref_keys.dart
+++ b/lib/utils/constants/pref_keys.dart
@@ -209,6 +209,13 @@ class PrefKeys {
   /// kalitga qarab tokenlarni tozalab, login sahifasiga qaytaradi.
   static const String apiEnv = 'api_env';
 
+  /// Soliq API'dan olingan BHM (Bazaviy Hisoblash Miqdori, so'm).
+  /// Naqd to'lov chegarasi = BHM × 400. Qarang: `BhmService`.
+  static const String bhmAmount = 'bhm_amount';
+
+  /// [bhmAmount] oxirgi marta qachon olingan (ms since epoch).
+  static const String bhmFetchedAt = 'bhm_fetched_at';
+
 
 
 }
```

#### 6.4. `lib/changes/domain/cart/cash_restriction_rules.dart`

Qattiq `bigTotalLimit` konstantasi olib tashlandi, `bigTotalHidden` ga `required double limit` parametri qo'shildi. Sinf Pref'ga bog'lanmaydi.

```diff
diff --git a/lib/changes/domain/cart/cash_restriction_rules.dart b/lib/changes/domain/cart/cash_restriction_rules.dart
index 91b9a61..878996b 100644
--- a/lib/changes/domain/cart/cash_restriction_rules.dart
+++ b/lib/changes/domain/cart/cash_restriction_rules.dart
@@ -5,7 +5,8 @@
 //   1. FAQAT KARTA — kommunal xizmat MXIK lari (elektr, gaz, suv...)
 //   2. MARKIROVKA — alkogol/tamaki guruhlari (OFD sozlamasiga bog'liq)
 //   3. CASHSALE — katalogdagi `cashsale` bayrog'i: 0 = naqd taqiqlangan,
-//      1 = ruxsat, lekin qator jami 25 mln dan oshsa yana taqiqlanadi
+//      1 = ruxsat, lekin qator jami 400 × BHM dan oshsa yana taqiqlanadi
+//      (chegara `BhmService.cashLimit` dan parametr sifatida keladi)
 //
 // `OrderingProvider4` dan ko'chirildi (Faza 9.3) — tanalar o'zgarmagan.
 // Sozlama bayroqlari parametr sifatida keladi, shuning uchun qoidalar
@@ -18,9 +19,6 @@ import 'package:invan2/utils/constants/mxik_constants.dart';
 class CashRestrictionRules {
   const CashRestrictionRules._();
 
-  /// Naqd 25 mln dan oshgan `cashsale == 1` qator uchun yopiladi.
-  static const double bigTotalLimit = 25000000;
-
   /// Kommunal xizmat kabi faqat karta bilan to'lanadigan MXIK bormi.
   /// QAYD: o'chirilgan qatorlar ham sanaladi (hozirgi xatti-harakat).
   static bool cardOnlyRequired(List<ReceiptModelSoldItem4> rows) {
@@ -76,13 +74,16 @@ class CashRestrictionRules {
     return false;
   }
 
-  /// `cashsale == 1` mahsulotning QATOR jami 25 mln dan oshdimi.
-  /// QAYD: chegara qator bo'yicha — 2 × 20 mln savat jami 40 mln bo'lsa ham
+  /// `cashsale == 1` mahsulotning QATOR jami [limit] dan oshdimi.
+  /// [limit] — 400 × BHM (`BhmService.cashLimit`). Parametr sifatida keladi,
+  /// shunda qoida Pref/tarmoqsiz testlanadi.
+  /// QAYD: chegara qator bo'yicha — 2 × 100 mln savat jami 200 mln bo'lsa ham
   /// bu qoida ishlamaydi (hozirgi xatti-harakat).
   static bool bigTotalHidden(
     List<ReceiptModelSoldItem4> rows, {
     required bool ofdOn,
     required bool cashsaleCheckOn,
+    required double limit,
   }) {
     if (!ofdOn) return false;
     if (!cashsaleCheckOn) return false;
@@ -93,7 +94,7 @@ class CashRestrictionRules {
       final product = ItemsSingleton.getProductById(item.productId);
       if (product == null) continue;
       if ((product.cashsale ?? -1) != 1) continue;
-      if (item.price * item.value > bigTotalLimit) return true;
+      if (item.price * item.value > limit) return true;
     }
     return false;
   }
```

#### 6.5. `lib/changes/providers/ordering_provider_4.dart`

`isBigTotalHidden` getteri `limit: BhmService.cashLimit` uzatadi. Import qo'shildi.

```diff
diff --git a/lib/changes/providers/ordering_provider_4.dart b/lib/changes/providers/ordering_provider_4.dart
index 3a40a9a..73f9e66 100644
--- a/lib/changes/providers/ordering_provider_4.dart
+++ b/lib/changes/providers/ordering_provider_4.dart
@@ -26,6 +26,7 @@ import 'package:invan2/changes/domain/barcode/scanned_product_lookup.dart';
 import 'package:invan2/changes/domain/barcode/tarozi_label.dart';
 import 'package:invan2/changes/domain/barcode/utsenka_qr.dart';
 import 'package:invan2/changes/domain/cart/cash_restriction_rules.dart';
+import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
 import 'package:invan2/changes/services/telegram_notifier.dart';
 import 'package:invan2/changes/domain/cart/deleted_item_recorder.dart';
 import 'package:invan2/changes/domain/cart/row_repricer.dart';
@@ -465,6 +466,7 @@ class OrderingProvider4 extends ChangeNotifier {
         _currentClient.orderedProducts,
         ofdOn: Pref.getBool(PrefKeys.markCheckWithOfd, true),
         cashsaleCheckOn: Pref.getBool('checkProductByCashsale', true),
+        limit: BhmService.cashLimit,
       );
 
   void resetCashRestrictionWarnings() {
```

#### 6.6. `lib/features/home/features/home_orders/order_list/order_list_item.dart`

Savat qatoridagi takroriy qattiq son o'rniga `BhmService.cashLimit`.

```diff
diff --git a/lib/features/home/features/home_orders/order_list/order_list_item.dart b/lib/features/home/features/home_orders/order_list/order_list_item.dart
index a6e92c5..9df7ed8 100644
--- a/lib/features/home/features/home_orders/order_list/order_list_item.dart
+++ b/lib/features/home/features/home_orders/order_list/order_list_item.dart
@@ -1,4 +1,5 @@
 import 'package:flutter/material.dart';
+import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
 import 'package:invan2/features/get_products/singletons/items_singleton.dart';
 import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
 import 'package:invan2/features/home/features/home_orders/order_list/order_list_top.dart';
@@ -47,13 +48,13 @@ class OrderListItem extends StatelessWidget {
     return (product?.cashsale ?? 1) == 0;
   }
 
-  // Shartli taqiq: cashsale==1 va umumiy narx 25mln dan oshgan
+  // Shartli taqiq: cashsale==1 va qator jami 400 × BHM dan oshgan
   bool _isBigTotalRestricted() {
     if (!CashsaleSettingHelper.isEnabled) return false;
     final product = ItemsSingleton.getProductById(orderedProduct.productId);
     if (product == null) return false;
     if ((product.cashsale ?? -1) != 1) return false;
-    return (orderedProduct.price * orderedProduct.value) > 25000000;
+    return (orderedProduct.price * orderedProduct.value) > BhmService.cashLimit;
   }
 
   @override
```

#### 6.7. `lib/changes/dialogs/upd/bloc/upd_bloc.dart`

"To'liq yangilash" dialogining Сервис bosqichida `BhmService.refresh(reason: 'full-update')`. ASOSIY yangilash nuqtasi.

```diff
diff --git a/lib/changes/dialogs/upd/bloc/upd_bloc.dart b/lib/changes/dialogs/upd/bloc/upd_bloc.dart
index ddce746..c3997f0 100644
--- a/lib/changes/dialogs/upd/bloc/upd_bloc.dart
+++ b/lib/changes/dialogs/upd/bloc/upd_bloc.dart
@@ -4,6 +4,7 @@ import 'package:flutter_bloc/flutter_bloc.dart';
 import 'package:hive_flutter/hive_flutter.dart';
 import 'package:invan2/changes/models/organization_model.dart';
 import 'package:invan2/changes/services/api/result_http_model.dart';
+import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
 import 'package:invan2/changes/services/get_items_service.dart';
 import 'package:invan2/changes/services/sync/sync_cursor.dart';
 import 'package:invan2/changes/services/company_app_service.dart';
@@ -115,6 +116,13 @@ class UpdBloc extends Bloc<UpdEvent, UpdState> {
         case APDstatus.service:
           {
             String? v = await _service(emit);
+            // Naqd chegarasi uchun BHM (400 × BHM) ni Soliq API'dan yangilash.
+            // Aynan shu yerda: "Организация" bosqichi STIR'ni Pref'ga yozib
+            // bo'lgan, va to'liq yangilash kassir ataylab bosadigan kam
+            // uchraydigan amal. Natija qatorning belgisiga ta'sir qilmaydi —
+            // BHM kelmasa eski kesh yoki fallback (176 mln) ishlayveradi.
+            // So'rov Alice'da ko'rinadi.
+            await BhmService.refresh(reason: 'full-update');
             List<UpdFailedRepo> r = _changeRepoStatus(i, v);
             emit(UpdLoadingState(repos: r));
           }
```

#### 6.8. `lib/app/wrapper/wrapper.dart`

Startup'da (auth'dan keyin, navbatlar flush'i yonida) `refreshIfStale` — 24 soat TTL bilan xavfsizlik to'ri.

```diff
diff --git a/lib/app/wrapper/wrapper.dart b/lib/app/wrapper/wrapper.dart
index d422ad3..80a0a54 100644
--- a/lib/app/wrapper/wrapper.dart
+++ b/lib/app/wrapper/wrapper.dart
@@ -22,6 +22,7 @@ import 'package:invan2/changes/services/catalog_refresh_notice.dart';
 import 'package:invan2/changes/services/startup_progress.dart';
 import 'package:invan2/changes/services/discount_auto_sync_service.dart';
 import 'package:invan2/changes/services/health/backend_health.dart';
+import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
 import 'package:invan2/changes/services/receipt/refund_upload_queue.dart';
 import 'package:invan2/changes/services/shift/shift_sync_queue.dart';
 import 'package:invan2/utils/helpers/network_error_helper.dart';
@@ -144,6 +145,11 @@ class _WrapperState extends State<Wrapper> {
           /// butunlay boshqa endpointdan boradi.
           unawaited(RefundUploadQueue.flush(reason: 'startup'));
 
+          /// Naqd chegarasi uchun BHM (400 × BHM). Kesh 24 soatdan eski
+          /// bo'lsagina Soliq API'ga boradi; "To'liq yangilash" (Сервис
+          /// bosqichi) ham yangilaydi. Fonda ketadi, startup'ni kutdirmaydi.
+          unawaited(BhmService.refreshIfStale(reason: 'startup'));
+
           // Startup yuklashi davomida "baza yangilanmagan" dialogi
           // chiqmasligi kerak — u yuklanish ekranining ustiga tushib qolardi.
           CatalogRefreshNotice.beginLoad();
```

#### 6.9. `lib/utils/l10n/app_uz.arb`

Ogohlantirish matni raqamsiz (eskirmaydi). Keyin `flutter gen-l10n`.

```diff
diff --git a/lib/utils/l10n/app_uz.arb b/lib/utils/l10n/app_uz.arb
index 7bdf102..c63337f 100644
--- a/lib/utils/l10n/app_uz.arb
+++ b/lib/utils/l10n/app_uz.arb
@@ -260,7 +260,7 @@
   "perecisleniya": "Transferlar",
   "naqd_tolov_mumkin_emas": "Bu mahsulot basketga qo'shilganiga naqd pul orqali to'lab bo'lmaydi",
   "naqd_tolov_taqiq": "Naqd to'lov mumkin emas",
-  "narx_limit_oshdi": "Umumiy narx 25 mln dan oshdi",
+  "narx_limit_oshdi": "Umumiy narx BHMning 400 baravaridan oshdi",
   "notogri_format_qr": "Noto'g'ri formatdagi QR kod skanerlandi",
   "upd_discounts": "Chegirmalar",
   "upd_items": "Mahsulotlar",
```

#### 6.10. `lib/utils/l10n/app_ru.arb`

Xuddi shu, ruscha.

```diff
diff --git a/lib/utils/l10n/app_ru.arb b/lib/utils/l10n/app_ru.arb
index a1bbe31..2b7b956 100644
--- a/lib/utils/l10n/app_ru.arb
+++ b/lib/utils/l10n/app_ru.arb
@@ -609,7 +609,7 @@
   "perecisleniya":"Перечисления",
   "naqd_tolov_mumkin_emas": "Оплата данного товара наличными невозможна",
   "naqd_tolov_taqiq": "Оплата наличными запрещена",
-  "narx_limit_oshdi": "Общая сумма превысила 25 млн",
+  "narx_limit_oshdi": "Общая сумма превысила 400 БРВ",
   "notogri_format_qr": "Отсканирован QR-код неправильного формата",
   "upd_discounts": "Скидки",
   "upd_items": "Товары",
```

#### 6.11. `test/cash_restriction_rules_test.dart`

`bigTotalHidden` guruhiga `limit:` parametri, qiymatlar 176 mln ga.

```diff
diff --git a/test/cash_restriction_rules_test.dart b/test/cash_restriction_rules_test.dart
index 5564f7f..0bc9c6d 100644
--- a/test/cash_restriction_rules_test.dart
+++ b/test/cash_restriction_rules_test.dart
@@ -126,62 +126,71 @@ void main() {
   });
 
   group('bigTotalHidden', () {
-    bool run(double price, {double value = 1, int? cashsale = 1}) {
+    // 400 × 440 000. Qoida chegarani parametr sifatida oladi — manba
+    // (`BhmService`) alohida testlanadi (bhm_service_test.dart).
+    const kLimit = 176000000.0;
+
+    bool run(double price,
+        {double value = 1, int? cashsale = 1, double limit = kLimit}) {
       ItemsSingleton.products = [catalogItem('a', cashsale)];
       return CashRestrictionRules.bigTotalHidden(
         [makeSoldItem(productId: 'a', price: price, value: value)],
         ofdOn: true,
         cashsaleCheckOn: true,
+        limit: limit,
       );
     }
 
-    test('chegara konstantasi 25 mln', () {
-      expect(CashRestrictionRules.bigTotalLimit, 25000000);
-    });
-
     test('chegaradan 1 so\'m yuqori → true', () {
-      expect(run(25000001), isTrue);
+      expect(run(176000001), isTrue);
     });
 
     test('aynan chegara → false (qat\'iy >)', () {
-      expect(run(25000000), isFalse);
+      expect(run(176000000), isFalse);
+    });
+
+    test('chegara parametrdan olinadi — 10 000 bo\'lsa 10 001 → true', () {
+      expect(run(10001, limit: 10000), isTrue);
+      expect(run(10000, limit: 10000), isFalse);
     });
 
     test('narx × miqdor hisoblanadi', () {
-      expect(run(13000000, value: 2), isTrue);
+      expect(run(90000000, value: 2), isTrue);
     });
 
     test('cashsale 0 bu qoidaga kirmaydi', () {
-      expect(run(30000000, cashsale: 0), isFalse);
+      expect(run(180000000, cashsale: 0), isFalse);
     });
 
     test('cashsale null bu qoidaga kirmaydi', () {
-      expect(run(30000000, cashsale: null), isFalse);
+      expect(run(180000000, cashsale: null), isFalse);
     });
 
     test('OFD o\'chiq → false', () {
       ItemsSingleton.products = [catalogItem('a', 1)];
       expect(
         CashRestrictionRules.bigTotalHidden(
-          [makeSoldItem(productId: 'a', price: 30000000)],
+          [makeSoldItem(productId: 'a', price: 180000000)],
           ofdOn: false,
           cashsaleCheckOn: true,
+          limit: kLimit,
         ),
         isFalse,
       );
     });
 
-    test('QAYD: chegara QATOR bo\'yicha — 2 × 20 mln savat jami ishlamaydi',
+    test('QAYD: chegara QATOR bo\'yicha — 2 × 100 mln savat jami ishlamaydi',
         () {
       ItemsSingleton.products = [catalogItem('a', 1), catalogItem('b', 1)];
       expect(
         CashRestrictionRules.bigTotalHidden(
           [
-            makeSoldItem(productId: 'a', price: 20000000),
-            makeSoldItem(productId: 'b', price: 20000000),
+            makeSoldItem(productId: 'a', price: 100000000),
+            makeSoldItem(productId: 'b', price: 100000000),
           ],
           ofdOn: true,
           cashsaleCheckOn: true,
+          limit: kLimit,
         ),
         isFalse,
       );
```

#### 6.12. `test/cash_restriction_test.dart`

Provider testlari 176 mln ga, `BhmService.clearCache()` setUp'da, Pref'dagi BHM chegarani boshqarishi testi.

```diff
diff --git a/test/cash_restriction_test.dart b/test/cash_restriction_test.dart
index 56cd503..a267d94 100644
--- a/test/cash_restriction_test.dart
+++ b/test/cash_restriction_test.dart
@@ -5,11 +5,12 @@
 // katalog. Faza 9 da alohida modulga ko'chiriladi — shuning uchun avval
 // HOZIRGI xatti-harakat to'liq muzlatiladi.
 //
-// Qamrov: har getterning har bir `if` shoxi, chegaraviy qiymatlar (25 mln,
+// Qamrov: har getterning har bir `if` shoxi, chegaraviy qiymatlar (400 × BHM = 176 mln,
 // cashsale 0/1/null), o'chirilgan qatorlar, bo'sh savat va Pref gate'lari.
 import 'package:flutter_test/flutter_test.dart';
 import 'package:invan2/changes/models/product/item_model.dart';
 import 'package:invan2/changes/providers/ordering_provider_4.dart';
+import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
 import 'package:invan2/features/get_products/singletons/items_singleton.dart';
 import 'package:invan2/utils/constants/pref_keys.dart';
 import 'package:invan2/utils/helpers/prefs.dart';
@@ -42,6 +43,8 @@ void main() {
   setUp(() async {
     ItemsSingleton.products = [];
     await enableCashsaleGates();
+    // Kesh bo'sh → fallback 440 000 × 400 = 176 mln.
+    await BhmService.clearCache();
     await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
   });
 
@@ -234,7 +237,7 @@ void main() {
     });
   });
 
-  group('isBigTotalHidden — cashsale == 1 va qator jami > 25 mln', () {
+  group('isBigTotalHidden — cashsale == 1 va qator jami > 400 × BHM (176 mln)', () {
     OrderingProvider4 withRow({
       int? cashsale = 1,
       double price = 5000,
@@ -256,47 +259,54 @@ void main() {
 
     test('markCheckWithOfd o\'chiq bo\'lsa false', () async {
       await Pref.setBool(PrefKeys.markCheckWithOfd, false);
-      expect(withRow(price: 30000000).isBigTotalHidden, isFalse);
+      expect(withRow(price: 180000000).isBigTotalHidden, isFalse);
     });
 
     test('checkProductByCashsale o\'chiq bo\'lsa false', () async {
       await Pref.setBool('checkProductByCashsale', false);
-      expect(withRow(price: 30000000).isBigTotalHidden, isFalse);
+      expect(withRow(price: 180000000).isBigTotalHidden, isFalse);
     });
 
     test('bo\'sh savatda false', () {
       expect(freshProvider().isBigTotalHidden, isFalse);
     });
 
-    test('25 000 001 → true', () {
-      expect(withRow(price: 25000001).isBigTotalHidden, isTrue);
+    test('176 000 001 → true', () {
+      expect(withRow(price: 176000001).isBigTotalHidden, isTrue);
     });
 
-    test('CHEGARA: aynan 25 000 000 → false (qat\'iy >)', () {
-      expect(withRow(price: 25000000).isBigTotalHidden, isFalse);
+    test('CHEGARA: aynan 176 000 000 → false (qat\'iy >)', () {
+      expect(withRow(price: 176000000).isBigTotalHidden, isFalse);
     });
 
-    test('price × value hisoblanadi (10 mln × 3 = 30 mln → true)', () {
-      expect(withRow(price: 10000000, value: 3).isBigTotalHidden, isTrue);
+    test('chegara Pref\'dagi BHM dan hisoblanadi (500 000 × 400 = 200 mln)',
+        () async {
+      await Pref.setInt(PrefKeys.bhmAmount, 500000);
+      expect(withRow(price: 176000001).isBigTotalHidden, isFalse);
+      expect(withRow(price: 200000001).isBigTotalHidden, isTrue);
+    });
+
+    test('price × value hisoblanadi (60 mln × 3 = 180 mln → true)', () {
+      expect(withRow(price: 60000000, value: 3).isBigTotalHidden, isTrue);
     });
 
     test('cashsale == 0 bo\'lsa bu getter false (u qat\'iy taqiqqa tegishli)',
         () {
-      expect(withRow(cashsale: 0, price: 30000000).isBigTotalHidden, isFalse);
+      expect(withRow(cashsale: 0, price: 180000000).isBigTotalHidden, isFalse);
     });
 
     test('cashsale == null bo\'lsa false (-1 default, 1 ga teng emas)', () {
       expect(
-          withRow(cashsale: null, price: 30000000).isBigTotalHidden, isFalse);
+          withRow(cashsale: null, price: 180000000).isBigTotalHidden, isFalse);
     });
 
     test('katalogda topilmasa false', () {
       expect(
-          withRow(inCatalog: false, price: 30000000).isBigTotalHidden, isFalse);
+          withRow(inCatalog: false, price: 180000000).isBigTotalHidden, isFalse);
     });
 
     test('o\'chirilgan qator hisobga olinmaydi', () {
-      expect(withRow(price: 30000000, deleted: true).isBigTotalHidden, isFalse);
+      expect(withRow(price: 180000000, deleted: true).isBigTotalHidden, isFalse);
     });
 
     test('ikkita qatordan biri oshsa true', () {
@@ -307,20 +317,20 @@ void main() {
       final p = freshProvider();
       p.getCurrentClient.orderedProducts
         ..add(makeSoldItem(productId: 'a', price: 1000))
-        ..add(makeSoldItem(productId: 'b', price: 26000000));
+        ..add(makeSoldItem(productId: 'b', price: 177000000));
       expect(p.isBigTotalHidden, isTrue);
     });
 
     test('QAYD: chegara QATOR bo\'yicha, savat jami bo\'yicha emas', () {
-      // 2 × 20 mln = 40 mln, lekin hech bir QATOR 25 mln dan oshmaydi.
+      // 2 × 100 mln = 200 mln, lekin hech bir QATOR 176 mln dan oshmaydi.
       ItemsSingleton.products = [
         productWithCashsale('a', 1),
         productWithCashsale('b', 1),
       ];
       final p = freshProvider();
       p.getCurrentClient.orderedProducts
-        ..add(makeSoldItem(productId: 'a', price: 20000000))
-        ..add(makeSoldItem(productId: 'b', price: 20000000));
+        ..add(makeSoldItem(productId: 'a', price: 100000000))
+        ..add(makeSoldItem(productId: 'b', price: 100000000));
       expect(p.isBigTotalHidden, isFalse);
     });
   });
```

### 7. Tekshirish

```bash
flutter test test/bhm_service_test.dart test/cash_restriction_rules_test.dart test/cash_restriction_test.dart
dart analyze lib/changes/services/cash_limit/bhm_service.dart lib/changes/domain/cart/cash_restriction_rules.dart
curl -s 'https://txkm.soliq.uz/api/txkm-api/ccm-api/info/check/is-vat/<STIR>' -H 'accept: */*'
```
Ilovada: "To'liq yangilash" → Обновить → Sozlamalar → Alice: `txkm.soliq.uz` GET, 200, `baseCalculationAmount`. Jurnal (`request_logs_of_invan_pos.txt`): `BHM (full-update): 0 → 440000, naqd chegarasi 176000000`. Keyin `cashsale == 1` mahsulotdan 176 000 001 so'mlik qator → naqd tugmasi yopiq, 176 000 000 → ochiq.

STIR bo'sh kompaniyada: jurnalda `BHM (full-update): STIR yo'q, so'rov yuborilmadi`, Alice'da 599 yozuv, chegara fallback 176 mln.

### 8. Eslatmalar va ochiq savollar

- **`http` ≥ 1.3:** `http.Response(..., 0)` ArgumentError tashlaydi. Sun'iy Alice yozuvlarida 599 ishlating. Asl loyihadagi `BackendHealth` (backend_health.dart ~406) hali 0 ishlatadi va shu sabab u yozuv Alice'da chiqmaydi — nusxada ham bir xil bo'lsa 599 ga o'zgartiring.
- **Qator vs chek jami:** qonun matni "tovar va xizmatlar uchun to'lovlar" deydi, aniq emas. Hozir qator bo'yicha (2 × 100 mln savat naqdga ochiq). Soliq texnik qo'llanmasi bilan aniqlashtirish kerak.
- **`cashSaleAllowed`** maydoni (API javobida `false` keldi) nimani anglatishi aniqlanmagan. Ishlatilmaydi.
- **STIR bo'sh** (`tax_payer_id: ""`) tashkilotda BHM hech qachon so'ralmaydi, fallback 176 mln ishlaydi. STIR fiskal chekda `ownerTin` sifatida ham ketadi, demak do'konlarda odatda to'ldirilgan.
- **Startup hook** ixtiyoriy: uni olib tashlasangiz faqat "To'liq yangilash" qoladi. Fallback tufayli xavfsiz.
- **BHM o'zgarsa** (yiliga bir-ikki marta): kodga tegish shart emas, keyingi to'liq yangilash yoki startup yangi qiymatni oladi. `fallbackBhm` ni ham yangilab qo'yish foydali, shart emas.

---

# 2-TASK — `is_marking=false`: markirovka dialogi yo'q, fiskalga statik MXIK (1.1.2+125)

> **Commit:** `347813b` (2026-09-11), reliz `f0eefff` 1.1.2+125.
> **Sessiya hujjati:** `docs/sessions/2026-09-11-fiskal-mxik-fallback-markirovkasiz.md`.
> **Manba:** `docs/fiskal-mxik-fallback-port.md` (2026-09-11) — quyida to'liq kiritilgan, sarlavhalar bir daraja pastga tushirilgan.
> **Doimiy qoida (bu loyihada):** `is_marking` (adminka bayrog'i) markirovkalilikning BIRINCHI mezoni. `true` → markirovkali (dialog, KM shart). `false` → markirovkali EMAS: MXIK markirovka ro'yxatida bo'lsa ham savatda dialog chiqmaydi, fiskalga statik `01905012001000000` MXIK + bo'sh barcode ketadi. `null` (bayroq kelmagan) → eski MXIK avto-aniqlash.
> **Holat 2026-09-24:** relizda; Mac'da soxta fiskal modul bilan sotuv + vozvrat tekshirilgan; do'kon (haqiqiy modul) sinovi kutilmoqda.

## `is_marking=false` + markirovka MXIK: port qilish qo'llanmasi

**Manba:** `ayyubxon` branch, ish daraxti `efa4727` (1.1.2+124) ustida, 2026-09-11. Hali kommit qilinmagan.
**Diff bazasi:** `efa4727` → ish daraxti (faqat feature va test fayllari).

Bu hujjat o'zgarishlarni **InVan 1** (yoki shu loyihaning boshqa nusxasi) ga qo'lda ko'chirish uchun yozilgan. Yangi fayllar to'liq, o'zgargan fayllar diff ko'rinishida. InVan 1 da fayl/sinf nomlari boshqacha bo'lsa, 5-bo'limdagi "qayerga qo'yiladi" jadvalidan foydalaning — mantiq o'sha, joyi boshqa.

---

### 1. Nima va nima uchun

Adminkada mahsulotga **markirovka talab qiladigan MXIK** (02202..., 02203... va h.k.) xato kiritilgan, lekin mahsulot **markirovkali emas** (`is_marking=false`, DataMatrix yo'q). Ilgari POS:

- savatda MXIK bo'yicha uni markirovkali deb hisoblab **markirovka dialogini ochardi** — kassirda skanerlaydigan kod yo'q, mahsulot sotilmasdi;
- "Avto markirovkani aniqlash" o'chiq bo'lsa qator oddiy tushardi, lekin fiskal modulga `SPIC=02202..., Label=""` ketib **soliq chekni rad etardi**.

Endi `is_marking` (adminka bayrog'i) markirovkalilikning **birinchi mezoni**:

| `is_marking` | Savat | Fiskal modul (SPIC / Barcode / Label) | `order_pos` (backend) |
|---|---|---|---|
| `true` | markirovka dialogi, KM shart | asl MXIK / asl / KM | o'zgarmagan |
| `false`, MXIK markirovka ro'yxatida | **dialog yo'q**, oddiy qator | **statik MXIK `01905012001000000` / bo'sh / bo'sh** | **o'zgarmagan**: `product_mxik` asl, `product_barcode` asl |
| `false`, oddiy MXIK | oddiy qator | asl / asl / bo'sh | o'zgarmagan |
| `null` (bayroq kelmagan) | eski MXIK avto-aniqlash (sozlama yoqiq bo'lsa dialog) | KM bo'lsa asl; KM bo'lmasa statik | o'zgarmagan |

Markirovka MXIK ro'yxati (mavjud `isMxikMarking`): `02009`, `02201`, `02202`, `02203`–`02208`, `024`.

### 2. Qoida (aniq ta'rif)

**Savat (dialog chiqadimi):**
```
markirovkali = OFD_yoqiq && (
    is_marking == true
 || (is_marking != false && avtoAniqlash_yoqiq && MXIK_royxatda)
)
```
Ya'ni eski formuladan yagona farq: `is_marking == false` bo'lsa MXIK umuman tekshirilmaydi.

**Fiskal body (har item uchun, sotuv va vozvratda bir xil):**
```
agar  is_marking(katalogdan) == false
  &&  MXIK_royxatda(item.mxik)
  &&  item.mark bo'sh                      // KM yo'q
  &&  statikMxik bo'sh emas
unda  SPIC    = statikMxik                 // Pref mxik_code = 01905012001000000
      Barcode = ""
aks holda hech narsa o'zgarmaydi.
Label har doim = item.mark ?? "" (o'zgarmagan).
```

Nega uchta shart:
- **`is_marking=true`** mahsulot haqiqatan markirovkali — KM siz qolsa ham (masalan invoice qatori) uni statik MXIK bilan "oddiy tovar" qilib o'tkazmaymiz (eski xatti-harakat: asl MXIK, bo'sh Label).
- **KM bor** bo'lsa (masalan `null` bayroqli mahsulotda avto-aniqlash ishlab KM skanerlangan) asl MXIK ketishi shart — aks holda KM statik SPIC bilan soliqqa noto'g'ri ro'yxatga olinadi.
- **statik MXIK bo'sh** (Pref yozilmagan chetki holat) — bo'sh SPIC yuborishdan ko'ra asl MXIK ketgani xavfsizroq, modul bo'sh SPIC ni har doim rad etadi.

`is_marking` chek qatorida saqlanmaydi — fiskal body qurilayotganda **katalogdan** (`ItemsSingleton.getProductById`) o'qiladi. Mahsulot katalogda yo'q (o'chirilgan) yoki qidiruv xato bersa → `false` deb olinadi (qaror MXIK + KM bo'yicha). Qidiruv faqat 2-3 shart bajarilganda chaqiriladi (20 000 mahsulot, 60 qator — 48 ms).

### 3. Qanday ishlaydi (oqim)

```
Mahsulot skanerlandi / bosildi
  └─ addProduct / onBarcodeScanned
       └─ MxikRules.isMxikAutoDetectCandidate(product)      ← is_marking != false && MXIK ro'yxatda
            ├─ true  → marking() → MarkingDialog → KM → MarkedRowBuilder (marking=true, mark=KM)
            └─ false → oddiy qator: SoldItemBuilder (marking=false, mark=null, mxik=asl, product_type="")

To'lov
  └─ ReceiptBuilder → ReceiptModel4 → LocalService.sell → ReceiptSingleton4.saleOnOFD
       └─ har qator: FiscalMxikFallback.resolve(isMarkingProduct: katalogdan, mxik, mark, barcode, staticMxik)
            ├─ substituted → classCode=019..., barcode="", LogHelper.write(warn, "FISKAL MXIK FALLBACK ...")
            └─ aks holda  → classCode=e.mxik, barcode=e.barcode
       └─ saleWithOutIncom → FiscalReceiptModel: SPIC=classCode, Barcode=barcode, Label=mark

Backend order_pos ← ReceiptModelSoldItem4.toJson (product_mxik, product_barcode) — TEGILMAYDI
Vozvrat ← o'sha saleOnOFD (isRefund) — bir xil qoida
```

### 4. O'zgarishlar ro'yxati

| Fayl | Nima |
|---|---|
| `lib/changes/domain/marking/fiscal_mxik_fallback.dart` | **YANGI** — sof qoida (`mayNeedFallback`, `needsFallback`, `resolve`) |
| `lib/changes/domain/marking/mxik_rules.dart` | `isMxikAutoDetectCandidate` yangi; `isProductMarkable` uni ishlatadi |
| `lib/changes/providers/ordering_provider_4.dart` | `addProduct` va skaner yo'lidagi `isMarkingByMxik` markaziy predikatga o'tdi; `_isMxikMarking` wrapper o'chirildi |
| `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart` | `saleOnOFD`: `classCode`/`barcode` qoida orqali; `_isMarkingInCatalog` helper; log |
| `test/fiscal_mxik_fallback_test.dart` | **YANGI** — 24 test (sof qoida + `saleOnOFD`) |
| `test/fiscal_mxik_fallback_scenarios_test.dart` | **YANGI** — 20 chetki holat |
| `test/mxik_rules_test.dart`, `sold_item_builder_test.dart`, `marked_row_builder_test.dart`, `invoice_row_builder_test.dart`, `box_row_builder_test.dart`, `marking_flag_ofd_gating_test.dart` | `is_marking=false` holatlari qo'shildi |

Tegilmagan (ataylab): `isMxikMarking` ro'yxati, `CashRestrictionRules` (alkogol naqd cheklovi hamon MXIK bo'yicha), `order_pos` JSON, `get_items_service` dagi Soliq bo'yicha `isMarking=true` sinxroni, vozvrat oqimi.

### 5. Qo'llash tartibi (InVan 1 uchun)

InVan 1 da domen sinflari (`MxikRules`, `SoldItemBuilder`, ...) bo'lmasligi mumkin — mantiq `OrderingProvider` ichida bo'lsa, o'sha joylarga qo'llang:

| Qadam | InVan 2 da qayerda | InVan 1 da nimani qidirish |
|---|---|---|
| 1 | `fiscal_mxik_fallback.dart` yarating | istalgan joy; faqat `isMxikMarking` ga bog'liq |
| 2 | `MxikRules.isProductMarkable` — `is_marking == false` → `false` | "markirovkali deb hisoblash" funksiyasi: `isMarking`, `mxik.startsWith('0220')` tekshiruvlari bor joy. Savat qatorining `marking` bayrog'i, `product_type`, `product_package` ham shu qarordan chiqishi kerak |
| 3 | `addProduct` dagi `isMarkingByMxik` | mahsulot qo'shishda markirovka dialogini ochish sharti (`MarkingDialog`/`marking()` chaqiruvi oldidagi `if`) |
| 4 | skaner yo'li `onBarcodeScanned` dagi `isMarkingByMxik` | shtrix-kod skanerlanganda `marking()` ga yo'naltiruvchi shart |
| 5 | DataMatrix skanida `item.mark = isMarkable(item) ? ... : null` | agar bor bo'lsa — o'sha `isMarkable` 2-qadamdagi funksiyaga tayanadi (alohida o'zgarish shart emas) |
| 6 | `saleOnOFD` — OFD item quruvchi | fiskal body'da `classCode`/`barcode` (yoki `SPIC`/`Barcode`) to'ldiriladigan joy. Sotuv VA vozvrat shu joydan o'tishiga ishonch hosil qiling |
| 7 | testlar | 7-bo'lim ro'yxati bo'yicha |

Statik MXIK: InVan 2 da `Pref.getString(PrefKeys.mxikCode)` (`mxik_code`), `main.dart` har ishga tushishda `'01905012001000000'` yozadi. InVan 1 da mahsulotga default MXIK qo'yadigan joy qanday nomlansa, o'shani ishlating.

### 6. Kod

#### 6.1. YANGI: `lib/changes/domain/marking/fiscal_mxik_fallback.dart`

```dart
// Fiskal modulga ketadigan item uchun MXIK / shtrix-kod fallback qoidasi.
//
// MUAMMO (2026-09-11): adminkada mahsulot markirovkali deb belgilanMAGAN
// (`is_marking=false` — markirovkalilikni aniqlovchi BIRINCHI mezon), lekin
// unga markirovka talab qiladigan MXIK (02202..., 02203... va h.k. —
// `MxikRules.isMxikMarking` ro'yxati) XATO kiritilgan. Mahsulotning o'zida
// markirovka kodi (seriya raqami) yo'q. Bunday qator fiskal modulga
// `SPIC=02202..., Label=""` bo'lib ketsa, soliq uni rad etadi — kassir chekni
// umuman yopa olmaydi.
//
// QOIDA — uch shart BIRGA bajarilsa, FAQAT fiskal body'da:
//   1) `isMarkingProduct == false` — adminkada markirovkali emas
//   2) MXIK markirovka ro'yxatida
//   3) qatorda markirovka kodi (KM) yo'q
// natija:
//   - `classCode` (SPIC) → statik MXIK (`Pref mxikCode`, 01905012001000000)
//   - `barcode`          → bo'sh
// Boshqa hech narsa o'zgarmaydi: backend chek `order_pos` (`product_mxik`,
// `product_barcode`), savat qatori, `product_type`/`product_package` avvalgidek.
//
// Savat tomoni (2026-09-11): `is_marking=false` mahsulotga markirovka dialogi
// ham CHIQMAYDI — `MxikRules.isMxikAutoDetectCandidate`. Shuning uchun bunday
// qator savatga oddiy (KM siz) tushadi va shu qoida bilan fiskalga ketadi.
//
// Nega 3-shart ham kerak: qanday yo'l bilan bo'lmasin qatorda KM bor bo'lsa
// (masalan bayroq `null` mahsulotda avto-aniqlash ishlab KM skanerlangan)
// asl MXIK ketishi shart — aks holda KM statik SPIC bilan ketib, soliqda
// noto'g'ri ro'yxatga olinadi.
//
// Nega 1-shart kerak: `is_marking=true` bo'lsa mahsulot haqiqatan markirovkali;
// KM siz qolgan bo'lsa ham (masalan invoice qatori) uni statik MXIK bilan
// "oddiy tovar" qilib o'tkazib yubormaymiz.
//
// Qoida sotuv va vozvratga BIR XIL qo'llanadi (ikkalasi
// `ReceiptSingleton4.saleOnOFD` orqali o'tadi) — shunda vozvrat sotuv bilan
// mos keladi.
//
// Sof funksiya — Pref/Hive o'qimaydi: `isMarkingProduct` va statik MXIK
// parametr sifatida keladi. Testlar: test/fiscal_mxik_fallback_test.dart

import 'package:invan2/changes/domain/marking/mxik_rules.dart';

/// Fiskal item uchun yakuniy `classCode` (SPIC) va `barcode`.
class FiscalItemCodes {
  const FiscalItemCodes({
    required this.classCode,
    required this.barcode,
    required this.substituted,
  });

  final String classCode;
  final String barcode;

  /// Almashtirish qo'llandimi (log va test uchun).
  final bool substituted;
}

class FiscalMxikFallback {
  const FiscalMxikFallback._();

  /// Qatorda markirovka kodi bormi (bo'sh joy = yo'q).
  static bool hasMark(String? mark) => mark != null && mark.trim().isNotEmpty;

  /// Fallback UMUMAN mumkinmi — `is_marking` ga qaramasdan: MXIK markirovka
  /// ro'yxatida va KM yo'q. Chaqiruvchi katalog qidiruvini (qimmat) faqat shu
  /// `true` bo'lganda qiladi.
  static bool mayNeedFallback({required String mxik, required String? mark}) =>
      MxikRules.isMxikMarking(mxik.trim()) && !hasMark(mark);

  /// Qator fiskal fallback'ga muhtojmi.
  ///
  /// [isMarkingProduct] — katalogdagi mahsulotning `is_marking` bayrog'i
  /// (adminka). Mahsulot katalogda topilmasa chaqiruvchi `false` beradi.
  static bool needsFallback({
    required bool isMarkingProduct,
    required String mxik,
    required String? mark,
  }) =>
      !isMarkingProduct && mayNeedFallback(mxik: mxik, mark: mark);

  /// Fiskal body uchun `classCode`/`barcode` ni hisoblaydi.
  ///
  /// [staticMxik] bo'sh bo'lsa (Pref yozilmagan chetki holat) almashtirish
  /// QILINMAYDI — bo'sh SPIC yuborishdan ko'ra asl MXIK ketgani xavfsizroq
  /// (fiskal modul bo'sh SPIC ni har doim rad etadi).
  static FiscalItemCodes resolve({
    required bool isMarkingProduct,
    required String mxik,
    required String? mark,
    required String barcode,
    required String staticMxik,
  }) {
    final String fallback = staticMxik.trim();
    final bool needs = needsFallback(
      isMarkingProduct: isMarkingProduct,
      mxik: mxik,
      mark: mark,
    );
    if (fallback.isEmpty || !needs) {
      return FiscalItemCodes(
        classCode: mxik,
        barcode: barcode,
        substituted: false,
      );
    }
    return FiscalItemCodes(
      classCode: fallback,
      barcode: '',
      substituted: true,
    );
  }
}
```

InVan 1 da `MxikRules.isMxikMarking` bo'lmasa, uning o'rniga mavjud "MXIK markirovka ro'yxatida" funksiyasini qo'ying (02009, 02201, 02202, 02203–02208, 024).

#### 6.2. `lib/changes/domain/marking/mxik_rules.dart`

```diff
@@ -30,22 +30,40 @@ class MxikRules {
       mxikStr.startsWith('02208') ||
       mxikStr.startsWith('024');
 
+  /// MXIK bo'yicha avto-aniqlash shu mahsulotga qo'llanadimi (sozlamalardan
+  /// qat'i nazar — OFD va "Avto markirovkani aniqlash" ni chaqiruvchi tekshiradi).
+  ///
+  /// `is_marking` (adminka bayrog'i) — markirovkalilikning BIRINCHI mezoni:
+  ///   - `false` — adminka aniq "markirovkali emas" degan. MXIK markirovka
+  ///     ro'yxatida bo'lsa ham (adminkada MXIK xato kiritilgan) mahsulot
+  ///     markirovkali deb HISOBLANMAYDI: markirovka dialogi chiqmaydi, savatga
+  ///     oddiy qator tushadi; fiskalga statik MXIK ketadi (`FiscalMxikFallback`).
+  ///     (2026-09-11, foydalanuvchi talabi)
+  ///   - `null` — bayroq kelmagan: eski xatti-harakat, MXIK bo'yicha aniqlanadi.
+  ///   - `true` — bu yerga kelmaydi (`isProductMarkable` avvalroq true qaytaradi).
+  static bool isMxikAutoDetectCandidate(ItemModel product) =>
+      product.isMarking != false &&
+      isMxikMarking((product.mxikCode ?? '').trim());
+
   /// Mahsulot markirovkali deb hisoblanadimi.
   /// Qoidalar:
   ///   0) Adminkada OFD o'chiq bo'lsa — hech narsa markirovkali emas
   ///   1) `product.isMarking == true` → markirovkali (sozlamadan qat'iy nazar, OFD ON bo'lsa)
-  ///   2) Aks holda "Avto markirovkani aniqlash" sozlamasi yoqilgan bo'lsa
-  ///      va MXIK kod ro'yxatda bo'lsa (`isMxikMarking`) → markirovkali
-  ///   3) "Avto markirovkani aniqlash" o'chirilgan bo'lsa MXIK umuman tekshirilmaydi
+  ///   2) `product.isMarking == false` → markirovkali EMAS (MXIK tekshirilmaydi)
+  ///   3) Aks holda (`null`) "Avto markirovkani aniqlash" sozlamasi yoqilgan
+  ///      bo'lsa va MXIK kod ro'yxatda bo'lsa (`isMxikMarking`) → markirovkali
+  ///   4) "Avto markirovkani aniqlash" o'chirilgan bo'lsa MXIK umuman tekshirilmaydi
   ///
   /// Savat qatorining `marking` bayrog'i ham shu qarorni ishlatadi
   /// (`SoldItemBuilder`) — aks holda OFD o'chiq bo'lsa ham qator markirovka
   /// guruhi bo'lib qolib, qty tahriri bloklanardi.
+  /// `addProduct` va skaner yo'li (`OrderingProvider4`) ham xuddi shu
+  /// [isMxikAutoDetectCandidate] ni ishlatadi — qoida bitta joyda.
   static bool isProductMarkable(ItemModel product) {
     if (!OfdAdminSetting.isEnabled) return false;
     if (product.isMarking ?? false) return true;
     if (!MarkingSettingHelper.isAutoDetectEnabled) return false;
-    return isMxikMarking((product.mxikCode ?? '').trim());
+    return isMxikAutoDetectCandidate(product);
   }
```

Kontekst: `OfdAdminSetting.isEnabled` = `Pref markCheckWithOfd` (adminkadan OFD yoqiqmi), `MarkingSettingHelper.isAutoDetectEnabled` = OFD yoqiq && `Pref sellProductsWithMarking` ("Avto markirovkani aniqlash"). `isProductMarkable` dan `resolveProductType`/`resolveProductPackage` (backend `product_type`/`product_package`) va savat qatorining `marking` bayrog'i chiqadi — shuning uchun `is_marking=false` qatorda ular oddiy tovardagidek bo'sh bo'ladi.

#### 6.3. `lib/changes/providers/ordering_provider_4.dart`

Ikki joy: `addProduct` (mahsulot qo'shish) va `onBarcodeScanned` (skaner). Ikkalasida ham `_isMxikMarking(mxikStr)` → `MxikRules.isMxikAutoDetectCandidate(product)`.

```diff
@@ -370,13 +370,15 @@ class OrderingProvider4 extends ChangeNotifier {
         'isTarozi': isTarozi,
       });
 
-      final mxikStr = (product.mxikCode ?? product.mxikCode ?? '').trim();
       final bool markCheckEnabled =
           Pref.getBool(PrefKeys.markCheckWithOfd, false);
       final bool sellWithMarkingEnabled =
           Pref.getBool(PrefKeys.sellProductsWithMarking, true);
-      final bool isMarkingByMxik =
-          markCheckEnabled && sellWithMarkingEnabled && _isMxikMarking(mxikStr);
+      // `is_marking == false` bo'lsa MXIK ro'yxatda bo'lsa ham markirovka
+      // dialogi chiqmaydi — oddiy mahsulot (qoida: MxikRules).
+      final bool isMarkingByMxik = markCheckEnabled &&
+          sellWithMarkingEnabled &&
+          MxikRules.isMxikAutoDetectCandidate(product);
 
       final isMarking =
           markCheckEnabled && (product.isMarking == true || isMarkingByMxik);
@@ -2940,8 +2942,11 @@ class OrderingProvider4 extends ChangeNotifier {
           Pref.getBool(PrefKeys.markCheckWithOfd, false);
       final bool sellWithMarkingEnabled =
           Pref.getBool(PrefKeys.sellProductsWithMarking, true);
-      final bool isMarkingByMxik =
-          markCheckEnabled && sellWithMarkingEnabled && _isMxikMarking(mxikStr);
+      // `is_marking == false` bo'lsa MXIK ro'yxatda bo'lsa ham markirovka
+      // dialogi chiqmaydi — oddiy mahsulot (qoida: MxikRules).
+      final bool isMarkingByMxik = markCheckEnabled &&
+          sellWithMarkingEnabled &&
+          MxikRules.isMxikAutoDetectCandidate(item);
 
       if (markCheckEnabled && _isAlcoholMxik(mxikStr)) {
         Pref.setBool(PrefKeys.isCashDisableForAlcohol, true);
@@ -3002,8 +3007,6 @@ class OrderingProvider4 extends ChangeNotifier {
     }
   }
 
-  bool _isMxikMarking(String mxikStr) => MxikRules.isMxikMarking(mxikStr);
-
   bool _isAlcoholMxik(String mxikStr) => MxikRules.isAlcoholMxik(mxikStr);
```

InVan 1 da bu shart `if (product.isMarking == true || mxik.startsWith('0220...'))` ko'rinishida bo'lsa, MXIK qismini `product.isMarking != false && <MXIK ro'yxatda>` ga o'zgartiring. Skaner yo'lidagi `mxikStr` alkogol tekshiruvida (`_isAlcoholMxik`) ishlatilgani uchun u yerda qoldi; `addProduct` da endi kerak emas.

#### 6.4. `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart`

`saleOnOFD` — fiskal body'ni (`params.items[]`) yig'adigan yagona joy; sotuv (`pressPaymentButtonOnlyOFD`), vozvrat (`ReturnBloc`) va qayta yuborish (`PreOfdBloc`) shu orqali o'tadi.

```diff
@@ -1,10 +1,12 @@
 
 import 'dart:convert';
 import 'package:flutter/foundation.dart';
+import 'package:invan2/changes/domain/marking/fiscal_mxik_fallback.dart';
 import 'package:invan2/changes/models/discount_model.dart';
 import 'package:invan2/changes/models/ofd/epos_response_model.dart';
 import 'package:invan2/changes/models/product/sale_item_model.dart';
 import 'package:invan2/changes/models/product_discount_model.dart';
+import 'package:invan2/changes/services/log_helper.dart';
 import 'package:invan2/changes/services/payment/click_service.dart';
 import 'package:invan2/changes/services/receipt_api_4.dart';
 import 'package:invan2/features/features.dart';
@@ -216,6 +218,27 @@ class ReceiptSingleton4 {
   }
 
  
+  /// Chek qatori mahsulotining adminka `is_marking` bayrog'i (katalogdan).
+  ///
+  /// Bayroq chek qatorida saqlanmaydi, shuning uchun `ItemsSingleton` dan
+  /// o'qiladi. Faqat fallback UMUMAN mumkin bo'lganda (MXIK markirovka
+  /// ro'yxatida va KM yo'q) qidiriladi — katalog bo'ylab chiziqli qidiruv
+  /// har qator uchun bekorga yurmasin.
+  ///
+  /// Mahsulot katalogda yo'q (o'chirilgan, eski chek vozvrati) yoki qidiruv
+  /// xato bersa — `false`: qaror MXIK va KM bo'yicha qilinadi. Bu yo'l to'lov
+  /// yo'li, shuning uchun hech qachon exception tashlamasligi kerak.
+  static bool _isMarkingInCatalog(ReceiptModelSoldItem4 e) {
+    if (!FiscalMxikFallback.mayNeedFallback(mxik: e.mxik, mark: e.mark)) {
+      return false; // natija baribir ishlatilmaydi — qidiruv shart emas
+    }
+    try {
+      return ItemsSingleton.getProductById(e.productId)?.isMarking ?? false;
+    } catch (_) {
+      return false;
+    }
+  }
+
     static Map<String, dynamic> saleOnOFD(ReceiptModel4 incomingReceipt) {
     ReceiptModel4 receipt = ReceiptApi4.func(incomingReceipt);
 
@@ -288,6 +311,14 @@ class ReceiptSingleton4 {
     String terId = Pref.getString(PrefKeys.terminalID, '');
     double totalPrice = ItemsSingleton.getOfdTotalPrice(receipt.soldItemList);
 
+    // Adminkada markirovkali deb belgilanMAGAN (`is_marking=false`), lekin
+    // MXIK'i markirovka ro'yxatida bo'lgan va KM siz qator → fiskalga statik
+    // MXIK va bo'sh shtrix-kod ketadi (adminkada MXIK xato kiritilgan holat;
+    // aks holda soliq chekni rad etadi). FAQAT fiskal body — `order_pos`
+    // (`product_mxik`, `product_barcode`) va savat qatori o'zgarmaydi. Sotuv va
+    // vozvrat bir xil. Qarang: lib/changes/domain/marking/fiscal_mxik_fallback.dart
+    final String staticMxik = Pref.getString(PrefKeys.mxikCode, '');
+
     // OFD itemlarini avval MODEL sifatida quramiz (toJson keyin). Shunda
     // yuborishdan oldin §10.2.1 balansini tekshirib/tuzatish imkoni bo'ladi.
     final List<SalingItemModel> ofdItems = receipt.soldItemList.map((e) {
@@ -299,13 +330,29 @@ class ReceiptSingleton4 {
       );
       num price = _countPrice(e);
 
+      final FiscalItemCodes codes = FiscalMxikFallback.resolve(
+        isMarkingProduct: _isMarkingInCatalog(e),
+        mxik: e.mxik,
+        mark: e.mark,
+        barcode: e.barcode,
+        staticMxik: staticMxik,
+      );
+      if (codes.substituted) {
+        LogHelper.write(
+          LogLevel.warn,
+          'FISKAL MXIK FALLBACK: "${e.productName}" is_marking=false, '
+          "MXIK=${e.mxik} markirovka ro'yxatida, KM yo'q -> "
+          "SPIC=${codes.classCode}, Barcode='' (adminkada MXIK tekshirilsin)",
+        );
+      }
+
       return SalingItemModel(
         id: e.productId,
         tin: e.commissionTIN,
         label: e.mark ?? '',
         amount: e.value * 1000,
-        barcode: e.barcode,
-        classCode: e.mxik,
+        barcode: codes.barcode,
+        classCode: codes.classCode,
         name: e.productName.replaceAll(' //blok', ''),
         discount: discount,
         ownerType: e.ownerType,
```

`LogHelper.write` — faylga yozadigan, to'liq try/catch ichidagi log. InVan 1 da bo'lmasa oddiy `print` yoki mavjud log xizmati. `ItemsSingleton.getProductById` — xotiradagi katalogdan id bo'yicha (katta-kichik harf farqsiz) qidiruv.

#### 6.5. YANGI: `test/fiscal_mxik_fallback_test.dart`

Sof qoida (15 test) + `saleOnOFD` orqali haqiqiy fiskal body (9 test). Harness (`setUpPosTestEnv`, `kCashierId`, ...) InVan 2 ga xos — InVan 1 da Pref/Hive setup'ini o'zingiznikiga moslang; `expect` lar o'zgarmaydi.

```dart
// Fiskal MXIK fallback — test.
//
// HOLAT (2026-09-11): adminkada mahsulot markirovkali deb belgilanMAGAN
// (`is_marking=false` — birinchi mezon), lekin unga markirovka talab qiladigan
// MXIK (02202... va h.k.) xato kiritilgan; mahsulotda markirovka kodi yo'q.
// Bunday qator fiskal modulga asl MXIK bilan ketsa soliq rad etadi.
//
// KUTILGAN: FAQAT fiskal body'da `classCode` → statik MXIK (019...),
// `barcode` → bo'sh. Backend chek `order_pos` (`product_mxik`) va savat qatori
// o'zgarmaydi. Sotuv va vozvratda bir xil.
//
// Uch shart birga: is_marking=false + MXIK ro'yxatda + KM yo'q.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/marking/fiscal_mxik_fallback.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kStaticMxik = '01905012001000000';
const kSuvMxik = '02202001001000000'; // suv — markirovka ro'yxatida
const kPivoMxik = '02203001001000000'; // pivo — alkogol, ro'yxatda
const kSigaretaMxik = '02400000000000000'; // sigareta — ro'yxatda
const kSharbatMxik = '02009001001000000'; // sharbat — ro'yxatda
const kOddiyMxik = '01234567890123456'; // oddiy tovar
const kBarcode = '4780000000001';
const kMark = '0104780000000001215Ab1cD2eF3g';

/// Katalog mahsuloti IDlari (is_marking bayrog'i katalogdan o'qiladi).
const kSuvXatoId = 'suv-xato'; // is_marking=false, MXIK 02202 (adminka xatosi)
const kSuvHaqiqiyId = 'suv-haqiqiy'; // is_marking=true, MXIK 02202
const kNonId = 'non'; // is_marking=false, oddiy MXIK
const kOchirilganId = 'ochirilgan'; // katalogda YO'Q

ItemModel product(String id, {required bool isMarking, required String mxik}) {
  final m = ItemModel();
  m.id = id;
  m.name = id;
  m.isMarking = isMarking;
  m.mxikCode = mxik;
  m.barcode = [kBarcode];
  return m;
}

ReceiptModelSoldItem4 row({
  required String mxik,
  String? mark,
  String productId = kSuvXatoId,
  String name = 'Suv 1L',
  double price = 5000,
  double value = 1,
}) {
  return ReceiptModelSoldItem4(
    inBox: 0,
    barcode: kBarcode,
    sku: 1001,
    vatPercent: 12,
    vat: (price * 12) / 112,
    mxik: mxik,
    tin: '',
    onlyPrice: price,
    realPrice: price,
    price: price,
    cost: 0,
    vatName: 'НДС 12%',
    createdTime: DateTime.now().millisecondsSinceEpoch,
    value: value,
    productId: productId,
    productName: name,
    sellerId: kCashierId,
    soldBy: kCashierId,
    singleDiscount: 0,
    ownerType: 1,
    mark: mark,
    marking: mark != null,
    packageCode: 'PACK-1',
    packageName: 'dona',
  );
}

ReceiptModel4 receiptWith(List<ReceiptModelSoldItem4> rows,
    {bool isRefund = false}) {
  double total = 0;
  for (final r in rows) {
    total += r.price * r.value;
  }
  final r = ReceiptModel4(
    createdDate: '2026-09-11 10:00:00',
    orderId: 'order-1',
    cashboxId: 'cashbox-1',
    externalId: 'ext-1',
    orderType: isRefund ? 'refund' : 'sale',
    shopId: 'shop-1',
    userId: kUserId,
    discountVat: 0,
    discountID: '',
    newid: '',
    cashierId: kCashierId,
    cashierName: kCashierName,
    date: DateTime.now().millisecondsSinceEpoch,
    isRefund: isRefund,
    totalPrice: total,
    uploaded: false,
    rejected: false,
    clientName: '',
    clientPhone: '',
    clientId: '',
    supplierId: '',
    cashback: 0,
    sdacha: 0,
    returnForCheck: isRefund ? 'ext-0' : '',
    posName: 'Test POS',
    isDonate: false,
  );
  r.soldItemList.addAll(rows);
  r.payment.add(
    ReceiptModelPaymentType4(name: 'CASH', payId: 'cash', value: total),
  );
  return r;
}

List<Map<String, dynamic>> ofdItems(ReceiptModel4 r) {
  final body = ReceiptSingleton4.saleOnOFD(r);
  return (body['params']['items'] as List).cast<Map<String, dynamic>>();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('needsFallback (sof qoida)', () {
    test('is_marking=false + markirovka MXIK + KM yo\'q → kerak', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kSuvMxik, mark: null),
          isTrue);
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kSuvMxik, mark: ''),
          isTrue);
    });

    test('is_marking=TRUE → hech qachon kerak emas (haqiqiy markirovkali)', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: true, mxik: kSuvMxik, mark: null),
          isFalse);
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: true, mxik: kSuvMxik, mark: kMark),
          isFalse);
    });

    test('KM faqat bo\'sh joy → KM yo\'q deb hisoblanadi', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kSuvMxik, mark: '   '),
          isTrue);
    });

    test('is_marking=false, lekin KM skanerlangan → kerak emas', () {
      // "Avto markirovkani aniqlash" haqiqiy markirovkali tovarni ushlagan —
      // asl MXIK ketishi shart.
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kSuvMxik, mark: kMark),
          isFalse);
    });

    test('oddiy MXIK + KM yo\'q → kerak emas', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kOddiyMxik, mark: null),
          isFalse);
    });

    test('statik MXIK ning o\'zi ro\'yxatda emas → kerak emas', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kStaticMxik, mark: null),
          isFalse);
    });

    test('bo\'sh MXIK → kerak emas', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: '', mark: null),
          isFalse);
    });

    test('butun avto-markirovka ro\'yxati qamrab olinadi', () {
      for (final m in [kSuvMxik, kPivoMxik, kSigaretaMxik, kSharbatMxik]) {
        expect(
            FiscalMxikFallback.needsFallback(
                isMarkingProduct: false, mxik: m, mark: null),
            isTrue,
            reason: m);
      }
      for (final p in ['02201', '02204', '02205', '02206', '02207', '02208']) {
        expect(
            FiscalMxikFallback.needsFallback(
                isMarkingProduct: false, mxik: '${p}000000000000', mark: null),
            isTrue,
            reason: p);
      }
    });

    test('MXIK atrofidagi bo\'sh joy e\'tiborga olinmaydi', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: ' $kSuvMxik ', mark: null),
          isTrue);
    });
  });

  group('resolve (sof qoida)', () {
    test('almashtirish: classCode = statik, barcode bo\'sh', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kSuvMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: kStaticMxik,
      );
      expect(c.substituted, isTrue);
      expect(c.classCode, kStaticMxik);
      expect(c.barcode, '');
    });

    test('is_marking=true → hech narsa o\'zgarmaydi', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: true,
        mxik: kSuvMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: kStaticMxik,
      );
      expect(c.substituted, isFalse);
      expect(c.classCode, kSuvMxik);
      expect(c.barcode, kBarcode);
    });

    test('KM bor → hech narsa o\'zgarmaydi', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kSuvMxik,
        mark: kMark,
        barcode: kBarcode,
        staticMxik: kStaticMxik,
      );
      expect(c.substituted, isFalse);
      expect(c.classCode, kSuvMxik);
      expect(c.barcode, kBarcode);
    });

    test('oddiy tovar → hech narsa o\'zgarmaydi', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kOddiyMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: kStaticMxik,
      );
      expect(c.substituted, isFalse);
      expect(c.classCode, kOddiyMxik);
      expect(c.barcode, kBarcode);
    });

    test('statik MXIK bo\'sh (Pref yozilmagan) → xavfsiz: asl MXIK qoladi',
        () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kSuvMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: '  ',
      );
      expect(c.substituted, isFalse);
      expect(c.classCode, kSuvMxik);
      expect(c.barcode, kBarcode);
    });

    test('statik MXIK atrofidagi bo\'sh joy tozalanadi', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kSuvMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: ' $kStaticMxik ',
      );
      expect(c.classCode, kStaticMxik);
    });
  });

  group('saleOnOFD (fiskal body)', () {
    setUpAll(() async {
      await setUpPosTestEnv('fiscal_mxik_fallback_test',
          withEmployee: false);
      await Pref.setString(PrefKeys.mxikCode, kStaticMxik);
    });
    tearDownAll(tearDownPosTestEnv);

    setUp(() {
      // Katalog: `is_marking` shu yerdan o'qiladi.
      ItemsSingleton.products = [
        product(kSuvXatoId, isMarking: false, mxik: kSuvMxik),
        product(kSuvHaqiqiyId, isMarking: true, mxik: kSuvMxik),
        product(kNonId, isMarking: false, mxik: kOddiyMxik),
      ];
    });
    tearDown(() => ItemsSingleton.products = []);

    test(
        'sotuv: is_marking=false + KM siz suv → statik SPIC, bo\'sh Barcode; qolganlar tegilmaydi',
        () {
      final rows = [
        row(mxik: kSuvMxik, productId: kSuvXatoId),
        row(mxik: kSuvMxik, mark: kMark, productId: kSuvHaqiqiyId),
        row(mxik: kOddiyMxik, productId: kNonId, name: 'Non'),
      ];
      final items = ofdItems(receiptWith(rows));

      expect(items.length, 3);

      final xato = items.firstWhere((e) => e['id'] == kSuvXatoId);
      expect(xato['classCode'], kStaticMxik);
      expect(xato['barcode'], '');
      expect(xato['label'], '');

      final haqiqiy = items.firstWhere((e) => e['id'] == kSuvHaqiqiyId);
      expect(haqiqiy['classCode'], kSuvMxik);
      expect(haqiqiy['barcode'], kBarcode);
      expect(haqiqiy['label'], kMark);

      final non = items.firstWhere((e) => e['id'] == kNonId);
      expect(non['classCode'], kOddiyMxik);
      expect(non['barcode'], kBarcode);
      expect(non['label'], '');
    });

    test('is_marking=true + KM yo\'q (masalan invoice qatori) → asl MXIK qoladi',
        () {
      final items =
          ofdItems(receiptWith([row(mxik: kSuvMxik, productId: kSuvHaqiqiyId)]));
      expect(items.single['classCode'], kSuvMxik);
      expect(items.single['barcode'], kBarcode);
    });

    test('is_marking=false, lekin KM skanerlangan (avto-aniqlash) → asl MXIK',
        () {
      final items = ofdItems(
          receiptWith([row(mxik: kSuvMxik, mark: kMark, productId: kSuvXatoId)]));
      expect(items.single['classCode'], kSuvMxik);
      expect(items.single['barcode'], kBarcode);
      expect(items.single['label'], kMark);
    });

    test('mahsulot katalogda yo\'q (o\'chirilgan) → MXIK + KM bo\'yicha almashtiriladi',
        () {
      final items =
          ofdItems(receiptWith([row(mxik: kSuvMxik, productId: kOchirilganId)]));
      expect(items.single['classCode'], kStaticMxik);
      expect(items.single['barcode'], '');
    });

    test('alkogol MXIK, is_marking=false, KM siz → statik SPIC', () {
      ItemsSingleton.products = [
        product('pivo', isMarking: false, mxik: kPivoMxik),
      ];
      final items = ofdItems(
          receiptWith([row(mxik: kPivoMxik, productId: 'pivo', name: 'Pivo')]));
      expect(items.single['classCode'], kStaticMxik);
      expect(items.single['barcode'], '');
    });

    test('vozvrat: sotuv bilan bir xil almashtiriladi', () {
      final rows = [
        row(mxik: kSuvMxik, productId: kSuvXatoId),
        row(mxik: kSuvMxik, mark: kMark, productId: kSuvHaqiqiyId),
      ];
      final body =
          ReceiptSingleton4.saleOnOFD(receiptWith(rows, isRefund: true));
      expect(body['method'], 'refund');
      final items =
          (body['params']['items'] as List).cast<Map<String, dynamic>>();

      final xato = items.firstWhere((e) => e['id'] == kSuvXatoId);
      expect(xato['classCode'], kStaticMxik);
      expect(xato['barcode'], '');

      final haqiqiy = items.firstWhere((e) => e['id'] == kSuvHaqiqiyId);
      expect(haqiqiy['classCode'], kSuvMxik);
      expect(haqiqiy['barcode'], kBarcode);
    });

    test(
        'faqat fiskal: chek qatori va order_pos JSON (product_mxik/product_barcode) o\'zgarmaydi',
        () {
      final r = receiptWith([row(mxik: kSuvMxik, productId: kSuvXatoId)]);
      ofdItems(r);

      final item = r.soldItemList.first;
      expect(item.mxik, kSuvMxik);
      expect(item.barcode, kBarcode);
      expect(item.toJson()['product_mxik'], kSuvMxik);
      expect(item.toJson()['product_barcode'], kBarcode);
    });

    test('narx/summa maydonlariga ta\'sir qilmaydi', () {
      final items = ofdItems(
          receiptWith([row(mxik: kSuvMxik, productId: kSuvXatoId, price: 5000)]));
      expect(items.single['price'], 500000); // tiyinda
      expect(items.single['amount'], 1000);
    });

    test('Pref statik MXIK bo\'sh → asl MXIK ketadi (xavfsiz chetki holat)',
        () async {
      await Pref.setString(PrefKeys.mxikCode, '');
      try {
        final items =
            ofdItems(receiptWith([row(mxik: kSuvMxik, productId: kSuvXatoId)]));
        expect(items.single['classCode'], kSuvMxik);
        expect(items.single['barcode'], kBarcode);
      } finally {
        await Pref.setString(PrefKeys.mxikCode, kStaticMxik);
      }
    });
  });
}
```

#### 6.6. YANGI: `test/fiscal_mxik_fallback_scenarios_test.dart` (20 chetki holat)

To'liq matn InVan 2 repo'sida (433 qator). Holatlar ro'yxati — InVan 1 da ham shular tekshirilishi kerak:

| # | Holat | Kutilgan |
|---|---|---|
| 1 | Blok (box) qatori, `is_marking=false`, MXIK 022 | blok KM saqlanmaydi, `marking=false`, fiskalga statik SPIC, nomdan ` //blok` kesiladi |
| 1 | Blok, `is_marking=true` | KM saqlanadi, asl SPIC, Label=KM |
| 2 | Invoice qatori, `is_marking=false`, MXIK 022 | oddiy qator, statik SPIC, `amount` = qty×1000 |
| 2 | Invoice, `is_marking=true`, KM yo'q | asl SPIC, bo'sh Label (eski xatti-harakat) |
| 3 | DataMatrix to'g'ridan-to'g'ri skan, `is_marking=false` | mahsulot GTIN bo'yicha topiladi, `mark` biriktirilMAYDI |
| 3 | DataMatrix, `is_marking=true` / `null` | `mark` biriktiriladi, kripto qism kesilgan |
| 4 | `is_marking=null`, avto-aniqlash yoqiq, KM skanerlangan | markirovkali, asl SPIC + Label |
| 4 | `is_marking=null`, avto-aniqlash o'chiq | oddiy qator, statik SPIC (null ≠ true) |
| 5 | Katalog bo'sh | xato yo'q, MXIK+KM bo'yicha statik |
| 5 | Katalogda `id=null` mahsulot bor | to'lov yo'li yiqilmaydi (try/catch), statik |
| 5 | Oddiy MXIK qatorda buzilgan katalog | qidiruv chaqirilmaydi, asl SPIC |
| 5 | `productId` katta-kichik harf farqi | topiladi |
| 6 | Sotuvda `false`, keyin adminka `true` qildi, vozvrat | vozvrat ASL MXIK (katalog joriy holatidan) — 8-bo'limga qarang |
| 6 | Sotuv va vozvrat `false` | ikkalasi statik |
| 7 | Alkogol MXIK + `is_marking=false` | statik SPIC, LEKIN `cashHiddenByMarking` hamon `true` (naqd yopiq) |
| 8 | 3 dona oddiy qator | `amount` 3000, `price` tiyinda, statik SPIC |
| 8 | `isDeleted` qator `saleOnOFD` ga kelsa | xato yo'q |
| 8 | `mxik` bo'sh qator | fallback aralashmaydi, SPIC bo'sh (eski) |
| 9 | 20 000 katalog, 60 qator | < 1 s (o'lchandi: 48 ms) |

#### 6.7. Mavjud testlarga qo'shimchalar

```diff
--- a/test/mxik_rules_test.dart
+++ b/test/mxik_rules_test.dart
@@ -155,6 +155,77 @@ void main() {
 
       expect(MxikRules.isProductMarkable(item()), isFalse);
     });
+
+    // 2026-09-11: `is_marking` — birinchi mezon. Adminka aniq `false` degan
+    // bo'lsa MXIK ro'yxatda bo'lsa ham (adminkada MXIK xato) markirovkali emas.
+    test('is_marking = false + MXIK ro\'yxatda -> markirovkali EMAS', () async {
+      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
+      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
+
+      expect(
+        MxikRules.isProductMarkable(
+            item(mxik: '02202001001000000', isMarking: false)),
+        isFalse,
+      );
+      expect(
+        MxikRules.isProductMarkable(
+            item(mxik: '02205000000000000', isMarking: false)),
+        isFalse,
+        reason: 'alkogol MXIK ham',
+      );
+    });
+
+    test('is_marking = null (bayroq kelmagan) + MXIK ro\'yxatda -> markirovkali',
+        () async {
+      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
+      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
+
+      expect(
+        MxikRules.isProductMarkable(
+            item(mxik: '02202001001000000', isMarking: null)),
+        isTrue,
+      );
+    });
+
+    test('is_marking = true, MXIK ro\'yxatda -> markirovkali (o\'zgarmagan)',
+        () async {
+      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
+      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
+
+      expect(
+        MxikRules.isProductMarkable(
+            item(mxik: '02202001001000000', isMarking: true)),
+        isTrue,
+      );
+    });
+  });
+
+  group('isMxikAutoDetectCandidate (sozlamalarsiz sof qoida)', () {
+    test('is_marking = false -> MXIK ro\'yxatda bo\'lsa ham false', () {
+      expect(
+        MxikRules.isMxikAutoDetectCandidate(
+            item(mxik: '02202001001000000', isMarking: false)),
+        isFalse,
+      );
+    });
+
+    test('is_marking = null + MXIK ro\'yxatda -> true', () {
+      expect(
+        MxikRules.isMxikAutoDetectCandidate(item(mxik: '02202001001000000')),
+        isTrue,
+      );
+    });
+
+    test('is_marking = null + MXIK ro\'yxatda emas -> false', () {
+      expect(
+        MxikRules.isMxikAutoDetectCandidate(item(mxik: '01234567890123456')),
+        isFalse,
+      );
+    });
+
+    test('mxikCode null -> false', () {
+      expect(MxikRules.isMxikAutoDetectCandidate(item()), isFalse);
+    });
   });
 
   group('resolveProductType / resolveProductPackage', () {
@@ -163,6 +234,13 @@ void main() {
       await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
     });
 
+    test('is_marking = false + MXIK ro\'yxatda -> bo\'sh type va package', () {
+      final p = item(mxik: '02202001001000000', isMarking: false);
+
+      expect(MxikRules.resolveProductType(p), '');
+      expect(MxikRules.resolveProductPackage(p), '');
+    });
+
     test('markirovkali emas -> bo\'sh type va bo\'sh package', () {
       final p = item(mxik: '99999999999999999');
```

```diff
--- a/test/sold_item_builder_test.dart
+++ b/test/sold_item_builder_test.dart
@@ -99,6 +99,20 @@ void main() {
       expect(r.marking, isFalse);
     });
 
+    // 2026-09-11: adminka `is_marking=false` degan bo'lsa MXIK ro'yxatda
+    // bo'lsa ham oddiy qator (markirovka dialogi ham chiqmaydi).
+    test('is_marking = false + MXIK ro\'yxatda -> marking false, type bo\'sh',
+        () {
+      final r = SoldItemBuilder.build(
+          product(mxik: '02202001001000000', isMarking: false), 5000, 1, false);
+
+      expect(r.marking, isFalse);
+      expect(r.productType, '');
+      expect(r.productPackage, '');
+      expect(r.mxik, '02202001001000000',
+          reason: 'savat qatorida asl MXIK qoladi (order_pos o\'zgarmaydi)');
+    });
+
     test('markirovkali mahsulotga productType va KIZ qo\'yiladi', () {
```

```diff
--- a/test/marked_row_builder_test.dart
+++ b/test/marked_row_builder_test.dart
@@ -21,7 +21,7 @@ const kPlainMxik = '01101001001000000';
 
 ItemModel product({
   String mxik = kMarkingMxik,
-  bool isMarking = false,
+  bool? isMarking, // null = bayroq kelmagan (MXIK bo'yicha avto-aniqlash)
   String unit = 'dona',
@@ -78,6 +78,21 @@ void main() {
       expect(row(p: product(mxik: kPlainMxik)).marking, isFalse);
     });
 
+    // 2026-09-11: `is_marking=false` — MXIK ro'yxatda bo'lsa ham oddiy qator.
+    test('is_marking = false: marking false, mark null, type bo\'sh', () {
+      final r = row(p: product(isMarking: false), mark: 'KM-XYZ');
+      expect(r.marking, isFalse);
+      expect(r.mark, isNull);
+      expect(r.productType, isEmpty);
+      expect(r.productPackage, isEmpty);
+    });
+
+    test('is_marking = true: marking true, mark saqlanadi', () {
+      final r = row(p: product(isMarking: true), mark: 'KM-XYZ');
+      expect(r.marking, isTrue);
+      expect(r.mark, 'KM-XYZ');
+    });
+
     test('OFD o\'chiq bo\'lsa marking false va mark null', () async {
```

DIQQAT: bu testda helper default'i `isMarking = false` edi — yangi qoida bilan u "markirovkali emas" degani. Niyat "MXIK avto-aniqlash" bo'lgani uchun default `null` qilindi. InVan 1 testlarida ham shunday default bo'lsa, xuddi shunday o'zgartiring, aks holda eski testlar yiqiladi.

```diff
--- a/test/invoice_row_builder_test.dart
+++ b/test/invoice_row_builder_test.dart
@@ -43,12 +43,14 @@ ItemModel product({
   String mxik = '01101001001000000',
   String? ownerType = '2',
+  bool? isMarking,
 }) {
   final m = ItemModel();
   m.id = 'suv-id';
   m.name = 'Suv (katalogdan)';
   m.sku = '1001';
   m.mxikCode = mxik;
+  m.isMarking = isMarking;
@@ -184,6 +186,14 @@ void main() {
       expect(r.marking, isTrue);
     });
 
+    // 2026-09-11: `is_marking=false` — MXIK ro'yxatda bo'lsa ham oddiy qator.
+    test('is_marking = false + MXIK ro\'yxatda -> marking false', () {
+      final r = InvoiceRowBuilder.build(invoiceItem(),
+          product(mxik: '02202001001000000', isMarking: false));
+      expect(r.marking, isFalse);
+      expect(r.mxik, '02202001001000000');
+    });
+
```

```diff
--- a/test/box_row_builder_test.dart
+++ b/test/box_row_builder_test.dart
@@ -22,12 +22,14 @@ ItemModel product({
   String? ownerType = '2',
+  bool? isMarking,
 }) {
   final m = ItemModel();
   m.id = 'suv-id';
   m.name = name;
   m.sku = '1001';
   m.mxikCode = mxik;
+  m.isMarking = isMarking;
@@ -84,6 +86,16 @@ void main() {
       expect(row(p: product(mxik: kMarkingMxik), rawMark: 'KM-9').mark, 'KM-9');
     });
 
+    // 2026-09-11: `is_marking=false` — MXIK ro'yxatda bo'lsa ham blok KM
+    // saqlanmaydi (mahsulot markirovkali emas).
+    test('is_marking = false + MXIK ro\'yxatda -> mark null', () {
+      expect(
+        row(p: product(mxik: kMarkingMxik, isMarking: false), rawMark: 'KM-9')
+            .mark,
+        isNull,
+      );
+    });
+
```

```diff
--- a/test/marking_flag_ofd_gating_test.dart
+++ b/test/marking_flag_ofd_gating_test.dart
@@ -14,6 +14,8 @@
 import 'package:flutter_test/flutter_test.dart';
 import 'package:invan2/app_navigation.dart';
+import 'package:invan2/changes/dialogs/alcohol_warning_dialog.dart';
+import 'package:invan2/changes/dialogs/markirovka_dialog.dart';
 import 'package:invan2/changes/models/product/item_model.dart';
@@ -200,6 +202,56 @@ void main() {
     });
   });
 
+  // 2026-09-11: `is_marking=false` — adminka aniq "markirovkali emas" degan.
+  // MXIK 02202 (markirovka ro'yxatida) bo'lsa ham markirovka dialogi
+  // CHIQMAYDI, savatga oddiy qator tushadi (fiskalga esa statik MXIK ketadi —
+  // test/fiscal_mxik_fallback_test.dart).
+  group('OFD YOQIQ, avto-aniqlash YOQIQ, is_marking = false — dialog yo\'q',
+      () {
+    setUp(() async {
+      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
+      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
+    });
+
+    testWidgets('markirovka dialogi chiqmaydi, qator oddiy (marking = false)',
+        (tester) async {
+      final ctx = await appContext(tester);
+      ItemsSingleton.products = [suv(isMarking: false)];
+      final p = freshProvider();
+
+      p.addProduct(
+          value: 1, product: suv(isMarking: false), where: 'test', context: ctx);
+      await settle(tester);
+
+      expect(find.byType(MarkingDialog), findsNothing);
+      expect(cart(p), hasLength(1));
+      expect(cart(p).first.marking, isFalse);
+      expect(cart(p).first.mark, isNull);
+      expect(cart(p).first.mxik, kSuvMxik,
+          reason: 'savat qatorida asl MXIK qoladi — order_pos o\'zgarmaydi');
+    });
+
+    // Alkogol MXIK (02203) + is_marking=false: markirovka dialogi yo'q, lekin
+    // alkogol naqd-cheklov ogohlantirishi hamon MXIK bo'yicha chiqadi
+    // (o'zgarmagan qoida — CashRestrictionRules).
+    testWidgets('alkogol MXIK: MarkingDialog yo\'q, naqd ogohlantirishi bor',
+        (tester) async {
+      final ctx = await appContext(tester);
+      final pivo = suv(isMarking: false, mxik: '02203001001000000');
+      ItemsSingleton.products = [pivo];
+      final p = freshProvider();
+
+      p.addProduct(value: 1, product: pivo, where: 'test', context: ctx);
+      await settle(tester);
+
+      expect(find.byType(MarkingDialog), findsNothing);
+      expect(find.byType(CashPaymentWarningDialog), findsOneWidget);
+      expect(cart(p), hasLength(1));
+      expect(cart(p).first.marking, isFalse);
+      expect(p.isCashPaymentHidden, isTrue,
+          reason: 'naqd cheklovi MXIK bo\'yicha — o\'zgarmagan');
+    });
+  });
```

### 7. Tekshirish

InVan 2 da (2026-09-11):
- `flutter test` — **1155/1155** o'tdi (44 tasi yangi)
- `flutter analyze` — yangi xato/ogohlantirish yo'q

Windows do'kon sinovi (kutilmoqda), OFD yoqiq, "Avto markirovkani aniqlash" yoqiq:
- [ ] Adminkada `is_marking=false`, MXIK `02202...` mahsulot skanerlanadi → markirovka dialogi CHIQMAYDI, oddiy qator, qty tahriri ishlaydi
- [ ] To'lov → Alice'da fiskal so'rov: `SPIC=01905012001000000`, `Barcode=""`, `Label=""` → soliq qabul qiladi
- [ ] O'sha chek `order_pos` da: `product_mxik=02202...`, `product_barcode` asl, `product_type=""`
- [ ] Log faylda `FISKAL MXIK FALLBACK: ...` qatori bor
- [ ] O'sha chekni vozvrat qilish → fiskal so'rovda ham `SPIC=019...` → qabul qilinadi
- [ ] Haqiqiy markirovkali (`is_marking=true`) suv → dialog chiqadi, KM bilan sotiladi, `SPIC` asl, `Label` to'la (regressiya yo'q)
- [ ] Markirovkali tovarni vozvrat qilish — modul qabul qiladimi (8-bo'lim, vozvrat)

### 8. Eslatmalar va ochiq savollar

**Alkogol MXIK xato kiritilgan mahsulot.** Markirovka dialogi chiqmaydi, fiskalga statik MXIK ketadi, LEKIN naqd to'lov cheklovi (`CashRestrictionRules.cashHiddenByMarking`) va alkogol ogohlantirishi hamon `row.mxik` bo'yicha ishlaydi — kassir faqat karta bilan sota oladi. Eski qoida, tegilmadi. Kerak bo'lsa `is_marking=false` da bu cheklovni ham olib tashlash mumkin (alohida qaror).

**`is_marking=null`.** Backend `is_marking` ni har doim yuborsa `null` amalda bo'lmaydi va "Avto markirovkani aniqlash" sozlamasi savatda deyarli ishlamaydi (faqat `true` bayroq dialog ochadi). Bu "is_marking birinchi mezon" talabiga mos.

**`switchMarking` sinxroni.** `get_items_service.dart` (default o'chiq sozlama) Soliq ro'yxati bo'yicha MXIK'i mos mahsulotlarga lokal `isMarking=true` qo'yadi — unda xato MXIK'li mahsulotga dialog yana chiqadi. Tegilmadi.

**Vozvrat (muhim, o'rganilgan).** InVan 2 da vozvrat lokal chekdan emas, **serverdan qayta yuklanadi** (`ReUpdateBloc` → `SearchReceiptService.getReceiptss(orderId)` → `ChecksSingleton.globalToLocall`). Server item modeli (`ItemsGTR`) `marking_names` ni o'qimaydi, `globalToLocall` da `mark:` izohda — **vozvrat qatorida KM hech qachon bo'lmaydi** (bu mendan oldingi holat). Qisman vozvrat `_itemCopyWith` ham `mark` ni ko'chirmaydi. Oqibatlar:

| Holat | Sotuvda fiskalga | Vozvratda fiskalga |
|---|---|---|
| `is_marking=false`, MXIK 022, KM siz | SPIC 019 | SPIC 019 — mos |
| `is_marking=true`, KM bilan | SPIC 022 + Label | SPIC 022, Label bo'sh — eski holat |
| sotuvdan keyin adminka `false`→`true` | SPIC 019 | SPIC 022, Label bo'sh |
| `is_marking=null`, avto-aniqlash bilan KM | SPIC 022 + Label | SPIC 019 — yangi nomuvofiqlik |
| yangilanishdan oldin `false` + KM bilan sotilgan | SPIC 022 + Label | SPIC 019 — faqat eski cheklar |

Fiskal modul vozvrat itemlarini asl sotuv bilan solishtirsa, oxirgi ikki qator rad etiladi (kam uchraydi). Solishtirmasa (hozircha markirovkali vozvratlar ishlayotgani shuni ko'rsatadi) — xavfsiz. Tavsiya: server javobida `items[].marking_names` kelsa, `globalToLocall` da `mark` ni tiklash — vozvratda KM ham ketadi, nomuvofiqlik yo'qoladi. Buning uchun Alice'da bitta vozvrat so'rovi javobini ko'rish kerak. InVan 1 da vozvrat qanday yig'ilishini (lokal chekdanmi, serverdanmi) alohida tekshiring.

**InVan 1 ga xos.** Agar InVan 1 da chek qatori `is_marking` ni saqlasa yoki mahsulot obyekti qatorda bo'lsa, `_isMarkingInCatalog` o'rniga to'g'ridan-to'g'ri o'sha bayroqni bering — katalog qidiruvi shart bo'lmaydi.

---

# 3-TASK — Vozvrat: serverga vozvratning O'Z fiskal URL'i ketadi (1.1.2+126)

> **Commit:** `fa2d395` (2026-09-22), reliz `1b11eca` 1.1.2+126 (2026-09-22, PRO backend'ga yuklangan).
> **Sessiya hujjati:** `docs/sessions/2026-09-22-refund-fiscal-url-to-server.md`.
> **Holat 2026-09-24:** relizda; Mac'da soxta fiskal modul + DEV backend bilan E2E tekshirilgan; do'kon (haqiqiy modul) sinovi kutilmoqda.

## 1. Nima va nima uchun

**Simptom:** adminkada (serverda) vozvrat yozuvining `url` maydonida asl SOTUV chekining QR URL'i turardi. Chop etilgan vozvrat cheki va lokal (ObjectBox) yozuv esa to'g'ri edi — ularda vozvratning o'z URL'i.

**Sabab:** onlayn vozvratda `ReturnBloc` serverga (`POST api/v1/refund_for_pos_new`, `ReceiptApi4.receiptCreateGrouppForRefund`) fiskal moduldan **oldin** yuborardi. O'sha paytda vozvrat modelidagi `url`/`refundInfo` hali sotuvdan nusxalangan edi. Oflayn navbat (`RefundUploadQueue.flush`) esa fiskaldan **keyin** yuborardi — onlayn va oflayn yo'l bir-biriga zid edi.

**Yechim:** tartib **fiskal → ObjectBox + chek chop → server**. Shunda serverga vozvratning o'z `QRCodeURL`i ketadi. Qo'shimcha tuzatishlar: fiskal xato bersa hech narsa saqlanmaydi; fiskal bo'lmagan vozvratda sotuvdan nusxalangan fiskal maydonlar tozalanadi; server rad etsa "Qayta urinish" yo'q.

## 2. Qanday ishlaydi (yangi oqim)

```
ReturnReturnEvent
  → internet yo'q → ReturnNoInternetState (hech narsa chaqirilmaydi)
  → externalId = yangi chek raqami (lokal hisoblagich), uploaded = false
  → 1) FISKAL (_fiscalRefund):
       - OFD o'chiq YOKI sotuv OFDda ro'yxatdan o'tmagan (url/terminalId/fiscalSign/dateTimeOFD yo'q)
           → fiskal chaqirilmaydi; sotuvdan nusxalangan url/refundInfo/terminalId/receiptSeq/
             dateTimeOFD/fiscalSign TOZALANADI (qayta chop etishda va serverda sotuv QR'i chiqmasin)
       - LocalService.sell xato/exception
           → maydonlar tozalanadi, ReturnFailedState, STOP. Hech narsa saqlanmaydi,
             serverga ketmaydi — "Qayta urinish" oqimni boshidan toza boshlaydi
       - OK → modelga vozvratning O'Z url/refundInfo/terminalId/receiptSeq/dateTimeOFD/fiscalSign
  → 2) LOKAL: ReceiptSingleton4.toOBJECTBOX(model, communicatorRECEIPT) — chek chop etiladi
  → 3) SERVER — faqat BackendHealth.isUp bo'lsa: RefundUploadQueue.uploadOne(model)
       - 200 / 201 / 409  → uploaded = true, rejected = false
       - 5xx (server o'lgan) / tarmoq / darvoza (-3) → pending: navbatda qoladi, kassirga xato yo'q
       - 4xx yoki 5xx-u server tirik → rejected = true; ReturnSuccedState(warning) — "Qayta urinish" YO'Q
     server yiqilgani oldindan ma'lum bo'lsa (isUp=false) → upload umuman chaqirilmaydi, navbatda qoladi
  → ReturnSuccedState(warning?)
```

- **Nega server rad etganda `Failed` emas:** fiskal chek allaqachon chiqqan; "Qayta urinish" tugmasi ikkinchi fiskal vozvrat chiqarardi. Chek `rejected` belgilanadi, kassir cheklar ekranidagi "Yangilash" orqali qo'lda yuboradi (oflayn navbatdagi bilan bir xil qoida).
- **Nega fiskal xato bersa hech narsa saqlanmaydi:** yangi tartibda bu holatda na server, na lokal o'zgargan. Saqlansa retry'da qoldiq ikki marta kamayardi. Xavf: modul chekni yozib, javob yo'qolgan bo'lsa retry ikkinchi fiskal vozvrat chiqaradi — sotuvdagi bilan bir xil, qabul qilindi.
- **Server "allaqachon qaytarilgan" deb rad etishi** amalda lokalda to'silgan: `return_page` qoldiqni shu kassadagi va admin paneldagi vozvratlarni hisobga olib chiqaradi, qoldiq 0 bo'lsa mahsulot ro'yxatga chiqmaydi.
- `refund_for_pos_new` body'siga fiskal maydonlar (`terminal_id/receipt_seq/fiscal_sign`) **qo'shilmadi** — backend qabul qilishi noma'lum; maqsad faqat URL edi.

## 3. O'zgarishlar ro'yxati

| Fayl | Tur | Nima |
|---|---|---|
| `lib/changes/services/receipt/refund_upload_queue.dart` | o'zgargan | `uploadOne()` — bitta vozvratni yuborish qoidasi (bloc va `flush` uchun bitta joy); `RefundUploadStatus`/`RefundUploadResult`; `_inFlight` himoyasi (bloc + flush bir vaqtda → bitta POST); `sendRequest`/`persist` in'ektsiyasi, `resetForTest()` |
| `lib/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart` | o'zgargan | Oqim tartibi fiskal → lokal → server; `_fiscalRefund`, `_wasRegisteredOnOfd`, `_clearFiscalFields`, `_FiscalOutcome`; `ReturnBlocDeps` (bog'liqliklar in'ektsiyasi, `ReturnBlocDeps.production()`) |
| `.../return_dialog/bloc/return_state.dart` | o'zgargan | `ReturnSuccedState({String? warning})` |
| `.../return_dialog/return_dialog.dart` | o'zgargan | Muvaffaqiyat ekranida `warning` (qizil matn) ko'rsatiladi |
| `lib/utils/l10n/app_uz.arb`, `app_ru.arb` | o'zgargan | `qaytarish_server_rad_etdi(error)`; keyin `flutter gen-l10n` (`app_localizations*.dart` generatsiya bo'ladi) |
| `test/refund_upload_queue_test.dart` | YANGI | 9 test: 200/201/409 → uploaded; 4xx → rejected; 5xx tirik → rejected; 5xx o'lgan → pending; darvoza → pending; parallel ikki chaqiruv → bitta POST |
| `test/return_bloc_flow_test.dart` | YANGI | 11 test: oqim tartibi va har chetki holat (jadval fayl boshida) |

## 4. Bog'liqliklar (InVan 1 uchun muhim)

- **`RefundUploadQueue` va `BackendHealth`** — 2026-09-02 "BackendHealth oflayn rejim" taskidan (bu hujjatdan TASHQARIDA; `docs/sessions/2026-09-02-backend-health-offline-mode.md`). InVan 1 da bo'lmasa: bu taskning asosiy qismi baribir qo'llanadi — quyidagi "minimal variant"ga qarang.
- `ReceiptSingleton4.toOBJECTBOX`, `LocalService.sell`, `ReceiptSingleton4.getCheckNo`, `CommunicatorRESPONSE`/`Info` (epos_response_model) — InVan 2 da eskidan bor, InVan 1 da nomi boshqa bo'lishi mumkin.
- l10n: `qaytarish_server_rad_etdi(error)` — arb + `flutter gen-l10n`.
- Testlar: `test/support/provider_harness.dart`; `refund_upload_queue_test` `BackendHealth.reset/autoProbe/internetCheck/probeRequest` ga tayanadi.

**Minimal variant (InVan 1 da `RefundUploadQueue`/`BackendHealth` bo'lmasa):** `ReturnBloc._return` ichida tartibni almashtiring — avval `LocalService.sell` (fiskal), muvaffaqiyatda modelga vozvratning `url`/`refundInfo`/pasportini yozing, keyin `toOBJECTBOX`, oxirida `receiptCreateGrouppForRefund`. Server javobi: 200/201/409 → `uploaded=true`; boshqa → `rejected=true` + muvaffaqiyat ekranida ogohlantirish (retry YO'Q). Fiskal xato → `ReturnFailedState`, saqlamang. OFD o'chiq / sotuv OFDda yo'q → `_clearFiscalFields`. `ReturnBlocDeps` in'ektsiyasi faqat testlar uchun — kerak bo'lmasa statik chaqiruvlarni to'g'ridan-to'g'ri yozing.

## 5. Qo'llash tartibi

1. `refund_upload_queue.dart` (6.1): `uploadOne`, `RefundUploadStatus`, `RefundUploadResult`, `_inFlight`, in'ektsiya. `flush` endi `uploadOne` orqali ishlaydi.
2. `return_state.dart` (6.3): `ReturnSuccedState.warning`.
3. `return_bloc.dart` (6.2): butun `_return` oqimi, yordamchi sinflar fayl oxirida.
4. `return_dialog.dart` (6.4): `warning` ko'rsatish.
5. l10n arb (6.5), keyin `flutter gen-l10n`.
6. Testlar (6.6, 6.7).
7. `dart analyze`, `flutter test`. Keyin E2E: onlayn vozvrat → serverdagi vozvrat yozuvida `url` = vozvratning o'z URL'i (`r=` vozvrat seq'i).

## 6. Kod

Diff bazasi: `fa2d395^` → `fa2d395`. `-` qatorlar eski kod, `+` yangi.

### 6.1. `lib/changes/services/receipt/refund_upload_queue.dart`

```diff
diff --git a/lib/changes/services/receipt/refund_upload_queue.dart b/lib/changes/services/receipt/refund_upload_queue.dart
index 71e3927..b4ad9d8 100644
--- a/lib/changes/services/receipt/refund_upload_queue.dart
+++ b/lib/changes/services/receipt/refund_upload_queue.dart
@@ -31,6 +31,33 @@ class RefundUploadQueue {
 
   static bool _inProgress = false;
 
+  /// Ayni paytda serverga ketayotgan cheklar (`externalId`). Onlayn vozvrat
+  /// (`ReturnBloc`) chekni ObjectBox'ga `uploaded=false` bilan yozib, darhol
+  /// o'zi yuboradi; xuddi shu lahzada tarmoq hodisasi `flush` ni ishga
+  /// tushirsa, o'sha chek ikki marta POST bo'lardi. Shu to'plam buni to'sadi.
+  static final Set<String> _inFlight = <String>{};
+
+  /// Serverga so'rov (testda soxtasi qo'yiladi).
+  static Future<HttpResult> Function(ReceiptModel4 refund) sendRequest =
+      ReceiptApi4.receiptCreateGrouppForRefund;
+
+  /// `uploaded`/`rejected` bayroqlarini saqlash (testda soxtasi qo'yiladi).
+  static void Function(ReceiptModel4 refund) persist = _persistDefault;
+
+  static void _persistDefault(ReceiptModel4 refund) {
+    MyObjectbox.saleStore
+        .box<ReceiptModel4>()
+        .put(refund, mode: PutMode.update);
+  }
+
+  /// Testlar uchun: bog'liqliklarni ishlab chiqarish holatiga qaytarish.
+  static void resetForTest() {
+    sendRequest = ReceiptApi4.receiptCreateGrouppForRefund;
+    persist = _persistDefault;
+    _inFlight.clear();
+    _inProgress = false;
+  }
+
   /// Navbatda kutayotgan qaytarishlar soni.
   static int get pendingCount {
     final query = _pendingQuery();
@@ -72,61 +99,113 @@ class RefundUploadQueue {
     if (pending.isEmpty) return;
 
     _inProgress = true;
-    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
     try {
       for (final ReceiptModel4 refund in pending) {
-        final HttpResult res =
-            await ReceiptApi4.receiptCreateGrouppForRefund(refund);
-
-        // 409 — server "bu qaytarish menda bor" dedi, ya'ni muvaffaqiyat.
-        if (res.statusCode == 200 ||
-            res.statusCode == 201 ||
-            res.statusCode == 409) {
-          refund.uploaded = true;
-          refund.rejected = false;
-          box.put(refund, mode: PutMode.update);
-          if (kDebugMode) {
-            debugPrint('RefundUploadQueue: ${refund.externalId} yuborildi '
-                '($reason)');
-          }
-          continue;
-        }
-
-        // Sotuv cheklaridagi bilan bir xil qoida: 5xx bo'lsa serverning
-        // o'zidan so'raymiz — tirik bo'lsa ayb hujjatda, o'lgan bo'lsa
-        // navbatda qoldiramiz.
-        final bool rejected =
-            await BackendHealth.isDocumentRejection(res.statusCode);
-
-        if (!rejected) {
-          // Server yiqilgan yoki tarmoq uzilgan — bu rad etish EMAS.
-          // Chekni navbatda qoldiramiz va butun tsiklni to'xtatamiz:
-          // qolganlari ham xuddi shu xatoga uchraydi.
-          if (kDebugMode) {
-            debugPrint('RefundUploadQueue: to\'xtatildi, server javob '
-                'bermayapti (status ${res.statusCode})');
-          }
-          break;
-        }
-
-        // Server tirik va hujjatni qabul qilmadi — qayta yuborish foydasiz,
-        // chek qo'lda ko'rib chiqilishi kerak.
-        refund.rejected = true;
-        box.put(refund, mode: PutMode.update);
-        LogRepository.addLog(
-          "Qaytarish server tomonidan rad etildi: ${res.getError}",
-          where: "RefundUploadQueue.flush",
-          file: "refund_upload_queue.dart",
-          method: "POST",
-          path: "api/v1/refund_for_pos_new",
-          statusCode: res.statusCode,
-          checkNo: refund.externalId,
-          createdDate: refund.createdDate,
-          success: false,
-        );
+        // Onlayn vozvrat shu lahzada o'zi yuborayotgan chek — tegilmaydi.
+        if (_inFlight.contains(refund.externalId)) continue;
+        final RefundUploadResult result =
+            await uploadOne(refund, reason: reason);
+
+        // Server yiqilgan yoki tarmoq uzilgan — bu rad etish EMAS.
+        // Chekni navbatda qoldiramiz va butun tsiklni to'xtatamiz:
+        // qolganlari ham xuddi shu xatoga uchraydi.
+        if (result.status == RefundUploadStatus.pending) break;
       }
     } finally {
       _inProgress = false;
     }
   }
+
+  /// Bitta qaytarish chekini serverga yuboradi va natijani ObjectBox'ga
+  /// yozadi. `flush` (navbat) va `ReturnBloc` (onlayn vozvrat) ikkalasi shu
+  /// metoddan foydalanadi — qoida bitta joyda:
+  ///
+  /// * 200/201/409 → `uploaded`; 409 — server "bu qaytarish menda bor" dedi.
+  /// * 5xx / tarmoq / darvoza → `pending`; chek navbatda qoladi.
+  /// * 4xx (yoki 5xx-u server tirik) → `rejected`; qayta yuborish foydasiz,
+  ///   kassir cheklar ekranidan qo'lda ko'rib chiqadi.
+  ///
+  /// Chek ObjectBox'da allaqachon saqlangan bo'lishi kerak (`id != 0`).
+  static Future<RefundUploadResult> uploadOne(
+    ReceiptModel4 refund, {
+    required String reason,
+  }) async {
+    final String key = refund.externalId;
+    if (_inFlight.contains(key)) {
+      // Boshqa yo'l (navbat yoki bloc) aynan shu chekni yuborayotgan
+      // bo'lsa ikkinchi POST qilinmaydi. Natijani o'sha yo'l DB'ga yozadi;
+      // bu chaqiruvchi uchun chek hozircha "navbatda".
+      return const RefundUploadResult(RefundUploadStatus.pending);
+    }
+    _inFlight.add(key);
+    try {
+      return await _send(refund, reason: reason);
+    } finally {
+      _inFlight.remove(key);
+    }
+  }
+
+  static Future<RefundUploadResult> _send(
+    ReceiptModel4 refund, {
+    required String reason,
+  }) async {
+    final HttpResult res = await sendRequest(refund);
+
+    if (res.statusCode == 200 ||
+        res.statusCode == 201 ||
+        res.statusCode == 409) {
+      refund.uploaded = true;
+      refund.rejected = false;
+      persist(refund);
+      if (kDebugMode) {
+        debugPrint('RefundUploadQueue: ${refund.externalId} yuborildi '
+            '($reason)');
+      }
+      return const RefundUploadResult(RefundUploadStatus.uploaded);
+    }
+
+    // Sotuv cheklaridagi bilan bir xil qoida: 5xx bo'lsa serverning
+    // o'zidan so'raymiz — tirik bo'lsa ayb hujjatda, o'lgan bo'lsa
+    // navbatda qoldiramiz.
+    final bool rejected =
+        await BackendHealth.isDocumentRejection(res.statusCode);
+
+    if (!rejected) {
+      if (kDebugMode) {
+        debugPrint('RefundUploadQueue: ${refund.externalId} navbatda qoldi, '
+            'server javob bermayapti (status ${res.statusCode}, $reason)');
+      }
+      return RefundUploadResult(RefundUploadStatus.pending,
+          error: res.getError);
+    }
+
+    // Server tirik va hujjatni qabul qilmadi — qayta yuborish foydasiz,
+    // chek qo'lda ko'rib chiqilishi kerak.
+    refund.rejected = true;
+    persist(refund);
+    LogRepository.addLog(
+      "Qaytarish server tomonidan rad etildi: ${res.getError}",
+      where: "RefundUploadQueue.uploadOne ($reason)",
+      file: "refund_upload_queue.dart",
+      method: "POST",
+      path: "api/v1/refund_for_pos_new",
+      statusCode: res.statusCode,
+      checkNo: refund.externalId,
+      createdDate: refund.createdDate,
+      success: false,
+    );
+    return RefundUploadResult(RefundUploadStatus.rejected,
+        error: res.getError);
+  }
+}
+
+enum RefundUploadStatus { uploaded, pending, rejected }
+
+class RefundUploadResult {
+  final RefundUploadStatus status;
+
+  /// Server xabari (`pending`/`rejected` da), kassirga ko'rsatish uchun.
+  final String? error;
+
+  const RefundUploadResult(this.status, {this.error});
 }
```

### 6.2. `lib/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart`

```diff
diff --git a/lib/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart b/lib/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart
index 0adab52..b90459a 100644
--- a/lib/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart
+++ b/lib/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart
@@ -5,13 +5,13 @@ import 'package:internet_connection_checker/internet_connection_checker.dart';
 import 'package:invan2/changes/models/ofd/epos_response_model.dart';
 import 'package:invan2/changes/services/health/backend_health.dart';
 import 'package:invan2/changes/services/local_selling_service.dart';
+import 'package:invan2/changes/services/receipt/refund_upload_queue.dart';
 import 'package:invan2/features/checks/return_page/right/return_dialog/return_dialog.dart';
 import 'package:invan2/features/features.dart';
 import 'package:invan2/utils/util_functions.dart';
 import 'package:invan2/utils/utils.dart';
 
 import '../../../../../../changes/services/api.dart';
-import '../../../../../../changes/services/api/result_http_model.dart';
 import '../../../../../../utils/l10n/app_localizations.dart';
 
 part 'return_event.dart';
@@ -19,14 +19,22 @@ part 'return_event.dart';
 part 'return_state.dart';
 
 class ReturnBloc extends Bloc<ReturnEvent, ReturnState> {
-  ReturnBloc() : super(ReturnInitial()) {
+  /// [deps] — tashqi bog'liqliklar (internet, server holati, fiskal modul,
+  /// ObjectBox, server API). Ishlab chiqarishda `null` qoldiriladi; testda
+  /// soxtasi beriladi — shunda vozvrat oqimining tartibi va holatlari
+  /// tarmoqsiz, fiskal modulsiz va ObjectBox'siz tekshiriladi.
+  ReturnBloc({ReturnBlocDeps? deps})
+      : _deps = deps ?? ReturnBlocDeps.production(),
+        super(ReturnInitial()) {
     on<ReturnReturnEvent>(_return);
   }
 
+  final ReturnBlocDeps _deps;
+
   _return(ReturnReturnEvent event, Emitter<ReturnState> emit) async {
     Log.d(event, name: 'return_bloc');
 
-    bool ofd = Pref.getBool(PrefKeys.withOFD, false);
+    final bool ofd = _deps.withOfd();
 
     final newReceiptModel41 = ReceiptModel4(
       supplierId: event.receiptModel4.supplierId,
@@ -118,128 +126,141 @@ class ReturnBloc extends Bloc<ReturnEvent, ReturnState> {
 
     newReceiptModel41.soldItemList.addAll(event.rightList);
 
-    // Qolgan kod o'zgarmadi...
     emit(ReturnLoadingState(message: ReturnMessage.internet));
 
-    // Internet va SERVER holati endi alohida tekshiriladi.
+    // Internet va SERVER holati alohida tekshiriladi.
     //
     // Internet yo'q bo'lsa qaytarishni umuman bajarib bo'lmaydi: fiskal chek
-    // OFD (soliq) ga yozilishi kerak, u esa internetsiz ishlamaydi — bu
-    // holat o'zgarmadi.
+    // OFD (soliq) ga yozilishi kerak, u esa internetsiz ishlamaydi.
     //
     // Internet BOR, lekin BIZNING server javob bermayotgan bo'lsa —
-    // qaytarish endi lokal bajariladi (fiskal chek chiqadi, ObjectBox'ga
-    // yoziladi), serverga yuborish esa `RefundUploadQueue` navbatiga
-    // qo'yiladi. Ilgari bu holatda qaytarish umuman ishlamasdi: kassir
-    // "internet yo'q" degan xabarni ko'rar, holbuki internet bor edi.
-    final bool internet = await InternetConnectionChecker().hasConnection;
-    final bool serverUp = internet && BackendHealth.isUp;
+    // qaytarish lokal bajariladi (fiskal chek chiqadi, ObjectBox'ga
+    // yoziladi), serverga yuborish esa `RefundUploadQueue` navbatida qoladi.
+    final bool internet = await _deps.hasInternet();
+    final bool serverUp = internet && _deps.isServerUp();
     if (event.isRetry) {
       await Future.delayed(const Duration(milliseconds: 500));
     }
 
-    /// Fiskal qism va lokal saqlash — onlayn va oflayn yo'l uchun bir xil.
-    ///
-    /// [uploaded] `false` bo'lsa chek `RefundUploadQueue` navbatida qoladi
-    /// va server tiklangach avtomatik yuboriladi.
-    Future<void> finishRefund({required bool uploaded}) async {
-      newReceiptModel41.uploaded = uploaded;
-
-      if (ofd) {
-          // Sotuv OFDga ro'yxatdan o'tganligini tekshiramiz:
-          // 1) URL bo'lishi kerak
-          // 2) Fiskal ma'lumotlar (terminalId, fiscalSign, dateTimeOFD) bo'lishi kerak
-          final urlValue = newReceiptModel41.url;
-          final terminalId = newReceiptModel41.terminalId;
-          final fiscalSign = newReceiptModel41.fiscalSign;
-          final dateTimeOFD = newReceiptModel41.dateTimeOFD;
-
-          final bool wasRegisteredOnOfd =
-              (urlValue != null && urlValue.isNotEmpty) &&
-              (terminalId != null && terminalId.isNotEmpty) &&
-              (fiscalSign != null && fiscalSign.isNotEmpty) &&
-              (dateTimeOFD != null &&
-                  dateTimeOFD.isNotEmpty &&
-                  dateTimeOFD != "0");
-
-          if (!wasRegisteredOnOfd) {
-            // OFDda sotuv yo'q — fiskal refund shart emas
-            await ReceiptSingleton4.toOBJECTBOX(newReceiptModel41);
-
-        emit(ReturnSuccedState());
-          } else {
-            await LocalService.sell(
-                    loc: event.loc, receiptData: newReceiptModel41)
-                .then(
-              (CommunicatorRESPONSE response) async {
-                if (!(response.error ?? true) && response.info != null) {
-                  newReceiptModel41.refundInfo =
-                      jsonEncode(response.info?.toJson());
-                  newReceiptModel41.url = response.info?.qrCodeUrl ?? '';
-                  final refundInfoValue = newReceiptModel41.refundInfo;
-                  if (refundInfoValue != null && refundInfoValue.isNotEmpty) {
-                    Info info = Info.fromJson(jsonDecode(refundInfoValue));
-                    newReceiptModel41.terminalId = info.terminalId;
-                    newReceiptModel41.receiptSeq =
-                        int.tryParse(info.receiptSeq ?? "0") ?? 0;
-                    newReceiptModel41.dateTimeOFD = info.dateTime ?? "0";
-                    newReceiptModel41.fiscalSign = info.fiscalSign;
-                  }
-                  await ReceiptSingleton4.toOBJECTBOX(newReceiptModel41,
-                      communicatorRECEIPT: response);
-                  emit(ReturnSuccedState());
-                } else {
-                  await ReceiptSingleton4.toOBJECTBOX(newReceiptModel41);
-                  emit(ReturnFailedState(error: response.paycheck.toString()));
-                }
-              },
-            ).catchError((err) async {
-              await ReceiptSingleton4.toOBJECTBOX(newReceiptModel41);
-              emit(ReturnFailedState(error: err.toString()));
-            });
-          }
-
-          //////////ofd
-      } else {
-        await ReceiptSingleton4.toOBJECTBOX(newReceiptModel41);
-        emit(ReturnSuccedState());
-      }
+    if (!internet) {
+      emit(ReturnNoInternetState());
+      return;
     }
 
-    if (newReceiptModel41.isRefund == true && internet) {
-      emit(ReturnLoadingState(message: ReturnMessage.returnig));
+    emit(ReturnLoadingState(message: ReturnMessage.returnig));
+
+    // Yangi check raqami generate qilib APIga ham, local DBga ham bir xil
+    // yuboramiz. Raqam lokal hisoblagichdan olinadi — serverga bog'liq emas.
+    newReceiptModel41.externalId = await _deps.nextCheckNo();
+    newReceiptModel41.uploaded = false;
 
-      // Yangi check raqami generate qilib APIga ham, local DBga ham bir xil
-      // yuboramiz. Raqam lokal hisoblagichdan olinadi — serverga bog'liq emas.
-      newReceiptModel41.externalId = await ReceiptSingleton4.getCheckNo();
+    // TARTIB: 1) fiskal → 2) ObjectBox + chek chop → 3) server.
+    //
+    // Ilgari server fiskaldan OLDIN chaqirilardi va serverga vozvrat
+    // modelidagi `url` — ya'ni asl SOTUV chekining QR URL'i ketardi.
+    // Endi server fiskal javobidan keyin chaqiriladi, shuning uchun
+    // `refund_for_pos_new` ga vozvratning o'z `QRCodeURL`i boradi. Oflayn
+    // navbat (`RefundUploadQueue`) allaqachon shu tartibda ishlaydi.
+    //
+    // Server "bu chek allaqachon qaytarilgan" deb rad etishi lokalda
+    // to'silgan: return_page qoldiqni shu kassadagi va admin paneldagi
+    // vozvratlarni hisobga olib chiqaradi, qoldiq 0 bo'lsa mahsulot
+    // ro'yxatga chiqmaydi. Shunga qaramay server rad etsa — chek `rejected`
+    // belgilanadi va kassir cheklar ekranidan qo'lda yuboradi (oflayn
+    // navbatdagi bilan bir xil qoida).
+    final _FiscalOutcome fiscal = await _fiscalRefund(
+      newReceiptModel41,
+      ofd: ofd,
+      loc: event.loc,
+    );
 
-      if (!serverUp) {
-        // Server yiqilgani allaqachon ma'lum — so'rov yuborib kassirni
-        // kutdirishning ma'nosi yo'q.
-        await finishRefund(uploaded: false);
-        return;
+    if (fiscal.error != null) {
+      // Fiskal vozvrat bo'lmadi — hali hech narsa (na lokal, na server)
+      // o'zgarmagan, shuning uchun hech narsa saqlanmaydi. Kassir "Qayta
+      // urinish" bossa oqim boshidan toza boshlanadi.
+      //
+      // Eski tartibda (server birinchi) bu holatda chek baribir lokalga
+      // yozilardi, chunki server allaqachon qabul qilgan edi — endi bunga
+      // hojat yo'q; aksincha, saqlash qoldiqni ikki marta kamaytirardi
+      // (retry'da ikkinchi yozuv).
+      emit(ReturnFailedState(error: fiscal.error!));
+      return;
+    }
+
+    await _deps.saveLocal(newReceiptModel41, fiscal.response);
+
+    String? warning;
+    if (serverUp) {
+      final RefundUploadResult upload =
+          await _deps.uploadToServer(newReceiptModel41);
+      if (upload.status == RefundUploadStatus.rejected) {
+        warning = event.loc.qaytarish_server_rad_etdi(upload.error ?? '');
       }
+    }
+    // serverUp == false yoki `pending` → chek navbatda, server tiklangach
+    // avtomatik yuboriladi.
+
+    emit(ReturnSuccedState(warning: warning));
+  }
+
+  /// Fiskal (OFD) vozvrat. Muvaffaqiyatda modelga vozvratning o'z
+  /// `url`/`refundInfo`/fiskal maydonlari yoziladi. Fiskal kerak bo'lmasa yoki
+  /// xato bersa — asl sotuvdan nusxalangan fiskal maydonlar TOZALANADI,
+  /// aks holda qayta chop etishda va serverda sotuv chekining QR'i chiqadi.
+  Future<_FiscalOutcome> _fiscalRefund(
+    ReceiptModel4 refund, {
+    required bool ofd,
+    required AppLocalizations loc,
+  }) async {
+    if (!ofd || !_wasRegisteredOnOfd(refund)) {
+      // OFDda sotuv yo'q — fiskal refund shart emas
+      _clearFiscalFields(refund);
+      return const _FiscalOutcome();
+    }
 
-      HttpResult? refundResponse =
-          await ReceiptApi4.receiptCreateGrouppForRefund(newReceiptModel41);
-
-      if (refundResponse.statusCode == 200) {
-        await finishRefund(uploaded: true);
-      } else if (BackendHealth.isServerFailureStatus(
-          refundResponse.statusCode)) {
-        // Server aynan shu so'rov paytida yiqildi — qaytarish yo'qolmasin,
-        // lokal bajarib navbatga qo'yamiz.
-        await finishRefund(uploaded: false);
-      } else {
-        // Server tirik va so'rovni rad etdi (masalan chek allaqachon
-        // qaytarilgan) — bu haqiqiy xato, yashirmaymiz.
-        emit(ReturnFailedState(error: refundResponse.getError));
+    try {
+      final CommunicatorRESPONSE response =
+          await _deps.fiscalSell(loc, refund);
+      final Info? info = response.info;
+      if ((response.error ?? true) || info == null) {
+        _clearFiscalFields(refund);
+        return _FiscalOutcome(error: response.paycheck.toString());
       }
-    } else {
-      emit(ReturnNoInternetState());
+      refund.refundInfo = jsonEncode(info.toJson());
+      refund.url = info.qrCodeUrl ?? '';
+      refund.terminalId = info.terminalId;
+      refund.receiptSeq = int.tryParse(info.receiptSeq ?? "0") ?? 0;
+      refund.dateTimeOFD = info.dateTime ?? "0";
+      refund.fiscalSign = info.fiscalSign;
+      return _FiscalOutcome(response: response);
+    } catch (err) {
+      _clearFiscalFields(refund);
+      return _FiscalOutcome(error: err.toString());
     }
   }
 
+  /// Sotuv OFDga ro'yxatdan o'tganmi: URL va fiskal ma'lumotlar
+  /// (terminalId, fiscalSign, dateTimeOFD) bo'lishi kerak.
+  static bool _wasRegisteredOnOfd(ReceiptModel4 r) {
+    final urlValue = r.url;
+    final terminalId = r.terminalId;
+    final fiscalSign = r.fiscalSign;
+    final dateTimeOFD = r.dateTimeOFD;
+    return (urlValue != null && urlValue.isNotEmpty) &&
+        (terminalId != null && terminalId.isNotEmpty) &&
+        (fiscalSign != null && fiscalSign.isNotEmpty) &&
+        (dateTimeOFD != null && dateTimeOFD.isNotEmpty && dateTimeOFD != "0");
+  }
+
+  static void _clearFiscalFields(ReceiptModel4 r) {
+    r.url = '';
+    r.refundInfo = null;
+    r.terminalId = null;
+    r.receiptSeq = null;
+    r.dateTimeOFD = null;
+    r.fiscalSign = null;
+  }
+
   double _getRightTotalPrice(List<ReceiptModelSoldItem4> v) {
     double t = 0;
     for (var element in v) {
@@ -249,3 +270,59 @@ class ReturnBloc extends Bloc<ReturnEvent, ReturnState> {
     return t;
   }
 }
+
+/// Fiskal vozvrat natijasi. [response] — muvaffaqiyatli fiskal javob (chek
+/// chop etish uchun), [error] — fiskal xato matni. Ikkalasi ham `null` bo'lsa
+/// fiskal kerak bo'lmagan (OFDsiz sotuv).
+class _FiscalOutcome {
+  final CommunicatorRESPONSE? response;
+  final String? error;
+
+  const _FiscalOutcome({this.response, this.error});
+}
+
+/// [ReturnBloc] tashqi bog'liqliklari. Har biri sof funksiya: ishlab
+/// chiqarishda [ReturnBlocDeps.production] statik xizmatlarga ulaydi, testda
+/// soxtalari beriladi (qarang: test/return_bloc_flow_test.dart).
+class ReturnBlocDeps {
+  final Future<bool> Function() hasInternet;
+  final bool Function() isServerUp;
+  final bool Function() withOfd;
+  final Future<String> Function() nextCheckNo;
+
+  /// Fiskal modulga vozvrat cheki (`LocalService.sell`).
+  final Future<CommunicatorRESPONSE> Function(
+      AppLocalizations loc, ReceiptModel4 refund) fiscalSell;
+
+  /// ObjectBox'ga yozish + chek chop etish (`ReceiptSingleton4.toOBJECTBOX`).
+  final Future<void> Function(ReceiptModel4 refund, CommunicatorRESPONSE? response)
+      saveLocal;
+
+  /// Serverga yuborish (`RefundUploadQueue.uploadOne`).
+  final Future<RefundUploadResult> Function(ReceiptModel4 refund) uploadToServer;
+
+  const ReturnBlocDeps({
+    required this.hasInternet,
+    required this.isServerUp,
+    required this.withOfd,
+    required this.nextCheckNo,
+    required this.fiscalSell,
+    required this.saveLocal,
+    required this.uploadToServer,
+  });
+
+  factory ReturnBlocDeps.production() => ReturnBlocDeps(
+        hasInternet: () => InternetConnectionChecker().hasConnection,
+        isServerUp: () => BackendHealth.isUp,
+        withOfd: () => Pref.getBool(PrefKeys.withOFD, false),
+        nextCheckNo: ReceiptSingleton4.getCheckNo,
+        fiscalSell: (loc, refund) =>
+            LocalService.sell(loc: loc, receiptData: refund),
+        saveLocal: (refund, response) => ReceiptSingleton4.toOBJECTBOX(
+          refund,
+          communicatorRECEIPT: response,
+        ),
+        uploadToServer: (refund) =>
+            RefundUploadQueue.uploadOne(refund, reason: 'return_bloc'),
+      );
+}
```

### 6.3. `.../return_dialog/bloc/return_state.dart`

```diff
diff --git a/lib/features/checks/return_page/right/return_dialog/bloc/return_state.dart b/lib/features/checks/return_page/right/return_dialog/bloc/return_state.dart
index faf235f..83e4f3b 100644
--- a/lib/features/checks/return_page/right/return_dialog/bloc/return_state.dart
+++ b/lib/features/checks/return_page/right/return_dialog/bloc/return_state.dart
@@ -11,7 +11,15 @@ class ReturnLoadingState extends ReturnState {
 
 class ReturnNoInternetState extends ReturnState {}
 
-class ReturnSuccedState extends ReturnState {}
+class ReturnSuccedState extends ReturnState {
+  /// Vozvrat lokal va fiskal jihatdan bajarildi, lekin server uni rad etdi.
+  /// Chek `rejected` belgilangan — cheklar ekranidan qo'lda yuboriladi.
+  /// "Qayta urinish" bu holatda BO'LMASLIGI kerak: fiskal chek allaqachon
+  /// chiqqan, qayta urinish ikkinchi fiskal vozvrat yaratadi.
+  final String? warning;
+
+  ReturnSuccedState({this.warning});
+}
 
 class ReturnFailedState extends ReturnState {
   final String error;
```

### 6.4. `.../return_dialog/return_dialog.dart`

```diff
diff --git a/lib/features/checks/return_page/right/return_dialog/return_dialog.dart b/lib/features/checks/return_page/right/return_dialog/return_dialog.dart
index f9f5cd5..1404d68 100644
--- a/lib/features/checks/return_page/right/return_dialog/return_dialog.dart
+++ b/lib/features/checks/return_page/right/return_dialog/return_dialog.dart
@@ -197,13 +197,30 @@ class ReturnDialog extends StatelessWidget {
                     return Column(
                       children: [
                         Expanded(
-                          child: Align(
-                            alignment: Alignment.center,
-                            child: Text(
-                              loc.qaytarish_muvaffaqiyatli_yakunlandi,
-                              style: MyThemes.txtStyle(
-                                  fontSize: 4,
-                                  color: Theme.of(context).canvasColor),
+                          child: Center(
+                            child: Column(
+                              mainAxisAlignment: MainAxisAlignment.center,
+                              children: [
+                                Text(
+                                  loc.qaytarish_muvaffaqiyatli_yakunlandi,
+                                  textAlign: TextAlign.center,
+                                  style: MyThemes.txtStyle(
+                                      fontSize: 4,
+                                      color: Theme.of(context).canvasColor),
+                                ),
+                                if (state.warning != null) ...[
+                                  SizedBox(height: SizeConfig.v * 2),
+                                  Text(
+                                    state.warning!,
+                                    textAlign: TextAlign.center,
+                                    style: MyThemes.txtStyle(
+                                        fontSize: 3,
+                                        color: Theme.of(context)
+                                            .colorScheme
+                                            .error),
+                                  ),
+                                ],
+                              ],
                             ),
                           ),
                         ),
```

### 6.5. l10n: `lib/utils/l10n/app_uz.arb`, `app_ru.arb` (keyin `flutter gen-l10n`)

```diff
diff --git a/lib/utils/l10n/app_ru.arb b/lib/utils/l10n/app_ru.arb
index 2b7b956..4895a84 100644
--- a/lib/utils/l10n/app_ru.arb
+++ b/lib/utils/l10n/app_ru.arb
@@ -573,6 +573,14 @@
   "bekor_qilish": "Отмена",
   "qaytarish_amalga_oshirilmoqda": "Возвращение...",
   "qaytarish_muvaffaqiyatli_yakunlandi": "Возврат успешно завершен",
+  "qaytarish_server_rad_etdi": "Внимание: сервер не принял возврат ({error}). Чек помечен как «отклонённый» — отправьте повторно через «Обновить» на экране чеков.",
+  "@qaytarish_server_rad_etdi": {
+    "placeholders": {
+      "error": {
+        "type": "String"
+      }
+    }
+  },
   "qaytarish_amalga_oshirilmadi": "Возврата не было",
   "check_qidirilmoqda": "Ищу чек...",
   "belgiga_tegishli_check_topilmadi": "Не найдено чеков, соответствующих символу",
diff --git a/lib/utils/l10n/app_uz.arb b/lib/utils/l10n/app_uz.arb
index c63337f..11f44e5 100644
--- a/lib/utils/l10n/app_uz.arb
+++ b/lib/utils/l10n/app_uz.arb
@@ -224,6 +224,7 @@
   "bekor_qilish": "Bekor qilish",
   "qaytarish_amalga_oshirilmoqda": "Qaytarish amalga oshirilmoqda...",
   "qaytarish_muvaffaqiyatli_yakunlandi": "Qaytarish muvaffaqiyatli yakunlandi",
+  "qaytarish_server_rad_etdi": "Diqqat: server qaytarishni qabul qilmadi ({error}). Chek \"rad etilgan\" deb belgilandi — cheklar ekranidagi \"Yangilash\" orqali qayta yuboring.",
   "qaytarish_amalga_oshirilmadi": "Qaytarish amalga oshirilmadi",
   "check_qidirilmoqda": "Check qidirilmoqda...",
   "belgiga_tegishli_check_topilmadi": "Belgiga tegishli checklar topilmadi",
```

Generatsiya bo'ladigan fayllar (`flutter gen-l10n`): `app_localizations.dart` (abstract `String qaytarish_server_rad_etdi(String error);`), `app_localizations_uz.dart`, `app_localizations_ru.dart`.

### 6.6. YANGI: `test/refund_upload_queue_test.dart`

<details>
<summary>To'liq fayl (174 qator)</summary>

```dart
// RefundUploadQueue.uploadOne — bitta vozvratni serverga yuborish qoidasi.
//
// Nega kerak: onlayn vozvrat (`ReturnBloc`) va oflayn navbat (`flush`)
// endi shu bitta metoddan o'tadi. Qaror og'ir: `rejected` bo'lgan chek
// avtomatik navbatdan chiqadi va faqat kassir qo'lda yuborsagina ketadi.
//
//   200 / 201 / 409          → uploaded  (uploaded=true, rejected=false)
//   4xx                      → rejected  (rejected=true)
//   5xx, server TIRIK        → rejected
//   5xx, server O'LGAN       → pending   (bayroqlar tegilmaydi)
//   -3 (darvoza yopiq)       → pending
//   bir vaqtda ikki chaqiruv → bitta POST, ikkinchisi pending
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/health/backend_health.dart';
import 'package:invan2/changes/services/receipt/refund_upload_queue.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import 'support/provider_harness.dart';

ReceiptModel4 refund({String externalId = 'DN-7'}) => ReceiptModel4(
      createdDate: '2026-09-22 10:00:00',
      orderId: 'order-1',
      cashboxId: 'cashbox-1',
      externalId: externalId,
      orderType: 'refund',
      shopId: 'shop-1',
      userId: kUserId,
      discountVat: 0,
      discountID: '',
      newid: '',
      cashierId: kCashierId,
      cashierName: kCashierName,
      date: DateTime.now().millisecondsSinceEpoch,
      isRefund: true,
      totalPrice: 4000,
      uploaded: false,
      rejected: false,
      clientName: '',
      clientPhone: '',
      clientId: '',
      supplierId: '',
      cashback: 0,
      sdacha: 0,
      returnForCheck: 'DN-6',
      posName: 'Test POS',
      isDonate: false,
      url: 'https://ofd.soliq.uz/check?t=T&r=2&c=1&s=1',
    );

HttpResult http(int code, [String msg = 'msg']) => HttpResult(
      statusCode: code,
      isSuccess: code >= 200 && code < 300,
      result: msg,
      reBytes: '',
    );

void main() {
  setUpAll(() => setUpPosTestEnv('refund_upload_queue', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  late List<ReceiptModel4> persisted;
  late int sent;

  setUp(() {
    BackendHealth.reset();
    BackendHealth.autoProbe = false;
    BackendHealth.internetCheck = () async => true;
    BackendHealth.probeRequest = () async => true; // standart: server tirik
    RefundUploadQueue.resetForTest();
    persisted = [];
    sent = 0;
    RefundUploadQueue.persist = persisted.add;
  });

  tearDown(() {
    RefundUploadQueue.resetForTest();
    BackendHealth.reset();
    BackendHealth.autoProbe = true;
  });

  void answer(int code, [String msg = 'msg']) {
    RefundUploadQueue.sendRequest = (_) async {
      sent++;
      return http(code, msg);
    };
  }

  for (final code in [200, 201, 409]) {
    test('$code → uploaded, bayroqlar saqlanadi', () async {
      answer(code);
      final r = refund();
      final res = await RefundUploadQueue.uploadOne(r, reason: 'test');
      expect(res.status, RefundUploadStatus.uploaded);
      expect(r.uploaded, isTrue);
      expect(r.rejected, isFalse);
      expect(persisted, [r]);
      expect(sent, 1);
    });
  }

  test('4xx → rejected, xabar qaytadi, rejected=true saqlanadi', () async {
    answer(422, 'Order already refunded');
    final r = refund();
    final res = await RefundUploadQueue.uploadOne(r, reason: 'test');
    expect(res.status, RefundUploadStatus.rejected);
    expect(res.error, 'Order already refunded');
    expect(r.rejected, isTrue);
    expect(r.uploaded, isFalse);
    expect(persisted, [r]);
  });

  test('5xx, server tirik → rejected (ayb hujjatda)', () async {
    answer(500, 'boom');
    BackendHealth.probeRequest = () async => true;
    final r = refund();
    final res = await RefundUploadQueue.uploadOne(r, reason: 'test');
    expect(res.status, RefundUploadStatus.rejected);
    expect(r.rejected, isTrue);
  });

  test('5xx, server o\'lgan → pending, bayroqlar tegilmaydi', () async {
    answer(502, 'bad gateway');
    BackendHealth.probeRequest = () async => false;
    final r = refund();
    final res = await RefundUploadQueue.uploadOne(r, reason: 'test');
    expect(res.status, RefundUploadStatus.pending);
    expect(r.rejected, isFalse);
    expect(r.uploaded, isFalse);
    expect(persisted, isEmpty);
  });

  test('darvoza yopiq (-3) → pending', () async {
    answer(BackendHealth.serverDownStatusCode, "Server bilan aloqa yo'q");
    final r = refund();
    final res = await RefundUploadQueue.uploadOne(r, reason: 'test');
    expect(res.status, RefundUploadStatus.pending);
    expect(persisted, isEmpty);
  });

  test('bir vaqtda ikki chaqiruv (bloc + flush) → bitta POST', () async {
    final gate = Completer<void>();
    RefundUploadQueue.sendRequest = (_) async {
      sent++;
      await gate.future; // birinchi so'rov "ketayotgan" paytda
      return http(200);
    };
    final r = refund();
    final first = RefundUploadQueue.uploadOne(r, reason: 'bloc');
    await Future<void>.delayed(Duration.zero);
    final second = await RefundUploadQueue.uploadOne(r, reason: 'flush');
    expect(second.status, RefundUploadStatus.pending,
        reason: 'ikkinchi yo\'l kutmaydi va POST qilmaydi');
    gate.complete();
    final res = await first;
    expect(res.status, RefundUploadStatus.uploaded);
    expect(sent, 1);
    expect(r.uploaded, isTrue);
  });

  test('yuborish tugagach xuddi shu chek yana yuborilishi mumkin', () async {
    answer(500);
    BackendHealth.probeRequest = () async => false;
    final r = refund();
    expect((await RefundUploadQueue.uploadOne(r, reason: 'a')).status,
        RefundUploadStatus.pending);
    answer(200);
    expect((await RefundUploadQueue.uploadOne(r, reason: 'b')).status,
        RefundUploadStatus.uploaded);
    expect(sent, 2);
  });
}
```

</details>

### 6.7. YANGI: `test/return_bloc_flow_test.dart`

<details>
<summary>To'liq fayl (354 qator)</summary>

```dart
// ReturnBloc — vozvrat oqimining TARTIBI va holatlari.
//
// Nega kerak: 2026-09-22 gacha server (`refund_for_pos_new`) fiskal moduldan
// OLDIN chaqirilar va serverga asl SOTUV chekining QR URL'i ketardi. Endi
// tartib: fiskal → ObjectBox → server. Bu test o'sha tartibni va har bir
// chetki holatda bloc nima qilishini mixlaydi — tarmoqsiz, fiskal modulsiz,
// ObjectBox'siz (hammasi `ReturnBlocDeps` orqali soxta).
//
// Holatlar jadvali:
//   1. internet yo'q                         → NoInternet, hech narsa chaqirilmaydi
//   2. fiskal OK, server OK                  → fiskal→save→upload; url = vozvrat URL'i
//   3. fiskal OK, server 4xx (rejected)      → Succeed + warning, save bo'lgan
//   4. fiskal OK, server javob bermadi       → Succeed (warning yo'q), navbatda
//   5. fiskal OK, server yiqilgani ma'lum    → upload chaqirilmaydi, Succeed
//   6. fiskal XATO                           → Failed, save ham, upload ham YO'Q
//   7. fiskal exception                      → Failed, save/upload yo'q
//   8. OFD yoqiq, sotuv OFDda yo'q (pre-check)→ fiskal yo'q, fiskal maydonlar bo'sh
//   9. OFD o'chiq, sotuvda url bor           → fiskal yo'q, url bo'sh (sotuv URL'i ketmaydi)
//  10. vozvrat modeli: isRefund, CASH to'lov, rightList, yangi chek raqami
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/services/receipt/refund_upload_queue.dart';
import 'package:invan2/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart';
import 'package:invan2/features/checks/return_page/right/return_dialog/return_dialog.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/l10n/app_localizations_uz.dart';

import 'support/provider_harness.dart';

const kSaleUrl =
    'https://ofd.soliq.uz/check?t=LG230110020538&r=38001&c=20260922090000&s=111111111111';
const kRefundUrl =
    'https://ofd.soliq.uz/check?t=LG230110020538&r=38002&c=20260922094049&s=513103888474';
const kTerminal = 'LG230110020538';

ReceiptModelSoldItem4 row({
  String productId = 'p1',
  double price = 4000,
  double value = 1,
}) {
  return ReceiptModelSoldItem4(
    inBox: 0,
    barcode: '4780000000001',
    sku: 7105,
    vatPercent: 12,
    vat: (price * 12) / 112,
    mxik: '01234567890123456',
    tin: '',
    onlyPrice: price,
    realPrice: price,
    price: price,
    cost: 0,
    vatName: 'НДС 12%',
    createdTime: DateTime.now().millisecondsSinceEpoch,
    value: value,
    productId: productId,
    productName: 'Test tovar',
    sellerId: kCashierId,
    soldBy: kCashierId,
    singleDiscount: 0,
    ownerType: 1,
    mark: null,
    marking: false,
    packageCode: '1512199',
    packageName: 'dona',
  );
}

/// Asl SOTUV cheki. [registeredOnOfd] — soliqqa yozilgan (url + pasport).
ReceiptModel4 sale({bool registeredOnOfd = true}) {
  final Info pasport = Info(
    qrCodeUrl: kSaleUrl,
    terminalId: kTerminal,
    receiptSeq: '38001',
    dateTime: '20260922090000',
    fiscalSign: '111111111111',
  );
  final r = ReceiptModel4(
    createdDate: '2026-09-22 09:00:00',
    orderId: 'order-1',
    cashboxId: 'cashbox-1',
    externalId: 'DN-100',
    orderType: 'sale',
    shopId: 'shop-1',
    userId: kUserId,
    discountVat: 0,
    discountID: '',
    newid: '',
    cashierId: kCashierId,
    cashierName: kCashierName,
    date: DateTime.now().millisecondsSinceEpoch,
    isRefund: false,
    totalPrice: 8000,
    uploaded: true,
    rejected: false,
    clientName: '',
    clientPhone: '',
    clientId: '',
    supplierId: '',
    cashback: 0,
    sdacha: 0,
    returnForCheck: '',
    posName: 'Test POS',
    isDonate: false,
    refundInfo: registeredOnOfd ? jsonEncode(pasport.toJson()) : null,
    url: registeredOnOfd ? kSaleUrl : '',
    terminalId: registeredOnOfd ? kTerminal : null,
    receiptSeq: registeredOnOfd ? 38001 : null,
    dateTimeOFD: registeredOnOfd ? '20260922090000' : null,
    fiscalSign: registeredOnOfd ? '111111111111' : null,
  );
  r.soldItemList.addAll([row(productId: 'p1', value: 2)]);
  return r;
}

CommunicatorRESPONSE fiscalOk() => CommunicatorRESPONSE(
      error: false,
      paycheck: 'pdf',
      method: 'Api.SendRefundReceipt',
      info: Info(
        qrCodeUrl: kRefundUrl,
        terminalId: kTerminal,
        receiptSeq: '38002',
        dateTime: '20260922094049',
        fiscalSign: '513103888474',
      ),
      itemInfo: const [],
    );

CommunicatorRESPONSE fiscalFail(String msg) => CommunicatorRESPONSE(
      error: true,
      paycheck: msg,
      info: null,
      itemInfo: const [],
    );

/// Soxta bog'liqliklar: chaqiruvlar tartibini va modelning o'sha paytdagi
/// holatini yozib boradi.
class FakeDeps {
  bool internet = true;
  bool serverUp = true;
  bool ofd = true;
  Future<CommunicatorRESPONSE> Function(ReceiptModel4) fiscal =
      (_) async => fiscalOk();
  RefundUploadResult uploadResult =
      const RefundUploadResult(RefundUploadStatus.uploaded);

  final List<String> calls = [];
  ReceiptModel4? saved;
  CommunicatorRESPONSE? savedResponse;
  ReceiptModel4? uploaded;
  String? uploadedUrl; // upload paytidagi url (keyin o'zgarmasin)

  ReturnBlocDeps build() => ReturnBlocDeps(
        hasInternet: () async => internet,
        isServerUp: () => serverUp,
        withOfd: () => ofd,
        nextCheckNo: () async => 'DN-101',
        fiscalSell: (loc, r) {
          calls.add('fiscal');
          return fiscal(r);
        },
        saveLocal: (r, resp) async {
          calls.add('save');
          saved = r;
          savedResponse = resp;
        },
        uploadToServer: (r) async {
          calls.add('upload');
          uploaded = r;
          uploadedUrl = r.url;
          return uploadResult;
        },
      );
}

Future<List<ReturnState>> run(FakeDeps deps, {ReceiptModel4? original}) async {
  final bloc = ReturnBloc(deps: deps.build());
  final states = <ReturnState>[];
  final sub = bloc.stream.listen(states.add);
  final src = original ?? sale();
  bloc.add(ReturnReturnEvent(
    isRetry: false,
    clientNumber: '',
    receiptModel4: src,
    rightList: [row(productId: 'p1', value: 1)],
    loc: AppLocalizationsUz(),
  ));
  // Oqim tugashini kutamiz: oxirgi holat terminal bo'lguncha.
  for (int i = 0; i < 200; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (states.isNotEmpty &&
        (states.last is ReturnSuccedState ||
            states.last is ReturnFailedState ||
            states.last is ReturnNoInternetState)) {
      break;
    }
  }
  await sub.cancel();
  await bloc.close();
  return states;
}

void main() {
  setUpAll(() => setUpPosTestEnv('return_bloc_flow', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    await Pref.setString(PrefKeys.cashId, 'cash-id');
  });

  test('1. internet yo\'q — hech narsa chaqirilmaydi', () async {
    final d = FakeDeps()..internet = false;
    final states = await run(d);
    expect(states.last, isA<ReturnNoInternetState>());
    expect(d.calls, isEmpty);
  });

  test('2. fiskal OK, server OK — tartib fiskal→save→upload, url vozvratniki',
      () async {
    final d = FakeDeps();
    final states = await run(d);

    expect(d.calls, ['fiscal', 'save', 'upload'],
        reason: 'server FISKALDAN KEYIN chaqirilishi shart');
    expect(states.last, isA<ReturnSuccedState>());
    expect((states.last as ReturnSuccedState).warning, isNull);

    expect(d.uploadedUrl, kRefundUrl,
        reason: 'serverga vozvratning o\'z QR URL\'i ketadi, sotuvniki emas');
    expect(d.uploaded!.url, isNot(kSaleUrl));
    expect(d.uploaded!.receiptSeq, 38002);
    expect(d.uploaded!.fiscalSign, '513103888474');
    expect(d.uploaded!.dateTimeOFD, '20260922094049');
    final Info saved = Info.fromJson(jsonDecode(d.saved!.refundInfo!));
    expect(saved.qrCodeUrl, kRefundUrl,
        reason: 'qayta chop etishda vozvrat QR\'i chiqadi');
    expect(identical(d.saved, d.uploaded), isTrue,
        reason: 'ObjectBox\'dagi va serverga ketgan model bitta obyekt');
    expect(d.savedResponse, isNotNull,
        reason: 'chek fiskal javob bilan chop etiladi (QR bilan)');
  });

  test('3. fiskal OK, server rad etdi — Succeed + ogohlantirish, save bo\'lgan',
      () async {
    final d = FakeDeps()
      ..uploadResult = const RefundUploadResult(RefundUploadStatus.rejected,
          error: 'Order already refunded');
    final states = await run(d);

    expect(d.calls, ['fiscal', 'save', 'upload']);
    final last = states.last;
    expect(last, isA<ReturnSuccedState>(),
        reason: 'fiskal chek chiqqan — "Qayta urinish" BO\'LMASLIGI kerak '
            '(ikkinchi fiskal vozvrat chiqarardi)');
    expect((last as ReturnSuccedState).warning, contains('Order already refunded'));
    expect(states.whereType<ReturnFailedState>(), isEmpty);
  });

  test('4. fiskal OK, server javob bermadi (pending) — Succeed, warning yo\'q',
      () async {
    final d = FakeDeps()
      ..uploadResult = const RefundUploadResult(RefundUploadStatus.pending);
    final states = await run(d);
    expect(d.calls, ['fiscal', 'save', 'upload']);
    expect((states.last as ReturnSuccedState).warning, isNull,
        reason: 'navbatda qoladi, kassirga xato ko\'rsatilmaydi');
  });

  test('5. server yiqilgani ma\'lum — upload umuman chaqirilmaydi', () async {
    final d = FakeDeps()..serverUp = false;
    final states = await run(d);
    expect(d.calls, ['fiscal', 'save']);
    expect(states.last, isA<ReturnSuccedState>());
    expect(d.saved!.uploaded, isFalse, reason: 'navbat uni keyin yuboradi');
    expect(d.saved!.url, kRefundUrl);
  });

  test('6. fiskal XATO — Failed, lokalga yozilmaydi, serverga ketmaydi',
      () async {
    final d = FakeDeps()..fiscal = (_) async => fiscalFail('Modul javob bermadi');
    final states = await run(d);
    expect(d.calls, ['fiscal']);
    expect(states.last, isA<ReturnFailedState>());
    expect((states.last as ReturnFailedState).error, 'Modul javob bermadi');
    expect(d.saved, isNull);
    expect(d.uploaded, isNull);
  });

  test('7. fiskal exception — Failed, save/upload yo\'q', () async {
    final d = FakeDeps()..fiscal = (_) async => throw Exception('timeout');
    final states = await run(d);
    expect(d.calls, ['fiscal']);
    expect(states.last, isA<ReturnFailedState>());
    expect(d.saved, isNull);
  });

  test('8. OFD yoqiq, sotuv OFDda yo\'q (pre-check) — fiskal yo\'q, maydonlar bo\'sh',
      () async {
    final d = FakeDeps();
    final states = await run(d, original: sale(registeredOnOfd: false));
    expect(d.calls, ['save', 'upload']);
    expect(states.last, isA<ReturnSuccedState>());
    expect(d.uploaded!.url, '');
    expect(d.uploaded!.refundInfo, isNull);
    expect(d.uploaded!.terminalId, isNull);
    expect(d.uploaded!.fiscalSign, isNull);
    expect(d.savedResponse, isNull, reason: 'QR\'siz chek');
  });

  test('9. OFD o\'chiq, sotuvda url bor — sotuv URL\'i vozvratga o\'tmaydi',
      () async {
    final d = FakeDeps()..ofd = false;
    final states = await run(d);
    expect(d.calls, ['save', 'upload']);
    expect(states.last, isA<ReturnSuccedState>());
    expect(d.uploaded!.url, '',
        reason: 'ilgari sotuv URL\'i vozvrat yozuvida qolib serverga ketardi');
    expect(d.uploaded!.refundInfo, isNull,
        reason: 'qayta chop etishda sotuv QR\'i chiqmasin');
  });

  test('10. vozvrat modeli: isRefund, CASH, rightList, yangi chek raqami',
      () async {
    final d = FakeDeps();
    await run(d);
    final r = d.saved!;
    expect(r.isRefund, isTrue);
    expect(r.externalId, 'DN-101');
    expect(r.comment, 'Refund made from DN-100');
    expect(r.payment.length, 1);
    expect(r.payment.single.name, 'CASH');
    expect(r.payment.single.payId, 'cash-id');
    expect(r.payment.single.value, 4000);
    expect(r.totalPrice, 4000);
    expect(r.soldItemList.length, 1);
    expect(r.soldItemList.single.productId, 'p1');
  });

  test('holatlar ketma-ketligi: internet → returnig → Succeed', () async {
    final d = FakeDeps();
    final states = await run(d);
    expect(states[0], isA<ReturnLoadingState>());
    expect((states[0] as ReturnLoadingState).message, ReturnMessage.internet);
    expect(states[1], isA<ReturnLoadingState>());
    expect((states[1] as ReturnLoadingState).message, ReturnMessage.returnig);
    expect(states[2], isA<ReturnSuccedState>());
    expect(states.length, 3);
  });
}
```

</details>

## 7. Tekshirish

- `flutter test test/return_bloc_flow_test.dart test/refund_upload_queue_test.dart` — 20/20; to'liq to'plam 1184 (2026-09-22).
- E2E (Mac, soxta fiskal modul Node 127.0.0.1:3448 + DEV backend, 2026-09-22): (a) onlayn vozvrat → serverda `url` = vozvratniki, sotuvda `refund_amount` oshdi; (b) fiskal xato → `ReturnFailedState`, ObjectBox'da yozuv yo'q, server chaqirilmadi; (c) server 400 → `ReturnSuccedState(warning)`, chek `rejected=true, uploaded=false`, serverda yozuv yo'q; (d) server o'chgan → `warning=null`, `uploaded=false`, server tiklangach `flush` → `uploaded=true`, serverda URL to'g'ri.
- `url` bo'sh vozvrat yozuvi cheklar ro'yxatida "Pre Check" deb ko'rinmasligi kerak — InVan 2 da ikkala joy `!isRefund` bilan himoyalangan (`build_list_item.dart`, `check_view_content.dart`). InVan 1 da tekshiring.
- Do'kon sinovi (haqiqiy modul): kutilmoqda.

## 8. Eslatmalar va ochiq savollar

- Backend `refund_for_pos_new` da `terminal_id/receipt_seq/fiscal_sign` qabul qiladimi — noma'lum, shoshilinch emas. Hozir serverdagi vozvrat yozuvida `receipt_seq/fiscal_sign` sotuvniki bo'lib qoladi (backend asl orderdan nusxalaydi), faqat `url` vozvratniki.
- `receiptCreateGrouppForRefund` ikki so'rov qiladi: birinchisi 201, ikkinchisi (`refund_order_items`) 4xx bo'lsa serverda itemsiz vozvrat sarlavhasi qolishi mumkin; qo'lda qayta yuborishda birinchi so'rov 409 → `uploaded` deb belgilanadi, itemlar ketmaydi. Eski xulq, alohida task.
- Sotuv chekida `discountID` bo'sh bo'lsa server 500 (`order_discount_type: ""`) — haqiqiy sotuvda `ReceiptBuilder` default `9fb3ada6-...` qo'yadi; E2E'da ko'rildi.
- JSON'dagi `&` = `&`; xom JSON'dan ko'chirilgan URL soliq sahifasida "48 soat" xabarini beradi — ilova xatosi emas.


---

# 4-TASK — Vozvrat fiskal chekida `OwnerType` va komitent STIR sotuv bilan bir xil (1.1.2+127)

> **Commit:** `c853b27` (2026-09-24), reliz 1.1.2+127 (2026-09-24, PRO backend'ga yuklangan).
> **Sessiya hujjati:** `docs/sessions/2026-09-24-refund-owner-type-komitent-stir.md`.
> **Holat 2026-09-24:** Relizda (1.1.2+127, PRO backendga yuklangan). Testlar o'tgan, do'kon sinovi yo'q.

## 1. Nima va nima uchun

**Simptom:** soliq sahifasida vozvrat chekida (2026-09-23, chek 38391) "Komitent STIR/JSHSHIR: 0" ko'rindi.

**Tahlil:**
- "Komitent STIR/JSHSHIR" = fiskal item `CommissionInfo.TIN/PINFL` — komissiya savdosida tovar egasining STIR (9 xona) yoki JSHSHIR (14 xona). O'z tovari uchun bo'sh. `OwnerType` oddiy tovar uchun `1` (spec: `docs/fiscal-sale-integration.md`).
- **Sotuv:** `SoldItemBuilder.build` → `ownerType = int.tryParse(product.ownerType ?? '1') ?? 1`, `tin = product.commissionTin ?? ''`. `saleOnOFD` → `OwnerType: 1`.
- **Vozvrat:** qatorlar serverdan (`api/v1/order`) keladi; server itemida `owner_type` ham, `commission_tin` ham YO'Q. `ChecksSingleton._globalToLocalSoldItem` ularga `ownerType: 0`, `tin: ""` **qattiq** yozardi → vozvrat soliqqa `OwnerType: 0` bilan ketardi. Sotuv bilan farq aynan shu.
- Soliq API (`POST new-ofd.soliq.uz/api/payment`, HMAC) tekshiruvi 2026-09-24: sotuvda ham, vozvratda ham `comitentTin: 0` — raqamli maydon, bo'sh TIN → 0. Ya'ni ko'ringan "0" = komitent yo'q, o'z tovari — NORMAL. Lekin `OwnerType` farqi haqiqiy edi va tuzatildi (sotuv bilan spec-parity).

**Yechim:** `RefundItemOrigin` — vozvrat qatori uchun `OwnerType`/STIR **katalogdagi mahsulotdan**, sotuv (`SoldItemBuilder`) bilan aynan bir xil qoida. Katalogda yo'q (o'chirilgan tovar, eski chek) → spec default `1` / `""`. Qidiruv hech qachon exception tashlamaydi (katalogda `id == null` mahsulot bo'lsa ham) — bu to'lov yo'li.

## 2. O'zgarishlar ro'yxati

| Fayl | Tur | Nima |
|---|---|---|
| `lib/changes/domain/receipt/refund_item_origin.dart` | YANGI | `RefundItemOrigin{ownerType, tin}`, `fallback`, `resolve(ItemModel?)`, `fromCatalog(productId)` |
| `lib/features/get_products/singletons/checks_singleton.dart` | o'zgargan | `_globalToLocalSoldItem`: `ownerType: origin.ownerType`, `tin: origin.tin` (ilgari `0`, `""`) |
| `test/refund_item_origin_test.dart` | YANGI | 12 test: sof qoida; `SoldItemBuilder` bilan tenglik; `globalToLocall` katalogdan; modulga ketadigan JSON'da `OwnerType` 1 / komissiya 2 |

## 3. Bog'liqliklar (InVan 1 uchun)

- `ItemsSingleton.getProductById(id)` — katalog qidiruvi; InVan 1 da nomi boshqa bo'lishi mumkin.
- `ItemModel.ownerType` (`String?`), `ItemModel.commissionTin` (`String?`). Eslatma: `commissionTin` serverdan **hech qachon kelmaydi** (product JSON'da `commission_tin` kaliti yo'q, adminkada bunday maydon yo'q — faqat "Owner type" dropdown) → lokalda doim `null` → STIR doim `""`. Bu ma'lum, tegilmagan.
- Qoida sotuv yo'li bilan bir xil bo'lishi SHART: InVan 1 da sotuv qatori `ownerType` ni qayerdan olsa (InVan 2 da `SoldItemBuilder.build`; InVan 1 da `OrderingProvider.addProduct` dagi `ReceiptModelSoldItem4(... ownerType: ...)` bo'lishi mumkin), vozvrat ham o'sha yerdan olsin.
- Test `SoldItemBuilder`, `ReceiptSingleton4.saleOnOFD`, `RequestSaleModel.fromJson`, `FiscalReceiptModel.fromRequest`, `GlobalReceipt.fromJson`, `test/support/provider_harness.dart` ga tayanadi.

## 4. Qo'llash tartibi

1. `refund_item_origin.dart` yarating (5.1).
2. `checks_singleton.dart` da vozvrat qatori quruvchisida `ownerType`/`tin` ni `RefundItemOrigin.fromCatalog(productId)` dan oling (5.2).
3. Test (5.3), `dart analyze`, `flutter test`.
4. Tekshirish: vozvrat fiskal JSON'ida (`Api.SendRefundReceipt` → `Items[].OwnerType`) qiymat sotuvdagi bilan bir xil (oddiy tovar `1`, komissiya `2`).

## 5. Kod

### 5.1. YANGI: `lib/changes/domain/receipt/refund_item_origin.dart`

```dart
// Vozvrat qatorining fiskal "egalik" maydonlari: OwnerType va komitent STIR.
//
// Nega kerak: vozvrat qatorlari serverdan (`api/v1/order`) keladi va u yerda
// `owner_type` ham, `commission_tin` ham YO'Q. `ChecksSingleton` ilgari
// `ownerType: 0`, `tin: ""` deb qo'yardi — natijada soliqqa sotuvda
// `OwnerType: 1` ketgan tovar vozvratda `OwnerType: 0` bilan ketardi
// (soliq sahifasida "Komitent STIR/JSHSHIR: 0", 2026-09-23).
//
// Yechim: sotuvdagi bilan BIR XIL manba — katalogdagi mahsulot
// (`SoldItemBuilder.build` qanday olsa, shunday). Mahsulot katalogda
// topilmasa (o'chirilgan, eski chek) — spec bo'yicha oddiy tovar: `1`, STIR "".
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';

class RefundItemOrigin {
  /// Fiskal `OwnerType`. Oddiy tovar — `1` (docs/fiscal-sale-integration.md).
  final int ownerType;

  /// Komitent STIR (9 xona) yoki JSHSHIR (14 xona); bo'lmasa "".
  final String tin;

  const RefundItemOrigin({required this.ownerType, required this.tin});

  static const RefundItemOrigin fallback =
      RefundItemOrigin(ownerType: 1, tin: '');

  /// Sotuv yo'li (`SoldItemBuilder.build`) bilan aynan bir xil qoida.
  static RefundItemOrigin resolve(ItemModel? product) {
    if (product == null) return fallback;
    return RefundItemOrigin(
      ownerType: int.tryParse(product.ownerType ?? '1') ?? 1,
      tin: product.commissionTin ?? '',
    );
  }

  /// Katalogdan qidiradi. Bu vozvrat (to'lov) yo'li — hech qachon exception
  /// tashlamaydi: katalogda `id == null` mahsulot bo'lsa ham [fallback].
  static RefundItemOrigin fromCatalog(String? productId) {
    if (productId == null || productId.isEmpty) return fallback;
    try {
      return resolve(ItemsSingleton.getProductById(productId));
    } catch (_) {
      return fallback;
    }
  }
}
```

### 5.2. `lib/features/get_products/singletons/checks_singleton.dart`

```diff
diff --git a/lib/features/get_products/singletons/checks_singleton.dart b/lib/features/get_products/singletons/checks_singleton.dart
index 964a350..7424dc3 100644
--- a/lib/features/get_products/singletons/checks_singleton.dart
+++ b/lib/features/get_products/singletons/checks_singleton.dart
@@ -1,5 +1,6 @@
 import 'dart:convert';
 
+import 'package:invan2/changes/domain/receipt/refund_item_origin.dart';
 import 'package:invan2/changes/models/discount_model.dart';
 import 'package:invan2/changes/models/receipts_get_model.dart';
 import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
@@ -134,6 +135,12 @@ supplierId: "",
 
       double vat = effectiveUnitPrice * (v[i].vatPercentage?.toDouble() ?? 0) / (100 + (v[i].vatPercentage?.toDouble() ?? 0));
 
+      // OwnerType va komitent STIR — server itemida yo'q, katalogdan (sotuv
+      // bilan bir xil manba). Ilgari `ownerType: 0`, `tin: ""` qattiq yozilgan
+      // edi — vozvrat soliqqa sotuvdan boshqa OwnerType bilan ketardi.
+      final RefundItemOrigin origin =
+          RefundItemOrigin.fromCatalog(v[i].productId);
+
       final receipt = ReceiptModelSoldItem4(
         inBox: 0,
         singleDiscount: singleDisc,
@@ -145,7 +152,7 @@ supplierId: "",
         createdTime: 0,
         mxik: v[i].mxikCode ?? "",
         price: effectiveUnitPrice,
-        ownerType: 0,
+        ownerType: origin.ownerType,
         productId: v[i].productId ?? "",
         productName: v[i].productName ?? '',
         sku: int.parse(v[i].sku ?? "0"),
@@ -153,7 +160,7 @@ supplierId: "",
         value: v[i].value?.toDouble() ?? 0,
         vat: vat,
         vatPercent: v[i].vatPercentage?.toDouble() ?? 0,
-        tin: "",
+        tin: origin.tin,
         packageCode: v[i].packageCode,
         packageName: v[i].packageName,
         // mark: ,
```

### 5.3. YANGI: `test/refund_item_origin_test.dart`

<details>
<summary>To'liq fayl (243 qator)</summary>

```dart
// Vozvrat qatorining fiskal OwnerType va komitent STIR'i — sotuv bilan bir xil.
//
// Nega kerak: vozvrat qatorlari serverdan keladi (`owner_type`/`commission_tin`
// yo'q) va ilgari `ChecksSingleton` `ownerType: 0`, `tin: ""` qattiq yozardi.
// Soliqqa sotuvda `OwnerType: 1` ketgan tovar vozvratda `OwnerType: 0` bilan
// ketardi (soliq sahifasi: "Komitent STIR/JSHSHIR: 0", 2026-09-23).
//
// Tekshiriladi:
//   1. `RefundItemOrigin.resolve` — `SoldItemBuilder` bilan bir xil qoida
//   2. `ChecksSingleton.globalToLocall` — server itemi katalog mahsulotidan OwnerType/STIR oladi
//   3. Modulga ketadigan JSON (`Api.SendRefundReceipt`) — `OwnerType` sotuvdagi bilan bir xil
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/cart/sold_item_builder.dart';
import 'package:invan2/changes/domain/receipt/refund_item_origin.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/models/receipts_get_model.dart';
import 'package:invan2/features/get_products/singletons/checks_singleton.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/fiscal_service/model/fiscal_receipt_model.dart';
import 'package:invan2/fiscal_service/model/location/location.dart';
import 'package:invan2/fiscal_service/model/receipt_data_model.dart';
import 'package:invan2/fiscal_service/model/request_receipt_model.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kMxik = '02202002001010021';
const kTin9 = '309072901';
const kPinfl14 = '31234567890123';

ItemModel product(String id, {String? ownerType, String? commissionTin}) {
  final m = ItemModel();
  m.id = id;
  m.name = 'Tovar $id';
  m.mxikCode = kMxik;
  m.barcode = ['4780069000017'];
  m.ownerType = ownerType;
  m.commissionTin = commissionTin;
  m.packageCode = '104579';
  return m;
}

/// Server `api/v1/order` javobidagi bitta sotuv cheki (vozvrat sahifasi
/// aynan shu shakldan boshlanadi).
GlobalReceipt serverSale(List<String> productIds) => GlobalReceipt.fromJson({
      'id': 'order-1',
      'external_id': 'DP-1',
      'status': {'name': 'paid'},
      'total_price': 191760 * productIds.length,
      'create_time': '2026-09-23T11:46:24Z',
      'terminal_id': 'LG230110020538',
      'receipt_seq': 38390,
      'date_time': '20260923164600',
      'fiscal_sign': '111111111111',
      'url': 'https://ofd.soliq.uz/check?t=LG230110020538&r=38390&c=20260923164600&s=111111111111',
      'pays': [],
      'items': [
        for (final pid in productIds)
          {
            'id': 'item-$pid',
            'product_id': pid,
            'product_name': 'Coca-Cola energy 250ml',
            'price': 7990,
            'value': 24,
            'refund_amount': 0,
            'total_price': 191760,
            'barcode': '4780069000017',
            'sku': '1',
            'mxik_code': kMxik,
            'vat_name': 'QQS 12%',
            'vat_percentage': 12,
            'package_code': '104579',
            'package_name': 'dona',
          },
      ],
    });

/// Modulga ketadigan JSON — `LocalService.saleWithOutIncom` zanjiri tarmoqsiz.
Map<String, dynamic> wireJson(ReceiptModel4 receipt) {
  final ofdBody = ReceiptSingleton4.saleOnOFD(receipt);
  final model = RequestSaleModel.fromJson(ofdBody);
  final fiscal = FiscalReceiptModel.fromRequest(
    model,
    ReceiptDataModel(
      factoryID: 'UZ000000000MOCK',
      terminalID: 'LG230110020538',
      location: Location(latitude: 41.311081, longitude: 69.240562),
    ),
    DateTime(2026, 9, 23, 16, 46, 24),
    ExtraInfo(
      carNumber: '',
      phoneNumber: '',
      cardType: 0,
      pinfl: '',
      tin: '',
      qrPaymentID: '',
      qrPaymentProvider: 0,
      cardNumber: '',
      pptId: '',
      cashedOutFromCard: 0,
    ),
  );
  return jsonDecode(jsonEncode(fiscal.toJson())) as Map<String, dynamic>;
}

List<Map<String, dynamic>> itemsOf(Map<String, dynamic> wire) =>
    (wire['params']['Receipt']['Items'] as List).cast<Map<String, dynamic>>();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('refund_item_origin', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  setUp(() {
    ItemsSingleton.products = [
      product('p-own', ownerType: '1'),
      product('p-komissiya', ownerType: '2', commissionTin: kTin9),
      product('p-fiz', ownerType: '2', commissionTin: kPinfl14),
      product('p-null'), // adminka owner_type bermagan
    ];
  });
  tearDown(() => ItemsSingleton.products = []);

  group('RefundItemOrigin.resolve — SoldItemBuilder bilan bir xil', () {
    test('o\'z tovari → OwnerType 1, STIR bo\'sh', () {
      final o = RefundItemOrigin.resolve(product('x', ownerType: '1'));
      expect(o.ownerType, 1);
      expect(o.tin, '');
    });

    test('komissiya tovari → OwnerType 2, STIR adminkadan', () {
      final o = RefundItemOrigin.resolve(
          product('x', ownerType: '2', commissionTin: kTin9));
      expect(o.ownerType, 2);
      expect(o.tin, kTin9);
    });

    test('owner_type yo\'q / buzuq → 1 (spec: oddiy tovar)', () {
      expect(RefundItemOrigin.resolve(product('x')).ownerType, 1);
      expect(RefundItemOrigin.resolve(product('x', ownerType: 'abc')).ownerType, 1);
    });

    test('mahsulot katalogda yo\'q → fallback 1, ""', () {
      expect(RefundItemOrigin.resolve(null), same(RefundItemOrigin.fallback));
      expect(RefundItemOrigin.fromCatalog('yo-q-id').ownerType, 1);
      expect(RefundItemOrigin.fromCatalog('').ownerType, 1);
      expect(RefundItemOrigin.fromCatalog(null).tin, '');
    });

    test('katalogda id == null mahsulot bo\'lsa ham exception yo\'q', () {
      ItemsSingleton.products = [ItemModel()..name = 'buzuq', product('p-own', ownerType: '1')];
      expect(() => RefundItemOrigin.fromCatalog('p-own'), returnsNormally);
    });

    for (final p in [
      product('a', ownerType: '1'),
      product('b', ownerType: '2', commissionTin: kTin9),
      product('c'),
    ]) {
      test('sotuv qatori (SoldItemBuilder) bilan aynan bir xil: ${p.id}', () {
        final sale = SoldItemBuilder.build(p, 7990, 1, false);
        final o = RefundItemOrigin.resolve(p);
        expect(o.ownerType, sale.ownerType);
        expect(o.tin, sale.tin);
      });
    }
  });

  group('ChecksSingleton.globalToLocall — vozvrat qatori', () {
    test('OwnerType va STIR katalogdan (ilgari 0 va "")', () {
      final r = ChecksSingleton.globalToLocall(
          serverSale(['p-own', 'p-komissiya', 'p-fiz', 'p-none']));
      final byId = {for (final e in r.soldItemList) e.productId: e};

      expect(byId['p-own']!.ownerType, 1);
      expect(byId['p-own']!.tin, '');
      expect(byId['p-komissiya']!.ownerType, 2);
      expect(byId['p-komissiya']!.tin, kTin9);
      expect(byId['p-fiz']!.tin, kPinfl14);
      expect(byId['p-none']!.ownerType, 1,
          reason: 'katalogda yo\'q (o\'chirilgan tovar) — spec default');
      expect(byId['p-none']!.tin, '');
    });

    test('refundItemId server item idsi bo\'lib qoladi (regressiya)', () {
      final r = ChecksSingleton.globalToLocall(serverSale(['p-own']));
      expect(r.soldItemList.single.refundItemId, 'item-p-own');
      expect(r.soldItemList.single.value, 24);
    });
  });

  group('Api.SendRefundReceipt — modulga ketadigan JSON', () {
    setUp(() async {
      await Pref.setString(PrefKeys.cashId, 'cash-id');
      await Pref.setString(PrefKeys.mxikCode, '01905012001000000');
    });

    test('vozvrat OwnerType sotuvdagi bilan bir xil (1), 0 emas', () {
      final original = ChecksSingleton.globalToLocall(serverSale(['p-own']));

      // return_bloc vozvrat modelini shunday quradi: isRefund, CASH, refundInfo.
      final refund = original
        ..isRefund = true
        ..externalId = 'DP-2'
        ..returnForCheck = 'DP-1';
      refund.payment
        ..clear()
        ..add(ReceiptModelPaymentType4(
            name: 'CASH', payId: 'cash-id', value: 191760));

      final wire = wireJson(refund);
      expect(wire['method'], 'Api.SendRefundReceipt');
      final it = itemsOf(wire).single;
      expect(it['OwnerType'], 1);
      expect(it['CommissionInfo'], {'TIN': '', 'PINFL': ''});

      // Sotuv qatori xuddi shu mahsulotdan — bir xil OwnerType.
      final saleRow = SoldItemBuilder.build(
          ItemsSingleton.getProductById('p-own')!, 7990, 24, false);
      expect(saleRow.ownerType, it['OwnerType']);
    });

    test('komissiya tovari: OwnerType 2 ketadi', () {
      final original = ChecksSingleton.globalToLocall(serverSale(['p-komissiya']));
      final refund = original
        ..isRefund = true
        ..externalId = 'DP-3'
        ..returnForCheck = 'DP-1';
      refund.payment
        ..clear()
        ..add(ReceiptModelPaymentType4(
            name: 'CASH', payId: 'cash-id', value: 191760));
      final it = itemsOf(wireJson(refund)).single;
      expect(it['OwnerType'], 2);
    });
  });
}
```

</details>

## 6. Tekshirish va ochiq savollar

- `flutter test test/refund_item_origin_test.dart` — 12/12; `flutter analyze` toza (faqat eski info); to'liq to'plam o'tgan (2026-09-24).
- Do'konda: vozvrat → soliq sahifasida OwnerType/komitent sotuv bilan bir xil — kutilmoqda.
- **Ochiq:** `OwnerType` справочник (0/1/2/3 ma'nosi) rasmiy ochiq manbada yo'q. FiscalDriveService README: `OwnerType uint8 — Тип владельца продукта/услуги (см. справочник)`, `CommissionInfo {TIN, PINFL}`. Adminkadagi "Owner type" dropdown variantlari nima — fiskal modul yetkazuvchisidan (NIC NT / YT.UZ) so'rash kerak. Hozir sotuv ham, vozvrat ham adminkadagi qiymatni yuboradi (bir xil) — soliq qabul qiladi.
- Rasmiy manbalar: VM qarori №943 (23.11.2019) Nizom 7-band 8-kichik band ("Komitent STIRi/JSHSHIRi" chek rekviziti); NRM.uz sharhi (komissiya savdosida komitent STIR ko'rsatiladi, uning hisobotiga kiradi).


---

# 5-TASK — Fiskal QQS bazasi chegirmadan keyingi summa: `VAT = (Price − Discount − Other) × p / (100 + p)` (1.1.2+127)

> **Commit:** `85199e6`..`0b3114c` (2026-09-24, branch `fix/fiskal-qqs-chegirma-bazasi`, 5 commit) — `7e01ce8` bilan `ayyubxon`ga birlashtirildi (konfliktsiz), reliz 1.1.2+127 (2026-09-24, PRO backend'ga yuklangan).
> **Sessiya hujjati:** `docs/sessions/2026-09-24-fiskal-qqs-chegirma-bazasi.md` (o'sha branch'da).
> **Holat 2026-09-24:** Relizda (1.1.2+127, PRO backendga yuklangan). 67 yangi test (16+28+23); 6-task bilan birga to'liq to'plam 1357/1357 o'tgan; do'kon sinovi (haqiqiy fiskal modul, ofd.soliq.uz chekida QQS) YO'Q.

## 1. Nima va nima uchun

**Muammo:** chegirmali tovarda fiskal modulga (soliqqa) QQS chegirmaSIZ narxdan ketardi. 50 000 so'mlik tovar 30 000 chegirma bilan 20 000 ga sotilsa, `VAT` 50 000 dan (5 357 so'm) hisoblanardi, to'g'risi 20 000 dan (2 143 so'm). Qog'oz chek va ekran esa 2 143 ko'rsatardi — fiskal va chek mos emas edi. 2026-05-16 dan beri shunday.

**Sabab:** `_countVat = (Price − Other) × p/(100+p)` — `Discount` ayrilmasdi. 2026-06-24 "OFD 10.2.1 elektron to'lov yaxlitlash" taskida bu formula "app formulasiga mos" deb qabul qilingan edi (o'sha arxiv hujjatiga "Superseded by" qo'shildi). Fiskal modul VAT summasini tekshirmaydi (faqat `Price − Discount − Other` balansini), shuning uchun chek rad etilmagan, lekin OFD'ga ortiqcha QQS ketgan.

**Yechim:** **`VAT = (Price − Discount − Other) × p / (100 + p)`**, manfiy chiqsa 0. Rasmiy FiscalDriveService misoli: `Price 100000, Discount 50000, VATPercent 12 → VAT 5357 = 50000 × 12 / 112`. Soliq kodeksi mantiqi: baza = tomonlar qo'llagan narx (chegirmadan keyingi).

## 2. Qanday ishlaydi

- Fiskal item (tiyinda): `Price = realPrice × qty` (chegirmasiz, `_countPrice`); `Discount = (realPrice − price) × qty` (`_countDiscountOFD`); `Other` = qatorga tushgan cashback ulushi (`_countOtherOFD`, chegirmali narx nisbatida, `Other ≤ Price − Discount`).
- Diskont qo'llanganda `price` kamayadi, `realPrice` asl narxda qoladi — shuning uchun barcha diskont turlari (foiz, summa, kategoriya, BuyXGetY, utsenka QR) shu yo'ldan o'tadi.
- Yangi baza `Price − Discount − Other` = `_enforce1021Balance` dagi δ bilan bir xil. 100% cashback → VAT 0 (avvalgidek), 100% chegirma → VAT 0.
- `_countVat` imzosi `named required` parametrlar bilan (`{required num discount, required num other}`) — chaqiruvda unutib bo'lmaydi. 4 chaqiruv: item qurish (`saleOnOFD`) + `_enforce1021Balance` uchala yo'li (per-item qirqish `discount: d`; residual > 0 Price kamaytirish; residual < 0 Other kamaytirish — ikkalasida `discount: discountOf(it)`).
- `_build1021Diag` (Telegram log diagnostikasi) kutilgan VAT ham shu formulada — aks holda har chegirmali qator "VAT mos emas" false positive berardi.
- Barcha fiskal yo'llar (sotuv, vozvrat, INCOM/lokal) `saleOnOFD` orqali — bitta joy. VAT yaxlitlash o'zgartirilmadi (kasr `.toInt()` bilan kesiladi; rasmiy misolda ham 5357.14 → 5357).

## 3. O'zgarishlar ro'yxati

| Fayl | Tur | Nima |
|---|---|---|
| `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart` | o'zgargan | `_countVat(price, nds, {required discount, required other})`; 4 chaqiruv |
| `lib/fiscal_service/base_service.dart` | o'zgargan | `_build1021Diag` kutilgan VAT formulasi `price − disc − other` |
| `docs/fiscal-sale-integration.md`, `.ru.md` | o'zgargan | VAT qoidasi (port qilinmaydi) |
| `test/fiscal_vat_base_test.dart` | YANGI | 18 test: foydalanuvchi misoli (50 000/30 000 → 214 285 tiyin), rasmiy misol (→ 5357), chegirmasiz regressiya, qty > 1, 100% chegirma, QQS 0%, vozvrat, ko'p qator; cashback 100% / qisman / chegirma bilan / ko'p qatorga taqsimot; `_enforce1021Balance` uchala yo'li |

## 4. Bog'liqliklar (InVan 1 uchun)

- `_enforce1021Balance` va `_countOtherOFD` — 2026-06-24 "OFD 10.2.1 elektron to'lov yaxlitlash" taskidan (bu hujjatdan TASHQARIDA; `docs/sessions/archive/2026-06-24-ofd-1021-electronic-payment-rounding.md`). InVan 1 da bo'lmasa, minimal variant: fiskal item quruvchida `VAT` formulasini `(Price − Discount − Other)` ga o'zgartiring — `Other` yo'q bo'lsa `(Price − Discount)`.
- `_build1021Diag` (`base_service.dart`) — Telegram log diagnostikasi; InVan 1 da bo'lmasa o'tkazib yuboring.
- Test `ReceiptSingleton4.saleOnOFD`, `SoldItemBuilder`, `RequestSaleModel`, `FiscalReceiptModel.fromRequest`, `test/support/provider_harness.dart` ga tayanadi.

## 5. Qo'llash tartibi

1. `receipt_singleton_4.dart`: `_countVat` imzosi va formulasi, 4 chaqiruv (6.1).
2. `base_service.dart`: diagnostika formulasi (6.2).
3. Test (6.3), `dart analyze`, `flutter test`.
4. Tekshirish: chegirmali tovar sotuvida fiskal JSON'da `VAT = (Price − Discount − Other) × p/(100+p)`; §10.2.1 balans (`Items` jami = to'lovlar) buzilmagan; 100% cashback → VAT 0.

## 6. Kod

Diff bazasi: `85199e6^` → `85199e6`.

### 6.1. `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart`

```diff
diff --git a/lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart b/lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart
index 55258c2..660cc9e 100644
--- a/lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart
+++ b/lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart
@@ -357,7 +357,7 @@ class ReceiptSingleton4 {
         discount: discount,
         ownerType: e.ownerType,
         other: other,
-        vat: _countVat(price, e.vatPercent, other),
+        vat: _countVat(price, e.vatPercent, discount: discount, other: other),
         vatPercent: e.vatPercent,
         price: price,
         packageCode: e.packageCode,
@@ -477,7 +477,7 @@ class ReceiptSingleton4 {
       final num payable = (p - d) < 0 ? 0 : (p - d);
       if ((it.other ?? 0) > payable) {
         it.other = payable;
-        it.vat = _countVat(p, it.vatPercent ?? 0, payable);
+        it.vat = _countVat(p, it.vatPercent ?? 0, discount: d, other: payable);
       }
     }
 
@@ -514,7 +514,12 @@ class ReceiptSingleton4 {
         if (delta <= 0) break; // kamayish tartibida — davomi ham ≤ 0
         final num take = delta < remaining ? delta : remaining;
         it.price = (it.price ?? 0) - take;
-        it.vat = _countVat(it.price ?? 0, it.vatPercent ?? 0, it.other ?? 0);
+        it.vat = _countVat(
+          it.price ?? 0,
+          it.vatPercent ?? 0,
+          discount: discountOf(it),
+          other: it.other ?? 0,
+        );
         remaining -= take;
       }
     } else {
@@ -530,7 +535,12 @@ class ReceiptSingleton4 {
         if (o <= 0) break; // kamayish tartibida — davomi ham ≤ 0
         final num take = o < remaining ? o : remaining;
         it.other = o - take;
-        it.vat = _countVat(it.price ?? 0, it.vatPercent ?? 0, it.other ?? 0);
+        it.vat = _countVat(
+          it.price ?? 0,
+          it.vatPercent ?? 0,
+          discount: discountOf(it),
+          other: it.other ?? 0,
+        );
         remaining -= take;
       }
     }
@@ -543,9 +553,27 @@ class ReceiptSingleton4 {
     return UtilFunctions.roundToNearest(e.value * e.price) * 100;
   }
 
-  static num _countVat(num priceJson, num nds, num other) {
-    // priceJson and other are both in tiins (already rounded), ensuring price = other + vat
-    num n = (priceJson - other) * nds / (100 + nds);
+  /// Fiskal `VAT` (tiyinda). QQS bazasi = `Price − Discount − Other`.
+  ///
+  /// `Price` chegirmaSIZ qator summasi (`_countPrice`), shuning uchun chegirma
+  /// ALBATTA ayriladi. 2026-09-24 gacha `Discount` ayrilmasdan hisoblanardi:
+  /// 50 000 so'mlik tovar 30 000 chegirma bilan 20 000 ga sotilsa, soliqqa
+  /// QQS 50 000 dan (5 357) ketardi, to'g'risi 20 000 dan (2 143).
+  ///
+  /// Rasmiy FiscalDriveService misoli: Price 100000, Discount 50000,
+  /// VATPercent 12 → VAT 5357 = (100000 − 50000) × 12 / 112.
+  ///
+  /// `Other` — xaridordan olinmagan qism (cashback va h.k., `_countOtherOFD`),
+  /// u ham bazaga kirmaydi: 100% cashback → VAT 0. Baza `_enforce1021Balance`
+  /// dagi δ bilan bir xil, shuning uchun balans tuzatilganda ham mos qoladi.
+  /// Hammasi tiyinda; manfiy chiqsa 0.
+  static num _countVat(
+    num price,
+    num nds, {
+    required num discount,
+    required num other,
+  }) {
+    num n = (price - discount - other) * nds / (100 + nds);
     return n < 0 ? 0 : n;
   }
 
```

### 6.2. `lib/fiscal_service/base_service.dart`

```diff
diff --git a/lib/fiscal_service/base_service.dart b/lib/fiscal_service/base_service.dart
index b17a707..199b461 100644
--- a/lib/fiscal_service/base_service.dart
+++ b/lib/fiscal_service/base_service.dart
@@ -170,11 +170,13 @@ class BaseService {
           problems.writeln(
               '  #$idx ${it['Name']}: ❗OTHER+DISC>PRICE (price=$price, other=$other, disc=$disc)');
         }
-        // 2) НДС tekshiruvi: app formulasi vat = (price - other) * vatP/(100+vatP).
-        //    (price - disc) EMAS — 100% elektronda other=price bo'lib VAT=0
-        //    to'g'ri hisoblanadi, uni bayroqlash false positive edi.
+        // 2) НДС tekshiruvi: app formulasi
+        //    vat = (price - disc - other) * vatP/(100+vatP).
+        //    QQS bazasi chegirmadan KEYINGI va Other'siz summa (rasmiy misol:
+        //    Price 100000, Discount 50000 → VAT 5357). 100% elektronda
+        //    other = price - disc bo'lib VAT=0 to'g'ri chiqadi.
         final num expVat =
-            vatP == 0 ? 0 : ((price - other) * vatP / (100 + vatP));
+            vatP == 0 ? 0 : ((price - disc - other) * vatP / (100 + vatP));
         if ((expVat - vat).abs() > 1) {
           problems.writeln(
               '  #$idx ${it['Name']}: VAT=$vat lekin kut~${expVat.round()} (vatP=$vatP, price=$price, other=$other, disc=$disc)');
```

### 6.3. YANGI: `test/fiscal_vat_base_test.dart`

<details>
<summary>To'liq fayl (472 qator)</summary>

```dart
// Fiskal `VAT` bazasi: Price − Discount − Other.
//
// Nega kerak: 2026-09-24 gacha `ReceiptSingleton4._countVat` chegirmani
// ayirmasdan `(Price − Other)` dan QQS hisoblardi. Chegirmali tovarda soliqqa
// chegirmaSIZ narxdan QQS ketardi (50 000 so'm, 30 000 chegirma → QQS 50 000
// dan, 5 357 so'm; to'g'risi 20 000 dan, 2 143 so'm). Rasmiy FiscalDriveService
// misoli: Price 100000, Discount 50000, VATPercent 12 → VAT 5357
// = (100000 − 50000) × 12 / 112.
//
// Zanjir `test/fiscal_wire_format_test.dart` bilan bir xil (tarmoqsiz):
//   ReceiptModel4 → ReceiptSingleton4.saleOnOFD → RequestSaleModel
//     → FiscalReceiptModel.fromRequest → toJson()  ← modulga ketadigan JSON
//
// Tekshiriladi: `Items[].VAT` har qatorda
//   trunc((Price − Discount − Other) × VATPercent / (100 + VATPercent)),
// cashback (`Other`) bilan aralash holatlar, `_enforce1021Balance` ning
// uchala tuzatish yo'li (per-item qirqish, residual > 0, residual < 0) dan
// keyin ham VAT shu formulada qolishi va §10.2.1 balansi.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/fiscal_service/model/fiscal_receipt_model.dart';
import 'package:invan2/fiscal_service/model/location/location.dart';
import 'package:invan2/fiscal_service/model/receipt_data_model.dart';
import 'package:invan2/fiscal_service/model/request_receipt_model.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kMxik = '01234567890123456';
const kBarcode = '4780000000002';
const kCashbackPayId = 'pay-cashback-1';
const kFactory = 'UZ000000000MOCK';
const kTerminal = 'MOCK00000001';

ItemModel product(String id) {
  final m = ItemModel();
  m.id = id;
  m.name = id;
  m.isMarking = false;
  m.mxikCode = kMxik;
  m.barcode = [kBarcode];
  return m;
}

/// Savat qatori. [realPrice] — chegirmasiz narx, [price] — chegirmadan keyingi
/// narx (berilmasa chegirma yo'q). Diskont qo'llanganda ilova aynan shunday
/// qiladi: `price` kamayadi, `realPrice` asl narxda qoladi
/// (discount_helpers.dart), fiskalga `Price = realPrice × qty`,
/// `Discount = (realPrice − price) × qty` ketadi.
ReceiptModelSoldItem4 row({
  required double realPrice,
  double? price,
  double value = 1,
  double vatPercent = 12,
  String productId = 'p-1',
  String name = 'Tovar',
}) {
  final double p = price ?? realPrice;
  return ReceiptModelSoldItem4(
    inBox: 0,
    barcode: kBarcode,
    sku: 1,
    vatPercent: vatPercent,
    vat: p == 0 ? 0 : (p * vatPercent) / (100 + vatPercent),
    mxik: kMxik,
    tin: '',
    onlyPrice: realPrice,
    realPrice: realPrice,
    price: p,
    cost: 0,
    vatName: 'НДС ${vatPercent.toStringAsFixed(0)}%',
    createdTime: DateTime.now().millisecondsSinceEpoch,
    value: value,
    productId: productId,
    productName: name,
    sellerId: kCashierId,
    soldBy: kCashierId,
    singleDiscount: realPrice - p,
    ownerType: 1,
    packageCode: '1512199',
    packageName: 'dona',
  );
}

ReceiptModelPaymentType4 cash(double v) =>
    ReceiptModelPaymentType4(name: 'CASH', payId: 'cash', value: v);

/// Do'kon bonusi (cashback). `saleOnOFD` uni `payId == PrefKeys.cashbackId`
/// bo'yicha taniydi va qatorlar bo'ylab `Other` ga taqsimlaydi.
ReceiptModelPaymentType4 cashback(double v) =>
    ReceiptModelPaymentType4(name: 'Cashback', payId: kCashbackPayId, value: v);

ReceiptModel4 receiptWith(
  List<ReceiptModelSoldItem4> rows, {
  List<ReceiptModelPaymentType4>? payments,
  bool isRefund = false,
}) {
  double total = 0;
  for (final r in rows) {
    total += r.price * r.value;
  }
  final r = ReceiptModel4(
    createdDate: '2026-09-24 12:00:00',
    orderId: 'order-1',
    cashboxId: 'cashbox-1',
    externalId: 'DN-1',
    orderType: isRefund ? 'refund' : 'sale',
    shopId: 'shop-1',
    userId: kUserId,
    discountVat: 0,
    discountID: '',
    newid: '',
    cashierId: kCashierId,
    cashierName: kCashierName,
    date: DateTime.now().millisecondsSinceEpoch,
    isRefund: isRefund,
    totalPrice: total,
    uploaded: false,
    rejected: false,
    clientName: '',
    clientPhone: '',
    clientId: '',
    supplierId: '',
    cashback: 0,
    sdacha: 0,
    returnForCheck: isRefund ? 'DN-0' : '',
    posName: 'Test POS',
    isDonate: false,
    refundInfo: isRefund
        ? jsonEncode(Info(
            terminalId: kTerminal,
            receiptSeq: '101',
            dateTime: '20260924120000',
            fiscalSign: '600000000101',
            qrCodeUrl: 'https://ofd.soliq.uz/check?t=$kTerminal&r=101',
          ).toJson())
        : null,
  );
  r.soldItemList.addAll(rows);
  r.payment.addAll(payments ?? [cash(total)]);
  return r;
}

/// `LocalService.saleWithOutIncom` bilan bir xil zanjir — tarmoqsiz.
Map<String, dynamic> wireJson(ReceiptModel4 receipt) {
  final Map<String, dynamic> ofdBody = ReceiptSingleton4.saleOnOFD(receipt);
  final RequestSaleModel model = RequestSaleModel.fromJson(ofdBody);
  final fiscal = FiscalReceiptModel.fromRequest(
    model,
    ReceiptDataModel(
      factoryID: kFactory,
      terminalID: kTerminal,
      location: Location(latitude: 41.311081, longitude: 69.240562),
    ),
    DateTime(2026, 9, 24, 12, 0, 0),
    ExtraInfo(
      carNumber: '',
      phoneNumber: '',
      cardType: 0,
      pinfl: '',
      tin: '',
      qrPaymentID: '',
      qrPaymentProvider: 0,
      cardNumber: '',
      pptId: '',
      cashedOutFromCard: 0,
    ),
  );
  return jsonDecode(jsonEncode(fiscal.toJson())) as Map<String, dynamic>;
}

Map<String, dynamic> receiptOf(Map<String, dynamic> wire) =>
    wire['params']['Receipt'] as Map<String, dynamic>;

List<Map<String, dynamic>> itemsOf(Map<String, dynamic> wire) =>
    (receiptOf(wire)['Items'] as List).cast<Map<String, dynamic>>();

/// Modul kutadigan VAT: trunc((Price − Discount − Other) × p / (100 + p)).
/// Transformatsiya kasrni `.toInt()` bilan kesadi, shuning uchun floor.
num netVat(Map<String, dynamic> it) {
  final num p = it['VATPercent'] as num;
  if (p == 0) return 0;
  final num base = (it['Price'] as num) -
      (it['Discount'] as num) -
      (it['Other'] as num? ?? 0);
  final num v = base * p / (100 + p);
  return v < 0 ? 0 : v.floor();
}

/// Har qatorda VAT aynan net bazadan (±1 tiyin yaxlitlash).
void expectVatFromNet(Map<String, dynamic> wire) {
  for (final it in itemsOf(wire)) {
    expect(it['VAT'], closeTo(netVat(it), 1),
        reason:
            '${it['Name']}: VAT=(Price−Discount−Other)×p/(100+p) bo\'lishi kerak '
            '(Price=${it['Price']} Discount=${it['Discount']} Other=${it['Other']})');
  }
}

/// §10.2.1: Σ(Price − Discount) == ReceivedCash + ReceivedCard + ΣOther,
/// har qatorda Other + Discount ≤ Price.
void expectBalanced(Map<String, dynamic> wire) {
  final receipt = receiptOf(wire);
  num left = 0, other = 0;
  for (final it in itemsOf(wire)) {
    left += (it['Price'] as num) - (it['Discount'] as num);
    other += (it['Other'] as num? ?? 0);
    expect((it['Other'] as num? ?? 0) + (it['Discount'] as num),
        lessThanOrEqualTo(it['Price'] as num),
        reason: 'per-item: Other + Discount ≤ Price');
  }
  final right = (receipt['ReceivedCash'] as num) +
      (receipt['ReceivedCard'] as num) +
      other;
  expect(left, right, reason: '§10.2.1 balans');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('fiscal_vat_base', withEmployee: false);
    await Pref.setString(PrefKeys.mxikCode, kMxik);
    await Pref.setString(PrefKeys.cashbackId, kCashbackPayId);
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() {
    ItemsSingleton.products = [product('p-1'), product('p-2')];
  });
  tearDown(() => ItemsSingleton.products = []);

  group('QQS bazasi: chegirma (Discount)', () {
    test('50 000 so\'m, 30 000 chegirma → QQS 20 000 dan (2 143), 50 000 dan emas',
        () {
      final wire = wireJson(receiptWith([row(realPrice: 50000, price: 20000)]));
      final it = itemsOf(wire).single;

      expect(it['Price'], 5000000, reason: 'chegirmasiz, tiyinda');
      expect(it['Discount'], 3000000);
      expect(it['Other'], 0);
      expect(it['VATPercent'], 12);
      // 2 000 000 × 12 / 112 = 214 285.71 → 214 285 tiyin = 2 143 so'm
      expect(it['VAT'], closeTo(214285, 1));
      // Eski (xato) qiymat: 5 000 000 × 12 / 112 = 535 714
      expect(it['VAT'], isNot(closeTo(535714, 1)),
          reason: 'chegirmasiz narxdan QQS ketmasligi kerak');
      expect(receiptOf(wire)['ReceivedCash'], 2000000);
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('rasmiy FiscalDriveService misoli: Price 100000, Discount 50000 → VAT 5357',
        () {
      // 1 000 so'm tovar 500 so'm chegirma bilan
      final wire = wireJson(receiptWith([row(realPrice: 1000, price: 500)]));
      final it = itemsOf(wire).single;
      expect(it['Price'], 100000);
      expect(it['Discount'], 50000);
      expect(it['VAT'], 5357);
      expectBalanced(wire);
    });

    test('chegirmasiz tovar: QQS o\'zgarmaydi (Price × 12 / 112)', () {
      final wire = wireJson(receiptWith([row(realPrice: 4000)]));
      final it = itemsOf(wire).single;
      expect(it['Price'], 400000);
      expect(it['Discount'], 0);
      expect(it['VAT'], closeTo(42857, 1));
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('miqdor > 1: Discount va QQS qator bo\'yicha', () {
      final wire =
          wireJson(receiptWith([row(realPrice: 50000, price: 20000, value: 3)]));
      final it = itemsOf(wire).single;
      expect(it['Amount'], 3000);
      expect(it['Price'], 15000000);
      expect(it['Discount'], 9000000);
      // 6 000 000 × 12 / 112 = 642 857.14
      expect(it['VAT'], closeTo(642857, 1));
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('100% chegirma (sovg\'a): Discount = Price, VAT 0', () {
      final wire = wireJson(receiptWith([row(realPrice: 50000, price: 0)]));
      final it = itemsOf(wire).single;
      expect(it['Price'], 5000000);
      expect(it['Discount'], 5000000);
      expect(it['VAT'], 0);
      expectBalanced(wire);
    });

    test('QQS 0% tovar: chegirma bo\'lsa ham VAT 0, VATPercent 0', () {
      final wire = wireJson(
          receiptWith([row(realPrice: 50000, price: 20000, vatPercent: 0)]));
      final it = itemsOf(wire).single;
      expect(it['VATPercent'], 0);
      expect(it['VAT'], 0);
      expect(it['Discount'], 3000000);
      expectBalanced(wire);
    });

    test('vozvrat: chegirmali qator QQS\'i ham chegirmadan keyingi', () {
      final wire = wireJson(
          receiptWith([row(realPrice: 50000, price: 20000)], isRefund: true));
      expect(wire['method'], 'Api.SendRefundReceipt');
      final it = itemsOf(wire).single;
      expect(it['Price'], 5000000);
      expect(it['Discount'], 3000000);
      expect(it['VAT'], closeTo(214285, 1));
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('ko\'p qatorli chek: chegirmali va chegirmasiz qatorlar mustaqil', () {
      final wire = wireJson(receiptWith([
        row(realPrice: 50000, price: 20000, name: 'Chegirmali'),
        row(realPrice: 30000, value: 2, productId: 'p-2', name: 'Oddiy'),
      ]));
      final items = itemsOf(wire);
      final a = items.firstWhere((e) => e['Name'] == 'Chegirmali');
      final b = items.firstWhere((e) => e['Name'] == 'Oddiy');
      expect(a['VAT'], closeTo(214285, 1));
      expect(b['Discount'], 0);
      expect(b['VAT'], closeTo(642857, 1), reason: '6 000 000 × 12 / 112');
      expect(receiptOf(wire)['ReceivedCash'], 8000000);
      expectVatFromNet(wire);
      expectBalanced(wire);
    });
  });

  group('QQS bazasi: cashback (Other) — xaridordan olinmagan pul', () {
    test('100% cashback: Other = Price, VAT 0', () {
      final wire = wireJson(receiptWith(
        [row(realPrice: 50000)],
        payments: [cashback(50000)],
      ));
      final it = itemsOf(wire).single;
      expect(it['Price'], 5000000);
      expect(it['Other'], 5000000);
      expect(it['VAT'], 0);
      expect(receiptOf(wire)['ReceivedCash'], 0);
      expect(receiptOf(wire)['ReceivedCard'], 0);
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('qisman cashback + naqd: QQS faqat naqd qismidan', () {
      final wire = wireJson(receiptWith(
        [row(realPrice: 50000)],
        payments: [cashback(20000), cash(30000)],
      ));
      final it = itemsOf(wire).single;
      expect(it['Other'], 2000000);
      // 3 000 000 × 12 / 112 = 321 428.57
      expect(it['VAT'], closeTo(321428, 1));
      expect(receiptOf(wire)['ReceivedCash'], 3000000);
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('chegirma + qisman cashback: baza = Price − Discount − Other', () {
      // 50 000 → 20 000 chegirma bilan; 5 000 cashback + 15 000 naqd
      final wire = wireJson(receiptWith(
        [row(realPrice: 50000, price: 20000)],
        payments: [cashback(5000), cash(15000)],
      ));
      final it = itemsOf(wire).single;
      expect(it['Price'], 5000000);
      expect(it['Discount'], 3000000);
      expect(it['Other'], 500000);
      // 1 500 000 × 12 / 112 = 160 714.28
      expect(it['VAT'], closeTo(160714, 1));
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('chegirma + 100% cashback: Other + Discount == Price, VAT 0', () {
      final wire = wireJson(receiptWith(
        [row(realPrice: 50000, price: 20000)],
        payments: [cashback(20000)],
      ));
      final it = itemsOf(wire).single;
      expect(it['Discount'], 3000000);
      expect(it['Other'], 2000000);
      expect((it['Other'] as num) + (it['Discount'] as num), it['Price']);
      expect(it['VAT'], 0);
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('ko\'p qatorli: cashback qatorlarga ulushi bo\'yicha, har qator VAT o\'z netidan',
        () {
      // A: 50 000 → 20 000 (net 20 000); B: 30 000 × 2 = 60 000. Jami 80 000.
      // Cashback 16 000 (20%) → A ga 4 000, B ga 12 000. Naqd 64 000.
      final wire = wireJson(receiptWith(
        [
          row(realPrice: 50000, price: 20000, name: 'A'),
          row(realPrice: 30000, value: 2, productId: 'p-2', name: 'B'),
        ],
        payments: [cashback(16000), cash(64000)],
      ));
      final items = itemsOf(wire);
      final a = items.firstWhere((e) => e['Name'] == 'A');
      final b = items.firstWhere((e) => e['Name'] == 'B');
      expect(a['Other'], 400000);
      expect(b['Other'], 1200000);
      // A: (5 000 000 − 3 000 000 − 400 000) × 12 / 112 = 171 428.57
      expect(a['VAT'], closeTo(171428, 1));
      // B: (6 000 000 − 0 − 1 200 000) × 12 / 112 = 514 285.71
      expect(b['VAT'], closeTo(514285, 1));
      expect(receiptOf(wire)['ReceivedCash'], 6400000);
      expectVatFromNet(wire);
      expectBalanced(wire);
    });
  });

  group('_enforce1021Balance tuzatishlaridan keyin ham VAT net bazadan', () {
    test('per-item qirqish: cashback net\'dan oshsa Other = Price − Discount, VAT 0',
        () {
      // Net 20 000, cashback 20 001 (yaxlitlash oqibati) → Other qirqiladi.
      final wire = wireJson(receiptWith(
        [row(realPrice: 50000, price: 20000)],
        payments: [cashback(20001)],
      ));
      final it = itemsOf(wire).single;
      expect(it['Other'], 2000000,
          reason: 'Other ≤ Price − Discount ga qirqiladi');
      expect(it['VAT'], 0);
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('residual > 0 (tarozi yarim so\'m): Price kamayadi, VAT qayta hisoblanadi',
        () {
      // 0.29 × 77 950 = 22 605.5 → Price 22 606 ga yuqoriga yaxlitlanadi,
      // to'lov 22 605 (pastga). Chegirma bilan (80 000 → 77 950).
      final wire = wireJson(receiptWith(
        [row(realPrice: 80000, price: 77950, value: 0.29)],
        payments: [cashback(22605)],
      ));
      final it = itemsOf(wire).single;
      expect(it['VAT'], 0, reason: '100% cashback → QQS bazasi 0');
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('residual < 0 (to\'lov 1 so\'m ko\'p): Other kamayadi, VAT netdan', () {
      // 50 000 tovar, cashback 20 000 + naqd 30 001.
      final wire = wireJson(receiptWith(
        [row(realPrice: 50000)],
        payments: [cashback(20000), cash(30001)],
      ));
      final it = itemsOf(wire).single;
      expect(it['Other'], 1999900);
      // (5 000 000 − 1 999 900) × 12 / 112 = 321 439.28
      expect(it['VAT'], closeTo(321439, 1));
      expectVatFromNet(wire);
      expectBalanced(wire);
    });
  });
}
```

</details>

## 7. Tekshirish

- `flutter test test/fiscal_vat_base_test.dart` — 18/18; to'liq to'plam 1212/1212 (2026-09-24).
- Do'kon sinovi (Windows, haqiqiy fiskal modul): chegirmali tovar sotib ofd.soliq.uz chekida QQS chegirmadan keyingi narxdan ekanini tekshirish; chegirma + cashback aralash chek; vozvrat — KUTILMOQDA.

## 8. Eslatmalar va ochiq savollar

- Click/Payme/Uzum hozir `Other` orqali ketadi (QQS 0) — rasmiy talab `ReceivedCard` + `QRPayment*`. Alohida task: `docs/fiskal-tolov-turlari-va-qqs.md` §6.1.
- Qog'oz chek, ekran va server `order_pos.vat` cashback ulushini ayirmaydi (chegirmani ayiradi). Bu fix'dan keyin chegirma bo'yicha fiskal va chek mos; cashback bo'yicha hali farq bor: `docs/fiskal-tolov-turlari-va-qqs.md` §4.2.

---

# 6-TASK — Notification (polling) sinxron tirqichlari: server soati, buzuq notification, timeout, qulf (1.1.2+127)

> **Commit:** `bfc4929`, `02ab30e`, `e85c52e`, `03a9227`, `c264890`, `80f88d7` (2026-09-24), reliz `36a2f6f`/`7e01ce8` 1.1.2+127.
> **Sessiya hujjati:** docs/sessions/2026-09-24-ws-notification-gap-audit.md
> **Holat 2026-09-24:** Relizda (1.1.2+127, PRO backendga yuklangan). To'liq test to'plami 1357/1357 (bu ish + 5-task birga). Do'kon sinovi kutilmoqda.

## 1. Nima va nima uchun

Adminkada qilingan o'zgarish (yangi mahsulot, narx, kategoriya, diskont) kassaga faqat qo'lda "to'liq yangilash"dan keyin yetib borardi. Muhim fakt: **WebSocket butunlay o'chiq** (`connectWebSocket` hech qayerdan chaqirilmaydi, barcha chaqiruv joylari kommentda). "WS notification" deb ataladigan narsa aslida har 1 daqiqada `GET ws.notification.7i.uz/notifications?...start_date&end_date` **polling** (2026-08-12 taskidan qolgan mexanizm — `SyncCursor`/`StreamSyncRunner`/`CatchUpSync`, bu hujjatdan TASHQARIDAgi eski task). Ya'ni "xabar yo'qolishi" = polling oynasi noto'g'ri hisoblanishi yoki qo'llashdagi xato, tarmoq emas.

Ko'p-agentli workflow bilan 46 real stsenariy (oflayn N kun, internet uzilishi turlari, soat sakrashi, poyga holatlari, server holatlari, buzuq payload'lar) kod bo'ylab qadam-baqadam kuzatildi, har xulosa 2-3 mustaqil skeptik tomonidan qayta tekshirildi. Natija: 36 ta haqiqiy tirqich (G1-G14 dastlabki bosqichda, +10 tasdiqlangan qo'shimcha ikkinchi bosqichda) topildi va yopildi. Eng jiddiylari:

- **Kassa soati serverdan 2+ daqiqa OLDINDA** bo'lsa (Windows'da noto'g'ri timezone) kursor "server kelajagi"ga yozilardi — server vaqti bo'yicha oradagi notification'lar HECH QACHON so'ralmasdi.
- **Bitta buzuq notification** (`images: []` → RangeError, `category_ids: null` → TypeError) butun oynani `failed` qilib, kursor joyida qolardi — 14 kungacha yoki qo'lda to'liq yangilashgacha HECH NARSA (narx ham) yangilanmasdi.
- **KRITIK, ikkinchi audit bosqichida o'z-o'zidan topilgan regressiya:** shu ish davomida qo'shilgan avto-sinxron halqasi (`unawaited(updateProvider.autoUpdate(context, mounted))`, wrapper.dart) Wrapper'ning tezda unmount bo'ladigan context'i bilan ishga tushirilgan edi — halqa birinchi tsikldayoq abadiy o'lardi va `_autoUpdateRunning` bayrog'i band bo'lib, TO'G'RI (NetworkSuccess) chaqiruvni ham bloklardi. Ya'ni butun sessiya davomida avtomatik sinxron umuman ishlamasligi mumkin edi.

Yechim: kursor mexanizmi server vaqtiga, xatoga chidamli qo'llashga va haqiqiy timeout/bekor qilishga asoslangan holda qayta quriladi; barcha to'liq yuklash yo'llari bitta qulf ostiga olinadi; avto-sinxron halqasi doimiy yashovchi context'dan foydalanadi.

## 2. Qanday ishlaydi (oqim; eski vs yangi)

**Eski:** har chaqiruv o'z vaqt oynasini o'zi hisoblardi (`DateTime.now()`, `lastSyncTime - 5 daqiqa`); natija tekshirilmasdi — muvaffaqiyatsiz bo'lsa ham oyna oldinga surilib, o'sha davr abadiy o'tkazib yuborilardi; umumiy 20s timeout (sekin internetda hech qachon yetmasdi); bitta notification xatosi butun oynani yiqitardi; `is_active`/`shop_prices` maydonlari noto'g'ri talqin qilinib mahsulot narxsiz yoki o'chirilgan holga tushardi; kategoriya to'liq yuklash `box.addAll` bilan dublikat yaratardi.

**Yangi oqim:**
```
UpdateProvider.autoUpdate (har 1 daqiqa, AppNavigation.navigatorKey.currentContext bilan — doimiy yashovchi)
  → CatchUpSync.run (bir vaqtda bitta; qulf; company/store id tekshiruvi; healCatalogState)
    → StreamSyncRunner (kategoriya → mahsulot → diskont, bu tartibda)
      → SyncCursor.needsFullReload? (kursor yo'q / 14 kundan eski / server vaqtidan overlap'dan ko'p KEYIN — soat sakragan)
        → HA: to'liq yuklash (backoff 5 daqiqa; timeout 15 daqiqa, chinakam bekor qilinadi)
        → YO'Q: SyncWindow.split (≤6 soatlik bo'laklar, bo'laklar orasida ham 2 daqiqalik overlap)
          → NotificationFetch.run (bitta GET; created_at bo'yicha barqaror tartiblash;
             har notification alohida try/catch — applyFailed bo'lsa oyna to'liq yuklash bilan qoplanadi;
             total_count tekshiriladi — server sahifa cheklovi bo'lsa ham kesilish aniqlanadi)
            → kursor FAQAT muvaffaqiyatli, ServerClock bilan cheklangan (`clamp`) qiymatga suriladi
```
Kursor hech qachon orqaga surilmaydi (`SyncCursor.commit` monoton; `force:true` faqat to'liq yuklashda). Qulf majburan olinganda (`exclusive`, stale-lock, logout epoch) eski jarayon `shouldContinue` orqali keyingi fetch/commit oldidan o'zini tekshiradi va hech narsa yozmasdan to'xtaydi.

## 3. O'zgarishlar ro'yxati

| Fayl | Tur | Nima |
|---|---|---|
| `lib/changes/services/sync/server_clock.dart` | YANGI | Server soati — HTTP `date` sarlavhasidan host bo'yicha (notification/api) o'rganiladi, Pref'da saqlanadi |
| `lib/changes/services/sync/notification_fetch.dart` | YANGI | Uchala oqim uchun yagona `GET /notifications` — xatoga chidamli qo'llash, tartiblash, timeout, total_count |
| `lib/changes/services/sync/sync_cursor.dart` | o'zgargan | Monoton commit, server-vaqt clamp, moslashuvchan bo'lak (chunk), to'liq yuklash backoff, sxema migratsiyasi |
| `lib/changes/services/sync/stream_sync_runner.dart` | o'zgargan | `shouldContinue`/`beforeCommit`/`onFullReloadTimeout` parametrlari, server-hozir-ga yetganda to'xtash, 401 ishlov |
| `lib/changes/services/sync/catch_up_sync.dart` | o'zgargan | Ticket-based qulf (epoch, stale takeover), `healCatalogState`, `exclusive`/`tryExclusive`, config tekshiruvi |
| `lib/changes/services/web_socket_service/product/products_ws_service.dart` | o'zgargan | `NotificationFetch` ustiga qayta yozildi; type 0/3/13 xavfsiz; tiriltirish himoyasi; `categoriesFromIds` |
| `lib/changes/services/web_socket_service/category/categories_ws_service.dart` | o'zgargan | `NotificationFetch` ustiga qayta yozildi |
| `lib/changes/services/web_socket_service/discount/discount_ws_service.dart` | o'zgargan | `NotificationFetch` ustiga qayta yozildi, `await` qo'shildi |
| `lib/changes/services/web_socket_service/urls/urls.dart` | o'zgargan | DEV/PRO endi `ApiProvider.currentEnv`dan hisoblanadi (mustaqil konstanta emas) |
| `lib/features/get_products/singletons/items_singleton.dart` | o'zgargan | `clearAndPutItems` atomik (putAll+deleteAll+preserveIds), `putItems` merge (priceKeyPresent), `parseCatalog` |
| `lib/changes/models/product/item_model.dart` | o'zgargan | Xavfsiz `images`/`categories`/`vat`/`measurement_unit`/tier parserlari, `ownerType` type-1'da ham |
| `lib/changes/providers/update_provider.dart` | o'zgargan | Halqa `AppNavigation.navigatorKey.currentContext` bilan (KRITIK tuzatish), `try/catch` |
| `lib/app/wrapper/wrapper.dart` | o'zgargan | `_syncCatalogOnStartup` qulf ostida, ikkinchi 43MB yuklanishni oldini oladi, `autoUpdate` shartsiz boshlanadi |
| `lib/changes/dialogs/upd/bloc/upd_bloc.dart` | o'zgargan | `CatchUpSync.exclusive` ostida, server-vaqt kursor commit |
| `lib/features/drawer/features/update/sync/bloc/sync_bloc.dart` | o'zgargan | `toHive`/`_category` endi `ItemsSingleton.clearAndPutItems`/`CategoryService.category()`ga delegatsiya |
| `lib/features/get_categories/service/category_service.dart` | o'zgargan | type 10/11/12 id bo'yicha upsert (idempotent), write-then-delete atomiklik |
| `lib/changes/services/catalog_refresh_notice.dart` | o'zgargan | "Yangilash" dialogi `CatchUpSync.exclusive` ostida, `clearPending()` |
| `lib/changes/services/discount_auto_sync_service.dart` | o'zgargan | `CatchUpSync.tryExclusive` bilan serializatsiya |
| `lib/utils/helpers/auth_reset.dart` | o'zgargan | Logout `CatchUpSync.exclusive` ostida + `epoch` |
| `lib/utils/util_functions.dart` | o'zgargan | `parseCatalog` orqali xavfsiz parse, muvaffaqiyatda kursor commit |
| `lib/changes/services/get_items_service.dart` | o'zgargan | Ulanish/sukut timeout, isolate'da decode, haqiqiy bekor qilish (`cancelCatalogDownload`) |
| `lib/changes/services/api/api_provider.dart` | o'zgargan | `ServerClock.observeHeaders` hook (host: api) |
| `lib/changes/services/health/backend_health.dart` | o'zgargan | `isDocumentRejection`: 401/403/408/429 endi rad etish emas |
| `lib/features/get_products/soliq/tasnif_service.dart` | o'zgargan | `getPackageCodes` so'roviga 15s timeout |
| `lib/main.dart` | o'zgargan | `SyncCursor.migrateIfNeeded()` startup'da |
| `lib/utils/constants/pref_keys.dart` | o'zgargan | `serverClockOffsetMs`, `syncCursorSchema`, `catalogWriteInProgress` |
| `test/server_clock_test.dart` | YANGI | 9 test |
| `test/notification_fetch_test.dart` | YANGI | ~24 test |
| `test/items_singleton_notification_test.dart` | YANGI | ~25 test |
| `test/category_ws_idempotent_test.dart` | YANGI | 6 test |
| `test/stream_sync_runner_test.dart` | o'zgargan | ~60 test (asosiy fayl, kursor kafolati) |
| `test/items_bulk_write_test.dart` | o'zgargan | +2 test (`preserveIds`) |
| `test/backend_health_test.dart` | o'zgargan | `isDocumentRejection` yangi guruh |

## 4. Bog'liqliklar (InVan 1 uchun muhim)

- **`SyncCursor`, `StreamSyncRunner`, `CatchUpSync`, `SyncFetchResult` sinflarining ASOSI bu taskdan TASHQARIDA** — 2026-08-12 "Ko'p kassa narx sinxron gap'i" taskidan (`docs/sessions/archive/2026-08-12-multi-kassa-price-sync-gap.md`, reliz 1.1.2+118 — bu port-changelog 2026-09-10dan boshlanadi, shuning uchun o'sha task bu faylda YO'Q). **InVan 1'da bu 4 sinf umuman bo'lmasa, AVVAL o'sha taskni alohida portlash kerak**, so'ng shu 6-taskni. Muqobil: quyidagi 6.3/6.4/6.5 diff'lari juda katta (ular deyarli qayta yozilgan) — InVan 2 repo'si qo'lda bo'lsa, diff qo'llash o'rniga to'g'ridan-to'g'ri `git show 7e01ce8:lib/changes/services/sync/<fayl>` bilan TO'LIQ faylni olib qo'yish osonroq va xavfsizroq.
- `AppNavigation.navigatorKey` — umumiy `GlobalKey<NavigatorState>` pattern, `MaterialApp(navigatorKey: ...)`. InVan 1'da boshqa nom bilan bo'lishi mumkin — `update_provider.dart`dagi `autoUpdate` shunga moslashtirilsin (muhim: bu KRITIK tuzatishning o'zagi — halqa har tsiklda FRESH, doimiy yashovchi context olishi shart, boshlagan widget'ning emas).
- `HiveBoxes.getProducts()/.getCategories()/.getDiscounts()`, `CategorySingleton`, `DiscountService`, `DiscountAutoSyncService`, `BackendHealth`, `OrdersService` (`get_items_service.dart`), `TasnifService`, `ItemModel`/`ShopPrices`/`ShID`/`ShopPriceTiers`/`MeasurementUnit`/`Vat`/`CategoriesFromProducts` — mavjud InVan 1 sinflari bilan nom/maydon darajasida solishtirilishi kerak; bu taskda ular O'ZGARTIRILDI (item_model.dart, items_singleton.dart), yangi qo'shilmadi.
- `Isolate.run` (`get_items_service.dart`) — Dart SDK 2.19+ kerak (pubspec: `>=2.19.2`); InVan 1'da SDK versiyasini tekshiring.

## 5. Qo'llash tartibi

1. **Old:** InVan 1'da `SyncCursor`/`StreamSyncRunner`/`CatchUpSync`/`SyncFetchResult` bormi tekshiring (4-band, yuqorida). Yo'q bo'lsa avval 2026-08-12 taskini portlang (yoki shu 4 faylni InVan 2'dan to'g'ridan-to'g'ri ko'chiring: `sync_cursor.dart`, `stream_sync_runner.dart`, `catch_up_sync.dart`).
2. `server_clock.dart` va `notification_fetch.dart` ni YANGI fayl sifatida qo'shing (6.1, 6.2) — boshqa hech nimaga bog'liq emas, birinchi bo'lib qo'shilishi mumkin.
3. `sync_cursor.dart`, `stream_sync_runner.dart`, `catch_up_sync.dart` ustiga diff qo'llang (6.3-6.5) — bular `server_clock.dart`/`notification_fetch.dart`ga bog'liq.
4. Uchta `*_ws_service.dart` (6.6-6.8) — `notification_fetch.dart`ga bog'liq.
5. `urls.dart` (6.9) — mustaqil, kichik.
6. `items_singleton.dart`, `item_model.dart` (6.10-6.11) — katalog modeli; boshqa hamma narsadan oldin yoki keyin qo'llash mumkin, lekin `products_ws_service.dart` bunga bog'liq (3-qadamdan oldin qo'llash tavsiya etiladi, amalda tartib muhim emas — Dart compile-time xato bermaydi, faqat runtime xulq).
7. `update_provider.dart` (6.12) — **KRITIK qismni alohida diqqat bilan ko'ring**: `AppNavigation.navigatorKey.currentContext` qatori. InVan 1'da bu xato mavjud bo'lmasligi mumkin (agar `autoUpdate` faqat barqaror context'dan chaqirilsa) — lekin himoya baribir foydali.
8. Qolgan integratsiya fayllari (6.13-6.26) — har biri mustaqil, tartib muhim emas.
9. Testlarni ko'chiring (6.27-6.33); `test/support/provider_harness.dart` kerak (5-band, "Boshqa nusxada Claude uchun ko'rsatma" bo'limiga qarang).
10. `flutter analyze` va `flutter test`.

## 6. Kod

Diff bazasi: `3a3afdf` (2026-09-24, ushbu taskdan oldingi oxirgi commit) → `7e2d6e9` (2026-09-24, reliz + backendga yuklash commiti). Yangi fayllar to'liq holatda `7e2d6e9`dagi ko'rinishida berilgan.

### 6.1. YANGI: `lib/changes/services/sync/server_clock.dart`

```dart
/*
    Server soati.

    Muammo: sinxron oynasi (`start_date`/`end_date`) ham, kursor ham
    kassaning O'Z soati bilan hisoblanardi. Kassa soati serverdan 2 daqiqadan
    ko'proq OLDINDA bo'lsa (Windows'da timezone noto'g'ri qo'yilib soat qo'lda
    "to'g'rilangan" — do'konlarda keng tarqalgan), kursor "server kelajagi"ga
    yoziladi va keyingi oyna o'sha kelajakdan (minus 2 daqiqa) boshlanadi:
    server vaqti bo'yicha oradagi notification'lar HECH QACHON so'ralmaydi.
    Kassa soati ORQADA bo'lsa — har o'zgarish shuncha kechikib keladi.

    Yechim: har HTTP javobidagi `date` sarlavhasidan server bilan farq
    (offset) o'rganiladi va butun sinxron faqat server vaqtida ishlaydi.
    Farq Pref'da saqlanadi — ilova qayta ochilganda birinchi so'rovdanoq
    to'g'ri vaqt ishlatiladi.

    Farq HOST bo'yicha alohida saqlanadi: sinxron soati — notification
    serverniki (ws.notification.7i.uz). API serveri (api.7i.uz) bilan
    ikkalasi soati bir-biridan farq qilsa, API farqi notification
    kursorini "kelajak"ka surib yubormasin. API farqi faqat notification
    farqi hali noma'lum bo'lganda zaxira sifatida ishlatiladi.
*/

import 'dart:async';
import 'dart:io' show HttpDate;

import '../../../utils/constants/pref_keys.dart';
import '../../../utils/helpers/prefs.dart';
import '../log_helper.dart';

class ServerClock {
  ServerClock._();

  static const String hostNotification = 'notification';
  static const String hostApi = 'api';
  static const String _hostPersisted = '_persisted';

  /// Mahalliy soat (UTC). Testlar almashtiradi.
  static DateTime Function() localNow = () => DateTime.now().toUtc();

  /// Shundan katta farq log'ga yoziladi — kassa soatini tuzatish kerakligi
  /// belgisi (fiskal chek vaqtlariga ham ta'sir qiladi).
  static const Duration warnSkew = Duration(minutes: 2);

  /// Pref'ga faqat shundan katta o'zgarishda yoziladi — har daqiqada Hive'ga
  /// yozib o'tirmaslik uchun.
  static const Duration persistThreshold = Duration(seconds: 2);

  static final Map<String, Duration> _offsets = <String, Duration>{};
  static bool _loaded = false;
  static Duration? _lastWarned;
  static bool _missingDateLogged = false;

  static void _load() {
    if (_loaded) return;
    _loaded = true;
    try {
      final Object? v = Pref.getObject(PrefKeys.serverClockOffsetMs);
      if (v is int) _offsets[_hostPersisted] = Duration(milliseconds: v);
    } catch (_) {
      // Pref box hali ochilmagan (juda erta chaqiruv) — noma'lum deb qolamiz,
      // keyingi javobda o'rganiladi.
      _loaded = false;
    }
  }

  /// Server bilan farq kamida bir marta o'lchanganmi (yoki saqlanganmi).
  static bool get isKnown {
    _load();
    return _offsets.isNotEmpty;
  }

  /// Sinxron uchun `server - kassa`: notification serveri; u yo'q bo'lsa
  /// API; u ham yo'q bo'lsa saqlangan qiymat; hech biri yo'q — nol.
  static Duration get offset {
    _load();
    return _offsets[hostNotification] ??
        _offsets[hostApi] ??
        _offsets[_hostPersisted] ??
        Duration.zero;
  }

  /// Hozirgi vaqt — server soati bo'yicha (UTC).
  static DateTime nowUtc() => localNow().add(offset);

  /// Mahalliy vaqtni server vaqtiga o'tkazadi.
  static DateTime toServer(DateTime local) => local.toUtc().add(offset);

  /// HTTP javob sarlavhalaridan server vaqtini o'qiydi va farqni yangilaydi.
  ///
  /// Qaytadi: server vaqti (UTC) yoki sarlavha bo'lmasa/buzuq bo'lsa null.
  static DateTime? observeHeaders(Map<String, String> headers,
      {String host = hostNotification}) {
    final String? raw = headers['date'] ?? headers['Date'];
    DateTime? server;
    if (raw != null && raw.isNotEmpty) {
      try {
        server = HttpDate.parse(raw).toUtc();
      } catch (_) {
        server = null;
      }
    }
    if (server == null) {
      if (!_missingDateLogged) {
        // Proxy sarlavhani olib tashlagan/buzgan — kassa soatiga tayanib
        // qolamiz; buni bir marta ko'rinadigan qilamiz.
        _missingDateLogged = true;
        unawaited(LogHelper.activity(
            'SYNC_SERVER_DATE_MISSING', {'host': host, 'raw': raw}));
      }
      return null;
    }
    observe(server, host: host);
    return server;
  }

  /// Server vaqti ma'lum bo'lganda farqni yangilaydi.
  ///
  /// [local] — javob olingan mahalliy vaqt; berilmasa hozir. Bir soniyalik
  /// aniqlik yetarli: sinxron oynasida 2 daqiqalik overlap bor.
  static void observe(DateTime serverUtc,
      {DateTime? local, String host = hostNotification}) {
    _load();
    final DateTime at = (local ?? localNow()).toUtc();
    final Duration fresh = serverUtc.toUtc().difference(at);
    final Duration before = offset;
    _offsets[host] = fresh;
    final Duration after = offset;
    if ((after - before).abs() >= persistThreshold ||
        !_offsets.containsKey(_hostPersisted)) {
      _offsets[_hostPersisted] = after;
      unawaited(_persist(after));
    }
    _maybeWarn(after);
  }

  static Future<void> _persist(Duration value) async {
    try {
      await Pref.setInt(PrefKeys.serverClockOffsetMs, value.inMilliseconds);
    } catch (_) {
      // Ilova yopilayotganda (Hive.close) yozuv yiqilishi mumkin — bu
      // sinxronga ta'sir qilmasligi kerak.
    }
  }

  static void _maybeWarn(Duration skew) {
    if (skew.abs() < warnSkew) {
      _lastWarned = null;
      return;
    }
    // Bir xil farqni har daqiqada yozmaymiz — faqat o'zgarganda.
    final Duration? last = _lastWarned;
    if (last != null && (skew - last).abs() < const Duration(minutes: 1)) {
      return;
    }
    _lastWarned = skew;
    unawaited(LogHelper.activity('SYNC_CLOCK_SKEW', {
      // Musbat = kassa soati serverdan OLDINDA.
      'kassa_minus_server_s': -skew.inSeconds,
      'note': 'kassa soati/timezone tekshirilsin',
    }));
  }

  /// Faqat testlar uchun: xotiradagi holatni tozalaydi (Pref'ga tegmaydi).
  static void reset() {
    _offsets.clear();
    _loaded = false;
    _lastWarned = null;
    _missingDateLogged = false;
  }
}
```

### 6.2. YANGI: `lib/changes/services/sync/notification_fetch.dart`

```dart
/*
    Bitta `GET /notifications` so'rovi va uning qo'llanishi — uchala oqim
    (mahsulot, kategoriya, diskont) uchun yagona kod.

    Ilgari uch xizmat bir xil kodni ko'chirib yurardi va hammasida bir xil
    tirqichlar bor edi:

      * bitta notification parse bo'lmasa (masalan `images: []`,
        `category_ids: null`) BUTUN oyna `failed` bo'lardi → kursor joyida
        qolardi → har daqiqa o'sha xato → 14 kungacha yoki qo'lda to'liq
        yangilashgacha HECH NARSA (narx ham) yangilanmasdi;
      * xato faqat debug'da print bo'lardi — do'konda izsiz;
      * notification'lar server bergan tartibda qo'llanardi (asc/desc
        noma'lum) — eski `create` yangi `update` ustidan yozishi mumkin edi;
      * server vaqti (HTTP `date`) o'qilmasdi — kassa soati oldinda bo'lsa
        kursor kelajakka ketardi;
      * 20 s UMUMIY timeout — sekin internetda katta javob hech qachon
        sig'masdi.

    Endi: har notification alohida himoyada, xatolik log'ga yoziladi va
    natijada `applyFailed` bayrog'i qaytadi (StreamSyncRunner to'liq yuklash
    bilan qoplaydi); `created_at` bo'yicha tartiblanadi; server vaqti
    natijada qaytadi; timeout — sarlavha kutish + bo'laklar orasidagi sukut
    (umumiy chegara yo'q, sekin bo'lsa ham oqib kelaveradi).
*/

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../alice_service.dart';
import '../../../utils/constants/pref_keys.dart';
import '../../../utils/helpers/prefs.dart';
import '../log_helper.dart';
import '../web_socket_service/urls/urls.dart';
import 'server_clock.dart';
import 'sync_cursor.dart';

/// Bitta notification'ni qo'llash natijasi.
enum NotifyApply {
  /// Lokal bazaga yozildi — oyna oxirida keshlar yangilanadi.
  applied,

  /// Bu turdagi notification bizga kerak emas (yoki keshga ta'sir qilmaydi).
  ignored,

  /// Qo'llab bo'lmadi va davom etishning ma'nosi yo'q. Oyna muvaffaqiyatsiz
  /// hisoblanadi, kursor surilmaydi, keyingi daqiqada qayta uriniladi.
  abort,

  /// Server "hammasini qayta yukla" dedi (type 0). Oynani qo'llash
  /// to'xtatiladi; runner bitta to'liq yuklash qiladi va kursorni suradi.
  fullReload,
}

typedef ApplyNotification = Future<NotifyApply> Function(
    Map<String, dynamic> ws);

class NotificationFetch {
  NotificationFetch._();

  static const int limit = 1000;

  /// Ulanish va javob sarlavhalarini kutish chegarasi.
  ///
  /// Testlar qisqartiradi (const emas).
  static Duration timeout = const Duration(seconds: 30);

  /// Javob tanasi oqimida ketma-ket ikki bo'lak orasidagi maksimal sukut.
  /// Umumiy chegara emas: sekin internetda katta javob uzoq oqishi mumkin,
  /// muhimi to'xtab qolmasin.
  static Duration idleTimeout = const Duration(seconds: 45);

  /// Log'ga yoziladigan javob tanasining maksimal uzunligi. To'liq tana
  /// (1000 mahsulot — MB'lar) 24 soatlik logni to'ldirib yuborardi;
  /// diagnostika uchun boshlanishi + `SYNC_WINDOW` hisobi yetarli.
  static const int logBodyLimit = 4000;

  /// Testlar uchun almashtiriladigan HTTP klient.
  static http.Client? client;

  static Map<String, String> headers(String token) => <String, String>{
        "timezone": "-300",
        "Vary": "Origin",
        "Strict-Transport-Security": "Strict-Transport-Security",
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Authorization": "Bearer $token",
        // Do'kon tarmog'idagi proxy eski javobni qaytarmasin.
        "Cache-Control": "no-cache, no-store, max-age=0",
        "Pragma": "no-cache",
      };

  /// `is_read=false` — 2026-08-21'da jonli tekshirilgan YAGONA konfiguratsiya
  /// (qarang: docs/sessions/archive/2026-08-21-price-sync-missing-on-some-kassas.md).
  /// Bu parametrni olib tashlash (masalan boshqa klient "o'qildi" deb
  /// belgilasa ham kassa ko'rishi uchun) jozibali, lekin server buni qanday
  /// talqin qilishi TEKSHIRILMAGAN — noto'g'ri taxmin aynan bizni
  /// yo'qotayotgan xato turini (jim, doimiy notification yo'qolishi)
  /// qaytarishi mumkin. Shuning uchun ataylab O'ZGARTIRILMAGAN.
  static String buildPath({
    required String companyId,
    required String types,
    required String startDate,
    required String endDate,
  }) {
    return "${Urls.baseNotificationUrl}notifications?company_id=$companyId&limit=$limit&offset=1&type=$types&is_read=false&start_date=$startDate&end_date=$endDate";
  }

  /// [types] — vergul bilan ajratilgan notification turlari.
  /// [apply] — bitta notification'ni lokalga qo'llaydi; istisno tashlasa
  /// faqat o'sha notification "qo'llanmadi" deb belgilanadi.
  /// [afterBatch] — kamida bitta notification qo'llangan bo'lsa oyna
  /// oxirida BIR marta chaqiriladi (keshlarni yangilash uchun).
  static Future<SyncFetchResult> run({
    required String label,
    required String types,
    required String startDate,
    required String endDate,
    required ApplyNotification apply,
    Future<void> Function()? afterBatch,
  }) async {
    final String token = Pref.getString(PrefKeys.token, 'not initialized');
    if (token.isEmpty || token == 'not initialized') {
      return const SyncFetchResult.failed();
    }

    final String comId = Pref.getString(PrefKeys.orgID, "");
    final String path = buildPath(
        companyId: comId, types: types, startDate: startDate, endDate: endDate);

    final _Fetched fetched = await _get(path, token, label, startDate, endDate);
    if (fetched.result != null) return fetched.result!;

    final http.Response response = fetched.response!;

    await LogHelper.logRequest(
        method: "GET",
        path: path,
        statusCode: response.statusCode,
        response: _shortBody(response.body));
    try {
      alice.onHttpResponse(response);
    } catch (_) {}

    // Server soati — kursor bundan oldinga o'tmaydi.
    final DateTime? serverTime =
        ServerClock.observeHeaders(response.headers, host: ServerClock.hostNotification);

    if (response.statusCode != 200) {
      final bool unauthorized =
          response.statusCode == 401 || response.statusCode == 403;
      await LogHelper.activity(unauthorized ? 'SYNC_UNAUTHORIZED' : 'SYNC_FETCH_HTTP',
          {'stream': label, 'status': response.statusCode});
      return SyncFetchResult.failed(
          serverTime: serverTime, unauthorized: unauthorized);
    }

    List<dynamic> notifications;
    int? totalCount;
    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw const FormatException('javob obyekt emas');
      }
      final dynamic raw = decoded['notifications'];
      if (raw == null &&
          !decoded.containsKey('notifications') &&
          (decoded.containsKey('error') || decoded.containsKey('message'))) {
        // 200 bilan kelgan xato tanasi — bo'sh oyna deb qabul qilinmasin.
        throw FormatException('server xato tanasi: ${_shortBody(response.body, 200)}');
      }
      notifications = raw is List ? raw : const <dynamic>[];
      final dynamic tc = decoded['total_count'];
      if (tc is num) totalCount = tc.toInt();
    } catch (e) {
      await LogHelper.activity(
          'SYNC_FETCH_PARSE', {'stream': label, 'error': e});
      return SyncFetchResult.failed(serverTime: serverTime);
    }

    int applied = 0;
    int ignored = 0;
    int noId = 0;
    bool applyFailed = false;
    bool fullReloadRequested = false;

    final _Sorted sorted = sortByCreatedAtDetailed(notifications);
    if (sorted.unparsed > 0) {
      await LogHelper.activity('SYNC_CREATED_AT_UNPARSED', {
        'stream': label,
        'count': sorted.unparsed,
        'sample': sorted.sample,
      });
    }

    for (final dynamic ws in sorted.list) {
      if (ws is! Map) {
        noId++;
        continue;
      }
      final Map<String, dynamic> m = Map<String, dynamic>.from(ws);
      if (m['id'] == null) {
        noId++;
        continue;
      }

      try {
        final NotifyApply outcome = await apply(m);
        if (outcome == NotifyApply.abort) {
          await LogHelper.activity('SYNC_APPLY_ABORT',
              {'stream': label, 'id': m['id'], 'type': m['type']});
          if (applied > 0 && afterBatch != null) await afterBatch();
          return SyncFetchResult.failed(serverTime: serverTime);
        }
        if (outcome == NotifyApply.fullReload) {
          fullReloadRequested = true;
          break;
        }
        if (outcome == NotifyApply.applied) {
          applied++;
        } else {
          ignored++;
        }
      } catch (e, stack) {
        // Faqat shu notification. Oyna oxirida `applyFailed` bilan
        // qaytadi — StreamSyncRunner to'liq yuklash bilan qoplaydi.
        applyFailed = true;
        await LogHelper.activity('SYNC_APPLY_FAILED', {
          'stream': label,
          'id': m['id'],
          'type': m['type'],
          'error': e,
          'stack': stack,
        });
      }
    }

    if (applied > 0 && afterBatch != null) await afterBatch();

    // Har oyna uchun bitta qisqa qator — "so'ralganmi, nechta kelgan,
    // nechta qo'llangan" savoliga 24 soatlik logdan javob topish uchun.
    await LogHelper.activity('SYNC_WINDOW', {
      'stream': label,
      'start': startDate,
      'end': endDate,
      'received': notifications.length,
      'applied': applied,
      'ignored': ignored,
      'no_id': noId,
      'failed': applyFailed,
      'full_reload': fullReloadRequested,
      'server_time': serverTime?.toIso8601String(),
    });

    // `total_count`: server sahifa hajmini `limit`dan kichik cheklagan
    // bo'lsa ham (masalan 500), qaytgan qator soni ondan kam bo'lib,
    // faqat `length >= limit` bilan aniqlanmaydigan yashirin kesish
    // (notification'lar jim yo'qolishi) shu bilan ushlanadi.
    final bool truncated = notifications.length >= limit ||
        (totalCount != null && totalCount > notifications.length);

    return SyncFetchResult.done(
      notifications.length,
      truncated: truncated,
      serverTime: serverTime,
      applyFailed: applyFailed,
      fullReloadRequested: fullReloadRequested,
    );
  }

  /// So'rovni yuboradi. Tarmoq/timeout xatosi bo'lsa tayyor natija,
  /// aks holda javob qaytadi (status tekshirilmaydi).
  static Future<_Fetched> _get(String path, String token, String label,
      String startDate, String endDate) async {
    http.Client? owned;
    try {
      final http.Client c = client ?? (owned = http.Client());
      final http.Request request = http.Request('GET', Uri.parse(path));
      request.headers.addAll(headers(token));
      final http.StreamedResponse streamed =
          await c.send(request).timeout(timeout);
      final List<int> bytes = await streamed.stream
          .timeout(idleTimeout, onTimeout: (EventSink<List<int>> s) {
            s.addError(TimeoutException(
                'javob oqimi to\'xtab qoldi', idleTimeout));
            s.close();
          })
          .expand((chunk) => chunk)
          .toList();
      final http.Response response = http.Response.bytes(
        bytes,
        streamed.statusCode,
        headers: streamed.headers,
        request: request,
        reasonPhrase: streamed.reasonPhrase,
      );
      return _Fetched(response: response);
    } on TimeoutException {
      await LogHelper.activity('SYNC_FETCH_TIMEOUT',
          {'stream': label, 'start': startDate, 'end': endDate});
      return const _Fetched(result: SyncFetchResult.failed(timedOut: true));
    } catch (e) {
      await LogHelper.activity('SYNC_FETCH_ERROR',
          {'stream': label, 'start': startDate, 'end': endDate, 'error': e});
      return const _Fetched(result: SyncFetchResult.failed());
    } finally {
      owned?.close();
    }
  }

  static String _shortBody(String body, [int max = logBodyLimit]) {
    if (body.length <= max) return body;
    return '${body.substring(0, max)}…(${body.length} belgi)';
  }

  /// `created_at` bo'yicha o'sish tartibida — eski o'zgarish avval, yangisi
  /// keyin qo'llanadi. Vaqti o'qilmaydiganlar asl tartibida oldinda.
  /// Tartiblash barqaror: teng vaqtlar asl tartibini saqlaydi.
  static List<dynamic> sortByCreatedAt(List<dynamic> list) =>
      sortByCreatedAtDetailed(list).list;

  static _Sorted sortByCreatedAtDetailed(List<dynamic> list) {
    final List<_Keyed> keyed = <_Keyed>[];
    int unparsed = 0;
    String? sample;
    for (int i = 0; i < list.length; i++) {
      final dynamic e = list[i];
      DateTime? at;
      if (e is Map) {
        at = parseCreatedAt(e['created_at']);
        if (at == null) {
          unparsed++;
          sample ??= '${e['created_at']}';
        }
      }
      keyed.add(_Keyed(i, at, e));
    }
    keyed.sort((a, b) {
      final DateTime? x = a.at;
      final DateTime? y = b.at;
      if (x == null && y == null) return a.index.compareTo(b.index);
      if (x == null) return -1;
      if (y == null) return 1;
      final int c = x.compareTo(y);
      return c != 0 ? c : a.index.compareTo(b.index);
    });
    return _Sorted(keyed.map((e) => e.value).toList(), unparsed, sample);
  }

  /// ISO 8601 (T yoki bo'sh joy bilan), epoch soniya/millisekund (raqam
  /// yoki raqamli satr).
  static final RegExp _digitsOnly = RegExp(r'^-?\d+$');

  static DateTime? parseCreatedAt(dynamic value) {
    if (value is num) return _fromEpoch(value);
    if (value is String && value.isNotEmpty) {
      // Sof raqamli satr avval epoch deb sinaladi: `DateTime.tryParse`
      // "1790000000" kabi satrni yil sifatida (kengaytirilgan ISO 8601,
      // 178999-11-30) noto'g'ri talqin qiladi — sana emas, chalkash natija.
      if (_digitsOnly.hasMatch(value)) {
        final num? n = num.tryParse(value);
        if (n != null) return _fromEpoch(n);
      }
      final DateTime? iso = DateTime.tryParse(value);
      if (iso != null) return iso;
    }
    return null;
  }

  static DateTime _fromEpoch(num v) {
    final int ms = v < 1e11 ? (v * 1000).round() : v.round();
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }
}

class _Fetched {
  final http.Response? response;
  final SyncFetchResult? result;

  const _Fetched({this.response, this.result});
}

class _Sorted {
  final List<dynamic> list;
  final int unparsed;
  final String? sample;

  const _Sorted(this.list, this.unparsed, this.sample);
}

class _Keyed {
  final int index;
  final DateTime? at;
  final dynamic value;

  const _Keyed(this.index, this.at, this.value);
}
```

### 6.3. `lib/changes/services/sync/sync_cursor.dart`

```diff
diff --git a/lib/changes/services/sync/sync_cursor.dart b/lib/changes/services/sync/sync_cursor.dart
index 24c7094..9a98cc1 100644
--- a/lib/changes/services/sync/sync_cursor.dart
+++ b/lib/changes/services/sync/sync_cursor.dart
@@ -11,12 +11,19 @@
     o'sha oynadagi notification'lar muvaffaqiyatli olinib lokalga
     yozilgandan keyin oldinga suriladi. Shu sababli har qanday uzilish
     keyingi muvaffaqiyatli sinxronda avtomatik "yetib olinadi".
+
+    Vaqt — SERVER vaqti (qarang: server_clock.dart). Kursor hech qachon
+    server "hozir"idan oldinga o'tmaydi: kassa soati oldinda bo'lsa ham.
+    Kursor monoton: oddiy commit uni ORQAGA surmaydi (parallel qolib ketgan
+    eski run yangi kursorni buzmasin); faqat to'liq yuklash `force` bilan
+    qayta o'rnatadi.
 */
 
 import 'package:intl/intl.dart';
 
 import '../../../utils/constants/pref_keys.dart';
 import '../../../utils/helpers/prefs.dart';
+import '../log_helper.dart';
 
 /// Alohida kursorga ega sinxron oqimlari.
 enum SyncStream { categories, products, discounts }
@@ -33,6 +40,12 @@ extension SyncStreamPref on SyncStream {
     }
   }
 
+  /// Moslashuvchan bo'lak uzunligi saqlanadigan kalit (daqiqa).
+  String get chunkPrefKey => '${prefKey}_chunk_min';
+
+  /// Oxirgi muvaffaqiyatsiz to'liq yuklash vaqti (ms) — backoff uchun.
+  String get reloadFailPrefKey => '${prefKey}_reload_fail_ms';
+
   String get label {
     switch (this) {
       case SyncStream.categories:
@@ -57,12 +70,65 @@ class SyncFetchResult {
   /// bo'lishi mumkin, uni maydaroq bo'laklab qayta olish kerak.
   final bool truncated;
 
-  const SyncFetchResult._(this.ok, this.received, this.truncated);
+  /// Javob berilgan paytdagi server vaqti (HTTP `date`). Kursor bundan
+  /// oldinga o'tmaydi — kassa soati serverdan oldinda bo'lsa ham.
+  final DateTime? serverTime;
+
+  /// Kamida bitta notification qo'llanmadi (parse yoki yozish xatosi).
+  /// Bunday oyna kursorni surmaydi — oqim to'liq qayta yuklanadi. Ilgari
+  /// bitta buzuq notification butun oynani ABADIY bloklab qo'yardi.
+  final bool applyFailed;
+
+  /// So'rov vaqt chegarasiga urildi — uzun oynani bo'lib qayta so'rash va
+  /// keyingi safar kichikroq bo'lak ishlatish mumkin.
+  final bool timedOut;
+
+  /// Server 401/403 qaytardi — token yaroqsiz. Qayta urinish foydasiz,
+  /// alohida log/ogohlantirish kerak.
+  final bool unauthorized;
+
+  /// Server "hammasini qayta yukla" (type 0) dedi — runner oynani
+  /// qo'llash o'rniga bitta to'liq yuklash qiladi.
+  final bool fullReloadRequested;
+
+  const SyncFetchResult._(
+    this.ok,
+    this.received,
+    this.truncated,
+    this.serverTime,
+    this.applyFailed,
+    this.timedOut,
+    this.unauthorized,
+    this.fullReloadRequested,
+  );
+
+  const SyncFetchResult.failed({
+    bool timedOut = false,
+    DateTime? serverTime,
+    bool unauthorized = false,
+  }) : this._(false, 0, false, serverTime, false, timedOut, unauthorized, false);
 
-  const SyncFetchResult.failed() : this._(false, 0, false);
+  const SyncFetchResult.done(
+    int received, {
+    bool truncated = false,
+    DateTime? serverTime,
+    bool applyFailed = false,
+    bool fullReloadRequested = false,
+  }) : this._(true, received, truncated, serverTime, applyFailed, false, false,
+            fullReloadRequested);
 
-  const SyncFetchResult.done(int received, {bool truncated = false})
-      : this._(true, received, truncated);
+  /// Ikki ketma-ket bo'lakning (oyna ikkiga bo'linganda) umumiy natijasi.
+  /// Birinchi yarimdagi bayroqlar yo'qolib ketmasligi kerak.
+  SyncFetchResult followedBy(SyncFetchResult next) => SyncFetchResult._(
+        next.ok,
+        received + next.received,
+        next.truncated,
+        next.serverTime ?? serverTime,
+        applyFailed || next.applyFailed,
+        next.timedOut,
+        unauthorized || next.unauthorized,
+        fullReloadRequested || next.fullReloadRequested,
+      );
 }
 
 /// Yopiq-ochiq vaqt oynasi (UTC).
@@ -109,19 +175,32 @@ class SyncWindow {
 class SyncCursor {
   SyncCursor._();
 
+  /// Kursor ma'nosi o'zgargan relizlar uchun. 2 — kursor server vaqtida
+  /// (ilgari kassa soatida). Eski kursor kassa soati oldinda bo'lganda
+  /// "kelajak"da bo'lishi mumkin va buni birinchi ishga tushishda (server
+  /// farqi hali noma'lum) aniqlab bo'lmaydi — shuning uchun bir marta
+  /// hamma kursor tashlanadi va uchala oqim to'liq yuklanadi.
+  static const int schemaVersion = 2;
+
   /// Backend `start_date`/`end_date` ni shu formatda kutadi (UTC).
   static final DateFormat fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
 
-  /// Har bir oyna oldingisidan shuncha ortga cho'ziladi — kassa va server
-  /// soatlari orasidagi farq tufayli chegaradagi notification tushib
-  /// qolmasligi uchun. Takror kelgan notification zarar qilmaydi: barcha
-  /// qo'llash amallari id bo'yicha `put`/`delete` — idempotent.
+  /// Har bir oyna oldingisidan shuncha ortga cho'ziladi — server ichidagi
+  /// kechikishlar va soniyalik aniqlik tufayli chegaradagi notification
+  /// tushib qolmasligi uchun. Takror kelgan notification zarar qilmaydi:
+  /// barcha qo'llash amallari id bo'yicha `put`/`delete` — idempotent.
   static const Duration overlap = Duration(minutes: 2);
 
-  /// Bundan eski kursor bilan notification so'rash ma'nosiz (server
-  /// tarixni cheksiz saqlamaydi) — bunday holda to'liq qayta yuklanadi.
+  /// Bundan eski kursor bilan notification so'rash o'rniga to'liq qayta
+  /// yuklash arzonroq (14 kun = 56 oyna × 3 oqim). Server tarixni saqlaydi
+  /// (2026-08-12 da tasdiqlangan), ya'ni bu ishonchlilik emas, tezlik chegarasi.
   static const Duration maxLookback = Duration(days: 14);
 
+  /// Yiqilgan to'liq yuklash shuncha vaqt qayta urinilmaydi (43 MB ni har
+  /// daqiqada tortmaslik uchun). `force` (ilova ochilganda, qo'lda) chetlab
+  /// o'tadi.
+  static const Duration fullReloadBackoff = Duration(minutes: 5);
+
   static String format(DateTime utc) => fmt.format(utc);
 
   static bool has(SyncStream stream) => Pref.getInt(stream.prefKey, 0) > 0;
@@ -145,7 +224,7 @@ class SyncCursor {
     return from.isBefore(floor) ? floor : from;
   }
 
-  /// Notification tarixiga ishonib bo'lmaydigan ikki holat — to'liq qayta
+  /// Notification tarixiga ishonib bo'lmaydigan holatlar — to'liq qayta
   /// yuklash kerak:
   ///
   ///  1. Kursor umuman yo'q. Bu — yangi o'rnatish yoki shu tuzatish
@@ -153,11 +232,107 @@ class SyncCursor {
   ///     yangilanishdan oldin o'tkazib yuborilgan o'zgarishlarni
   ///     notification'dan tiklab bo'lmaydi, shuning uchun kassa bir marta
   ///     to'liq qayta yuklab, boshqalar bilan bir xil holatga keladi.
-  ///  2. Kursor [maxLookback] dan eskirgan — server bunchalik uzoq
-  ///     tarixni saqlashiga ishonch yo'q.
-  static bool needsFullReload(SyncStream stream, DateTime end) =>
-      !has(stream) || raw(stream, end).isBefore(end.subtract(maxLookback));
+  ///  2. Kursor [maxLookback] dan eskirgan — notification'dan yig'ish qimmat.
+  ///  3. Kursor [end] dan [overlap] dan ko'proq KEYINDA. Bu faqat soat
+  ///     sakraganda bo'ladi: kassa soati oldinda bo'lgan paytda (yoki eski
+  ///     versiya kassa soati bilan) yozilgan kursor. Oradagi o'zgarishlarni
+  ///     notification'dan tiklab bo'lmaydi — to'liq yuklab, kursorni server
+  ///     vaqtiga qaytaramiz.
+  static bool needsFullReload(SyncStream stream, DateTime end) {
+    if (!has(stream)) return true;
+    final DateTime r = raw(stream, end);
+    if (r.isBefore(end.subtract(maxLookback))) return true;
+    if (r.isAfter(end.add(overlap))) return true;
+    return false;
+  }
+
+  /// Kursor uchun xavfsiz qiymat: so'ralgan oyna oxiri, lekin server
+  /// vaqtidan (javob paytidagi) oldinga emas.
+  ///
+  /// Kassa soati oldinda bo'lsa `upTo` server kelajagida bo'ladi; unga
+  /// yozilsa keyingi oyna o'sha kelajakdan boshlanib, oradagi
+  /// notification'lar tushib qoladi. Server vaqti bilan cheklash buni yopadi.
+  static DateTime clamp(DateTime upTo, DateTime? serverTime) {
+    if (serverTime != null && serverTime.isBefore(upTo)) return serverTime;
+    return upTo;
+  }
 
-  static Future<void> commit(SyncStream stream, DateTime upTo) =>
-      Pref.setInt(stream.prefKey, upTo.millisecondsSinceEpoch);
+  /// Kursorni suradi.
+  ///
+  /// Oddiy (`force: false`) commit MONOTON: saqlangan kursordan orqaga
+  /// yozmaydi. Sabab: qulf majburan olingan yoki logout bo'lgan paytda hali
+  /// ishlab turgan eski run o'z oynasining (eski) oxirini yozib, qo'lda
+  /// to'liq yangilash surgan kursorni orqaga qaytarishi mumkin edi.
+  ///
+  /// [force] — to'liq yuklash: kursor qayta O'RNATILADI (soat sakraganda
+  /// "kelajak"dagi kursorni server vaqtiga qaytarish uchun orqaga yozish
+  /// shart).
+  static Future<bool> commit(SyncStream stream, DateTime upTo,
+      {bool force = false}) async {
+    final int value = upTo.millisecondsSinceEpoch;
+    if (!force) {
+      final int stored = Pref.getInt(stream.prefKey, 0);
+      if (stored > value) {
+        await LogHelper.activity('SYNC_CURSOR_NOT_MOVED_BACK', {
+          'stream': stream.label,
+          'stored': stored,
+          'attempted': value,
+        });
+        return false;
+      }
+    }
+    await Pref.setInt(stream.prefKey, value);
+    return true;
+  }
+
+  /// Kursorni tashlaydi — keyingi run to'liq yuklaydi.
+  static Future<void> reset(SyncStream stream, {String reason = ''}) async {
+    if (!has(stream)) return;
+    await LogHelper.activity(
+        'SYNC_CURSOR_RESET', {'stream': stream.label, 'reason': reason});
+    await Pref.removeWithKey(stream.prefKey);
+  }
+
+  /// Sxema versiyasi o'zgargan bo'lsa barcha kursorlarni bir marta tashlaydi.
+  /// main.dart'da, sinxronning har qanday chaqiruvidan OLDIN chaqiriladi.
+  static Future<void> migrateIfNeeded() async {
+    final int current = Pref.getInt(PrefKeys.syncCursorSchema, 0);
+    if (current >= schemaVersion) return;
+    for (final SyncStream s in SyncStream.values) {
+      await reset(s, reason: 'schema $current -> $schemaVersion');
+    }
+    await Pref.setInt(PrefKeys.syncCursorSchema, schemaVersion);
+  }
+
+  // ——— Moslashuvchan bo'lak (timeout'ga qarshi) ———
+
+  /// Oqim uchun joriy bo'lak uzunligi. Sekin internetda katta oyna har safar
+  /// timeout bo'lib o'sha joyda qotib qolmasligi uchun timeout'da
+  /// yarimlanadi, muvaffaqiyatda asta qaytadi.
+  static Duration chunk(SyncStream stream, Duration fallback) {
+    final int minutes = Pref.getInt(stream.chunkPrefKey, 0);
+    if (minutes <= 0) return fallback;
+    return Duration(minutes: minutes);
+  }
+
+  static Future<void> setChunk(SyncStream stream, Duration value) =>
+      Pref.setInt(stream.chunkPrefKey, value.inMinutes);
+
+  // ——— To'liq yuklash backoff ———
+
+  static Future<void> markFullReloadFailed(SyncStream stream, DateTime now) =>
+      Pref.setInt(stream.reloadFailPrefKey, now.millisecondsSinceEpoch);
+
+  static Future<void> clearFullReloadFailed(SyncStream stream) =>
+      Pref.removeWithKey(stream.reloadFailPrefKey);
+
+  /// Yaqinda yiqilgan to'liq yuklash hali qayta urinilmasligi kerakmi.
+  static bool fullReloadBackoffActive(SyncStream stream, DateTime now) {
+    final int at = Pref.getInt(stream.reloadFailPrefKey, 0);
+    if (at <= 0) return false;
+    final DateTime failedAt = DateTime.fromMillisecondsSinceEpoch(at, isUtc: true);
+    final Duration since = now.difference(failedAt);
+    // Manfiy farq = soat orqaga sakragan — backoff'ni ushlab turmaymiz.
+    return since >= Duration.zero && since < fullReloadBackoff;
+  }
 }
```

### 6.4. `lib/changes/services/sync/stream_sync_runner.dart`

```diff
diff --git a/lib/changes/services/sync/stream_sync_runner.dart b/lib/changes/services/sync/stream_sync_runner.dart
index 7a92dbc..ef2a5dc 100644
--- a/lib/changes/services/sync/stream_sync_runner.dart
+++ b/lib/changes/services/sync/stream_sync_runner.dart
@@ -5,10 +5,25 @@
     qayta yuklash tashqaridan callback sifatida beriladi. Shu sababli
     kursor qachon suriladi, qachon surilmaydi degan asosiy kafolatni
     testda tekshirish mumkin (qarang: test/stream_sync_runner_test.dart).
+
+    Kafolatlar:
+      * kursor FAQAT oyna to'liq va xatosiz qo'llangandan keyin suriladi;
+      * kursor hech qachon server vaqtidan oldinga o'tmaydi va oddiy commit
+        bilan orqaga qaytmaydi;
+      * bitta buzuq notification oqimni bloklamaydi — to'liq yuklash bilan
+        qoplanadi;
+      * timeout bo'lgan uzun oyna bo'linadi va keyingi safar kichikroq
+        bo'lak ishlatiladi; eng kichik bo'lak ham sig'masa — to'liq yuklash;
+      * qulf boshqa egaga o'tsa (`shouldContinue` false) run hech narsa
+        yozmasdan to'xtaydi.
 */
 
+import 'dart:async';
+
 import 'package:flutter/foundation.dart';
 
+import '../log_helper.dart';
+import 'server_clock.dart';
 import 'sync_cursor.dart';
 
 /// Bitta vaqt oynasidagi notification'larni olib qo'llaydi.
@@ -19,9 +34,12 @@ typedef FetchWindow = Future<SyncFetchResult> Function(
 typedef FullReload = Future<bool> Function();
 
 class StreamSyncRunner {
-  /// Bitta so'rov qamrab oladigan maksimal oraliq.
+  /// Bitta so'rov qamrab oladigan maksimal oraliq (standart).
   static const Duration defaultChunk = Duration(hours: 6);
 
+  /// Timeout'larda bo'lak shundan kichik bo'lmaydi.
+  static const Duration minChunk = Duration(minutes: 15);
+
   /// Bitta chaqiruvda ko'pi bilan shuncha bo'lak (~30 kun). Qolgani keyingi
   /// chaqiruvda davom etadi — kursor bo'lak-bo'lak surilgani uchun
   /// bajarilgani qayta so'ralmaydi.
@@ -30,6 +48,21 @@ class StreamSyncRunner {
   /// Limitga urilgan oynani necha marta ikkiga bo'lib ko'rish mumkin.
   static const int defaultMaxSplitDepth = 3;
 
+  /// Timeout bo'lgan oyna ko'pi bilan shuncha marta bo'linadi (bu yerda
+  /// chuqur ketmaymiz: tarmoq umuman javob bermayotgan bo'lsa har urinish
+  /// timeout'gacha kutadi).
+  static const int timeoutSplitDepth = 1;
+
+  /// Shundan qisqa oyna timeout bo'lsa bo'linmaydi va bo'lak
+  /// kichraytirilmaydi — muammo hajmda emas, tarmoqda.
+  static const Duration minSplitOnTimeout = Duration(minutes: 30);
+
+  /// To'liq yuklash (43 MB) shundan uzoq cho'zilsa yiqilgan hisoblanadi —
+  /// qulf abadiy band bo'lib qolmasin. `CatchUpSync.staleLock` dan qisqa.
+  ///
+  /// Testlar qisqartiradi (const emas).
+  static Duration fullReloadTimeout = const Duration(minutes: 15);
+
   final SyncStream stream;
   final Duration chunk;
   final int maxChunksPerRun;
@@ -53,10 +86,14 @@ class StreamSyncRunner {
     this.minInterval = Duration.zero,
   });
 
-  /// Oqimni kursordan [end] gacha yetkazadi.
+  /// Oqimni kursordan [end] gacha yetkazadi. [end] — SERVER vaqti.
   ///
-  /// [force] — `minInterval` cheklovini chetlab o'tadi (ilova ochilganda,
-  /// qo'lda "Yangilash" bosilganda).
+  /// [force] — `minInterval` cheklovini va to'liq yuklash backoff'ini chetlab
+  /// o'tadi (ilova ochilganda, qo'lda "Yangilash" bosilganda).
+  /// [shouldContinue] — false qaytarsa (qulf boshqa egaga o'tdi, logout)
+  /// run hech narsa yozmasdan to'xtaydi.
+  /// [beforeCommit] — kursor yozilishidan oldin (ma'lumot boxlarini diskka
+  /// flush qilish uchun).
   ///
   /// Qaytadi: to'liq yetkazildimi. `false` bo'lsa kursor eng oxirgi
   /// muvaffaqiyatli bo'lak joyida qoladi va keyingi chaqiruv o'sha yerdan
@@ -66,6 +103,9 @@ class StreamSyncRunner {
     required FetchWindow fetch,
     required FullReload fullReload,
     bool force = false,
+    bool Function()? shouldContinue,
+    Future<void> Function()? beforeCommit,
+    void Function()? onFullReloadTimeout,
   }) async {
     if (_throttled(end, force)) {
       if (kDebugMode) {
@@ -75,46 +115,129 @@ class StreamSyncRunner {
     }
 
     if (SyncCursor.needsFullReload(stream, end)) {
-      if (kDebugMode) {
-        print('📦 ${stream.label}: kursor yo\'q/eskirgan → to\'liq yuklash');
-      }
-      return _fullReloadAndCommit(end, fullReload);
+      return _fullReloadAndCommit(end, fullReload,
+          why: SyncCursor.has(stream)
+              ? 'kursor eskirgan yoki soat sakragan'
+              : 'kursor yo\'q',
+          force: force,
+          shouldContinue: shouldContinue,
+          beforeCommit: beforeCommit,
+          onFullReloadTimeout: onFullReloadTimeout);
     }
 
     final DateTime start = SyncCursor.start(stream, end);
+    final Duration effectiveChunk = SyncCursor.chunk(stream, chunk);
     final List<SyncWindow> windows = SyncWindow.split(
       start,
       end,
-      chunk,
+      effectiveChunk,
       maxChunks: maxChunksPerRun,
     );
 
-    for (final SyncWindow window in windows) {
-      final SyncFetchResult result = await _fetchDeep(fetch, window);
+    // Bo'lak (persist qilingan chunk) shundan qisqa oyna timeout bo'lsa
+    // kichraytirilmaydi: oyna allaqachon minChunk'dan kichik bo'lsa,
+    // muammo hajmda emas — tarmoqning o'zi (yoki server) javob bermayapti,
+    // bo'lakni yanada kichraytirish foyda bermaydi.
+    bool sawTimeout = false;
+    for (int i = 0; i < windows.length; i++) {
+      final SyncWindow window = windows[i];
+      if (!_alive(shouldContinue, 'fetch')) return false;
+
+      // Birinchi oynadan boshqalari oldingisining oxiridan overlap qadar
+      // ortga cho'ziladi — run'lar orasidagi kabi. Server chegarani qat'iy
+      // (strict) solishtirsa ham chegaradagi soniya tushib qolmaydi.
+      final SyncFetchResult result =
+          await _fetchDeep(fetch, window, overlapStart: i > 0);
+      if (result.timedOut && window.length >= minChunk) sawTimeout = true;
 
       if (!result.ok) {
+        if (result.unauthorized) {
+          // Token yaroqsiz — qayta urinishning foydasi yo'q, kursor joyida.
+          await LogHelper.activity('SYNC_UNAUTHORIZED', {'stream': stream.label});
+          return false;
+        }
+        if (result.timedOut && effectiveChunk <= minChunk) {
+          // Eng kichik bo'lak ham timeout'ga sig'madi (juda sekin internet
+          // + og'ir payload'lar). Bo'lish/kichraytirish tugadi — to'liq
+          // yuklash (u bo'lak-bo'lak, sukut-timeout'li) yagona yo'l.
+          return _fullReloadAndCommit(end, fullReload,
+              why: 'eng kichik oyna ham timeout',
+              force: force,
+              shouldContinue: shouldContinue,
+              beforeCommit: beforeCommit,
+          onFullReloadTimeout: onFullReloadTimeout);
+        }
         // Kursor surilmaydi — shu oyna keyingi urinishda qaytadan olinadi.
         if (kDebugMode) {
           print('⚠️ ${stream.label}: oyna olinmadi, kursor joyida qoldi');
         }
+        if (sawTimeout) await _shrinkChunk(effectiveChunk);
         return false;
       }
 
+      if (result.fullReloadRequested) {
+        return _fullReloadAndCommit(end, fullReload,
+            why: 'server type 0',
+            force: true,
+            shouldContinue: shouldContinue,
+            beforeCommit: beforeCommit,
+          onFullReloadTimeout: onFullReloadTimeout);
+      }
+
       if (result.truncated) {
         // Bo'lib ko'rish ham yordam bermadi: shuncha o'zgarish bo'lgan
         // bo'lsa, to'liq qayta yuklash ham arzonroq, ham ishonchliroq.
-        if (kDebugMode) {
-          print('📦 ${stream.label}: oyna limitga urildi → to\'liq yuklash');
-        }
-        return _fullReloadAndCommit(end, fullReload);
+        return _fullReloadAndCommit(end, fullReload,
+            why: 'oyna limitga urildi',
+            force: force,
+            shouldContinue: shouldContinue,
+            beforeCommit: beforeCommit,
+          onFullReloadTimeout: onFullReloadTimeout);
+      }
+
+      if (result.applyFailed) {
+        // Oynadagi biror notification qo'llanmadi. Kursorni surib
+        // yuborsak o'sha o'zgarish abadiy yo'qoladi; surmasak oyna abadiy
+        // takrorlanadi (aynan shu bo'lgan). To'liq yuklash ikkalasini ham
+        // yopadi: boshqa endpoint, boshqa parser.
+        return _fullReloadAndCommit(end, fullReload,
+            why: 'notification qo\'llanmadi',
+            force: force,
+            shouldContinue: shouldContinue,
+            beforeCommit: beforeCommit,
+          onFullReloadTimeout: onFullReloadTimeout);
       }
 
-      await SyncCursor.commit(stream, window.end);
+      if (!_alive(shouldContinue, 'commit')) return false;
+      if (beforeCommit != null) await beforeCommit();
+      final DateTime upTo = SyncCursor.clamp(window.end, result.serverTime);
+      await SyncCursor.commit(stream, upTo);
+
+      // Server "hozir"iga yetdik — qolgan oynalar server kelajagida
+      // (kassa soati oldinda). Ularni so'rash bekor: bo'sh qaytadi, kursor
+      // esa har javobdagi server vaqtiga surilib, so'ralmagan oraliq hosil
+      // bo'lardi.
+      if (result.serverTime != null && !window.end.isBefore(result.serverTime!)) {
+        break;
+      }
+    }
+
+    if (sawTimeout) {
+      await _shrinkChunk(effectiveChunk);
+    } else if (windows.isNotEmpty && effectiveChunk < chunk) {
+      await _growChunk(effectiveChunk);
     }
 
     return true;
   }
 
+  bool _alive(bool Function()? shouldContinue, String where) {
+    if (shouldContinue == null || shouldContinue()) return true;
+    LogHelper.activity(
+        'SYNC_RUN_PREEMPTED', {'stream': stream.label, 'at': where});
+    return false;
+  }
+
   /// Oqim yaqinda sinxronlangan bo'lsa `true`.
   ///
   /// Kursor yo'q bo'lsa hech qachon cheklanmaydi — birinchi to'liq yuklash
@@ -125,34 +248,106 @@ class StreamSyncRunner {
     return end.difference(SyncCursor.raw(stream, end)) < minInterval;
   }
 
-  Future<bool> _fullReloadAndCommit(DateTime end, FullReload fullReload) async {
+  Future<bool> _fullReloadAndCommit(
+    DateTime end,
+    FullReload fullReload, {
+    required String why,
+    bool force = false,
+    bool Function()? shouldContinue,
+    Future<void> Function()? beforeCommit,
+    void Function()? onFullReloadTimeout,
+  }) async {
+    if (!force && SyncCursor.fullReloadBackoffActive(stream, end)) {
+      // Yaqinda yiqilgan — 43 MB ni har daqiqada tortmaymiz.
+      if (kDebugMode) {
+        print('⏳ ${stream.label}: to\'liq yuklash backoff, o\'tkazib yuborildi');
+      }
+      return false;
+    }
+    if (!_alive(shouldContinue, 'full-reload')) return false;
+
+    if (kDebugMode) {
+      print('📦 ${stream.label}: to\'liq yuklash ($why)');
+    }
+    await LogHelper.activity(
+        'SYNC_FULL_RELOAD', {'stream': stream.label, 'why': why});
+
+    // Yuklash BOSHLANGAN mahalliy vaqt. Kursor tugagan vaqtga emas,
+    // boshlangan vaqtga suriladi: yuklash davomidagi o'zgarishlar
+    // notification orqali kelishi kerak. Server vaqtiga esa yuklashdan
+    // KEYIN o'tkaziladi — yuklash davomida (javoblardan) server soati
+    // farqi aniqlanib bo'lgan bo'ladi.
+    final DateTime localStart = ServerClock.localNow();
+
     bool ok;
     try {
-      ok = await fullReload();
+      ok = await fullReload().timeout(fullReloadTimeout);
+    } on TimeoutException catch (e) {
+      // `Future.timeout` faqat KUTISHNI to'xtatadi — asl ish (masalan 43 MB
+      // yuklash) fonda davom etadi. Chaqiruvchi shu yerda qulfsiz/kursorsiz
+      // qolgan ishni majburan to'xtatish imkonini beradi (masalan yuklashni
+      // amalga oshirayotgan HttpClient'ni yopish orqali).
+      onFullReloadTimeout?.call();
+      if (kDebugMode) {
+        print('❌ ${stream.label}: to\'liq yuklash muddati tugadi: $e');
+      }
+      await LogHelper.activity(
+          'SYNC_FULL_RELOAD_FAILED', {'stream': stream.label, 'error': e});
+      ok = false;
     } catch (e) {
       if (kDebugMode) {
         print('❌ ${stream.label}: to\'liq yuklash xatosi: $e');
       }
+      await LogHelper.activity(
+          'SYNC_FULL_RELOAD_FAILED', {'stream': stream.label, 'error': e});
       ok = false;
     }
-    if (ok) await SyncCursor.commit(stream, end);
-    return ok;
+    if (!ok) {
+      await LogHelper.activity(
+          'SYNC_FULL_RELOAD_FAILED', {'stream': stream.label, 'why': why});
+      await SyncCursor.markFullReloadFailed(stream, end);
+      return false;
+    }
+    if (!_alive(shouldContinue, 'full-reload-commit')) return false;
+    await SyncCursor.clearFullReloadFailed(stream);
+    if (beforeCommit != null) await beforeCommit();
+    await SyncCursor.commit(
+      stream,
+      SyncCursor.clamp(end, ServerClock.toServer(localStart)),
+      force: true,
+    );
+    return true;
   }
 
-  /// Oyna server limitiga urilsa, uni ikkiga bo'lib qayta so'raydi.
-  /// Takror kelgan notification zarar qilmaydi — qo'llash amallari
-  /// id bo'yicha idempotent.
+  /// Oyna server limitiga urilsa (yoki timeout bo'lsa), uni ikkiga bo'lib
+  /// qayta so'raydi. Takror kelgan notification zarar qilmaydi — qo'llash
+  /// amallari id bo'yicha idempotent.
+  ///
+  /// [overlapStart] — so'rov boshlanishi oynadan [SyncCursor.overlap] qadar
+  /// oldinroq (ketma-ket bo'laklar chegarasida tushib qolish bo'lmasin).
   Future<SyncFetchResult> _fetchDeep(
     FetchWindow fetch,
     SyncWindow window, {
     int depth = 0,
+    bool overlapStart = false,
   }) async {
+    final DateTime requestStart =
+        overlapStart ? window.start.subtract(SyncCursor.overlap) : window.start;
     final SyncFetchResult result = await fetch(
-      SyncCursor.format(window.start),
+      SyncCursor.format(requestStart),
       SyncCursor.format(window.end),
     );
 
-    if (!result.ok || !result.truncated || depth >= maxSplitDepth) {
+    final bool shouldSplit;
+    final int depthLimit;
+    if (result.ok) {
+      shouldSplit = result.truncated;
+      depthLimit = maxSplitDepth;
+    } else {
+      shouldSplit = result.timedOut && window.length >= minSplitOnTimeout;
+      depthLimit = timeoutSplitDepth;
+    }
+    if (!shouldSplit || depth >= depthLimit) {
       return result;
     }
 
@@ -167,9 +362,32 @@ class StreamSyncRunner {
       fetch,
       SyncWindow(window.start, mid),
       depth: depth + 1,
+      overlapStart: overlapStart,
     );
     if (!first.ok || first.truncated) return first;
 
-    return _fetchDeep(fetch, SyncWindow(mid, window.end), depth: depth + 1);
+    final SyncFetchResult second = await _fetchDeep(
+      fetch,
+      SyncWindow(mid, window.end),
+      depth: depth + 1,
+      overlapStart: true,
+    );
+    return first.followedBy(second);
+  }
+
+  Future<void> _shrinkChunk(Duration current) async {
+    Duration next = Duration(milliseconds: current.inMilliseconds ~/ 2);
+    if (next < minChunk) next = minChunk;
+    if (next == current) return;
+    await SyncCursor.setChunk(stream, next);
+    await LogHelper.activity('SYNC_CHUNK_SHRINK',
+        {'stream': stream.label, 'minutes': next.inMinutes});
+  }
+
+  Future<void> _growChunk(Duration current) async {
+    Duration next = current * 2;
+    if (next > chunk) next = chunk;
+    if (next == current) return;
+    await SyncCursor.setChunk(stream, next);
   }
 }
```

### 6.5. `lib/changes/services/sync/catch_up_sync.dart`

```diff
diff --git a/lib/changes/services/sync/catch_up_sync.dart b/lib/changes/services/sync/catch_up_sync.dart
index 8040bc7..a3f996b 100644
--- a/lib/changes/services/sync/catch_up_sync.dart
+++ b/lib/changes/services/sync/catch_up_sync.dart
@@ -14,6 +14,15 @@
 
     Bu sinf faqat "simlarni ulaydi": qaysi oqim qaysi API bilan olinadi va
     qaysi tartibda. Kursor mantig'i StreamSyncRunner ichida.
+
+    Qulf: bir vaqtda bitta sinxron. Qo'lda to'liq yangilash (UpdBloc,
+    SyncBloc, startup, "baza yangilanmagan" dialogi) va logout ham shu
+    qulfdan o'tadi (`exclusive`) — aks holda to'liq yuklash `clearAndPutItems`
+    bilan sinxron yozgan mahsulotni o'chirib, kursor esa o'tib ketishi mumkin
+    edi. Qulf ticket asosida: majburan olingan yoki logout bo'lgan paytda
+    hali ishlab turgan eski run `shouldContinue` orqali to'xtaydi va hech
+    narsa yozmaydi. Qulf osilib qolsa (`staleLock`, monoton Stopwatch bilan
+    o'lchanadi — kassa soati sakrasa ham) keyingi chaqiruv uni majburan oladi.
 */
 
 import 'dart:async';
@@ -23,14 +32,18 @@ import 'package:flutter/material.dart';
 import 'package:flutter_bloc/flutter_bloc.dart';
 
 import '../../../features/get_categories/service/category_service.dart';
+import '../../../features/hive_repository/hive_boxes.dart';
 import '../../../features/home/bloc/home_bloc/home_bloc.dart';
 import '../../../utils/constants/pref_keys.dart';
 import '../../../utils/helpers/prefs.dart';
 import '../catalog_refresh_notice.dart';
 import '../discount_service.dart';
+import '../get_items_service.dart';
+import '../log_helper.dart';
 import '../web_socket_service/category/categories_ws_service.dart';
 import '../web_socket_service/discount/discount_ws_service.dart';
 import '../web_socket_service/product/products_ws_service.dart';
+import 'server_clock.dart';
 import 'stream_sync_runner.dart';
 import 'sync_cursor.dart';
 
@@ -45,37 +58,128 @@ class CatchUpSync {
   /// qo'lda "Yangilash" bosilganda `force: true` bilan chetlab o'tiladi.
   static const Duration slowStreamInterval = Duration(minutes: 10);
 
-  static bool _running = false;
+  /// Qulf shundan uzoq ushlab turilsa — egasi osilib qolgan deb hisoblanadi.
+  /// Har bir ichki qadam (notification so'rovi, to'liq yuklash) o'z
+  /// timeout'iga ega va bundan qisqa.
+  static const Duration staleLock = Duration(minutes: 20);
+
+  /// Qo'lda to'liq yangilash joriy sinxron tugashini ko'pi bilan shuncha
+  /// kutadi, keyin (`forceAfterWait`) baribir davom etadi.
+  static const Duration exclusiveMaxWait = Duration(minutes: 3);
+
+  static int _seq = 0;
+  static int _ticket = 0;
+  static Stopwatch? _lockAge;
+  static String _lockReason = '';
+  static int _lastBusyLoggedTicket = 0;
+
+  /// Logout/yangi token bilan oshadi — o'sha paytda ishlab turgan run
+  /// eski kompaniya natijalarini yozmasin.
+  static int _epoch = 0;
+
+  /// Mahsulot oqimi lokalda yo'q kategoriya id'sini ko'rdi — kategoriya
+  /// oqimi keyingi safar 10 daqiqalik cheklovsiz so'raladi.
+  static bool _categoriesRequested = false;
+
+  static bool get isRunning => _ticket != 0;
+
+  static bool owns(int ticket) => _ticket == ticket;
+
+  static int get epoch => _epoch;
+
+  static void bumpEpoch() => _epoch++;
+
+  static void requestCategoriesRefresh() => _categoriesRequested = true;
+
+  static int _take(String reason) {
+    _ticket = ++_seq;
+    _lockAge = Stopwatch()..start();
+    _lockReason = reason;
+    return _ticket;
+  }
+
+  static int? _tryAcquire(String reason) {
+    if (_ticket != 0) {
+      final Stopwatch? age = _lockAge;
+      final bool stale = age != null && age.elapsed > staleLock;
+      if (!stale) return null;
+      unawaited(LogHelper.activity('SYNC_STALE_LOCK', {
+        'held_by': _lockReason,
+        'held_min': age.elapsed.inMinutes,
+        'taken_by': reason,
+      }));
+    }
+    return _take(reason);
+  }
 
-  static bool get isRunning => _running;
+  static void _release(int ticket) {
+    // Qulf osilib qolgani uchun boshqa ega olgan bo'lsa — unga tegmaymiz.
+    if (_ticket != ticket) return;
+    _ticket = 0;
+    _lockAge = null;
+    _lockReason = '';
+  }
 
-  /// Barcha oqimlarni kursordan hozirgi vaqtgacha yetkazadi.
+  /// Barcha oqimlarni kursordan hozirgi (SERVER) vaqtgacha yetkazadi.
   ///
-  /// [force] — sekin oqimlarning 10 daqiqalik cheklovini chetlab o'tadi.
+  /// [force] — sekin oqimlarning 10 daqiqalik cheklovini va to'liq yuklash
+  /// backoff'ini chetlab o'tadi.
   ///
-  /// Qaytadi: hamma oqim to'liq sinxronlandimi.
+  /// Qaytadi: hamma oqim to'liq sinxronlandimi. Hech qachon istisno
+  /// tashlamaydi — aks holda avto-sinxron halqasi o'lib qolardi.
   static Future<bool> run(
     BuildContext context,
     bool mounted, {
     String reason = '',
     bool force = false,
   }) async {
-    if (_running) {
+    final int? ticket = _tryAcquire(reason);
+    if (ticket == null) {
       if (kDebugMode) {
-        print('⏭️ Sinxron allaqachon ketmoqda, o\'tkazib yuborildi ($reason)');
+        print('⏭️ Sinxron allaqachon ketmoqda ($_lockReason), '
+            'o\'tkazib yuborildi ($reason)');
+      }
+      // Har daqiqada emas — har bir qulf egasi uchun bir marta.
+      if (_lastBusyLoggedTicket != _ticket) {
+        _lastBusyLoggedTicket = _ticket;
+        await LogHelper.activity('SYNC_SKIPPED_BUSY', {
+          'held_by': _lockReason,
+          'held_s': _lockAge?.elapsed.inSeconds,
+          'skipped': reason,
+        });
       }
       return false;
     }
 
-    final String token = Pref.getString(PrefKeys.token, '');
-    if (token.isEmpty || token == 'not initialized') {
-      return false;
-    }
-
-    _running = true;
-    final DateTime end = DateTime.now().toUtc();
+    final int myEpoch = _epoch;
+    bool alive() => owns(ticket) && _epoch == myEpoch;
 
     try {
+      final String token = Pref.getString(PrefKeys.token, '');
+      if (token.isEmpty || token == 'not initialized') {
+        return false;
+      }
+
+      // Kompaniya/do'kon id'siz so'rov ma'nosiz (server hammasini yoki
+      // hech narsani qaytaradi) va narx filtri ishlamaydi — kursor
+      // surilmasin.
+      final String orgId = Pref.getString(PrefKeys.orgID, '');
+      final String storeId = Pref.getString(PrefKeys.storeId, '');
+      if (orgId.isEmpty || storeId.isEmpty) {
+        await LogHelper.activity('SYNC_CONFIG_MISSING', {
+          'orgID': orgId.isEmpty ? 'BO\'SH' : 'ok',
+          'storeId': storeId.isEmpty ? 'BO\'SH' : 'ok',
+        });
+        return false;
+      }
+
+      await healCatalogState();
+
+      // Server vaqti. Kassa soati noto'g'ri bo'lsa ham oyna server
+      // bo'yicha hisoblanadi (qarang: server_clock.dart).
+      final DateTime end = ServerClock.nowUtc();
+      final Stopwatch sw = Stopwatch()..start();
+
       if (kDebugMode) {
         print('🔄 CatchUpSync boshlandi ($reason)');
       }
@@ -87,11 +191,14 @@ class CatchUpSync {
         minInterval: slowStreamInterval,
       ).run(
         end: end,
-        force: force,
+        force: force || _categoriesRequested,
         fetch: (s, e) =>
             CategoriesWsService.getReceivedWS(mounted, context, s, e),
         fullReload: () async => await CategoryService.category() == null,
+        shouldContinue: alive,
+        beforeCommit: flushCatalogBoxes,
       );
+      if (ok) _categoriesRequested = false;
 
       // Narx o'zgarishi (type 13) shu oqimda — cheklovsiz, har chaqiruvda.
       ok = await const StreamSyncRunner(stream: SyncStream.products).run(
@@ -100,6 +207,12 @@ class CatchUpSync {
             fetch: (s, e) =>
                 ProductsWsService.getReceivedWS(mounted, context, s, e),
             fullReload: () => ProductsWsService.import(context),
+            shouldContinue: alive,
+            beforeCommit: flushCatalogBoxes,
+            // 43 MB yuklash `Future.timeout` bilan to'xtatilmaydi (u faqat
+            // kutishni to'xtatadi) — shuning uchun timeout aynan shu
+            // ulanishni majburan yopadi (qarang: get_items_service.dart).
+            onFullReloadTimeout: OrdersService.cancelCatalogDownload,
           ) &&
           ok;
 
@@ -115,14 +228,25 @@ class CatchUpSync {
             fetch: (s, e) =>
                 DiscountWsService.getReceivedWS(mounted, context, s, e),
             fullReload: () async => await DiscountService.discounts() == null,
+            shouldContinue: alive,
+            beforeCommit: flushCatalogBoxes,
           ) &&
           ok;
 
+      if (!alive()) return false;
+
       if (ok) {
         // Bosh ekrandagi "oxirgi yangilanish" ko'rsatkichi shu kalitni
         // o'qiydi — endi u haqiqatan muvaffaqiyatli sinxron vaqtini
         // ko'rsatadi.
         await Pref.setInt(PrefKeys.lastSyncTime, end.millisecondsSinceEpoch);
+        // Katalog kursordan to'liq yetib olindi — startup'dagi yiqilish
+        // sabab qo'yilgan "baza yangilanmagan" ogohlantirishi endi
+        // asossiz (ilgari kassir baribir qo'lda 43 MB yuklashga majbur edi).
+        await CatalogRefreshNotice.clearPending();
+      } else {
+        await LogHelper.activity('SYNC_RUN_INCOMPLETE',
+            {'reason': reason, 'ms': sw.elapsedMilliseconds});
       }
 
       _refreshUi(context, mounted);
@@ -131,20 +255,112 @@ class CatchUpSync {
         print('${ok ? '✅' : '⚠️'} CatchUpSync tugadi ($reason), ok=$ok');
       }
       return ok;
+    } catch (e, stack) {
+      // Kutilmagan xato (masalan Hive yozuvi). Chaqiruvchiga yetkazmaymiz:
+      // avto-sinxron halqasi shu yerda o'lib, internet o'zgarguncha
+      // tirilmasdi.
+      await LogHelper.activity(
+          'SYNC_CRASH', {'reason': reason, 'error': e, 'stack': stack});
+      return false;
     } finally {
-      _running = false;
+      _release(ticket);
 
       // Startup'dagi to'liq yuklash yiqilgan bo'lsa kassirga ogohlantirish
       // chiqaramiz. Bu nuqta ilova ochilganda, tarmoq tiklanganda va har
       // davriy tsiklda o'tiladi — ya'ni internet qaytishi bilan ko'rinadi.
       //
       // Ataylab `await` qilinmaydi: dialog modal, kassir uni yopmaguncha
-      // kutib turilsa `_running` band bo'lib qolardi va sinxron shu vaqt
+      // kutib turilsa qulf band bo'lib qolardi va sinxron shu vaqt
       // davomida butunlay to'xtab turardi.
       unawaited(CatalogRefreshNotice.maybeShow());
     }
   }
 
+  /// Lokal katalog holati kursorga mos kelmasa kursorni tashlaydi —
+  /// keyingi runner to'liq yuklaydi.
+  ///
+  /// Holatlar: to'liq yozuv (clearAndPutItems) o'rtada uzilgan (marker
+  /// qolgan); items/categories box bo'sh (Hive buzilgan faylni jimgina
+  /// bo'shatib ochadi) — kursor esa "hammasi bor" deb turardi.
+  static Future<void> healCatalogState() async {
+    try {
+      if (Pref.getBool(PrefKeys.catalogWriteInProgress, false)) {
+        await SyncCursor.reset(SyncStream.products,
+            reason: 'to\'liq katalog yozuvi tugamagan');
+        await Pref.setBool(PrefKeys.catalogWriteInProgress, false);
+      }
+      if (HiveBoxes.getProducts().isEmpty) {
+        await SyncCursor.reset(SyncStream.products, reason: 'items box bo\'sh');
+      }
+      if (HiveBoxes.getCategories().isEmpty) {
+        await SyncCursor.reset(SyncStream.categories,
+            reason: 'categories box bo\'sh');
+      }
+    } catch (e) {
+      await LogHelper.activity('SYNC_HEAL_ERROR', {'error': e});
+    }
+  }
+
+  /// Kursor yozilishidan oldin ma'lumot diskka tushsin: kursor va
+  /// ma'lumot turli fayllarda (prefs.hive / items.hive); Hive o'zi fsync
+  /// qilmaydi — svet o'chsa kursor saqlanib, ma'lumot yo'qolishi mumkin edi.
+  static Future<void> flushCatalogBoxes() async {
+    try {
+      await HiveBoxes.getProducts().flush();
+      await HiveBoxes.getCategories().flush();
+      await HiveBoxes.getDiscounts().flush();
+    } catch (_) {
+      // flush yiqilsa ham sinxron to'xtamasin — bu qo'shimcha himoya.
+    }
+  }
+
+  /// [body] ni sinxron qulfi ostida bajaradi — qo'lda/startup to'liq
+  /// yuklashlar va logout uchun. Davriy sinxron shu vaqtda o'tkazib
+  /// yuboriladi.
+  ///
+  /// Joriy sinxron tugashini [exclusiveMaxWait] gacha kutadi; shundan
+  /// keyin [forceAfterWait] true bo'lsa baribir davom etadi (kassir bosgan
+  /// yangilash javobsiz qolmasin — eski run `shouldContinue` orqali
+  /// to'xtaydi), false bo'lsa qulf bo'shaguncha kutaveradi (startup kabi
+  /// odam kutmaydigan ishlar uchun).
+  static Future<T> exclusive<T>(
+    Future<T> Function() body, {
+    String reason = 'manual-full-update',
+    bool forceAfterWait = true,
+  }) async {
+    final Stopwatch sw = Stopwatch()..start();
+    int? ticket = _tryAcquire(reason);
+    while (ticket == null && (!forceAfterWait || sw.elapsed < exclusiveMaxWait)) {
+      await Future.delayed(const Duration(milliseconds: 250));
+      ticket = _tryAcquire(reason);
+    }
+    if (ticket == null) {
+      await LogHelper.activity('SYNC_LOCK_FORCED',
+          {'held_by': _lockReason, 'taken_by': reason});
+      ticket = _take(reason);
+    }
+    try {
+      return await body();
+    } finally {
+      _release(ticket);
+    }
+  }
+
+  /// Qulf bo'sh bo'lsagina [body] ni bajaradi, band bo'lsa null (kutmaydi).
+  /// Davriy fon ishlari uchun (masalan diskont avto-sinxroni).
+  static Future<T?> tryExclusive<T>(
+    Future<T> Function() body, {
+    String reason = 'background',
+  }) async {
+    final int? ticket = _tryAcquire(reason);
+    if (ticket == null) return null;
+    try {
+      return await body();
+    } finally {
+      _release(ticket);
+    }
+  }
+
   static void _refreshUi(BuildContext context, bool mounted) {
     if (!mounted || !context.mounted) return;
     try {
```

### 6.6. `lib/changes/services/web_socket_service/product/products_ws_service.dart`

```diff
diff --git a/lib/changes/services/web_socket_service/product/products_ws_service.dart b/lib/changes/services/web_socket_service/product/products_ws_service.dart
index 4b536e3..4672f78 100644
--- a/lib/changes/services/web_socket_service/product/products_ws_service.dart
+++ b/lib/changes/services/web_socket_service/product/products_ws_service.dart
@@ -1,19 +1,18 @@
-// ignore_for_file: use_build_context_synchronously, invalid_use_of_protected_member
+// ignore_for_file: use_build_context_synchronously, invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
 
 import 'dart:convert';
 import 'package:flutter/foundation.dart';
 import 'package:flutter/material.dart';
 import 'package:flutter/scheduler.dart';
 import 'package:hive/hive.dart';
-import 'package:http/http.dart' as http;
 import 'package:invan2/changes/services/log_helper.dart';
 import 'package:invan2/changes/services/catalog_refresh_notice.dart';
+import 'package:invan2/changes/services/sync/catch_up_sync.dart';
+import 'package:invan2/changes/services/sync/notification_fetch.dart';
 import 'package:invan2/changes/services/sync/sync_cursor.dart';
 import 'package:invan2/changes/services/web_socket_service/product/model/mxik_updates.dart';
 import 'package:invan2/changes/services/web_socket_service/product/model/product_price_edit_response.dart';
-import 'package:invan2/changes/services/web_socket_service/urls/urls.dart';
 import 'package:provider/provider.dart';
-import '../../../../alice_service.dart';
 import '../../../../features/features.dart';
 import '../../../../features/get_products/singletons/items_singleton.dart';
 import '../../../../features/get_products/soliq/tasnif_service.dart';
@@ -26,216 +25,220 @@ import '../../../singletons/organization_singleton.dart';
 import '../../api/result_http_model.dart';
 import '../../get_items_service.dart';
 
+/*
+    Mahsulot oqimi: notification'lardan lokal katalogni yangilash.
+
+    Turlari: 0 — hammasini qayta yukla, 1 — yangi mahsulot, 2 — yangilash,
+    3 — o'chirish, 13 — narx, 20/21 — MXIK, 40 — to'lov turi (CLICK/UZUM/
+    PAYME), 6 — e'tiborsiz.
+
+    So'rov/tartiblash/xatoga chidamlilik NotificationFetch'da; bu yerda
+    faqat bitta notification'ni qanday qo'llash yozilgan.
+*/
 class ProductsWsService {
   ProductsWsService._();
 
-  /*static sendReceivedWS(List<String> ids) async {
-    final token = Pref.getString(PrefKeys.token, 'not initialized');
-
-    if (token.isEmpty || token == 'not initialized') {
-      return;
-    }
+  static const int limit = NotificationFetch.limit;
 
-    final headers = <String, String>{
-      "timezone": "-300",
-      "Vary": "Origin",
-      "Strict-Transport-Security": "Strict-Transport-Security",
-      "Content-Type": "application/json",
-      "Access-Control-Allow-Origin": "*",
-      "Authorization": "Bearer $token"
-    };
-
-    final body = jsonEncode({"ids": ids});
-
-    http.Response response = await http
-        .delete(
-          Uri.parse("${Urls.baseNotificationUrl}notifications"),
-          body: body,
-          headers: headers,
-        )
-        .timeout(const Duration(seconds: 20));
-    alice.onHttpResponse(response);
-    await Pref.setInt(
-        PrefKeys.lastSyncTime, DateTime.now().millisecondsSinceEpoch);
-    await Pref.setBool(PrefKeys.lastSyncTimeChanged, true);
-  }*/
-
-  static const int limit = 1000;
+  /// Mahsulot oqimi qamrab oladigan notification turlari.
+  static const String types = '1,2,3,0,6,13,20,21,40';
 
   static Future<SyncFetchResult> getReceivedWS(bool mounted,
       BuildContext context, String startDate, String endDate) async {
     try {
-      return await _fetch(mounted, context, startDate, endDate);
-    } catch (e) {
-      // Timeout / tarmoq / parse xatosi. Kursor surilmasligi uchun
-      // muvaffaqiyatsiz deb qaytaramiz — oyna keyingi urinishda
-      // qaytadan so'raladi.
+      // Bitta oynada avval o'chirilgan mahsulotni keyinroq (yoki xuddi shu
+      // soniyada) kelgan create/update qayta tiriltirmasin — id → o'chirish
+      // vaqti.
+      final Map<String, DateTime?> deletedInBatch = <String, DateTime?>{};
+      return await NotificationFetch.run(
+        label: 'Product',
+        types: types,
+        startDate: startDate,
+        endDate: endDate,
+        apply: (ws) => _apply(ws, context, mounted, deletedInBatch),
+        afterBatch: refreshCaches,
+      );
+    } catch (e, stack) {
+      // NotificationFetch o'zi hamma narsani ushlaydi; bu faqat oxirgi
+      // himoya — kursor surilmasligi uchun muvaffaqiyatsiz qaytaramiz.
       if (kDebugMode) {
         print('❌ Product notification xatosi: $e');
       }
+      await LogHelper.activity(
+          'SYNC_FETCH_CRASH', {'stream': 'Product', 'error': e, 'stack': stack});
       return const SyncFetchResult.failed();
     }
   }
 
-  static Future<SyncFetchResult> _fetch(bool mounted, BuildContext context,
-      String startDate, String endDate) async {
-    final token = Pref.getString(PrefKeys.token, 'not initialized');
+  /// Hive'dagi katalogni xotira keshiga qayta yuklaydi.
+  ///
+  /// Oyna oxirida BIR marta chaqiriladi. Ilgari har notification'dan keyin
+  /// chaqirilardi: 500 ta narx o'zgarishi = 57 000 mahsulotni 500 marta
+  /// qayta yuklash — UI o'nlab soniya qotardi.
+  static Future<void> refreshCaches() async {
+    await ItemsSingleton.storeProducts();
+    CategorySingleton.init();
+  }
 
-    if (token.isEmpty || token == 'not initialized') {
-      return const SyncFetchResult.failed();
+  static Future<NotifyApply> _apply(Map<String, dynamic> ws, BuildContext context,
+      bool mounted, Map<String, DateTime?> deletedInBatch) async {
+    final int? type = _asInt(ws['type']);
+    final Map<String, dynamic> data = _asMap(ws['data']);
+
+    switch (type) {
+      case 21:
+        await ItemsSingleton.deleteMxik(_asList(data['mxik_codes']));
+        return NotifyApply.applied;
+
+      case 20:
+        await ItemsSingleton.editMxik(MxikUpdates.fromJson(data).mxikCodes ?? []);
+        return NotifyApply.applied;
+
+      case 13:
+        final ProductPriceEdit edit = ProductPriceEdit.fromJson(ws);
+        if (data.isNotEmpty && edit.data?.productsValues == null) {
+          // Payload bor-u, biz kutgan `product_values` yo'q — shakl
+          // o'zgargan. Jimgina "qo'llandi" deyish narxni yo'qotardi.
+          throw const FormatException('type 13: product_values yo\'q');
+        }
+        await ItemsSingleton.editItem(edit);
+        return NotifyApply.applied;
+
+      case 0:
+        // Serverning "hammasini qayta yukla" buyrug'i — oyna ichida emas,
+        // runner'ning yagona to'liq yuklash yo'li orqali (backoff, timeout,
+        // kursor commit hammasi o'sha yerda).
+        return NotifyApply.fullReload;
+
+      case 1:
+      case 2:
+        return _upsert(ws, data, isUpdate: type == 2, deletedInBatch: deletedInBatch);
+
+      case 3:
+        final List<String> ids = _asList(data['ids'])
+            .map((e) => e.toString())
+            .where((e) => e.isNotEmpty)
+            .toList();
+        if (ids.isEmpty) {
+          throw const FormatException('type 3: ids bo\'sh yoki noto\'g\'ri shakl');
+        }
+        await ItemsSingleton.deleteProduct(ids);
+        final DateTime? at = NotificationFetch.parseCreatedAt(ws['created_at']);
+        for (final String id in ids) {
+          deletedInBatch[id] = at;
+        }
+        return NotifyApply.applied;
+
+      case 40:
+        await _paymentToggle(data, context, mounted);
+        return NotifyApply.ignored;
+
+      default:
+        return NotifyApply.ignored;
     }
+  }
 
-    String comId = Pref.getString(PrefKeys.orgID, "");
-    final headers = <String, String>{
-      "timezone": "-300",
-      "Vary": "Origin",
-      "Strict-Transport-Security": "Strict-Transport-Security",
-      "Content-Type": "application/json",
-      "Access-Control-Allow-Origin": "*",
-      "Authorization": "Bearer $token"
-    };
-    final String path =
-        "${Urls.baseNotificationUrl}notifications?company_id=$comId&limit=$limit&offset=1&type=1,2,3,0,6,13,20,21,40&is_read=false&start_date=$startDate&end_date=$endDate";
-    http.Response response = await http
-        .get(
-          Uri.parse(path),
-          headers: headers,
-        )
-        .timeout(const Duration(seconds: 20));
-    await LogHelper.logRequest(
-        method: "GET",
-        path: path,
-        statusCode: response.statusCode,
-        response: response.body);
-
-    alice.onHttpResponse(response);
-    if (kDebugMode) {
-      print(
-          '☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️ - Product  Get - ☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️');
-      print(
-          'Response: ${response.statusCode} - ${response.body} - Product Get - ${DateTime.now()}');
+  /// Yangi mahsulot (type 1) yoki yangilash (type 2).
+  ///
+  /// Parse xatosi istisno bo'lib chiqadi — NotificationFetch uni faqat shu
+  /// notification uchun belgilaydi, oyna qolgan qismi qo'llanadi va oqim
+  /// to'liq yuklash bilan tenglashtiriladi.
+  static Future<NotifyApply> _upsert(
+    Map<String, dynamic> ws,
+    Map<String, dynamic> data, {
+    required bool isUpdate,
+    required Map<String, DateTime?> deletedInBatch,
+  }) async {
+    if (data.isEmpty) {
+      throw const FormatException('notification data bo\'sh');
     }
-    if (response.statusCode != 200) {
-      return const SyncFetchResult.failed();
+    if (data['is_active'] != null && data['is_active'] is! bool) {
+      throw FormatException('is_active bool emas: ${data['is_active']}');
     }
-    
-    {
-      if (jsonDecode(utf8.decode(response.bodyBytes))['notifications'] !=
-          null) {
-        List<String> deleteIds = [];
-        List notification =
-            jsonDecode(utf8.decode(response.bodyBytes))['notifications'];
-
-        for (var ws in notification) {
-    
-          if (ws['id'] != null) {
-            if (ws['type'] == 21) {
-              await ItemsSingleton.deleteMxik(ws['data']['mxik_codes']);
-              await ItemsSingleton.storeProducts();
-              CategorySingleton.init();
-              deleteIds.add(ws['id']);
-            }
-            if (ws['type'] == 20) {
-              await ItemsSingleton.editMxik(
-                  MxikUpdates.fromJson(ws['data']).mxikCodes ?? []);
-              await ItemsSingleton.storeProducts();
-              CategorySingleton.init();
-              deleteIds.add(ws['id']);
-            }
-            if (ws['type'] == 13) {
-              await ItemsSingleton.editItem(ProductPriceEdit.fromJson(ws));
-              await ItemsSingleton.storeProducts();
-              CategorySingleton.init();
-              deleteIds.add(ws['id']);
-            }
-            if (ws['type'] == 0) {
-              bool isSuccess = await import(context);
-              if (isSuccess) {
-                deleteIds.add(ws['id']);
-              }
-            }
-            if (ws['type'] == 2) {
-              ItemModel item = ItemModel.fromWebSocketJsonUpdate(ws['data']);
-              if ((ws['data']['category_ids'] as List<dynamic>).isNotEmpty) {
-                item.categories ??=
-                    getCategories(ws['data']['category_ids'][0]);
-              }
-              await ItemsSingleton.putItems([item]);
-              await ItemsSingleton.storeProducts();
-              CategorySingleton.init();
-              deleteIds.add(ws['id']);
-            }
-            if (ws['type'] == 1) {
-              ItemModel item = ItemModel.fromWebSocketJson(ws['data']);
-              if ((ws['data']['category_ids'] as List<dynamic>).isNotEmpty) {
-                item.categories ??=
-                    getCategories(ws['data']['category_ids'][0]);
-              }
-              await ItemsSingleton.putItems([item]);
-              await ItemsSingleton.storeProducts();
-              CategorySingleton.init();
-              deleteIds.add(ws['id']);
-            }
-            if (ws['type'] == 3) {
-              if (ws['data']['ids'] != null) {
-                // await ItemsSingleton.deleteProduct(
-                //   ws['data']['ids'].cast<String?>());
-                await ItemsSingleton.deleteProduct(
-                  (ws['data']['ids'] as List<dynamic>)
-                      .map((e) => e.toString())
-                      .toList(),
-                );
-              }
-              await ItemsSingleton.storeProducts();
-              CategorySingleton.init();
-              deleteIds.add(ws['id']);
-            }
-            if (ws['type'] == 6) {
-              deleteIds.add(ws['id']);
-            }
-            if (ws['type'] == 40) {
-              final data = ws['data'];
-              final String name = data['name'];
-              final bool isUsed = data['is_used'];
-              final String id = data['id'];
-
-              if (name == 'CLICK') {
-                await Pref.setBool(PrefKeys.clickEnable, isUsed);
-                await Pref.setString(PrefKeys.clickId, id);
-              } else if (name == 'UZUM') {
-                await Pref.setBool(PrefKeys.uzumEnable, isUsed);
-                await Pref.setString(PrefKeys.uzumId, id);
-              } else if (name == 'PAYME') {
-                await Pref.setBool(PrefKeys.paymeEnable, isUsed);
-                await Pref.setString(PrefKeys.paymeId, id);
-              }
-
-              final box = await Hive.openBox<Payment>('other_payments');
-              final payments = box.values.toList();
-              for (int i = 0; i < payments.length; i++) {
-                if (payments[i].name == name) {
-                  payments[i].isAdded = isUsed;
-                  await box.putAt(i, payments[i]);
-                  break;
-                }
-              }
-
-              await OrganizationSingleton.setOtherPayments();
-              if (mounted) {
-                Provider.of<OrderingProvider4>(context, listen: false).notifyListeners();
-              }
-            }
-          }
-        }
-        if (deleteIds.isNotEmpty) {
-          // await sendReceivedWS(deleteIds);
-          deleteIds = [];
-        }
-        return SyncFetchResult.done(notification.length,
-            truncated: notification.length >= limit);
+    final ItemModel item = isUpdate
+        ? ItemModel.fromWebSocketJsonUpdate(data)
+        : ItemModel.fromWebSocketJson(data);
+    final String? id = item.id;
+    if (id == null || id.isEmpty) {
+      throw const FormatException('mahsulot id yo\'q');
+    }
+
+    // Shu oynada allaqachon o'chirilgan mahsulot: create/update o'chirishdan
+    // qat'iy KEYIN yaratilgan bo'lsagina qo'llanadi. Bir soniya ichidagi
+    // juftlik (server yangi-birinchi qaytarsa) o'chirilganini tiriltirmasin.
+    if (deletedInBatch.containsKey(id)) {
+      final DateTime? deletedAt = deletedInBatch[id];
+      final DateTime? at = NotificationFetch.parseCreatedAt(ws['created_at']);
+      if (deletedAt == null || at == null || !at.isAfter(deletedAt)) {
+        await LogHelper.activity('SYNC_SKIP_RESURRECT', {'id': id});
+        return NotifyApply.ignored;
+      }
+    }
+
+    item.categories ??= categoriesFromIds(data['category_ids']);
+
+    // Notification payload'i to'liq katalogdan kambag'alroq: `shop_prices`
+    // KALITI umuman yo'q bo'lsa mavjud narx saqlanadi (ilgari mahsulot
+    // to'liq ustidan yozilib narxsiz qolar, skanerda topilmay qolardi).
+    // Kalit BOR-U natija 0 bo'lsa (server ataylab narxni olib
+    // tashlagan/0 qilgan) — bu hurmat qilinadi, eski narx saqlanib
+    // qolmaydi. Parser bilmaydigan/lokalda topilmagan boshqa maydonlar
+    // (ownerType, commissionTin, o'lchov birligi/QQS) mavjud yozuvdan
+    // saqlanadi.
+    await ItemsSingleton.putItems(
+      [item],
+      mergeWithExisting: true,
+      priceKeyPresent: data.containsKey('shop_prices'),
+    );
+    return NotifyApply.applied;
+  }
+
+  static Future<void> _paymentToggle(
+      Map<String, dynamic> data, BuildContext context, bool mounted) async {
+    final String name = data['name']?.toString() ?? '';
+    final bool isUsed = data['is_used'] == true;
+    final String id = data['id']?.toString() ?? '';
+
+    if (name == 'CLICK') {
+      await Pref.setBool(PrefKeys.clickEnable, isUsed);
+      await Pref.setString(PrefKeys.clickId, id);
+    } else if (name == 'UZUM') {
+      await Pref.setBool(PrefKeys.uzumEnable, isUsed);
+      await Pref.setString(PrefKeys.uzumId, id);
+    } else if (name == 'PAYME') {
+      await Pref.setBool(PrefKeys.paymeEnable, isUsed);
+      await Pref.setString(PrefKeys.paymeId, id);
+    }
+
+    final box = await Hive.openBox<Payment>('other_payments');
+    final payments = box.values.toList();
+    for (int i = 0; i < payments.length; i++) {
+      if (payments[i].name == name) {
+        payments[i].isAdded = isUsed;
+        await box.putAt(i, payments[i]);
+        break;
       }
     }
-    return const SyncFetchResult.done(0);
+
+    await OrganizationSingleton.setOtherPayments();
+    if (mounted && context.mounted) {
+      Provider.of<OrderingProvider4>(context, listen: false).notifyListeners();
+    }
+  }
+
+  static int? _asInt(dynamic v) =>
+      v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
+
+  static Map<String, dynamic> _asMap(dynamic v) =>
+      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
+
+  static List<dynamic> _asList(dynamic v) => v is List ? v : const <dynamic>[];
+
+  /// `category_ids` dan mahsulot kategoriyasi. null yoki bo'sh bo'lsa null —
+  /// ilgari `as List` bilan cast qilinib, null kelganda butun oyna yiqilardi.
+  static List<CategoriesFromProducts>? categoriesFromIds(dynamic ids) {
+    if (ids is! List || ids.isEmpty) return null;
+    return getCategories(ids.first);
   }
 
   static Future<bool> import(BuildContext context) async {
@@ -250,24 +253,25 @@ class ProductsWsService {
   static Future<bool> _import(BuildContext context) async {
     DateTime time = DateTime.now();
     List<ItemModel> allProducts = [];
+    final Set<String> skippedIds = <String>{};
     await TasnifService.setPackageCode();
 
     HttpResult httpResult = await OrdersService.getItems();
 
-
-
     if (httpResult.isSuccess) {
       try {
-        var decodedJson = json.decode(httpResult.result);
+        final dynamic decodedJson = httpResult.result is String
+            ? json.decode(httpResult.result)
+            : httpResult.result;
 
         if (decodedJson is List) {
-          List<ItemModel> i = List<ItemModel>.from(
-            decodedJson.map((e) {
-              return ItemModel.fromJson(e);
-            }),
-          ).toList();
-          i = ItemsSingleton.addPackageCodeAndMxikCode(
-            i,
+          // Bitta buzuq yozuv butun 43 MB importni yiqitmasin — u
+          // o'tkazib yuboriladi va log'ga yoziladi (parseCatalog).
+          final CatalogParseResult parsed =
+              await ItemsSingleton.parseCatalog(decodedJson);
+          skippedIds.addAll(parsed.skippedIds);
+          List<ItemModel> i = ItemsSingleton.addPackageCodeAndMxikCode(
+            parsed.items,
             Pref.getString(PrefKeys.mxikCode, ''),
             Pref.getString(PrefKeys.packageCode, ''),
           );
@@ -277,16 +281,23 @@ class ProductsWsService {
           return false;
         }
       } catch (e) {
+        await LogHelper.activity('SYNC_CATALOG_PARSE_FAILED', {'error': e});
         return false;
       }
     }
 
-    await Pref.setInt(PrefKeys.lastSyncTime, time.millisecondsSinceEpoch);
     if (allProducts.isNotEmpty) {
-      await ItemsSingleton.clearAndPutItems(allProducts);
+      // Faqat haqiqiy muvaffaqiyatda — ilgari yiqilgan yuklash ham
+      // "oxirgi yangilanish" vaqtini surib qo'yardi.
+      await Pref.setInt(PrefKeys.lastSyncTime, time.millisecondsSinceEpoch);
+      // `skippedIds`: bu safar parse bo'lmagan mahsulotlar "serverda yo'q"
+      // deb o'chirilmaydi (parseCatalog dokumentatsiyasiga qarang).
+      await ItemsSingleton.clearAndPutItems(allProducts,
+          preserveIds: skippedIds);
       CategorySingleton.init();
       await ItemsSingleton.storeProducts();
       SchedulerBinding.instance.addPostFrameCallback((_) {
+        if (!context.mounted) return;
         Provider.of<OrderingProvider4>(context, listen: false).pressAllPath();
       });
       allProducts.clear();
@@ -297,21 +308,26 @@ class ProductsWsService {
     return false;
   }
 
+  /// Kategoriya id'sidan mahsulot uchun kategoriya yozuvi.
+  ///
+  /// Kategoriya hali lokalga kelmagan bo'lsa ham id SAQLANADI: UI mahsulotni
+  /// kategoriya bo'yicha aynan id orqali filtrlaydi, nomi kategoriya oqimi
+  /// bilan keladi (u darhol so'raladi — `requestCategoriesRefresh`). Ilgari
+  /// bunday mahsulot kategoriyasiz qolar va to'liq yuklashgacha o'z
+  /// kategoriyasida ko'rinmasdi.
   static List<CategoriesFromProducts>? getCategories(dynamic message) {
-    List<CategoriesFromProducts> categories = [];
+    final String id = message?.toString() ?? '';
+    if (id.isEmpty) return null;
+
+    CategoryData? local;
     final Box<CategoryData> categoriesModel = HiveBoxes.getCategories();
-    CategoryData categoryData = CategoryData();
-    for (CategoryData c in categoriesModel.values.toList()) {
-      if (c.id != null && c.id == message) {
-        categoryData = c;
+    for (CategoryData c in categoriesModel.values) {
+      if (c.id == id) {
+        local = c;
         break;
       }
     }
-    categories.add(
-        CategoriesFromProducts(id: categoryData.id, name: categoryData.name));
-    if (categoryData.id == null || categoryData.id!.isEmpty) {
-      return null;
-    }
-    return categories;
+    if (local == null) CatchUpSync.requestCategoriesRefresh();
+    return [CategoriesFromProducts(id: id, name: local?.name)];
   }
 }
```

### 6.7. `lib/changes/services/web_socket_service/category/categories_ws_service.dart`

```diff
diff --git a/lib/changes/services/web_socket_service/category/categories_ws_service.dart b/lib/changes/services/web_socket_service/category/categories_ws_service.dart
index 53f4898..e0c4144 100644
--- a/lib/changes/services/web_socket_service/category/categories_ws_service.dart
+++ b/lib/changes/services/web_socket_service/category/categories_ws_service.dart
@@ -1,113 +1,70 @@
 // ignore_for_file: use_build_context_synchronously, invalid_use_of_protected_member
 
-import 'dart:convert';
 import 'package:flutter/foundation.dart';
 import 'package:flutter/material.dart';
-import 'package:http/http.dart' as http;
 
-import '../../../../alice_service.dart';
 import '../../../../features/features.dart';
-import '../../../../features/get_products/singletons/items_singleton.dart';
-import '../../../../utils/constants/constants.dart';
-import '../../../../utils/helpers/helpers.dart';
 import '../../log_helper.dart';
+import '../../sync/notification_fetch.dart';
 import '../../sync/sync_cursor.dart';
-import '../urls/urls.dart';
+import '../product/products_ws_service.dart';
 
+/*
+    Kategoriya oqimi: 10 — yaratish, 11 — yangilash, 12 — o'chirish.
+    So'rov/tartiblash/xatoga chidamlilik NotificationFetch'da.
+*/
 class CategoriesWsService {
   CategoriesWsService._();
 
-  static const int limit = 1000;
+  static const int limit = NotificationFetch.limit;
+
+  static const String types = '10,11,12';
 
   static Future<SyncFetchResult> getReceivedWS(bool mounted,
       BuildContext context, String startDate, String endDate) async {
     try {
-      return await _fetch(startDate, endDate);
-    } catch (e) {
+      return await NotificationFetch.run(
+        label: 'Category',
+        types: types,
+        startDate: startDate,
+        endDate: endDate,
+        apply: _apply,
+        afterBatch: ProductsWsService.refreshCaches,
+      );
+    } catch (e, stack) {
       if (kDebugMode) {
         print('❌ Category notification xatosi: $e');
       }
+      await LogHelper.activity('SYNC_FETCH_CRASH',
+          {'stream': 'Category', 'error': e, 'stack': stack});
       return const SyncFetchResult.failed();
     }
   }
 
-  static Future<SyncFetchResult> _fetch(
-      String startDate, String endDate) async {
-    final token = Pref.getString(PrefKeys.token, 'not initialized');
-
-    if (token.isEmpty || token == 'not initialized') {
-      return const SyncFetchResult.failed();
-    }
-
-    String comId = Pref.getString(PrefKeys.orgID, "");
-    final headers = <String, String>{
-      "timezone": "-300",
-      "Vary": "Origin",
-      "Strict-Transport-Security": "Strict-Transport-Security",
-      "Content-Type": "application/json",
-      "Access-Control-Allow-Origin": "*",
-      "Authorization": "Bearer $token"
-    };
-    final String path =
-        "${Urls.baseNotificationUrl}notifications?company_id=$comId&limit=$limit&offset=1&type=10,11,12&is_read=false&start_date=$startDate&end_date=$endDate";
-    http.Response response = await http
-        .get(
-          Uri.parse(path),
-          headers: headers,
-        )
-        .timeout(const Duration(seconds: 20));
-    await LogHelper.logRequest(
-        method: "GET",
-        path: path,
-        statusCode: response.statusCode,
-        response: response.body);
+  static Future<NotifyApply> _apply(Map<String, dynamic> ws) async {
+    final dynamic rawType = ws['type'];
+    final int? type = rawType is int ? rawType : int.tryParse('$rawType');
+    final dynamic data = ws['data'];
 
-    alice.onHttpResponse(response);
-    if (kDebugMode) {
-      print('☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️ - Category Get - ☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️');
+    switch (type) {
+      case 10:
+        await CategorySingleton.putCategories([CategoryData.fromJson(_asMap(data))]);
+        return NotifyApply.applied;
+      case 11:
+        await CategorySingleton.editCategory(CategoryData.fromJson(_asMap(data)));
+        return NotifyApply.applied;
+      case 12:
+        final String id = data is Map ? (data['id']?.toString() ?? '') : '';
+        if (id.isEmpty) throw const FormatException('kategoriya id yo\'q');
+        await CategorySingleton.deleteCategories(id);
+        return NotifyApply.applied;
+      default:
+        return NotifyApply.ignored;
     }
-    if (response.statusCode != 200) {
-      return const SyncFetchResult.failed();
-    }
-    {
-      if (jsonDecode(utf8.decode(response.bodyBytes))['notifications'] !=
-          null) {
-        List<String> deleteIds = [];
-        List notification =
-            jsonDecode(utf8.decode(response.bodyBytes))['notifications'];
+  }
 
-        for (var ws in notification) {
-          if (ws['id'] != null) {
-            if (ws['type'] == 10) {
-              CategoryData categoryData = CategoryData.fromJson(ws['data']);
-              await CategorySingleton.putCategories([categoryData]);
-              await ItemsSingleton.storeProducts();
-              CategorySingleton.init();
-              deleteIds.add(ws['id']);
-            }
-            if (ws['type'] == 11) {
-              CategoryData? categoryData = CategoryData.fromJson(ws['data']);
-              await CategorySingleton.editCategory(categoryData);
-              CategorySingleton.init();
-              await ItemsSingleton.storeProducts();
-              deleteIds.add(ws['id']);
-            }
-            if (ws['type'] == 12) {
-              await CategorySingleton.deleteCategories(ws['data']['id']);
-              await ItemsSingleton.storeProducts();
-              CategorySingleton.init();
-              deleteIds.add(ws['id']);
-            }
-          }
-        }
-        if (deleteIds.isNotEmpty) {
-          // await sendReceivedWS(deleteIds);
-          deleteIds = [];
-        }
-        return SyncFetchResult.done(notification.length,
-            truncated: notification.length >= limit);
-      }
-    }
-    return const SyncFetchResult.done(0);
+  static Map<String, dynamic> _asMap(dynamic v) {
+    if (v is Map) return Map<String, dynamic>.from(v);
+    throw const FormatException('notification data bo\'sh');
   }
 }
```

### 6.8. `lib/changes/services/web_socket_service/discount/discount_ws_service.dart`

```diff
diff --git a/lib/changes/services/web_socket_service/discount/discount_ws_service.dart b/lib/changes/services/web_socket_service/discount/discount_ws_service.dart
index 8cb986c..547e72b 100644
--- a/lib/changes/services/web_socket_service/discount/discount_ws_service.dart
+++ b/lib/changes/services/web_socket_service/discount/discount_ws_service.dart
@@ -1,96 +1,73 @@
 // ignore_for_file: use_build_context_synchronously, invalid_use_of_protected_member
 
-import 'dart:convert';
 import 'package:flutter/foundation.dart';
 import 'package:flutter/material.dart';
-import 'package:http/http.dart' as http;
 import 'package:invan2/changes/services/log_helper.dart';
+import 'package:invan2/changes/services/sync/notification_fetch.dart';
 import 'package:invan2/changes/services/sync/sync_cursor.dart';
-import 'package:invan2/changes/services/web_socket_service/urls/urls.dart';
 
-import '../../../../alice_service.dart';
 import '../../../../features/get_discounts/get_discounts.dart';
-import '../../../../utils/constants/constants.dart';
-import '../../../../utils/helpers/helpers.dart';
 
+/*
+    Diskont oqimi: 15 — yaratish, 16 — yangilash, 17 — o'chirish.
+    So'rov/tartiblash/xatoga chidamlilik NotificationFetch'da.
+
+    Bundan tashqari DiscountAutoSyncService har 10 daqiqada to'liq ro'yxat
+    bilan tenglashtiradi — bu oqim uzilishlarni tezroq qoplash uchun.
+*/
 class DiscountWsService {
   DiscountWsService._();
 
-  static const int limit = 1000;
+  static const int limit = NotificationFetch.limit;
+
+  static const String types = '15,16,17';
 
   static Future<SyncFetchResult> getReceivedWS(bool mounted,
       BuildContext context, String startDate, String endDate) async {
     try {
-      return await _fetch(startDate, endDate);
-    } catch (e) {
+      return await NotificationFetch.run(
+        label: 'Discount',
+        types: types,
+        startDate: startDate,
+        endDate: endDate,
+        apply: _apply,
+      );
+    } catch (e, stack) {
       if (kDebugMode) {
         print('❌ Discount notification xatosi: $e');
       }
+      await LogHelper.activity('SYNC_FETCH_CRASH',
+          {'stream': 'Discount', 'error': e, 'stack': stack});
       return const SyncFetchResult.failed();
     }
   }
 
-  static Future<SyncFetchResult> _fetch(
-      String startDate, String endDate) async {
-    final token = Pref.getString(PrefKeys.token, 'not initialized');
-    if (token.isEmpty || token == 'not initialized') {
-      return const SyncFetchResult.failed();
-    }
+  static Future<NotifyApply> _apply(Map<String, dynamic> ws) async {
+    final dynamic rawType = ws['type'];
+    final int? type = rawType is int ? rawType : int.tryParse('$rawType');
+    final dynamic data = ws['data'];
 
-    String comId = Pref.getString(PrefKeys.orgID, "");
-    final headers = <String, String>{
-      "timezone": "-300",
-      "Vary": "Origin",
-      "Strict-Transport-Security": "Strict-Transport-Security",
-      "Content-Type": "application/json",
-      "Access-Control-Allow-Origin": "*",
-      "Authorization": "Bearer $token"
-    };
-    final String path =
-        "${Urls.baseNotificationUrl}notifications?company_id=$comId&limit=$limit&offset=1&type=15,16,17&is_read=false&start_date=$startDate&end_date=$endDate";
-    http.Response response = await http
-        .get(
-          Uri.parse(path),
-          headers: headers,
-        )
-        .timeout(const Duration(seconds: 20));
-    await LogHelper.logRequest(
-        method: "GET",
-        path: path,
-        statusCode: response.statusCode,
-        response: response.body);
-    alice.onHttpResponse(response);
-    if (kDebugMode) {
-      print('☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️ - Discount Get - ☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️');
+    // Ilgari bu chaqiruvlar `await`siz edi: Hive yozuvi yiqilsa xato
+    // yutilar, kursor esa baribir surilardi.
+    switch (type) {
+      case 15:
+        await DiscountService.createDiscount(DiscountItem.fromJson(_asMap(data)));
+        return NotifyApply.applied;
+      case 16:
+        await DiscountService.updateDiscount(DiscountItem.fromJson(_asMap(data)));
+        return NotifyApply.applied;
+      case 17:
+        final String id = data is Map ? (data['id']?.toString() ?? '') : '';
+        if (id.isEmpty) throw const FormatException('diskont id yo\'q');
+        await DiscountService.deleteDiscount(id);
+        return NotifyApply.applied;
+      default:
+        return NotifyApply.ignored;
     }
-    if (response.statusCode != 200) {
-      return const SyncFetchResult.failed();
-    }
-    {
-      if (jsonDecode(utf8.decode(response.bodyBytes))['notifications'] !=
-          null) {
-        List notification =
-            jsonDecode(utf8.decode(response.bodyBytes))['notifications'];
+  }
 
-        for (var ws in notification) {
-          if (ws['id'] != null) {
-            if (ws['type'] == 15) {
-              DiscountItem discountItem = DiscountItem.fromJson(ws['data']);
-              DiscountService.createDiscount(discountItem);
-            }
-            if (ws['type'] == 16) {
-              DiscountItem discountItem = DiscountItem.fromJson(ws['data']);
-              DiscountService.updateDiscount(discountItem);
-            }
-            if (ws['type'] == 17) {
-              DiscountService.deleteDiscount(ws['data']['id']);
-            }
-          }
-        }
-        return SyncFetchResult.done(notification.length,
-            truncated: notification.length >= limit);
-      }
-    }
-    return const SyncFetchResult.done(0);
+  static Map<String, dynamic> _asMap(dynamic v) {
+    if (v is Map) return Map<String, dynamic>.from(v);
+    throw const FormatException('notification data bo\'sh');
   }
 }
```

### 6.9. `lib/changes/services/web_socket_service/urls/urls.dart`

```diff
diff --git a/lib/changes/services/web_socket_service/urls/urls.dart b/lib/changes/services/web_socket_service/urls/urls.dart
index 09e40c8..52fd4b4 100644
--- a/lib/changes/services/web_socket_service/urls/urls.dart
+++ b/lib/changes/services/web_socket_service/urls/urls.dart
@@ -2,14 +2,22 @@
     @author Ayyubxon Ahmajonov, 11/11/2024, 4:06 PM
 */
 
+import '../../api/api_provider.dart';
+
+/// Notification/socket manzillari API muhitidan (ApiProvider) keltirib
+/// chiqariladi — ilgari ikkita alohida qo'lda o'zgartiriladigan konstanta
+/// edi va API DEV'da, notification PRO'da qolib ketardi (DEV token PRO
+/// notification serveriga ketar, sinxron jimgina ishlamasdi).
 class Urls {
-static String socketUrlPro = 'wss://ws.notification.7i.uz/';
-static String socketUrlDev = 'wss://dev-ws.notification.7i.uz/';
-static String notificationUrlPro = 'https://ws.notification.7i.uz/';
-static String notificationUrlDev = 'https://dev-ws.notification.7i.uz/';
-static String baseSocketUrl = socketUrlPro;
-static String baseNotificationUrl = notificationUrlPro;
-  // static String baseNotificationUrl = notificationUrlDev;
-  // static String baseSocketUrl = socketUrlDev;
-
-}
\ No newline at end of file
+  static const String socketUrlPro = 'wss://ws.notification.7i.uz/';
+  static const String socketUrlDev = 'wss://dev-ws.notification.7i.uz/';
+  static const String notificationUrlPro = 'https://ws.notification.7i.uz/';
+  static const String notificationUrlDev = 'https://dev-ws.notification.7i.uz/';
+
+  static bool get _isPro => ApiProvider.currentEnv == ApiProvider.envPro;
+
+  static String get baseSocketUrl => _isPro ? socketUrlPro : socketUrlDev;
+
+  static String get baseNotificationUrl =>
+      _isPro ? notificationUrlPro : notificationUrlDev;
+}
```

### 6.10. `lib/features/get_products/singletons/items_singleton.dart`

```diff
diff --git a/lib/features/get_products/singletons/items_singleton.dart b/lib/features/get_products/singletons/items_singleton.dart
index b8aa0f6..cc82713 100644
--- a/lib/features/get_products/singletons/items_singleton.dart
+++ b/lib/features/get_products/singletons/items_singleton.dart
@@ -10,6 +10,7 @@ import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/mo
 import '../../../changes/components/tranlator.dart';
 import '../../../changes/providers/ordering_provider_4.dart';
 import '../../../changes/services/web_socket_service/product/model/product_price_edit_response.dart';
+import '../../../changes/services/log_helper.dart';
 import '../../../utils/util_functions.dart';
 import '../../../utils/utils.dart';
 
@@ -435,11 +436,72 @@ static Future<void> storeProducts() async {
   //   return;
   // }
 
-  static Future<void> clearAndPutItems(List<ItemModel> items) async {
+  /// Katalogni to'liq almashtiradi.
+  ///
+  /// Ilgari `box.clear()` + `putAll` edi: clear faylni 0 baytga qisqartirar,
+  /// putAll o'rtada yiqilsa (fayl qulfi, disk to'lgan, ilova o'ldirildi,
+  /// svet o'chdi) katalog bo'sh/yarim qolar, kursor esa "hammasi bor" deb
+  /// turardi. Endi: avval hammasi ustidan yoziladi (eski fayl butun
+  /// qoladi), keyin serverda yo'q qolgan yozuvlar o'chiriladi, oxirida
+  /// diskka flush. Butun jarayon marker bilan o'raladi — ilova o'rtada
+  /// o'lsa keyingi sinxron kursorni tashlab to'liq yuklashni qaytaradi
+  /// (CatchUpSync.healCatalogState).
+  ///
+  /// [preserveIds] — bu safar parse bo'lmagan (shuning uchun [items] da
+  /// yo'q) mahsulot id'lari (`parseCatalog().skippedIds`). Ular "serverda
+  /// yo'q" deb O'CHIRILMAYDI — biz shunchaki bu safar ularni o'qiy olmadik.
+  /// Aks holda bitta buzuq maydonli yozuv (masalan noto'g'ri son formati)
+  /// o'sha mahsulotni har to'liq yuklashda kassadan yo'qotib turardi.
+  static Future<void> clearAndPutItems(
+    List<ItemModel> items, {
+    Set<dynamic> preserveIds = const <dynamic>{},
+  }) async {
     final box = HiveBoxes.getProducts();
-    await box.clear();
-    final map = {for (var e in items) (e).key: e};
+    final Map<dynamic, ItemModel> map = {for (var e in items) (e).key: e};
+    final List<dynamic> stale = box.keys
+        .where((k) => !map.containsKey(k) && !preserveIds.contains(k))
+        .toList();
+    await Pref.setBool(PrefKeys.catalogWriteInProgress, true);
     await box.putAll(map);
+    if (stale.isNotEmpty) await box.deleteAll(stale);
+    await box.flush();
+    await Pref.setBool(PrefKeys.catalogWriteInProgress, false);
+  }
+
+  /// To'liq katalog JSON ro'yxatini modelga o'tkazadi — har yozuv alohida
+  /// himoyada. Ilgari bitta buzuq yozuv (masalan `min_quantity: 1.0`)
+  /// butun importni yiqitar va sinxron abadiy muzlab qolardi.
+  static Future<CatalogParseResult> parseCatalog(List<dynamic> raw) async {
+    final List<ItemModel> items = <ItemModel>[];
+    final Set<String> skippedIds = <String>{};
+    int failed = 0;
+    Object? firstError;
+    for (final dynamic e in raw) {
+      try {
+        if (e is! Map) throw FormatException('yozuv obyekt emas: $e');
+        items.add(ItemModel.fromJson(Map<String, dynamic>.from(e)));
+      } catch (err) {
+        failed++;
+        firstError ??= err;
+        // Id'ni bo'lak qismidan ham (kengroq himoyada) olishga urinamiz —
+        // topilsa, `clearAndPutItems` bu mahsulotni o'chirmaydi.
+        try {
+          if (e is Map) {
+            final dynamic id = e['id'];
+            if (id != null) skippedIds.add(id.toString());
+          }
+        } catch (_) {}
+      }
+    }
+    if (failed > 0) {
+      await LogHelper.activity('SYNC_CATALOG_PARSE_SKIPPED', {
+        'skipped': failed,
+        'total': raw.length,
+        'first_error': firstError,
+        'skipped_ids_known': skippedIds.length,
+      });
+    }
+    return CatalogParseResult(items, failed, firstError, skippedIds);
   }
 
   static Future<void> deleteProduct(List<String> items) async {
@@ -450,7 +512,27 @@ static Future<void> storeProducts() async {
     return;
   }
 
-  static Future<void> putItems(List<ItemModel> items) async {
+  /// Mahsulotlarni lokalga yozadi (id bo'yicha ustidan yozish).
+  ///
+  /// `is_active == false` bo'lsagina o'chiriladi. Ilgari `!(isActive ?? false)`
+  /// edi — payload'da maydon bo'lmasa (null) mahsulot O'CHIRILARDI.
+  ///
+  /// [mergeWithExisting] — notification yo'li uchun: kelgan yozuv to'liq
+  /// katalogdan kambag'alroq bo'lishi mumkin, shuning uchun
+  ///  * `shop_prices` KALITI payload'da umuman bo'lmasa, lokaldagi mavjud
+  ///    narx saqlanadi (ilgari mahsulot narxsiz qolib skanerda topilmasdi).
+  ///    [priceKeyPresent] shu signalni beradi — FAQAT kalit yo'qligida
+  ///    saqlanadi, kalit BOR-U natija 0/topilmadi bo'lsa (server ataylab
+  ///    narxni olib tashlagan/0 qilgan) hurmat qilinadi, eski narx
+  ///    ustidan yozilmasdan qolib ketmaydi;
+  ///  * parser bilmaydigan/lokalda topilmagan maydonlar (ownerType,
+  ///    commissionTin, mark, o'lchov birligi, QQS) mavjud yozuvdan olinadi —
+  ///    aks holda fiskal chekda OwnerType/QQS noto'g'ri ketardi.
+  static Future<void> putItems(
+    List<ItemModel> items, {
+    bool mergeWithExisting = false,
+    bool priceKeyPresent = true,
+  }) async {
     items = addPackageCodeAndMxikCode(
       items,
       Pref.getString(PrefKeys.mxikCode, ''),
@@ -460,13 +542,19 @@ static Future<void> storeProducts() async {
     Map<String, ItemModel> map = {};
     for (var item in items) {
       if (item.id == null) continue;
-      if (!(item.isActive ?? false)) {
+      if (item.isActive == false) {
         await deleteProduct([item.id!]);
       } else {
-        // Mavjud productning isMarking qiymatini saqlash
         final existing = box.get(item.id);
-        if (existing != null && (existing.isMarking == true)) {
-          item = item.copyWith(isMarking: true);
+        if (existing != null) {
+          // Mavjud productning isMarking qiymatini saqlash
+          if (existing.isMarking == true) {
+            item = item.copyWith(isMarking: true);
+          }
+          if (mergeWithExisting) {
+            item = _mergeFromExisting(item, existing,
+                priceKeyPresent: priceKeyPresent);
+          }
         }
         map[item.id!] = item;
       }
@@ -475,37 +563,90 @@ static Future<void> storeProducts() async {
     return;
   }
 
-  static Future<void> editItem(ProductPriceEdit priceEdit) async {
-    Box<ItemModel> box = HiveBoxes.getProducts();
-
-    List<ProductsValues>? productsValues = priceEdit.data?.productsValues;
-
-    if (productsValues != null && productsValues.isNotEmpty) {
-      for (ProductsValues p in productsValues) {
-        ItemModel? item = box.get(p.productId);
-        if (item != null) {
-          if (item.shopPrices?.shID?.shopId == p.price?.shopId) {
-            if (p.price != null &&
-                p.price!.shopPriceTiers != null &&
-                item.shopPrices != null &&
-                item.shopPrices!.shID != null &&
-                item.shopPrices!.shID!.shopPriceTiers != null) {
-              item.shopPrices!.shID!.shopPriceTiers!.clear();
-              for (ShopPriceTiersSub sh in p.price!.shopPriceTiers!) {
-                item.shopPrices!.shID!.shopPriceTiers!.add(
-                  ShopPriceTiers(
-                    minQuantity: sh.minQuantity,
-                    retailPrice: sh.retailPrice,
-                  ),
-                );
-              }
-            }
-          }
-          await box.put(item.id, item);
-        }
+  static ItemModel _mergeFromExisting(ItemModel item, ItemModel existing,
+      {required bool priceKeyPresent}) {
+    if (!priceKeyPresent &&
+        onePrice(item.shopPrices) <= 0 &&
+        onePrice(existing.shopPrices) > 0) {
+      item = item.copyWith(shopPrices: existing.shopPrices);
+      LogHelper.activity('SYNC_PRICE_KEPT', {'id': item.id});
+    }
+    // copyWith `??` bilan ishlaydi: faqat kelgan qiymat null bo'lganda
+    // mavjudini beramiz, aks holda kelgan qiymat ustun.
+    if (item.ownerType == null && existing.ownerType != null) {
+      item = item.copyWith(ownerType: existing.ownerType);
+    }
+    if (item.commissionTin == null && existing.commissionTin != null) {
+      item = item.copyWith(commissionTin: existing.commissionTin);
+    }
+    if (item.mark == null && existing.mark != null) {
+      item = item.copyWith(mark: existing.mark);
+    }
+    final bool unitMissing =
+        item.measurementUnit == null || (item.measurementUnit!.id ?? '').isEmpty;
+    if (unitMissing && existing.measurementUnit != null) {
+      item = item.copyWith(measurementUnit: existing.measurementUnit);
+    }
+    final bool vatMissing = item.vat == null || (item.vat!.id ?? '').isEmpty;
+    if (vatMissing && existing.vat != null) {
+      item = item.copyWith(vat: existing.vat);
+    }
+    return item;
+  }
+
+  /// Narx o'zgarishi (notification type 13) — shu do'kon uchun narx
+  /// pog'onalarini almashtiradi.
+  ///
+  /// Mahsulotda hali shu do'kon narxi BO'LMASA ham yaratiladi. Ilgari faqat
+  /// mavjud `shopPriceTiers` ro'yxati yangilanardi: mahsulot avval boshqa
+  /// do'kon uchun yaratilib, keyin shu do'konga narx qo'yilsa (yoki type 1
+  /// payload'ida narx bo'lmasa) narx hech qachon yetib bormas, mahsulot
+  /// to'liq yuklashgacha skanerda topilmasdi.
+  ///
+  /// Qaytadi: nechta mahsulot yangilandi.
+  static Future<int> editItem(ProductPriceEdit priceEdit) async {
+    final Box<ItemModel> box = HiveBoxes.getProducts();
+    final String myShop = Pref.getString(PrefKeys.storeId, '');
+    final List<ProductsValues>? productsValues = priceEdit.data?.productsValues;
+    if (productsValues == null || productsValues.isEmpty) return 0;
+
+    int changed = 0;
+    for (final ProductsValues p in productsValues) {
+      final String? productId = p.productId;
+      if (productId == null || productId.isEmpty) continue;
+      final ItemModel? item = box.get(productId);
+      if (item == null) continue;
+
+      final Price? price = p.price;
+      final String targetShop = price?.shopId ?? '';
+      if (price == null || price.shopPriceTiers == null || targetShop.isEmpty) {
+        continue;
       }
+
+      // Faqat shu kassaning do'koni (yoki mahsulotda allaqachon turgan
+      // do'kon — eski xulq bilan mos). Boshqa do'kon narxi e'tiborsiz.
+      final bool mine = targetShop == myShop ||
+          targetShop == item.shopPrices?.shID?.shopId;
+      if (!mine) continue;
+
+      final List<ShopPriceTiers> tiers = price.shopPriceTiers!
+          .map((sh) => ShopPriceTiers(
+                minQuantity: sh.minQuantity,
+                retailPrice: sh.retailPrice,
+              ))
+          .toList();
+      final ShID? existing = item.shopPrices?.shID;
+      item.shopPrices = ShopPrices(
+        shID: ShID(
+          shopId: targetShop,
+          supplyPrice: price.supplyPrice ?? existing?.supplyPrice,
+          shopPriceTiers: tiers,
+        ),
+      );
+      await box.put(item.id, item);
+      changed++;
     }
-    return;
+    return changed;
   }
 
   static Future<void> editMxik(List<MxikCodes> mxikUpdates) async {
@@ -593,3 +734,18 @@ static Future<void> storeProducts() async {
     return i;
   }
 }
+
+/// To'liq katalogni parse qilish natijasi.
+class CatalogParseResult {
+  final List<ItemModel> items;
+  final int failed;
+  final Object? firstError;
+
+  /// Parse bo'lmagan, lekin id'si aniqlangan yozuvlar. `clearAndPutItems`
+  /// ga `preserveIds` sifatida uzatilsa, bu mahsulotlar "serverda yo'q"
+  /// deb o'chirilmaydi.
+  final Set<String> skippedIds;
+
+  const CatalogParseResult(
+      this.items, this.failed, this.firstError, this.skippedIds);
+}
```

### 6.11. `lib/changes/models/product/item_model.dart`

```diff
diff --git a/lib/changes/models/product/item_model.dart b/lib/changes/models/product/item_model.dart
index 65d5ff8..81188d2 100644
--- a/lib/changes/models/product/item_model.dart
+++ b/lib/changes/models/product/item_model.dart
@@ -173,12 +173,7 @@ class ItemModel extends HiveObject {
     shopPrices = json['shop_prices'] != null
         ? ShopPrices.fromJson(json["shop_prices"])
         : null;
-    if (json['categories'] != null) {
-      categories = <CategoriesFromProducts>[];
-      json['categories'].forEach((v) {
-        categories!.add(CategoriesFromProducts.fromJson(v));
-      });
-    }
+    categories = parseCategoriesField(json['categories']);
     measurementUnit = json['measurement_unit'] != null
         ? MeasurementUnit.fromJson(json['measurement_unit'])
         : null;
@@ -186,13 +181,98 @@ class ItemModel extends HiveObject {
     packageCode = json['package_code'];
     packageType = json['package_type'];
     packageName = json['package_name'];
-    ownerType = json['owner_type'];
+    ownerType = json['owner_type']?.toString();
     boxBarcode = json['box_barcode'];
     boxBarcodeQuantity = json['box_barcode_quantity'];
     hasBoxBarcode = json['has_box_barcode'];
     cashsale = ((json['cash_sale'] as num?) ?? 1).toInt();
   }
 
+  /// Notification payload'idagi `images` ro'yxatidan birinchi rasm URL'i.
+  ///
+  /// Ilgari `json['images'][0]` to'g'ridan-to'g'ri o'qilardi: rasmsiz
+  /// mahsulotda server `images: []` yuborsa RangeError chiqar va bu
+  /// notification (u bilan butun oyna) qo'llanmay qolardi.
+  static String? firstImageUrl(dynamic images) {
+    if (images is List && images.isNotEmpty) {
+      final dynamic first = images.first;
+      final dynamic url = first is Map ? first['image_url'] : null;
+      if (url is String && url.isNotEmpty) return ApiProvider.imageUrl + url;
+    }
+    return null;
+  }
+
+  /// `categories` maydonini ikkala ma'lum shaklda ham o'qiydi: to'liq
+  /// katalog/type-2 obyekt ro'yxati (`[{id,name,parent_id}, ...]`) HAM
+  /// eski type-1 sof id ro'yxati (`["id1", "id2"]`). Ilgari type-1
+  /// parseri faqat ikkinchi shaklni kutar edi — server obyekt ro'yxati
+  /// yuborsa, `String?` maydonga `Map` yozilib TypeError bilan butun
+  /// notification (oyna) yiqilardi. Elementlar aralash yoki noma'lum
+  /// shaklda bo'lsa xatosiz o'tkazib yuboriladi.
+  static List<CategoriesFromProducts>? parseCategoriesField(dynamic raw) {
+    if (raw is! List || raw.isEmpty) return null;
+    final List<CategoriesFromProducts> result = <CategoriesFromProducts>[];
+    for (final dynamic v in raw) {
+      try {
+        if (v is Map) {
+          result.add(CategoriesFromProducts.fromJson(Map<String, dynamic>.from(v)));
+        } else if (v is String && v.isNotEmpty) {
+          result.add(CategoriesFromProducts(id: v));
+        }
+      } catch (_) {
+        // Bitta elementning shakli noma'lum — shu elementni o'tkazib
+        // yuboramiz, butun mahsulotni yiqitmaymiz.
+      }
+    }
+    return result.isEmpty ? null : result;
+  }
+
+  /// Notification payload'idan o'lchov birligi: ichki obyekt bo'lsa undan
+  /// (to'liq katalog kabi), bo'lmasa lokal box'dan id bo'yicha. Topilmasa
+  /// null — bo'sh obyekt EMAS: `putItems(mergeWithExisting)` mavjud
+  /// yozuvdagi qiymatni saqlab qoladi (adminkada yangi birlik yaratilib,
+  /// lokal box hali yangilanmagan bo'lsa ham).
+  static MeasurementUnit? resolveMeasurementUnit(dynamic nested, dynamic id) {
+    if (nested is Map) {
+      try {
+        final MeasurementUnit m =
+            MeasurementUnit.fromJson(Map<String, dynamic>.from(nested));
+        if ((m.id ?? '').isNotEmpty) return m;
+      } catch (_) {}
+    }
+    if (id == null) return null;
+    try {
+      for (final MesUnitModel m in HiveBoxes.mesUnitBox().values) {
+        if (m.id == id) {
+          return MeasurementUnit(
+            id: m.id ?? "",
+            longName: m.longName ?? "",
+            shortName: m.shortName ?? "",
+          );
+        }
+      }
+    } catch (_) {}
+    return null;
+  }
+
+  static Vat? resolveVat(dynamic nested, dynamic id) {
+    if (nested is Map) {
+      try {
+        final Vat v = Vat.fromJson(Map<String, dynamic>.from(nested));
+        if ((v.id ?? '').isNotEmpty) return v;
+      } catch (_) {}
+    }
+    if (id == null) return null;
+    try {
+      for (final VatUnitModel v in HiveBoxes.vatUnitBox().values) {
+        if (v.id == id) {
+          return Vat(id: v.id, name: v.name, percentage: v.percentage);
+        }
+      }
+    } catch (_) {}
+    return null;
+  }
+
   ItemModel.fromWebSocketJson(Map<String, dynamic> json) {
     // Notification data'da product ID maydoni 'id' (server fromWebSocketJsonUpdate
     // bilan bir xil). Avval 'product_id' o'qilardi va u null qaytarardi, natijada
@@ -201,13 +281,14 @@ class ItemModel extends HiveObject {
     id = json['id'] ?? json['product_id'];
     sku = json['sku'];
     name = json['name'];
-    image = json['images'] != null
-        ? ApiProvider.imageUrl + json['images'][0]['image_url']
-        : null;
+    image = firstImageUrl(json['images']);
     isMarking = json['is_marking'];
     isActive = json['is_active'];
     mxikCode = json['mxik_code'];
     parentId = json['parent_id'];
+    // Ilgari faqat update parserida bor edi — yangi (type 1) mahsulot
+    // ownerType'siz qolib, fiskal chekda OwnerType noto'g'ri ketardi.
+    ownerType = json['owner_type']?.toString();
     companyId = json['company_id'];
     description = json['description'];
     productTypeId = json['product_type_id'];
@@ -231,45 +312,15 @@ class ItemModel extends HiveObject {
       }
     }
 
-    if (json['categories'] != null) {
-      categories = <CategoriesFromProducts>[];
-      json['categories'].forEach((v) {
-        categories!.add(CategoriesFromProducts(id: v));
-      });
-    }
+    categories = parseCategoriesField(json['categories']);
 
     {
-      List<MesUnitModel> mesUnits = [];
-      final Box<MesUnitModel> mesUnitModel = HiveBoxes.mesUnitBox();
-      mesUnits = mesUnitModel.values.toList().where((e) {
-        return e.id == json['measurement_unit_id'];
-      }).toList();
-      MeasurementUnit mess = MeasurementUnit();
-      if (mesUnits.isNotEmpty) {
-        mess = MeasurementUnit(
-          id: mesUnits.first.id ?? "",
-          longName: mesUnits.first.longName ?? "",
-          shortName: mesUnits.first.shortName ?? "",
-        );
-      }
-      measurementUnit = json['measurement_unit_id'] != null ? mess : null;
+      measurementUnit = resolveMeasurementUnit(
+          json['measurement_unit'], json['measurement_unit_id']);
     }
 
     {
-      List<VatUnitModel> vatUnits = [];
-      final Box<VatUnitModel> vatUnitModel = HiveBoxes.vatUnitBox();
-      vatUnits = vatUnitModel.values.toList().where((e) {
-        return e.id == json['vat_id'];
-      }).toList();
-      Vat vatt = Vat();
-      if (vatUnits.isNotEmpty) {
-        vatt = Vat(
-          id: vatUnits.first.id,
-          name: vatUnits.first.name,
-          percentage: vatUnits.first.percentage,
-        );
-      }
-      vat = json['vat_id'] != null ? vatt : null;
+      vat = resolveVat(json['vat'], json['vat_id']);
     }
 
     packageCode = json['package_code'];
@@ -285,14 +336,12 @@ class ItemModel extends HiveObject {
     id = json['id'];
     sku = json['sku'];
     name = json['name'];
-    image = json['images'] != null
-        ? ApiProvider.imageUrl + json['images'][0]['image_url']
-        : null;
+    image = firstImageUrl(json['images']);
     isMarking = json['is_marking'];
     isActive = json['is_active'];
     mxikCode = json['mxik_code'];
     parentId = json['parent_id'];
-    ownerType = json['owner_type'];
+    ownerType = json['owner_type']?.toString();
     companyId = json['company_id'];
     description = json['description'];
     productTypeId = json['product_type_id'];
@@ -319,46 +368,15 @@ class ItemModel extends HiveObject {
       }
     }
 
-    if (json['categories'] != null) {
-      categories = <CategoriesFromProducts>[];
-      json['categories'].forEach((v) {
-        categories!.add(CategoriesFromProducts.fromJson(v));
-      });
-    }
+    categories = parseCategoriesField(json['categories']);
 
     {
-      List<MesUnitModel> mesUnits = [];
-      final Box<MesUnitModel> mesUnitModel = HiveBoxes.mesUnitBox();
-      mesUnits = mesUnitModel.values.toList().where((e) {
-        return e.id == json['measurement_unit_id'];
-      }).toList();
-
-      MeasurementUnit mess = MeasurementUnit();
-      if (mesUnits.isNotEmpty) {
-        mess = MeasurementUnit(
-          id: mesUnits.first.id ?? "",
-          shortName: mesUnits.first.shortName ?? "",
-          longName: mesUnits.first.longName ?? "",
-        );
-      }
-      measurementUnit = json['measurement_unit_id'] != null ? mess : null;
+      measurementUnit = resolveMeasurementUnit(
+          json['measurement_unit'], json['measurement_unit_id']);
     }
 
     {
-      List<VatUnitModel> vatUnits = [];
-      final Box<VatUnitModel> vatUnitModel = HiveBoxes.vatUnitBox();
-      vatUnits = vatUnitModel.values.toList().where((e) {
-        return e.id == json['vat_id'];
-      }).toList();
-      Vat vatt = Vat();
-      if (vatUnits.isNotEmpty) {
-        vatt = Vat(
-          id: vatUnits.first.id,
-          name: vatUnits.first.name,
-          percentage: vatUnits.first.percentage,
-        );
-      }
-      vat = json['vat_id'] != null ? vatt : null;
+      vat = resolveVat(json['vat'], json['vat_id']);
       packageCode = json['package_code'];
       packageType = json['package_type'];
       packageName = json['package_name'];
@@ -480,8 +498,23 @@ class ShopPriceTiers extends HiveObject {
   ShopPriceTiers({this.minQuantity, this.retailPrice});
 
   ShopPriceTiers.fromJson(Map<String, dynamic> json) {
-    minQuantity = json['min_quantity'];
-    retailPrice = json['retail_price'];
+    // `1.0` (double) yoki "1" (satr) kelsa ham yiqilmasin — bitta buzuq
+    // yozuv butun katalog importini to'xtatardi.
+    minQuantity = _toInt(json['min_quantity']);
+    retailPrice = _toNum(json['retail_price']);
+  }
+
+  static int? _toInt(dynamic v) {
+    if (v is int) return v;
+    if (v is num) return v.toInt();
+    if (v is String) return num.tryParse(v)?.toInt();
+    return null;
+  }
+
+  static num? _toNum(dynamic v) {
+    if (v is num) return v;
+    if (v is String) return num.tryParse(v);
+    return null;
   }
 
   Map<String, dynamic> toJson() {
```

### 6.12. `lib/changes/providers/update_provider.dart`

```diff
diff --git a/lib/changes/providers/update_provider.dart b/lib/changes/providers/update_provider.dart
index 0b5f3e6..657af71 100644
--- a/lib/changes/providers/update_provider.dart
+++ b/lib/changes/providers/update_provider.dart
@@ -1,6 +1,8 @@
 // ignore_for_file: use_build_context_synchronously
 
 import 'dart:async';
+import 'package:invan2/app_navigation.dart';
+import 'package:invan2/changes/services/log_helper.dart';
 import 'package:invan2/changes/services/sync/catch_up_sync.dart';
 import 'package:invan2/utils/util_functions.dart';
 import 'package:invan2/utils/utils.dart';
@@ -14,6 +16,20 @@ class UpdateProvider extends ChangeNotifier {
   /// NetworkSuccess har safar kelganda chaqirilishi mumkin, shuning uchun
   /// bir vaqtda bittadan ortiq halqa ishlamasligi ta'minlangan (ilgari har
   /// bir qayta ulanishda yangi cheksiz halqa qo'shilib borardi).
+  ///
+  /// Halqa HECH QACHON o'lmasligi kerak: u faqat NetworkSuccess'da (internet
+  /// holati O'ZGARGANDA) ishga tushadi. Ilgari bitta istisno (masalan
+  /// Windows'da antivirus ushlab turgan Hive faylga yozuv) halqani yiqitar
+  /// va internet barqaror kassada sinxron restartgacha to'xtab qolardi.
+  ///
+  /// [context]/[mounted] FAQAT birinchi tekshiruv uchun — halqaning o'zi
+  /// har tsiklda YANGI, doimiy yashovchi context oladi
+  /// (`AppNavigation.navigatorKey`). Sabab: bu metod endi `Wrapper`
+  /// (startup) dan ham chaqiriladi, uning context'i navigatsiyadan bir necha
+  /// qator keyin UNMOUNT bo'ladi — o'sha context bilan halqa umrbod
+  /// "context o'chgan" deb hech narsa qilmay, lekin `_autoUpdateRunning`
+  /// bayrog'ini abadiy band qilib turgan bo'lardi (boshqa — to'g'ri —
+  /// chaqiruv ham ishga tushmasdi).
   Future<void> autoUpdate(BuildContext context, bool mounted) async {
     if (_autoUpdateRunning) return;
 
@@ -26,7 +42,20 @@ class UpdateProvider extends ChangeNotifier {
     try {
       while (true) {
         await Future.delayed(period);
-        await startPeriodicRequest(context, mounted);
+        try {
+          final BuildContext? liveContext =
+              AppNavigation.navigatorKey.currentContext;
+          if (liveContext == null || !liveContext.mounted) {
+            // Navigator hali qurilmagan (juda erta) yoki ilova yopilayotgan
+            // bo'lishi mumkin — halqa o'lmaydi, keyingi tsiklda qayta
+            // urinadi.
+            continue;
+          }
+          await startPeriodicRequest(liveContext, true);
+        } catch (e, stack) {
+          await LogHelper.activity(
+              'SYNC_LOOP_ERROR', {'error': e, 'stack': stack});
+        }
       }
     } finally {
       _autoUpdateRunning = false;
```

### 6.13. `lib/app/wrapper/wrapper.dart`

```diff
diff --git a/lib/app/wrapper/wrapper.dart b/lib/app/wrapper/wrapper.dart
index 80a0a54..5577117 100644
--- a/lib/app/wrapper/wrapper.dart
+++ b/lib/app/wrapper/wrapper.dart
@@ -20,6 +20,7 @@ import 'package:invan2/utils/helpers/auth_backup.dart';
 import 'package:invan2/utils/helpers/auth_reset.dart';
 import 'package:invan2/changes/services/catalog_refresh_notice.dart';
 import 'package:invan2/changes/services/startup_progress.dart';
+import 'package:invan2/changes/services/sync/catch_up_sync.dart';
 import 'package:invan2/changes/services/discount_auto_sync_service.dart';
 import 'package:invan2/changes/services/health/backend_health.dart';
 import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
@@ -150,15 +151,19 @@ class _WrapperState extends State<Wrapper> {
           /// bosqichi) ham yangilaydi. Fonda ketadi, startup'ni kutdirmaydi.
           unawaited(BhmService.refreshIfStale(reason: 'startup'));
 
-          // Startup yuklashi davomida "baza yangilanmagan" dialogi
-          // chiqmasligi kerak — u yuklanish ekranining ustiga tushib qolardi.
-          CatalogRefreshNotice.beginLoad();
+          final UpdateProvider updateProvider =
+              Provider.of<UpdateProvider>(context, listen: false);
           if (!kDebugMode || kDebugStartupCatalogSync) {
-            await _syncCatalogOnStartup(
-                Provider.of<UpdateProvider>(context, listen: false));
+            await _syncCatalogOnStartup(updateProvider);
           }
 
-          CatalogRefreshNotice.endLoad();
+          /// Davriy sinxron ilgari FAQAT NetworkSuccess'dan boshlanardi, u
+          /// esa internet_connection_checker'ning 1.1.1.1:53 kabi
+          /// probe'lariga bog'liq — do'kon tarmog'ida probe bloklansa (API
+          /// ishlasa ham) halqa umuman ishga tushmasdi. Idempotent
+          /// (`_autoUpdateRunning`), NetworkSuccess'dagi chaqiruv qoladi.
+          unawaited(updateProvider.autoUpdate(context, mounted));
+
           // Shkala 100% ga to'lib, keyin sahifa almashadi — kassir
           // "yarmida uzilib qoldi" degan taassurot olmasligi kerak.
           StartupProgress.done();
@@ -207,16 +212,45 @@ class _WrapperState extends State<Wrapper> {
       await CatalogRefreshNotice.markFailed();
       return;
     }
-    try {
-      await Future(() async {
+    final int startedAt = DateTime.now().millisecondsSinceEpoch;
+
+    // Yuklash davomida "baza yangilanmagan" dialogi chiqmasin. `endLoad`
+    // ish HAQIQATAN tugaganda chaqiriladi — budjet tugasa ham fon ishi
+    // davom etadi (ilgari budjet tugashi bilan bayroq olinib, dialog
+    // yuklanayotgan katalog ustiga chiqib qolardi).
+    CatalogRefreshNotice.beginLoad();
+    final Future<void> work = Future(() async {
+      try {
         StartupProgress.set(StartupPhase.employees);
         await updateProvider.fullUpdateEmployee();
-        await updateProvider.fullUpdateItems();
-      }).timeout(_startupSyncBudget);
+        // Sinxron qulfi ostida: NetworkSuccess bilan deyarli bir vaqtda
+        // boshlanadigan CatchUpSync yuklash o'rtasida mahsulot yozib,
+        // `clearAndPutItems` uni o'chirib yuborishi (kursor esa o'tib
+        // ketishi) mumkin edi. Startup odam kutmaydigan ish — qulfni
+        // majburan olmaydi, bo'shashini kutadi.
+        await CatchUpSync.exclusive(() async {
+          // NetworkSuccess'dagi catch-up (kursor yo'q bo'lsa) katalogni
+          // allaqachon to'liq yuklagan bo'lishi mumkin — ikkinchi 43 MB
+          // shart emas. Kursor commit `fullUpdateProduct` ichida.
+          if (Pref.getInt(PrefKeys.lastFullCatalogSyncAt, 0) >= startedAt) {
+            return;
+          }
+          final String? error = await updateProvider.fullUpdateItems();
+          if (error != null) await CatalogRefreshNotice.markFailed();
+        }, reason: 'startup-full-update', forceAfterWait: false);
+      } catch (_) {
+        await CatalogRefreshNotice.markFailed();
+      } finally {
+        CatalogRefreshNotice.endLoad();
+      }
+    });
+
+    try {
+      await work.timeout(_startupSyncBudget);
     } catch (_) {
-      // Yiqildi yoki budjetga sig'madi — eski katalog bilan ochilaveramiz,
+      // Budjetga sig'madi — eski katalog bilan ochilaveramiz, yuklash
+      // fonda davom etadi; yiqilsa `markFailed` ichkarida qo'yiladi va
       // kassirga ogohlantirish `CatalogRefreshNotice` orqali chiqadi.
-      await CatalogRefreshNotice.markFailed();
     }
   }
 
```

### 6.14. `lib/changes/dialogs/upd/bloc/upd_bloc.dart`

```diff
diff --git a/lib/changes/dialogs/upd/bloc/upd_bloc.dart b/lib/changes/dialogs/upd/bloc/upd_bloc.dart
index c3997f0..3d34ca0 100644
--- a/lib/changes/dialogs/upd/bloc/upd_bloc.dart
+++ b/lib/changes/dialogs/upd/bloc/upd_bloc.dart
@@ -6,6 +6,8 @@ import 'package:invan2/changes/models/organization_model.dart';
 import 'package:invan2/changes/services/api/result_http_model.dart';
 import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
 import 'package:invan2/changes/services/get_items_service.dart';
+import 'package:invan2/changes/services/sync/catch_up_sync.dart';
+import 'package:invan2/changes/services/sync/server_clock.dart';
 import 'package:invan2/changes/services/sync/sync_cursor.dart';
 import 'package:invan2/changes/services/company_app_service.dart';
 import 'package:invan2/changes/services/organization_service.dart';
@@ -310,35 +312,49 @@ class UpdBloc extends Bloc<UpdEvent, UpdState> {
   ///
   /// [startedAt] — yuklash **boshlangan** vaqt. Ataylab tugagan vaqt emas:
   /// yuklash davomida bo'lgan o'zgarishlar notification orqali kelishi kerak.
+  ///
+  /// [startedAt] mahalliy UTC; kursorga SERVER vaqtida yoziladi — yuklash
+  /// davomida (ApiProvider javoblaridan) server soati farqi aniqlanib
+  /// bo'lgan bo'ladi. Kassa soati oldinda bo'lsa ham kursor kelajakka ketmaydi.
+  ///
+  /// Yuklashning o'zi `CatchUpSync.exclusive` ostida — davriy sinxron bilan
+  /// bir vaqtda `clearAndPutItems` bo'lmasligi uchun.
   Future<void> _advanceCursor(
     SyncStream stream,
     DateTime startedAt,
     String? error,
   ) async {
     if (error != null) return;
-    await SyncCursor.commit(stream, startedAt);
+    await SyncCursor.commit(stream, ServerClock.toServer(startedAt));
   }
 
   Future<String?> _category(Emitter<UpdState> emit) async {
-    final DateTime startedAt = DateTime.now().toUtc();
-    final String? error = await CategoryService.category();
-    await _advanceCursor(SyncStream.categories, startedAt, error);
-    return error;
+    return CatchUpSync.exclusive(() async {
+      final DateTime startedAt = DateTime.now().toUtc();
+      final String? error = await CategoryService.category();
+      await _advanceCursor(SyncStream.categories, startedAt, error);
+      return error;
+    }, reason: 'upd-dialog-categories');
   }
 
   Future<String?> _discounts(Emitter<UpdState> emit) async {
-    final DateTime startedAt = DateTime.now().toUtc();
-    final String? error = await DiscountService.discounts();
-    await _advanceCursor(SyncStream.discounts, startedAt, error);
-    return error;
+    return CatchUpSync.exclusive(() async {
+      final DateTime startedAt = DateTime.now().toUtc();
+      final String? error = await DiscountService.discounts();
+      await _advanceCursor(SyncStream.discounts, startedAt, error);
+      return error;
+    }, reason: 'upd-dialog-discounts');
   }
 
   Future<String?> _items(Emitter<UpdState> emit) async {
     String? error;
-    final DateTime startedAt = DateTime.now().toUtc();
 
-    error = await UtilFunctions.fullUpdateProduct();
-    await _advanceCursor(SyncStream.products, startedAt, error);
+    error = await CatchUpSync.exclusive(() async {
+      final DateTime startedAt = DateTime.now().toUtc();
+      final String? e = await UtilFunctions.fullUpdateProduct();
+      await _advanceCursor(SyncStream.products, startedAt, e);
+      return e;
+    }, reason: 'upd-dialog-products');
 
     if (error == null) {
       final bool isMarkingSyncEnabled = Pref.getBool('switchMarking', false);
```

### 6.15. `lib/features/drawer/features/update/sync/bloc/sync_bloc.dart`

```diff
diff --git a/lib/features/drawer/features/update/sync/bloc/sync_bloc.dart b/lib/features/drawer/features/update/sync/bloc/sync_bloc.dart
index 12c80f5..d806d50 100644
--- a/lib/features/drawer/features/update/sync/bloc/sync_bloc.dart
+++ b/lib/features/drawer/features/update/sync/bloc/sync_bloc.dart
@@ -2,14 +2,15 @@ import 'dart:convert';
 import 'package:invan2/changes/services/catalog_refresh_notice.dart';
 
 import 'package:flutter_bloc/flutter_bloc.dart';
-import 'package:hive_flutter/hive_flutter.dart';
 import 'package:invan2/changes/models/product/item_model.dart';
 import 'package:invan2/changes/services/api/result_http_model.dart';
 import 'package:invan2/changes/services/get_items_service.dart';
+import 'package:invan2/changes/services/sync/catch_up_sync.dart';
+import 'package:invan2/changes/services/sync/server_clock.dart';
 import 'package:invan2/changes/services/sync/sync_cursor.dart';
 import 'package:invan2/features/get_categories/get_categories.dart';
+import 'package:invan2/features/get_categories/service/category_service.dart';
 import 'package:invan2/features/get_products/singletons/items_singleton.dart';
-import 'package:invan2/features/hive_repository/hive_boxes.dart';
 import 'package:invan2/utils/constants/pref_keys.dart';
 import 'package:invan2/utils/helpers/helpers.dart';
 
@@ -37,12 +38,22 @@ class SyncBloc extends Bloc<SyncEvent, SyncState> {
   }
 
   static _sync(SyncSyncEvent event, Emitter<SyncState> emit) async {
+    emit(SyncLoadingState());
+    // Sinxron qulfi ostida: davriy CatchUpSync bilan bir vaqtda
+    // `clearAndPutItems` bo'lmasligi uchun (yuklash o'rtasida kelgan
+    // mahsulot o'chib, kursor esa o'tib ketishi mumkin edi).
+    await CatchUpSync.exclusive(() => _syncLocked(emit),
+        reason: 'drawer-sync');
+  }
+
+  static Future<void> _syncLocked(Emitter<SyncState> emit) async {
     DateTime time = DateTime.now();
     // Kursor yuklash BOSHLANGAN vaqtga suriladi — yuklash davomida bo'lgan
-    // o'zgarishlar notification orqali kelishi kerak.
+    // o'zgarishlar notification orqali kelishi kerak. Server vaqtiga
+    // yuklashdan KEYIN o'tkaziladi (ServerClock shu paytda aniq).
     final DateTime startedAt = DateTime.now().toUtc();
-    emit(SyncLoadingState());
     List<ItemModel> allProducts = [];
+    final Set<String> skippedIds = <String>{};
     String getError = '';
     await TasnifService.setPackageCode();
 
@@ -50,16 +61,15 @@ class SyncBloc extends Bloc<SyncEvent, SyncState> {
 
     if (httpResult.isSuccess) {
       try {
-        var decodedJson = json.decode(httpResult.result);
+        final dynamic decodedJson = httpResult.result is String
+            ? json.decode(httpResult.result)
+            : httpResult.result;
 
         if (decodedJson is List) {
-          List<ItemModel> i = List<ItemModel>.from(
-            decodedJson.map((e) {
-              return ItemModel.fromJson(e);
-            }),
-          ).toList();
-          i = ItemsSingleton.addPackageCodeAndMxikCode(
-            i,
+          final parsed = await ItemsSingleton.parseCatalog(decodedJson);
+          skippedIds.addAll(parsed.skippedIds);
+          List<ItemModel> i = ItemsSingleton.addPackageCodeAndMxikCode(
+            parsed.items,
             Pref.getString(PrefKeys.mxikCode, ''),
             Pref.getString(PrefKeys.packageCode, ''),
           );
@@ -76,13 +86,14 @@ class SyncBloc extends Bloc<SyncEvent, SyncState> {
     }
 
     if (allProducts.isNotEmpty) {
-      await toHive(allProducts);
+      await toHive(allProducts, skippedIds);
       await Pref.setInt(PrefKeys.lastSyncTime, time.millisecondsSinceEpoch);
       // Mahsulotlar to'liq qayta yuklandi — notification tarixiga ehtiyoj
       // qolmadi. Kategoriya kursoriga tegilmaydi: `toHive` ichidagi
       // `_category()` xatoni yutib yuboradi, ya'ni muvaffaqiyatiga
       // ishonib bo'lmaydi.
-      await SyncCursor.commit(SyncStream.products, startedAt);
+      await SyncCursor.commit(
+          SyncStream.products, ServerClock.toServer(startedAt));
       // Katalog to'liq qayta yuklandi — "baza yangilanmagan" ogohlantirishi
       // qaysi yo'l bilan yangilanganidan qat'i nazar to'xtashi kerak.
       await CatalogRefreshNotice.markFresh();
@@ -120,34 +131,29 @@ class SyncBloc extends Bloc<SyncEvent, SyncState> {
     
   }
 
-  static toHive(List<ItemModel> v) async {
-    Box<ItemModel> box = HiveBoxes.getProducts();
-    Map<String, ItemModel> map = {};
-    for (var item in v) {
-      map[item.key] = item;
-    }
-    await box.putAll(map);
+  /// [skippedIds] — bu safar parse bo'lmagan mahsulotlar; "serverda yo'q"
+  /// deb o'chirilmasin (qarang: ItemsSingleton.parseCatalog).
+  static Future<void> toHive(
+      List<ItemModel> v, Set<String> skippedIds) async {
+    // Ilgari bu yerda bevosita `box.putAll` edi: eski (serverda o'chirilgan)
+    // mahsulotlar hech qachon o'chirilmasdi, `catalogWriteInProgress`
+    // markeri va `box.flush()` yo'q edi — boshqa to'liq yuklash yo'llaridan
+    // farqli o'laroq. Endi bitta umumiy, tekshirilgan metod ishlatiladi.
+    await ItemsSingleton.clearAndPutItems(v, preserveIds: skippedIds);
+    // Bu yerdagi kategoriya xatosi yutiladi — `_syncLocked` shu sabab
+    // kategoriya kursoriga tegmaydi (muvaffaqiyatiga ishonib bo'lmaydi).
     await _category();
     await ItemsSingleton.storeProducts();
     CategorySingleton.init();
   }
 
-  static _category() async {
-    HttpResult httpResult = await CategoriesApi.categoryFind();
-
-    if (httpResult.isSuccess) {
-      Category category = Category.fromJson(httpResult.result);
-      final box = HiveBoxes.getCategories();
-      await box.clear();
-      final categoryList = category.data ?? <CategoryData>[];
-      CategoryData noneCategory = CategoryData(
-        children: [],
-        id: "",
-        name: "None",
-      );
-      categoryList.add(noneCategory);
-      if (categoryList.isNotEmpty) await box.addAll(categoryList);
-    }
-    return;
-  }
+  /// Kategoriyalarni to'liq qayta yuklaydi.
+  ///
+  /// Ilgari bu yerda alohida, tekislamaydigan (`children` ichkarida qolib
+  /// ketadigan) implementatsiya bor edi — pastki kategoriyalar Hive'ga
+  /// TOP-LEVEL qator sifatida yozilmasdi va ular ichidagi mahsulotlar
+  /// keyingi "haqiqiy" kategoriya sinxronigacha katalog to'rida ko'rinmay
+  /// qolardi. Endi boshqa barcha to'liq yuklash yo'llari bilan bir xil,
+  /// tekshirilgan `CategoryService.category()` ishlatiladi.
+  static Future<String?> _category() => CategoryService.category();
 }
```

### 6.16. `lib/features/get_categories/service/category_service.dart`

```diff
diff --git a/lib/features/get_categories/service/category_service.dart b/lib/features/get_categories/service/category_service.dart
index 88f000c..ef370f9 100644
--- a/lib/features/get_categories/service/category_service.dart
+++ b/lib/features/get_categories/service/category_service.dart
@@ -68,8 +68,11 @@ class CategoryService {
         _flattenCategories([noneCategory]);
         if (flatCategories.isNotEmpty) {
           final box = HiveBoxes.getCategories();
-          await box.clear();
+          // Avval yangilari yoziladi, keyin eskilar o'chiriladi — clear+addAll
+          // o'rtasida ilova o'lsa kategoriyalar bo'sh qolmasin.
+          final List<dynamic> oldKeys = box.keys.toList();
           await box.addAll(flatCategories);
+          if (oldKeys.isNotEmpty) await box.deleteAll(oldKeys);
         }
       } else {
         throw Exception(
@@ -81,85 +84,83 @@ class CategoryService {
     return error;
   }
 
+  /// Notification (type 10): kategoriya yaratish — id bo'yicha UPSERT.
+  ///
+  /// Ilgari `box.addAll` edi: sinxron oynalari 2 daqiqa overlap bilan
+  /// qayta so'ralgani uchun bir xil kategoriya ikki-uch marta qo'shilib
+  /// ketardi (gridda dublikat, keyin update faqat birinchisini o'zgartirardi).
   static Future<String?> categoriesCreateForWebSocket(
       List<CategoryData> categoryList) async {
-    final box = HiveBoxes.getCategories();
+    if (categoryList.isEmpty) return 'Category list empty';
     flatCategories = [];
-    String? error;
-    if (categoryList.isNotEmpty) {
-      _flattenCategoriesCreate(categoryList);
-      if (flatCategories.isNotEmpty) {
-        await box.addAll(flatCategories);
-      }
-    } else {
-      error = 'Category list empty';
-    }
-    return error;
+    _flattenCategoriesCreate(categoryList);
+    await upsertCategories(flatCategories);
+    return null;
   }
 
+  /// Notification (type 11): yangilash; lokalda bo'lmasa yaratiladi.
   static Future<String?> categoriesUpdateForWebSocket(
       CategoryData? categoryData) async {
-    String? error;
-    if (categoryData != null) {
-      final box = HiveBoxes.getCategories();
-      List<CategoryData> categoryListLocal = box.values.toList();
-      bool isUpdated = false;
-      for (int i = 0; i < categoryListLocal.length; i++) {
-        if (categoryListLocal[i].id == categoryData.id) {
-          box.putAt(
-            i,
-            CategoryData(
-              id: categoryData.id,
-              name: categoryData.name,
-              parentId: categoryData.parentId,
-              children: [],
-            ),
-          );
-          isUpdated = true;
-          break;
-        }
-      }
-      if (!isUpdated) {
-        flatCategories = [];
-        _flattenCategoriesCreate([categoryData]);
-        if (flatCategories.isNotEmpty) {
-          await box.addAll(flatCategories);
-        }
+    if (categoryData == null) return 'Category list empty';
+    flatCategories = [];
+    _flattenCategoriesCreate([categoryData]);
+    if (flatCategories.isEmpty) {
+      flatCategories = [
+        CategoryData(
+          id: categoryData.id,
+          name: categoryData.name,
+          parentId: categoryData.parentId,
+          children: [],
+        ),
+      ];
+    }
+    await upsertCategories(flatCategories);
+    return null;
+  }
+
+  /// Har bir kategoriya id bo'yicha bitta yozuv: bor bo'lsa ustidan
+  /// yoziladi (dublikatlar ham yig'ishtiriladi), yo'q bo'lsa qo'shiladi.
+  static Future<void> upsertCategories(List<CategoryData> list) async {
+    final box = HiveBoxes.getCategories();
+    for (final CategoryData c in list) {
+      final String? id = c.id;
+      final CategoryData row = CategoryData(
+        id: id,
+        name: c.name,
+        parentId: c.parentId,
+        children: [],
+      );
+      final List<dynamic> keys = id == null
+          ? const <dynamic>[]
+          : box.keys.where((k) => box.get(k)?.id == id).toList();
+      if (keys.isEmpty) {
+        await box.add(row);
+      } else {
+        await box.put(keys.first, row);
+        if (keys.length > 1) await box.deleteAll(keys.skip(1).toList());
       }
-    } else {
-      error = 'Category list empty';
     }
-    return error;
   }
 
+  /// Notification (type 12): o'chirish. Yozuvlar kalit bo'yicha o'chiriladi
+  /// (ilgari snapshot indeksi bilan `deleteAt` va `await`siz — ikkinchi
+  /// dublikatda noto'g'ri qator o'chib, xato esa yutilardi).
   static Future<String?> categoriesDeleteForWebSocket(String categoryId) async {
-    String? error;
-    if (categoryId.isNotEmpty) {
-      bool isDeleted = false;
-      final box = HiveBoxes.getCategories();
-      final itemBox = HiveBoxes.getProducts();
-      List<CategoryData> categoryList = box.values.toList();
-      List<ItemModel> itemList = itemBox.values.toList();
-      for (int i = 0; i < categoryList.length; i++) {
-        if (categoryList[i].id == categoryId) {
-          box.deleteAt(i);
-          isDeleted = true;
-        }
-      }
-      if (isDeleted) {
-        for (int i = 0; i < itemList.length; i++) {
-          if (itemList[i].categories != null &&
-              itemList[i].categories!.isNotEmpty) {
-            if (itemList[i].categories![0].id == categoryId) {
-              itemList[i].categories = null;
-              itemBox.putAt(i, itemList[i]);
-            }
-          }
-        }
+    if (categoryId.isEmpty) return 'Category list empty';
+    final box = HiveBoxes.getCategories();
+    final List<dynamic> keys =
+        box.keys.where((k) => box.get(k)?.id == categoryId).toList();
+    if (keys.isEmpty) return null;
+    await box.deleteAll(keys);
+
+    final itemBox = HiveBoxes.getProducts();
+    for (final ItemModel item in itemBox.values.toList()) {
+      final List<CategoriesFromProducts>? cats = item.categories;
+      if (cats != null && cats.isNotEmpty && cats[0].id == categoryId) {
+        item.categories = null;
+        await itemBox.put(item.id, item);
       }
-    } else {
-      error = 'Category list empty';
     }
-    return error;
+    return null;
   }
 }
```

### 6.17. `lib/changes/services/catalog_refresh_notice.dart`

```diff
diff --git a/lib/changes/services/catalog_refresh_notice.dart b/lib/changes/services/catalog_refresh_notice.dart
index 0f778e0..7ed3af3 100644
--- a/lib/changes/services/catalog_refresh_notice.dart
+++ b/lib/changes/services/catalog_refresh_notice.dart
@@ -29,6 +29,7 @@ import '../models/six_client_model.dart';
 import '../providers/ordering_provider_4.dart';
 import '../providers/update_provider.dart';
 import 'package:invan2/changes/services/health/backend_health.dart';
+import 'package:invan2/changes/services/sync/catch_up_sync.dart';
 
 class CatalogRefreshNotice {
   CatalogRefreshNotice._();
@@ -74,6 +75,16 @@ class CatalogRefreshNotice {
   static bool get isPending =>
       Pref.getBool(PrefKeys.catalogRefreshPending, false);
 
+  /// Katalog kursordan to'liq yetib olindi (notification yo'li) — startup
+  /// yiqilishi sabab qo'yilgan bayroq endi asossiz. `markFresh`dan farqi:
+  /// "to'liq katalog yuklandi" vaqtiga TEGMAYDI.
+  static Future<void> clearPending() async {
+    _snoozedUntil = null;
+    if (isPending) {
+      await Pref.setBool(PrefKeys.catalogRefreshPending, false);
+    }
+  }
+
   /// Hozir dialog ko'rsatilyaptimi (takroriy ochilishdan himoya).
   static bool get isShowing => _showing;
 
@@ -229,9 +240,15 @@ class _CatalogStaleDialogState extends State<CatalogStaleDialog> {
       _error = null;
     });
 
-    final String? error =
-        await Provider.of<UpdateProvider>(context, listen: false)
-            .fullUpdateItems();
+    final UpdateProvider provider =
+        Provider.of<UpdateProvider>(context, listen: false);
+    // Sinxron qulfi ostida — davriy catch-up bilan bir vaqtda
+    // `clearAndPutItems` bo'lmasin (bu yagona qulfsiz to'liq yuklash edi).
+    // Kursor commit `fullUpdateProduct` ichida.
+    final String? error = await CatchUpSync.exclusive(
+      () => provider.fullUpdateItems(),
+      reason: 'stale-dialog-full-update',
+    );
 
     if (!mounted) return;
 
```

### 6.18. `lib/changes/services/discount_auto_sync_service.dart`

```diff
diff --git a/lib/changes/services/discount_auto_sync_service.dart b/lib/changes/services/discount_auto_sync_service.dart
index a834db1..f9ef402 100644
--- a/lib/changes/services/discount_auto_sync_service.dart
+++ b/lib/changes/services/discount_auto_sync_service.dart
@@ -1,3 +1,4 @@
+import 'package:invan2/changes/services/sync/catch_up_sync.dart';
 import 'dart:async';
 
 import 'package:flutter/foundation.dart';
@@ -48,7 +49,24 @@ class DiscountAutoSyncService {
     _timer = null;
   }
 
+  /// Sinxron qulfi bo'sh bo'lsagina ishlaydi (kutmaydi — keyingi 10
+  /// daqiqada yana uriniladi). Ilgari CatchUpSync bilan parallel ishlar,
+  /// to'liq ro'yxat olinayotgan paytda notification orqali kelgan yangi
+  /// diskontni "serverda yo'q" deb o'chirib yuborardi.
   Future<void> _syncNow() async {
+    final bool? ran = await CatchUpSync.tryExclusive(
+      () async {
+        await _syncNowUnlocked();
+        return true;
+      },
+      reason: 'discount-auto-sync',
+    );
+    if (ran == null) {
+      debugPrint('🔖 DISKONT AVTO-SYNC: sinxron qulfi band — skip');
+    }
+  }
+
+  Future<void> _syncNowUnlocked() async {
     if (_syncing) {
       debugPrint('🔖 DISKONT AVTO-SYNC: oldingi tsikl hali tugamagan — skip');
       return;
```

### 6.19. `lib/utils/helpers/auth_reset.dart`

```diff
diff --git a/lib/utils/helpers/auth_reset.dart b/lib/utils/helpers/auth_reset.dart
index da73643..249fb35 100644
--- a/lib/utils/helpers/auth_reset.dart
+++ b/lib/utils/helpers/auth_reset.dart
@@ -1,5 +1,7 @@
 import 'package:invan2/changes/services/api/api_provider.dart';
 import 'package:invan2/changes/services/log_service.dart';
+import 'package:invan2/changes/services/sync/catch_up_sync.dart';
+import 'package:invan2/changes/services/sync/sync_cursor.dart';
 import 'package:invan2/features/get_products/singletons/items_singleton.dart';
 import 'package:invan2/features/hive_repository/hive_boxes.dart';
 import 'package:invan2/utils/constants/constants.dart';
@@ -21,19 +23,30 @@ class AuthReset {
   ///
   /// Navigatsiya qilmaydi: chaqiruvchi tomon o'zi login sahifasiga o'tkazadi.
   static Future<void> clearAuthAndCache() async {
-    await Pref.setBool(PrefKeys.authenticationBool, false);
-    await AuthBackup.delete();
+    // Sinxron qulfi ostida: hozir ketayotgan catch-up/to'liq yuklash boxlar
+    // tozalangandan KEYIN eski kompaniya ma'lumotini/kursorini yozib
+    // qo'ymasin. Epoch oshirilgani uchun eski run `shouldContinue` orqali
+    // to'xtaydi.
+    CatchUpSync.bumpEpoch();
+    await CatchUpSync.exclusive(() async {
+      await Pref.setBool(PrefKeys.authenticationBool, false);
+      await AuthBackup.delete();
 
-    // prefBox ham shu yerda tozalanadi — token, shop/pos ma'lumotlari
-    // hammasi shu box ichida.
-    await HiveBoxes.clearAllBoxes();
-    ItemsSingleton.clearTheProducts();
+      // prefBox ham shu yerda tozalanadi — token, shop/pos ma'lumotlari
+      // hammasi shu box ichida.
+      await HiveBoxes.clearAllBoxes();
+      ItemsSingleton.clearTheProducts();
 
-    // clearAllBoxes prefBox'ni ham tozalagani uchun login sahifasigacha
-    // kerak bo'ladigan qiymatlar qayta yoziladi.
-    await Pref.setString(PrefKeys.mxikCode, '01905012001000000');
-    await Pref.setString(PrefKeys.version, await LogService.getAppVersion() ?? '');
-    await Pref.setString(PrefKeys.apiEnv, ApiProvider.currentEnv);
+      // clearAllBoxes prefBox'ni ham tozalagani uchun login sahifasigacha
+      // kerak bo'ladigan qiymatlar qayta yoziladi.
+      await Pref.setString(PrefKeys.mxikCode, '01905012001000000');
+      await Pref.setString(
+          PrefKeys.version, await LogService.getAppVersion() ?? '');
+      await Pref.setString(PrefKeys.apiEnv, ApiProvider.currentEnv);
+      // Kursor sxemasi ham tozalandi — qayta yozamiz, aks holda keyingi
+      // startup yana migratsiya qiladi (zararsiz, lekin ortiqcha).
+      await Pref.setInt(PrefKeys.syncCursorSchema, SyncCursor.schemaVersion);
+    }, reason: 'logout');
   }
 
   /// Build API muhiti (dev↔pro) oldingi ishga tushirishdagidan farq qilsa
```

### 6.20. `lib/utils/util_functions.dart`

```diff
diff --git a/lib/utils/util_functions.dart b/lib/utils/util_functions.dart
index 886c996..834afca 100644
--- a/lib/utils/util_functions.dart
+++ b/lib/utils/util_functions.dart
@@ -2,6 +2,8 @@
     @author Suxrob Sattorov, 3/17/2025, 10:00 AM
 */
 
+import 'package:invan2/changes/services/sync/server_clock.dart';
+import 'package:invan2/changes/services/sync/sync_cursor.dart';
 import 'dart:convert';
 import 'package:invan2/changes/services/catalog_refresh_notice.dart';
 import 'package:invan2/changes/services/startup_progress.dart';
@@ -218,6 +220,7 @@ static Future<String?> fullUpdateProduct({bool apd = false}) async {
 static Future<String?> _fullUpdateProduct({bool apd = false}) async {
   DateTime time = DateTime.now();
   List<ItemModel> allProducts = [];
+  final Set<String> skippedIds = <String>{};
   String getError = '';
 
   print('🔄 fullUpdateProduct chaqirildi - ${DateTime.now()}');
@@ -229,22 +232,21 @@ static Future<String?> _fullUpdateProduct({bool apd = false}) async {
 
   if (httpResult.isSuccess) {
     try {
-      var decodedJson = json.decode(httpResult.result);
+      final dynamic decodedJson = httpResult.result is String
+          ? json.decode(httpResult.result)
+          : httpResult.result;
 
       if (decodedJson is List) {
-
-        final i = <ItemModel>[];
-        for (final e in decodedJson) {
-          i.add(ItemModel.fromJson(e));
-        }
+        // Har yozuv alohida himoyada — bitta buzuq yozuv butun importni
+        // yiqitmaydi (ItemsSingleton.parseCatalog).
+        final parsed = await ItemsSingleton.parseCatalog(decodedJson);
+        skippedIds.addAll(parsed.skippedIds);
 
         allProducts = ItemsSingleton.addPackageCodeAndMxikCode(
-          i,
+          parsed.items,
           Pref.getString(PrefKeys.mxikCode, ''),
           Pref.getString(PrefKeys.packageCode, ''),
         );
-
-       // print('📦 Jami mahsulotlar soni: ${allProducts.length}');
       } else {
         getError = "Ma'lumotlar formati noto'g'ri.";
       }
@@ -258,15 +260,17 @@ static Future<String?> _fullUpdateProduct({bool apd = false}) async {
     print('❌ API xatosi: $getError');
   }
 
-  // Vaqtni saqlash
-  await Pref.setInt(PrefKeys.lastSyncTime, time.millisecondsSinceEpoch);
-
   if (allProducts.isNotEmpty) {
+    // Faqat haqiqiy muvaffaqiyatda — ilgari yiqilgan yuklash ham
+    // "oxirgi yangilanish" vaqtini surib qo'yardi.
+    await Pref.setInt(PrefKeys.lastSyncTime, time.millisecondsSinceEpoch);
     print('💾 Mahsulotlar localga saqlanmoqda...');
 
     // Yozish bosqichi uch qadamga bo'linadi — shkala qotib qolmasligi uchun.
     StartupProgress.saving(0);
-    await ItemsSingleton.clearAndPutItems(allProducts);
+    // `skippedIds`: bu safar parse bo'lmagan mahsulotlar "serverda yo'q"
+    // deb o'chirilmaydi.
+    await ItemsSingleton.clearAndPutItems(allProducts, preserveIds: skippedIds);
     StartupProgress.saving(.5);
 
     if (apd) {
@@ -286,6 +290,16 @@ static Future<String?> _fullUpdateProduct({bool apd = false}) async {
 
     print('✅ Mahsulotlar muvaffaqiyatli yangilandi!');
     allProducts = [];
+    // Katalog to'liq yuklandi — notification tarixiga ehtiyoj qolmadi.
+    // Kursor yuklash BOSHLANGAN server vaqtiga suriladi (yagona nuqta —
+    // barcha chaqiruvchilar: startup, UPD dialogi, "baza yangilanmagan"
+    // dialogi, aktivatsiya). `force`: soat sakragan bo'lsa ham qayta
+    // o'rnatilsin.
+    await SyncCursor.commit(
+      SyncStream.products,
+      ServerClock.toServer(time.toUtc()),
+      force: true,
+    );
     // Katalog to'liq yangilandi — "baza yangilanmagan" ogohlantirishi olinadi.
     await CatalogRefreshNotice.markFresh();
     return null;
```

### 6.21. `lib/changes/services/get_items_service.dart`

```diff
diff --git a/lib/changes/services/get_items_service.dart b/lib/changes/services/get_items_service.dart
index ceb46e0..b7b2114 100644
--- a/lib/changes/services/get_items_service.dart
+++ b/lib/changes/services/get_items_service.dart
@@ -1,6 +1,7 @@
 import 'dart:async';
 import 'dart:convert';
 import 'dart:io';
+import 'dart:isolate';
 import 'package:path_provider/path_provider.dart';
 import 'package:invan2/changes/services/api/api_provider.dart';
 import 'package:invan2/changes/services/api/result_http_model.dart';
@@ -17,11 +18,26 @@ import 'startup_progress.dart';
 class OrdersService {
   // ─── Cancel support ───────────────────────────────────────────────
   static http.Client? _activeClient;
+  static HttpClient? _activeDownloadClient;
 
   static void cancelRequests() {
     _activeClient?.close();
     _activeClient = null;
   }
+
+  /// 43 MB katalog yuklanishini majburan to'xtatadi.
+  ///
+  /// `Future.timeout()` (StreamSyncRunner'da to'liq yuklash uchun) faqat
+  /// KUTISHNI to'xtatadi — asl `HttpClient` chaqiruvi o'zi to'xtamasdan
+  /// fonda davom etardi (yarim soatgacha, agar link juda sekin bo'lsa-yu
+  /// 90 s sukut chegarasiga urilmasa) va keyin qulfsiz Hive'ga yozardi.
+  /// Runner timeout'ni ushlaganda shu metodni chaqiradi — ulanish darhol
+  /// yopiladi, `downloadFile` ichidagi kutish `SocketException`/xato bilan
+  /// tugaydi.
+  static void cancelCatalogDownload() {
+    _activeDownloadClient?.close(force: true);
+    _activeDownloadClient = null;
+  }
   // ──────────────────────────────────────────────────────────────────
 
   static Future<void> _saveSoliqMxikItemsToLocal(
@@ -58,32 +74,49 @@ class OrdersService {
       String downloadUrl = httpResult.result['id'].toString();
       String fileName = downloadUrl.split('/').last;
 
-      File downloadedFile = await downloadFile(
-        downloadUrl,
-        fileName,
-        onProgress: StartupProgress.download,
-      );
-
-      // Yuklab olish tugadi — endi arxivni ochib, lokalga yozish bosqichi.
-      StartupProgress.saving(0);
-
-      final bytes = await downloadedFile.readAsBytes();
-      final decoded = GZipCodec().decode(bytes);
-      final jsonContent = utf8.decode(decoded);
+      // Yuklash/ochish xatosi (timeout, tarmoq uzilishi, buzuq arxiv)
+      // istisno bo'lib chiqmaydi — chaqiruvchilar (startup, UpdBloc,
+      // CatchUpSync) natijani `isSuccess` bilan tekshiradi.
       try {
-        final jsonList = jsonDecode(jsonContent) as List;
+        File downloadedFile = await downloadFile(
+          downloadUrl,
+          fileName,
+          onProgress: StartupProgress.download,
+        );
+
+        // Yuklab olish tugadi — endi arxivni ochib, lokalga yozish bosqichi.
+        StartupProgress.saving(0);
+
+        // Arxivni ochish + JSON parse alohida isolate'da: 43 MB ni asosiy
+        // isolate'da ochish UI'ni bir necha soniya qotirardi (skaner
+        // kiritishi bo'linib ketardi). Natija `Isolate.exit` bilan
+        // nusxalanmasdan qaytadi.
+        final String path = downloadedFile.path;
+        final List<dynamic> decoded =
+            await Isolate.run(() => decodeCatalogFile(path));
+        try {
+          await downloadedFile.delete();
+        } catch (_) {
+          // Windows'da antivirus/indekslovchi faylni ushlab turishi mumkin —
+          // vaqtinchalik fayl qolib ketgani muvaffaqiyatni bekor qilmaydi.
+        }
 
+        return HttpResult(
+          statusCode: 200,
+          isSuccess: true,
+          // E'tibor: endi satr emas, tayyor ro'yxat. Chaqiruvchilar
+          // `result is String ? json.decode(...) : result` bilan o'qiydi.
+          result: decoded,
+          reBytes: '',
+        );
       } catch (e) {
-        print('print error: $e');
+        return HttpResult(
+          statusCode: -1,
+          isSuccess: false,
+          result: 'Katalogni yuklab bo\'lmadi: $e',
+          reBytes: '',
+        );
       }
-      await downloadedFile.delete();
-
-      return HttpResult(
-        statusCode: 200,
-        isSuccess: true,
-        result: jsonContent,
-        reBytes: '',
-      );
     }
     return HttpResult(
       statusCode: httpResult.statusCode,
@@ -93,8 +126,31 @@ class OrdersService {
     );
   }
 
+  /// gzip → utf8 → JSON. Alohida isolate'da ishlaydi (Hive/Pref ishlatmaydi).
+  static List<dynamic> decodeCatalogFile(String path) {
+    final List<int> bytes = File(path).readAsBytesSync();
+    final List<int> unzipped = GZipCodec().decode(bytes);
+    final dynamic json = jsonDecode(utf8.decode(unzipped));
+    if (json is! List) {
+      throw const FormatException('Katalog javobi ro\'yxat emas');
+    }
+    return json;
+  }
+
+  /// Ulanish va sarlavha kutish chegarasi.
+  static const Duration downloadConnectTimeout = Duration(seconds: 30);
+
+  /// Ketma-ket ikki bo'lak orasidagi maksimal sukut. Bu UMUMIY chegara
+  /// emas (43 MB sekin internetda uzoq yuklanishi mumkin) — faqat oqim
+  /// butunlay to'xtab qolganini aniqlaydi.
+  static const Duration downloadIdleTimeout = Duration(seconds: 90);
+
   /// [onProgress] — `(olingan bayt, jami bayt)`. Server `Content-Length`
   /// bermasa `jami` manfiy bo'ladi va chaqiruvchi foiz ko'rsatmasligi kerak.
+  ///
+  /// Ilgari bu yerda hech qanday timeout yo'q edi: yuklash o'rtada osilsa
+  /// `await response.forEach` abadiy kutar, `CatchUpSync` qulfi bo'shamas
+  /// va har daqiqalik sinxron restartgacha jimgina o'chib qolardi.
   static Future<File> downloadFile(
     String url,
     String fileName, {
@@ -104,21 +160,43 @@ class OrdersService {
     final filePath = '${directory.path}/$fileName';
     final file = File(filePath);
 
-    final request = await HttpClient().getUrl(Uri.parse(url));
-    final response = await request.close();
-    final sink = file.openWrite();
-
-    final int total = response.contentLength;
-    int received = 0;
+    final HttpClient client = HttpClient()
+      ..connectionTimeout = downloadConnectTimeout;
+    _activeDownloadClient = client;
+    try {
+      final request = await client
+          .getUrl(Uri.parse(url))
+          .timeout(downloadConnectTimeout);
+      final response = await request.close().timeout(downloadConnectTimeout);
+      if (response.statusCode < 200 || response.statusCode >= 300) {
+        throw HttpException('Yuklash javobi: ${response.statusCode}',
+            uri: Uri.parse(url));
+      }
 
-    await response.forEach((chunk) {
-      sink.add(chunk);
-      received += chunk.length;
-      onProgress?.call(received, total);
-    });
+      final sink = file.openWrite();
+      final int total = response.contentLength;
+      int received = 0;
 
-    await sink.close();
-    return file;
+      try {
+        await response
+            .timeout(downloadIdleTimeout, onTimeout: (EventSink<List<int>> s) {
+          s.addError(TimeoutException(
+              'Yuklash to\'xtab qoldi (${downloadIdleTimeout.inSeconds} s)',
+              downloadIdleTimeout));
+          s.close();
+        }).forEach((chunk) {
+          sink.add(chunk);
+          received += chunk.length;
+          onProgress?.call(received, total);
+        });
+      } finally {
+        await sink.close();
+      }
+      return file;
+    } finally {
+      client.close(force: true);
+      if (identical(_activeDownloadClient, client)) _activeDownloadClient = null;
+    }
   }
 
   static Future<HttpResult> getAllMxikItemsWithHistory() async {
```

### 6.22. `lib/changes/services/api/api_provider.dart`

```diff
diff --git a/lib/changes/services/api/api_provider.dart b/lib/changes/services/api/api_provider.dart
index 4932dc3..fa6e317 100644
--- a/lib/changes/services/api/api_provider.dart
+++ b/lib/changes/services/api/api_provider.dart
@@ -8,6 +8,7 @@ import 'package:invan2/changes/services/api.dart';
 import 'package:invan2/changes/services/api/result_http_model.dart';
 import 'package:invan2/changes/services/health/backend_health.dart';
 import 'package:invan2/changes/services/log_out_service.dart';
+import 'package:invan2/changes/services/sync/server_clock.dart';
 import '../../../alice_service.dart';
 import '../log_helper.dart';
 
@@ -45,12 +46,8 @@ class ApiProvider {
   /// qachon tugamasdi va ilova startup'da splash ekranda muzlab qolardi.
   /// POST/PUT dan qisqaroq: GET'lar odatda ma'lumot o'qish uchun va ular
   /// kutilishi kassirni to'g'ridan-to'g'ri to'sib qo'yadi.
+ 
   static const Duration _getDuration = Duration(seconds: 15);
-
-  /// Server yiqilgani aniqlangani uchun tarmoqqa umuman chiqarilmagan so'rov.
-  ///
-  /// Bu javob darhol qaytadi — kassir 15-30 soniya kutib o'tirmaydi va
-  /// chaqiruvchi kod mavjud oflayn shoxiga tushadi.
   static HttpResult _serverDownResult(String path) {
     LogHelper.logRequest(
       method: "GATE",
@@ -60,7 +57,7 @@ class ApiProvider {
     );
     return HttpResult(
       reBytes: "",
-      isSuccess: false,
+      isSuccess: false, 
       result: "Server bilan aloqa yo'q",
       statusCode: BackendHealth.serverDownStatusCode,
     );
@@ -84,13 +81,9 @@ class ApiProvider {
           )
           .timeout(_duration);
       BackendHealth.recordStatusCode(response.statusCode, path: path);
+      // Server soati — sinxron kursori uchun (qarang: server_clock.dart).
+      ServerClock.observeHeaders(response.headers, host: ServerClock.hostApi);
 
-      // 409 ham yoziladi. Ilgari u o'tkazib yuborilardi va natijada
-      // "server chekni allaqachon qabul qilgan" degan MUHIM holat na
-      // jurnalda, na tashxisda ko'rinmasdi — 2026-09-03 da cheklar serverda
-      // turgani holda kassada qizil (!) bo'lib qolganini aniqlash shu sabab
-      // qiyin bo'ldi. Telegramga esa baribir ketmaydi (LogRepository 409 ni
-      // filtrlaydi) — u yerda shovqin bo'lardi.
       await LogHelper.logRequest(
         method: "POST",
         path: path,
@@ -191,6 +184,8 @@ class ApiProvider {
           )
           .timeout(seconds != null ? Duration(seconds: seconds) : _getDuration);
       BackendHealth.recordStatusCode(response.statusCode, path: path);
+      // Server soati — sinxron kursori uchun (qarang: server_clock.dart).
+      ServerClock.observeHeaders(response.headers, host: ServerClock.hostApi);
       await LogHelper.logRequest(
           method: "GET",
           path: path,
@@ -251,6 +246,8 @@ class ApiProvider {
           )
           .timeout(_duration);
       BackendHealth.recordStatusCode(response.statusCode, path: path);
+      // Server soati — sinxron kursori uchun (qarang: server_clock.dart).
+      ServerClock.observeHeaders(response.headers, host: ServerClock.hostApi);
       await LogHelper.logRequest(
         method: "PUT",
         path: path,
```

### 6.23. `lib/changes/services/health/backend_health.dart`

```diff
diff --git a/lib/changes/services/health/backend_health.dart b/lib/changes/services/health/backend_health.dart
index 769e539..5ce3202 100644
--- a/lib/changes/services/health/backend_health.dart
+++ b/lib/changes/services/health/backend_health.dart
@@ -266,6 +266,15 @@ class BackendHealth {
   ///   ayb hujjatda → rad etilgan; o'lgan bo'lsa navbatda qoladi.
   static Future<bool> isDocumentRejection(int statusCode) async {
     if (statusCode < 400) return false;
+    // Hujjatning o'zi emas, SESSIYA/so'rov holati: token eskirgan (401/403),
+    // so'rov vaqti tugagan (408), cheklov (429). Hujjat rad etilmagan —
+    // navbatda qolib, keyin qayta yuborilishi kerak.
+    if (statusCode == 401 ||
+        statusCode == 403 ||
+        statusCode == 408 ||
+        statusCode == 429) {
+      return false;
+    }
     if (statusCode < 500) return true;
     return isServerAlive();
   }
```

### 6.24. `lib/features/get_products/soliq/tasnif_service.dart`

```diff
diff --git a/lib/features/get_products/soliq/tasnif_service.dart b/lib/features/get_products/soliq/tasnif_service.dart
index dc24e62..32b4ea7 100644
--- a/lib/features/get_products/soliq/tasnif_service.dart
+++ b/lib/features/get_products/soliq/tasnif_service.dart
@@ -16,7 +16,11 @@ class TasnifService {
     String url =
         'https://tasnif.soliq.uz/api/cl-api/integration-mxik/get/information?mxikCode=${Pref.getString(PrefKeys.mxikCode, '')}';
     try {
-      http.Response response = await http.get(Uri.parse(url));
+      // Timeoutsiz edi: tasnif.soliq.uz javob bermay qo'ysa har to'liq
+      // yuklash (u shu chaqiruvdan boshlanadi) abadiy osilib qolardi.
+      http.Response response = await http
+          .get(Uri.parse(url))
+          .timeout(const Duration(seconds: 15));
       await LogHelper.logRequest(method: "Get", path: url, statusCode: response.statusCode,response: response.body);
 
       alice.onHttpResponse(response);
```

### 6.25. `lib/main.dart`

```diff
diff --git a/lib/main.dart b/lib/main.dart
index dc1da1d..a2e8fe3 100644
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -1,3 +1,4 @@
+import 'package:invan2/changes/services/sync/sync_cursor.dart';
 import 'dart:io';
 import 'package:bitsdojo_window/bitsdojo_window.dart';
 import 'package:easy_localization/easy_localization.dart';
@@ -84,6 +85,9 @@ Future<void> main() async {
   await _hiveInit();
   await hiveOpen();
   await _healPrintersIfNeeded();
+  // Kursor ma'nosi o'zgargan relizda (kassa soati → server soati) bir
+  // martalik migratsiya — sinxronning har qanday chaqiruvidan oldin.
+  await SyncCursor.migrateIfNeeded();
   // birinchi kirishda ofd
   // await Pref.setBool(PrefKeys.withOFD, true);
   // Printer required
```

### 6.26. `lib/utils/constants/pref_keys.dart`

```diff
diff --git a/lib/utils/constants/pref_keys.dart b/lib/utils/constants/pref_keys.dart
index 5c868b8..1d3ff8a 100644
--- a/lib/utils/constants/pref_keys.dart
+++ b/lib/utils/constants/pref_keys.dart
@@ -91,6 +91,20 @@ class PrefKeys {
   static const String syncCursorCategories = 'sync_cursor_categories';
   static const String syncCursorDiscounts = 'sync_cursor_discounts';
 
+  /// Server soati bilan kassa soati orasidagi farq (server - kassa, ms).
+  /// HTTP `date` sarlavhasidan o'rganiladi — qarang:
+  /// lib/changes/services/sync/server_clock.dart
+  static const String serverClockOffsetMs = 'server_clock_offset_ms';
+
+  /// Kursor sxemasi versiyasi. Kursor ma'nosi o'zgargan relizda (masalan
+  /// kassa soatidan server soatiga o'tish) bir martalik migratsiya uchun.
+  static const String syncCursorSchema = 'sync_cursor_schema';
+
+  /// To'liq katalog yozuvi (clearAndPutItems) boshlanib tugamagan — ilova
+  /// o'rtada o'lgan bo'lsa keyingi ishga tushishda mahsulot kursori
+  /// tashlanib, to'liq yuklash qaytariladi.
+  static const String catalogWriteInProgress = 'catalog_write_in_progress';
+
   ////////// DEBT CLICK ////////////////////////
   static const String debtClick = "debt_click";
 
```

### 6.27. YANGI: `test/server_clock_test.dart`

<details>
<summary>To'liq fayl (112 qator)</summary>

```dart
// Server soati — sinxron kursori kassa soatiga emas, server soatiga
// tayanishi kerak.
//
// Muammo: kassa soati serverdan 2 daqiqadan ko'proq OLDINDA bo'lsa kursor
// "server kelajagi"ga yozilar va keyingi oyna o'sha kelajakdan boshlanardi —
// oradagi notification'lar hech qachon so'ralmasdi. Bu yerda farq HTTP
// `date` sarlavhasidan qanday o'rganilishi va saqlanishi tekshiriladi.

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/sync/server_clock.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('server_clock_test', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  final DateTime local = DateTime.utc(2026, 9, 24, 10, 0, 0);

  setUp(() async {
    await Pref.removeWithKey(PrefKeys.serverClockOffsetMs);
    ServerClock.reset();
    ServerClock.localNow = () => local;
  });

  tearDown(() {
    ServerClock.localNow = () => DateTime.now().toUtc();
    ServerClock.reset();
  });

  test('farq noma\'lum bo\'lsa nol — eski xulq saqlanadi', () {
    expect(ServerClock.isKnown, isFalse);
    expect(ServerClock.offset, Duration.zero);
    expect(ServerClock.nowUtc(), local);
    expect(ServerClock.toServer(local), local);
  });

  test('kassa soati 2 soat OLDINDA: server vaqti kassa - 2 soat', () {
    // Server javob berganda uning soati 08:00 edi, kassaniki 10:00.
    ServerClock.observe(DateTime.utc(2026, 9, 24, 8, 0, 0));

    expect(ServerClock.isKnown, isTrue);
    expect(ServerClock.offset, const Duration(hours: -2));
    expect(ServerClock.nowUtc(), DateTime.utc(2026, 9, 24, 8, 0, 0));
    expect(ServerClock.toServer(DateTime.utc(2026, 9, 24, 10, 30)),
        DateTime.utc(2026, 9, 24, 8, 30));
  });

  test('kassa soati orqada: server vaqti oldinda chiqadi', () {
    ServerClock.observe(DateTime.utc(2026, 9, 24, 10, 5, 0));
    expect(ServerClock.offset, const Duration(minutes: 5));
    expect(ServerClock.nowUtc(), DateTime.utc(2026, 9, 24, 10, 5, 0));
  });

  test('HTTP `date` sarlavhasi (RFC 1123) o\'qiladi', () {
    final DateTime? server = ServerClock.observeHeaders(
        {'date': 'Thu, 24 Sep 2026 09:58:30 GMT'});

    expect(server, DateTime.utc(2026, 9, 24, 9, 58, 30));
    expect(ServerClock.offset, const Duration(seconds: -90));
  });

  test('sarlavha yo\'q yoki buzuq bo\'lsa farq o\'zgarmaydi', () {
    ServerClock.observe(DateTime.utc(2026, 9, 24, 9, 0, 0));

    expect(ServerClock.observeHeaders(const {}), isNull);
    expect(ServerClock.observeHeaders({'date': 'bugun'}), isNull);
    expect(ServerClock.offset, const Duration(hours: -1));
  });

  test('farq Pref\'da saqlanadi — ilova qayta ochilganda darhol to\'g\'ri',
      () async {
    ServerClock.observe(DateTime.utc(2026, 9, 24, 8, 0, 0));
    // Yozuv `unawaited` — navbatni bo'shatamiz.
    await Future<void>.delayed(Duration.zero);

    // "Qayta ochilish": xotira tozalanadi, Pref qoladi.
    ServerClock.reset();

    expect(ServerClock.isKnown, isTrue);
    expect(ServerClock.offset, const Duration(hours: -2));
  });

  test('API serveri farqi notification serveri farqini bosmaydi', () {
    ServerClock.observe(DateTime.utc(2026, 9, 24, 10, 0, 0),
        host: ServerClock.hostNotification);
    // API serveri 3 daqiqa oldinda yuradi.
    ServerClock.observe(DateTime.utc(2026, 9, 24, 10, 3, 0),
        host: ServerClock.hostApi);

    expect(ServerClock.offset, Duration.zero,
        reason: 'sinxron soati — notification serverniki');
  });

  test('notification farqi hali yo\'q bo\'lsa API farqi zaxira', () {
    ServerClock.observe(DateTime.utc(2026, 9, 24, 9, 0, 0),
        host: ServerClock.hostApi);
    expect(ServerClock.offset, const Duration(hours: -1));
  });

  test('mahalliy (UTC bo\'lmagan) vaqt ham to\'g\'ri o\'tkaziladi', () {
    ServerClock.observe(DateTime.utc(2026, 9, 24, 9, 0, 0));
    final DateTime asLocal = DateTime.utc(2026, 9, 24, 10, 0, 0).toLocal();

    expect(ServerClock.toServer(asLocal), DateTime.utc(2026, 9, 24, 9, 0, 0));
    expect(ServerClock.toServer(asLocal).isUtc, isTrue);
  });
}
```

</details>

### 6.28. YANGI: `test/notification_fetch_test.dart`

<details>
<summary>To'liq fayl (365 qator)</summary>

```dart
// `GET /notifications` so'rovi va qo'llanishi — uchala oqim uchun yagona
// yo'l. Bu yerda tarmoq o'rniga MockClient ishlatiladi.
//
// Asosiy kafolatlar:
//   * bitta buzuq notification qolganlarini to'xtatmaydi va natijada
//     `applyFailed` bilan qaytadi (ilgari butun oyna `failed` bo'lib kursor
//     abadiy qotib qolardi);
//   * notification'lar `created_at` bo'yicha o'sish tartibida qo'llanadi;
//   * server vaqti (`date` sarlavhasi) natijada qaytadi;
//   * timeout va tarmoq xatosi farqlanadi.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invan2/changes/services/sync/notification_fetch.dart';
import 'package:invan2/changes/services/sync/server_clock.dart';
import 'package:invan2/changes/services/sync/sync_cursor.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('notification_fetch_test', withEmployee: false);
    await Pref.setString(PrefKeys.token, 'test-token');
    await Pref.setString(PrefKeys.orgID, 'org-1');
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() {
    ServerClock.reset();
    NotificationFetch.timeout = const Duration(seconds: 5);
    NotificationFetch.idleTimeout = const Duration(seconds: 5);
  });

  tearDown(() {
    NotificationFetch.client = null;
    NotificationFetch.timeout = const Duration(seconds: 30);
    NotificationFetch.idleTimeout = const Duration(seconds: 45);
    ServerClock.localNow = () => DateTime.now().toUtc();
    ServerClock.reset();
  });

  Map<String, dynamic> n(String id, int type, {String? createdAt, Map<String, dynamic>? data}) => {
        'id': id,
        'type': type,
        if (createdAt != null) 'created_at': createdAt,
        'data': data ?? <String, dynamic>{},
      };

  void serve(
    List<Map<String, dynamic>> notifications, {
    int status = 200,
    Map<String, String> headers = const {},
    String? rawBody,
    void Function(http.Request)? onRequest,
  }) {
    NotificationFetch.client = MockClient((req) async {
      onRequest?.call(req);
      return http.Response(
        rawBody ??
            jsonEncode({
              'notifications': notifications,
              'total_count': notifications.length,
            }),
        status,
        headers: headers,
      );
    });
  }

  Future<SyncFetchResult> run(
    ApplyNotification apply, {
    Future<void> Function()? afterBatch,
  }) =>
      NotificationFetch.run(
        label: 'Test',
        types: '1,2',
        startDate: '2026-09-24 09:00:00',
        endDate: '2026-09-24 10:00:00',
        apply: apply,
        afterBatch: afterBatch,
      );

  group('tartiblash (sof funksiya)', () {
    test('created_at bo\'yicha o\'sish tartibi — server desc qaytarsa ham',
        () {
      final sorted = NotificationFetch.sortByCreatedAt([
        n('c', 2, createdAt: '2026-09-24T09:03:00Z'),
        n('a', 1, createdAt: '2026-09-24T09:01:00Z'),
        n('b', 2, createdAt: '2026-09-24T09:02:00Z'),
      ]);
      expect(sorted.map((e) => e['id']).toList(), ['a', 'b', 'c']);
    });

    test('teng vaqt va vaqti yo\'qlar asl tartibini saqlaydi (barqaror)', () {
      final sorted = NotificationFetch.sortByCreatedAt([
        n('x', 1),
        n('b', 1, createdAt: '2026-09-24T09:02:00Z'),
        n('y', 1),
        n('a', 1, createdAt: '2026-09-24T09:02:00Z'),
      ]);
      expect(sorted.map((e) => e['id']).toList(), ['x', 'y', 'b', 'a']);
    });

    test('bo\'sh joyli sana formati ham o\'qiladi', () {
      expect(NotificationFetch.parseCreatedAt('2026-09-24 09:02:00'),
          isNotNull);
      expect(NotificationFetch.parseCreatedAt('bugun'), isNull);
      expect(NotificationFetch.parseCreatedAt(null), isNull);
    });
  });

  group('xatoga chidamlilik', () {
    test('bitta buzuq notification qolganlarini to\'xtatmaydi', () async {
      serve([
        n('1', 1, createdAt: '2026-09-24T09:01:00Z'),
        n('2', 1, createdAt: '2026-09-24T09:02:00Z'),
        n('3', 1, createdAt: '2026-09-24T09:03:00Z'),
      ]);
      final applied = <String>[];

      final r = await run((ws) async {
        if (ws['id'] == '2') throw const FormatException('images: []');
        applied.add(ws['id'] as String);
        return NotifyApply.applied;
      });

      expect(r.ok, isTrue);
      expect(r.applyFailed, isTrue, reason: 'to\'liq yuklash bilan qoplanadi');
      expect(applied, ['1', '3']);
      expect(r.received, 3);
    });

    test('abort → oyna muvaffaqiyatsiz, kursor surilmasin', () async {
      serve([n('1', 0), n('2', 1)]);

      final r = await run((ws) async =>
          ws['id'] == '1' ? NotifyApply.abort : NotifyApply.applied);

      expect(r.ok, isFalse);
      expect(r.timedOut, isFalse);
    });

    test('afterBatch faqat BIR marta — qo\'llanganlar bo\'lsa', () async {
      serve([n('1', 1), n('2', 1), n('3', 1)]);
      int refreshed = 0;

      await run((_) async => NotifyApply.applied,
          afterBatch: () async => refreshed++);

      expect(refreshed, 1);
    });

    test('hech narsa qo\'llanmasa afterBatch chaqirilmaydi', () async {
      serve([n('1', 6)]);
      int refreshed = 0;

      final r = await run((_) async => NotifyApply.ignored,
          afterBatch: () async => refreshed++);

      expect(r.ok, isTrue);
      expect(refreshed, 0);
    });

    test('id\'siz notification o\'tkazib yuboriladi', () async {
      serve([
        {'type': 1, 'data': {}},
        n('ok', 1),
      ]);
      final seen = <String>[];

      await run((ws) async {
        seen.add(ws['id'] as String);
        return NotifyApply.applied;
      });

      expect(seen, ['ok']);
    });
  });

  group('HTTP', () {
    test('so\'rov parametrlari va token', () async {
      late http.Request captured;
      serve([], onRequest: (req) => captured = req);

      await run((_) async => NotifyApply.applied);

      final q = captured.url.queryParameters;
      expect(q['company_id'], 'org-1');
      expect(q['type'], '1,2');
      expect(q['start_date'], '2026-09-24 09:00:00');
      expect(q['end_date'], '2026-09-24 10:00:00');
      expect(q['limit'], '${NotificationFetch.limit}');
      expect(captured.headers['Authorization'], 'Bearer test-token');
      // `is_read=false` — 2026-08-21'da jonli tekshirilgan YAGONA
      // konfiguratsiya; ataylab o'zgartirilmagan (notification_fetch.dart
      // buildPath izohiga qarang).
      expect(q['is_read'], 'false');
      expect(captured.headers['Cache-Control'], contains('no-store'));
    });

    test('401/403 → unauthorized bayrog\'i', () async {
      serve([], status: 401);
      final r = await run((_) async => NotifyApply.applied);
      expect(r.ok, isFalse);
      expect(r.unauthorized, isTrue);
    });

    test('type 0 → fullReloadRequested, qolganlari qo\'llanmaydi', () async {
      serve([
        n('a', 1, createdAt: '2026-09-24T09:01:00Z'),
        n('z', 0, createdAt: '2026-09-24T09:02:00Z'),
        n('b', 1, createdAt: '2026-09-24T09:03:00Z'),
      ]);
      final seen = <String>[];

      final r = await run((ws) async {
        if (ws['type'] == 0) return NotifyApply.fullReload;
        seen.add(ws['id'] as String);
        return NotifyApply.applied;
      });

      expect(r.ok, isTrue);
      expect(r.fullReloadRequested, isTrue);
      expect(seen, ['a']);
    });

    test('200 bilan kelgan xato tanasi bo\'sh oyna deb qabul qilinmaydi',
        () async {
      serve([], rawBody: '{"error": "company not found"}');
      final r = await run((_) async => NotifyApply.applied);
      expect(r.ok, isFalse);
    });

    test('created_at epoch (soniya/ms) ham o\'qiladi', () {
      final expected = DateTime.utc(2026, 9, 21, 14, 13, 20);
      expect(NotificationFetch.parseCreatedAt(1790000000), expected);
      expect(NotificationFetch.parseCreatedAt(1790000000000), expected);
      expect(NotificationFetch.parseCreatedAt('1790000000'), expected);
    });

    test('`date` sarlavhasi → serverTime va ServerClock', () async {
      ServerClock.localNow = () => DateTime.utc(2026, 9, 24, 12, 0, 0);
      serve([], headers: {'date': 'Thu, 24 Sep 2026 10:00:00 GMT'});

      final r = await run((_) async => NotifyApply.applied);

      expect(r.ok, isTrue);
      expect(r.serverTime, DateTime.utc(2026, 9, 24, 10, 0, 0));
      expect(ServerClock.offset, const Duration(hours: -2));
    });

    test('timeout → failed(timedOut) — oyna bo\'linadi', () async {
      NotificationFetch.timeout = const Duration(milliseconds: 50);
      NotificationFetch.client =
          MockClient((_) => Completer<http.Response>().future);

      final r = await run((_) async => NotifyApply.applied);

      expect(r.ok, isFalse);
      expect(r.timedOut, isTrue);
    });

    test('tarmoq xatosi → failed, lekin timedOut emas', () async {
      NotificationFetch.client =
          MockClient((_) async => throw const SocketException('yo\'q'));

      final r = await run((_) async => NotifyApply.applied);

      expect(r.ok, isFalse);
      expect(r.timedOut, isFalse);
    });

    test('500 → failed, server vaqti baribir o\'qiladi', () async {
      serve([],
          status: 500, headers: {'date': 'Thu, 24 Sep 2026 10:00:00 GMT'});

      final r = await run((_) async => NotifyApply.applied);

      expect(r.ok, isFalse);
      expect(r.serverTime, DateTime.utc(2026, 9, 24, 10, 0, 0));
    });

    test('buzuq JSON → failed', () async {
      serve([], rawBody: '<html>502</html>');

      final r = await run((_) async => NotifyApply.applied);

      expect(r.ok, isFalse);
    });

    test('notifications: null → bo\'sh oyna (ok, 0)', () async {
      serve([], rawBody: '{"notifications": null, "total_count": 0}');

      final r = await run((_) async => NotifyApply.applied);

      expect(r.ok, isTrue);
      expect(r.received, 0);
      expect(r.truncated, isFalse);
    });

    test('limit\'ga teng miqdor → truncated', () async {
      serve(List.generate(NotificationFetch.limit, (i) => n('$i', 1)));

      final r = await run((_) async => NotifyApply.ignored);

      expect(r.ok, isTrue);
      expect(r.truncated, isTrue);
    });

    test('total_count qaytgan miqdordan ko\'p bo\'lsa ham truncated (server '
        '`limit`dan kichikroq sahifa cheklovi qo\'ygan bo\'lishi mumkin)',
        () async {
      NotificationFetch.client = MockClient((_) async => http.Response(
          jsonEncode({
            'notifications':
                List.generate(200, (i) => n('$i', 1)),
            'total_count': 950,
          }),
          200));

      final r = await run((_) async => NotifyApply.ignored);

      expect(r.ok, isTrue);
      expect(r.received, 200);
      expect(r.truncated, isTrue,
          reason: '200 < total_count(950) — ba\'zi notification\'lar '
              'yashirin kesilgan bo\'lishi mumkin');
    });

    test('total_count qaytgan miqdorga teng bo\'lsa truncated emas',
        () async {
      NotificationFetch.client = MockClient((_) async => http.Response(
          jsonEncode({
            'notifications': [n('1', 1), n('2', 1)],
            'total_count': 2,
          }),
          200));

      final r = await run((_) async => NotifyApply.ignored);

      expect(r.truncated, isFalse);
    });

    test('token yo\'q bo\'lsa so\'rov ham ketmaydi', () async {
      await Pref.setString(PrefKeys.token, '');
      bool requested = false;
      serve([], onRequest: (_) => requested = true);

      final r = await run((_) async => NotifyApply.applied);

      expect(r.ok, isFalse);
      expect(requested, isFalse);
      await Pref.setString(PrefKeys.token, 'test-token');
    });
  });
}
```

</details>

### 6.29. YANGI: `test/items_singleton_notification_test.dart`

<details>
<summary>To'liq fayl (436 qator)</summary>

```dart
// Notification orqali kelgan mahsulot/narxning lokal katalogga qo'llanishi.
//
// Uchta tirqich yopilgani tekshiriladi:
//   * type 13 (narx) — mahsulotda hali shu do'kon narxi bo'lmasa ham
//     yaratiladi (ilgari faqat mavjud tier ro'yxati yangilanardi va narx
//     hech qachon yetib bormasdi);
//   * type 2 (yangilash) payload'ida `shop_prices` bo'lmasa mavjud narx
//     saqlanadi (ilgari mahsulot to'liq ustidan yozilib narxsiz qolardi);
//   * `images: []` va `category_ids: null` parserni yiqitmaydi (ilgari
//     RangeError/TypeError butun oynani abadiy bloklardi).

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invan2/changes/dialogs/creat_product/model/mes_vat_unit_model/mes_unit.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/web_socket_service/product/model/product_price_edit_response.dart';
import 'package:invan2/changes/services/web_socket_service/product/products_ws_service.dart';
import 'package:invan2/features/get_categories/model/category.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kShop = 'shop-1';
const kOtherShop = 'shop-2';

ItemModel product(String id, {ShopPrices? price, List<String>? barcode}) =>
    ItemModel(
      id: id,
      sku: '1$id',
      name: 'Mahsulot $id',
      isActive: true,
      isMarking: false,
      barcode: barcode ?? ['478000$id'],
      shopPrices: price,
    );

ShopPrices priceOf(num retail, {String shop = kShop}) => ShopPrices(
      shID: ShID(
        shopId: shop,
        supplyPrice: retail - 100,
        shopPriceTiers: [ShopPriceTiers(minQuantity: 1, retailPrice: retail)],
      ),
    );

/// type 13 notification (server shakli).
ProductPriceEdit priceNotification(String productId, num retail,
        {String shop = kShop}) =>
    ProductPriceEdit.fromJson({
      'id': 'n-$productId',
      'type': 13,
      'data': {
        'product_values': [
          {
            'product_id': productId,
            'price': {
              'shop_id': shop,
              'retail_price': retail,
              'supply_price': retail - 100,
              'shop_price_tiers': [
                {'min_quantity': 1, 'retail_price': retail},
              ],
            },
          },
        ],
      },
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('items_singleton_notification_test',
        withEmployee: false);

    void reg<T>(int typeId, TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(adapter);
    }

    reg(ItemModelAdapter().typeId, ItemModelAdapter());
    reg(ShopPricesAdapter().typeId, ShopPricesAdapter());
    reg(ShIDAdapter().typeId, ShIDAdapter());
    reg(ShopPriceTiersAdapter().typeId, ShopPriceTiersAdapter());
    reg(CategoriesFromProductsAdapter().typeId,
        CategoriesFromProductsAdapter());
    reg(MeasurementUnitAdapter().typeId, MeasurementUnitAdapter());
    reg(VatAdapter().typeId, VatAdapter());
    reg(MesUnitModelAdapter().typeId, MesUnitModelAdapter());
    reg(VatUnitModelAdapter().typeId, VatUnitModelAdapter());

    await Hive.openBox<ItemModel>(HiveBoxNames.items);
    await Hive.openBox<MesUnitModel>(HiveBoxNames.mesUnit);
    await Hive.openBox<VatUnitModel>(HiveBoxNames.vatUnit);

    await Pref.setString(PrefKeys.storeId, kShop);
    await Pref.setString(PrefKeys.acceptService, kShop);
    await Pref.setString(PrefKeys.mxikCode, '01905012001000000');
    await Pref.setString(PrefKeys.packageCode, '1');
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    await HiveBoxes.getProducts().clear();
    await HiveBoxes.getCategories().clear();
    ItemsSingleton.clearTheProducts();
  });

  group('type 13 — narx (editItem)', () {
    test('narxi YO\'Q mahsulotga shu do\'kon narxi yaratiladi', () async {
      await ItemsSingleton.putItems([product('p1')]);
      expect(ItemsSingleton.onePrice(HiveBoxes.getProducts().get('p1')!.shopPrices), 0);

      final changed = await ItemsSingleton.editItem(priceNotification('p1', 5000));
      await ItemsSingleton.storeProducts();

      expect(changed, 1);
      final saved = HiveBoxes.getProducts().get('p1')!;
      expect(saved.shopPrices?.shID?.shopId, kShop);
      expect(ItemsSingleton.onePrice(saved.shopPrices), 5000);
      // Endi barcode skanerida ham topiladi (narx > 0 talab qilinadi).
      expect(ItemsSingleton.getProductByBarcode('478000p1')?.id, 'p1');
    });

    test('mavjud narx pog\'onalari almashtiriladi (eski xulq)', () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);

      await ItemsSingleton.editItem(priceNotification('p1', 7000));

      final saved = HiveBoxes.getProducts().get('p1')!;
      expect(saved.shopPrices!.shID!.shopPriceTiers!.length, 1);
      expect(ItemsSingleton.onePrice(saved.shopPrices), 7000);
    });

    test('boshqa do\'kon narxi e\'tiborsiz qoladi', () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);

      final changed = await ItemsSingleton.editItem(
          priceNotification('p1', 9999, shop: kOtherShop));

      expect(changed, 0);
      expect(ItemsSingleton.onePrice(HiveBoxes.getProducts().get('p1')!.shopPrices), 3000);
    });

    test('lokalda yo\'q mahsulot — hech narsa bo\'lmaydi, xato yo\'q', () async {
      final changed = await ItemsSingleton.editItem(priceNotification('ghost', 100));
      expect(changed, 0);
    });

    test('narx ma\'lumoti to\'liq bo\'lmasa (tiers yo\'q) o\'tkazib yuboriladi',
        () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);
      final edit = ProductPriceEdit.fromJson({
        'id': 'n', 'type': 13,
        'data': {
          'product_values': [
            {'product_id': 'p1', 'price': {'shop_id': kShop}},
          ],
        },
      });

      final changed = await ItemsSingleton.editItem(edit);

      expect(changed, 0);
      expect(ItemsSingleton.onePrice(HiveBoxes.getProducts().get('p1')!.shopPrices), 3000);
    });
  });

  group('type 1/2 — putItems va narxni saqlash', () {
    test(
        'mergeWithExisting + priceKeyPresent:false: shop_prices KALITI '
        'yo\'q bo\'lsa mavjud narx saqlanadi', () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);

      // Adminkada faqat nom o'zgartirildi — payload'da shop_prices KALITI
      // umuman yo'q (ProductsWsService `data.containsKey('shop_prices')`
      // orqali shuni aniqlaydi).
      final update = product('p1')..name = 'Yangi nom';
      await ItemsSingleton.putItems([update],
          mergeWithExisting: true, priceKeyPresent: false);

      final saved = HiveBoxes.getProducts().get('p1')!;
      expect(saved.name, 'Yangi nom');
      expect(ItemsSingleton.onePrice(saved.shopPrices), 3000);
    });

    test(
        'priceKeyPresent:true (standart) — shop_prices KALITI bo\'lsa '
        'narxsiz yangilash ham narxni O\'CHIRADI (kalit yo\'qligi bilan '
        'chalkashtirilmaydi)', () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);

      final update = product('p1')..name = 'Yangi nom';
      // priceKeyPresent standart bo'yicha true — bu chaqiruvchi shop_prices
      // KALITI payload'da BOR deb bilishini anglatadi (garchi natija narxi
      // bo'sh bo'lsa ham).
      await ItemsSingleton.putItems([update], mergeWithExisting: true);

      expect(HiveBoxes.getProducts().get('p1')!.shopPrices, isNull,
          reason: 'kalit bor edi — server ataylab narxni olib tashlagan '
              'deb hurmat qilinadi');
    });

    test('bayroqsiz (to\'liq yuklash kabi) narx ustidan yoziladi', () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);

      await ItemsSingleton.putItems([product('p1')]);

      expect(HiveBoxes.getProducts().get('p1')!.shopPrices, isNull);
    });

    test('kelgan mahsulotda narx bo\'lsa u ustun', () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);

      await ItemsSingleton.putItems([product('p1', price: priceOf(4500))],
          mergeWithExisting: true);

      expect(ItemsSingleton.onePrice(HiveBoxes.getProducts().get('p1')!.shopPrices), 4500);
    });

    test(
        'shop_prices KALITI bor-u, shu do\'kon narxi 0 (masalan '
        'retail_price:null) — server signali hurmat qilinadi, narx 0 '
        'bo\'ladi (eski narx SAQLANMAYDI)', () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);

      // Jonli ko'rilgan shakl: tier bor, retail_price yo'q (null → 0).
      // `shop_prices` KALITI payload'da BOR — bu "narx yo'q" degan bilinch
      // signal emas, "narx 0/olib tashlangan" degan aniq signal.
      final incoming = product('p1',
          price: ShopPrices(
              shID: ShID(shopId: kShop, shopPriceTiers: [
            ShopPriceTiers(minQuantity: 1, retailPrice: null),
          ])));
      await ItemsSingleton.putItems([incoming], mergeWithExisting: true);

      expect(ItemsSingleton.onePrice(HiveBoxes.getProducts().get('p1')!.shopPrices), 0);
    });

    test('is_active YO\'Q (null) bo\'lsa mahsulot O\'CHIRILMAYDI', () async {
      final item = product('p1')..isActive = null;

      await ItemsSingleton.putItems([item], mergeWithExisting: true);

      expect(HiveBoxes.getProducts().get('p1'), isNotNull,
          reason: 'ilgari !(null ?? false) → o\'chirilardi');
    });

    test('is_active == false bo\'lsa o\'chiriladi', () async {
      await ItemsSingleton.putItems([product('p1')]);

      await ItemsSingleton.putItems([product('p1')..isActive = false],
          mergeWithExisting: true);

      expect(HiveBoxes.getProducts().get('p1'), isNull);
    });

    test('ownerType/commissionTin notification\'da yo\'q bo\'lsa mavjudi qoladi',
        () async {
      await ItemsSingleton.putItems([
        product('p1')
          ..ownerType = '2'
          ..commissionTin = '123456789'
      ]);

      await ItemsSingleton.putItems([product('p1')], mergeWithExisting: true);

      final saved = HiveBoxes.getProducts().get('p1')!;
      expect(saved.ownerType, '2');
      expect(saved.commissionTin, '123456789');

      // Kelgan qiymat bo'lsa u ustun.
      await ItemsSingleton.putItems([product('p1')..ownerType = '1'],
          mergeWithExisting: true);
      expect(HiveBoxes.getProducts().get('p1')!.ownerType, '1');
    });

    test('QQS/o\'lchov birligi lokalda topilmasa mavjudi qoladi', () async {
      await ItemsSingleton.putItems([
        product('p1')
          ..vat = Vat(id: 'vat-12', name: '12%', percentage: 12)
          ..measurementUnit = MeasurementUnit(id: 'u-1', longName: 'dona', shortName: 'd')
      ]);

      // Parser topolmagan → null keladi.
      await ItemsSingleton.putItems([product('p1')], mergeWithExisting: true);

      final saved = HiveBoxes.getProducts().get('p1')!;
      expect(saved.vat?.percentage, 12);
      expect(saved.measurementUnit?.id, 'u-1');
    });

    test('isMarking saqlanishi buzilmagan', () async {
      await ItemsSingleton.putItems([product('p1')..isMarking = true]);

      await ItemsSingleton.putItems([product('p1')], mergeWithExisting: true);

      expect(HiveBoxes.getProducts().get('p1')!.isMarking, isTrue);
    });
  });

  group('parser — buzuq payload oynani yiqitmaydi', () {
    Map<String, dynamic> payload({dynamic images, dynamic categoryIds}) => {
          'id': 'p-new',
          'sku': '777',
          'name': 'Rasmsiz mahsulot',
          'is_active': true,
          'barcode': ['4780001112223'],
          'images': images,
          'category_ids': categoryIds,
          'shop_prices': [
            {
              'shop_id': kShop,
              'supply_price': 900,
              'shop_price_tiers': [
                {'min_quantity': 1, 'retail_price': 1200},
              ],
            },
          ],
        };

    test('images: [] → rasm null, mahsulot saqlanadi', () {
      final item = ItemModel.fromWebSocketJson(payload(images: <dynamic>[]));
      expect(item.id, 'p-new');
      expect(item.image, isNull);
      expect(ItemsSingleton.onePrice(item.shopPrices), 1200);
    });

    test('images: [{image_url}] → to\'liq URL', () {
      final item = ItemModel.fromWebSocketJson(
          payload(images: [{'image_url': 'a/b.png'}]));
      expect(item.image, '${ApiProvider.imageUrl}a/b.png');
    });

    test('fromWebSocketJsonUpdate ham images: [] ga chidaydi', () {
      final item = ItemModel.fromWebSocketJsonUpdate(payload(images: <dynamic>[]));
      expect(item.id, 'p-new');
      expect(item.image, isNull);
    });

    test('type 1 parseri owner_type ni o\'qiydi (int kelsa ham)', () {
      final item = ItemModel.fromWebSocketJson(payload(images: null)..['owner_type'] = 2);
      expect(item.ownerType, '2');
    });

    test('min_quantity double / retail_price satr kelsa ham yiqilmaydi', () {
      final p = payload(images: null);
      (p['shop_prices'] as List)[0]['shop_price_tiers'] = [
        {'min_quantity': 1.0, 'retail_price': '1200'},
      ];
      final item = ItemModel.fromWebSocketJson(p);
      expect(item.shopPrices!.shID!.shopPriceTiers!.first.minQuantity, 1);
      expect(ItemsSingleton.onePrice(item.shopPrices), 1200);
    });

    test('ichki vat/measurement_unit obyekti bo\'lsa undan olinadi', () {
      final p = payload(images: null)
        ..['vat'] = {'id': 'vat-15', 'name': '15%', 'percentage': 15}
        ..['measurement_unit'] = {'id': 'u-kg', 'long_name': 'kilogramm', 'short_name': 'kg'};
      final item = ItemModel.fromWebSocketJson(p);
      expect(item.vat?.percentage, 15);
      expect(item.measurementUnit?.id, 'u-kg');
    });

    test('vat_id lokalda topilmasa null (bo\'sh obyekt emas)', () {
      final p = payload(images: null)..['vat_id'] = 'nomalum';
      final item = ItemModel.fromWebSocketJson(p);
      expect(item.vat, isNull);
    });

    test(
        'categories maydoni ikkala shaklda ham (sof id yoki obyekt '
        'ro\'yxati) xatosiz o\'qiladi — type 1 parseri ilgari faqat sof '
        'id\'ni kutar edi', () {
      final asIds =
          ItemModel.fromWebSocketJson(payload(images: null)..['categories'] = ['cat-1', 'cat-2']);
      expect(asIds.categories!.map((c) => c.id), ['cat-1', 'cat-2']);

      final asObjects = ItemModel.fromWebSocketJson(payload(images: null)
        ..['categories'] = [
          {'id': 'cat-1', 'name': 'Ichimlik', 'parent_id': null},
        ]);
      expect(asObjects.categories!.single.id, 'cat-1');
      expect(asObjects.categories!.single.name, 'Ichimlik');

      // fromWebSocketJsonUpdate (type 2) ham ikkala shaklga chidamli.
      final updateAsIds = ItemModel.fromWebSocketJsonUpdate(
          payload(images: null)..['categories'] = ['cat-9']);
      expect(updateAsIds.categories!.single.id, 'cat-9');
    });

    test('parseCatalog: buzuq yozuv o\'tkazib yuboriladi, qolgani kiradi',
        () async {
      final raw = <dynamic>[
        {'id': 'a', 'name': 'A', 'is_active': true, 'barcode': ['1']},
        'buzuq',
        {'id': 'b', 'name': 'B', 'is_active': true, 'barcode': 'satr-emas-list'},
        {'id': 'c', 'name': 'C', 'is_active': true},
      ];
      final r = await ItemsSingleton.parseCatalog(raw);
      expect(r.items.map((e) => e.id), containsAll(['a', 'c']));
      expect(r.failed, greaterThanOrEqualTo(1));
      expect(r.items.length + r.failed, raw.length);
      // 'b' — Map, id ma'lum, lekin parse bo'lmadi: preserveIds'ga tushadi
      // (clearAndPutItems bu id'ni "serverda yo'q" deb o'chirmasin).
      // 'buzuq' — Map emas, id chiqarib olib bo'lmaydi.
      expect(r.skippedIds, contains('b'));
      expect(r.skippedIds, isNot(contains('a')));
      expect(r.skippedIds, isNot(contains('c')));
    });

    test('category_ids: null / [] → kategoriya null, xato yo\'q', () {
      expect(ProductsWsService.categoriesFromIds(null), isNull);
      expect(ProductsWsService.categoriesFromIds(<dynamic>[]), isNull);
      expect(ProductsWsService.categoriesFromIds('cat'), isNull);
    });

    test('kategoriya hali lokalda bo\'lmasa ham id saqlanadi', () {
      final cats = ProductsWsService.categoriesFromIds(['cat-9']);
      expect(cats, isNotNull);
      expect(cats!.single.id, 'cat-9');
      expect(cats.single.name, isNull);
    });

    test('kategoriya lokalda bo\'lsa nomi ham keladi', () async {
      await HiveBoxes.getCategories()
          .add(CategoryData(id: 'cat-1', name: 'Ichimliklar', children: []));

      final cats = ProductsWsService.categoriesFromIds(['cat-1', 'cat-2']);
      expect(cats!.single.id, 'cat-1');
      expect(cats.single.name, 'Ichimliklar');
    });
  });
}
```

</details>

### 6.30. YANGI: `test/category_ws_idempotent_test.dart`

<details>
<summary>To'liq fayl (103 qator)</summary>

```dart
// Kategoriya notification'lari (type 10/11/12) idempotent bo'lishi kerak:
// sinxron oynalari 2 daqiqa overlap bilan qayta so'raladi, ya'ni bir xil
// "kategoriya yaratildi" xabari 2-3 marta qo'llanadi. Ilgari `box.addAll`
// har safar yangi qator qo'shar, gridda dublikat chiqar, update esa faqat
// birinchisini o'zgartirardi.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_categories/model/category.dart';
import 'package:invan2/features/get_categories/service/category_service.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';

import 'support/provider_harness.dart';

CategoryData cat(String id, String name, {String? parent}) =>
    CategoryData(id: id, name: name, parentId: parent, children: []);

List<String?> idsInBox() =>
    HiveBoxes.getCategories().values.map((c) => c.id).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('category_ws_idempotent_test', withEmployee: false);
    void reg<T>(int typeId, TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(adapter);
    }

    reg(ItemModelAdapter().typeId, ItemModelAdapter());
    reg(ShopPricesAdapter().typeId, ShopPricesAdapter());
    reg(ShIDAdapter().typeId, ShIDAdapter());
    reg(ShopPriceTiersAdapter().typeId, ShopPriceTiersAdapter());
    reg(CategoriesFromProductsAdapter().typeId,
        CategoriesFromProductsAdapter());
    reg(MeasurementUnitAdapter().typeId, MeasurementUnitAdapter());
    reg(VatAdapter().typeId, VatAdapter());
    await Hive.openBox<ItemModel>(HiveBoxNames.items);
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    await HiveBoxes.getCategories().clear();
    await HiveBoxes.getProducts().clear();
  });

  test('type 10 uch marta kelsa ham bitta qator', () async {
    for (int i = 0; i < 3; i++) {
      await CategoryService.categoriesCreateForWebSocket([cat('c1', 'Suv')]);
    }
    expect(idsInBox().where((id) => id == 'c1').length, 1);
  });

  test('type 11 nomni o\'zgartiradi, dublikat yaratmaydi', () async {
    await CategoryService.categoriesCreateForWebSocket([cat('c1', 'Suv')]);
    await CategoryService.categoriesUpdateForWebSocket(cat('c1', 'Ichimlik'));
    await CategoryService.categoriesUpdateForWebSocket(cat('c1', 'Ichimlik'));

    final rows = HiveBoxes.getCategories().values.where((c) => c.id == 'c1');
    expect(rows.length, 1);
    expect(rows.single.name, 'Ichimlik');
  });

  test('type 11 lokalda yo\'q kategoriya uchun yaratadi', () async {
    await CategoryService.categoriesUpdateForWebSocket(cat('c9', 'Yangi'));
    expect(idsInBox(), contains('c9'));
  });

  test('eski dublikatlar upsert\'da yig\'ishtiriladi', () async {
    final box = HiveBoxes.getCategories();
    await box.addAll([cat('c1', 'Suv'), cat('c1', 'Suv'), cat('c1', 'Suv')]);

    await CategoryService.categoriesUpdateForWebSocket(cat('c1', 'Suv 2'));

    expect(idsInBox().where((id) => id == 'c1').length, 1);
  });

  test('type 12 hamma nusxani o\'chiradi va mahsulot kategoriyasini tozalaydi',
      () async {
    final box = HiveBoxes.getCategories();
    await box.addAll([cat('c1', 'Suv'), cat('c1', 'Suv'), cat('c2', 'Non')]);
    final items = HiveBoxes.getProducts();
    await items.put(
        'p1',
        ItemModel(
            id: 'p1',
            name: 'P',
            isActive: true,
            categories: [CategoriesFromProducts(id: 'c1', name: 'Suv')]));

    await CategoryService.categoriesDeleteForWebSocket('c1');

    expect(idsInBox(), ['c2']);
    expect(items.get('p1')!.categories, isNull);
  });

  test('type 12 ikkinchi marta kelsa xato yo\'q', () async {
    await HiveBoxes.getCategories().add(cat('c1', 'Suv'));
    await CategoryService.categoriesDeleteForWebSocket('c1');
    expect(await CategoryService.categoriesDeleteForWebSocket('c1'), isNull);
  });
}
```

</details>

### 6.31. `test/stream_sync_runner_test.dart`

<details>
<summary>Diff (596 qator)</summary>

```diff
diff --git a/test/stream_sync_runner_test.dart b/test/stream_sync_runner_test.dart
index 0ae135a..3226201 100644
--- a/test/stream_sync_runner_test.dart
+++ b/test/stream_sync_runner_test.dart
@@ -7,9 +7,13 @@
 // ishlatiladi, shuning uchun har xil uzilish stsenariysini aniq
 // takrorlash mumkin.
 
+import 'dart:async';
+
 import 'package:flutter_test/flutter_test.dart';
+import 'package:invan2/changes/services/sync/server_clock.dart';
 import 'package:invan2/changes/services/sync/stream_sync_runner.dart';
 import 'package:invan2/changes/services/sync/sync_cursor.dart';
+import 'package:invan2/utils/constants/pref_keys.dart';
 import 'package:invan2/utils/helpers/prefs.dart';
 
 import 'support/provider_harness.dart';
@@ -29,10 +33,18 @@ void main() {
 
   setUp(() async {
     await Pref.setInt(stream.prefKey, 0);
+    await Pref.setInt(stream.chunkPrefKey, 0);
+    await Pref.removeWithKey(stream.reloadFailPrefKey);
+    ServerClock.reset();
     asked = [];
     fullReloadCalls = 0;
   });
 
+  tearDown(() {
+    ServerClock.localNow = () => DateTime.now().toUtc();
+    ServerClock.reset();
+  });
+
   FetchWindow recording(
       SyncFetchResult Function(int callIndex) reply) {
     return (String s, String e) async {
@@ -115,9 +127,13 @@ void main() {
       // Oxirgi so'rov aynan `end` da tugaydi.
       expect(asked.last[1], SyncCursor.format(end));
 
-      // Oynalar orasida bo'shliq yo'q — aks holda notification tushib qoladi.
+      // Oynalar orasida bo'shliq yo'q — har keyingi oyna oldingisining
+      // oxiridan overlap qadar ORTDAN boshlanadi (server chegarani qat'iy
+      // solishtirsa ham chegaradagi soniya tushib qolmasin).
       for (int i = 1; i < asked.length; i++) {
-        expect(asked[i][0], asked[i - 1][1]);
+        final DateTime prevEnd = SyncCursor.fmt.parseUtc(asked[i - 1][1]);
+        expect(asked[i][0],
+            SyncCursor.format(prevEnd.subtract(SyncCursor.overlap)));
       }
 
       expect(SyncCursor.raw(stream, end), end);
@@ -143,8 +159,9 @@ void main() {
 
     test('yangilashga hojat yo\'q bo\'lsa so\'rov ham yubormaydi', () async {
       final end = DateTime.utc(2026, 8, 12, 10);
-      // Kursor `end` dan keyinda — overlap ham hisobga olinsa oyna bo'sh.
-      await SyncCursor.commit(stream, end.add(const Duration(hours: 1)));
+      // Kursor `end` dan aynan overlap qadar keyinda — oyna bo'sh, lekin
+      // bu hali "soat sakragan" emas (chegara), to'liq yuklash ham yo'q.
+      await SyncCursor.commit(stream, end.add(SyncCursor.overlap));
 
       final ok = await runner.run(
         end: end,
@@ -156,6 +173,25 @@ void main() {
       expect(asked, isEmpty);
       expect(fullReloadCalls, 0);
     });
+
+    test('kursor `end` dan overlap\'dan ko\'proq keyinda — soat sakragan → '
+        'to\'liq yuklash va kursor server vaqtiga qaytadi', () async {
+      final end = DateTime.utc(2026, 8, 12, 10);
+      // Eski versiya kassaning 2 soat oldinda yurgan soati bilan yozgan.
+      await SyncCursor.commit(stream, end.add(const Duration(hours: 2)));
+
+      final ok = await runner.run(
+        end: end,
+        fetch: recording((_) => const SyncFetchResult.done(0)),
+        fullReload: reloading(),
+      );
+
+      expect(ok, isTrue);
+      expect(asked, isEmpty);
+      expect(fullReloadCalls, 1);
+      expect(SyncCursor.raw(stream, end), end,
+          reason: 'kursor endi kelajakda emas');
+    });
   });
 
   group('uzilish va davom ettirish — asosiy stsenariy', () {
@@ -455,4 +491,504 @@ void main() {
       expect(SyncCursor.raw(stream, end), end);
     });
   });
+  group('server vaqti — kassa soati oldinda bo\'lsa ham kursor kelajakka ketmaydi',
+      () {
+    test('javobdagi server vaqti `end` dan oldin bo\'lsa kursor unga qisqaradi',
+        () async {
+      // Kassa soati bo'yicha `end` 10:00, server esa aslida 09:57.
+      final end = DateTime.utc(2026, 8, 12, 10);
+      final serverNow = DateTime.utc(2026, 8, 12, 9, 57);
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 9));
+
+      final ok = await runner.run(
+        end: end,
+        fetch: recording(
+            (_) => SyncFetchResult.done(2, serverTime: serverNow)),
+        fullReload: reloading(),
+      );
+
+      expect(ok, isTrue);
+      expect(SyncCursor.raw(stream, end), serverNow,
+          reason: 'keyingi oyna 09:55 dan boshlanadi — 09:57–10:00 '
+              'orasidagi server notification\'lari tushib qolmaydi');
+    });
+
+    test('server vaqti `end` dan keyin bo\'lsa (oddiy holat) kursor `end` da',
+        () async {
+      final end = DateTime.utc(2026, 8, 12, 10);
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 9));
+
+      await runner.run(
+        end: end,
+        fetch: recording((_) => SyncFetchResult.done(0,
+            serverTime: end.add(const Duration(seconds: 1)))),
+        fullReload: reloading(),
+      );
+
+      expect(SyncCursor.raw(stream, end), end);
+    });
+
+    test('oraliq bo\'laklar server vaqtidan ta\'sirlanmaydi', () async {
+      final end = DateTime.utc(2026, 8, 12, 12);
+      final serverNow = DateTime.utc(2026, 8, 12, 11, 58);
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 0));
+
+      // 3-so'rov yiqiladi: kursor 2-bo'lak oxirida qolishi kerak, server
+      // vaqti (11:58) undan keyin bo'lgani uchun uni qisqartirmaydi.
+      await runner.run(
+        end: end,
+        fetch: recording((i) => i == 2
+            ? const SyncFetchResult.failed()
+            : SyncFetchResult.done(1, serverTime: serverNow)),
+        fullReload: reloading(),
+      );
+
+      final expected = DateTime.utc(2026, 8, 12, 0)
+          .subtract(SyncCursor.overlap)
+          .add(const Duration(hours: 12));
+      expect(SyncCursor.raw(stream, end), expected);
+    });
+
+    test('to\'liq yuklashdan keyin kursor server vaqtida (mahalliy emas)',
+        () async {
+      // Kassa soati 2 soat oldinda: mahalliy 12:00, server 10:00.
+      final end = DateTime.utc(2026, 8, 12, 10);
+      ServerClock.localNow = () => DateTime.utc(2026, 8, 12, 12);
+      ServerClock.observe(DateTime.utc(2026, 8, 12, 10),
+          local: DateTime.utc(2026, 8, 12, 12));
+
+      final ok = await runner.run(
+        end: end,
+        fetch: recording((_) => const SyncFetchResult.done(0)),
+        fullReload: reloading(),
+      );
+
+      expect(ok, isTrue);
+      expect(fullReloadCalls, 1);
+      expect(SyncCursor.raw(stream, end), end,
+          reason: 'mahalliy 12:00 emas, server 10:00');
+    });
+  });
+
+  group('buzuq notification oqimni bloklamaydi', () {
+    // Ilgari bitta parse xatosi butun oynani `failed` qilar, kursor joyida
+    // qolar va har daqiqa o'sha xato takrorlanardi — 14 kungacha yoki
+    // qo'lda to'liq yangilashgacha HECH NARSA yangilanmasdi.
+    test('applyFailed → to\'liq yuklash va kursor oldinga suriladi',
+        () async {
+      final end = DateTime.utc(2026, 8, 12, 10);
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 9));
+
+      final ok = await runner.run(
+        end: end,
+        fetch: recording(
+            (_) => const SyncFetchResult.done(5, applyFailed: true)),
+        fullReload: reloading(),
+      );
+
+      expect(ok, isTrue);
+      expect(fullReloadCalls, 1);
+      expect(SyncCursor.raw(stream, end), end);
+
+      // Keyingi chaqiruv eski (09:00 dan) oynani QAYTA so'ramaydi — faqat
+      // odatdagi 2 daqiqalik overlap.
+      asked = [];
+      await runner.run(
+        end: end,
+        fetch: recording((_) => const SyncFetchResult.done(0)),
+        fullReload: reloading(),
+      );
+      expect(asked.length, 1);
+      expect(asked.single[0],
+          SyncCursor.format(end.subtract(SyncCursor.overlap)));
+    });
+
+    test('to\'liq yuklash ham yiqilsa kursor joyida qoladi', () async {
+      final end = DateTime.utc(2026, 8, 12, 10);
+      final before = DateTime.utc(2026, 8, 12, 9);
+      await SyncCursor.commit(stream, before);
+
+      final ok = await runner.run(
+        end: end,
+        fetch: recording(
+            (_) => const SyncFetchResult.done(5, applyFailed: true)),
+        fullReload: reloading(ok: false),
+      );
+
+      expect(ok, isFalse);
+      expect(SyncCursor.raw(stream, end), before);
+    });
+
+    test('bo\'lingan oynaning birinchi yarmidagi applyFailed yo\'qolmaydi',
+        () async {
+      final end = DateTime.utc(2026, 8, 12, 6);
+      await SyncCursor.commit(
+          stream, DateTime.utc(2026, 8, 12, 0).add(SyncCursor.overlap));
+
+      // To'la oyna limitga uriladi → bo'linadi; birinchi yarimda buzuq
+      // notification bor, ikkinchi yarim toza.
+      final ok = await runner.run(
+        end: end,
+        fetch: recording((i) {
+          if (i == 0) return const SyncFetchResult.done(1000, truncated: true);
+          if (i == 1) return const SyncFetchResult.done(10, applyFailed: true);
+          return const SyncFetchResult.done(10);
+        }),
+        fullReload: reloading(),
+      );
+
+      expect(ok, isTrue);
+      expect(fullReloadCalls, 1, reason: 'applyFailed e\'tiborsiz qolmasin');
+    });
+  });
+
+  group('timeout — sekin internetda katta oyna', () {
+    test('uzun oyna timeout bo\'lsa ikkiga bo\'lib qayta so\'raladi', () async {
+      final end = DateTime.utc(2026, 8, 12, 6);
+      await SyncCursor.commit(
+          stream, DateTime.utc(2026, 8, 12, 0).add(SyncCursor.overlap));
+
+      final ok = await runner.run(
+        end: end,
+        fetch: recording((i) => i == 0
+            ? const SyncFetchResult.failed(timedOut: true)
+            : const SyncFetchResult.done(3)),
+        fullReload: reloading(),
+      );
+
+      expect(ok, isTrue);
+      expect(asked.length, 3, reason: '1 to\'la + 2 yarim');
+      expect(SyncCursor.raw(stream, end), end);
+    });
+
+    test('qisqa oyna (oddiy daqiqalik) timeout bo\'lsa bo\'linmaydi', () async {
+      final end = DateTime.utc(2026, 8, 12, 10);
+      await SyncCursor.commit(stream, end.subtract(const Duration(minutes: 1)));
+
+      final ok = await runner.run(
+        end: end,
+        fetch: recording((_) => const SyncFetchResult.failed(timedOut: true)),
+        fullReload: reloading(),
+      );
+
+      expect(ok, isFalse);
+      expect(asked.length, 1);
+    });
+
+    test('timeout\'dan keyin bo\'lak kichrayadi, muvaffaqiyatdan keyin qaytadi',
+        () async {
+      final end = DateTime.utc(2026, 8, 12, 12);
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 0));
+
+      // Hamma so'rov timeout: oyna 6 soat → keyingi safar 3 soat.
+      await runner.run(
+        end: end,
+        fetch: recording((_) => const SyncFetchResult.failed(timedOut: true)),
+        fullReload: reloading(),
+      );
+      expect(SyncCursor.chunk(stream, StreamSyncRunner.defaultChunk),
+          const Duration(hours: 3));
+
+      // Endi 3 soatlik bo'laklar bilan so'raladi va muvaffaqiyatli bo'lsa
+      // bo'lak yana o'sadi.
+      asked = [];
+      await runner.run(
+        end: end,
+        fetch: recording((_) => const SyncFetchResult.done(1)),
+        fullReload: reloading(),
+      );
+      final firstWindow = asked.first;
+      final s = SyncCursor.fmt.parseUtc(firstWindow[0]);
+      final e = SyncCursor.fmt.parseUtc(firstWindow[1]);
+      expect(e.difference(s), const Duration(hours: 3));
+      expect(SyncCursor.chunk(stream, StreamSyncRunner.defaultChunk),
+          const Duration(hours: 6));
+    });
+
+    test('bo\'lak hech qachon minChunk dan kichik bo\'lmaydi', () async {
+      final end = DateTime.utc(2026, 8, 12, 12);
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 0));
+
+      for (int i = 0; i < 10; i++) {
+        await runner.run(
+          end: end,
+          fetch:
+              recording((_) => const SyncFetchResult.failed(timedOut: true)),
+          fullReload: reloading(),
+        );
+      }
+      expect(SyncCursor.chunk(stream, StreamSyncRunner.defaultChunk),
+          StreamSyncRunner.minChunk);
+    });
+  });
+  group('monoton kursor va to\'xtatish (preempt)', () {
+    test('oddiy commit kursorni orqaga surmaydi', () async {
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 12));
+      final moved =
+          await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 10));
+      expect(moved, isFalse);
+      expect(SyncCursor.raw(stream, DateTime.utc(2026, 8, 12, 13)),
+          DateTime.utc(2026, 8, 12, 12));
+    });
+
+    test('force commit (to\'liq yuklash) orqaga ham yozadi', () async {
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 12));
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 10),
+          force: true);
+      expect(SyncCursor.raw(stream, DateTime.utc(2026, 8, 12, 13)),
+          DateTime.utc(2026, 8, 12, 10));
+    });
+
+    test('qulf boshqa egaga o\'tsa run hech narsa yozmaydi', () async {
+      final end = DateTime.utc(2026, 8, 12, 12);
+      final before = DateTime.utc(2026, 8, 12, 0);
+      await SyncCursor.commit(stream, before);
+
+      int calls = 0;
+      final ok = await runner.run(
+        end: end,
+        // Ikkinchi oynadan boshlab qulf yo'qolgan.
+        shouldContinue: () => calls < 1,
+        fetch: recording((_) {
+          calls++;
+          return const SyncFetchResult.done(1);
+        }),
+        fullReload: reloading(),
+      );
+
+      expect(ok, isFalse);
+      expect(asked.length, 1);
+      expect(SyncCursor.raw(stream, end), before,
+          reason: 'birinchi oyna ham commit qilinmaydi — commit oldidan '
+              'qulf tekshiriladi');
+    });
+
+    test('beforeCommit har commit oldidan chaqiriladi', () async {
+      final end = DateTime.utc(2026, 8, 12, 12);
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 0));
+      int flushed = 0;
+
+      await runner.run(
+        end: end,
+        beforeCommit: () async => flushed++,
+        fetch: recording((_) => const SyncFetchResult.done(0)),
+        fullReload: reloading(),
+      );
+
+      expect(flushed, asked.length);
+    });
+  });
+
+  group('server hozir, 401, type 0', () {
+    test('server "hozir"iga yetgach qolgan (kelajak) oynalar so\'ralmaydi',
+        () async {
+      // Kassa soati 5 soat oldinda deylik: end 15:00, server aslida 10:00.
+      final end = DateTime.utc(2026, 8, 12, 15);
+      final serverNow = DateTime.utc(2026, 8, 12, 10);
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 3));
+
+      await runner.run(
+        end: end,
+        fetch: recording((_) => SyncFetchResult.done(0, serverTime: serverNow)),
+        fullReload: reloading(),
+      );
+
+      // 03:00→15:00 = 12 soat = 2 oyna; birinchisi (03–09) server
+      // hozirdan oldin, ikkinchisi (09–15) uni qamrab oladi → to'xtaydi.
+      expect(asked.length, 2);
+      expect(SyncCursor.raw(stream, end), serverNow);
+    });
+
+    test('401 → kursor joyida, bo\'lak kichraymaydi', () async {
+      final end = DateTime.utc(2026, 8, 12, 12);
+      final before = DateTime.utc(2026, 8, 12, 0);
+      await SyncCursor.commit(stream, before);
+
+      final ok = await runner.run(
+        end: end,
+        fetch: recording(
+            (_) => const SyncFetchResult.failed(unauthorized: true)),
+        fullReload: reloading(),
+      );
+
+      expect(ok, isFalse);
+      expect(asked.length, 1);
+      expect(SyncCursor.raw(stream, end), before);
+      expect(SyncCursor.chunk(stream, StreamSyncRunner.defaultChunk),
+          StreamSyncRunner.defaultChunk);
+    });
+
+    test('type 0 (fullReloadRequested) → bitta to\'liq yuklash, kursor end da',
+        () async {
+      final end = DateTime.utc(2026, 8, 12, 12);
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 0));
+
+      final ok = await runner.run(
+        end: end,
+        fetch: recording((i) => i == 0
+            ? const SyncFetchResult.done(3, fullReloadRequested: true)
+            : const SyncFetchResult.done(0)),
+        fullReload: reloading(),
+      );
+
+      expect(ok, isTrue);
+      expect(fullReloadCalls, 1);
+      expect(asked.length, 1, reason: 'qolgan oynalar so\'ralmaydi');
+      expect(SyncCursor.raw(stream, end), end);
+    });
+  });
+
+  group('eng kichik oyna timeout va backoff', () {
+    test('minChunk oyna ham timeout bo\'lsa to\'liq yuklashga o\'tadi',
+        () async {
+      final end = DateTime.utc(2026, 8, 12, 12);
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 11));
+      await SyncCursor.setChunk(stream, StreamSyncRunner.minChunk);
+
+      final ok = await runner.run(
+        end: end,
+        fetch: recording((_) => const SyncFetchResult.failed(timedOut: true)),
+        fullReload: reloading(),
+      );
+
+      expect(ok, isTrue);
+      expect(fullReloadCalls, 1);
+      expect(SyncCursor.raw(stream, end), end);
+    });
+
+    test('yiqilgan to\'liq yuklash 5 daqiqa qayta urinilmaydi (backoff)',
+        () async {
+      final end = DateTime.utc(2026, 8, 12, 12);
+
+      await runner.run(
+        end: end,
+        fetch: recording((_) => const SyncFetchResult.done(0)),
+        fullReload: reloading(ok: false),
+      );
+      expect(fullReloadCalls, 1);
+
+      // Bir daqiqadan keyin yana — urinilmaydi.
+      await runner.run(
+        end: end.add(const Duration(minutes: 1)),
+        fetch: recording((_) => const SyncFetchResult.done(0)),
+        fullReload: reloading(ok: false),
+      );
+      expect(fullReloadCalls, 1);
+
+      // force (ilova ochilganda / qo'lda) — chetlab o'tadi.
+      await runner.run(
+        end: end.add(const Duration(minutes: 2)),
+        force: true,
+        fetch: recording((_) => const SyncFetchResult.done(0)),
+        fullReload: reloading(ok: false),
+      );
+      expect(fullReloadCalls, 2);
+
+      // 5 daqiqadan keyin — yana uriniladi.
+      await runner.run(
+        end: end.add(const Duration(minutes: 8)),
+        fetch: recording((_) => const SyncFetchResult.done(0)),
+        fullReload: reloading(),
+      );
+      expect(fullReloadCalls, 3);
+      expect(SyncCursor.has(stream), isTrue);
+    });
+
+    test('qisqa (3 daqiqalik) oyna timeout bo\'lsa bo\'lak kichraymaydi',
+        () async {
+      final end = DateTime.utc(2026, 8, 12, 12);
+      await SyncCursor.commit(stream, end.subtract(const Duration(minutes: 1)));
+
+      await runner.run(
+        end: end,
+        fetch: recording((_) => const SyncFetchResult.failed(timedOut: true)),
+        fullReload: reloading(),
+      );
+
+      expect(SyncCursor.chunk(stream, StreamSyncRunner.defaultChunk),
+          StreamSyncRunner.defaultChunk);
+    });
+  });
+
+  group('migratsiya va tashlash', () {
+    test('sxema versiyasi eski bo\'lsa hamma kursor tashlanadi (bir marta)',
+        () async {
+      for (final SyncStream st in SyncStream.values) {
+        await SyncCursor.commit(st, DateTime.utc(2026, 8, 12, 10));
+      }
+      await Pref.setInt(PrefKeys.syncCursorSchema, 0);
+
+      await SyncCursor.migrateIfNeeded();
+      for (final SyncStream st in SyncStream.values) {
+        expect(SyncCursor.has(st), isFalse);
+      }
+
+      // Ikkinchi marta — tegmaydi.
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 11));
+      await SyncCursor.migrateIfNeeded();
+      expect(SyncCursor.has(stream), isTrue);
+    });
+
+    test('reset → keyingi run to\'liq yuklaydi', () async {
+      final end = DateTime.utc(2026, 8, 12, 12);
+      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 11));
+      await SyncCursor.reset(stream, reason: 'test');
+
+      await runner.run(
+        end: end,
+        fetch: recording((_) => const SyncFetchResult.done(0)),
+        fullReload: reloading(),
+      );
+      expect(fullReloadCalls, 1);
+      expect(asked, isEmpty);
+    });
+  });
+
+  group('to\'liq yuklash muddati tugashi — ish o\'zi to\'xtatiladi', () {
+    setUp(() {
+      StreamSyncRunner.fullReloadTimeout = const Duration(milliseconds: 50);
+    });
+    tearDown(() {
+      StreamSyncRunner.fullReloadTimeout = const Duration(minutes: 15);
+    });
+
+    test(
+        'muddat tugasa onFullReloadTimeout chaqiriladi (masalan yuklashni '
+        'majburan to\'xtatish uchun)', () async {
+      final end = DateTime.utc(2026, 8, 12, 12);
+      int cancelCalls = 0;
+
+      final ok = await runner.run(
+        end: end,
+        fetch: recording((_) => const SyncFetchResult.done(0)),
+        // Hech qachon tugamaydigan "yuklash" — Future.timeout uni real
+        // hayotda ham to'xtata olmaydi, shuning uchun onFullReloadTimeout
+        // orqali chaqiruvchi o'zi bekor qilishi kerak.
+        fullReload: () => Completer<bool>().future,
+        onFullReloadTimeout: () => cancelCalls++,
+      );
+
+      expect(ok, isFalse);
+      expect(cancelCalls, 1,
+          reason: '15 daqiqalik Future.timeout to\'xtagach chaqiruvchiga '
+              'xabar berilishi kerak — aks holda yuklash fonda abadiy '
+              'davom etar edi');
+      expect(SyncCursor.has(stream), isFalse);
+    });
+
+    test('muvaffaqiyatli to\'liq yuklashda onFullReloadTimeout chaqirilmaydi',
+        () async {
+      final end = DateTime.utc(2026, 8, 12, 12);
+      int cancelCalls = 0;
+
+      await runner.run(
+        end: end,
+        fetch: recording((_) => const SyncFetchResult.done(0)),
+        fullReload: reloading(),
+        onFullReloadTimeout: () => cancelCalls++,
+      );
+
+      expect(cancelCalls, 0);
+    });
+  });
 }
```

</details>

### 6.32. `test/items_bulk_write_test.dart`

<details>
<summary>Diff (42 qator)</summary>

```diff
diff --git a/test/items_bulk_write_test.dart b/test/items_bulk_write_test.dart
index 1e6b2c4..540a930 100644
--- a/test/items_bulk_write_test.dart
+++ b/test/items_bulk_write_test.dart
@@ -127,6 +127,37 @@ void main() {
     expect(ItemsSingleton.getProductById('prod-49'), isNotNull);
   });
 
+  test(
+      'preserveIds: bu safar parse bo\'lmagan mahsulot "serverda yo\'q" deb '
+      'O\'CHIRILMAYDI', () async {
+    await ItemsSingleton.clearAndPutItems(List.generate(100, makeItem));
+    await ItemsSingleton.storeProducts();
+    expect(ItemsSingleton.getProductById('prod-77'), isNotNull);
+
+    // Keyingi to'liq yuklashda prod-77 buzuq yozuv bo'lgani uchun parse
+    // bo'lmadi (items ro'yxatida yo'q), lekin id'si ma'lum — preserveIds'ga
+    // qo'shiladi. Qolgan 99 tasi muvaffaqiyatli.
+    final items = List.generate(100, makeItem)
+      ..removeWhere((e) => e.id == 'prod-77');
+    await ItemsSingleton.clearAndPutItems(items,
+        preserveIds: {'prod-77'});
+    await ItemsSingleton.storeProducts();
+
+    expect(ItemsSingleton.getProductById('prod-77'), isNotNull,
+        reason: 'ilgari: parse bo\'lmagan = "serverda yo\'q" bilan bir xil '
+            'ko\'rilib o\'chirilardi');
+    expect(HiveBoxes.getProducts().length, 100);
+  });
+
+  test('preserveIds bo\'lmasa (standart) haqiqatan yo\'q mahsulot o\'chadi',
+      () async {
+    await ItemsSingleton.clearAndPutItems(List.generate(10, makeItem));
+    await ItemsSingleton.clearAndPutItems(
+        List.generate(10, makeItem)..removeWhere((e) => e.id == 'prod-5'));
+
+    expect(ItemsSingleton.getProductById('prod-5'), isNull);
+  });
+
   test('notification orqali kelgan katta paket (putItems) qo\'shiladi',
       () async {
     await ItemsSingleton.clearAndPutItems(List.generate(1000, makeItem));
```

</details>

### 6.33. `test/backend_health_test.dart`

<details>
<summary>Diff (32 qator)</summary>

```diff
diff --git a/test/backend_health_test.dart b/test/backend_health_test.dart
index 18be045..d0c2c92 100644
--- a/test/backend_health_test.dart
+++ b/test/backend_health_test.dart
@@ -141,11 +141,26 @@ void main() {
     });
 
     test('4xx — rad etish (qayta yuborish foydasiz)', () async {
-      for (final int code in [400, 401, 403, 404, 422]) {
+      // 401/403/408/429 bu yerga KIRMAYDI — pastdagi alohida guruhga
+      // qarang: ular sessiya/so'rov holati, hujjatning o'zi emas.
+      for (final int code in [400, 404, 422]) {
         expect(await BackendHealth.isDocumentRejection(code), isTrue);
       }
     });
 
+    // Token eskirgan (401/403), so'rov vaqti tugagan (408) yoki cheklovga
+    // uchragan (429) hujjatning o'zi bilan bog'liq emas — qayta yuborish
+    // (token yangilangach yoki keyinroq) muvaffaqiyatli bo'lishi mumkin.
+    // Ilgari bular ham "rad etilgan" sanalar, natijada masalan qaytarish
+    // (refund) navbatdan abadiy chiqib ketardi va token muammosi
+    // tuzatilgandan keyin ham hech qachon qayta yuborilmasdi.
+    test('401/403/408/429 — rad etish EMAS, navbatda qoladi', () async {
+      for (final int code in [401, 403, 408, 429]) {
+        expect(await BackendHealth.isDocumentRejection(code), isFalse,
+            reason: '$code — sessiya/so\'rov holati, hujjat emas');
+      }
+    });
+
     // 409 ni chaqiruvchilar (UsrBloc, RefundUploadQueue) MUVAFFAQIYAT deb
     // hal qiladi — bu yerga umuman yetib kelmaydi. Test shuni mixlaydi:
     // agar kimdir 409 ni shu metodga uzatsa, u "rad etilgan" deb
```

</details>

## 7. Tekshirish

- `flutter analyze lib test` — 0 xato (2026-09-24).
- `flutter test` — bu ish yolg'iz 1290/1290; 5-task (fiskal QQS) bilan birlashtirilgach to'liq to'plam **1357/1357** (2026-09-24).
- Ko'p-agentli audit workflow: 46 stsenariy, har biri 2-3 mustaqil skeptik tomonidan tekshirilgan; alohida 7-linzali kashfiyot bosqichi (ikkinchi marta ishga tushirilgan, shu ish USTIDAGI kamchiliklarni — jumladan yuqoridagi KRITIK regressiyani — topgan). To'liq tahlil, rad etilgan gipotezalar, ataylab tuzatilmagan topilmalar: `docs/sessions/2026-09-24-ws-notification-gap-audit.md`.
- Jonli API tekshiruvi qilinmadi (token materializatsiyasi rad etildi, xavfsizlik siyosati). `is_read=false` faqat 2026-08-21'da jonli tekshirilgan (eski task, `docs/sessions/archive/2026-08-21-price-sync-missing-on-some-kassas.md`).
- **Do'kon sinovi (Windows, real tarmoq) hali qilinmadi** — eng muhim tekshiruv: kassa soatini ataylab 10 daqiqa oldinga surib narx o'zgartirish, rasmsiz/kategoriyasiz mahsulot yaratish, internet uzilishi, kassa bir necha kun o'chiq turishi.

## 8. Eslatmalar va ochiq savollar

**Backend savollari (InVan 1 uchun ham dolzarb, agar bir xil backend ishlatilsa):**
- `is_read` parametri GLOBAL (server darajasida) yoki QURILMA bo'yichami? Admin panel yoki boshqa klient notification'ni "o'qildi" deb belgilasa, `is_read=false` filtri bilan bu kassa uni umuman ko'rmaydi. **Filtr ATAYLAB o'zgartirilmadi** (avval olib tashlab ko'rilgan, keyin xavfli deb qaytarilgan — tarixni sessiya hujjatida ko'ring).
- Server `notifications` javobini qaysi tartibda qaytaradi (asc/desc created_at bo'yicha)? Klient tomonda barqaror tartiblanadi, lekin bu server kafolatiga bog'liq emas.
- Mahsulotga tegishli boshqa notification `type` lari bormi (hozir so'ralayotgan: `0,1,2,3,6,13,20,21,40`)? Masalan o'lchov birligi/QQS o'zgarishi uchun alohida type yo'q — ular faqat qo'lda "Servis" bosqichida yangilanadi.

**Ataylab tuzatilmagan (past ustuvorlik yoki kattaroq refaktor talab qiladi — InVan 1'ga portlashda ham shu holicha qoldirilishi mumkin):**
- DNS-only internet uzilishi `BackendHealth`da "server o'chgan" deb noto'g'ri tasniflanishi mumkin (`_defaultProbe` hostname orqali so'raydi). **Mahsulot/narx sinxroniga (bu taskning predmeti) TA'SIRI YO'Q** — notification yo'li `BackendHealth`dan butunlay mustaqil, raw HTTP client ishlatadi. Faqat chiquvchi so'rovlarga (chek, qaytarish, smena) tegishli, va u yerda ham eng ko'pi ~30s kechikish, ma'lumot yo'qolishi emas.
- Drawer "Sinxronizatsiya" (qo'lda tugma) kategoriya kursorini commit qilmaydi — samaradorlik masalasi (keyingi avto-sinxron ortiqcha oyna so'raydi), ma'lumot yo'qolmaydi.
- `isMarking=true` mahsulotda "yopishib qoladi" (`putItems` merge) — admin uni `false` qilsa ham notification orqali qaytmaydi. Bu **taskdan OLDIN ham shunday edi** (regressiya emas) — alohida soliq-MXIK moslashtirish job'iga ishonilgani uchun ataylab qilingan bo'lishi mumkin. **→ 2026-09-30: do'konda jonli muammo chiqardi va 7-TASKDA TUZATILDI** (bu bandni endi qo'llamang, 7-task diffini qo'llang).
- Notification yo'lida mahsulot faqat BITTA kategoriyaga (`category_ids.first`) bog'lanadi, to'liq katalog esa butun ierarxiyani beradi — bu ham OLDINDAN mavjud xulq, tuzatilmadi.
- Bir soniya ichida type 13 (narx) type 1 (yaratish)dan OLDIN kelsa (server tartibi noma'lum bo'lgan holatda) narx qo'llanmay qolishi mumkin — juda tor chekka holat.
- Qulf majburan olinganda (`exclusive` force, stale-lock, logout) eski jarayonning JORIY oynadagi qo'llash tsikli darhol to'xtamaydi (faqat keyingi fetch/commit oldidan tekshiriladi) — kengroq himoya (monoton kursor, epoch) asosiy xavfni (kursor orqaga surilishi) yopadi, qolgani nozik race.
- Hive (2.2.3) haqiqiy `fsync` qilmaydi — `box.flush()` shu kutubxonaning eng yaxshi vositasi. Qattiq svet o'chishida nazariy jihatdan bir necha soniyalik oyna qoladi; `beforeCommit` orqali ma'lumot kursordan OLDIN yoziladi — bu asosiy xavfni yopadi, lekin OS darajasidagi to'liq kafolat yo'q.

---

# 7-TASK — `is_marking` true→false o'zgarishi kassaga o'tmasligi: sticky isMarking (1.1.2+129)

> **Commit:** `a83668c` (2026-09-30) + e2e test `d31e4df` (2026-10-01); `ayyubxon`ga `1e96fc5` da birlashtirilgan; reliz `c4e42e1` 1.1.2+129.
> **Sessiya hujjati:** docs/sessions/2026-09-30-is-marking-notification-sticky.md
> **Holat 2026-10-02:** relizda (1.1.2+129, PRO backendga yuklangan); do'kon sinovi kutilmoqda. Odoo forkiga: `a83668c` — kerak; `d31e4df` — kerak emas (InVan notification feed'iga bog'liq e2e test).

## 1. Nima va nima uchun

**Simptom (jonli, 2026-09-30, Tiin Optom):** adminkada mahsulot markirovkasi o'chirildi (`is_marking` true→false). Notification (type 2) kassalarga yetib keldi — Alice'da `"is_marking": false` ko'rinib turibdi, narx/nom qo'llandi — lekin kassalar baribir markirovka (KM) so'rayverdi. Qo'lda to'liq yangilashdan keyingina to'g'rilanardi; bir kassada keyinroq (Servis'da qo'lda yangilashdan so'ng) muammo QAYTIB keldi.

**Sabab — 2 ta joy serverning aniq `false` qiymatini ustidan yozadi:**

1. `ItemsSingleton.putItems` (har notification shu orqali yoziladi): "lokalda `isMarking == true` bo'lsa — kelgan qiymatdan qat'i nazar true'ga qaytarish" (sticky). Adminka true→false qilsa, notification orqali HECH QACHON o'tmaydi — barcha kassada, deterministik. 6-task oxiridagi "Ataylab tuzatilmagan" ro'yxatida qayd etilgan edi; jonli hodisa uni haqiqiy bug ekanini isbotladi.
2. `OrdersService.updateMarkingStatusFromSoliq` (Servis'dagi qo'lda yangilashdan keyin, `switchMarking` pref true bo'lsa): MXIK Soliq markirovka ro'yxatida bo'lsa `false`ni ham `true` qilib qo'yardi (`p.isMarking ?? false` — false'ni null'dan ajratmasdi). Shu tufayli to'liq yuklab to'g'rilangan mahsulot keyingi qo'lda yangilashda yana markirovkali bo'lib qolardi; keyin 1-band uni qulflab qo'yardi.

**Yechim:** ikkala joyda ham qoida "2-TASK: is_marking — birinchi mezon"ga moslashtirildi: **serverdan kelgan aniq true/false har doim ustun; mavjud lokal qiymat faqat payload'da bayroq umuman bo'lmaganda (null) saqlanadi;** Soliq ro'yxati bo'yicha avto-true faqat `isMarking == null` mahsulotlarga.

## 2. Qanday ishlaydi (eski vs yangi)

`putItems`da mavjud mahsulot ustiga yozishda:

| Kelgan `is_marking` | Lokal qiymat | ESKI natija | YANGI natija |
|---|---|---|---|
| `false` | `true` | **`true` (bug)** | `false` |
| `true` | `false`/`null` | `true` | `true` |
| `null` (payload'da yo'q) | `true`/`false` | `true` faqat true'da | lokal qiymat saqlanadi |
| `false`/`true` | teng emas | — | yoziladi + `SYNC_MARKING_CHANGED` log (id, from, to) |

`updateMarkingStatusFromSoliq`da (MXIK Soliq ro'yxatida bo'lsa):

| Lokal `isMarking` | ESKI | YANGI |
|---|---|---|
| `null` | `true` qilinadi | `true` qilinadi (foydali eski xulq saqlandi) |
| `false` | **`true` qilinadi (bug)** | TEGILMAYDI |
| `true` | tegilmaydi | tegilmaydi |

To'liq yuklash (`clearAndPutItems`) ilgari ham sticky'siz to'g'ri yozardi — o'zgartirilmagan.

## 3. O'zgarishlar ro'yxati

| Fayl | Tur | Nima |
|---|---|---|
| `lib/features/get_products/singletons/items_singleton.dart` | o'zgargan | `putItems`: sticky isMarking → null-only saqlash + `SYNC_MARKING_CHANGED` log |
| `lib/changes/services/get_items_service.dart` | o'zgargan | `updateMarkingStatusFromSoliq`: avto-true faqat `isMarking == null` ga |
| `test/items_singleton_notification_test.dart` | o'zgargan | 6 yangi/yangilangan test (eski "isMarking saqlanishi buzilmagan" testi buggy xulqni qulflagan edi — teskarisiga o'zgartirildi) |

## 4. Bog'liqliklar (InVan 1 uchun)

- **`LogHelper.activity`** — diagnostika logi (6-taskda kiritilgan). InVan 1 da bo'lmasa: `SYNC_MARKING_CHANGED` blokini oddiy log/print bilan almashtiring yoki butunlay tashlab keting — funksional emas.
- **`updateMarkingStatusFromSoliq`** InVan 1 da umuman bo'lmasligi mumkin (Soliq MXIK ro'yxatidan avto-markirovka job'i). Bo'lmasa — 2-qadam kerak emas.
- InVan 1 da `putItems` analogi boshqacha nomlanishi mumkin: **notification/WS orqali kelgan mahsulotni lokal bazaga yozadigan JOYNI toping** va "mavjud isMarking'ni saqlash" kodi bor-yo'qligini tekshiring. Printsip bitta: serverdan kelgan aniq qiymat lokalni yengishi shart.
- 2-TASK (is_marking birinchi mezon, MxikRules) qo'llangan bo'lishi kerak — 7-task o'sha qoidaning YOZISH tomonini tuzatadi.

## 5. Qo'llash tartibi

1. `putItems` (yoki analogi)dagi sticky blokni 6.1-diff bo'yicha almashtiring.
2. Soliq avto-markirovka job'i bo'lsa, shartini 6.2-diff bo'yicha `isMarking == null` ga toraytiring.
3. Testlarni qo'shing (6.3, `<details>`).
4. `dart analyze` + `flutter test`.

## 6. Kod

### 6.1 `lib/features/get_products/singletons/items_singleton.dart` (diff)

```diff
       } else {
         final existing = box.get(item.id);
         if (existing != null) {
-          // Mavjud productning isMarking qiymatini saqlash
-          if (existing.isMarking == true) {
-            item = item.copyWith(isMarking: true);
+          // `is_marking` payload'da bo'lmasa (null) mavjud qiymat qoladi;
+          // kelgan ANIQ true/false esa har doim ustun. Ilgari lokal true
+          // serverning false'ini yutib yuborardi: adminkada markirovka
+          // o'chirilsa notification kassaga yetib kelsa ham hech qachon
+          // qo'llanmasdi, faqat to'liq yuklash yordam berardi (2026-09-30).
+          if (item.isMarking == null && existing.isMarking != null) {
+            item = item.copyWith(isMarking: existing.isMarking);
+          } else if (existing.isMarking != item.isMarking) {
+            LogHelper.activity('SYNC_MARKING_CHANGED', {
+              'id': item.id,
+              'from': existing.isMarking,
+              'to': item.isMarking,
+            });
           }
           if (mergeWithExisting) {
             item = _mergeFromExisting(item, existing,
```

Eslatma: `copyWith` `??` bilan ishlaydi — `copyWith(isMarking: false)` false'ni yozadi (faqat null "tegma" degani), shuning uchun `existing.isMarking` (true ham, false ham) to'g'ri ko'chadi.

### 6.2 `lib/changes/services/get_items_service.dart` (diff, `updateMarkingStatusFromSoliq` ichida)

```diff
         final mxik = (p.mxikCode ?? '').trim();
         if (mxik.isEmpty) continue;
 
-        final bool currentMarking = p.isMarking ?? false;
-        if (markingMxikSet.contains(mxik) && !currentMarking) {
+        // `is_marking` — birinchi mezon (2026-09-11 qarori): adminka aniq
+        // FALSE degan mahsulot MXIK Soliq ro'yxatida bo'lsa ham markirovkali
+        // qilinMAYDI. Avto-true faqat bayroq umuman kelmagan (null)
+        // mahsulotlarga. Ilgari false ham true qilinardi — adminkada
+        // o'chirilgan markirovka keyingi qo'lda yangilashda qaytib kelardi.
+        if (markingMxikSet.contains(mxik) && p.isMarking == null) {
           updates[p.key] = p.copyWith(isMarking: true);
         }
       }
```

### 6.3 Testlar

<details>
<summary>test/items_singleton_notification_test.dart (diff)</summary>

```diff
@@ imports @@
 import 'package:invan2/changes/models/product/item_model.dart';
+import 'package:invan2/changes/models/product/soliq_mxik_model.dart';
 import 'package:invan2/changes/services/api/api_provider.dart';
+import 'package:invan2/changes/services/get_items_service.dart';
@@ setUpAll @@
     reg(MesUnitModelAdapter().typeId, MesUnitModelAdapter());
     reg(VatUnitModelAdapter().typeId, VatUnitModelAdapter());
+    reg(SoliqMxikModelAdapter().typeId, SoliqMxikModelAdapter());
 
+    await Hive.openBox<SoliqMxikModel>(HiveBoxNames.markingProducts);
     await Hive.openBox<ItemModel>(HiveBoxNames.items);
@@ "type 1/2 — putItems va narxni saqlash" guruhida eski test almashtirildi @@
-    test('isMarking saqlanishi buzilmagan', () async {
+    // `is_marking` — birinchi mezon: serverdan kelgan ANIQ qiymat har doim
+    // ustun, mavjud qiymat faqat payload'da bayroq bo'lmaganda (null)
+    // saqlanadi. Eski xulq (lokal true false'ni yutardi) tufayli adminkada
+    // markirovka o'chirilsa kassaga hech qachon yetmasdi (2026-09-30).
+    test('notification aniq false yuborsa false YOZILADI (true→false)',
+        () async {
       await ItemsSingleton.putItems([product('p1')..isMarking = true]);
 
+      // product() helper is_marking: false bilan yaratadi — adminka
+      // "markirovkali emas" degan holat.
       await ItemsSingleton.putItems([product('p1')], mergeWithExisting: true);
 
+      expect(HiveBoxes.getProducts().get('p1')!.isMarking, isFalse);
+    });
+
+    test('payload\'da is_marking BO\'LMASA (null) mavjud true saqlanadi',
+        () async {
+      await ItemsSingleton.putItems([product('p1')..isMarking = true]);
+
+      await ItemsSingleton.putItems([product('p1')..isMarking = null],
+          mergeWithExisting: true);
+
+      expect(HiveBoxes.getProducts().get('p1')!.isMarking, isTrue);
+    });
+
+    test('payload\'da is_marking bo\'lmasa mavjud false ham saqlanadi',
+        () async {
+      await ItemsSingleton.putItems([product('p1')]); // isMarking: false
+
+      await ItemsSingleton.putItems([product('p1')..isMarking = null],
+          mergeWithExisting: true);
+
+      expect(HiveBoxes.getProducts().get('p1')!.isMarking, isFalse);
+    });
+
+    test('false→true (adminka markirovkani yoqdi) ham darrov qo\'llanadi',
+        () async {
+      await ItemsSingleton.putItems([product('p1')]); // isMarking: false
+
+      await ItemsSingleton.putItems([product('p1')..isMarking = true],
+          mergeWithExisting: true);
+
       expect(HiveBoxes.getProducts().get('p1')!.isMarking, isTrue);
     });
+
+    test('merge\'siz putItems ham aniq false\'ni yozadi', () async {
+      await ItemsSingleton.putItems([product('p1')..isMarking = true]);
+
+      await ItemsSingleton.putItems([product('p1')]); // isMarking: false
+
+      expect(HiveBoxes.getProducts().get('p1')!.isMarking, isFalse);
+    });
   });
@@ fayl oxiriga yangi guruh @@
+  group('updateMarkingStatusFromSoliq — Soliq ro\'yxati va is_marking', () {
+    SoliqMxikModel soliq(String mxik) => SoliqMxikModel(
+          mxik: mxik,
+          mxikNameUz: '',
+          mxikNameRu: '',
+          mxikNameLat: '',
+          internationalCode: '',
+          usePackage: 0,
+          packages: const [],
+        );
+
+    // `product()` helper mxik/package bermaydi — putItems bo'sh maydonlarni
+    // org default bilan to'ldirmasligi uchun ikkalasi ham beriladi.
+    ItemModel withMxik(String id, String mxik, {bool? marking}) =>
+        product(id)
+          ..isMarking = marking
+          ..mxikCode = mxik
+          ..packageCode = '1';
+
+    test('faqat NULL bayroq to\'ldiriladi; adminka false\'i DAXLSIZ',
+        () async {
+      const inList = '02203001001000000';
+      await HiveBoxes.markingProductsBox().clear();
+      await HiveBoxes.markingProductsBox().put(inList, soliq(inList));
+
+      await ItemsSingleton.putItems([
+        withMxik('pNull', inList, marking: null),
+        withMxik('pFalse', inList, marking: false),
+        withMxik('pTrue', inList, marking: true),
+        withMxik('pOther', '01704001016000000', marking: null),
+      ]);
+
+      await OrdersService().updateMarkingStatusFromSoliq(fromLocal: true);
+
+      final box = HiveBoxes.getProducts();
+      // Bayroq kelmagan + MXIK ro'yxatda → avto-true (eski foydali xulq).
+      expect(box.get('pNull')!.isMarking, isTrue);
+      // Adminka aniq false degan — ro'yxatda bo'lsa ham TEGILMAYDI
+      // (ilgari true qilinar va markirovka qaytib kelardi).
+      expect(box.get('pFalse')!.isMarking, isFalse);
+      expect(box.get('pTrue')!.isMarking, isTrue);
+      // Ro'yxatda yo'q MXIK — o'zgarmaydi.
+      expect(box.get('pOther')!.isMarking, isNull);
+    });
+  });
 }
```

InVan 1 da `product()` helper (isMarking: false bilan ItemModel yasaydi), `setUpPosTestEnv` va `HiveBoxNames.markingProducts` (`marking_products`, typeId 131, `SoliqMxikModel`) bo'lmasa — 5-band umumiy ko'rsatmaga qarang (hujjat boshi).

</details>

## 7. Tekshirish

- `flutter test` — **1365/1365 o'tdi** (2026-09-30); `flutter analyze` yangi issue qo'shmadi.
- Do'kon sinovi (reliz chiqqach): (a) adminkada `is_marking` true→false → kassada TO'LIQ YANGILASHSIZ 1-2 daqiqada barcode urilganda markirovka so'ramasligi; (b) shundan keyin Servis'da qo'lda yangilash → false SAQLANIB qolishi (qaytib true bo'lmasligi); (c) logda `SYNC_MARKING_CHANGED` qatori.

## 8. Eslatmalar va ochiq savollar

- Foydalanuvchi kuzatuvi "batch (bir nechta notification) kelsa qo'llanmayapti, bittasi kelsa qo'llanyapti" — **tasodif**: qo'llash har notification uchun alohida, batch hajmining ahamiyati yo'q. Farq lokal qiymatda edi (qayta urinish paytida kassa oradagi to'liq yuklashdan false olib bo'lgan).
- "False ishlab turib keyin yana so'rab qoldi" — sababi kod bo'yicha ISBOTLANMAGAN. `updateMarkingStatusFromSoliq` (2-diff) — haqiqiy yashirin xato va yopildi, lekin bu hodisaga aloqasi ehtimoldan uzoq: uning Soliq ro'yxati faqat hozir kommentdagi sozlama tugmasi orqali to'ldiriladi, hodisadagi mahsulot esa bo'sh `mxik_code` bilan kelgan. Qolgan nomzodlar server/ma'lumot tomonida (keyingi `is_marking: true` notification, to'liq katalogdagi qiymat, dublikat barcode'li kartochka) — do'kon sinovida aniqlanadi.
- Bo'sh `mxik_code` kelganda org default MXIK bilan to'ldirish (`addPackageCodeAndMxikCode`) ATAYLAB o'zgartirilmadi: to'liq yuklash ham xuddi shunday qiladi — ikkala yo'l izchil.

---

# 8-TASK — Shorebird code push: Dart tuzatishlari `.exe` siz, kassir bir ochilishda (1.1.2+128 / +129)

> **Commitlar:** `7db61a9`, `3154158` (CI — 1.1.2+128), `df6ef7c`, `919e601` (2026-09-30), `d16df8a` (2026-10-01), `40bc8c2`, `5112b2b` (2026-10-02). Reliz: CI va Shorebird relizi — 1.1.2+128; to'liq mantiq — **1.1.2+129** (`c4e42e1`).
> **Sessiya hujjati:** docs/sessions/2026-10-02-shorebird-mac-test.md; doimiy qoidalar: `docs/shorebird-qoidalari.md` (InVan 2 ichki hujjati).
> **Holat 2026-10-02:** Mac'da sinalgan (alohida sinov relizi `1.1.2+9128`, patch 1–5): bir ochilishda yangilanish, tugma, rollback, xato ekrani, ochilish vaqtlari. **Windows'da qayta yonish sinalmagan** — 1.1.2+129 dan keyingi birinchi prod patch bilan tekshiriladi.

## 1. Nima va nima uchun

Ilgari har Dart tuzatishi uchun yangi `.exe` (reliz → backendga yuklash → kassir drawer'dagi "Yangilanish"ni bosadi) kerak edi. Shorebird code push bilan Dart kodi o'zgarishi o'rnatilgan kassalarga **patch** sifatida yetadi; yangi reliz faqat native o'zgarishda (windows/, native plagin, Flutter versiyasi, assets, ObjectBox sxemasi) kerak.

Shorebird'ning odatiy xulqi: patch fonda yuklanadi va faqat **keyingi** ishga tushirishda qo'llanadi — kassir dasturni ikki marta yopib ochishi kerak. Bu task:

1. **Ochilishda bir martada:** `main()` boshida (oyna yashirin, bazalar ochilmagan) yangi patch bo'lsa yuklab, dastur o'zini qayta ishga tushiradi.
2. **Ish vaqtida:** davriy tekshiruv; patch tayyor bo'lsa yuqorida yashil **"Yangilanish tayyor"** tugmasi — faqat 6 ta savatning hammasi bo'sh bo'lganda (sotuv o'rtasida qayta yonmaslik uchun). Dastur hech qachon O'ZI qayta yonmaydi.
3. **Qayta yongandan keyin** "✓ Dastur yangilandi" xabari (oynaning bir zum yopilib-ochilishi xatoga o'xshamasin).
4. **Ishga tushish xato ekrani:** `main()` dagi bazalar/sozlamalar xato bersa (masalan ObjectBox sxemasi dastur versiyasiga mos emas — rollback yoki eski installer'dan keyin) ilgari Mac'da qora oyna, Windows'da (oyna startup'da yashirin) "ochilmaydigan" dastur qolardi. Endi sabab ikki tilda ko'rsatiladi.
5. **Windows runner:** dastur o'zini qayta ishga tushirganda yangi nusxa eski nusxa yopilishini kutadi ("bitta nusxa" tekshiruvi uni jim yopib qo'ymasin).

Tuzatilgan poyga (Mac sinovi, 2026-10-02): dastur ochilganda Shorebird'ning O'Z avtomatik yuklovchisi (`auto_update`) xuddi shu patch'ni parallel yuklaydi. Birinchi versiyada (`df6ef7c`) tekshiruv shu poygada birinchi muvaffaqiyatsiz chaqiruvdayoq to'xtardi — patch yuklanardi-yu, dastur qayta yonmasdi. Yana: Shorebird 3.41.3 dvigateli "Update already in progress" ni xato kodi bilan qaytaradi (`shorebird_code_push` 2.0.7 uni zararsiz deb kutadi).

## 2. Qanday ishlaydi

**Reliz va patch (CI):**
- `release.yml`: `flutter build windows` o'rniga `shorebird release windows --flutter-version=3.41.3` — build Shorebird'da reliz sifatida ro'yxatga olinadi; `.exe` (Inno Setup) avvalgidek.
- `patch.yml` (qo'lda, workflow_dispatch): `release_version` — **aniq** versiya (standart qiymat yo'q: `latest` boshqa platforma relizini tanlab qo'yishi mumkin), `track` — staging/beta/stable. Kassalar faqat `stable` ni o'qiydi. `--dart-define` qiymatlari `release.yml` bilan **bir xil** bo'lishi shart.

**Kassada — ochilishda (`PatchUpdater.applyOnStartup`, `main()` ning birinchi `await`i):**

```
INVAN_PATCH_RELAUNCHED=1 ?  → tekshiruvsiz (qayta yongan jarayon), odatdagidek ochiladi
byudjet 8 s ichida tsikl:
  1) lokal: readNextPatch != readCurrentPatch ? → QAYTA YONISH
  2) checkForUpdate (har chaqiruv ≤ 3 s):
       restartRequired → QAYTA YONISH
       outdated        → update() (avtomatik yuklovchi ishlayotgan bo'lsa darhol qaytadi), qayta so'rash
       upToDate        → 300 ms kutib lokal tekshiruv → ochiladi
       xato            → vaqt tugagan bo'lsa (tarmoq osilgan) darhol ochiladi; ketma-ket 2-xatoda ochiladi
QAYTA YONISH = Process.start(o'zi, env INVAN_PATCH_RELAUNCHED=1, detached) + exit(0)
```

O'lchov (Mac, patch 5): yangi patch bor — ~2 s yuklash, +3.2 s da yangi patch'da; patch yo'q — ~0.7 s; internet yo'q — ~0.3 s; Wi-Fi bor, internet "osilgan" — ~3 s. Sekin internetda 8 s ichida yuklanib ulgurmasa — odatdagidek ochiladi, yuklash fonda davom etadi.

**Kassada — ish vaqtida (`PatchUpdater.start`, `runApp` dan keyin):** 1 daqiqadan keyin, keyin har 10 daqiqada va `BackendHealth` `up` ga o'tganda (oflayn → onlayn) `_downloadIfAny` → patch diskda bo'lsa `readyToRestart = true` → `PatchRestartButton` (AppBar) 6 ta savatning hammasi bo'sh bo'lsa ko'rinadi → bosilsa `restartNow()`: `appClosedTime`/`isFirstTime` saqlanadi, `Hive.close()`, ObjectBox store'lari yopiladi, qayta yonish. Tugma bosilmasa — keyingi ochilishda baribir qo'llanadi.

**Xato ekrani:** `main()` dagi bazalar/sozlamalar `_initData()` ga ajratilgan; `try/catch` → `[STARTUP]` log + `runApp(StartupErrorApp(error))` + oynani ko'rsatish (`doWhenWindowReady`). Ekran Hive/Pref/tarjimaga bog'liq emas (ular ochilmagan bo'lishi mumkin). "Qayta ishga tushirish" yangi jarayonni `INVAN_RESTART=1` bilan ochadi va meros `INVAN_PATCH_RELAUNCHED` ni olib tashlaydi — yangi jarayon patch tekshiruvini (rollback'ni) o'tkazib yubormasin.

**Windows runner (`CheckOneInstance`):** ilgari ikkinchi nusxa darhol jim chiqardi. Endi `INVAN_PATCH_RELAUNCHED=1` yoki `INVAN_RESTART=1` bo'lsa 100 × 100 ms (10 s) eski nusxa yopilishini kutadi; kassir o'zi ochganda xulq o'zgarmagan.

## 3. O'zgarishlar ro'yxati

| Fayl | Tur | Nima |
|---|---|---|
| `shorebird.yaml` | YANGI | Shorebird `app_id` (InVan 1 o'zinikini oladi — `shorebird init`) |
| `.github/workflows/release.yml` | o'zgargan | `shorebird release windows --flutter-version=3.41.3`, git long paths |
| `.github/workflows/patch.yml` | YANGI | Qo'lda patch: aniq `release_version`, `track` |
| `pubspec.yaml` | o'zgargan | `shorebird_code_push: ^2.0.7` |
| `lib/changes/services/patch_updater.dart` | YANGI | Ochilishda bir martada qo'llash, fon tekshiruvi, qayta yonish |
| `lib/features/home/components/patch_restart_button.dart` | YANGI | "Yangilanish tayyor" tugmasi (6 savat bo'sh), "Dastur yangilandi" xabari |
| `lib/app/startup_error_app.dart` | YANGI | Ishga tushish xato ekrani |
| `lib/main.dart` | o'zgargan | `applyOnStartup` birinchi; `_initData()` + try/catch; `_showWindow()`; `PatchUpdater.start()`; xabar |
| `lib/features/home/home_page.dart` | o'zgargan | AppBar'ga `PatchRestartButton` |
| `windows/runner/win32_window.cpp` | o'zgargan | `CheckOneInstance`: o'zi qayta yonganda eski nusxani kutadi |
| `test/patch_updater_test.dart` | YANGI | "Update already in progress" filtri |
| `test/startup_error_app_test.dart` | YANGI | Xato ekrani matnlari, qayta ishga tushirish muhiti |

## 4. Bog'liqliklar (InVan 1 uchun)

- **Shorebird hisobi va O'Z `app_id`:** `shorebird init` — InVan 2 ning `app_id` sini KO'CHIRMANG (patch'lar InVan 2 kassalariga tushadi). CI uchun `SHOREBIRD_TOKEN` secret.
- **Flutter versiyasi** reliz va patch uchun bir xil (`--flutter-version`). Patch faqat o'sha `shorebird release` bilan chiqqan versiyaga tushadi.
- `BackendHealth` (2026-09-02 taski, bu hujjatdan tashqarida) — `PatchUpdater.start` dagi `_onConnectivityChanged`. Bo'lmasa: listener'ni olib tashlang (10 daqiqalik davr qoladi).
- `PatchReporter` — **12-TASK**. `patch_updater.dart` unga 6 joyda murojaat qiladi (`import`, `PatchReporter.start`, `PatchReporter.error`). 12-TASK ni qo'llamasangiz — shu qatorlarni olib tashlang.
- `restartNow()`: `Pref`, `PrefKeys.appClosedTime`, `PrefKeys.isFirstTime`, `MyObjectbox.saleStore/storee` — InVan 1 dagi nomlarga moslang (ma'no: dastur yopilgandagi kabi holatni saqlash, bazalarni yopish).
- `PatchRestartButton`: savatlar ro'yxati `OrderingProvider4.sixClient4List` + `currentClient` — InVan 1 dagi savat modeliga moslang; `AppNavigation.navigatorKey` (xabar uchun).
- `bitsdojo_window` (`appWindow`, `doWhenWindowReady`, `BDW_HIDE_ON_STARTUP`) — `main()` dagi `_showWindow()`.
- Windows runner'dagi `CheckOneInstance` — InVan 2 ning o'z qo'shimchasi (Flutter shablonida yo'q). InVan 1 da bo'lmasa — 6.10 kerak emas.

## 5. Qo'llash tartibi

1. `shorebird init` (o'z `app_id`), `pubspec.yaml` ga `shorebird_code_push: ^2.0.7` (6.4).
2. CI: `release.yml` ni `shorebird release windows` ga o'tkazing (6.2), `patch.yml` qo'shing (6.3). GitHub secrets: `SHOREBIRD_TOKEN` + mavjud `--dart-define` lar.
3. Yangi fayllar: `patch_updater.dart` (6.5), `patch_restart_button.dart` (6.6), `startup_error_app.dart` (6.7).
4. `main.dart` (6.8): `applyOnStartup()` — `WidgetsFlutterBinding.ensureInitialized()` dan keyin BIRINCHI `await`; bazalar `_initData()` ga, try/catch; oxirida `PatchUpdater.start()` va xabar.
5. `home_page.dart` AppBar `actions` ga `const PatchRestartButton()` (6.9).
6. Windows runner (6.10) — faqat `CheckOneInstance` bo'lsa.
7. Testlar (6.11), `flutter test`.
8. Birinchi `shorebird release windows` → kassalarga odatiy yo'l bilan; keyingi Dart tuzatishlari — `patch.yml`.

## 6. Kod

### 6.1. YANGI: `shorebird.yaml` (InVan 2 niki — `app_id` ni o'zingizniki bilan almashtiring)

```yaml
# This file is used to configure the Shorebird updater used by your app.
# Learn more at https://docs.shorebird.dev
# This file does not contain any sensitive information and should be checked into version control.

# Your app_id is the unique identifier assigned to your app.
# It is used to identify your app when requesting patches from Shorebird's servers.
# It is not a secret and can be shared publicly.
app_id: c36a12bc-72fe-4c53-8887-1c7a435f27d8

# auto_update controls if Shorebird should automatically update in the background on launch.
# If auto_update: false, you will need to use package:shorebird_code_push to trigger updates.
# https://pub.dev/packages/shorebird_code_push
# Uncomment the following line to disable automatic updates.
# auto_update: false
```

### 6.2. `.github/workflows/release.yml`

```diff
diff --git a/.github/workflows/release.yml b/.github/workflows/release.yml
index ab6774f..19deaa3 100644
--- a/.github/workflows/release.yml
+++ b/.github/workflows/release.yml
@@ -24,22 +24,26 @@ jobs:
           $line = (Select-String -Path pubspec.yaml -Pattern '^version:\s*(.+)$').Matches.Groups[1].Value.Trim()
           echo "full=$line" >> $env:GITHUB_OUTPUT
 
-      - name: Setup Flutter
-        uses: subosito/flutter-action@v2
+      # Shorebird o'z Flutter'i bilan build qiladi — versiya shu yerda qotiriladi.
+      # Patch'lar ham aynan shu Flutter bilan yasaladi (patch.yml).
+      # Shorebird Flutter checkout'ida yo'llar 260 belgidan uzun —
+      # Windows'da ruxsatsiz "Filename too long" bilan yiqiladi.
+      - name: Enable git long paths
+        run: git config --system core.longpaths true
+
+      - name: Setup Shorebird
+        uses: shorebirdtech/setup-shorebird@v1
         with:
-          channel: stable
-          flutter-version: '3.41.3'
           cache: true
 
-      - name: Flutter info
-        run: flutter --version
-
-      - name: Install dependencies
-        run: flutter pub get
-
-      - name: Build Windows release
+      # `flutter build windows` o'rniga: shu build Shorebird'da reliz sifatida
+      # ro'yxatga olinadi va keyin `shorebird patch windows` bilan yangilanadi.
+      # Chiqish papkasi o'sha: build\windows\x64\runner\Release (installer.iss).
+      - name: Shorebird release (Windows)
+        env:
+          SHOREBIRD_TOKEN: ${{ secrets.SHOREBIRD_TOKEN }}
         run: |
-          flutter build windows --release `
+          shorebird release windows --flutter-version=3.41.3 `
             --dart-define=TELEGRAM_BOT_TOKEN="${{ secrets.TELEGRAM_BOT_TOKEN }}" `
             --dart-define=TELEGRAM_CHANNEL_ID="${{ secrets.TELEGRAM_CHANNEL_ID }}" `
             --dart-define=FISCAL_API_TOKEN="${{ secrets.FISCAL_API_TOKEN }}"
```

### 6.3. YANGI: `.github/workflows/patch.yml`

```yaml
name: Shorebird Patch Windows

# Yangi .exe chiqarmasdan o'rnatilgan kassalarga Dart kod o'zgarishini
# yuboradi. Faqat `shorebird release windows` bilan chiqqan versiyaga
# tushadi (release.yml). Native o'zgarish (windows/runner, native plugin,
# Flutter versiyasi) bo'lsa — patch emas, yangi reliz kerak.
#
# Kassa patch'ni ochilishda (bir martada) yoki ish vaqtida fonda yuklaydi
# (PatchUpdater). Kassalar FAQAT stable kanalni o'qiydi — staging/beta
# patch'i kassaga tushmaydi, uni faqat `shorebird preview --track staging`
# bilan Windows kompyuterda sinash mumkin.

on:
  workflow_dispatch:
    inputs:
      # Standart qiymat YO'Q — har safar aniq yoziladi. `latest` Shorebird'da
      # "eng oxirgi yangilangan reliz" degani: u Windows'niki bo'lmasligi
      # mumkin (masalan Mac sinov relizi 1.1.2+9128, 2026-10-02).
      release_version:
        description: 'Patch qilinadigan Windows reliz versiyasi (pubspec version, masalan 1.1.2+128)'
        required: true
        default: ''
      track:
        description: 'Kanal'
        required: true
        default: 'stable'
        type: choice
        options:
          - staging
          - beta
          - stable

jobs:
  patch-windows:
    runs-on: windows-2022

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      # Shorebird Flutter checkout'ida yo'llar 260 belgidan uzun —
      # Windows'da ruxsatsiz "Filename too long" bilan yiqiladi.
      - name: Enable git long paths
        run: git config --system core.longpaths true

      - name: Setup Shorebird
        uses: shorebirdtech/setup-shorebird@v1
        with:
          cache: true

      # Flutter versiyasi reliz qilingani bilan bir xil bo'lishi SHART.
      - name: Shorebird patch (Windows)
        env:
          SHOREBIRD_TOKEN: ${{ secrets.SHOREBIRD_TOKEN }}
        run: |
          shorebird patch windows `
            --release-version="${{ inputs.release_version }}" `
            --track=${{ inputs.track }} `
            --dart-define=TELEGRAM_BOT_TOKEN="${{ secrets.TELEGRAM_BOT_TOKEN }}" `
            --dart-define=TELEGRAM_CHANNEL_ID="${{ secrets.TELEGRAM_CHANNEL_ID }}" `
            --dart-define=FISCAL_API_TOKEN="${{ secrets.FISCAL_API_TOKEN }}"
```

### 6.4. `pubspec.yaml`

```yaml
dependencies:
  # ...
  shorebird_code_push: ^2.0.7
```

### 6.5. YANGI: `lib/changes/services/patch_updater.dart`

```dart
/*
    Shorebird patch'larini BITTA ochilishda qo'llash.

    Nima uchun kerak: Shorebird o'zi patch'ni fonda yuklaydi va faqat KEYINGI
    ishga tushirishda qo'llaydi — kassir dasturni ikki marta yopib ochishi
    kerak bo'lardi. Bu servis:

    1. `applyOnStartup` — main() boshida, oyna ko'rinmasidan va bazalar
       ochilmasidan OLDIN: yangi patch (yoki rollback) bo'lsa yuklab oladi va
       dasturni darhol qayta ishga tushiradi. Vaqt chegaralangan — internet
       yo'q/sekin bo'lsa dastur odatdagidek ochiladi.
    2. `start` — ish vaqtida davriy tekshiradi, internet (server) qaytgan
       zahoti ham — startup'da oflayn bo'lib o'tkazib yuborilgan patch shu
       yerda ushlanadi. Patch tayyor bo'lsa dastur
       O'ZI qayta yonmaydi (sotuv o'rtasida xavfli) — `readyToRestart` orqali
       yuqorida tugma chiqadi, kassir savat bo'shligida bosadi.

    Debug yoki `shorebird release` siz build'da `isAvailable == false` —
    hech narsa qilmaydi.
*/

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:invan2/changes/services/health/backend_health.dart';
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/changes/services/patch_reporter.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class PatchUpdater {
  PatchUpdater._();

  static final ShorebirdUpdater _updater = ShorebirdUpdater();

  /// Ish vaqtida patch yuklab bo'lindi — qayta ishga tushirish tugmasi.
  static final ValueNotifier<bool> readyToRestart = ValueNotifier<bool>(false);

  /// Startup'da kutishning yuqori chegarasi. Oyna shu vaqt ko'rinmaydi
  /// (BDW_HIDE_ON_STARTUP), shuning uchun qisqa bo'lishi shart.
  static const Duration _startupBudget = Duration(seconds: 8);

  /// Startup'dagi bitta server tekshiruvining chegarasi. Odatda ~0.4 s;
  /// shundan uzoq — tarmoq osilgan (Wi-Fi bor, internet yo'q).
  static const Duration _checkCap = Duration(seconds: 3);
  static const Duration _interval = Duration(minutes: 10);

  static Timer? _timer;
  static bool _busy = false;
  static bool _restarting = false;

  /// Qayta ishga tushirilgan jarayonga beriladi — u startup tekshiruvini
  /// takrorlamaydi (patch "kutilmoqda" bo'lib qolsa cheksiz qayta yonish va
  /// har safar 8 s yashirin oyna bo'lmasin).
  static const String relaunchedEnv = 'INVAN_PATCH_RELAUNCHED';

  /// Shu jarayon yangilanish uchun O'ZI qayta ishga tushirilganmi (startup'da
  /// patch qo'llanganda yoki "Yangilanish tayyor" tugmasi bosilganda) —
  /// kassirga "Dastur yangilandi" deb aytish uchun.
  static bool get relaunchedForUpdate =>
      Platform.environment[relaunchedEnv] == '1';

  /// main() boshida chaqiriladi. Patch tayyor bo'lsa QAYTMAYDI (jarayon
  /// yangisi bilan almashadi).
  ///
  /// Muhim: dastur ochilganda Shorebird'ning O'Z avtomatik yuklovchisi ham
  /// (shorebird.yaml `auto_update`) xuddi shu patch'ni parallel yuklaydi.
  /// Ilgari bu poyga paytida tekshiruv tsikli birinchi muvaffaqiyatsiz
  /// chaqiruvdayoq to'xtardi — patch yuklanardi-yu, dastur qayta yonmasdi
  /// (Mac sinovi, 2026-10-02: kassir ikki marta ochishi yoki tugmani bosishi
  /// kerak bo'lardi). Endi tsikl vaqt chegarasigacha davom etadi, har bir
  /// chaqiruv xatosi qayta urinish bilan o'tkaziladi va diskdagi tayyor patch
  /// tarmoqsiz aniqlanadi.
  static Future<void> applyOnStartup() async {
    if (!_updater.isAvailable) {
      _log('startup: Shorebird updater mavjud emas');
      return;
    }
    if (Platform.environment[relaunchedEnv] == '1') {
      _log('startup: qayta ishga tushirilgan jarayon — tekshiruv yo\'q, '
          'boot patch=${await _bootPatchText()}');
      return;
    }
    final Stopwatch sw = Stopwatch()..start();
    _busy = true;
    try {
      _log('startup: boshlandi, boot patch=${await _bootPatchText()}');
      final bool ready = await _waitForPatchOnStartup(sw);
      _log('startup: ${ready ? "patch tayyor — QAYTA ISHGA TUSHIRILADI" : "yangi patch yo'q"} '
          '(${sw.elapsedMilliseconds} ms)');
      if (ready) await _relaunch();
    } catch (e) {
      // Kutilmagan xato — dastur odatdagidek ochiladi, fon tekshiruvi
      // keyinroq qayta urinadi.
      _log('startup: xato $e (${sw.elapsedMilliseconds} ms)');
      PatchReporter.error('startup', e);
    } finally {
      _busy = false;
    }
  }

  /// Startup byudjeti ichida patch'ni kutadi. `true` — patch diskda,
  /// qayta ishga tushirish kerak.
  static Future<bool> _waitForPatchOnStartup(Stopwatch sw) async {
    int errorsInARow = 0;
    while (sw.elapsed < _startupBudget) {
      // 1) Tarmoqsiz: avtomatik yuklovchi patch'ni allaqachon diskka
      //    yozib bo'lganmi.
      if (await _restartNeededLocally()) return true;

      // 2) Server bilan. Har tekshiruv [_checkCap] bilan cheklanadi: Wi-Fi
      //    bor-u internet "osilgan" bo'lsa so'rov javobsiz qoladi — startup
      //    byudjet oxirigacha kutmasin.
      final Duration left = _startupBudget - sw.elapsed;
      final Duration cap = left < _checkCap ? left : _checkCap;
      final Stopwatch call = Stopwatch()..start();
      final UpdateStatus? status = await _safeCheck(timeout: cap);
      _log('startup: holat=${status?.name ?? "xato"} '
          '(${sw.elapsedMilliseconds} ms)');
      switch (status) {
        case UpdateStatus.restartRequired:
          return true;
        case UpdateStatus.unavailable:
          return false;
        case UpdateStatus.outdated:
          errorsInARow = 0;
          // Avtomatik yuklovchi ishlayotgan bo'lsa darhol qaytadi.
          await _safeUpdate(timeout: _startupBudget - sw.elapsed);
          break;
        case UpdateStatus.upToDate:
          // Yangi patch yo'q (internet yo'q bo'lsa ham Shorebird shunday
          // deydi). Avtomatik yuklovchi patch'ni hozirgina diskka yozgan
          // bo'lishi mumkin — ikkinchi TARMOQ so'rovi o'rniga qisqa lokal
          // tekshiruv (oddiy ochilish ~0.8 s tezroq).
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return await _restartNeededLocally();
        case null:
          // Vaqt tugadi — tarmoq osilgan: qayta urinish ma'nosiz.
          if (call.elapsed >= cap) return await _restartNeededLocally();
          // Chaqiruv xatosi. Bittasi — avtomatik yuklovchi bilan poyga
          // bo'lishi mumkin, qayta urinamiz. Ketma-ket ikkinchisi — kutish
          // ma'nosiz, kassa darhol ochilsin.
          if (++errorsInARow >= 2) return await _restartNeededLocally();
          break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return await _restartNeededLocally();
  }

  /// Diskdagi keyingi patch joriysidan farq qiladimi (yangi patch yuklangan
  /// yoki joriy patch bekor qilingan). Tarmoqqa chiqmaydi.
  static Future<bool> _restartNeededLocally() async {
    try {
      final Patch? current = await _updater.readCurrentPatch();
      final Patch? next = await _updater.readNextPatch();
      return current?.number != next?.number;
    } catch (e) {
      _log('lokal patch holatini o\'qib bo\'lmadi: $e');
      PatchReporter.error('readPatch', e);
      return false;
    }
  }

  /// [timeout] — startup byudjetidan qolgan vaqt (fon tekshiruvida yo'q).
  /// Vaqt tugasa xato deb hisoblanadi.
  static Future<UpdateStatus?> _safeCheck({Duration? timeout}) async {
    try {
      final Future<UpdateStatus> check = _updater.checkForUpdate();
      return timeout == null ? await check : await check.timeout(timeout);
    } catch (e) {
      _log('checkForUpdate xatosi: $e');
      // Startup'dagi xato odatda avtomatik yuklovchi bilan poyga — kanalga
      // faqat fon tekshiruvidagisi.
      if (_timer != null) PatchReporter.error('checkForUpdate', e);
      return null;
    }
  }

  static Future<void> _safeUpdate({Duration? timeout}) async {
    try {
      final Future<void> update = _updater.update();
      await (timeout == null ? update : update.timeout(timeout));
    } catch (e) {
      _log('update xatosi: $e');
      // Avtomatik yuklovchi shu patch'ni yuklayapti — kutilgan poyga, xato
      // emas: kanalga yuborilmaydi.
      if (!isUpdateInProgress(e)) PatchReporter.error('update', e);
    }
  }

  /// Shorebird'ning o'z yuklovchisi ishlayotgan paytdagi `update()` javobi.
  /// shorebird_code_push 2.0.7 buni zararsiz deb qaytarishi kerak edi, lekin
  /// Flutter 3.41.3 dvigateli uni umumiy xato kodi bilan beradi:
  /// `UpdateException: Update already in progress (unknown)` (Mac, 2026-10-02).
  @visibleForTesting
  static bool isUpdateInProgress(Object error) =>
      error is UpdateException &&
      error.message.toLowerCase().contains('already in progress');

  static Future<String> _bootPatchText() async {
    try {
      final Patch? current = await _updater.readCurrentPatch();
      final Patch? next = await _updater.readNextPatch();
      return '${current?.number ?? "-"} (keyingi: ${next?.number ?? "-"})';
    } catch (_) {
      return '?';
    }
  }

  static void _log(String message) {
    // Konsolga ham — dasturni terminaldan ishga tushirib kuzatish uchun
    // (macOS'da Documents'dagi log faylini boshqa dastur o'qiy olmaydi).
    debugPrint('[PATCH] $message');
    unawaited(LogHelper.write(LogLevel.info, '[PATCH] $message'));
  }

  /// runApp() dan keyin — fon tekshiruvini boshlaydi.
  static void start() {
    if (!_updater.isAvailable || _timer != null) return;
    _timer = Timer.periodic(_interval, (_) => _checkInBackground());
    Timer(const Duration(minutes: 1), _checkInBackground);
    BackendHealth.status.addListener(_onConnectivityChanged);
    PatchReporter.start(_updater);
  }

  /// Oflayn → onlayn: 10 daqiqalik davrni kutmasdan darhol tekshiradi.
  static void _onConnectivityChanged() {
    if (BackendHealth.status.value == BackendStatus.up) _checkInBackground();
  }

  /// Kassir tugmani bosganda (savat bo'sh bo'lishi kerak — chaqiruvchi
  /// tekshiradi). Oyna yopilgandagi kabi holat saqlanadi, keyin qayta yonadi.
  static Future<void> restartNow() async {
    // Ikki marta bosilsa ikkita POS jarayoni bitta bazani ochmasin.
    if (_restarting) return;
    _restarting = true;
    readyToRestart.value = false; // tugma darhol yo'qoladi
    try {
      await Pref.setString(PrefKeys.appClosedTime,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()));
      await Pref.setBool(PrefKeys.isFirstTime, true);
      await Hive.close();
    } catch (_) {
      // Saqlash xatosi qayta ishga tushirishni to'xtatmasin.
    }
    // Cheklar bazasi (ObjectBox) yangi jarayon ochishidan OLDIN yopiladi.
    for (final void Function() close in <void Function()>[
      () => MyObjectbox.saleStore.close(),
      () => MyObjectbox.storee.close(),
    ]) {
      try {
        close();
      } catch (_) {
        // Ochilmagan (late) yoki allaqachon yopilgan — e'tiborsiz.
      }
    }
    await _relaunch();
  }

  static Future<void> _checkInBackground() async {
    if (_busy || readyToRestart.value) return;
    _busy = true;
    try {
      if (await _downloadIfAny()) {
        _log('fon: patch tayyor — "Yangilanish tayyor" tugmasi ko\'rsatiladi');
        readyToRestart.value = true;
      }
    } catch (e) {
      // Keyingi davrda qayta uriniladi.
      _log('fon: xato $e');
      PatchReporter.error('fon tekshiruvi', e);
    } finally {
      _busy = false;
    }
  }

  /// `true` — yangi patch diskda (yoki joriy patch rollback qilingan) va
  /// qayta ishga tushirish kerak.
  ///
  /// Shorebird'ning avtomatik yuklovchisi ishga tushganda parallel ishlaydi;
  /// u holda `update()` darhol qaytadi (UPDATE_IN_PROGRESS), shuning uchun
  /// holat `outdated` dan chiqquncha qayta so'raladi.
  static Future<bool> _downloadIfAny() async {
    if (await _restartNeededLocally()) return true;
    // ~40 × 0.7 s — avtomatik yuklovchi osilib qolsa ham cheksiz aylanmaydi.
    for (int attempt = 0; attempt < 40; attempt++) {
      final UpdateStatus? status = await _safeCheck();
      switch (status) {
        case UpdateStatus.restartRequired:
          return true;
        case UpdateStatus.upToDate:
        case UpdateStatus.unavailable:
          return false;
        case UpdateStatus.outdated:
          if (attempt == 0) _log('fon: yangi patch topildi — yuklanmoqda');
          await _safeUpdate();
          break;
        case null:
          // Chaqiruv xatosi — qayta urinamiz.
          break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
    return await _restartNeededLocally();
  }

  static Future<void> _relaunch() async {
    // Jarayon darhol tugaydi — log diskka yozilishini kutamiz.
    await LogHelper.write(LogLevel.info,
        '[PATCH] qayta ishga tushirilmoqda, boot patch=${await _bootPatchText()}');
    await Process.start(
      Platform.resolvedExecutable,
      const <String>[],
      mode: ProcessStartMode.detached,
      workingDirectory: File(Platform.resolvedExecutable).parent.path,
      environment: const <String, String>{relaunchedEnv: '1'},
    );
    exit(0);
  }
}
```

### 6.6. YANGI: `lib/features/home/components/patch_restart_button.dart`

```dart
/*
    "Yangilanish tayyor" tugmasi — ish vaqtida Shorebird patch yuklangach
    (PatchUpdater.readyToRestart) yuqori panelda chiqadi.

    Dastur o'zi qayta yonmaydi: sotuv o'rtasida bu savatni yo'qotadi. Tugma
    faqat 6 ta mijoz savatining HAMMASI bo'sh bo'lganda ko'rinadi — bittasida
    ham mahsulot tursa yashirin, bo'shagan zahoti (OrderingProvider4
    notifyListeners) paydo bo'ladi.
*/

import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/changes/services/patch_updater.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';

/// Dastur yangilanish uchun o'zi qayta ochilgandan keyin birinchi ekranda
/// "Dastur yangilandi" xabari — oynaning bir zum yopilib-ochilishi kassirga
/// xato kabi ko'rinmasligi uchun.
///
/// runApp() dan keyin chaqiriladi. Birinchi sahifa chizilguncha bir necha
/// marta urinadi; `mySnackBar` ishlatilmaydi — u SizeConfig'ga bog'liq,
/// ilova endigina ochilganda u hali sozlanmagan bo'lishi mumkin.
void showPatchUpdatedMessage() {
  int attempts = 0;

  void tryShow() {
    attempts++;
    final BuildContext? context = AppNavigation.navigatorKey.currentContext;
    final ScaffoldMessengerState? messenger =
        context == null ? null : ScaffoldMessenger.maybeOf(context);
    if (context == null || messenger == null) {
      if (attempts < 10) {
        Future<void>.delayed(const Duration(seconds: 1), tryShow);
      }
      return;
    }
    final AppLocalizations? loc = AppLocalizations.of(context);
    final bool isUz = loc == null || loc.ha.toLowerCase() == 'ha';
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      width: 420,
      backgroundColor: const Color(0xFF2E7D32),
      duration: const Duration(seconds: 4),
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isUz ? 'Dastur yangilandi' : 'Программа обновлена',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    ));
  }

  // Oyna ko'rinishi va birinchi sahifa chizilishi uchun biroz kutamiz.
  Future<void>.delayed(const Duration(seconds: 2), tryShow);
}

class PatchRestartButton extends StatelessWidget {
  const PatchRestartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PatchUpdater.readyToRestart,
      builder: (context, ready, _) {
        if (!ready) return const SizedBox.shrink();

        return Consumer<OrderingProvider4>(
          builder: (context, ordering, _) {
            final bool allCartsEmpty =
                ordering.getCurrentClient.orderedProducts.isEmpty &&
                    ordering.getSixClient4List
                        .every((c) => c.orderedProducts.isEmpty);
            if (!allCartsEmpty) return const SizedBox.shrink();

            final AppLocalizations? loc = AppLocalizations.of(context);
            final bool isUz = loc == null || loc.ha.toLowerCase() == 'ha';
            const Color green = Color(0xFF2E7D32);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 0.6),
              child: OutlinedButton.icon(
                focusNode: FocusNode(skipTraversal: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: green,
                  side: const BorderSide(color: green),
                  backgroundColor: const Color(0xFFE8F5E9),
                ),
                onPressed: PatchUpdater.restartNow,
                icon: Icon(Icons.system_update_alt,
                    size: SizeConfig.v * 2.4, color: green),
                label: Text(
                  isUz
                      ? 'Yangilanish tayyor — qayta ishga tushirish'
                      : 'Обновление готово — перезапустить',
                  style: MyThemes.txtStyle(fontSize: 1.8, color: green),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
```

### 6.7. YANGI: `lib/app/startup_error_app.dart`

```dart
/*
    Dastur ishga tushmasa — sabab ko'rsatiladigan ekran.

    main() runApp'gacha bazalar va sozlamalarni tayyorlaydi. Shu qadamlardan
    biri xato bersa, ilgari dastur birinchi ekranni umuman chizmasdi: Mac'da
    qora oyna qolardi, Windows'da esa oyna startup'da yashirin bo'lgani uchun
    dastur "ochilmasdi" — kassir sababini bilmasdi.

    Qachon bo'ladi (misollar):
    - cheklar bazasi (ObjectBox) dastur versiyasiga mos emas: dastur eski
      versiyaga qaytarilgan (patch rollback, eski installer) yoki shu
      kompyuterda boshqa InVan dasturi bazani o'z sxemasiga yangilagan
      (Mac sinovi, 2026-10-02: "DB's last property ID 61 is higher than the
      incoming one 50 in entity ReceiptModel4");
    - baza fayli buzilgan (kompyuter to'satdan o'chgan), disk to'la;
    - Hive fayli boshqa nusxa tomonidan band (dastur ikki marta ochilgan).

    Bu ekran Hive/Pref/tarjimaga BOG'LIQ EMAS (ular ochilmagan bo'lishi
    mumkin) — matn ikki tilda.
*/

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:invan2/changes/services/patch_updater.dart';

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  /// Cheklar bazasi sxemasi dastur versiyasiga mos emasmi.
  bool get _isDbSchemaMismatch {
    final String text = '$error';
    return text.contains('last property ID') ||
        text.contains('last entity ID') ||
        text.contains('last index ID') ||
        text.contains('last relation ID');
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFF111A22);
    const Color red = Color(0xFFE53935);
    const TextStyle title =
        TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold);
    const TextStyle body = TextStyle(color: Colors.white70, fontSize: 17, height: 1.4);

    final String uz = _isDbSchemaMismatch
        ? 'Kassadagi ma\'lumotlar bazasi dasturning bu versiyasiga mos emas. '
            'Odatda dastur eski versiyaga qaytarilganda yoki shu kompyuterda '
            'boshqa InVan dasturi ishlatilganda bo\'ladi.\n'
            'Cheklar o\'chirilmagan — ular bazada saqlanib turibdi. '
            'Administratorga murojaat qiling.'
        : 'Dasturni ishga tushirishda xato yuz berdi. Qayta ishga tushirib '
            'ko\'ring. Takrorlansa — administratorga murojaat qiling va '
            'pastdagi matnni yuboring.';
    final String ru = _isDbSchemaMismatch
        ? 'База данных кассы не подходит к этой версии программы. Обычно это '
            'бывает, когда программу откатили на старую версию или на этом '
            'компьютере использовалась другая программа InVan.\n'
            'Чеки не удалены — они сохранены в базе. Обратитесь к '
            'администратору.'
        : 'При запуске программы произошла ошибка. Попробуйте перезапустить. '
            'Если повторится — обратитесь к администратору и отправьте текст '
            'ниже.';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: bg,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: red, size: 56),
                  const SizedBox(height: 16),
                  const Text('Dastur ishga tushmadi', style: title),
                  const SizedBox(height: 8),
                  Text(uz, style: body),
                  const SizedBox(height: 24),
                  const Text('Программа не запустилась', style: title),
                  const SizedBox(height: 8),
                  Text(ru, style: body),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      '$error',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13, height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _restart,
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                            'Qayta ishga tushirish / Перезапустить'),
                      ),
                      OutlinedButton(
                        onPressed: () => exit(0),
                        child: const Text('Yopish / Закрыть',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Dasturni qayta ochadi. Startup'dagi patch tekshiruvi ATAYLAB
  /// o'tkazib yuborilmaydi: muammoni tuzatuvchi patch chiqqan bo'lsa,
  /// qayta ochilishda u qo'llanadi.
  static Future<void> _restart() async {
    try {
      await Process.start(
        Platform.resolvedExecutable,
        const <String>[],
        mode: ProcessStartMode.detached,
        workingDirectory: File(Platform.resolvedExecutable).parent.path,
        environment: restartEnvironment(Platform.environment),
        includeParentEnvironment: false,
      );
    } catch (_) {
      // Ochib bo'lmasa ham joriy jarayon yopiladi — kassir qo'lda ochadi.
    }
    exit(0);
  }

  /// Windows runner (`windows/runner/win32_window.cpp` `CheckOneInstance`)
  /// shu belgini ko'rsa eski nusxa yopilishini kutadi — aks holda yangi
  /// nusxa "ikkinchi nusxa" deb jim yopilib qolishi mumkin.
  static const String restartEnv = 'INVAN_RESTART';

  /// Yangi jarayon muhiti. Joriy jarayon patch uchun o'zi qayta yongan
  /// bo'lsa (masalan yangi patch bazani ochmadi), uning yangilanish belgisi
  /// meros bo'lib o'tmasin: aks holda yangi jarayon patch tekshiruvini
  /// o'tkazib yuborardi (rollback'ni ushlamasdi) va "Dastur yangilandi"
  /// derdi.
  @visibleForTesting
  static Map<String, String> restartEnvironment(Map<String, String> current) =>
      Map<String, String>.of(current)
        ..remove(PatchUpdater.relaunchedEnv)
        ..[restartEnv] = '1';
}
```

### 6.8. `lib/main.dart`

```diff
diff --git a/lib/main.dart b/lib/main.dart
index a2e8fe3..8ab42d5 100644
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -36,7 +36,11 @@ import 'package:provider/provider.dart';
 import 'package:google_fonts/google_fonts.dart';
 import 'package:window_manager/window_manager.dart';
 import 'changes/dialogs/creat_product/model/mes_vat_unit_model/mes_unit.dart';
+import 'app/startup_error_app.dart';
+import 'changes/services/log_helper.dart';
 import 'changes/services/log_service.dart';
+import 'changes/services/patch_updater.dart';
+import 'features/home/components/patch_restart_button.dart';
 import 'features/home/bloc/home_bloc/home_bloc.dart';
 
 class MyWindowListener extends WindowListener {
@@ -64,6 +68,9 @@ class MyHttpOverrides extends HttpOverrides {
 
 Future<void> main() async {
   WidgetsFlutterBinding.ensureInitialized();
+  // Yangi Shorebird patch bo'lsa — hech narsa ochilmasdan yuklab, dasturni
+  // qayta ishga tushiradi (kassir bir marta ochadi, ikki emas).
+  await PatchUpdater.applyOnStartup();
   PackageInfo.fromPlatform();
   HttpOverrides.global = MyHttpOverrides();
   GoogleFonts.config.allowRuntimeFetching = true;
@@ -80,6 +87,49 @@ Future<void> main() async {
 
   await windowManager.ensureInitialized();
   windowManager.addListener(MyWindowListener());
+
+  // Bazalar va sozlamalar. Biror qadam xato bersa, ilgari dastur birinchi
+  // ekranni umuman chizmasdi: Mac'da qora oyna, Windows'da (oyna startup'da
+  // yashirin) dastur "ochilmasdi". Endi sabab ko'rsatiladi.
+  try {
+    await _initData();
+  } catch (e, st) {
+    await LogHelper.write(
+        LogLevel.error, '[STARTUP] dastur ishga tushmadi: $e\n$st');
+    runApp(StartupErrorApp(error: e));
+    _showWindow();
+    return;
+  }
+
+  runApp(
+    MultiProvider(
+      providers: [
+        BlocProvider(create: (context) => HomeBloc()),
+        BlocProvider(create: (context) => InvoiceBloc()),
+      ],
+      child: const App(),
+    ),
+  );
+  _showWindow();
+
+  OfdConfigMigrator.migrateIfNeeded();
+  PatchUpdater.start();
+  // Yangilanish uchun o'zi qayta ochilgan bo'lsa — kassirga aytamiz
+  // (aks holda oynaning bir zum yopilib-ochilishi xatoga o'xshaydi).
+  if (PatchUpdater.relaunchedForUpdate) showPatchUpdatedMessage();
+}
+
+void _showWindow() {
+  doWhenWindowReady(() async {
+    final win = appWindow;
+    win.maximize();
+    win.title = "InVan 2";
+    win.show();
+  });
+}
+
+/// runApp'gacha tayyorlanadigan bazalar va sozlamalar.
+Future<void> _initData() async {
   // await Prefs.init();
   await MyObjectbox.init();
   await _hiveInit();
@@ -126,24 +176,6 @@ Future<void> main() async {
   CategorySingleton.init();
   await OrganizationSingleton.setOtherPayments();
   await SettingsInnerSingleton().intiDeviceData();
-
-  runApp(
-    MultiProvider(
-      providers: [
-        BlocProvider(create: (context) => HomeBloc()),
-        BlocProvider(create: (context) => InvoiceBloc()),
-      ],
-      child: const App(),
-    ),
-  );
-  doWhenWindowReady(() async {
-    final win = appWindow;
-    win.maximize();
-    win.title = "InVan 2";
-    win.show();
-  });
-
-  OfdConfigMigrator.migrateIfNeeded();
 }
 
 Future<void> hiveClose() async {
```

### 6.9. `lib/features/home/home_page.dart` (faqat tugma; shu fayldagi `cancelOrdering` o'zgarishi — 10-TASK)

```diff
diff --git a/lib/features/home/home_page.dart b/lib/features/home/home_page.dart
index f7600f4..549b884 100644
--- a/lib/features/home/home_page.dart
+++ b/lib/features/home/home_page.dart
@@ -12,6 +12,7 @@ import 'package:invan2/features/home/bloc/home_bloc/home_bloc.dart';
 import 'package:invan2/features/home/bloc/invoice/invoice_bloc.dart';
 import 'package:invan2/features/home/build_content.dart';
 import 'package:invan2/features/home/components/offline_mode_badge.dart';
+import 'package:invan2/features/home/components/patch_restart_button.dart';
 import 'package:invan2/features/home/components/sync_button_home.dart';
 import 'package:invan2/features/home/features/home_products/shift_opened/top_buttons/search_buttons.dart';
 import 'package:invan2/features/home/features/home_orders/clients_part/clients_part.dart';
@@ -138,6 +139,8 @@ class HomePageState extends State<HomePage> with WidgetsBindingObserver {
               actions: [
                 // Server javob bermayotgan bo'lsa kassir buni ko'rib tursin.
                 const OfflineModeBadge(),
+                // Ish vaqtida yuklangan Shorebird patch — savat bo'sh bo'lsa qayta ishga tushirish.
+                const PatchRestartButton(),
                 Consumer<SettingsProvider>(
                   builder: (context, settings, _) => settings.showInvoiceButton
                       ? TextButton(
```

### 6.10. `windows/runner/win32_window.cpp`

```diff
diff --git a/windows/runner/win32_window.cpp b/windows/runner/win32_window.cpp
index 2ac3a35..0ccea04 100644
--- a/windows/runner/win32_window.cpp
+++ b/windows/runner/win32_window.cpp
@@ -102,28 +102,50 @@ Win32Window::~Win32Window() {
   Destroy();
 }
 
+// Jarayonni dasturning O'ZI qayta ishga tushirganmi: Shorebird patch
+// qo'llangach (PatchUpdater startup'i yoki "Yangilanish tayyor" tugmasi -
+// INVAN_PATCH_RELAUNCHED=1) yoki ishga tushish xato ekranidagi "Qayta ishga
+// tushirish" (INVAN_RESTART=1). Bunda eski nusxa hali yopilayotgan bo'ladi.
+static bool IsSelfRestart() {
+    const wchar_t* names[] = {L"INVAN_PATCH_RELAUNCHED", L"INVAN_RESTART"};
+    for (const wchar_t* name : names) {
+        wchar_t value[8];
+        if (GetEnvironmentVariableW(name, value, 8) == 1u && value[0] == L'1') {
+            return true;
+        }
+    }
+    return false;
+}
+
+// Dastur bitta nusxada ishlaydi: ikkinchi nusxa oyna ochmasdan chiqadi.
+// O'zi qayta yongan jarayon esa eski nusxa yopilishini 10 s gacha kutadi:
+// eski nusxa Process.start dan keyin exit(0) qiladi va yangi nusxa undan
+// oldin shu tekshiruvga yetsa, "ikkinchi nusxa" deb jim yopilib qolardi -
+// kassir dasturni qo'lda qayta ochishi kerak bo'lardi.
 bool CheckOneInstance()
 {
+    const int attempts = IsSelfRestart() ? 100 : 1;  // 100 x 100 ms
 
-    HANDLE  m_hStartEvent = CreateEventW( NULL, FALSE, FALSE, L"Global\\yourpackage" );
-
-    if(m_hStartEvent == NULL)
-    {
-        CloseHandle( m_hStartEvent );
-        return false;
-    }
+    for (int i = 0; i < attempts; ++i) {
+        HANDLE m_hStartEvent = CreateEventW( NULL, FALSE, FALSE, L"Global\\yourpackage" );
 
+        if (m_hStartEvent == NULL) {
+            return false;
+        }
 
-    if (GetLastError() == ERROR_ALREADY_EXISTS) {
+        if (GetLastError() != ERROR_ALREADY_EXISTS) {
+            // the only instance, start in a usual way (handle jarayon
+            // yopilguncha ochiq qoladi - boshqa nusxalar shuni ko'radi)
+            return true;
+        }
 
-        CloseHandle( m_hStartEvent );
-        m_hStartEvent = NULL;
         // already exist
-        // send message from here to existing copy of the application
-        return false;
+        CloseHandle( m_hStartEvent );
+        if (i + 1 < attempts) {
+            Sleep(100);
+        }
     }
-    // the only instance, start in a usual way
-    return true;
+    return false;
 }
 
 bool Win32Window::CreateAndShow(const std::wstring& title,
```

### 6.11. Testlar

<details><summary>YANGI: <code>test/patch_updater_test.dart</code></summary>

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/patch_updater.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() {
  group('PatchUpdater.isUpdateInProgress', () {
    test('avtomatik yuklovchi bilan poyga — xato emas (kanalga yuborilmaydi)',
        () {
      // Mac sinovidagi aynan shu xabar (Flutter 3.41.3 dvigateli).
      const UpdateException error = UpdateException(
        message: 'Update already in progress',
        reason: UpdateFailureReason.unknown,
      );
      expect(PatchUpdater.isUpdateInProgress(error), isTrue);
    });

    test('haqiqiy yuklash/o\'rnatish xatosi — xato', () {
      expect(
        PatchUpdater.isUpdateInProgress(const UpdateException(
          message: 'Failed to download patch',
          reason: UpdateFailureReason.downloadFailed,
        )),
        isFalse,
      );
      expect(
        PatchUpdater.isUpdateInProgress(const UpdateException(
          message: 'Patch failed to install',
          reason: UpdateFailureReason.installFailed,
        )),
        isFalse,
      );
    });

    test('UpdateException bo\'lmagan xato — matni mos bo\'lsa ham xato', () {
      expect(
        PatchUpdater.isUpdateInProgress(
            Exception('Update already in progress')),
        isFalse,
      );
    });
  });
}
```

</details>

<details><summary>YANGI: <code>test/startup_error_app_test.dart</code></summary>

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/app/startup_error_app.dart';
import 'package:invan2/changes/services/patch_updater.dart';

/// Dastur ishga tushmaganda ko'rsatiladigan ekran (qora/ko'rinmas oyna
/// o'rniga). Mac sinovida (2026-10-02) haqiqiy sabab — boshqa InVan dasturi
/// cheklar bazasini o'z sxemasiga yangilagan edi.
void main() {
  setUp(() {
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize =
        const Size(1600, 1200);
    binding.platformDispatcher.views.first.devicePixelRatio = 1;
  });

  testWidgets(
      'ObjectBox sxemasi mos emas — bazaga oid aniq sabab va "cheklar '
      'o\'chirilmagan" ko\'rsatiladi', (WidgetTester tester) async {
    await tester.pumpWidget(StartupErrorApp(
      error: Exception('ObjectBoxException: failed to create store: DB\'s '
          'last property ID 61 is higher than the incoming one 50 in entity '
          'ReceiptModel4'),
    ));

    expect(find.text('Dastur ishga tushmadi'), findsOneWidget);
    expect(find.text('Программа не запустилась'), findsOneWidget);
    expect(find.textContaining('dasturning bu versiyasiga mos emas'),
        findsOneWidget);
    expect(find.textContaining('Cheklar o\'chirilmagan'), findsOneWidget);
    expect(find.textContaining('last property ID 61'), findsOneWidget,
        reason: 'administrator uchun asl xato matni ko\'rinishi kerak');
    expect(find.text('Qayta ishga tushirish / Перезапустить'), findsOneWidget);
    expect(find.text('Yopish / Закрыть'), findsOneWidget);
  });

  testWidgets('boshqa xato — umumiy matn, baza haqida gapirilmaydi',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        const StartupErrorApp(error: 'HiveError: box is already locked'));

    expect(find.text('Dastur ishga tushmadi'), findsOneWidget);
    expect(find.textContaining('Qayta ishga tushirib'), findsOneWidget);
    expect(find.textContaining('versiyasiga mos emas'), findsNothing);
    expect(find.textContaining('box is already locked'), findsOneWidget);
  });

  test(
      'qayta ishga tushirish yangilanish belgisini meros qilmaydi — yangi '
      'jarayon patch tekshiruvini (rollback) o\'tkazib yubormaydi', () {
    final Map<String, String> env =
        StartupErrorApp.restartEnvironment(<String, String>{
      'PATH': r'C:\Windows\system32',
      PatchUpdater.relaunchedEnv: '1',
    });

    expect(env.containsKey(PatchUpdater.relaunchedEnv), isFalse);
    expect(env['PATH'], r'C:\Windows\system32',
        reason: 'qolgan muhit o\'zgarmasdan o\'tadi');
    expect(env[StartupErrorApp.restartEnv], '1',
        reason: 'Windows runner eski nusxa yopilishini kutsin');
  });
}
```

</details>

## 7. Tekshirish

- `flutter test test/patch_updater_test.dart test/startup_error_app_test.dart` — 6 test; to'liq to'plam — 1616/1616 (2026-10-02, `c4e42e1`).
- Mac (sinov relizi `1.1.2+9128`, patch 1–5, 2026-10-02): ilova ichida tugma → qayta yonish ✅; yopiq ilova ochilganda bir martada (+3.2 s) ✅; rollback (patch 3 → 2) bir ochilishda ✅; xato ekrani (boshqa dastur yangilagan ObjectBox bazasi bilan) ✅; ochilish vaqtlari — 2-bo'limda.
- **Windows:** qayta yonish (`CheckOneInstance` kutishi) sinalmagan — 1.1.2+129 o'rnatilgach birinchi patch bilan: (1) yopiq dastur ochiladi → bir martada yangi patch, "Dastur yangilandi"; (2) ish vaqtida tugma → dastur qayta ochiladi (yopilib qolmaydi).

## 8. Eslatmalar va ochiq savollar

- **ObjectBox sxemasini o'zgartiruvchi o'zgarish HECH QACHON patch bilan chiqmaydi** — rollback'dan keyin eski kod yangi bazani ochmaydi. Sxema faqat to'liq reliz bilan (va shu relizdan pastga qaytish yopiladi).
- `assets/` patch'ga kirmaydi. Yangi `Icons.xxx` ikonka shriftini o'zgartiradi → Shorebird "asset changes" deb ogohlantiradi (mavjud ikonkani ishlating).
- Patch faqat bitta relizga tushadi — kassalar turli relizlarda bo'lsa, muhim tuzatish har biriga alohida patch qilinadi.
- Rollback: `shorebird patches rollback --release-version=<v> --patch-number=<n>` (yoki console) — kassa keyingi tekshiruvda avvalgi patch'ga qaytadi.
- Odoo forkiga: kerak (Shorebird mantig'i umumiy; Odoo o'z `app_id` si bilan; `df6ef7c`..`d16df8a` allaqachon ko'chirilgan).

---

# 9-TASK — Click Pass / Payme Go → ReceivedCard (QQS to'liq) + elektron to'lov ID'lari chekda (1.1.2+129)

> **Commit:** `f007377` (2026-10-01) + `e5ba429` (2026-10-02), reliz `c4e42e1` 1.1.2+129.
> **Sessiya hujjati:** docs/sessions/2026-09-30-click-pass-payme-go-received-card.md
> **Holat 2026-10-02:** to'liq testlar o'tdi (1616), do'kon/qurilma sinovi kutilmoqda.

> ⚠️ **ObjectBox SXEMASI O'ZGARADI.** `ReceiptModel4` ga yangi maydon `epayJson`
> (`String?`) qo'shiladi — InVan 2 da bu ObjectBox property **51**
> (`lib/objectbox-model.json`). Shu sababli bu task **faqat to'liq reliz bilan**
> chiqadi (yangi `.exe`), **Shorebird patch bilan EMAS**: patch rollback bo'lsa
> eski kod yangi sxemali bazani ochmaydi va dastur ishga tushmaydi.
> **InVan 1 da `objectbox-model.json` / `objectbox.g.dart` ni InVan 2 dan
> KO'CHIRMANG** — maydonni modelga qo'shib, `dart run build_runner build
> --delete-conflicting-outputs` bilan O'ZINGIZ generatsiya qiling (property ID va
> UID'lar sizda boshqa bo'ladi).

## 1. Nima va nima uchun

**a) Click Pass / Payme Go fiskalda karta to'lovi (f007377).** Soliq (RPC) talabi:
mobil ilova integratsiyasi orqali olingan to'lov — haqiqiy beznal. Ilgari Click Pass
va Payme Go summasi fiskal chekning `Other` maydoniga tushardi va QQS **0** chiqardi
(noto'g'ri). Endi ular `ReceivedCard` ga tushadi, QQS to'liq hisoblanadi. Click QR /
Payme QR (kassir qo'lda belgilaydi, to'lov ID'si `@` bilan) va Uzum (Pass ham, QR
ham) — o'zgarishsiz `Other`, QQS 0.

**b) QR to'lovda provayderga noto'g'ri so'rov (f007377).** Fiskaldan keyin chek
havolasini Click/Payme/Uzum API'siga qaytarish bayroqlari (`receivedClick/Payme/Uzum`)
QR to'lovda ham `true` bo'lardi → provayderga oldingi to'lovdan qolgan `payment_id`
bilan so'rov ketardi. Endi bayroqlar faqat Pass/Go to'lovida `true`.

**c) Fiskal `ExtraInfo` da eski to'lov ID'si (2026-10-02).** `ExtraInfo`
(`QRPaymentProvider` / `QRPaymentID` / `PhoneNumber`) chekdan emas, global
Pref'dan (`epayPay_Id`, `epay_Id`, `epay_phone`) olinardi. Bu Pref:
- faqat fiskal MUVAFFAQIYATLI bo'lganda tozalanardi (fiskal yiqilsa — qolardi);
- `ClickService.post` HAR bir Click so'rovida qayta yozardi, jumladan fiskaldan
  keyingi `submit_qrcode` javobida — u tozalashdan KEYIN keladi, natijada har
  Click Pass sotuvidan keyin `epayPay_Id = 64` qolardi.
Natija: keyingi chekka, hatto naqd chekka ham, soliqqa "Click orqali to'langan" (64)
va eski to'lov ID'si ketishi mumkin edi.

**d) Qayta yuborilgan chekda provayderga boshqa to'lov ID'si (2026-10-02).** Cheklar
ro'yxatidan fiskalga qayta yuborishda (PreOfd) provayderga chekning emas, xotiradagi
OXIRGI to'lovning ID'si ketardi (`ClickService.paymentId`, `UzumService.paymentId`,
`PaynetService.paymentId`, Pref `p_id`); dastur qayta ochilgan bo'lsa — bo'sh ID.

**Yechim (c, d):** elektron to'lov ID'lari chek yaratilgan zahoti chekning o'ziga
(`ReceiptModel4.epayJson`) yoziladi; fiskal body ham, provayderga yuborish ham faqat
shundan o'qiydi. To'lov sahifasi ochilganda global qoldiqlar tozalanadi.

## 2. Qanday ishlaydi (oqim; eski vs yangi)

**To'lov tasnifi (sotuv, `FiscalPaymentSplit.of`):**

| To'lov turi | Eski | Yangi |
|---|---|---|
| Naqd | `ReceivedCash` | o'zgarmagan |
| Karta (Uzcard/Humo), nasiya, noma'lum | `ReceivedCard` | o'zgarmagan |
| **Click Pass / Payme Go** (payId `id`, nomi `CLICK PASS` / `PAYME GO`) | `Other`, QQS 0 | **`ReceivedCard`, QQS to'liq** |
| Click QR / Payme QR (payId `@id` YOKI nomida `QR`) | `Other` | o'zgarmagan |
| Uzum / Uzum QR | `Other` | o'zgarmagan |
| Cashback | `Other` | o'zgarmagan |
| Vozvrat (hamma tur) | `ReceivedCash` | o'zgarmagan |

QR aniqlash: `payId` `@` bilan boshlansa **yoki** nomida `QR` bo'lsa (serverdan
qaytgan chekda `@` yo'q bo'lishi mumkin).

**Elektron to'lov ID'lari:**

```
ESKI:
  to'lov (Click/Payme/Uzum) → ClickService.paymentId / Pref p_id / UzumService.paymentId
                              + Pref epay_Id/epayPay_Id/epay_phone   (GLOBAL)
  saleOnOFD → externalInfo = Pref epay_*           ← oldingi to'lovniki bo'lishi mumkin
  sell OK  → provayderga ClickService.paymentId …  ← qayta yuborishda boshqa to'lovniki
  sell OK  → Pref epay_* tozalanadi (yiqilsa — yo'q; Click javobi keyin qayta yozadi)

YANGI:
  to'lov sahifasi ochildi → EpayCapture.reset()   (statik ID'lar + Pref epay_*, p_id)
  to'lov (servislar eskicha global yozadi)
  chek yig'ildi → receipt.epayJson = EpayCapture.forReceipt(receipt)
                  (faqat SHU chekdagi Pass/Go provayderlarining ID'lari)
  saleOnOFD → externalInfo = ReceiptEpay.decode(receipt.epayJson)  (vozvratda bo'sh)
  sell OK  → epay.targets(params): bayroq true VA chekda ID bor → provayderga shu ID
  PreOfd   → nusxa epayJson'ni o'zi bilan olib yuradi
```

`ReceiptEpay.capture` qoidalari:
- Click/Payme/Uzum ID'si faqat chekda o'sha provayderning **Pass/Go** to'lovi bo'lsa
  (`FiscalPaymentSplit.hasPass`); QR'da olinmaydi.
- Paynet ID'si chekda Paynet to'lovi bo'lsa (Pass ham, QR ham — `receivedPaynet`
  qoidasi bilan bir xil).
- `ExtraInfo` provayderi: chekdagi Pass/Go provayderi; bir nechta bo'lsa — oxirgi
  to'langani (Pref `epayPay_Id`), aniqlanmasa Click → Payme → Uzum tartibi.
  Provayder kodlari: Click **64**, Payme **141**, Uzum **161**.
- Telefon faqat oxirgi to'langan provayder shu chekdagi provayder bo'lsa (boshqa
  provayderning telefoni oqib ketmasin).
- Vozvrat → bo'sh.

Yangilanishdan oldingi fiskalsiz cheklar (`epayJson == null`) qayta yuborilsa:
provayderga **yuborilmaydi** (noto'g'ri ID bilan yuborishdan ko'ra), `ExtraInfo`
bo'sh; pul maydonlari (`ReceivedCard` va h.k.) o'zgarmaydi.

## 3. O'zgarishlar ro'yxati

| Fayl | Tur | Nima |
|---|---|---|
| `lib/changes/domain/receipt/receipt_vat.dart` | o'zgargan (f007377) | `FiscalPaymentSplit.isQr`, `hasPass`; Click/Payme: Pass/Go → `card`, QR → `epay` |
| `lib/changes/domain/receipt/receipt_epay.dart` | YANGI | `ReceiptEpay` (capture / encode / decode / targets), `EpayTarget` |
| `lib/changes/services/payment/epay_capture.dart` | YANGI | `EpayCapture.forReceipt` (global manbalar → `ReceiptEpay`), `EpayCapture.reset` |
| `lib/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart` | o'zgargan | `String? epayJson` maydoni (ObjectBox) — serverga ketmaydi |
| `lib/objectbox-model.json`, `lib/objectbox.g.dart` | generatsiya | +1 property (InVan 1 o'zi generatsiya qiladi!) |
| `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart` | o'zgargan | f007377: `receivedClick/Payme/Uzum` = `hasPass`; yangi: `externalInfo` chekdagi `ReceiptEpay` dan (vozvratda bo'sh); `fromReceipt4ToClick(clickPaymentId:)`; `click_service` importi olib tashlandi |
| `lib/changes/services/local_selling_service.dart` | o'zgargan | provayderga yuborish `ReceiptEpay.targets` + chekdagi ID'lar bilan; `extraInfoFromBody` ajratildi (tana o'zgarmagan) |
| `lib/changes/services/payment/payme_service.dart` | o'zgargan | `setFiscalData2(paymeReceiptId:)` — Pref `p_id` o'rniga |
| `lib/changes/services/receipt_api_4.dart` | o'zgargan | `ReceiptApi4.func` nusxasiga `epayJson` |
| `lib/features/checks/features/check_view/bloc/pre_ofd/preofd_bloc.dart` | o'zgargan | nusxa `receiptForResend` ga ajratildi (tana o'zgarmagan) + `epayJson` |
| `lib/changes/providers/ordering_provider_4.dart` | o'zgargan | `pressPaymentButton` va `pressPaymentButtonOnlyOFD` da chek yig'ilgach `epayJson`; `initPaymentPageValues` da `EpayCapture.reset()` (eski `PaynetService.paymentId = null` shu ichida) |
| `test/receipt_vat_test.dart` | o'zgargan (f007377) | Pass/Go/QR tasnifi va bayroqlar |
| `test/receipt_epay_test.dart` | YANGI | 36 test |
| `test/epay_fiscal_matrix_test.dart` | YANGI | 124 test (to'lov turi × savat, juftlar, vozvrat) |
| `test/support/epay_fixtures.dart` | YANGI | umumiy fixture'lar |

## 4. Bog'liqliklar (InVan 1 uchun)

InVan 1 da bo'lmasligi mumkin bo'lgan sinflar:

- **`FiscalPaymentSplit`** (`receipt_vat.dart`) — 2026-09-24 "fiskal QQS chegirma
  bazasi" taskida paydo bo'lgan. Yo'q bo'lsa: kerakli minimal — `isQr(p)` va
  `hasPass(receipt, providerId)` statik funksiyalari hamda `saleOnOFD` dagi to'lov
  tasnifi tsikli (Click/Payme shoxida `isQr ? epay : card`).
- **`ReceiptBuilder`** (`lib/changes/domain/receipt/receipt_builder.dart`) —
  OrderingProvider4 ajratilishidan (Faza 9). Yo'q bo'lsa: `epayJson` chek
  `ReceiptModel4(...)` yaratilib, `payment` qo'shilgan joyda (pressPaymentButton /
  pressPaymentButtonOnlyOFD ichida) yoziladi.
- **`ReceiptPayments.build`** — to'lov nomlarini normallashtiradi (`CLICK PASS`,
  `CLICK QR`, `PAYME GO`, `PAYME QR`, `UZUM`, `UZUM QR`); QR — `type == 1`, kalit
  `@id`. InVan 1 da nomlar boshqacha bo'lsa — `isQr` / `hasPass` shunga moslanadi.
- **`PaynetService`** — Paynet integratsiyasi yo'q bo'lsa: `ReceiptEpay` dan
  `paynetPaymentId` va `EpayTarget.paynet` ni olib tashlang, `EpayCapture` dan
  Paynet qatorini olib tashlang.
- **`PreOfdBloc`** — cheklar ro'yxatidan fiskalga qayta yuborish. Boshqa nom bilan
  bo'lishi mumkin: asosiysi — chek nusxasi `epayJson` ni olib yurishi.
- **`ReceiptApi4.func`** — `saleOnOFD` chekning nusxasi bilan ishlaydi; nusxaga
  `epayJson` o'tishi shart (aks holda `ExtraInfo` doim bo'sh).

## 5. Qo'llash tartibi

1. `receipt_vat.dart`: `isQr`, `hasPass` va Click/Payme tasnifi (f007377 diff).
2. `receipt_singleton_4.dart` → `saleOnOFD`: `receivedClick/Payme/Uzum` =
   `FiscalPaymentSplit.hasPass(...)` (f007377 diff).
3. `receipt_epay.dart` (YANGI, to'liq) va `epay_capture.dart` (YANGI, to'liq).
4. `ReceiptModel4` ga `String? epayJson;` → **InVan 1 da** `dart run build_runner
   build --delete-conflicting-outputs` (ObjectBox generatsiyasi; InVan 2 fayllarini
   ko'chirmang).
5. Nusxalash joylari: `ReceiptApi4.func` va `PreOfdBloc` (va InVan 1 da chekni
   qayta yaratadigan boshqa joylar — `cardNumber`/`pptId` nusxalanadigan joylarni
   qidiring).
6. `saleOnOFD`: `externalInfo` chekdagi `ReceiptEpay` dan (vozvratda `empty`).
7. `fromReceipt4ToClick(clickPaymentId:)`, `PaymeGOService.setFiscalData2(paymeReceiptId:)`.
8. `LocalService.sell`: `epay.targets(body['params'])` bo'yicha provayderlarga.
9. `OrderingProvider4`: chek yig'ilgach `receipt.epayJson = EpayCapture.forReceipt(receipt)`
   (ikkala to'lov yo'lida); `initPaymentPageValues` da `EpayCapture.reset()`.
10. Testlar (6-bo'lim) — InVan 1 fixture'lariga moslab.

## 6. Kod

> `lib/objectbox-model.json` va `lib/objectbox.g.dart` bu yerda YO'Q — generatsiya, InVan 1 o'zi qiladi (yuqoridagi ogohlantirish).

### 6.1. `lib/changes/domain/receipt/receipt_vat.dart` (`f007377`)

```diff
diff --git a/lib/changes/domain/receipt/receipt_vat.dart b/lib/changes/domain/receipt/receipt_vat.dart
index 606686f..dc72dda 100644
--- a/lib/changes/domain/receipt/receipt_vat.dart
+++ b/lib/changes/domain/receipt/receipt_vat.dart
@@ -11,10 +11,11 @@
 // Ulush fiskal `_countOtherOFD` bilan aynan bir xil taqsimlanadi (chegirmali
 // qator summasining chek jamisidagi nisbati, so'mga yaxlitlab).
 //
-// Click / Payme / Uzum: fiskalda hozircha `Other` (QQS 0) — bu alohida
-// masala (docs/fiskal-tolov-turlari-va-qqs.md §6.1, rasmiy talab: karta
-// to'lovi, QQS to'liq). Qog'oz chekda ular ayrilMAYDI — fiskal tuzatilganda
-// ikkisi o'z-o'zidan mos keladi.
+// Click Pass / Payme Go (2026-09-30): ilova integratsiyasi orqali olingan
+// haqiqiy beznal pul → fiskal `ReceivedCard`, QQS to'liq (rasmiy talab,
+// docs/fiskal-tolov-turlari-va-qqs.md §2.2). Qog'oz chek bilan mos.
+// Click QR / Payme QR (qo'lda belgilanadigan, `@id`) va Uzum (Pass ham, QR
+// ham) — o'zgarishsiz `Other` (QQS 0). Qog'oz chekda ular ayrilMAYDI.
 //
 // Testlar: test/receipt_vat_test.dart
 
@@ -35,7 +36,8 @@ class FiscalPaymentSplit {
   /// Do'kon bonusi (cashback) — xaridordan olinmagan pul → fiskal `Other`.
   final double cashback;
 
-  /// Click / Payme / Uzum — hozircha fiskal `Other` (yuqoridagi izoh).
+  /// Click QR / Payme QR / Uzum — fiskal `Other` (yuqoridagi izoh).
+  /// Click Pass / Payme Go bu yerga emas, [card] ga tushadi.
   final double epay;
 
   const FiscalPaymentSplit({
@@ -45,9 +47,24 @@ class FiscalPaymentSplit {
     required this.epay,
   });
 
-  /// `saleOnOFD` dagi qoida (o'zgartirilmagan, shu yerga ko'chirildi):
-  /// vozvratda hammasi naqd; sotuvda avval nom, keyin adminka ID bo'yicha;
-  /// hech qaysiga tushmasa — karta.
+  /// QR varianti: to'lov ekranida qo'lda belgilangan (`type: 1` → payId
+  /// '@id', nomi 'CLICK QR' / 'PAYME QR' / 'UZUM QR'). Serverdan qaytgan
+  /// chekda '@' olib tashlangan bo'lishi mumkin — shuning uchun nom ham.
+  static bool isQr(ReceiptModelPaymentType4 p) =>
+      p.payId.trim().startsWith('@') || p.name.toUpperCase().contains('QR');
+
+  /// Chekda [providerId] ning Pass/Go (integratsiya orqali) to'lovi bormi.
+  /// Fiskal chek URL'i provayderga (Click/Payme/Uzum) faqat shunda qaytariladi:
+  /// QR variantida provayder to'lov ID'si yo'q (yoki oldingi to'lovdan qolgan).
+  static bool hasPass(ReceiptModel4 receipt, String providerId) {
+    if (providerId.isEmpty) return false;
+    return receipt.payment.any(
+      (p) => p.payId.replaceFirst('@', '').trim() == providerId && !isQr(p),
+    );
+  }
+
+  /// `saleOnOFD` dagi qoida: vozvratda hammasi naqd; sotuvda avval nom,
+  /// keyin adminka ID bo'yicha; hech qaysiga tushmasa — karta.
   static FiscalPaymentSplit of(ReceiptModel4 receipt) {
     double cash = 0, card = 0, cashback = 0, epay = 0;
 
@@ -80,8 +97,14 @@ class FiscalPaymentSplit {
       } else if (id == cashbackId) {
         cashback += p.value;
       } else if ((id == clickId && nameUpper.contains('CLICK')) ||
-          (id == paymeId && nameUpper.contains('PAYME')) ||
-          (id == uzumId && nameUpper.contains('UZUM'))) {
+          (id == paymeId && nameUpper.contains('PAYME'))) {
+        // Pass / Go — beznal (karta), QR — Other
+        if (isQr(p)) {
+          epay += p.value;
+        } else {
+          card += p.value;
+        }
+      } else if (id == uzumId && nameUpper.contains('UZUM')) {
         epay += p.value;
       } else {
         // Boshqa barcha holatlar (xavfsizlik uchun) → CARD
```

### 6.2. YANGI: `lib/changes/domain/receipt/receipt_epay.dart`

```dart
// Chekning elektron to'lov (Click Pass / Payme Go / Uzum / Paynet) ma'lumoti.
//
// Nega kerak (2026-10-02): ilgari bu ma'lumot chekda emas, global joyda
// turardi — `ClickService.paymentId`, `UzumService.paymentId`,
// `PaynetService.paymentId` (xotirada) va Pref `epay_Id` / `epayPay_Id` /
// `epay_phone` / `p_id`. Natijada:
//   1. Fiskal `ExtraInfo` (QRPaymentProvider / QRPaymentID / PhoneNumber)
//      oldingi to'lovdan qolgan qiymat bilan ketardi — hatto naqd chekda ham
//      (Click'ning `submit_qrcode` javobi Pref'ni tozalashdan KEYIN qayta
//      yozardi; fiskal yiqilsa Pref umuman tozalanmasdi).
//   2. Cheklar ro'yxatidan fiskalga qayta yuborilgan (PreOfd) Pass chekida
//      provayderga (Click/Payme/Uzum/Paynet) o'sha chekning emas, xotiradagi
//      oxirgi to'lov ID'si ketardi (dastur qayta ochilgan bo'lsa — bo'sh).
//
// Endi chek yaratilgan zahoti ([capture]) shu chekdagi Pass/Go to'lovlarining
// ID'lari chekka (`ReceiptModel4.epayJson`) yoziladi va fiskal body ham,
// provayderga yuborish ham faqat shu yerdan o'qiydi.
//
// Testlar: test/receipt_epay_test.dart, test/epay_fiscal_matrix_test.dart

import 'dart:convert';

import 'package:invan2/changes/domain/receipt/receipt_vat.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

/// Fiskal chek URL'i qaytariladigan provayder.
enum EpayTarget { click, payme, uzum, paynet }

class ReceiptEpay {
  const ReceiptEpay({
    this.qrPaymentProvider = 0,
    this.qrPaymentId = '',
    this.phoneNumber = '',
    this.clickPaymentId = '',
    this.paymeReceiptId = '',
    this.uzumPaymentId = '',
    this.paynetPaymentId,
  });

  /// Fiskal `ExtraInfo.QRPaymentProvider` kodlari.
  static const int clickProvider = 64;
  static const int paymeProvider = 141;
  static const int uzumProvider = 161;

  static const ReceiptEpay empty = ReceiptEpay();

  /// Fiskal `ExtraInfo` — 0 / bo'sh: elektron Pass to'lov yo'q.
  final int qrPaymentProvider;
  final String qrPaymentId;
  final String phoneNumber;

  /// Provayderga fiskal chek URL'ini qaytarish uchun — bo'sh bo'lsa
  /// yuborilmaydi (noto'g'ri ID bilan yuborishdan ko'ra yubormagan yaxshi).
  final String clickPaymentId;
  final String paymeReceiptId;
  final String uzumPaymentId;
  final int? paynetPaymentId;

  bool get isEmpty =>
      qrPaymentProvider == 0 &&
      qrPaymentId.isEmpty &&
      phoneNumber.isEmpty &&
      clickPaymentId.isEmpty &&
      paymeReceiptId.isEmpty &&
      uzumPaymentId.isEmpty &&
      paynetPaymentId == null;

  /// Chek yaratilayotgan paytdagi manbalardan faqat SHU chekdagi to'lovlarga
  /// tegishlisini oladi. Manbalar (servis/Pref qiymatlari) chaqiruvchidan
  /// beriladi — bu klass global holatni o'qimaydi.
  ///
  /// - Click/Payme/Uzum ID'si faqat chekda o'sha provayderning Pass/Go
  ///   to'lovi bo'lsa (QR — qo'lda belgilanadi, provayder ID'si yo'q).
  /// - Paynet ID'si chekda Paynet to'lovi bo'lsa (Pass ham, QR ham —
  ///   `receivedPaynet` bilan bir xil qoida).
  /// - ExtraInfo: chekdagi Pass/Go provayderi. Bir nechta bo'lsa — eng oxirgi
  ///   to'langani ([lastProvider], Pref `epayPay_Id`), aniqlanmasa Click →
  ///   Payme → Uzum tartibida birinchisi. Telefon faqat [lastProvider] shu
  ///   provayder bo'lsa (u boshqa provayderniki bo'lishi mumkin).
  static ReceiptEpay capture({
    required ReceiptModel4 receipt,
    required String clickId,
    required String paymeId,
    required String uzumId,
    required String paynetId,
    String? clickPaymentId,
    String? paymeReceiptId,
    String? uzumPaymentId,
    int? paynetPaymentId,
    int lastProvider = 0,
    String lastPhone = '',
  }) {
    if (receipt.isRefund) return empty;

    String pick(String providerId, String? value) =>
        FiscalPaymentSplit.hasPass(receipt, providerId)
            ? (value ?? '').trim()
            : '';

    final String click = pick(clickId, clickPaymentId);
    final String payme = pick(paymeId, paymeReceiptId);
    final String uzum = pick(uzumId, uzumPaymentId);

    final bool hasPaynet = paynetId.isNotEmpty &&
        receipt.payment
            .any((p) => p.payId.replaceFirst('@', '').trim() == paynetId);
    final int? paynet =
        hasPaynet && paynetPaymentId != null && paynetPaymentId > 0
            ? paynetPaymentId
            : null;

    final Map<int, String> present = <int, String>{
      if (click.isNotEmpty) clickProvider: click,
      if (payme.isNotEmpty) paymeProvider: payme,
      if (uzum.isNotEmpty) uzumProvider: uzum,
    };
    int provider = 0;
    if (present.containsKey(lastProvider)) {
      provider = lastProvider;
    } else if (present.isNotEmpty) {
      provider = present.keys.first;
    }

    return ReceiptEpay(
      qrPaymentProvider: provider,
      qrPaymentId: present[provider] ?? '',
      phoneNumber: provider != 0 && provider == lastProvider ? lastPhone : '',
      clickPaymentId: click,
      paymeReceiptId: payme,
      uzumPaymentId: uzum,
      paynetPaymentId: paynet,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'qrPaymentProvider': qrPaymentProvider,
        'qrPaymentId': qrPaymentId,
        'phoneNumber': phoneNumber,
        'clickPaymentId': clickPaymentId,
        'paymeReceiptId': paymeReceiptId,
        'uzumPaymentId': uzumPaymentId,
        if (paynetPaymentId != null) 'paynetPaymentId': paynetPaymentId,
      };

  factory ReceiptEpay.fromJson(Map<String, dynamic> json) => ReceiptEpay(
        qrPaymentProvider: (json['qrPaymentProvider'] as num?)?.toInt() ?? 0,
        qrPaymentId: '${json['qrPaymentId'] ?? ''}',
        phoneNumber: '${json['phoneNumber'] ?? ''}',
        clickPaymentId: '${json['clickPaymentId'] ?? ''}',
        paymeReceiptId: '${json['paymeReceiptId'] ?? ''}',
        uzumPaymentId: '${json['uzumPaymentId'] ?? ''}',
        paynetPaymentId: (json['paynetPaymentId'] as num?)?.toInt(),
      );

  /// Fiskal muvaffaqiyatli bo'lgach fiskal chek URL'i qaysi provayderlarga
  /// qaytariladi. [params] — `saleOnOFD` body'sining `params` qismi
  /// (`receivedClick` va h.k. — faqat Pass/Go'da true). Bayroq bo'lsa-yu,
  /// chekda ID bo'lmasa (yangilanishdan oldingi chek) — yuborilmaydi:
  /// boshqa to'lov ID'si bilan yuborishdan ko'ra yubormagan to'g'ri.
  Set<EpayTarget> targets(Map<String, dynamic> params) => <EpayTarget>{
        if (params['receivedClick'] == true && clickPaymentId.isNotEmpty)
          EpayTarget.click,
        if (params['receivedPayme'] == true && paymeReceiptId.isNotEmpty)
          EpayTarget.payme,
        if (params['receivedUzum'] == true && uzumPaymentId.isNotEmpty)
          EpayTarget.uzum,
        if (params['receivedPaynet'] == true && paynetPaymentId != null)
          EpayTarget.paynet,
      };

  /// `ReceiptModel4.epayJson` uchun. Bo'sh bo'lsa `null` (eski cheklar kabi).
  String? encode() => isEmpty ? null : jsonEncode(toJson());

  /// Buzilgan yoki yo'q (eski chek) — [empty].
  static ReceiptEpay decode(String? raw) {
    if (raw == null || raw.isEmpty) return empty;
    try {
      final dynamic json = jsonDecode(raw);
      return json is Map<String, dynamic> ? ReceiptEpay.fromJson(json) : empty;
    } catch (_) {
      return empty;
    }
  }
}
```

### 6.3. YANGI: `lib/changes/services/payment/epay_capture.dart`

```dart
// Elektron to'lov ID'larining global manbalari (servis maydonlari va Pref)
// bilan `ReceiptEpay` o'rtasidagi ko'prik.
//
// - [reset] — to'lov sahifasi ochilganda (`initPaymentPageValues`): oldingi
//   sotuvdan qolgan ID hech qachon yangi chekka tushmasin. `paymentsMap` ham
//   shu yerda tozalanadi, ya'ni yangi Pass to'lov baribir qaytadan qilinadi.
// - [forReceipt] — chek yig'ilgan zahoti: shu chekdagi Pass/Go to'lovlarining
//   ID'larini chekka yozish uchun JSON.

import 'package:invan2/changes/domain/receipt/receipt_epay.dart';
import 'package:invan2/changes/services/payment/click_service.dart';
import 'package:invan2/changes/services/payment/paynet_service.dart';
import 'package:invan2/changes/services/payment/uzum_service.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class EpayCapture {
  const EpayCapture._();

  /// `ReceiptModel4.epayJson` uchun qiymat (Pass/Go yo'q bo'lsa null).
  static String? forReceipt(ReceiptModel4 receipt) => ReceiptEpay.capture(
        receipt: receipt,
        clickId: Pref.getString(PrefKeys.clickId, ''),
        paymeId: Pref.getString(PrefKeys.paymeId, ''),
        uzumId: Pref.getString(PrefKeys.uzumId, ''),
        paynetId: Pref.getString(PrefKeys.paynetId, ''),
        clickPaymentId: ClickService.paymentId,
        paymeReceiptId: Pref.getString('p_id', ''),
        uzumPaymentId: UzumService.paymentId,
        paynetPaymentId: PaynetService.paymentId,
        lastProvider: Pref.getInt('epayPay_Id', 0),
        lastPhone: Pref.getString('epay_phone', ''),
      ).encode();

  /// Yangi to'lov sessiyasi — oldingi to'lov ID'lari unutiladi.
  static void reset() {
    ClickService.paymentId = null;
    UzumService.paymentId = null;
    PaynetService.paymentId = null;
    // Faqat qiymat bor bo'lsa yoziladi — to'lov sahifasi har ochilganda
    // diskka bekorga yozilmasin.
    for (final String key in const ['p_id', 'epay_Id', 'epay_phone']) {
      if (Pref.getString(key, '').isNotEmpty) Pref.setString(key, '');
    }
    if (Pref.getInt('epayPay_Id', 0) != 0) Pref.setInt('epayPay_Id', 0);
  }
}
```

### 6.4. `lib/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart`

```diff
diff --git a/lib/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart b/lib/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart
index a4118d7..1269cc5 100644
--- a/lib/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart
+++ b/lib/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart
@@ -57,6 +57,12 @@ class ReceiptModel4 {
   String? pptId;        // RRN: "608610728951"
   int? cardType;
 
+  /// Elektron to'lov (Click Pass / Payme Go / Uzum / Paynet) ID'lari va fiskal
+  /// ExtraInfo — `ReceiptEpay` JSON'i. Chek yaratilganda yoziladi; fiskal body
+  /// va provayderga fiskal URL yuborish faqat shundan o'qiydi. Eski cheklarda
+  /// null. Serverga (order_pos) ketmaydi.
+  String? epayJson;
+
   /// Savat sessiyasida o'chirilgan mahsulotlar (DeletedItemModel4 ro'yxati)
   /// JSON string ko'rinishida — offline chek bilan birga saqlanib,
   /// order_pos body'sida "deleted_items" bo'lib ketadi.
```

### 6.5. `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart` (`f007377` + `e5ba429`)

```diff
diff --git a/lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart b/lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart
index ba75e4d..719ce2c 100644
--- a/lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart
+++ b/lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart
@@ -3,12 +3,12 @@ import 'dart:convert';
 import 'package:flutter/foundation.dart';
 import 'package:invan2/changes/domain/marking/fiscal_mxik_fallback.dart';
 import 'package:invan2/changes/domain/receipt/receipt_vat.dart';
+import 'package:invan2/changes/domain/receipt/receipt_epay.dart';
 import 'package:invan2/changes/models/discount_model.dart';
 import 'package:invan2/changes/models/ofd/epos_response_model.dart';
 import 'package:invan2/changes/models/product/sale_item_model.dart';
 import 'package:invan2/changes/models/product_discount_model.dart';
 import 'package:invan2/changes/services/log_helper.dart';
-import 'package:invan2/changes/services/payment/click_service.dart';
 import 'package:invan2/changes/services/receipt_api_4.dart';
 import 'package:invan2/features/features.dart';
 import 'package:invan2/features/get_products/singletons/items_singleton.dart';
@@ -245,10 +245,15 @@ class ReceiptSingleton4 {
 
     final paynetId = Pref.getString(PrefKeys.paynetId, "");
 
-    // To'lov tasnifi (naqd / karta / cashback / Click-Payme-Uzum) qog'oz chek
+    // To'lov tasnifi (naqd / karta / cashback / QR-Uzum) qog'oz chek
     // QQS'i bilan BIR XIL qoidadan: lib/changes/domain/receipt/receipt_vat.dart
-    // (vozvratda hammasi naqd; sotuvda nom/ID bo'yicha; noma'lum → karta).
+    // (vozvratda hammasi naqd; sotuvda nom/ID bo'yicha; noma'lum → karta;
+    // Click Pass / Payme Go → karta, Click/Payme QR va Uzum → Other).
     final FiscalPaymentSplit split = FiscalPaymentSplit.of(receipt);
+    // Vozvratda provayderga hech narsa qaytarilmaydi va ExtraInfo bo'sh.
+    final ReceiptEpay epay = receipt.isRefund
+        ? ReceiptEpay.empty
+        : ReceiptEpay.decode(receipt.epayJson);
     // Tiyinda, butun songa yaxlitlab — float changi FiscalReceiptModel'dagi
     // `.toInt()` kesishida 1 tiyin yo'qotmasin.
     final double receivedCashValue = (split.cash * 100).roundToDouble();
@@ -365,15 +370,23 @@ class ReceiptSingleton4 {
         if (!receipt.isRefund) ...{'paycheckNumber': receipt.externalId},
         "receivedCash": receivedCashValue,
         "receivedCard": receivedCardValue,
-        "receivedClick": receipt.hasClick,
-        "receivedUzum": receipt.hasUzum,
-        "receivedPayme": receipt.hasPayme,
+        // Fiskal chek URL'ini provayderga qaytarish bayroqlari — faqat
+        // Pass/Go. `receipt.hasClick/...` QR'da ham true (serverga shunday
+        // ketadi), QR'da esa provayder to'lov ID'si yo'q.
+        "receivedClick": FiscalPaymentSplit.hasPass(
+            receipt, Pref.getString(PrefKeys.clickId, "")),
+        "receivedUzum": FiscalPaymentSplit.hasPass(
+            receipt, Pref.getString(PrefKeys.uzumId, "")),
+        "receivedPayme": FiscalPaymentSplit.hasPass(
+            receipt, Pref.getString(PrefKeys.paymeId, "")),
         "receivedPaynet": receivedPaynet,
         "receivedDept": receipt.hasDept,
+        // ExtraInfo chekning o'zidan: global Pref (`epay_Id` va h.k.) oldingi
+        // to'lovdan qolgan bo'lishi mumkin edi. Qarang: ReceiptEpay.
         "externalInfo": {
-          "qrPaymentProvider": Pref.getInt('epayPay_Id', 0).toString(),
-          "qrPaymentID": Pref.getString('epay_Id', "").toString(),
-          "phoneNumber": Pref.getString('epay_phone', "").toString(),
+          "qrPaymentProvider": epay.qrPaymentProvider.toString(),
+          "qrPaymentID": epay.qrPaymentId,
+          "phoneNumber": epay.phoneNumber,
           "cardType": receipt.cardType ?? Pref.getInt('card_type', 0),
           "cardNumber": receipt.cardNumber ?? '',
           "pptId": receipt.pptId ?? '',
@@ -634,15 +647,18 @@ class ReceiptSingleton4 {
 
   //   return clickData;
   // }
+  /// [clickPaymentId] — shu chekning Click Pass to'lov ID'si
+  /// (`ReceiptEpay.clickPaymentId`), xotiradagi oxirgi to'lovniki emas.
   static Map<String, dynamic> fromReceipt4ToClick({
     required Map<String, dynamic> receipt,
+    required String clickPaymentId,
   }) {
     Map<String, dynamic> params = receipt['params'];
     List<Map<String, dynamic>> items = params['items'];
 
     var clickData = {
       "service_id": Pref.getInt(PrefKeys.serviceId, -1),
-      "payment_id": num.tryParse(ClickService.paymentId ?? ''),
+      "payment_id": num.tryParse(clickPaymentId),
       "items": List.generate(items.length, (index) {
         Map<String, dynamic> map = {};
         Map<String, dynamic> item = items[index];
```

### 6.6. `lib/changes/services/local_selling_service.dart`

```diff
diff --git a/lib/changes/services/local_selling_service.dart b/lib/changes/services/local_selling_service.dart
index a649890..d511f6a 100644
--- a/lib/changes/services/local_selling_service.dart
+++ b/lib/changes/services/local_selling_service.dart
@@ -3,6 +3,7 @@
 import 'dart:async';
 import 'dart:convert';
 import 'dart:io';
+import 'package:invan2/changes/domain/receipt/receipt_epay.dart';
 import 'package:invan2/changes/models/ofd/epos_response_model.dart';
 import 'package:invan2/changes/models/ofd/incom_response_model.dart';
 import 'package:invan2/changes/repository/log_repository.dart';
@@ -109,9 +110,22 @@ static String cleanMarkForFiscal(String rawMark) {
 
       if (!data['error']) {
         CommunicatorRESPONSE res = CommunicatorRESPONSE.fromJson(data);
+        // Fiskal chek URL'i provayderlarga — faqat SHU chekning to'lov
+        // ID'lari bilan (ReceiptEpay). Ilgari xotiradagi oxirgi to'lov ID'si
+        // ishlatilardi: cheklar ro'yxatidan qayta yuborilganda boshqa
+        // to'lovga (yoki bo'sh ID bilan) ketardi.
+        final ReceiptEpay epay = receiptData is ReceiptModel4 &&
+                !receiptData.isRefund
+            ? ReceiptEpay.decode(receiptData.epayJson)
+            : ReceiptEpay.empty;
+        final Set<EpayTarget> targets = epay.targets(body['params']);
+
         // Agar to'lovda CLICK PASSdan foydalanilsa, Receiptni CLICK ka jo'natish kerak
-        if (body['params']['receivedClick']) {
-          var clickData = ReceiptSingleton4.fromReceipt4ToClick(receipt: body);
+        if (targets.contains(EpayTarget.click)) {
+          var clickData = ReceiptSingleton4.fromReceipt4ToClick(
+            receipt: body,
+            clickPaymentId: epay.clickPaymentId,
+          );
           ClickService.sendFiscalReceipt({
             'service_id': clickData['service_id'],
             'payment_id': clickData['payment_id'],
@@ -120,16 +134,16 @@ static String cleanMarkForFiscal(String rawMark) {
         }
 
         // Agar to'lovda Uzum Passdan foydalanilsa, Receiptni Uzumga ka jo'natish kerak
-        if (body['params']['receivedUzum']) {
+        if (targets.contains(EpayTarget.uzum)) {
           await UzumService.sendFiscalReceipt({
-            'payment_id': UzumService.paymentId.toString(),
+            'payment_id': epay.uzumPaymentId,
             'fiscal_url': res.info?.qrCodeUrl,
           });
         }
 
         // Agar to'lovda Paynet (Pass yoki QR) dan foydalanilsa, fiskal chekni Paynетга jo'natish kerak
-        if (body['params']['receivedPaynet'] == true) {
-          final pid = PaynetService.paymentId ?? 0;
+        if (targets.contains(EpayTarget.paynet)) {
+          final int pid = epay.paynetPaymentId!;
           final qrcode = res.info?.qrCodeUrl ?? '';
           final address = Pref.getString(PrefKeys.serviceAddress, "");
           print('======= Paynet sendFiscalReceipt | pid: $pid | qrcode: $qrcode | address: $address =======');
@@ -142,10 +156,11 @@ static String cleanMarkForFiscal(String rawMark) {
         }
 
         // Agar to'lovda Payme Godan foydalanilsa, Receiptni Paymega ka jo'natish kerak
-        if (body['params']['receivedPayme']) {
+        if (targets.contains(EpayTarget.payme)) {
           PaymeGOService.setFiscalData2(
             info: res.info,
             statusCode: 0,
+            paymeReceiptId: epay.paymeReceiptId,
           );
         }
         LogRepository.addLog(
@@ -225,6 +240,30 @@ static String cleanMarkForFiscal(String rawMark) {
     }
   }
 
+  /// `saleOnOFD` body'sidagi `externalInfo` → fiskal `ExtraInfo`
+  /// (`saleWithOutIncom` dan ajratildi — tana o'zgarmagan; testlar uchun).
+  static ExtraInfo extraInfoFromBody(Map<String, dynamic> body) {
+    return ExtraInfo(
+      carNumber: "",
+      phoneNumber: body['params']['externalInfo']['phoneNumber'] ?? '',
+      cardType: body['params']['externalInfo']['cardType'],
+      pinfl: "",
+      tin: "",
+      qrPaymentID: body['params']['externalInfo']['qrPaymentID'] ?? '',
+      qrPaymentProvider: int.tryParse(
+        body['params']['externalInfo']['qrPaymentProvider']?.toString() ?? '0',
+      ) ?? 0,
+
+      // ==================== YANGI QO‘SHILGAN MAYDONLAR ====================
+      cardNumber: body['params']['externalInfo']['cardNumber'] ?? '',
+      pptId: body['params']['externalInfo']['pptId'] ??
+          body['params']['externalInfo']['RRN'] ??
+          body['params']['externalInfo']['PPTID'] ?? '',                     // RRN / PPTID
+      cashedOutFromCard: body['params']['externalInfo']['cashedOutFromCard'] ?? 0,
+      // ==================================================================
+    );
+  }
+
   /// Sale Method
   static Future saleWithOutIncom({var body}) async {
     final RequestSaleModel model = RequestSaleModel.fromJson(body);
@@ -263,25 +302,7 @@ static String cleanMarkForFiscal(String rawMark) {
     //     body['params']['externalInfo']['qrPaymentProvider'] ?? 0,
     //   ),
     // );
-    var extraInfo = ExtraInfo(
-      carNumber: "",
-      phoneNumber: body['params']['externalInfo']['phoneNumber'] ?? '',
-      cardType: body['params']['externalInfo']['cardType'],
-      pinfl: "",
-      tin: "",
-      qrPaymentID: body['params']['externalInfo']['qrPaymentID'] ?? '',
-      qrPaymentProvider: int.tryParse(
-        body['params']['externalInfo']['qrPaymentProvider']?.toString() ?? '0',
-      ) ?? 0,
-
-      // ==================== YANGI QO‘SHILGAN MAYDONLAR ====================
-      cardNumber: body['params']['externalInfo']['cardNumber'] ?? '',
-      pptId: body['params']['externalInfo']['pptId'] ??
-          body['params']['externalInfo']['RRN'] ??
-          body['params']['externalInfo']['PPTID'] ?? '',                     // RRN / PPTID
-      cashedOutFromCard: body['params']['externalInfo']['cashedOutFromCard'] ?? 0,
-      // ==================================================================
-    );
+    var extraInfo = extraInfoFromBody(body);
     FiscalReceiptModel receiptModel = FiscalReceiptModel.fromRequest(
       model,
       dataModel,
```

### 6.7. `lib/changes/services/payment/payme_service.dart`

```diff
diff --git a/lib/changes/services/payment/payme_service.dart b/lib/changes/services/payment/payme_service.dart
index 8a6b3dd..858b84a 100644
--- a/lib/changes/services/payment/payme_service.dart
+++ b/lib/changes/services/payment/payme_service.dart
@@ -135,15 +135,18 @@ class PaymeGOService {
     );
   }
 
+  /// [paymeReceiptId] — shu chekning Payme Go cheki ID'si
+  /// (`ReceiptEpay.paymeReceiptId`), Pref `p_id` dagi oxirgisi emas.
   static Future setFiscalData2({
     int statusCode = 0,
     Info? info,
+    required String paymeReceiptId,
   }) async {
     return await _post(
       api: "/api HTTP/1.1",
       method: "receipts.set_fiscal_data",
       params: {
-        "id": Pref.getString('p_id', ""),
+        "id": paymeReceiptId,
         "fiscal_data": {
           "receipt_id": int.parse(info?.receiptSeq ?? "0"),
           "qr_code_url": info?.qrCodeUrl,
```

### 6.8. `lib/changes/services/receipt_api_4.dart`

```diff
diff --git a/lib/changes/services/receipt_api_4.dart b/lib/changes/services/receipt_api_4.dart
index ad4b6a4..ea5b463 100644
--- a/lib/changes/services/receipt_api_4.dart
+++ b/lib/changes/services/receipt_api_4.dart
@@ -253,6 +253,8 @@ class ReceiptApi4 {
 
     receipt.soldItemList.addAll(r.soldItemList);
     receipt.payment.addAll(paymentMap.values);
+    // Fiskal ExtraInfo va provayder ID'lari (saleOnOFD shu nusxadan o'qiydi).
+    receipt.epayJson = r.epayJson;
     // Savatda o'chirilgan mahsulotlar ro'yxati serverga ketadigan nusxada
     // ham saqlanadi ("deleted_items" massivi).
     receipt.deletedItemsJson =
```

### 6.9. `lib/features/checks/features/check_view/bloc/pre_ofd/preofd_bloc.dart`

```diff
diff --git a/lib/features/checks/features/check_view/bloc/pre_ofd/preofd_bloc.dart b/lib/features/checks/features/check_view/bloc/pre_ofd/preofd_bloc.dart
index 18087da..380ee83 100644
--- a/lib/features/checks/features/check_view/bloc/pre_ofd/preofd_bloc.dart
+++ b/lib/features/checks/features/check_view/bloc/pre_ofd/preofd_bloc.dart
@@ -25,48 +25,8 @@ class PreOfdBloc extends Bloc<PreOfdEvent, PreOfdState> {
     final String character =
         Pref.getString(PrefKeys.checkId, "not initialized");
     bool ofd = Pref.getBool(PrefKeys.withOFD, false);
-    final newReceiptModel41 = ReceiptModel4(
-      supplierId: event.receiptModel4.supplierId,
-      newid: event.receiptModel4.newid,
-      clientPhone: event.clientNumber,
-      cashierId: event.receiptModel4.cashierId,
-      cashierName: event.receiptModel4.cashierName,
-      date: DateTime.now().millisecondsSinceEpoch,
-      isRefund: false,
-      comment: event.receiptModel4.comment,
-      fiscalSign: event.receiptModel4.fiscalSign,
-      receiptSeq: event.receiptModel4.receiptSeq,
-      terminalId: event.receiptModel4.terminalId,
-      totalPrice: _getRightTotalPrice(event.receiptModel4.soldItemList),
-      uploaded: false,
-      clientName: event.receiptModel4.clientName,
-      clientId: event.receiptModel4.clientId,
-      cashback: 0,
-      sdacha: 0,
-      returnForCheck: event.receiptModel4.returnForCheck,
-      posName: event.receiptModel4.posName,
-      refundInfo: event.receiptModel4.refundInfo,
-      commissionTIN: event.receiptModel4.commissionTIN,
-      isDonate: Pref.getBool('donate', false),
-      createdDate: event.receiptModel4.createdDate,
-      orderId: event.receiptModel4.orderId,
-      cashboxId: event.receiptModel4.cashboxId,
-      externalId: event.receiptModel4.externalId,
-      orderType: event.receiptModel4.orderType,
-      shopId: event.receiptModel4.shopId,
-      userId: event.receiptModel4.userId,
-      discountVat: event.receiptModel4.discountVat,
-      discountID: event.receiptModel4.discountID,
-      rejected: event.receiptModel4.rejected,
-      url: event.receiptModel4.url,
-    );
-    newReceiptModel41.id = event.receiptModel4.id;
-    newReceiptModel41.rejected = event.receiptModel4.rejected;
-    newReceiptModel41.uploaded = event.receiptModel4.uploaded;
-    newReceiptModel41.payment.clear();
-    newReceiptModel41.soldItemList.clear();
-    newReceiptModel41.payment.addAll(event.receiptModel4.payment);
-    newReceiptModel41.soldItemList.addAll(event.receiptModel4.soldItemList);
+    final newReceiptModel41 =
+        receiptForResend(event.receiptModel4, event.clientNumber);
 
     if (ofd) {
       emit(PreOfdLoadingState(message: ReturnMessage.internet));
@@ -122,7 +82,58 @@ class PreOfdBloc extends Bloc<PreOfdEvent, PreOfdState> {
     }
   }
 
-  double _getRightTotalPrice(List<ReceiptModelSoldItem4> v) {
+  /// Fiskalga qayta yuboriladigan nusxa (asl chek o'rniga `box.put` bilan
+  /// yoziladi). `_preOfd` dan ajratildi — tana o'zgarmagan; testlar uchun.
+  static ReceiptModel4 receiptForResend(ReceiptModel4 src, String clientNumber) {
+    final newReceiptModel41 = ReceiptModel4(
+      supplierId: src.supplierId,
+      newid: src.newid,
+      clientPhone: clientNumber,
+      cashierId: src.cashierId,
+      cashierName: src.cashierName,
+      date: DateTime.now().millisecondsSinceEpoch,
+      isRefund: false,
+      comment: src.comment,
+      fiscalSign: src.fiscalSign,
+      receiptSeq: src.receiptSeq,
+      terminalId: src.terminalId,
+      totalPrice: _getRightTotalPrice(src.soldItemList),
+      uploaded: false,
+      clientName: src.clientName,
+      clientId: src.clientId,
+      cashback: 0,
+      sdacha: 0,
+      returnForCheck: src.returnForCheck,
+      posName: src.posName,
+      refundInfo: src.refundInfo,
+      commissionTIN: src.commissionTIN,
+      isDonate: Pref.getBool('donate', false),
+      createdDate: src.createdDate,
+      orderId: src.orderId,
+      cashboxId: src.cashboxId,
+      externalId: src.externalId,
+      orderType: src.orderType,
+      shopId: src.shopId,
+      userId: src.userId,
+      discountVat: src.discountVat,
+      discountID: src.discountID,
+      rejected: src.rejected,
+      url: src.url,
+    );
+    newReceiptModel41.id = src.id;
+    newReceiptModel41.rejected = src.rejected;
+    newReceiptModel41.uploaded = src.uploaded;
+    newReceiptModel41.payment.clear();
+    newReceiptModel41.soldItemList.clear();
+    newReceiptModel41.payment.addAll(src.payment);
+    // Shu chekning o'z to'lov ID'lari — xotiradagi oxirgi to'lovniki emas.
+    // box.put shu nusxani asl chek o'rniga yozadi, shuning uchun yo'qolmasin.
+    newReceiptModel41.epayJson = src.epayJson;
+    newReceiptModel41.soldItemList.addAll(src.soldItemList);
+    return newReceiptModel41;
+  }
+
+  static double _getRightTotalPrice(List<ReceiptModelSoldItem4> v) {
     double t = 0;
     for (var element in v) {
       t += element.price * element.value;
```

### 6.10. `lib/changes/providers/ordering_provider_4.dart` (faqat `e5ba429`; shu fayldagi savat o'zgarishlari — 10-TASK)

```diff
diff --git a/lib/changes/providers/ordering_provider_4.dart b/lib/changes/providers/ordering_provider_4.dart
index a9d3252..e98a874 100644
--- a/lib/changes/providers/ordering_provider_4.dart
+++ b/lib/changes/providers/ordering_provider_4.dart
@@ -64,6 +64,7 @@ import 'package:invan2/features/home/features/home_orders/calculation_part/total
 import 'package:invan2/features/payment/right/complete_button/uzum_pay_bloc/uzum_pay_bloc.dart';
 import 'package:invan2/features/payment/right/dilogs/click/bloc/click_bloc.dart';
 import 'package:invan2/changes/services/payment/paynet_service.dart';
+import 'package:invan2/changes/services/payment/epay_capture.dart';
 import 'package:invan2/features/payment/right/dilogs/paynet/bloc/paynet_bloc.dart';
 import 'package:invan2/features/payment/right/dilogs/paynet/paynet_dialog.dart';
 import 'package:invan2/features/payment/right/dilogs/click/clic_pass_dialog.dart';
@@ -1781,6 +1782,9 @@ class OrderingProvider4 extends ChangeNotifier {
       orphanDeletedItems: _orphanDeletedItems,
       isTpEdited: isTpEdited,
     );
+    // Shu chekdagi Pass/Go to'lov ID'lari — keyin cheklar ro'yxatidan
+    // fiskalga yuborilganda ham aynan shular ishlatiladi.
+    receiptModel4.epayJson = EpayCapture.forReceipt(receiptModel4);
     if (receiptModel4.payment.isNotEmpty &&
         receiptModel4.soldItemList.isNotEmpty) {
       await ReceiptSingleton4.toOBJECTBOX(
@@ -1855,6 +1859,7 @@ class OrderingProvider4 extends ChangeNotifier {
       lastCardNumber: _lastCardNumber,
       lastRRN: _lastRRN,
     );
+    receiptModel4.epayJson = EpayCapture.forReceipt(receiptModel4);
 
     if (receiptModel4.soldItemList.isEmpty) {
       LogHelper.write(
@@ -1960,7 +1965,9 @@ class OrderingProvider4 extends ChangeNotifier {
     _isOfdWithOfd = false;
     _clickPassPaid = false;
     _paymePaid = false;
-    PaynetService.paymentId = null;
+    // Oldingi sotuvning Click/Payme/Uzum/Paynet to'lov ID'lari va fiskal
+    // ExtraInfo qoldig'i yangi chekka tushmasin.
+    EpayCapture.reset();
   }
 
   late bool _paymentInProgress;
```

### 6.11. Testlar

<details><summary><code>test/receipt_vat_test.dart</code> (<code>f007377</code>, diff)</summary>

```diff
diff --git a/test/receipt_vat_test.dart b/test/receipt_vat_test.dart
index 89d151d..1416aa2 100644
--- a/test/receipt_vat_test.dart
+++ b/test/receipt_vat_test.dart
@@ -8,8 +8,9 @@
 //   2) chek jami QQS'i fiskal ΣVAT bilan (qator boshiga ≤ 1 so'm yaxlitlash)
 //      mos — cashback, chegirma, ko'p qator, QQS 0%, vozvrat;
 //   3) qator QQS'i aniq raqamlarda; blok/dona bo'linganda yig'indi saqlanadi.
-// Click/Payme/Uzum: fiskalda hozircha Other (VAT 0), chekda ayrilmaydi —
-// ataylab, alohida masala (§6.1). Bu farq ham testda qayd etilgan.
+// Click Pass / Payme Go: fiskalda ReceivedCard (QQS to'liq), chek bilan mos.
+// Click QR / Payme QR / Uzum: fiskalda Other (VAT 0), chekda ayrilmaydi —
+// ataylab (§6.1). Bu farq ham testda qayd etilgan.
 import 'dart:convert';
 
 import 'package:flutter_test/flutter_test.dart';
@@ -58,9 +59,14 @@ ReceiptModelPaymentType4 pay(String name, String payId, double v) =>
 ReceiptModelPaymentType4 cash(double v) => pay('CASH', kCashId, v);
 ReceiptModelPaymentType4 card(double v) => pay('CARD', kCardId, v);
 ReceiptModelPaymentType4 cashback(double v) => pay('Cashback', kCashbackId, v);
-ReceiptModelPaymentType4 click(double v) => pay('Click', kClickId, v);
-ReceiptModelPaymentType4 payme(double v) => pay('Payme', kPaymeId, v);
-ReceiptModelPaymentType4 uzum(double v) => pay('Uzum', kUzumId, v);
+// Nomlar/IDlar `ReceiptPayments.build` natijasidagidek: Pass/Go — '@' siz,
+// QR (`type: 1`) — '@id'.
+ReceiptModelPaymentType4 clickPass(double v) => pay('CLICK PASS', kClickId, v);
+ReceiptModelPaymentType4 clickQr(double v) => pay('CLICK QR', '@$kClickId', v);
+ReceiptModelPaymentType4 paymeGo(double v) => pay('PAYME GO', kPaymeId, v);
+ReceiptModelPaymentType4 paymeQr(double v) => pay('PAYME QR', '@$kPaymeId', v);
+ReceiptModelPaymentType4 uzum(double v) => pay('UZUM', kUzumId, v);
+ReceiptModelPaymentType4 uzumQr(double v) => pay('UZUM QR', '@$kUzumId', v);
 
 ReceiptModel4 receiptWith(
   List<ReceiptModelSoldItem4> rows, {
@@ -219,14 +225,35 @@ void main() {
       expectSplitMatchesWire(r);
     });
 
-    test('Click / Payme / Uzum: ID + nom mos bo\'lsa epay', () {
-      for (final p in [click(50000), payme(50000), uzum(50000)]) {
+    test('Click QR / Payme QR / Uzum (Pass ham, QR ham) → epay (Other)', () {
+      for (final p in [clickQr(50000), paymeQr(50000), uzum(50000), uzumQr(50000)]) {
         final r = receiptWith([row(realPrice: 50000)], payments: [p]);
-        expect(FiscalPaymentSplit.of(r).epay, 50000, reason: p.name);
+        final s = FiscalPaymentSplit.of(r);
+        expect(s.epay, 50000, reason: p.name);
+        expect(s.card, 0, reason: p.name);
         expectSplitMatchesWire(r);
       }
     });
 
+    test('Click Pass / Payme Go → karta (ReceivedCard), Other 0', () {
+      for (final p in [clickPass(50000), paymeGo(50000)]) {
+        final r = receiptWith([row(realPrice: 50000)], payments: [p]);
+        final s = FiscalPaymentSplit.of(r);
+        expect(s.card, 50000, reason: p.name);
+        expect(s.epay, 0, reason: p.name);
+        final w = wireOf(r);
+        expect(receiptPart(w)['ReceivedCard'], 5000000, reason: p.name);
+        expect(sumOf(w, 'Other'), 0, reason: p.name);
+        expectSplitMatchesWire(r);
+      }
+    });
+
+    test('QR: serverdan qaytgan chekda \'@\' yo\'q, lekin nomi QR → epay', () {
+      final r = receiptWith([row(realPrice: 50000)],
+          payments: [pay('CLICK QR', kClickId, 50000)]);
+      expect(FiscalPaymentSplit.of(r).epay, 50000);
+    });
+
     test('Click ID bor, lekin nomi mos emas → karta (fallback)', () {
       final r = receiptWith([row(realPrice: 50000)], payments: [pay('Boshqa', kClickId, 50000)]);
       expect(FiscalPaymentSplit.of(r).card, 50000);
@@ -239,10 +266,10 @@ void main() {
       expectSplitMatchesWire(r);
     });
 
-    test('aralash: naqd + karta + cashback + click', () {
+    test('aralash: naqd + karta + cashback + click QR', () {
       final r = receiptWith(
         [row(realPrice: 100000)],
-        payments: [cash(40000), card(30000), cashback(20000), click(10000)],
+        payments: [cash(40000), card(30000), cashback(20000), clickQr(10000)],
       );
       final s = FiscalPaymentSplit.of(r);
       expect(s.cash, 40000);
@@ -252,6 +279,18 @@ void main() {
       expectSplitMatchesWire(r);
     });
 
+    test('aralash: naqd + Click Pass + Payme QR', () {
+      final r = receiptWith(
+        [row(realPrice: 100000)],
+        payments: [cash(40000), clickPass(35000), paymeQr(25000)],
+      );
+      final s = FiscalPaymentSplit.of(r);
+      expect(s.cash, 40000);
+      expect(s.card, 35000);
+      expect(s.epay, 25000);
+      expectSplitMatchesWire(r);
+    });
+
     test('vozvrat: hammasi naqd, to\'lov turidan qat\'iy nazar', () {
       final r = receiptWith(
         [row(realPrice: 50000)],
@@ -342,16 +381,53 @@ void main() {
       expectPaperMatchesFiscal(r);
     });
 
-    test('QAYD: Click bilan to\'langanda chekda QQS to\'liq, fiskalda 0 (hozircha)', () {
-      // Fiskal Click'ni Other'ga yozadi (§6.1 — alohida masala, tegilmadi).
-      // Chek uni ayirmaydi: rasmiy talab bo'yicha Click = karta, QQS to'liq.
-      final r = receiptWith([row(realPrice: 50000)], payments: [click(50000)]);
+    test('Click Pass / Payme Go: chek va fiskal QQS to\'liq, mos', () {
+      for (final p in [clickPass(50000), paymeGo(50000)]) {
+        final r = receiptWith([row(realPrice: 50000)], payments: [p]);
+        expect(ReceiptVat.total(r), closeTo(5357.14, 0.01), reason: p.name);
+        expect(sumOf(wireOf(r), 'VAT'), closeTo(535714, 1), reason: p.name);
+        expectPaperMatchesFiscal(r);
+      }
+    });
+
+    test('QAYD: Click QR bilan to\'langanda chekda QQS to\'liq, fiskalda 0', () {
+      // Fiskal QR'ni Other'ga yozadi (§6.1 — ataylab o'zgartirilmagan).
+      final r = receiptWith([row(realPrice: 50000)], payments: [clickQr(50000)]);
       expect(ReceiptVat.paperOtherTotal(r), 0);
       expect(ReceiptVat.total(r), closeTo(5357.14, 0.01));
       expect(sumOf(wireOf(r), 'VAT'), 0);
     });
   });
 
+  group('receivedClick/Payme/Uzum — provayderga fiskal URL faqat Pass/Go da', () {
+    Map<String, dynamic> paramsOf(ReceiptModel4 r) =>
+        ReceiptSingleton4.saleOnOFD(r)['params'] as Map<String, dynamic>;
+
+    test('Pass/Go → true', () {
+      expect(paramsOf(receiptWith([row(realPrice: 50000)],
+          payments: [clickPass(50000)]))['receivedClick'], true);
+      expect(paramsOf(receiptWith([row(realPrice: 50000)],
+          payments: [paymeGo(50000)]))['receivedPayme'], true);
+      expect(paramsOf(receiptWith([row(realPrice: 50000)],
+          payments: [uzum(50000)]))['receivedUzum'], true);
+    });
+
+    test('QR → false (ilgari true edi va eski payment ID bilan yuborilardi)', () {
+      final p = paramsOf(receiptWith([row(realPrice: 90000)],
+          payments: [clickQr(30000), paymeQr(30000), uzumQr(30000)]));
+      expect(p['receivedClick'], false);
+      expect(p['receivedPayme'], false);
+      expect(p['receivedUzum'], false);
+    });
+
+    test('naqd → hammasi false', () {
+      final p = paramsOf(receiptWith([row(realPrice: 50000)]));
+      expect(p['receivedClick'], false);
+      expect(p['receivedPayme'], false);
+      expect(p['receivedUzum'], false);
+    });
+  });
+
   group('ReceiptVat.lineVat — qator va blok/dona bo\'linishi', () {
     test('qty berilmasa to\'liq qator', () {
       expect(ReceiptVat.lineVat(row(realPrice: 50000, value: 2)),
```

</details>

<details><summary>YANGI: <code>test/receipt_epay_test.dart</code></summary>

```dart
// ReceiptEpay — elektron to'lov ID'lari chekning o'zida (2026-10-02).
//
// Tuzatilgan ikki muammo:
//   1. Fiskal ExtraInfo (QRPaymentProvider/QRPaymentID/PhoneNumber) global
//      Pref'dan olinardi → oldingi Click/Payme/Uzum to'lovining ID'si keyingi
//      (hatto naqd) chekka ham ketardi.
//   2. Cheklar ro'yxatidan fiskalga qayta yuborilganda (PreOfd) provayderga
//      chekning emas, xotiradagi oxirgi to'lov ID'si ketardi.
//
// Testlar: sof qoida (capture / encode / targets), fiskal JSON'dagi ExtraInfo,
// nusxalash yo'llari (ReceiptApi4.func, PreOfd), servis holati bilan to'liq
// sotuv stsenariylari (EpayCapture).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/receipt/receipt_epay.dart';
import 'package:invan2/changes/services/payment/click_service.dart';
import 'package:invan2/changes/services/payment/epay_capture.dart';
import 'package:invan2/changes/services/payment/paynet_service.dart';
import 'package:invan2/changes/services/payment/uzum_service.dart';
import 'package:invan2/changes/services/receipt_api_4.dart';
import 'package:invan2/features/checks/features/check_view/bloc/pre_ofd/preofd_bloc.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/epay_fixtures.dart';
import 'support/provider_harness.dart';

const kPaynetId = 'pay-paynet';

ReceiptModelPaymentType4 paynet(double v, {bool qr = false}) =>
    ReceiptModelPaymentType4(
        name: qr ? 'PAYNET QR' : 'PAYNET',
        payId: qr ? '@$kPaynetId' : kPaynetId,
        value: v);

/// To'lov sahifasidagi holat — servislar to'lovdan keyin qanday qoldiradi.
void simulateClickPaid(String id, {String phone = '998901111111'}) {
  ClickService.paymentId = id;
  Pref.setString('epay_Id', id);
  Pref.setInt('epayPay_Id', 64);
  Pref.setString('epay_phone', phone);
}

void simulatePaymePaid(String id, {String phone = '998902222222'}) {
  Pref.setString('p_id', id);
  Pref.setString('epay_Id', id);
  Pref.setInt('epayPay_Id', 141);
  Pref.setString('epay_phone', phone);
}

void simulateUzumPaid(String id, {String phone = '998903333333'}) {
  UzumService.paymentId = id;
  Pref.setString('epay_Id', id);
  Pref.setInt('epayPay_Id', 161);
  Pref.setString('epay_phone', phone);
}

/// ClickService.post `submit_qrcode` javobida Pref'ni qayta yozadi (fiskal
/// tozalashdan KEYIN keladi) — eski xatoning manbai.
void simulateLateClickSubmitResponse() {
  Pref.setString('epay_Id', '');
  Pref.setInt('epayPay_Id', 64);
  Pref.setString('epay_phone', '');
}

ReceiptModel4 sale(Map<Kind, double> amounts,
    {List<ReceiptModelPaymentType4> extra = const []}) {
  final double total =
      amounts.values.fold<double>(0, (a, b) => a + b) +
          extra.fold<double>(0, (a, p) => a + p.value);
  return receiptOf([row(realPrice: total)],
      [...buildPayments(amounts), ...extra]);
}

/// Fiskal modulga ketadigan ExtraInfo.
Map<String, dynamic> extraOf(ReceiptModel4 r) =>
    receiptPart(wireOf(r))['ExtraInfo'] as Map<String, dynamic>;

ReceiptEpay capture(
  ReceiptModel4 r, {
  String? click,
  String? payme,
  String? uzum,
  int? paynetPid,
  int last = 0,
  String phone = '',
}) =>
    ReceiptEpay.capture(
      receipt: r,
      clickId: ids.click,
      paymeId: ids.payme,
      uzumId: ids.uzum,
      paynetId: kPaynetId,
      clickPaymentId: click,
      paymeReceiptId: payme,
      uzumPaymentId: uzum,
      paynetPaymentId: paynetPid,
      lastProvider: last,
      lastPhone: phone,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('receipt_epay', withEmployee: false);
    await Pref.setString(PrefKeys.mxikCode, kMxik);
    await Pref.setString(PrefKeys.cashId, ids.cash);
    await Pref.setString(PrefKeys.cardId, ids.card);
    await Pref.setString(PrefKeys.cashbackId, ids.cashback);
    await Pref.setString(PrefKeys.clickId, ids.click);
    await Pref.setString(PrefKeys.paymeId, ids.payme);
    await Pref.setString(PrefKeys.uzumId, ids.uzum);
    await Pref.setString(PrefKeys.paynetId, kPaynetId);
  });

  setUp(EpayCapture.reset);

  group('ReceiptEpay.capture — faqat shu chekdagi Pass/Go', () {
    test('naqd chek: manbalarda eski ID bo\'lsa ham bo\'sh', () {
      final e = capture(sale({Kind.cash: 50000}),
          click: 'OLD-C', payme: 'OLD-P', uzum: 'OLD-U', paynetPid: 9,
          last: 64, phone: '998900000000');
      expect(e.isEmpty, isTrue);
      expect(e.encode(), isNull);
    });

    test('har bir to\'lov turi yakka: faqat Pass/Go ID oladi', () {
      for (final k in Kind.values) {
        final e = capture(sale({k: 50000}),
            click: 'C1', payme: 'P1', uzum: 'U1', last: 0);
        final why = k.name;
        expect(e.clickPaymentId, k == Kind.clickPass ? 'C1' : '', reason: why);
        expect(e.paymeReceiptId, k == Kind.paymeGo ? 'P1' : '', reason: why);
        expect(e.uzumPaymentId, k == Kind.uzum ? 'U1' : '', reason: why);
        final int provider = const {
              Kind.clickPass: 64,
              Kind.paymeGo: 141,
              Kind.uzum: 161,
            }[k] ??
            0;
        expect(e.qrPaymentProvider, provider, reason: why);
        expect(e.qrPaymentId, provider == 0 ? '' : isNotEmpty, reason: why);
      }
    });

    test('Click Pass: ExtraInfo 64 + ID + telefon (oxirgi to\'lov Click)', () {
      final e = capture(sale({Kind.clickPass: 50000}),
          click: '123456', last: 64, phone: '998901234567');
      expect(e.qrPaymentProvider, 64);
      expect(e.qrPaymentId, '123456');
      expect(e.phoneNumber, '998901234567');
    });

    test('Click QR: eski ClickService ID\'si bo\'lsa ham olinmaydi', () {
      final e = capture(sale({Kind.clickQr: 50000}), click: 'OLD', last: 64);
      expect(e.isEmpty, isTrue);
    });

    test('Payme Go + Click Pass: ExtraInfo oxirgi to\'langan provayder, ikkala ID saqlanadi',
        () {
      final r = sale({Kind.clickPass: 20000, Kind.paymeGo: 30000});
      final e = capture(r, click: 'C', payme: 'P', last: 141, phone: '99890');
      expect(e.qrPaymentProvider, 141);
      expect(e.qrPaymentId, 'P');
      expect(e.phoneNumber, '99890');
      expect(e.clickPaymentId, 'C');
      expect(e.paymeReceiptId, 'P');
    });

    test('oxirgi provayder noma\'lum: Click → Payme → Uzum tartibi, telefon yo\'q',
        () {
      final r = sale({Kind.paymeGo: 20000, Kind.uzum: 30000, Kind.clickPass: 1});
      final e = capture(r, click: 'C', payme: 'P', uzum: 'U', last: 0,
          phone: '99890');
      expect(e.qrPaymentProvider, 64);
      expect(e.phoneNumber, '');
    });

    test('Pref\'dagi oxirgi provayder chekda yo\'q: uning telefoni oqib ketmaydi',
        () {
      final e = capture(sale({Kind.clickPass: 50000}),
          click: 'C', last: 141, phone: 'PAYME-PHONE');
      expect(e.qrPaymentProvider, 64);
      expect(e.phoneNumber, '');
    });

    test('Pass bor, lekin ID yo\'q (to\'lov ID\'si olinmagan): ExtraInfo bo\'sh',
        () {
      for (final id in [null, '', '   ']) {
        final e = capture(sale({Kind.clickPass: 50000}), click: id, last: 64);
        expect(e.qrPaymentProvider, 0, reason: '"$id"');
        expect(e.clickPaymentId, '', reason: '"$id"');
      }
    });

    test('ID atrofidagi bo\'shliq olib tashlanadi', () {
      final e = capture(sale({Kind.clickPass: 50000}), click: ' 77 ');
      expect(e.clickPaymentId, '77');
    });

    test('Paynet (Pass ham, QR ham): ID chekda Paynet bo\'lsa saqlanadi', () {
      for (final qr in [false, true]) {
        final r = sale({}, extra: [paynet(50000, qr: qr)]);
        expect(capture(r, paynetPid: 555).paynetPaymentId, 555, reason: 'qr=$qr');
        expect(capture(r, paynetPid: null).paynetPaymentId, isNull);
        expect(capture(r, paynetPid: 0).paynetPaymentId, isNull);
      }
      expect(capture(sale({Kind.cash: 1}), paynetPid: 555).paynetPaymentId,
          isNull,
          reason: 'chekda Paynet yo\'q — eski ID olinmaydi');
    });

    test('vozvrat: hech narsa olinmaydi', () {
      final r = receiptOf([row(realPrice: 50000)],
          buildPayments({Kind.clickPass: 50000}),
          isRefund: true);
      expect(capture(r, click: 'C', last: 64).isEmpty, isTrue);
    });
  });

  group('encode / decode', () {
    test('to\'liq qaytish (round-trip)', () {
      const e = ReceiptEpay(
        qrPaymentProvider: 141,
        qrPaymentId: 'P',
        phoneNumber: '998',
        clickPaymentId: 'C',
        paymeReceiptId: 'P',
        uzumPaymentId: 'U',
        paynetPaymentId: 42,
      );
      final d = ReceiptEpay.decode(e.encode());
      expect(d.toJson(), e.toJson());
    });

    test('null / bo\'sh / buzilgan / boshqa tur → bo\'sh, xato tashlamaydi', () {
      for (final raw in [null, '', '{', '[]', '"x"', 'null', '{"qrPaymentProvider":"abc"}']) {
        expect(() => ReceiptEpay.decode(raw), returnsNormally, reason: '$raw');
      }
      expect(ReceiptEpay.decode(null).isEmpty, isTrue);
      expect(ReceiptEpay.decode('{').isEmpty, isTrue);
      expect(ReceiptEpay.decode('[]').isEmpty, isTrue);
    });

    test('kalitlari yetishmagan JSON: mavjudi o\'qiladi', () {
      final d = ReceiptEpay.decode('{"clickPaymentId":"C"}');
      expect(d.clickPaymentId, 'C');
      expect(d.qrPaymentProvider, 0);
      expect(d.paynetPaymentId, isNull);
    });
  });

  group('targets — fiskal URL qaysi provayderga qaytariladi', () {
    const full = ReceiptEpay(
        clickPaymentId: 'C', paymeReceiptId: 'P', uzumPaymentId: 'U',
        paynetPaymentId: 1);

    test('bayroq + ID → yuboriladi', () {
      expect(
          full.targets({
            'receivedClick': true,
            'receivedPayme': true,
            'receivedUzum': true,
            'receivedPaynet': true,
          }),
          EpayTarget.values.toSet());
    });

    test('bayroq bor, ID yo\'q (eski chek) → yuborilmaydi', () {
      expect(
          ReceiptEpay.empty.targets({
            'receivedClick': true,
            'receivedPayme': true,
            'receivedUzum': true,
            'receivedPaynet': true,
          }),
          isEmpty);
    });

    test('ID bor, bayroq yo\'q (QR yoki naqd) → yuborilmaydi', () {
      expect(
          full.targets({
            'receivedClick': false,
            'receivedPayme': false,
            'receivedUzum': false,
            'receivedPaynet': false,
          }),
          isEmpty);
      expect(full.targets(<String, dynamic>{}), isEmpty);
    });

    test('haqiqiy saleOnOFD params bilan: Click Pass + Payme QR → faqat Click', () {
      final r = sale({Kind.clickPass: 20000, Kind.paymeQr: 30000});
      r.epayJson = capture(r, click: 'C', payme: 'STALE').encode();
      final params = paramsOf(r);
      expect(ReceiptEpay.decode(r.epayJson).targets(params), {EpayTarget.click});
    });
  });

  group('Fiskal JSON ExtraInfo — chekdan, Pref\'dan emas', () {
    test('naqd chek, Pref\'da oldingi Click qoldig\'i: ExtraInfo bo\'sh', () {
      simulateClickPaid('OLD-111');
      simulateLateClickSubmitResponse();
      Pref.setString('epay_Id', 'OLD-111');
      final x = extraOf(sale({Kind.cash: 50000}));
      expect(x['QRPaymentProvider'], 0);
      expect(x['QRPaymentID'], '');
      expect(x['PhoneNumber'], '');
    });

    test('Click Pass chek: ExtraInfo chekdagi ID, Pref\'da boshqa to\'lov bo\'lsa ham',
        () {
      final r = sale({Kind.clickPass: 50000});
      r.epayJson = capture(r, click: 'C-1', last: 64, phone: '998901').encode();
      simulatePaymePaid('OTHER'); // keyingi mijozning to'lovi
      final x = extraOf(r);
      expect(x['QRPaymentProvider'], 64);
      expect(x['QRPaymentID'], 'C-1');
      expect(x['PhoneNumber'], '998901');
    });

    test('har bir Pass/Go turi: provayder kodi to\'g\'ri', () {
      const codes = {Kind.clickPass: 64, Kind.paymeGo: 141, Kind.uzum: 161};
      for (final k in codes.keys) {
        final int code = codes[k]!;
        final r = sale({k: 50000});
        r.epayJson =
            capture(r, click: 'C', payme: 'P', uzum: 'U', last: code).encode();
        expect(extraOf(r)['QRPaymentProvider'], code, reason: k.name);
      }
    });

    test('QR chek: ExtraInfo bo\'sh, pul Other\'da (o\'zgarishsiz)', () {
      for (final k in [Kind.clickQr, Kind.paymeQr, Kind.uzumQr]) {
        final r = sale({k: 50000});
        r.epayJson = capture(r, click: 'X', payme: 'X', uzum: 'X').encode();
        expect(r.epayJson, isNull, reason: k.name);
        expect(extraOf(r)['QRPaymentProvider'], 0, reason: k.name);
        expect(sumOf(wireOf(r), 'Other'), 5000000, reason: k.name);
      }
    });

    test('vozvrat: chekda epayJson bo\'lsa ham ExtraInfo bo\'sh', () {
      final r = receiptOf([row(realPrice: 50000)],
          [ReceiptModelPaymentType4(name: 'CASH', payId: ids.cash, value: 50000)],
          isRefund: true);
      r.epayJson = const ReceiptEpay(
              qrPaymentProvider: 64, qrPaymentId: 'C', clickPaymentId: 'C')
          .encode();
      final x = extraOf(r);
      expect(x['QRPaymentProvider'], 0);
      expect(x['QRPaymentID'], '');
    });

    test('ExtraInfo qo\'shilishi pul maydonlarini o\'zgartirmaydi', () {
      final r = sale({Kind.clickPass: 30000, Kind.cash: 20000});
      final before = jsonEncode(receiptPart(wireOf(r))['Items']);
      r.epayJson = capture(r, click: 'C', last: 64, phone: '9').encode();
      final w = wireOf(r);
      expect(jsonEncode(receiptPart(w)['Items']), before);
      expect(receiptPart(w)['ReceivedCard'], 3000000);
      expect(receiptPart(w)['ReceivedCash'], 2000000);
    });
  });

  group('Nusxalash yo\'llari epayJson\'ni yo\'qotmaydi', () {
    test('ReceiptApi4.func (saleOnOFD ishlatadi)', () {
      final r = sale({Kind.clickPass: 50000});
      r.epayJson = capture(r, click: 'C').encode();
      expect(ReceiptApi4.func(r).epayJson, r.epayJson);
    });

    test('PreOfdBloc.receiptForResend', () {
      final r = sale({Kind.paymeGo: 50000});
      r.epayJson = capture(r, payme: 'P').encode();
      final copy = PreOfdBloc.receiptForResend(r, '');
      expect(copy.epayJson, r.epayJson);
      expect(copy.payment.map((p) => p.payId), r.payment.map((p) => p.payId));
    });

    test('eski chek (epayJson null) nusxada ham null', () {
      final r = sale({Kind.clickPass: 50000});
      expect(PreOfdBloc.receiptForResend(r, '').epayJson, isNull);
      expect(ReceiptApi4.func(r).epayJson, isNull);
    });
  });

  group('Click payload — payment_id chekdan', () {
    test('fromReceipt4ToClick ClickService.paymentId ni emas, berilganini oladi',
        () {
      ClickService.paymentId = '999999';
      final r = sale({Kind.clickPass: 50000});
      final data = ReceiptSingleton4.fromReceipt4ToClick(
          receipt: ReceiptSingleton4.saleOnOFD(r), clickPaymentId: '123');
      expect(data['payment_id'], 123);
    });
  });

  group('EpayCapture — servis holati bilan to\'liq stsenariylar', () {
    test('reset: barcha global manbalar tozalanadi', () {
      simulateClickPaid('C');
      simulatePaymePaid('P');
      simulateUzumPaid('U');
      PaynetService.paymentId = 5;
      EpayCapture.reset();
      expect(ClickService.paymentId, isNull);
      expect(UzumService.paymentId, isNull);
      expect(PaynetService.paymentId, isNull);
      expect(Pref.getString('p_id', 'x'), '');
      expect(Pref.getInt('epayPay_Id', -1), 0);
      expect(Pref.getString('epay_Id', 'x'), '');
      expect(Pref.getString('epay_phone', 'x'), '');
    });

    test('1-muammo: Click Pass sotuvi fiskalda yiqildi → keyingi naqd chekda ExtraInfo bo\'sh',
        () {
      // Sotuv 1: Click Pass.
      simulateClickPaid('111');
      final r1 = sale({Kind.clickPass: 50000});
      r1.epayJson = EpayCapture.forReceipt(r1);
      // Fiskal yiqildi — LocalService Pref'ni tozalamadi; Click javobi ham keldi.
      simulateLateClickSubmitResponse();
      // Sotuv 2: yangi to'lov sahifasi, naqd.
      EpayCapture.reset();
      final r2 = sale({Kind.cash: 30000});
      r2.epayJson = EpayCapture.forReceipt(r2);
      expect(r2.epayJson, isNull);
      expect(extraOf(r2)['QRPaymentProvider'], 0);
      expect(extraOf(r2)['QRPaymentID'], '');
      // Sotuv 1 o'z ma'lumotini saqlab qolgan.
      expect(extraOf(r1)['QRPaymentProvider'], 64);
      expect(extraOf(r1)['QRPaymentID'], '111');
    });

    test('reset\'dan keyin ham kech kelgan Click javobi: naqd chekka 64 tushmaydi',
        () {
      EpayCapture.reset();
      simulateLateClickSubmitResponse(); // epayPay_Id = 64
      final r = sale({Kind.cash: 30000});
      r.epayJson = EpayCapture.forReceipt(r);
      expect(extraOf(r)['QRPaymentProvider'], 0);
    });

    test('Payme Go to\'lovidan keyin kech Click javobi: ExtraInfo baribir Payme',
        () {
      EpayCapture.reset();
      simulatePaymePaid('PM-2');
      simulateLateClickSubmitResponse(); // epayPay_Id 141 → 64 bo'lib qoldi
      final r = sale({Kind.paymeGo: 40000});
      r.epayJson = EpayCapture.forReceipt(r);
      final x = extraOf(r);
      expect(x['QRPaymentProvider'], 141);
      expect(x['QRPaymentID'], 'PM-2');
      expect(x['PhoneNumber'], '', reason: 'telefon kimniki ekani noma\'lum');
    });

    test('2-muammo: PreOfd qayta yuborish — provayderga chekning o\'z ID\'si', () {
      // Sotuv 1: Click Pass, fiskalsiz saqlandi.
      simulateClickPaid('111');
      final r1 = sale({Kind.clickPass: 50000});
      r1.epayJson = EpayCapture.forReceipt(r1);
      // Sotuv 2: boshqa mijoz, Click Pass 222 va Payme Go.
      EpayCapture.reset();
      simulateClickPaid('222');
      simulatePaymePaid('PM-9');
      final r2 = sale({Kind.clickPass: 10000, Kind.paymeGo: 10000});
      r2.epayJson = EpayCapture.forReceipt(r2);

      // Keyinroq cheklar ro'yxatidan sotuv 1 fiskalga qayta yuboriladi.
      final resend = PreOfdBloc.receiptForResend(r1, '');
      final body = ReceiptSingleton4.saleOnOFD(resend);
      final epay = ReceiptEpay.decode(resend.epayJson);
      expect(epay.targets(body['params']), {EpayTarget.click});
      expect(epay.clickPaymentId, '111');
      expect(
          ReceiptSingleton4.fromReceipt4ToClick(
              receipt: body, clickPaymentId: epay.clickPaymentId)['payment_id'],
          111);
      expect(extraOf(resend)['QRPaymentID'], '111');

      // Sotuv 2 o'z ID'lari bilan.
      final e2 = ReceiptEpay.decode(r2.epayJson);
      expect(e2.clickPaymentId, '222');
      expect(e2.paymeReceiptId, 'PM-9');
      expect(e2.targets(paramsOf(r2)), {EpayTarget.click, EpayTarget.payme});
    });

    test('dastur qayta ochilgandan keyin (statik ID\'lar yo\'q) qayta yuborish', () {
      simulateClickPaid('111');
      final r1 = sale({Kind.clickPass: 50000});
      r1.epayJson = EpayCapture.forReceipt(r1);
      // Qayta ishga tushish: xotira tozalandi.
      ClickService.paymentId = null;
      final resend = PreOfdBloc.receiptForResend(r1, '');
      final epay = ReceiptEpay.decode(resend.epayJson);
      expect(epay.targets(paramsOf(resend)), {EpayTarget.click});
      expect(epay.clickPaymentId, '111');
    });

    test('yangilanishdan oldingi chek (epayJson yo\'q): provayderga yuborilmaydi, ExtraInfo bo\'sh',
        () {
      ClickService.paymentId = 'SOMEONE-ELSE';
      Pref.setInt('epayPay_Id', 64);
      Pref.setString('epay_Id', 'SOMEONE-ELSE');
      final old = sale({Kind.clickPass: 50000}); // epayJson null
      final resend = PreOfdBloc.receiptForResend(old, '');
      expect(ReceiptEpay.decode(resend.epayJson).targets(paramsOf(resend)),
          isEmpty);
      expect(extraOf(resend)['QRPaymentID'], '');
      // Pul maydonlari o'zgarmagan: Pass → ReceivedCard.
      expect(receiptPart(wireOf(resend))['ReceivedCard'], 5000000);
    });

    test('Uzum Pass va Paynet: ID chekdan', () {
      simulateUzumPaid('UZ-1');
      PaynetService.paymentId = 77;
      final r = sale({Kind.uzum: 20000}, extra: [paynet(30000)]);
      r.epayJson = EpayCapture.forReceipt(r);
      final e = ReceiptEpay.decode(r.epayJson);
      expect(e.uzumPaymentId, 'UZ-1');
      expect(e.paynetPaymentId, 77);
      expect(e.qrPaymentProvider, 161);
      final params = paramsOf(r);
      expect(params['receivedPaynet'], true);
      expect(e.targets(params), {EpayTarget.uzum, EpayTarget.paynet});
    });
  });
}
```

</details>

<details><summary>YANGI: <code>test/epay_fiscal_matrix_test.dart</code></summary>

```dart
// Click Pass / Payme Go / QR / Uzum — fiskal modulga ketadigan JSON matritsasi.
//
// f007377 (Click Pass / Payme Go → ReceivedCard, QQS to'liq; QR → Other;
// receivedClick/Payme/Uzum faqat Pass/Go) ni keng qamrovda tekshiradi.
//
// receipt_vat_test.dart dan farqi: to'lovlar QO'LDA yasalmaydi — to'lov
// ekranidagi xarita (`Map<String, Payment>`, QR `type: 1` → '@id' kalit)
// haqiqiy `ReceiptPayments.build` dan o'tadi, so'ng `saleOnOFD` →
// `RequestSaleModel` → `FiscalReceiptModel.toJson` (modulga ketadigan JSON).
//
// Har bir holatda modul invariantlari:
//   - ReceivedCash / ReceivedCard / ΣOther — to'lov turiga qarab kutilgan;
//   - Σ(Price − Discount) == ReceivedCash + ReceivedCard + ΣOther (§10.2.1);
//   - har qatorda 0 ≤ Other, Other + Discount ≤ Price;
//   - VAT == (Price − Discount − Other) × p / (100 + p), 0% da 0;
//   - receivedClick / receivedPayme / receivedUzum faqat Pass/Go bo'lsa.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'dart:convert';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import 'support/epay_fixtures.dart';
import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('epay_fiscal_matrix', withEmployee: false);
    await Pref.setString(PrefKeys.mxikCode, kMxik);
    await Pref.setString(PrefKeys.cashId, ids.cash);
    await Pref.setString(PrefKeys.cardId, ids.card);
    await Pref.setString(PrefKeys.cashbackId, ids.cashback);
    await Pref.setString(PrefKeys.clickId, ids.click);
    await Pref.setString(PrefKeys.paymeId, ids.payme);
    await Pref.setString(PrefKeys.uzumId, ids.uzum);
  });

  group('ReceiptPayments.build — to\'lov ekranidan chekka nomlar', () {
    test('Pass/Go — \'@\' siz, QR — \'@id\' va nomda QR', () {
      final ps = buildPayments({
        for (final k in Kind.values) k: 1000,
      });
      final byKey = {for (final p in ps) p.payId: p.name};
      expect(byKey['pay-click'], 'CLICK PASS');
      expect(byKey['@pay-click'], 'CLICK QR');
      expect(byKey['pay-payme'], 'PAYME GO');
      expect(byKey['@pay-payme'], 'PAYME QR');
      expect(byKey['pay-uzum'], 'UZUM');
      expect(byKey['@pay-uzum'], 'UZUM QR');
      expect(byKey['pay-card'], 'UZCARD');
      expect(byKey['@pay-card'], 'HUMO');
      expect(byKey['pay-cash'], 'CASH');
      expect(byKey['pay-cashback'], 'CASHBACK');
      expect(byKey['pay-debt'], 'DEBT');
    });
  });

  group('Yakka to\'lov turi × savat — fiskal JSON', () {
    for (final cart in [...carts, scaleCart]) {
      for (final kind in Kind.values) {
        test('${kind.name} | ${cart.name}', () {
          final rows = cart.rows();
          final double total = cartTotal(rows);
          final amounts = {kind: total};
          final r = receiptOf(rows, buildPayments(amounts));
          final w = wireOf(r);
          final why = '${kind.name} / ${cart.name}';

          expectModuleInvariants(w, why);
          // Tarozida to'lov so'mga yaxlitlanadi — summa emas, bucket muhim.
          final paid = {kind: r.payment.single.value};
          if (cart != scaleCart) {
            expectBuckets(w, paid, why, rows: rows.length);
          } else {
            final rp = receiptPart(w);
            switch (kind.bucket) {
              case Bucket.cash:
                expect(rp['ReceivedCard'], 0, reason: why);
                expect(sumOf(w, 'Other'), 0, reason: why);
                break;
              case Bucket.card:
                expect(rp['ReceivedCash'], 0, reason: why);
                expect(sumOf(w, 'Other'), 0, reason: why);
                break;
              case Bucket.other:
                expect(rp['ReceivedCash'], 0, reason: why);
                expect(rp['ReceivedCard'], 0, reason: why);
                break;
            }
          }
          expectFlags(paramsOf(r), {kind}, why);

          // Karta guruhi (Pass/Go ham) — QQS to'liq; Other guruhi — 0.
          final num vat = sumOf(w, 'VAT');
          if (kind.bucket == Bucket.other) {
            expect(vat, 0, reason: '$why: Other → VAT 0');
          } else if (rows.any((x) => x.vatPercent > 0)) {
            expect(vat, greaterThan(0), reason: '$why: VAT to\'liq');
          }
        });
      }
    }
  });

  group('Pass/Go oldin vs hozir — aniq raqamlar', () {
    test('Click Pass 112 000 (12%): ReceivedCard, Other 0, VAT 12 000 so\'m', () {
      final rows = [row(realPrice: 112000)];
      final w = wireOf(receiptOf(rows, buildPayments({Kind.clickPass: 112000})));
      final it = itemsOf(w).single;
      expect(receiptPart(w)['ReceivedCash'], 0);
      expect(receiptPart(w)['ReceivedCard'], 11200000);
      expect(it['Price'], 11200000);
      expect(it['Other'], 0);
      expect(it['VAT'], closeTo(1200000, 1));
    });

    test('Payme Go 112 000: xuddi shunday', () {
      final w = wireOf(receiptOf(
          [row(realPrice: 112000)], buildPayments({Kind.paymeGo: 112000})));
      expect(receiptPart(w)['ReceivedCard'], 11200000);
      expect(itemsOf(w).single['Other'], 0);
      expect(itemsOf(w).single['VAT'], closeTo(1200000, 1));
    });

    test('Click QR / Payme QR 112 000: o\'zgarishsiz — Other, VAT 0', () {
      for (final k in [Kind.clickQr, Kind.paymeQr]) {
        final w = wireOf(
            receiptOf([row(realPrice: 112000)], buildPayments({k: 112000})));
        expect(receiptPart(w)['ReceivedCard'], 0, reason: k.name);
        expect(receiptPart(w)['ReceivedCash'], 0, reason: k.name);
        expect(itemsOf(w).single['Other'], 11200000, reason: k.name);
        expect(itemsOf(w).single['VAT'], 0, reason: k.name);
      }
    });
  });

  group('Aralash: har juft to\'lov turi (1/3 + 2/3)', () {
    final kinds = Kind.values;
    for (var i = 0; i < kinds.length; i++) {
      for (var j = i + 1; j < kinds.length; j++) {
        final a = kinds[i], b = kinds[j];
        test('${a.name} + ${b.name}', () {
          for (final cart in carts) {
            final rows = cart.rows();
            final double total = cartTotal(rows);
            final double first = (total / 3).floorToDouble();
            final amounts = {a: first, b: total - first};
            final r = receiptOf(rows, buildPayments(amounts));
            final w = wireOf(r);
            final why = '${a.name}+${b.name} / ${cart.name}';
            expectModuleInvariants(w, why);
            expectBuckets(w, amounts, why, rows: rows.length);
            expectFlags(paramsOf(r), {a, b}, why);
          }
        });
      }
    }
  });

  group('Murakkab holatlar', () {
    test('hamma 11 tur bitta chekda', () {
      final rows = [
        row(realPrice: 110000, name: 'X'),
        row(realPrice: 55000, vatPercent: 0, name: 'Y'),
      ];
      final amounts = {for (final k in Kind.values) k: 15000.0};
      final r = receiptOf(rows, buildPayments(amounts));
      final w = wireOf(r);
      expectModuleInvariants(w, 'hammasi');
      expectBuckets(w, amounts, 'hammasi', rows: 2);
      expectFlags(paramsOf(r), Kind.values.toSet(), 'hammasi');
    });

    test('bir provayderning Pass + QR bitta chekda: Pass → karta, QR → Other, bayroq true',
        () {
      final rows = [row(realPrice: 100000)];
      for (final pair in [
        [Kind.clickPass, Kind.clickQr],
        [Kind.paymeGo, Kind.paymeQr],
        [Kind.uzum, Kind.uzumQr],
      ]) {
        final amounts = {pair[0]: 60000.0, pair[1]: 40000.0};
        final r = receiptOf(rows, buildPayments(amounts));
        final w = wireOf(r);
        expectModuleInvariants(w, pair.toString());
        expectBuckets(w, amounts, pair.toString());
        expectFlags(paramsOf(r), pair.toSet(), pair.toString());
      }
    });

    test('naqd qaytim (sdacha) + Click Pass: naqd qatoridan qaytim ayriladi', () {
      final rows = [row(realPrice: 50000)];
      // Mijoz 20 000 Click Pass + 40 000 naqd berdi, qaytim 10 000.
      final payments = buildPayments(
          {Kind.clickPass: 20000, Kind.cash: 40000},
          sdacha: 10000);
      final r = receiptOf(rows, payments);
      final w = wireOf(r);
      expectModuleInvariants(w, 'sdacha');
      expect(receiptPart(w)['ReceivedCash'], 3000000);
      expect(receiptPart(w)['ReceivedCard'], 2000000);
      expect(sumOf(w, 'Other'), 0);
      expect(paramsOf(r)['receivedClick'], true);
    });

    test('cashback + Click QR + Payme Go: Other = cashback + QR, karta = Go', () {
      final rows = [
        row(realPrice: 30000, name: 'A'),
        row(realPrice: 70000, name: 'B'),
      ];
      final amounts = {
        Kind.cashback: 10000.0,
        Kind.clickQr: 25000.0,
        Kind.paymeGo: 65000.0,
      };
      final r = receiptOf(rows, buildPayments(amounts));
      final w = wireOf(r);
      expectModuleInvariants(w, 'cb+qr+go');
      expectBuckets(w, amounts, 'cb+qr+go', rows: 2);
      expectFlags(paramsOf(r), amounts.keys.toSet(), 'cb+qr+go');
    });

    test('serverdan qaytgan chek: QR\'da \'@\' yo\'q, nomi QR → baribir Other',
        () {
      final rows = [row(realPrice: 50000)];
      final r = receiptOf(rows, [
        ReceiptModelPaymentType4(name: 'CLICK QR', payId: 'pay-click', value: 20000),
        ReceiptModelPaymentType4(name: 'PAYME QR', payId: 'pay-payme', value: 30000),
      ]);
      final w = wireOf(r);
      expectModuleInvariants(w, 'server QR');
      expect(receiptPart(w)['ReceivedCard'], 0);
      expect(sumOf(w, 'Other'), 5000000);
      expectFlags(paramsOf(r), const {}, 'server QR');
    });

    test('nomi kichik harfda (eski chek): click pass → karta', () {
      final r = receiptOf([row(realPrice: 50000)], [
        ReceiptModelPaymentType4(name: 'click pass', payId: 'pay-click', value: 50000),
      ]);
      final w = wireOf(r);
      expect(receiptPart(w)['ReceivedCard'], 5000000);
      expect(paramsOf(r)['receivedClick'], true);
    });
  });

  group('Vozvrat — to\'lov turidan qat\'iy nazar naqd', () {
    test('Click Pass / Payme Go / QR chekining vozvrati (return_bloc: faqat CASH)',
        () {
      for (final k in [Kind.clickPass, Kind.paymeGo, Kind.clickQr, Kind.paymeQr]) {
        final rows = [row(realPrice: 50000)];
        // return_bloc.dart: vozvrat cheki to'lovi har doim bitta CASH.
        final refund = receiptOf(
          rows,
          [ReceiptModelPaymentType4(name: 'CASH', payId: ids.cash, value: 50000)],
          isRefund: true,
        );
        final w = wireOf(refund);
        expectModuleInvariants(w, 'vozvrat ${k.name}');
        expect(receiptPart(w)['ReceivedCash'], 5000000, reason: k.name);
        expect(receiptPart(w)['ReceivedCard'], 0, reason: k.name);
        expect(sumOf(w, 'Other'), 0, reason: k.name);
        expectFlags(paramsOf(refund), const {}, 'vozvrat ${k.name}');
      }
    });

    test('vozvrat chekida asl to\'lovlar qolgan bo\'lsa ham — hammasi ReceivedCash',
        () {
      final rows = [row(realPrice: 50000)];
      final refund = receiptOf(
        rows,
        buildPayments({Kind.clickPass: 20000, Kind.paymeQr: 30000}),
        isRefund: true,
      );
      final w = wireOf(refund);
      expectModuleInvariants(w, 'vozvrat aralash');
      expect(receiptPart(w)['ReceivedCash'], 5000000);
      expect(receiptPart(w)['ReceivedCard'], 0);
      expect(sumOf(w, 'Other'), 0);
    });
  });

  group('Barqarorlik', () {
    test('saleOnOFD qayta chaqirilsa (PreOfd qayta urinish) natija bir xil', () {
      final rows = [
        row(realPrice: 37500, value: 2, name: 'A'),
        row(realPrice: 9990, name: 'C'),
      ];
      final total = cartTotal(rows);
      final r = receiptOf(rows,
          buildPayments({Kind.clickPass: 30000, Kind.clickQr: total - 30000}));
      final before = jsonEncode(r.payment.map((p) => [p.name, p.payId, p.value]).toList());
      final first = jsonEncode(wireOf(r));
      final second = jsonEncode(wireOf(r));
      expect(second, first);
      expect(
          jsonEncode(r.payment.map((p) => [p.name, p.payId, p.value]).toList()),
          before,
          reason: 'saleOnOFD chek to\'lovlarini o\'zgartirmasligi kerak');
    });

    test('provayder ID sozlanmagan (clickId bo\'sh): Pass bayrog\'i false', () async {
      final saved = Pref.getString(PrefKeys.clickId, '');
      await Pref.setString(PrefKeys.clickId, '');
      try {
        final r = receiptOf(
            [row(realPrice: 50000)], buildPayments({Kind.clickPass: 50000}));
        expect(paramsOf(r)['receivedClick'], false);
        expectModuleInvariants(wireOf(r), 'clickId bo\'sh');
      } finally {
        await Pref.setString(PrefKeys.clickId, saved);
      }
    });
  });
}
```

</details>

<details><summary>YANGI: <code>test/support/epay_fixtures.dart</code></summary>

```dart
// Click/Payme/Uzum fiskal testlari uchun umumiy fixture'lar:
// test/epay_fiscal_matrix_test.dart, test/receipt_epay_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/receipt/receipt_payments.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/services/local_selling_service.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/fiscal_service/model/fiscal_receipt_model.dart';
import 'package:invan2/fiscal_service/model/location/location.dart';
import 'package:invan2/fiscal_service/model/receipt_data_model.dart';
import 'package:invan2/fiscal_service/model/request_receipt_model.dart';
import 'provider_harness.dart';

const kMxik = '01234567890123456';
const ids = PaymentIds(
  cash: 'pay-cash',
  card: 'pay-card',
  cashback: 'pay-cashback',
  debt: 'pay-debt',
  payme: 'pay-payme',
  click: 'pay-click',
  uzum: 'pay-uzum',
);

/// Fiskalda qaysi maydonga tushishi kerak.
enum Bucket { cash, card, other }

/// To'lov ekranidagi tugma.
enum Kind {
  cash('pay-cash', 0, Bucket.cash),
  uzcard('pay-card', 0, Bucket.card),
  humo('@pay-card', 1, Bucket.card),
  clickPass('pay-click', 0, Bucket.card),
  clickQr('@pay-click', 1, Bucket.other),
  paymeGo('pay-payme', 0, Bucket.card),
  paymeQr('@pay-payme', 1, Bucket.other),
  uzum('pay-uzum', 0, Bucket.other),
  uzumQr('@pay-uzum', 1, Bucket.other),
  cashback('pay-cashback', 0, Bucket.other),
  debt('pay-debt', 0, Bucket.card);

  const Kind(this.key, this.type, this.bucket);

  /// `paymentsMap` kaliti (QR — '@id').
  final String key;
  final int type;
  final Bucket bucket;
}

/// Savat varianti.
class Cart {
  const Cart(this.name, this.rows);
  final String name;
  final List<ReceiptModelSoldItem4> Function() rows;
}

ReceiptModelSoldItem4 row({
  required double realPrice,
  double? price,
  double value = 1,
  double vatPercent = 12,
  String name = 'Tovar',
}) =>
    makeSoldItem(
      productId: name,
      name: name,
      price: price ?? realPrice,
      realPrice: realPrice,
      onlyPrice: realPrice,
      value: value,
      vatPercent: vatPercent,
      singleDiscount: realPrice - (price ?? realPrice),
      mxik: kMxik,
    );

final List<Cart> carts = [
  Cart('bitta qator 50 000, 12%', () => [row(realPrice: 50000)]),
  Cart('ko\'p qator, QQS 12% va 0%', () => [
        row(realPrice: 37500, value: 2, name: 'A'),
        row(realPrice: 15000, vatPercent: 0, name: 'B'),
        row(realPrice: 9990, name: 'C'),
      ]),
  Cart('chegirma 120 000 → 99 000', () => [
        row(realPrice: 120000, price: 99000, name: 'D'),
        row(realPrice: 4500, value: 3, name: 'E'),
      ]),
  Cart('katta summa 3 × 12 500 000', () => [
        row(realPrice: 12500000, value: 3, name: 'F'),
      ]),
];

/// Tarozi: 0.29 × 77 950 = 22 605.5 (yarim so'm) — §10.2.1 yaxlitlash.
Cart scaleCart = Cart('tarozi 0.29 × 77 950', () => [
      row(realPrice: 77950, value: 0.29, name: 'Go\'sht'),
      row(realPrice: 12000, name: 'Non'),
    ]);

double cartTotal(List<ReceiptModelSoldItem4> rows) =>
    rows.fold<double>(0, (a, r) => a + r.price * r.value);

/// To'lov ekrani xaritasi → haqiqiy `ReceiptPayments.build`.
List<ReceiptModelPaymentType4> buildPayments(
  Map<Kind, double> amounts, {
  double sdacha = 0,
}) {
  final map = <String, Payment>{
    for (final e in amounts.entries)
      e.key.key: Payment(
        name: e.key.name,
        id: e.key.key.replaceFirst('@', ''),
        type: e.key.type,
        value: e.value,
      ),
  };
  return ReceiptPayments.build(map,
      ids: ids, sdacha: sdacha, zdachaToCashBack: 0);
}

ReceiptModel4 receiptOf(
  List<ReceiptModelSoldItem4> rows,
  List<ReceiptModelPaymentType4> payments, {
  bool isRefund = false,
}) {
  final r = ReceiptModel4(
    createdDate: '2026-10-02 12:00:00',
    orderId: 'order-1',
    cashboxId: 'cashbox-1',
    externalId: 'DN-1',
    orderType: isRefund ? 'refund' : 'sale',
    shopId: 'shop-1',
    userId: kUserId,
    discountVat: 0,
    discountID: '',
    newid: '',
    cashierId: kCashierId,
    cashierName: kCashierName,
    date: DateTime.now().millisecondsSinceEpoch,
    isRefund: isRefund,
    totalPrice: cartTotal(rows),
    uploaded: false,
    rejected: false,
    clientName: '',
    clientPhone: '',
    clientId: '',
    supplierId: '',
    cashback: 0,
    sdacha: 0,
    returnForCheck: isRefund ? 'DN-0' : '',
    posName: 'Test POS',
    isDonate: false,
    refundInfo: isRefund
        ? jsonEncode({
            'TerminalID': 'MOCK00000001',
            'ReceiptSeq': '101',
            'DateTime': '20261002120000',
            'FiscalSign': '600000000101',
            'QRCodeURL': '',
          })
        : null,
  );
  r.soldItemList.addAll(rows);
  r.payment.addAll(payments);
  return r;
}

Map<String, dynamic> paramsOf(ReceiptModel4 r) =>
    ReceiptSingleton4.saleOnOFD(r)['params'] as Map<String, dynamic>;

/// Modulga ketadigan JSON.
Map<String, dynamic> wireOf(ReceiptModel4 receipt) {
  final body = ReceiptSingleton4.saleOnOFD(receipt);
  final model = RequestSaleModel.fromJson(body);
  final fiscal = FiscalReceiptModel.fromRequest(
    model,
    ReceiptDataModel(
      factoryID: 'UZ000000000MOCK',
      terminalID: 'MOCK00000001',
      location: Location(latitude: 41.311081, longitude: 69.240562),
    ),
    DateTime(2026, 10, 2, 12, 0, 0),
    // saleWithOutIncom bilan aynan bir xil ExtraInfo.
    LocalService.extraInfoFromBody(body),
  );
  return jsonDecode(jsonEncode(fiscal.toJson())) as Map<String, dynamic>;
}

Map<String, dynamic> receiptPart(Map<String, dynamic> w) =>
    w['params']['Receipt'] as Map<String, dynamic>;
List<Map<String, dynamic>> itemsOf(Map<String, dynamic> w) =>
    (receiptPart(w)['Items'] as List).cast<Map<String, dynamic>>();
num sumOf(Map<String, dynamic> w, String key) =>
    itemsOf(w).fold<num>(0, (a, it) => a + (it[key] as num? ?? 0));

/// Modul qabul qilishi uchun shart bo'lgan invariantlar.
void expectModuleInvariants(Map<String, dynamic> w, String why) {
  final rp = receiptPart(w);
  final num cash = rp['ReceivedCash'] as num;
  final num card = rp['ReceivedCard'] as num;
  expect(cash, greaterThanOrEqualTo(0), reason: '$why: ReceivedCash');
  expect(card, greaterThanOrEqualTo(0), reason: '$why: ReceivedCard');

  for (final it in itemsOf(w)) {
    final num price = it['Price'] as num;
    final num disc = it['Discount'] as num? ?? 0;
    final num other = it['Other'] as num? ?? 0;
    final num vat = it['VAT'] as num? ?? 0;
    final num p = it['VATPercent'] as num? ?? 0;
    expect(other, greaterThanOrEqualTo(0), reason: '$why: ${it['Name']} Other');
    expect(other + disc, lessThanOrEqualTo(price),
        reason: '$why: ${it['Name']} Other+Discount ≤ Price');
    final double expectedVat = p == 0 ? 0 : (price - disc - other) * p / (100 + p);
    expect(vat, closeTo(expectedVat, 1),
        reason: '$why: ${it['Name']} VAT bazasi (Price−Discount−Other)');
  }

  final num lhs = sumOf(w, 'Price') - sumOf(w, 'Discount');
  final num rhs = cash + card + sumOf(w, 'Other');
  expect(lhs, rhs, reason: '$why: §10.2.1 Σ(Price−Discount) = Cash+Card+ΣOther');
}

/// To'lov turlariga qarab kutilgan maydonlar (tiyinda).
void expectBuckets(
  Map<String, dynamic> w,
  Map<Kind, double> amounts,
  String why, {
  int rows = 1,
}) {
  double cash = 0, card = 0, other = 0;
  amounts.forEach((k, v) {
    switch (k.bucket) {
      case Bucket.cash:
        cash += v;
        break;
      case Bucket.card:
        card += v;
        break;
      case Bucket.other:
        other += v;
        break;
    }
  });
  final rp = receiptPart(w);
  expect(rp['ReceivedCash'], (cash * 100).round(), reason: '$why: ReceivedCash');
  expect(rp['ReceivedCard'], (card * 100).round(), reason: '$why: ReceivedCard');
  // Other qatorlarga so'mga yaxlitlab taqsimlanadi — qator boshiga ≤ 1 so'm.
  expect(sumOf(w, 'Other'), closeTo(other * 100, rows * 100.0),
      reason: '$why: ΣOther');
  if (other == 0) expect(sumOf(w, 'Other'), 0, reason: '$why: Other 0');
}

void expectFlags(Map<String, dynamic> params, Set<Kind> kinds, String why) {
  expect(params['receivedClick'], kinds.contains(Kind.clickPass),
      reason: '$why: receivedClick');
  expect(params['receivedPayme'], kinds.contains(Kind.paymeGo),
      reason: '$why: receivedPayme');
  expect(params['receivedUzum'], kinds.contains(Kind.uzum),
      reason: '$why: receivedUzum');
}
```

</details>

## 7. Tekshirish

- Unit/integratsiya: `test/receipt_epay_test.dart` (36), `test/epay_fiscal_matrix_test.dart`
  (124), `test/receipt_vat_test.dart` (30). To'liq suite: 1616 ✅,
  `flutter analyze` — 0 error.
- Matritsa: to'lovlar haqiqiy `ReceiptPayments.build` orqali; natija modulga ketadigan
  aniq JSON'da (`saleOnOFD` → `RequestSaleModel` → `FiscalReceiptModel.toJson`,
  `ExtraInfo` — `LocalService.extraInfoFromBody`). 11 to'lov turi × 5 savat (12%/0%,
  chegirma, tarozi yarim so'm, 37,5 mln), 55 juft, sdacha, vozvrat, `@` siz server
  QR. Har holatda §10.2.1 balansi, `Other + Discount ≤ Price`, QQS bazasi.
- Mutatsiya: tuzatishni 11 xil buzish (Pass→Other, hasPass QR'ni o'tkazishi,
  ExtraInfo Pref'dan, nusxalar epayJson'siz, reset, targets, vozvrat, telefon
  oqishi va h.k.) — hammasini testlar ushladi.
- **Do'kon/qurilma sinovi (kutilmoqda):**
  - Click Pass / Payme Go chek: fiskal JSON `ReceivedCard` = summa, `Other` = 0,
    `VAT` > 0; `ExtraInfo` 64/141 + to'lov ID + telefon; provayderga
    `submit_qrcode` / `set_fiscal_data` shu to'lov ID'si bilan.
  - Click Pass'dan keyingi naqd chek: `ExtraInfo.QRPaymentProvider` = 0, ID bo'sh.
  - Click QR / Payme QR: eskidek `Other`, QQS 0, provayderga so'rov yo'q.
  - Fiskalsiz saqlangan Pass chekni cheklar ro'yxatidan qayta yuborish: provayderga
    o'sha chekning ID'si.

## 8. Eslatmalar va ochiq savollar

- **ObjectBox:** property 51 (`epayJson`) — faqat to'liq reliz. InVan 1 o'zi
  generatsiya qiladi; InVan 2 `objectbox-model.json` ni ko'chirmang.
- Servislar (`ClickService.post`, `PaymeGOService._post`, `UzumService.payment`)
  global Pref'ga yozishda davom etadi — ataylab tegilmadi (to'lov oqimi
  o'zgarmasin); fiskal endi ulardan o'qimaydi.
- `epayJson` serverga (`order_pos`) yuborilmaydi.
- Qog'oz chek QQS'i: Click/Payme QR va Uzum fiskalda `Other` (QQS 0), qog'oz chekda
  ayrilmaydi — avvalgidek, ataylab (receipt_vat_test "QAYD" testi).
- `PaynetService._baseUrl = _baseUrlTest` — mavjud holat, bu taskda tegilmagan
  (alohida tekshirilsin).
- `ofd_page.dart` (qo'lda OFD sahifasi) hali Pref `epay_*` dan o'qiydi — u yerda
  `receivedClick/Payme` false, tegilmadi.

**Odoo forkiga: KERAK** — fiskal to'lov tasnifi (Click Pass/Payme Go → ReceivedCard)
va ExtraInfo/provayder ID mantig'i umumiy. Odoo forki ObjectBox'ni o'zi generatsiya
qilsin (u yerda `ReceiptModel4` property ID'lari boshqa — 61 gacha).

---

# 10-TASK — Multi-klient orqali access-siz mahsulot o'chirish yopildi (1.1.2+129)

> **Commit:** `a3a69a9` (2026-10-01), reliz 1.1.2+129.
> **Sessiya hujjati:** docs/sessions/2026-09-30-multi-klient-access-bypass-fix.md
> **Holat 2026-10-02:** relizda; do'kon sinovi kutilmoqda.

## 1. Nima va nima uchun

Kassirlar bo'sh klient tab'ini bosib, `deleteS` (o'chirish) huquqisiz mahsulotni savatdan "yo'qotish" yo'lini topishgan. Ildiz: `selectClient()` tanlangan bo'sh klientni `_clearEmptyClients()` bilan ro'yxatdan o'chirib, `_currentClient` ni ro'yxatdan uzilgan holda qoldirardi; keyingi to'lovda `_paymentOnClients()` savatni **indeks** bo'yicha tozalab, boshqa klientning savatini jimgina (deletedItems/Telegram izsiz) o'chirardi. Yondosh teshiklar: `cancelOrdering` mantig'i teskari edi (`deleteS` YO'Q xodim savatni dialogsiz tozalardi, BOR xodim dialog olardi); Shift+Delete `delete_ticket` prefiga qarardi (uni har qanday PIN yozadi — rahbar PIN'idan keyin ruxsatsiz kassir tozalay olardi); `Pref.getDeleteItem` defaulti `true` edi.

## 2. Qanday ishlaydi

- `selectClient(i)`: bo'sh tanlangan klient ro'yxatda QOLADI (`_clearEmptyClients(keep: _currentClient)`), `_index` — `indexOf(_currentClient)`.
- `_paymentOnClients()`: to'lagan klient doim `_currentClient` — savat **identity** bo'yicha tozalanadi, keyin bo'sh klientlar olinadi.
- Yangi klient qo'shishda joriy klient ro'yxatda bo'lmasa — savati bilan qo'shiladi.
- `cancelOrdering(access)`: ruxsat = dialogdan kelgan `access` YOKI joriy xodimning jonli `deleteS`; ikkalasi yo'q → `false` (chaqiruvchi `NoAccessDialog` ko'rsatadi).
- Shift+Delete: `cancelOrdering(false)` — faqat jonli huquq.
- `Pref.getDeleteItem` default `false` (default-deny).

## 3. O'zgarishlar ro'yxati

| Fayl | Tur | Nima |
|---|---|---|
| `lib/changes/providers/ordering_provider_4.dart` | o'zgargan | `cancelOrdering`, `selectClient`, `_clearEmptyClients(keep:)`, `_paymentOnClients`, klient qo'shish |
| `lib/features/home/home_page.dart` | o'zgargan | Shift+Delete → `cancelOrdering(false)`, `deleteTicketAccess` olib tashlandi |
| `lib/utils/helpers/prefs.dart` | o'zgargan | `getDeleteItem` default `false` |
| `test/multi_client_access_bypass_regression_test.dart` | YANGI | Hiyla stsenariysi va yondosh teshiklar |
| `test/multi_client_stress_test.dart` | YANGI | Ko'p klientli tasodifiy ketma-ketliklar |
| `test/cart_basic_test.dart` | o'zgargan | `cancelOrdering` yangi mantig'i |

## 4. Bog'liqliklar

- `OrderingProvider4` ajratilgan holati (Faza 9, bu hujjatdan tashqarida) — InVan 1 da savat mantig'i boshqa faylda bo'lsa, xuddi shu metodlarni toping (`selectClient`, `_clearEmptyClients`, `_paymentOnClients`, `cancelOrdering`).
- Testlar `test/support/provider_harness.dart` ga tayanadi (yuqoridagi umumiy ko'rsatma, 5-band).

## 5. Qo'llash tartibi

1. `ordering_provider_4.dart` (6.1) — to'rt metod.
2. `home_page.dart` (6.2) va `prefs.dart` (6.3).
3. Testlar (6.4), `flutter test`.

## 6. Kod

### 6.1. `lib/changes/providers/ordering_provider_4.dart`

```diff
diff --git a/lib/changes/providers/ordering_provider_4.dart b/lib/changes/providers/ordering_provider_4.dart
index fae7fb7..a9d3252 100644
--- a/lib/changes/providers/ordering_provider_4.dart
+++ b/lib/changes/providers/ordering_provider_4.dart
@@ -257,15 +257,11 @@ class OrderingProvider4 extends ChangeNotifier {
 
   bool cancelOrdering(bool access) {
     if (_currentClient.orderedProducts.isEmpty) return true;
-    if (!access) {
-      if (!(currentEmployee.access?.deleteS ?? false)) {
-        _currentClient.orderedProducts = [];
-        _currentClient.lastAddedIndex = -1;
-        notifyListeners();
-        return true;
-      } else {
-        return false;
-      }
+    // Ruxsat: dialog/sozlamadan kelgan `access` YOKI joriy xodimning jonli
+    // deleteS huquqi. Ikkalasi ham yo'q bo'lsa — savatga tegilmaydi, false
+    // qaytadi va chaqiruvchi NoAccessDialog ko'rsatadi.
+    if (!access && !(currentEmployee.access?.deleteS ?? false)) {
+      return false;
     }
     _currentClient.orderedProducts = [];
     _currentClient.lastAddedIndex = -1;
@@ -1528,7 +1524,10 @@ class OrderingProvider4 extends ChangeNotifier {
         orderedProducts: [],
         discountAmountFromNewClient: 0,
       );
-      if (_sixClient4List.isEmpty) {
+      // Joriy klient ro'yxatda bo'lmasa (bitta-klient rejimi yoki har qanday
+      // uzilgan holat) — savati bilan ro'yxatga qo'shiladi, aks holda undagi
+      // mahsulotlar izsiz yo'qoladi.
+      if (!_sixClient4List.contains(_currentClient)) {
         _sixClient4List.add(_currentClient);
       }
 
@@ -1543,8 +1542,11 @@ class OrderingProvider4 extends ChangeNotifier {
   void selectClient(int i) {
     LogHelper.activity('CLIENT_SELECT', {'index': i});
     _currentClient = _sixClient4List[i];
-    _index = i;
-    _clearEmptyClients();
+    // Tanlangan klient bo'sh bo'lsa ham ro'yxatdan chiqarilmaydi (keep) —
+    // aks holda _currentClient ro'yxatdan uzilib, _index dangling qoladi va
+    // keyingi to'lovda boshqa klientning savati access-siz o'chib ketadi.
+    _clearEmptyClients(keep: _currentClient);
+    _index = _sixClient4List.indexOf(_currentClient);
     _syncReceiptCompanyPrefsFromCurrentClient();
     notifyListeners();
   }
@@ -1575,15 +1577,15 @@ class OrderingProvider4 extends ChangeNotifier {
     _syncReceiptCompanyPrefsFromCurrentClient();
   }
 
-  void _clearEmptyClients() {
-    List<int> clientNumbers = [];
-    for (int i = 0; i < _sixClient4List.length; i++) {
-      if (_sixClient4List[i].orderedProducts.isEmpty) {
-        clientNumbers.add(_sixClient4List[i].clientNumber);
-        _harvestDeletedItems(_sixClient4List[i]);
+  void _clearEmptyClients({SixClientModel4? keep}) {
+    for (final client in _sixClient4List) {
+      if (client.orderedProducts.isEmpty && !identical(client, keep)) {
+        _harvestDeletedItems(client);
       }
     }
-    _sixClient4List.removeWhere((e) => e.orderedProducts.isEmpty);
+    _sixClient4List.removeWhere(
+      (e) => e.orderedProducts.isEmpty && !identical(e, keep),
+    );
   }
 
   void _harvestDeletedItems(SixClientModel4 client) {
@@ -1603,6 +1605,13 @@ class OrderingProvider4 extends ChangeNotifier {
     _cashsaleWarningShown = false;
     _bigTotalWarningShown = false;
     _harvestDeletedItems(_currentClient);
+    // To'lagan klient DOIM _currentClient — savat identity bo'yicha
+    // tozalanadi. Indeks (_sixClient4List[_index]) bo'yicha tozalash mumkin
+    // emas: indeks siljigan bo'lsa boshqa klientning savati o'chib ketadi
+    // yoki RangeError beradi.
+    _currentClient.orderedProducts = [];
+    _currentClient.lastAddedIndex = -1;
+    _clearEmptyClients();
     if (_sixClient4List.isEmpty) {
       _clientNumber = 1;
       _currentClient = SixClientModel4(
@@ -1611,19 +1620,8 @@ class OrderingProvider4 extends ChangeNotifier {
         orderedProducts: [],
         discountAmountFromNewClient: 0,
       );
-    } else if (_sixClient4List.length == 1) {
-      _clientNumber = 1;
-      _currentClient = SixClientModel4(
-        clientNumber: _clientNumber,
-        lastAddedIndex: -1,
-        orderedProducts: [],
-        discountAmountFromNewClient: 0,
-      );
-      _sixClient4List[0].orderedProducts = [];
-      _clearEmptyClients();
+      _index = 0;
     } else {
-      _sixClient4List[_index].orderedProducts = [];
-      _clearEmptyClients();
       _index = 0;
       _currentClient = _sixClient4List.first;
     }
```

### 6.2. `lib/features/home/home_page.dart`

```diff
diff --git a/lib/features/home/home_page.dart b/lib/features/home/home_page.dart
index 549b884..73417e8 100644
--- a/lib/features/home/home_page.dart
+++ b/lib/features/home/home_page.dart
@@ -76,7 +76,6 @@ class HomePageState extends State<HomePage> with WidgetsBindingObserver {
     });
   }
 
-  bool deleteTicketAccess = Pref.getDeleteItem('delete_ticket');
 
   @override
   Widget build(BuildContext context) {
@@ -242,7 +241,13 @@ class HomePageState extends State<HomePage> with WidgetsBindingObserver {
                         bool result = Provider.of<OrderingProvider4>(
                           context,
                           listen: false,
-                        ).cancelOrdering(deleteTicketAccess);
+                        )
+                        // Faqat joriy kassirning JONLI deleteS huquqi
+                        // (cancelOrdering ichida). `delete_ticket` prefi
+                        // ishlatilmaydi: uni har qanday PIN (masalan rahbar
+                        // chek tarixiga kirganda) yozadi va keyin ruxsatsiz
+                        // kassir dialogsiz savatni tozalay olardi.
+                        .cancelOrdering(false);
                         if (!result) {
                           blBlocc.add(
                             BlStatusChangedEvent(
```

### 6.3. `lib/utils/helpers/prefs.dart`

```diff
diff --git a/lib/utils/helpers/prefs.dart b/lib/utils/helpers/prefs.dart
index ee62483..1d3720e 100644
--- a/lib/utils/helpers/prefs.dart
+++ b/lib/utils/helpers/prefs.dart
@@ -62,7 +62,9 @@ class Pref {
     return _box.get(key) ?? defValue;
   }
 
-  ///
-  static bool getDeleteItem(String key) => _box.get(key) ?? true;
+  /// Default `false` (default-deny): kalit hali yozilmagan bo'lsa (PIN
+  /// login'dan oldin) o'chirish ruxsati YO'Q deb hisoblanadi. Ruxsati bor
+  /// xodim uchun cancelOrdering jonli deleteS tekshiruvi bilan baribir ochiq.
+  static bool getDeleteItem(String key) => _box.get(key) ?? false;
   static Future removeWithKey(String removedKey) => _box.delete(removedKey);
 }
```

### 6.4. Testlar

<details><summary>YANGI: <code>test/multi_client_access_bypass_regression_test.dart</code></summary>

```dart
// Regression: bo'sh klient tanlash orqali access-siz mahsulot o'chirish
// (kassir hiylasi, 2026-09-30 da fix qilindi).
//
// Bug tarixi: selectClient() tanlangan bo'sh klientni _clearEmptyClients()
// bilan ro'yxatdan chiqarib, _currentClient'ni detached qoldirardi (savat UI
// bo'sh ko'rinardi — mahsulot "yo'qolardi"); keyingi to'lovda
// _paymentOnClients() indeks bo'yicha _sixClient4List[0] ni tozalab,
// 1-klientning mahsulotini access kodisiz va deletedItems/orphan yozuvisiz
// o'chirardi. 3+ klientda dangling _index RangeError ham berardi.
//
// Fix: selectClient tanlangan klientni ro'yxatda saqlaydi (keep) va _index'ni
// identity'dan qayta hisoblaydi; _paymentOnClients indeks emas,
// _currentClient (to'lagan klient) bo'yicha tozalaydi.
// Hujjat: docs/sessions/2026-09-30-multi-klient-access-bypass-fix.md
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('multi_client_access_bypass_regression'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() => Pref.setBool(PrefKeys.isRedDeleteActivated, false));

  test('bo\'sh klient tanlansa ro\'yxatda qoladi — current uzilmaydi', () {
    final p = freshProvider();
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
    p.addClient(); // list=[c1,c2], current=c2(bo'sh), index=1

    p.selectClient(1); // kassir "Mijoz 2" tugmasini bosdi

    // Bo'sh klient tanlangan bo'lsa ro'yxatdan CHIQMAYDI
    expect(p.getSixClient4List.length, 2);
    expect(p.getSixClient4List.contains(p.getCurrentClient), isTrue);
    expect(p.getSelectedIndex, 1);
    // 1-klient mahsuloti joyida
    expect(p.getSixClient4List.first.orderedProducts.length, 1);
  });

  testWidgets(
      'bo\'sh klient tanlangan holatda to\'lov — 1-klient savati saqlanadi',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final ctx = tester.element(find.byType(SizedBox));

    final p = freshProvider();
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
    final client1 = p.getCurrentClient;
    p.addClient();
    p.selectClient(1); // bo'sh "Mijoz 2" tanlandi (hiyla urinishi)

    // Kassir keyingi xaridorning mahsulotini skanladi
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'x'));

    p.initPaymentPageValues(
      sixClientModel4: p.getCurrentClient,
      totalPrice: 5000,
      discountAmount: 0,
    );
    await p.pressPaymentButton(ctx);

    // 1-klient mahsuloti to'lovdan keyin ham JOYIDA — jimgina o'chmaydi
    expect(client1.orderedProducts.length, 1);
    expect(client1.orderedProducts.first.productId, 'a');
    expect(p.getSixClient4List, [client1]);
    expect(p.getCurrentClient, same(client1));
    expect(p.getSelectedIndex, 0);
  });

  test('o\'rtadagi bo\'sh klient o\'chganda _index qayta hisoblanadi', () {
    final p = freshProvider();
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
    p.addClient();
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'b'));
    p.addClient();
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'c'));
    // list=[c1(a), c2(b), c3(c)], index=2

    // c2 savati boshqa yo'l bilan bo'shadi (masalan PIN bilan o'chirilgan)
    p.getSixClient4List[1].orderedProducts.clear();

    p.selectClient(2); // kassir "Mijoz 3" ni bosdi

    // c2 chiqib ketdi, _index endi currentning REAL o'rnini ko'rsatadi
    expect(p.getSixClient4List.length, 2);
    expect(p.getSelectedIndex, 1);
    expect(p.getSixClient4List[1], same(p.getCurrentClient));
    expect(p.getCurrentClient.orderedProducts.first.productId, 'c');
  });

  testWidgets(
      'ko\'p klientda to\'lov faqat to\'lagan klient savatini tozalaydi',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final ctx = tester.element(find.byType(SizedBox));

    final p = freshProvider();
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
    final client1 = p.getCurrentClient;
    p.addClient();
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'b'));
    // list=[c1(a), c2(b)], current=c2, index=1

    p.initPaymentPageValues(
      sixClientModel4: p.getCurrentClient,
      totalPrice: 5000,
      discountAmount: 0,
    );
    await p.pressPaymentButton(ctx);

    // Faqat c2 (to'lagan) tozalanib chiqdi; c1 mahsuloti bilan joriy bo'ldi
    expect(p.getSixClient4List, [client1]);
    expect(p.getCurrentClient, same(client1));
    expect(p.getSelectedIndex, 0);
    expect(client1.orderedProducts.first.productId, 'a');
  });
}
```

</details>

<details><summary>YANGI: <code>test/multi_client_stress_test.dart</code></summary>

```dart
// Multi-klient stress-test — katta miqyosli tasodifiy stsenariylar.
//
// MAQSAD: 2026-09-30 access-bypass fix'idan keyin multi-klient holat mashinasi
// HAR QANDAY operatsiya ketma-ketligida buzilmasligini isbotlash. Minglab
// tasodifiy (seed'langan, takrorlanuvchi) qadamlar bajariladi va har qadamdan
// keyin quyidagi invariantlar tekshiriladi:
//
//   I1. Ro'yxat bo'sh bo'lmasa: _currentClient DOIM ro'yxatda (identity) va
//       getSelectedIndex uning real o'rniga teng.
//   I2. Ro'yxatdagi bo'sh savatli klient faqat _currentClient bo'lishi mumkin
//       (begona bo'sh slot qolmaydi).
//   I3. clientNumber'lar ro'yxat ichida unikal (tab'larda takror "Mijoz N" yo'q).
//   I4. Konservatsiya: hech bir klientning savati unga qaratilmagan operatsiya
//       natijasida O'ZGARMAYDI; mahsulotli klient hech qachon izsiz yo'qolmaydi.
//       (aynan kassir hiylasi shu invariantni buzardi)
//
// Har seed uchun kutilgan holat "shadow" modelda (identity-map) yuritiladi va
// provider bilan solishtiriladi. Xatolik chiqsa reason'da seed va qadam bor —
// aynan shu ketma-ketlikni lokal takrorlash mumkin.
//
// Hujjat: docs/sessions/2026-09-30-multi-klient-access-bypass-fix.md
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

/// Shadow model: har klient (identity) uchun kutilgan productId ro'yxati.
typedef Shadow = Map<SixClientModel4, List<String>>;

bool _inListOrCurrent(OrderingProvider4 p, SixClientModel4 c) =>
    identical(p.getCurrentClient, c) ||
    p.getSixClient4List.any((e) => identical(e, c));

void _checkInvariants(OrderingProvider4 p, Shadow shadow, String ctx) {
  final list = p.getSixClient4List;
  final current = p.getCurrentClient;

  if (list.isNotEmpty) {
    final idx = list.indexWhere((c) => identical(c, current));
    expect(idx, isNot(-1), reason: '$ctx: current ro\'yxatdan uzilgan');
    expect(p.getSelectedIndex, idx,
        reason: '$ctx: _index ($idx kutilgan) noto\'g\'ri');
    for (final c in list) {
      if (c.orderedProducts.isEmpty) {
        expect(identical(c, current), isTrue,
            reason: '$ctx: begona bo\'sh klient ro\'yxatda qolgan');
      }
    }
    final nums = list.map((c) => c.clientNumber).toList();
    expect(nums.toSet().length, nums.length,
        reason: '$ctx: clientNumber takrorlangan: $nums');
  }

  // Konservatsiya: mahsulotli klient izsiz yo'qolmasligi kerak
  for (final e in shadow.entries) {
    if (e.value.isNotEmpty) {
      expect(_inListOrCurrent(p, e.key), isTrue,
          reason:
              '$ctx: klient #${e.key.clientNumber} ${e.value} mahsulotlari '
              'bilan G\'OYIB bo\'ldi (kassir hiylasi qaytdi!)');
    }
  }

  // Har ko'rinadigan klient savati aynan kutilganidek
  final visible = <SixClientModel4>{...list, current};
  for (final c in visible) {
    final expected = shadow[c] ?? const <String>[];
    expect(c.orderedProducts.map((i) => i.productId).toList(), expected,
        reason: '$ctx: klient #${c.clientNumber} savati ruxsatsiz o\'zgargan');
  }

  // Ko'rinmay qolgan (to'langan/bo'sh chiqarilgan) klientlarni shadow'dan olib
  // tashlaymiz — ular faqat bo'sh holda chiqib ketishi mumkin edi (yuqorida
  // tekshirildi).
  shadow.removeWhere((c, _) => !_inListOrCurrent(p, c));
}

Future<void> _fuzzSeed(WidgetTester tester, int seed, int steps) async {
  await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  final ctx = tester.element(find.byType(SizedBox));

  final rnd = Random(seed);
  final p = freshProvider();
  final Shadow shadow = Map.identity();
  shadow[p.getCurrentClient] = [];
  int productSeq = 0;

  List<String> sh(SixClientModel4 c) => shadow.putIfAbsent(c, () => []);

  for (int step = 0; step < steps; step++) {
    final roll = rnd.nextInt(100);
    final current = p.getCurrentClient;
    final list = p.getSixClient4List;
    String op;

    if (roll < 30) {
      // SKAN — joriy savatga mahsulot
      op = 'scan';
      final id = 'p${productSeq++}';
      current.orderedProducts.add(makeSoldItem(productId: id));
      sh(current).add(id);
    } else if (roll < 45 && list.length < 6) {
      // YANGI KLIENT (provider bo'sh savatda o'zi rad etadi)
      op = 'addClient';
      final hadItems = current.orderedProducts.isNotEmpty;
      p.addClient();
      if (hadItems) {
        sh(p.getCurrentClient); // yangi bo'sh klient shadow'ga
      } else {
        expect(identical(p.getCurrentClient, current), isTrue,
            reason: 'seed=$seed step=$step: bo\'sh savatda addClient '
                'holatni o\'zgartirmasligi kerak');
      }
    } else if (roll < 65 && list.isNotEmpty) {
      // KLIENT TANLASH — har qanday indeks, jumladan bo'sh/joriy klient
      final i = rnd.nextInt(list.length);
      op = 'select($i)';
      final target = list[i];
      p.selectClient(i);
      expect(identical(p.getCurrentClient, target), isTrue,
          reason: 'seed=$seed step=$step: tanlangan klient joriy bo\'lmadi');
    } else if (roll < 72) {
      // BUTUN SAVATNI BEKOR QILISH — ruxsat bilan
      op = 'cancelTrue';
      p.cancelOrdering(true);
      sh(current).clear();
    } else if (roll < 79) {
      // RUXSATSIZ BEKOR QILISH — test xodimida deleteS yo'q: rad etilishi shart
      op = 'cancelFalse';
      final result = p.cancelOrdering(false);
      if (current.orderedProducts.isNotEmpty) {
        expect(result, isFalse,
            reason: 'seed=$seed step=$step: ruxsatsiz cancelOrdering '
                'savatni tozalab yubordi (access bypass!)');
      }
    } else if (roll < 89 && current.orderedProducts.isNotEmpty) {
      // OXIRGI QATORNI O'CHIRISH
      op = 'removeLast';
      current.lastAddedIndex = current.orderedProducts.length - 1;
      p.removeLastAdded();
      sh(current).removeLast();
    } else if (roll < 97 && current.orderedProducts.isNotEmpty) {
      // TO'LOV — faqat joriy klient savati tozalanishi kerak
      op = 'pay';
      p.initPaymentPageValues(
        sixClientModel4: current,
        totalPrice: 1000,
        discountAmount: 0,
      );
      await p.pressPaymentButton(ctx);
      sh(current).clear();
    } else if (roll >= 97) {
      // SMENA TOZALASH — hammasi bo'shaydi
      op = 'clearAll';
      p.clearSixClient4List();
      shadow.clear();
      shadow[p.getCurrentClient] = [];
    } else {
      continue; // shart bajarilmagan variant — qadam tashlab ketiladi
    }

    _checkInvariants(p, shadow, 'seed=$seed step=$step op=$op');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('multi_client_stress_test'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() => Pref.setBool(PrefKeys.isRedDeleteActivated, false));

  group('Fuzz — tasodifiy operatsiyalar oqimi (har qadamda invariantlar)', () {
    for (final batch in [0, 1, 2]) {
      testWidgets('seed to\'plami ${batch + 1}/3 (10 seed x 300 qadam)',
          (tester) async {
        // Minglab qadamda [ACTIVITY] loglari konsolni bosmasligi uchun
        // vaqtincha o'chiriladi; test tugashidan OLDIN tiklanishi shart
        // (framework foundation o'zgaruvchilarini tekshiradi).
        final originalDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {};
        try {
          for (int s = 0; s < 10; s++) {
            final seed = 1000 + batch * 10 + s;
            await _fuzzSeed(tester, seed, 300);
          }
        } finally {
          debugPrint = originalDebugPrint;
        }
      }, timeout: const Timeout(Duration(minutes: 5)));
    }
  });

  group('Deterministik chekka holatlar', () {
    test('bo\'sh klient tab\'ini KETMA-KET ikki marta bosish', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
      p.addClient();

      p.selectClient(1);
      p.selectClient(1); // double-tap

      expect(p.getSixClient4List.length, 2);
      expect(p.getSelectedIndex, 1);
      expect(p.getSixClient4List[1], same(p.getCurrentClient));
      expect(p.getSixClient4List.first.orderedProducts.length, 1);
    });

    testWidgets('4 klientli hiyla varianti: bo\'sh 4-klient orqali to\'lov',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final p = freshProvider();
      // 3 ta to'la klient
      for (final id in ['a', 'b', 'c']) {
        p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: id));
        p.addClient();
      }
      // hozir 4-klient (bo'sh) joriy; kassir uni qayta bosdi
      p.selectClient(3);
      // skanladi va sotdi
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'x'));
      p.initPaymentPageValues(
        sixClientModel4: p.getCurrentClient,
        totalPrice: 5000,
        discountAmount: 0,
      );
      await p.pressPaymentButton(ctx);

      // Uchchala klient mahsulotlari joyida
      final products = p.getSixClient4List
          .map((c) => c.orderedProducts.map((i) => i.productId).join())
          .toList();
      expect(products, ['a', 'b', 'c']);
      expect(p.getCurrentClient, same(p.getSixClient4List.first));
      expect(p.getSelectedIndex, 0);
    });

    test('cancelOrdering(true) dan keyin boshqa klientga o\'tish', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
      p.addClient();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'b'));

      // joriy (2-klient) savati ruxsat bilan bekor qilindi — bo'sh, lekin joriy
      p.cancelOrdering(true);
      expect(p.getSixClient4List.length, 2);

      // 1-klientga qaytish — bo'shab qolgan 2-klient ro'yxatdan chiqadi
      p.selectClient(0);

      expect(p.getSixClient4List.length, 1);
      expect(p.getSelectedIndex, 0);
      expect(p.getCurrentClient.orderedProducts.first.productId, 'a');
    });

    test('6 klientgacha ketma-ket qo\'shish — raqamlar unikal va o\'suvchi',
        () {
      final p = freshProvider();
      for (int i = 0; i < 5; i++) {
        p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'p$i'));
        p.addClient();
      }
      expect(p.getSixClient4List.length, 6);
      expect(
        p.getSixClient4List.map((c) => c.clientNumber).toList(),
        [1, 2, 3, 4, 5, 6],
      );
      expect(p.getSelectedIndex, 5);
    });

    test('bo\'sh klientda skan qilib, orqaga qaytish — mahsulotlar o\'z '
        'joyida', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
      p.addClient();
      p.selectClient(1); // bo'sh 2-klient joriy (ro'yxatda!)
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'x'));

      p.selectClient(0);
      expect(p.getCurrentClient.orderedProducts.first.productId, 'a');

      p.selectClient(1);
      expect(p.getCurrentClient.orderedProducts.first.productId, 'x');
      expect(p.getSixClient4List.length, 2);
    });
  });
}
```

</details>

<details><summary><code>test/cart_basic_test.dart</code> (diff)</summary>

```diff
diff --git a/test/cart_basic_test.dart b/test/cart_basic_test.dart
index d276ab9..b3d2351 100644
--- a/test/cart_basic_test.dart
+++ b/test/cart_basic_test.dart
@@ -9,6 +9,8 @@
 // kontekstsiz metodlar chaqiriladi.
 // MUHIM: "to'g'rimi?" emas, "hozir nima bo'lyapti?" yoziladi.
 import 'package:flutter_test/flutter_test.dart';
+import 'package:invan2/features/get_employees/model/employees_find_response.dart';
+import 'package:invan2/features/hive_repository/hive_boxes.dart';
 import 'package:invan2/utils/constants/pref_keys.dart';
 import 'package:invan2/utils/helpers/prefs.dart';
 
@@ -114,16 +116,40 @@ void main() {
       expect(p.getLastAddedIndex, -1);
     });
 
-    test('ruxsatsiz va xodimda deleteS huquqi yo\'q: savat baribir tozalanadi',
-        () {
+    test('ruxsatsiz va xodimda deleteS huquqi yo\'q: savatga TEGILMAYDI', () {
+      // 2026-09-30 fix: avval bu holatda savat dialogsiz tozalanardi
+      // (mantiq teskari edi). Endi false qaytadi — chaqiruvchi
+      // NoAccessDialog ko'rsatadi.
       final p = freshProvider();
       p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
 
       // Test xodimida access = null, ya'ni deleteS = false
       final result = p.cancelOrdering(false);
 
-      expect(result, isTrue);
-      expect(p.getCurrentClient.orderedProducts, isEmpty);
+      expect(result, isFalse);
+      expect(p.getCurrentClient.orderedProducts.length, 1);
+    });
+
+    test('ruxsat parametrsiz, lekin xodimda deleteS bor: savat tozalanadi',
+        () async {
+      // getCurrentEmployee bir xil id'li yozuvlardan OXIRGISINI oladi —
+      // deleteS'li xodimni vaqtincha qo'shib, testdan keyin o'chiramiz.
+      final box = HiveBoxes.getEmployees();
+      final key = await box.add(Employee(
+        user: EmployeeUser(id: kCashierId, firstName: kCashierName),
+        access: EmployeeAccess(deleteS: true),
+      ));
+      try {
+        final p = freshProvider();
+        p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
+
+        final result = p.cancelOrdering(false);
+
+        expect(result, isTrue);
+        expect(p.getCurrentClient.orderedProducts, isEmpty);
+      } finally {
+        await box.delete(key);
+      }
     });
   });
 
```

</details>

## 7. Tekshirish

- `flutter test test/multi_client_access_bypass_regression_test.dart` — 4/4; to'liq to'plam o'tgan (2026-09-30: 1382; 2026-10-02: 1616/1616 (2026-10-02, `c4e42e1`)).
- Do'kon sinovi kutilmoqda: (1) kassir hiylasi stsenariysi — bo'sh tab bosilib, keyingi to'lovda boshqa savat o'chmasligi; (2) `deleteS` siz xodim Shift+Del → dialog, `deleteS` li xodim → tozalash.

## 8. Eslatmalar

- Odoo forkiga: kerak (savat mantig'i umumiy).

---

# 11-TASK — Smena ochish/yopish navbati FIFO ro'yxat: server o'chiq kunda ham har smena serverga yetadi (1.1.2+129)

> **Commit:** `a24d0c9` (2026-10-02), reliz 1.1.2+129.
> **Sessiya hujjati:** docs/sessions/2026-10-02-smena-navbat-fifo.md
> **Holat 2026-10-02:** relizda; Mac'da qo'lda sinalgan (foydalanuvchi: 4-5 marta ochish/yopish, orada sotuv, internetsiz), jonli dev API sinovi; **Windows'da qo'lda sinalmagan**.

## 1. Nima va nima uchun

Server yoki internet yo'qligida bajarilgan smena ochish/yopishlari "navbat"da saqlanib, server qaytganda yuboriladi. Eski navbatda ochish va yopish uchun **bittadan joy** (Pref: `openedDate/openedCount`, `closedDate/closedCount`) bor edi:

- Server ertalabdan o'chiq: 08:00 oflayn ochish → 14:00 yopish → 14:05 qayta ochish. Ochish joyi 08:00 → 14:05 ga almashadi. Server qaytganda "yopish 14:00, ochish 14:05" ketadi — server yopiq kassani yopishga ham 200 qaytaradi (jonli sinov), natijada **08:00–14:00 smenasi serverga umuman yetmaydi**.
- Ikkinchi oflayn yopish umuman bloklanardi ("Smena yopilmadi" — `blockingCloseIssue`).
- `user_id` yuborish paytidagi kassirdan olinardi → Alining smenasi Vali nomidan ketardi.
- Onlayn ochish POST'i yiqilsa (fire-and-forget) navbatga tushmasdi.
- Yopish-oldi dialogidagi "Yopishni yuborish" joriy (ochiq) smenani Pref'da yopiq qilib qo'yardi.

## 2. Qanday ishlaydi

- Navbat = Pref'dagi JSON ro'yxat (`PrefKeys.shiftSyncQueue = 'shift_sync_queue'`). Har voqea: `method` (`open`/`close`), `at` (UTC `yyyy-MM-dd HH:mm:ss`), `user_id`, `cashbox_id`, `failures`, `first_failure_at`. ObjectBox sxemasi o'zgarmaydi.
- **Qat'iy FIFO:** navbat bo'sh bo'lmasa yangi voqea to'g'ridan-to'g'ri yuborilmaydi — oxiriga qo'shiladi. `flush()` boshidan bittalab: 200/201 → olib tashlanadi.
- 200/201 bo'lmasa — **server holati** so'raladi (`shift_statuses`): kassa voqea kutgan holatda bo'lsa (ochish → ochiq, yopish → to'liq yopiq) voqea olinadi; aks holda navbatda qoladi va yuborish TO'XTAYDI (keyingilari kutadi). Sabab: status kodi "rad etdi" bilan "bir lahza yiqildi"ni ajrata olmaydi — haqiqiy smenani tashlagandan kutgan yaxshi (stend testi 500 da haqiqiy yopilish yo'qolishini ko'rsatdi).
- **Zaharli voqea:** server tirik + holat mos emas + ≥5 rad + birinchi raddan ≥1 soat → olib tashlanadi va hisobot (bitta buzuq voqea — masalan o'chirilgan kassir — navbatni va logout'ni abadiy to'smasin).
- Ochish: navbatda yetmagan voqea bo'lsa server holatiga qaramay lokal bajariladi (navbatga). Navbat bo'sh bo'lsa — avvalgidek `shift_statuses` tekshiruvi.
- Yopish: navbat bo'sh va server ishlayotgan bo'lsa to'g'ridan-to'g'ri; aks holda navbatga. Oflayn yopish cheklovi YO'Q.
- Eski kalitlar (`opened/closed Date/Count`) o'qishda ro'yxat oxiriga ko'chiriladi va birinchi yozishda tozalanadi (yangilangan kassada qolib ketgan navbat yo'qolmaydi).
- Logout: avval "Ochiq smenani yopishingiz kerak" (avvalgidek); smena yopiq bo'lsa navbat yuboriladi, qolsa — "Smena ma'lumotlari serverga hali yuborilmagan. Internetni tekshirib, keyinroq qayta urinib ko'ring." (chiqilmaydi).
- Oflayn belgi navbatdagi voqealar sonini ham ko'rsatadi.

Server xulqi (jonli dev, 2026-10-02): o'tgan/kechagi vaqtli ochish-yopishni ketma-ket qabul qiladi, takrorga 200 `{"message":"OK"}` (idempotent), vaqt tartibini tekshirmaydi, yo'q `user_id` → 500, yaroqsiz token → 403.

## 3. O'zgarishlar ro'yxati

| Fayl | Tur | Nima |
|---|---|---|
| `lib/changes/services/shift/shift_sync_queue.dart` | qayta yozilgan | `ShiftQueueEvent`, FIFO ro'yxat, `flush`, server holati tekshiruvi, zaharli voqea, eski kalitlar migratsiyasi |
| `lib/changes/services/shift_api_4.dart` | o'zgargan | `openShift/closeShift` — vaqt, `userId`, `cashboxId` parametr; `isCashboxFullyClosed` |
| `.../shift_4/singleton/shift_singleton_4.dart` | o'zgargan | Ochish/yopish navbat orqali; `syncCloseToServer`; voqea egasi — smena ochgan kassir |
| `lib/changes/services/shift/shift_diagnostics.dart` | o'zgargan | Navbatdan hisoblanadi; oflayn yopish cheklovi olib tashlandi |
| `lib/changes/providers/open_shift_provider.dart` | o'zgargan | Yopishdan oldin navbat yuboriladi; "Yopishni yuborish" ochiq smenaga tegmaydi |
| `.../child_settings/view/child_settings_content.dart` | o'zgargan | Logout: navbat yuborilmaguncha chiqilmaydi |
| `lib/features/home/components/offline_mode_badge.dart` | o'zgargan | Belgi soniga navbat ham qo'shiladi |
| `lib/utils/constants/pref_keys.dart` | o'zgargan | `shiftSyncQueue` |
| `test/shift_queue_scenarios_test.dart` | YANGI | Holatli soxta backend + uzilishlar + tasodifiy ketma-ketliklar (28 test) |
| `test/server_down_behaviour_test.dart`, `test/shift_close_guard_test.dart` | o'zgargan | Yangi navbat qoidalari |

## 4. Bog'liqliklar

- `BackendHealth` (2026-09-02, bu hujjatdan tashqarida): `isUsable`, `markUserInitiatedAction`. Bo'lmasa — "server ishlayaptimi" tekshiruvini InVan 1 dagi ekvivalentiga almashtiring.
- `ShiftApi4.shiftStatusInvan2()` (`shift_statuses`) — InVan backend endpointi; InVan 1 dagi ERP'da kassa holatini qaytaradigan so'rov kerak (bo'lmasa: holat tekshiruvi `null` qaytarsin — voqea navbatda qoladi, faqat 200/201 bilan olinadi).
- `ShiftDiagnostics` (2026-08-13 taski) — yopish-oldi ogohlantirishlari.

## 5. Qo'llash tartibi

1. `pref_keys.dart` (6.8), keyin `shift_sync_queue.dart` ni to'liq almashtiring (6.1).
2. `shift_api_4.dart` (6.2), `shift_singleton_4.dart` (6.3).
3. `shift_diagnostics.dart` (6.4), `open_shift_provider.dart` (6.5), logout (6.6), belgi (6.7).
4. Testlar (6.9). Og'ir rejim: `flutter test test/shift_queue_scenarios_test.dart --dart-define=SHIFT_FUZZ_SEEDS=2000`.

## 6. Kod

### 6.1. `lib/changes/services/shift/shift_sync_queue.dart` (to'liq)

```dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:invan2/changes/models/shift/shifting_model.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/shift/shift_diagnostics.dart';
import 'package:invan2/changes/services/shift_api_4.dart';
import 'package:invan2/utils/utils.dart';

enum ShiftQueueMethod { open, close }

/// Navbatdagi bitta voqea: smena ochildi yoki yopildi.
@immutable
class ShiftQueueEvent {
  const ShiftQueueEvent({
    required this.method,
    required this.at,
    required this.userId,
    required this.cashboxId,
    this.failures = 0,
    this.firstFailureAt,
  });

  final ShiftQueueMethod method;

  /// Voqea vaqti, `yyyy-MM-dd HH:mm:ss` (UTC) — serverga `opened_at` /
  /// `closed_at` bo'lib ketadi.
  final String at;

  /// Amalni bajargan kassir — voqea paytidagi `PrefKeys.userId`.
  final String userId;

  /// Voqea sodir bo'lgan kassa — voqea paytidagi `PrefKeys.activatedPosId`.
  /// Kassa keyin boshqasiga qayta aktivlashtirilsa ham voqea o'z kassasiga
  /// ketadi. Bo'sh bo'lsa (eski yozuv) — yuborish paytidagi kassa.
  final String cashboxId;

  /// Server TIRIK bo'lib (kassa holatini ko'rsatib) bu voqeani necha marta
  /// qabul qilmagan. Uzilish paytidagi urinishlar sanalmaydi.
  final int failures;

  /// Birinchi shunday rad etish vaqti.
  final DateTime? firstFailureAt;

  bool get isOpen => method == ShiftQueueMethod.open;

  bool get isClose => method == ShiftQueueMethod.close;

  /// Aynan shu voqeami. `userId` hisobga olinmaydi: eski kalitlardan
  /// tiklangan voqea `userId` ni joriy kassirdan oladi va u o'zgarishi
  /// mumkin. Bir xil turdagi ikki voqea bir soniyada sodir bo'lmaydi.
  bool sameAs(ShiftQueueEvent other) =>
      other.method == method && other.at == at;

  /// Yana bir rad etish qayd etilgan nusxa.
  ShiftQueueEvent withFailure(DateTime now) => ShiftQueueEvent(
        method: method,
        at: at,
        userId: userId,
        cashboxId: cashboxId,
        failures: failures + 1,
        firstFailureAt: firstFailureAt ?? now,
      );

  Map<String, dynamic> toJson() => {
        'method': method.name,
        'at': at,
        'user_id': userId,
        'cashbox_id': cashboxId,
        if (failures > 0) 'failures': failures,
        if (firstFailureAt != null)
          'first_failure_at': firstFailureAt!.toIso8601String(),
      };

  static ShiftQueueEvent? fromJson(dynamic json) {
    if (json is! Map) return null;
    final String at = '${json['at'] ?? ''}';
    if (at.isEmpty) return null;
    final String name = '${json['method']}';
    final ShiftQueueMethod method;
    if (name == 'open') {
      method = ShiftQueueMethod.open;
    } else if (name == 'close') {
      method = ShiftQueueMethod.close;
    } else {
      return null;
    }
    return ShiftQueueEvent(
      method: method,
      at: at,
      userId: '${json['user_id'] ?? ''}',
      cashboxId: '${json['cashbox_id'] ?? ''}',
      failures: int.tryParse('${json['failures'] ?? 0}') ?? 0,
      firstFailureAt: DateTime.tryParse('${json['first_failure_at'] ?? ''}'),
    );
  }

  @override
  String toString() => '${isOpen ? "ochish" : "yopish"} $at';
}

/// Serverga yetkazilmagan smena ochish/yopish voqealarining navbati.
///
/// Kassa oflayn ishlashi shart: server yoki internet bo'lmasa smena avval
/// **lokal** ochiladi/yopiladi, serverga yuborish esa shu navbatga qo'yiladi.
///
/// Navbat — voqealar RO'YXATI. Har voqea o'z vaqti va o'z kassiri bilan
/// saqlanadi va serverga aynan sodir bo'lgan tartibda (FIFO) yuboriladi.
///
/// Nima uchun ro'yxat. 2026-10-02 gacha navbatda ochish va yopish uchun
/// bittadan joy bor edi (`openedDate`/`closedDate`):
/// - ikkinchi oflayn ochish birinchisining vaqtini o'chirib yuborardi. Server
///   ertalabdan o'chiq kunda "ochish 08:00 → yopish 14:00 → ochish 14:05"
///   navbatda "yopish 14:00, ochish 14:05" bo'lib qolardi — 08:00–14:00
///   smenasi serverga UMUMAN yetmasdi (yopiq kassani yopishga server 200
///   qaytaradi, ya'ni yopish bekor ketardi — jonli dev sinovi, 2026-10-02);
/// - ikkinchi oflayn yopish umuman bloklanardi (joy band edi);
/// - `user_id` yuborish paytidagi kassirdan olinardi.
///
/// Haqiqiy server (dev, 2026-10-02 jonli sinov): o'tgan va hatto kechagi
/// vaqtli ochish/yopishni ketma-ket qabul qiladi (200), vaqt tartibini
/// tekshirmaydi, takror ochish/yopishga 200 "OK" qaytaradi (holat
/// o'zgarmaydi), mavjud bo'lmagan `user_id` ga 500 ("sql: no rows"),
/// yaroqsiz tokenga 403.
///
/// Qoidalar:
/// 1. Navbat bo'sh bo'lmasa yangi voqea to'g'ridan-to'g'ri serverga
///    yuborilmaydi — navbat oxiriga turadi (aks holda tartib buziladi).
/// 2. Yuborish birinchi voqeadan boshlanadi va u o'tmaguncha keyingisiga
///    o'tilmaydi.
/// 3. Server 200/201 qaytarmasa, voqea faqat serverdagi kassa holati
///    ALLAQACHON unga mos bo'lsa olib tashlanadi (javobi yo'qolgan yoki
///    takror yuborilgan voqea) — buni `shift_statuses` dan so'raymiz. Status
///    kodiga ishonilmaydi: qayta ishga tushayotgan server ham 500/404
///    qaytaradi va darhol tiriladi — kod bo'yicha "rad etildi" deb tashlab
///    yuborilgan haqiqiy yopilish serverni kassadan ajratib qo'yardi
///    (tasodifiy stend testida topilgan).
/// 4. Aks holda voqea navbatda qoladi va yuborish to'xtaydi (Telegram
///    hisoboti bilan) — keyingi urinishda davom etadi.
/// 5. ZAHARLI voqea: server TIRIK bo'lib (kassa holatini ko'rsatib) uni
///    kamida [poisonAttempts] marta va [poisonAfter] dan uzoq qabul
///    qilmasa (masalan kassir backend'da o'chirilgan) — u majburiy Telegram
///    hisoboti bilan olib tashlanadi. Aks holda bitta buzuq voqea butun
///    navbatni va tizimdan chiqishni abadiy to'sib qo'yardi.
class ShiftSyncQueue {
  ShiftSyncQueue._();

  static bool _inProgress = false;

  /// Zaharli voqea uchun eng kam rad etishlar soni (qoida 5).
  static const int poisonAttempts = 5;

  /// Zaharli voqea uchun birinchi rad etishdan beri o'tishi kerak bo'lgan
  /// vaqt (qoida 5). Qisqa qisman uzilishda haqiqiy voqea tashlanmasligi
  /// uchun uzun.
  static const Duration poisonAfter = Duration(hours: 1);

  /// Hozirgi vaqt — testlarda soatni oldinga surish uchun almashtiriladi.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  /* ─────────────────────────────── O'QISH ─────────────────────────────── */

  /// Navbatdagi voqealar — eskisidan yangisiga.
  static List<ShiftQueueEvent> get pending => _load();

  static int get pendingCount => _load().length;

  static bool get hasPending => _load().isNotEmpty;

  /// Navbatda kutayotgan yopish bormi.
  static bool get hasPendingClose => _load().any((e) => e.isClose);

  /// Navbatda kutayotgan ochish bormi.
  static bool get hasPendingOpen => _load().any((e) => e.isOpen);

  /// Hisobot uchun: "ochish 2026-10-02 03:00:00 → yopish ...".
  static String describe([List<ShiftQueueEvent>? events]) =>
      (events ?? _load()).join(' → ');

  /* ─────────────────────────────── YOZISH ─────────────────────────────── */

  /// Smena ochilishini navbatga qo'yadi. [at] — ochilish vaqti (UTC),
  /// [userId] / [cashboxId] — ochgan kassir va kassa (berilmasa joriy
  /// `PrefKeys.userId` / `PrefKeys.activatedPosId`).
  static Future<void> enqueueOpen(
    String at, {
    String? userId,
    String? cashboxId,
  }) =>
      _enqueue(ShiftQueueMethod.open, at, userId, cashboxId);

  /// Smena yopilishini navbatga qo'yadi. [at] — yopilish vaqti (UTC),
  /// [userId] / [cashboxId] — yopgan kassir va kassa (berilmasa joriy
  /// `PrefKeys.userId` / `PrefKeys.activatedPosId`).
  static Future<void> enqueueClose(
    String at, {
    String? userId,
    String? cashboxId,
  }) =>
      _enqueue(ShiftQueueMethod.close, at, userId, cashboxId);

  static Future<void> _enqueue(
    ShiftQueueMethod method,
    String at,
    String? userId,
    String? cashboxId,
  ) async {
    final List<ShiftQueueEvent> events = _load()
      ..add(ShiftQueueEvent(
        method: method,
        at: at,
        userId: userId ?? Pref.getString(PrefKeys.userId, ''),
        cashboxId: cashboxId ?? Pref.getString(PrefKeys.activatedPosId, ''),
      ));
    await _save(events);
  }

  /* ────────────────────────────── YUBORISH ────────────────────────────── */

  /// Navbatni serverga yuborishga urinadi.
  ///
  /// Xavfsiz: navbat bo'sh bo'lsa yoki boshqa urinish ketayotgan bo'lsa
  /// darhol qaytadi, shuning uchun istalgan joydan (startup, tarmoq yoki
  /// server tiklanganda, cheklar ketgandan keyin) chaqirish mumkin.
  static Future<void> flush({required String reason}) async {
    if (_inProgress || !hasPending) return;
    _inProgress = true;

    try {
      while (true) {
        final List<ShiftQueueEvent> events = _load();
        if (events.isEmpty) return;
        final ShiftQueueEvent event = events.first;

        final int status = await _send(event);
        if (kDebugMode) {
          print('ShiftSyncQueue: $event ($reason) → $status');
        }

        if (status == 200 || status == 201) {
          if (!await _remove(event)) return;
          continue;
        }

        // Muvaffaqiyat javobi kelmadi. Bu "server yiqilgan", "javob
        // yo'qolgan" yoki "server rad etdi" bo'lishi mumkin — status kodidan
        // ajratib bo'lmaydi: qayta ishga tushayotgan server ham 500/502/404
        // qaytaradi va bir lahzadan keyin tiriladi. Shuning uchun voqea
        // faqat serverning O'ZI tasdiqlaganda olib tashlanadi: kassa holati
        // allaqachon bu voqea kutgan holatda (javobi yo'qolgan yoki takror
        // yuborilgan voqea). Aks holda u navbatda qoladi — haqiqiy amal hech
        // qachon tashlab yuborilmaydi.
        final bool? applied = await _alreadyApplied(event);
        if (applied == true) {
          if (!await _remove(event)) return;
          await ShiftDiagnostics.report(
            issue: event.isOpen
                ? ShiftIssue.pendingOpenNotSynced
                : ShiftIssue.pendingCloseNotSynced,
            action: event.isOpen ? ShiftAction.open : ShiftAction.close,
            detail: 'Navbatdagi voqea ($reason): $event — server javobi '
                'status $status, lekin serverdagi kassa holati ALLAQACHON '
                'MOS (javob yo\'qolgan yoki takror). Voqea navbatdan olindi, '
                'keyingisi yuboriladi.\n'
                'Navbatda qoldi: ${_describeOrNone()}',
          );
          continue;
        }

        if (applied == false) {
          // Server TIRIK (kassa holatini ko'rsatdi), lekin voqeani qabul
          // qilmayapti. Qisqa qisman uzilish bo'lishi mumkin — darhol
          // tashlamaymiz, faqat sanaymiz (qoida 5).
          final ShiftQueueEvent counted = event.withFailure(now());
          if (counted.failures >= poisonAttempts &&
              now().difference(counted.firstFailureAt!) >= poisonAfter) {
            if (!await _remove(event)) return;
            await ShiftDiagnostics.report(
              issue: event.isOpen
                  ? ShiftIssue.pendingOpenNotSynced
                  : ShiftIssue.pendingCloseNotSynced,
              action: event.isOpen ? ShiftAction.open : ShiftAction.close,
              detail: 'ZAHARLI VOQEA NAVBATDAN OLIB TASHLANDI ($reason): '
                  '$event, user_id=${event.userId}, '
                  'cashbox_id=${_cashboxOf(event)}. Server tirik, lekin uni '
                  '${counted.failures} marta (birinchisi '
                  '${counted.firstFailureAt}) qabul qilmadi, oxirgi status '
                  '$status. Serverda QO\'LDA tekshiring — bu ochish/yopish '
                  'serverga yetmagan.\n'
                  'Navbatda qoldi: ${_describeOrNone()}',
              force: true,
            );
            continue;
          }
          await _replace(event, counted);
        }

        await ShiftDiagnostics.report(
          issue: event.isOpen
              ? ShiftIssue.pendingOpenNotSynced
              : ShiftIssue.pendingCloseNotSynced,
          action: event.isOpen ? ShiftAction.open : ShiftAction.close,
          detail: 'Navbatni yuborish ($reason) to\'xtadi: $event, '
              'status $status'
              '${applied == false ? ", server rad etdi (${event.failures + 1}-marta)" : ""}'
              '. Navbatda qoldi: ${_describeOrNone()}',
        );
        return;
      }
    } finally {
      _inProgress = false;
    }
  }

  static String _describeOrNone() {
    final String text = describe();
    return text.isEmpty ? "yo'q" : text;
  }

  /// Serverdagi kassa holati [event] kutgan holatdami: ochish uchun kassa
  /// ochiq, yopish uchun to'liq yopiq. `null` — bilib bo'lmadi (server
  /// javob bermadi yoki kassa ro'yxatda yo'q).
  static Future<bool?> _alreadyApplied(ShiftQueueEvent event) async {
    final HttpResult res = await ShiftApi4.shiftStatusInvan2();
    if (!res.isSuccess || res.result is! List) return null;
    final String cashboxId = _cashboxOf(event);
    for (final dynamic cashBox in res.result as List) {
      if (cashBox is Map && cashBox['cashbox_id'] == cashboxId) {
        final bool fullyClosed = ShiftApi4.isCashboxFullyClosed(cashBox);
        return event.isOpen ? !fullyClosed : fullyClosed;
      }
    }
    return null;
  }

  static String _cashboxOf(ShiftQueueEvent event) => event.cashboxId.isNotEmpty
      ? event.cashboxId
      : Pref.getString(PrefKeys.activatedPosId, '');

  /// Voqeani serverga yuboradi va HTTP status kodini qaytaradi.
  /// Istisno bo'lsa -2 (`ApiProvider` dagi "kutilmagan xato" kodi).
  static Future<int> _send(ShiftQueueEvent event) async {
    final String cashboxId = _cashboxOf(event);
    if (event.isOpen) {
      final HttpResult res = await ShiftApi4.openShift(
          openedAt: event.at, userId: event.userId, cashboxId: cashboxId);
      return res.statusCode;
    }
    final ShiftingModel res = await ShiftApi4.closeShift(
        closedAt: event.at, userId: event.userId, cashboxId: cashboxId);
    return res.statusCode ?? -2;
  }

  /// [old] o'rniga [updated] ni yozadi (rad etishlar hisobi uchun).
  static Future<void> _replace(
    ShiftQueueEvent old,
    ShiftQueueEvent updated,
  ) async {
    final List<ShiftQueueEvent> events = _load();
    final int index = events.indexWhere((e) => e.sameAs(old));
    if (index < 0) return;
    events[index] = updated;
    await _save(events);
  }

  /// [event] ni navbatdan olib tashlaydi. `false` — topilmadi.
  static Future<bool> _remove(ShiftQueueEvent event) async {
    final List<ShiftQueueEvent> events = _load();
    final int index = events.indexWhere((e) => e.sameAs(event));
    if (index < 0) return false;
    events.removeAt(index);
    await _save(events);
    return true;
  }

  /* ─────────────────────────────── SAQLASH ─────────────────────────────── */

  static List<ShiftQueueEvent> _load() {
    final List<ShiftQueueEvent> events = [];
    final String raw = Pref.getString(PrefKeys.shiftSyncQueue, '');
    if (raw.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final dynamic item in decoded) {
            final ShiftQueueEvent? event = ShiftQueueEvent.fromJson(item);
            if (event != null) events.add(event);
          }
        }
      } catch (_) {
        // Buzilgan yozuv — bo'sh navbat deb hisoblaymiz.
      }
    }

    // Eski kalitlar ro'yxat OXIRIGA qo'shiladi: oddiy yangilanishda ro'yxat
    // bo'sh, Shorebird rollback'dan keyin esa eski kod yozgan voqealar
    // ro'yxatdagilardan yangiroq. Ro'yxatga ko'chib bo'lganlari takrorlanmaydi
    // (yozuv o'rtasida ilova yopilgan bo'lsa).
    for (final ShiftQueueEvent legacy in _legacyEvents()) {
      if (!events.any((e) => e.sameAs(legacy))) events.add(legacy);
    }
    return events;
  }

  /// Ro'yxatni saqlaydi va eski kalitlarni tozalaydi — ulardagi voqealar
  /// endi ro'yxat ichida.
  static Future<void> _save(List<ShiftQueueEvent> events) async {
    await Pref.setString(
      PrefKeys.shiftSyncQueue,
      jsonEncode(events.map((e) => e.toJson()).toList()),
    );
    await Pref.setInt(PrefKeys.openedCount, 0);
    await Pref.setString(PrefKeys.openedDate, '');
    await Pref.setInt(PrefKeys.closedCount, 0);
    await Pref.setString(PrefKeys.closedDate, '');
  }

  /// Eski (2026-10-02 gacha) navbat kalitlaridagi voqealar.
  ///
  /// Kassa server o'chgan paytda yangilansa, navbat eski kalitlarda qolgan
  /// bo'ladi — u yo'qolmasligi kerak. Ikkalasi ham bo'lsa eski qoida bo'yicha
  /// vaqt tartibida (vaqt noaniq bo'lsa ochish oldin).
  static List<ShiftQueueEvent> _legacyEvents() {
    final String openedAt = Pref.getString(PrefKeys.openedDate, '');
    final String closedAt = Pref.getString(PrefKeys.closedDate, '');
    final bool hasOpen =
        openedAt.isNotEmpty && Pref.getInt(PrefKeys.openedCount, 0) == 1;
    final bool hasClose =
        closedAt.isNotEmpty && Pref.getInt(PrefKeys.closedCount, 0) == 1;
    if (!hasOpen && !hasClose) return const [];

    final String userId = Pref.getString(PrefKeys.userId, '');
    final String cashboxId = Pref.getString(PrefKeys.activatedPosId, '');
    final ShiftQueueEvent open = ShiftQueueEvent(
        method: ShiftQueueMethod.open,
        at: openedAt,
        userId: userId,
        cashboxId: cashboxId);
    final ShiftQueueEvent close = ShiftQueueEvent(
        method: ShiftQueueMethod.close,
        at: closedAt,
        userId: userId,
        cashboxId: cashboxId);
    if (!hasClose) return [open];
    if (!hasOpen) return [close];

    final DateTime? opened = DateTime.tryParse(openedAt);
    final DateTime? closed = DateTime.tryParse(closedAt);
    final bool openFirst =
        opened == null || closed == null || opened.isBefore(closed);
    return openFirst ? [open, close] : [close, open];
  }
}
```

### 6.2. `lib/changes/services/shift_api_4.dart`

```diff
diff --git a/lib/changes/services/shift_api_4.dart b/lib/changes/services/shift_api_4.dart
index c21ec83..43f2dc5 100644
--- a/lib/changes/services/shift_api_4.dart
+++ b/lib/changes/services/shift_api_4.dart
@@ -112,7 +112,16 @@ class ShiftApi4 {
   /////                   OPEN SHIFT                     /////
   /////                                                   /////
   /////////////////////////////////////////////////////////////
-  static Future<HttpResult> openShift() async {
+
+  /// [openedAt] — smena ochilgan vaqt (`yyyy-MM-dd HH:mm:ss`, UTC),
+  /// [userId] — ochgan kassir, [cashboxId] — kassa. Hammasi chaqiruvchidan
+  /// keladi: navbatdan yuborilganda ular yuborish paytidagi emas, ochish
+  /// paytidagi qiymatlar bo'lishi shart (qarang: `ShiftSyncQueue`).
+  static Future<HttpResult> openShift({
+    required String openedAt,
+    required String userId,
+    required String cashboxId,
+  }) async {
     final token = Pref.getString(PrefKeys.token, "not initialized");
     final headers = <String, String>{
       'Accept-Version': '2.0.0',
@@ -125,16 +134,15 @@ class ShiftApi4 {
       'timezone': "-300",
       'Accept-Service': _acceptService,
     };
-    String cashBoxId = Pref.getString(PrefKeys.activatedPosId, "");
 
     var body = {
-      "opened_at": Pref.getString(PrefKeys.openedDate, ""),
+      "opened_at": openedAt,
       "closed_at": "",
       "method": "open",
       "opened_by_pos": true,
       "opened_by_web": false,
-      "cashbox_id": cashBoxId,
-      "user_id": Pref.getString(PrefKeys.userId, "")
+      "cashbox_id": cashboxId,
+      "user_id": userId
     };
 
     return ApiProvider.postResponse(
@@ -144,6 +152,14 @@ class ShiftApi4 {
     );
   }
 
+  /// `shift_statuses` ro'yxatidagi kassa TO'LIQ yopiqmi (hech kim — na POS,
+  /// na web — ochmagan).
+  static bool isCashboxFullyClosed(Map<dynamic, dynamic> cashBox) =>
+      cashBox['opened_by_web'] == false &&
+      cashBox['opened_by_pos'] == false &&
+      cashBox['opened_by_user_id'] == '' &&
+      (cashBox['status'] == 'closed' || cashBox['status'] == 'close');
+
   static Future<HttpResult> shiftStatusInvan2({String? token}) async {
     // Aktivatsiyadan oldin (kassa tanlash) PrefKeys.token hali bo'sh bo'ladi,
     // shuning uchun login token'ini parametr orqali uzatish mumkin.
@@ -166,7 +182,17 @@ class ShiftApi4 {
   /////                                                   /////
   /////////////////////////////////////////////////////////////
 
-  static Future<ShiftingModel> closeShift() async {
+  /// [closedAt] — smena yopilgan vaqt (`yyyy-MM-dd HH:mm:ss`, UTC),
+  /// [userId] — yopgan kassir, [cashboxId] — kassa (qarang: [openShift]).
+  ///
+  /// Muvaffaqiyatsiz javobda ham `statusCode` haqiqiy HTTP kodi bo'ladi:
+  /// navbat u bo'yicha "server rad etdi" va "server javob bermadi" ni
+  /// ajratadi. Istisno bo'lsa `statusCode` — `null`.
+  static Future<ShiftingModel> closeShift({
+    required String closedAt,
+    required String userId,
+    required String cashboxId,
+  }) async {
     final token = Pref.getString(PrefKeys.token, "not initialized");
     ShiftingModel result = ShiftingModel();
     var headers = {
@@ -176,15 +202,14 @@ class ShiftApi4 {
       'timezone': "-300",
       'Content-Type': 'application/json'
     };
-    String cashId = Pref.getString(PrefKeys.activatedPosId, "");
     final body = {
       "opened_at": '',
-      "closed_at": Pref.getString(PrefKeys.closedDate, ""),
-      "cashbox_id": cashId,
+      "closed_at": closedAt,
+      "cashbox_id": cashboxId,
       "opened_by_pos": false,
       "opened_by_web": false,
       "method": "close",
-      "user_id": Pref.getString(PrefKeys.userId, "")
+      "user_id": userId
     };
     try {
       var response = await ApiProvider.postResponse(
@@ -193,9 +218,12 @@ class ShiftApi4 {
         headers: headers,
       );
       _statusCode = response.statusCode;
-      if (response.statusCode == 200) {
+      if (response.statusCode == 200 || response.statusCode == 201) {
         result.statusCode = response.statusCode;
-        result.message = response.result['message'];
+        // Javob tanasi Map bo'lmasa ham yopish muvaffaqiyatli — ilgari bu
+        // yerdagi istisno tasdiqlangan yopishni "xato" qilib qo'yardi.
+        final dynamic data = response.result;
+        result.message = data is Map ? data['message']?.toString() : null;
 
         LogRepository.addLog(
           """ HEADERS: => $headers, 
@@ -220,7 +248,9 @@ class ShiftApi4 {
           url: ApiProvider.baseUrlINVAN2,
           statusCode: _statusCode,
         );
-        return ShiftingModel()..message = "Failed";
+        return ShiftingModel()
+          ..statusCode = response.statusCode
+          ..message = "Failed";
       }
     } catch (e) {
       Log.e(e, name: 'shift_api_4.dart');
```

### 6.3. `lib/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart`

```diff
diff --git a/lib/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart b/lib/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart
index 0fefa17..f99d94a 100644
--- a/lib/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart
+++ b/lib/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart
@@ -1,3 +1,5 @@
+import 'dart:async';
+
 import 'package:flutter/material.dart';
 import 'package:hive_flutter/hive_flutter.dart';
 import 'package:intl/intl.dart';
@@ -5,6 +7,7 @@ import 'package:invan2/changes/models/shift/shift_hive_model.dart';
 import 'package:invan2/changes/repository/log_repository.dart';
 import 'package:invan2/changes/services/api/result_http_model.dart';
 import 'package:invan2/changes/services/shift/shift_diagnostics.dart';
+import 'package:invan2/changes/services/shift/shift_sync_queue.dart';
 import 'package:invan2/changes/services/shift_api_4.dart';
 import 'package:invan2/features/hive_repository/hive_boxes.dart';
 import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
@@ -18,6 +21,11 @@ import '../../../../../../../changes/models/shift/shifting_model.dart';
 import 'package:invan2/changes/services/health/backend_health.dart';
 
 class ShiftSingleton4 {
+  /// Smena ochilish/yopilish vaqti shu soatdan olinadi. Testlarda ketma-ket
+  /// amallarga aniq, farqli vaqt berish uchun almashtiriladi.
+  @visibleForTesting
+  static DateTime Function() clock = DateTime.now;
+
   static void updateTheShift(List<ReceiptModelPaymentType4> payments,
       double zdachaToCashBack, double discountAmount) async {
     num card = 0;
@@ -116,26 +124,46 @@ class ShiftSingleton4 {
     sh.iV = i;
     bool? isReturn = true;
 
-    await Pref.setString(PrefKeys.openedDate,
-        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()));
+    // Ochilish vaqti, kassir va kassa BIR MARTA olinadi: onlayn yuborilsa
+    // ham, navbatga tushsa ham serverga aynan shu qiymatlar ketadi.
+    final String openedAt =
+        DateFormat('yyyy-MM-dd HH:mm:ss').format(clock().toUtc());
+    final String userId = Pref.getString(PrefKeys.userId, '');
+    final String cashboxId = Pref.getString(PrefKeys.activatedPosId, '');
     await Pref.setInt(PrefKeys.currentShiftKey, i);
     // Har urinishdan oldin oldingi sababni tozalaymiz — UI faqat shu
     // urinishning sababini ko'rsatishi kerak.
     ShiftDiagnostics.resetOpenIssue();
 
-    /// Smenani serversiz (lokal) ochish — navbatga qo'yiladi.
+    /// Smenani serversiz (lokal) ochish — ochilish navbatga qo'yiladi.
     ///
-    /// Ikki holatda ishlatiladi: internet yo'q va server yiqilgan. Ikkalasi
-    /// ham kassa uchun bir xil: serverdagi holatni tekshirib bo'lmaydi,
-    /// lekin kassir sotishi kerak.
+    /// Internet yo'q, server yiqilgan yoki navbatda serverga yetmagan eski
+    /// voqealar bor — kassa uchun hammasi bir xil: kassir sotishi kerak,
+    /// ochilish esa navbat orqali o'z tartibida yetadi.
+    ///
+    /// Har ochilish navbatga alohida yoziladi. Ilgari navbatda ochish uchun
+    /// bitta joy bor edi va ikkinchi oflayn ochilish birinchisining vaqtini
+    /// o'chirib yuborardi (qarang: `ShiftSyncQueue`).
     Future<void> openOffline() async {
-      if (Pref.getInt(PrefKeys.openedCount, 0) == 0) {
-        isReturn = true;
-        await Pref.setInt(PrefKeys.openedCount, 1);
-      }
+      isReturn = true;
+      await ShiftSyncQueue.enqueueOpen(openedAt,
+          userId: userId, cashboxId: cashboxId);
     }
 
     if (await BackendHealth.isUsable()) {
+      // Serverga yetmagan eski voqealar (masalan oldingi smenaning yopilishi)
+      // avval ketsin — serverdagi kassa holati shundan keyingina to'g'ri.
+      await ShiftSyncQueue.flush(reason: 'before-open');
+
+      // Ular baribir ketmagan bo'lsa, serverdagi holat ESKIRGAN: masalan
+      // server kassani "ochiq" deb ko'rsatadi, chunki bizning yopilishimiz
+      // unga hali yetmagan. Unga ishonib ochishni bloklash noto'g'ri —
+      // smena lokal ochiladi va navbatda ularning ortidan turadi.
+      if (ShiftSyncQueue.hasPending) {
+        await openOffline();
+        return isReturn;
+      }
+
       await ShiftApi4.shiftStatusInvan2().then((HttpResult status) async {
         // 1a) Server yiqilgan (5xx / timeout / ulanmadi) — bu "smena
         // ochilmasin" degani EMAS. Internet uzilgandagi kabi lokal ochamiz
@@ -194,10 +222,7 @@ class ShiftSingleton4 {
         }
 
         // 4) Kassa serverda to'liq yopiqmi?
-        final bool isFullyClosed = myCashBox['opened_by_web'] == false &&
-            myCashBox['opened_by_pos'] == false &&
-            myCashBox['opened_by_user_id'] == '' &&
-            (myCashBox['status'] == 'closed' || myCashBox['status'] == 'close');
+        final bool isFullyClosed = ShiftApi4.isCashboxFullyClosed(myCashBox);
 
         if (!isFullyClosed) {
           ShiftDiagnostics.lastOpenIssue = myCashBox['opened_by_web'] == true
@@ -214,46 +239,61 @@ class ShiftSingleton4 {
           return;
         }
 
-        // 5) Hammasi joyida — smenani serverda ochamiz.
-        ShiftApi4.openShift().then(
-          (HttpResult value) async {
-            if (value.isSuccess) {
-              String localSUuid = const Uuid().v4();
-              sh
-                ..shiftId = localSUuid
-                ..iV = i;
-              await box.put(
-                i,
-                sh,
-              );
-            } else {
-              await box.put(i, sh);
-              // Smena kassada ochildi, lekin server tasdiqlamadi — keyinchalik
-              // yopishda "kassa serverda ochiq emas" muammosi chiqadi.
-              await ShiftDiagnostics.report(
-                issue: ShiftIssue.pendingOpenNotSynced,
-                action: ShiftAction.open,
-                detail: 'POST api/v1/shift_pos (open) → '
-                    'status ${value.statusCode}',
-              );
-            }
-          },
-        ).catchError(
-          (err) {
-            LogRepository.addLog(
-              err.toString(),
-              file: "ShiftSingleton_4 / openShift / catchError",
-              method: "OPEN SHIFT",
-              where: "SHIFT SINGLETON / CATCH ERROR",
-              path: "ShiftSingleton_4.dart",
-              statusCode: 0,
-              url: '-',
+        // 5) Hammasi joyida. Lekin navbatda hali ketmagan eski voqealar
+        // qolgan bo'lsa, bu ochilish ularning ORTIDAN ketishi kerak —
+        // to'g'ridan-to'g'ri yuborilsa server ularni noto'g'ri tartibda oladi.
+        if (ShiftSyncQueue.hasPending) {
+          await openOffline();
+          unawaited(ShiftSyncQueue.flush(reason: 'after-open'));
+          return;
+        }
+
+        // Navbat bo'sh — smenani serverda to'g'ridan-to'g'ri ochamiz.
+        //
+        // Javob KUTILADI: yiqilsa ochilish shu zahoti navbatga tushishi
+        // kerak. Ilgari so'rov kutilmasdi — kassir smenani ochib darhol
+        // yopsa, yopilish ochilishdan oldin serverga yetib bekor ketishi
+        // (server yopiq kassani yopishga 200 qaytaradi) va smena serverda
+        // ochiq qolishi mumkin edi.
+        try {
+          final HttpResult value = await ShiftApi4.openShift(
+              openedAt: openedAt, userId: userId, cashboxId: cashboxId);
+          if (value.isSuccess) {
+            String localSUuid = const Uuid().v4();
+            sh
+              ..shiftId = localSUuid
+              ..iV = i;
+            await box.put(
+              i,
+              sh,
             );
-          },
-        );
+          } else {
+            await box.put(i, sh);
+            // Server ochilishni tasdiqlamadi — navbatga qo'yamiz: server
+            // yiqilgan bo'lsa keyin yetadi, rad etgan bo'lsa navbat uni
+            // hisobot bilan olib tashlaydi. Ilgari bu ochilish yo'qolardi
+            // va kechqurun "kassa serverda ochiq emas" muammosi chiqardi.
+            await ShiftSyncQueue.enqueueOpen(openedAt,
+                userId: userId, cashboxId: cashboxId);
+            await ShiftDiagnostics.report(
+              issue: ShiftIssue.pendingOpenNotSynced,
+              action: ShiftAction.open,
+              detail: 'POST api/v1/shift_pos (open) → '
+                  'status ${value.statusCode}',
+            );
+          }
+        } catch (err) {
+          LogRepository.addLog(
+            err.toString(),
+            file: "ShiftSingleton_4 / openShift / catchError",
+            method: "OPEN SHIFT",
+            where: "SHIFT SINGLETON / CATCH ERROR",
+            path: "ShiftSingleton_4.dart",
+            statusCode: 0,
+            url: '-',
+          );
+        }
         isReturn = true;
-        await Pref.setInt(PrefKeys.openedCount, 0);
-        await Pref.setString(PrefKeys.openedDate, '');
       });
     } else {
       await openOffline();
@@ -273,50 +313,70 @@ class ShiftSingleton4 {
       ..isClosed = true;
     shift.closingTime = closingTime;
 
-    await Pref.setString(PrefKeys.closedDate,
-        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()));
     await box.put(currentShiftKey, shift);
     //-------------
 
-    /// Smenani serversiz yopish — yopish NAVBATGA qo'yiladi.
-    ///
-    /// `ShiftSyncQueue` navbatni ikki shart bo'yicha topadi: `closedDate`
-    /// bo'sh emas VA `closedCount == 1`. Shuning uchun hisoblagichni
-    /// qo'ymaslik yopishni butunlay yo'qotishga olib keladi.
+    final bool delivered = await syncCloseToServer(
+      // Yopilish vaqti, kassir va kassa BIR MARTA olinadi: onlayn yuborilsa
+      // ham, navbatga tushsa ham serverga aynan shu qiymatlar ketadi.
+      closedAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(clock().toUtc()),
+      userId: Pref.getString(PrefKeys.userId, ''),
+      cashboxId: Pref.getString(PrefKeys.activatedPosId, ''),
+    );
+    if (delivered) uploadHiveShifts();
+    return returnedShift;
+  }
+
+  /// Smena yopilishini serverga yetkazadi. `true` — server darhol tasdiqladi.
+  ///
+  /// Smena kassada HAR DOIM yopiladi (`shiftsOpened = false`). Server bilan
+  /// aloqa bo'lmasa, navbatda serverga yetmagan eski voqealar bo'lsa yoki
+  /// server tasdiqlamasa — yopilish navbatga tushadi. Navbat ro'yxat, har
+  /// yopilish alohida yoziladi: ilgari navbatda yopish uchun bitta joy bor
+  /// edi va internetsiz ikkinchi marta yopib bo'lmasdi.
+  ///
+  /// ObjectBox'ga tegmaydi (cheklar `closeShift` da) — shuning uchun
+  /// testlarda haqiqiy so'rovlar bilan alohida sinaladi.
+  @visibleForTesting
+  static Future<bool> syncCloseToServer({
+    required String closedAt,
+    required String userId,
+    required String cashboxId,
+  }) async {
     Future<void> closeOffline() async {
-      // Ochish navbatda turgani yopishga TO'SIQ EMAS: `ShiftSyncQueue` endi
-      // ikkalasini vaqt tartibida yuboradi (avval ochish, keyin yopish).
-      // Ilgari bu shart `openedCount == 0` ni ham talab qilardi — natijada
-      // server o'chgan kunda ertalab oflayn ochilgan smenani kechqurun
-      // umuman yopib bo'lmasdi.
-      //
-      // `closedCount == 0` sharti qoladi: navbatda bitta yopish uchungina
-      // joy bor, ikkinchisi birinchisining sanasini yo'q qilib yuborardi.
-      if (Pref.getInt(PrefKeys.closedCount, 0) == 0) {
-        await Pref.setBool(PrefKeys.shiftsOpened, false);
-        await Pref.setInt(PrefKeys.closedCount, 1);
-      }
+      await Pref.setBool(PrefKeys.shiftsOpened, false);
+      await ShiftSyncQueue.enqueueClose(closedAt,
+          userId: userId, cashboxId: cashboxId);
     }
 
-    if (await BackendHealth.isUsable()) {
-      ShiftingModel shiftingModel = await ShiftApi4.closeShift();
-      if (shiftingModel.statusCode != null && shiftingModel.statusCode == 200) {
-        uploadHiveShifts();
-        await Pref.setBool(PrefKeys.shiftsOpened, false);
-        await Pref.setString(PrefKeys.closedDate, '');
-        await Pref.setInt(PrefKeys.closedCount, 0);
-      } else if (BackendHealth.isServerFailureStatus(
-          shiftingModel.statusCode ?? 0)) {
-        // Server yiqilgan — internet uzilgandagi kabi navbatga qo'yamiz.
-        // Ilgari bu shox umuman yo'q edi: Hive'da smena "yopilgan" bo'lib
-        // qolar, `closedCount` esa 0 bo'lgani uchun navbat ham hosil
-        // bo'lmasdi — ya'ni yopilish serverga HECH QACHON yetmasdi.
-        await closeOffline();
-      }
-    } else {
+    if (!await BackendHealth.isUsable()) {
       await closeOffline();
+      return false;
     }
-    return returnedShift;
+
+    if (ShiftSyncQueue.hasPending) {
+      // Navbatda serverga yetmagan eski voqealar bor — bu yopilish ularning
+      // ORTIDAN ketishi kerak. To'g'ridan-to'g'ri yuborilsa, masalan,
+      // oflayn ochilgan smenaning yopilishi ochilishidan OLDIN yetib bekor
+      // ketardi (server yopiq kassani yopishga 200 qaytaradi), keyin
+      // yetgan ochilish esa kassani serverda ochiq qoldirardi.
+      await closeOffline();
+      unawaited(ShiftSyncQueue.flush(reason: 'after-close'));
+      return false;
+    }
+
+    final ShiftingModel shiftingModel = await ShiftApi4.closeShift(
+        closedAt: closedAt, userId: userId, cashboxId: cashboxId);
+    if (shiftingModel.statusCode == 200 || shiftingModel.statusCode == 201) {
+      await Pref.setBool(PrefKeys.shiftsOpened, false);
+      return true;
+    }
+
+    // Server yopilishni tasdiqlamadi — smena baribir kassada yopiladi,
+    // yopilish navbatga tushadi: server yiqilgan bo'lsa keyin yetadi,
+    // rad etgan bo'lsa navbat uni hisobot bilan olib tashlaydi.
+    await closeOffline();
+    return false;
   }
 
 //////////////////////////////////////////////////////////////////////////////
```

### 6.4. `lib/changes/services/shift/shift_diagnostics.dart`

```diff
diff --git a/lib/changes/services/shift/shift_diagnostics.dart b/lib/changes/services/shift/shift_diagnostics.dart
index 370868f..b7e1ada 100644
--- a/lib/changes/services/shift/shift_diagnostics.dart
+++ b/lib/changes/services/shift/shift_diagnostics.dart
@@ -1,4 +1,5 @@
 import 'package:invan2/changes/repository/log_repository.dart';
+import 'package:invan2/changes/services/shift/shift_sync_queue.dart';
 import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
 import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
 import 'package:invan2/objectbox.g.dart';
@@ -38,10 +39,6 @@ enum ShiftIssue {
   /// ko'rsatilardi, holbuki serverga umuman murojaat qilinmagan edi.
   offlineCloseBlockedByPendingOpen,
 
-  /// Internetsiz yopib bo'lmaydi: oldingi yopish hali navbatda
-  /// (`closedCount == 1`).
-  offlineCloseBlockedByPendingClose,
-
   /// Yopish so'rovi serverga ketdi, lekin server 200 qaytarmadi.
   serverCloseFailed,
 
@@ -84,24 +81,25 @@ class ShiftSnapshot {
     required this.posName,
     required this.cashboxId,
     required this.cashierName,
+    this.queueSummary = '',
   });
 
   final bool internet;
   final int unsentReceipts;
   final int rejectedReceipts;
 
-  /// `PrefKeys.closedDate` — bo'sh bo'lmasa, serverga yetmagan yopish bor.
+  /// Navbatdagi eng ESKI yopish vaqti (UTC) — bo'sh bo'lmasa, serverga
+  /// yetmagan yopish bor.
   final String pendingCloseAt;
 
-  /// `PrefKeys.openedDate` — bo'sh bo'lmasa, serverga yetmagan ochish bor.
+  /// Navbatdagi eng ESKI ochish vaqti (UTC) — bo'sh bo'lmasa, serverga
+  /// yetmagan ochish bor.
   final String pendingOpenAt;
 
-  /// `PrefKeys.openedCount` — 1 bo'lsa, smena OFLAYN ochilgan va ochilish
-  /// serverga yuborilishi kutilyapti.
+  /// Navbatda serverga yuborilishi kutilayotgan ochishlar soni.
   final int openedCount;
 
-  /// `PrefKeys.closedCount` — 1 bo'lsa, oflayn yopilish serverga yuborilishi
-  /// kutilyapti.
+  /// Navbatda serverga yuborilishi kutilayotgan yopishlar soni.
   final int closedCount;
 
   final bool shiftsOpened;
@@ -110,21 +108,12 @@ class ShiftSnapshot {
   final String cashboxId;
   final String cashierName;
 
+  /// Navbat tarkibi, hisobot uchun ("ochish ... → yopish ...").
+  final String queueSummary;
+
   bool get hasPendingClose => pendingCloseAt.isNotEmpty;
 
   bool get hasPendingOpen => pendingOpenAt.isNotEmpty;
-
-  /// Internetsiz yopish mumkinmi.
-  ///
-  /// `ShiftSingleton4.closeShift` ning oflayn shoxidagi shartning aynan
-  /// nusxasi — ikkalasi bir joydan o'qilishi kerak, aks holda UI "yopiladi"
-  /// deb va'da berib, kod yopmay qo'yadi (2026-08-17 hodisasi).
-  /// Serverga ulanmasdan yopish mumkinmi.
-  ///
-  /// Navbatda OCHISH turgani to'siq emas — `ShiftSyncQueue` ochish va
-  /// yopishni vaqt tartibida yuboradi. Faqat navbatda allaqachon YOPISH
-  /// turgan bo'lsa mumkin emas: navbatda bitta yopish uchungina joy bor.
-  bool get canCloseOffline => closedCount == 0;
 }
 
 class ShiftDiagnostics {
@@ -178,19 +167,28 @@ class ShiftDiagnostics {
       // ObjectBox o'qib bo'lmasa ham diagnostika ishlashda davom etsin.
     }
 
+    final List<ShiftQueueEvent> queue = ShiftSyncQueue.pending;
+    String oldest(ShiftQueueMethod method) {
+      for (final ShiftQueueEvent e in queue) {
+        if (e.method == method) return e.at;
+      }
+      return '';
+    }
+
     return ShiftSnapshot(
       internet: hasNet,
       unsentReceipts: unsent,
       rejectedReceipts: rejected,
-      pendingCloseAt: Pref.getString(PrefKeys.closedDate, ''),
-      pendingOpenAt: Pref.getString(PrefKeys.openedDate, ''),
-      openedCount: Pref.getInt(PrefKeys.openedCount, 0),
-      closedCount: Pref.getInt(PrefKeys.closedCount, 0),
+      pendingCloseAt: oldest(ShiftQueueMethod.close),
+      pendingOpenAt: oldest(ShiftQueueMethod.open),
+      openedCount: queue.where((e) => e.isOpen).length,
+      closedCount: queue.where((e) => e.isClose).length,
       shiftsOpened: Pref.getBool(PrefKeys.shiftsOpened, false),
       currentShiftKey: Pref.getInt(PrefKeys.currentShiftKey, -1),
       posName: Pref.getString(PrefKeys.posName, '-'),
       cashboxId: Pref.getString(PrefKeys.activatedPosId, ''),
       cashierName: Pref.getString(PrefKeys.cashierName, '-'),
+      queueSummary: ShiftSyncQueue.describe(queue),
     );
   }
 
@@ -205,21 +203,10 @@ class ShiftDiagnostics {
   /// bermaydi — ogohlantirish shunchaki shovqin bo'lardi. Ular baribir
   /// Telegram hisobotida (`Rad etilgan cheklar: N`) ko'rinadi va Sozlamalar →
   /// rad etilgan cheklar bo'limidan alohida boshqariladi.
-  /// Smenani yopish **umuman mumkin emas** bo'lgan holat.
-  ///
-  /// `null` qaytsa — yopishga urinish mumkin. Aks holda yopish tugmasi
-  /// bosilganda hech narsa yozilmasligi kerak: `ShiftSingleton4.closeShift`
-  /// Hive yozuviga `isClosed=true` va `closedDate` ni **shartni tekshirishdan
-  /// oldin** yozadi, keyin esa shart bajarilmasa smenani yopmay qo'yadi.
-  /// Natijada Hive'da "yopiq", POS'da "ochiq" — nomuvofiq holat qoladi.
   ///
-  /// Faqat oflayn holat tekshiriladi: internet bo'lsa yopish server javobiga
-  /// qarab hal qilinadi.
-  static ShiftIssue? blockingCloseIssue(ShiftSnapshot s) {
-    if (s.internet || s.canCloseOffline) return null;
-    return ShiftIssue.offlineCloseBlockedByPendingClose;
-  }
-
+  /// Yopishni TO'SADIGAN holat yo'q: smena navbati ro'yxat bo'lgani uchun
+  /// internetsiz ham istalgancha yopish mumkin (2026-10-02 gacha navbatda
+  /// bitta yopish uchun joy bor edi va ikkinchisi bloklanardi).
   static List<ShiftIssue> closeWarnings(ShiftSnapshot s) {
     final List<ShiftIssue> issues = [];
     if (!s.internet) issues.add(ShiftIssue.noInternet);
@@ -252,10 +239,6 @@ class ShiftDiagnostics {
         return isUz
             ? 'Smena yopilmadi — ochilishi serverga yetmagan'
             : 'Смена не закрыта — открытие не дошло до сервера';
-      case ShiftIssue.offlineCloseBlockedByPendingClose:
-        return isUz
-            ? 'Smena yopilmadi — oldingi yopish navbatda'
-            : 'Смена не закрыта — прошлое закрытие в очереди';
       case ShiftIssue.serverCloseFailed:
         return isUz
             ? 'Server smenani yopmadi'
@@ -296,13 +279,9 @@ class ShiftDiagnostics {
       case ShiftIssue.noInternet:
         return isUz
             ? 'Internet ulanmagan. Smena kassada yopiladi va serverga yuborish '
-                'navbatiga tushadi — internet tiklangach avtomatik yuboriladi. '
-                'Yopish serverga yetmaguncha bu kassada keyingi smenani '
-                'internetsiz yopib bo\'lmaydi.'
+                'navbatiga tushadi — internet tiklangach avtomatik yuboriladi.'
             : 'Нет интернета. Смена закроется на кассе и попадёт в очередь '
-                'отправки — уйдёт автоматически после восстановления связи. Пока '
-                'закрытие не дошло до сервера, следующую смену на этой кассе без '
-                'интернета закрыть не получится.';
+                'отправки — уйдёт автоматически после восстановления связи.';
       case ShiftIssue.unsentReceipts:
         return isUz
             ? '${s.unsentReceipts} ta chek hali serverga yuborilmagan. '
@@ -355,29 +334,11 @@ class ShiftDiagnostics {
                 'открытие смены уйдёт на сервер автоматически — после этого '
                 'закройте смену как обычно.\n'
                 'Продажи и чеки не потеряются, всё сохранено на кассе.';
-      case ShiftIssue.offlineCloseBlockedByPendingClose:
-        final ago = _agoText(s.pendingCloseAt, isUz: isUz);
-        return isUz
-            ? 'NIMA BO\'LDI: Smena yopilmadi — kassada ochiq qoldi.\n'
-                'SABAB: Oldingi smena yopilishi hali serverga yuborilmagan$ago. '
-                'Kassa bir vaqtda faqat bitta yuborilmagan yopishni saqlay '
-                'oladi, shuning uchun internetsiz ikkinchi marta yopib '
-                'bo\'lmaydi.\n'
-                'NIMA QILISH KERAK: Internetni ulang — navbatdagi yopish '
-                'yuboriladi, shundan keyin bu smenani yopasiz.\n'
-                'Sotuvlar va cheklar yo\'qolmaydi.'
-            : 'ЧТО ПРОИЗОШЛО: Смена не закрыта — осталась открытой на кассе.\n'
-                'ПРИЧИНА: Закрытие прошлой смены ещё не отправлено на сервер'
-                '$ago. Касса хранит только одно неотправленное закрытие, '
-                'поэтому без интернета закрыть второй раз нельзя.\n'
-                'ЧТО ДЕЛАТЬ: Подключите интернет — закрытие из очереди уйдёт на '
-                'сервер, после этого закройте эту смену.\n'
-                'Продажи и чеки не потеряются.';
       case ShiftIssue.serverCloseFailed:
-        // Navbatga tushdimi? `ShiftSyncQueue` faqat `closedCount == 1` bo'lsa
-        // qayta yuboradi. Aks holda "qayta yuboriladi" deb va'da berish
-        // yolg'on bo'ladi — kassir kutib o'tiradi, hech narsa ketmaydi.
-        final bool queued = s.closedCount == 1 && s.hasPendingClose;
+        // Navbatga tushdimi? Faqat navbatdagi yopish qayta yuboriladi. Aks
+        // holda "qayta yuboriladi" deb va'da berish yolg'on bo'ladi — kassir
+        // kutib o'tiradi, hech narsa ketmaydi.
+        final bool queued = s.hasPendingClose;
         return isUz
             ? 'NIMA BO\'LDI: Smena kassada yopildi, lekin server tasdiqlamadi.\n'
                 'SABAB: Yopish so\'rovi serverga yuborildi, server esa muvaffaqiyat '
@@ -538,7 +499,9 @@ class ShiftDiagnostics {
               "${_agoText(s.pendingCloseAt, isUz: true)}" : "yo'q"}')
       ..writeln('Serverga yetmagan OCHISH: '
           '${s.hasPendingOpen ? "${s.pendingOpenAt} UTC"
-              "${_agoText(s.pendingOpenAt, isUz: true)}" : "yo'q"}');
+              "${_agoText(s.pendingOpenAt, isUz: true)}" : "yo'q"}')
+      ..writeln('Smena navbati: '
+          '${s.queueSummary.isEmpty ? "bo'sh" : "${s.queueSummary} (UTC)"}');
 
     if (detail != null && detail.trim().isNotEmpty) {
       buffer
```

### 6.5. `lib/changes/providers/open_shift_provider.dart`

```diff
diff --git a/lib/changes/providers/open_shift_provider.dart b/lib/changes/providers/open_shift_provider.dart
index 05f9e6c..2d49f32 100644
--- a/lib/changes/providers/open_shift_provider.dart
+++ b/lib/changes/providers/open_shift_provider.dart
@@ -4,6 +4,7 @@ import 'package:flutter_bloc/flutter_bloc.dart';
 import 'package:hive/hive.dart';
 import 'package:invan2/app_navigation.dart';
 import 'package:invan2/changes/models/shift/shift_hive_model.dart';
+import 'package:invan2/changes/services/health/backend_health.dart';
 import 'package:invan2/changes/services/shift/shift_diagnostics.dart';
 import 'package:invan2/changes/services/shift/shift_sync_queue.dart';
 import 'package:invan2/features/checks/features/checks_app_bar/bloc/usr_bloc.dart';
@@ -14,7 +15,6 @@ import 'package:invan2/widgets/my_snackbar.dart';
 import 'package:invan2/widgets/shift_warning_dialog.dart';
 import 'package:provider/provider.dart';
 import '../../features/hive_repository/hive_boxes.dart';
-import '../models/shift/shifting_model.dart';
 import '../services/api.dart';
 
 class OpenShiftProvider extends ChangeNotifier {
@@ -120,11 +120,10 @@ class OpenShiftProvider extends ChangeNotifier {
     notifyListeners();
     ShiftSnapshot snapshot = await ShiftDiagnostics.capture();
 
-    // Navbatda ochish/yopish turgan bo'lsa, internet bor ekan — avval o'shani
-    // yuboramiz. Aks holda serverda ochilmagan smenani yopishga urinamiz va
-    // server rad etadi. Bu yerda `flush` tartibi ham to'g'ri: avval yopish,
-    // keyin ochish.
-    if (snapshot.internet && !snapshot.canCloseOffline) {
+    // Navbatda serverga yetmagan ochish/yopish turgan bo'lsa, internet bor
+    // ekan — avval o'shani yuboramiz: bu smenaning yopilishi ulardan KEYIN
+    // ketishi kerak (navbat qat'iy tartibda yuboriladi).
+    if (snapshot.internet && ShiftSyncQueue.hasPending) {
       await ShiftSyncQueue.flush(reason: 'before-close');
       snapshot = await ShiftDiagnostics.capture(internet: true);
     }
@@ -132,34 +131,8 @@ class OpenShiftProvider extends ChangeNotifier {
     _isWaiting = false;
     notifyListeners();
 
-    // 1) Yopish umuman mumkinmi? Mumkin bo'lmasa hech narsa yozilmasligi
-    // kerak: `ShiftSingleton4.closeShift` Hive yozuviga `isClosed=true` va
-    // `closedDate` ni shartni tekshirishdan OLDIN yozadi, keyin esa smenani
-    // yopmay qo'yadi. 2026-08-17 da kassir aynan shu sababli "Smena yopildi"
-    // degan xabarni ko'rib, smena ochiq qolganini keyin bilgan.
-    final ShiftIssue? blocker = ShiftDiagnostics.blockingCloseIssue(snapshot);
-    if (blocker != null) {
-      await ShiftDiagnostics.report(
-        issue: blocker,
-        action: ShiftAction.close,
-        snapshot: snapshot,
-        detail: 'Yopish boshlanmadi (oflayn shart bajarilmaydi): '
-            'openedCount=${snapshot.openedCount}, '
-            'closedCount=${snapshot.closedCount}',
-      );
-      await showShiftWarningDialog(
-        context,
-        issues: [blocker],
-        snapshot: snapshot,
-        isUz: isUz,
-        action: ShiftAction.close,
-        infoOnly: true,
-        succeeded: false,
-      );
-      return false;
-    }
-
-    // 2) Yopish mumkin, lekin e'tibor berish kerak bo'lgan holatlar.
+    // Yopishni to'sadigan holat yo'q (navbat ro'yxat — internetsiz ham
+    // istalgancha yopish mumkin). Faqat e'tibor berish kerak bo'lganlari.
     final List<ShiftIssue> warnings = ShiftDiagnostics.closeWarnings(snapshot);
     if (warnings.isEmpty) return true;
 
@@ -204,11 +177,17 @@ class OpenShiftProvider extends ChangeNotifier {
     }
   }
 
-  /// Serverga yetmagan smena yopilishini qo'lda qayta yuboradi.
+  /// Serverga yetmagan smena voqealarini (yopish va ochishlarni) qo'lda
+  /// yuboradi — navbatdagi tartibida.
   ///
   /// 2026-08-13 hodisasida aynan shu yo'l yetishmagan edi: lokal smena yopiq,
   /// serverda ochiq — va yopishni qayta yuborishning hech qanday usuli yo'q edi,
   /// shu sababli kassa butunlay bloklanib qolgan.
+  ///
+  /// Joriy smenaning holatiga (`shiftsOpened`) TEGILMAYDI: navbatdagi yopish
+  /// doim OLDINGI smenaniki — joriy smena yopilganda u allaqachon `false`.
+  /// Ilgari bu yerda `shiftsOpened=false` qilinardi va tugma yopish-oldi
+  /// dialogidan bosilsa, ochiq smena Pref'da yopiq bo'lib qolardi.
   Future<void> sendPendingCloseToServer(
     BuildContext context, {
     required bool isUz,
@@ -216,20 +195,17 @@ class OpenShiftProvider extends ChangeNotifier {
     _isWaiting = true;
     notifyListeners();
 
-    ShiftingModel result = await ShiftApi4.closeShift();
-    final bool ok = result.statusCode == 200;
+    // Kassir o'zi bosdi — "server o'chgan" degan xotira so'rovni to'smasin.
+    BackendHealth.markUserInitiatedAction();
+    await ShiftSyncQueue.flush(reason: 'manual');
+    final bool ok = !ShiftSyncQueue.hasPending;
 
-    if (ok) {
-      await Pref.setString(PrefKeys.closedDate, '');
-      await Pref.setInt(PrefKeys.closedCount, 0);
-      await Pref.setBool(PrefKeys.shiftsOpened, false);
-      _isShiftOpened = false;
-    } else {
+    if (!ok) {
       await ShiftDiagnostics.report(
         issue: ShiftIssue.serverCloseFailed,
         action: ShiftAction.close,
-        detail: 'Kassir "Yopishni yuborish" tugmasini bosdi, server javobi: '
-            '${result.statusCode ?? "-"} / ${result.message ?? "-"}',
+        detail: 'Kassir "Yopishni yuborish" tugmasini bosdi — navbat to\'liq '
+            'ketmadi. Navbatda qoldi: ${ShiftSyncQueue.describe()}',
       );
     }
 
@@ -335,11 +311,11 @@ class OpenShiftProvider extends ChangeNotifier {
       }
       _isShiftOpened = false;
 
-      // Smena kassada yopildi. Lekin serverga yetdimi? `closedDate` faqat
-      // server 200 qaytarganda tozalanadi — bo'sh bo'lmasa, yopilish navbatda
-      // qolgan va bu kassada yangi smena OCHILMAYDI. Kassir buni hozir
-      // bilishi kerak, 15 marta "smena ochish"ni bosgandan keyin emas.
-      if (Pref.getString(PrefKeys.closedDate, '').isNotEmpty) {
+      // Smena kassada yopildi. Lekin serverga yetdimi? Navbatda yopish
+      // qolgan bo'lsa — server bu kassani hali "ochiq" deb hisoblaydi. Kassir
+      // buni hozir bilishi kerak, 15 marta "smena ochish"ni bosgandan keyin
+      // emas.
+      if (ShiftSyncQueue.hasPendingClose) {
         await ShiftDiagnostics.report(
           issue: ShiftIssue.pendingCloseNotSynced,
           action: ShiftAction.close,
```

### 6.6. `lib/features/settings/features/child_settings/view/child_settings_content.dart`

```diff
diff --git a/lib/features/settings/features/child_settings/view/child_settings_content.dart b/lib/features/settings/features/child_settings/view/child_settings_content.dart
index c362abd..d6e922d 100644
--- a/lib/features/settings/features/child_settings/view/child_settings_content.dart
+++ b/lib/features/settings/features/child_settings/view/child_settings_content.dart
@@ -8,7 +8,10 @@ import 'package:invan2/features/settings/bloc/settings_bloc.dart';
 import 'package:invan2/features/settings/features/child_settings/dialogs/before_log_out_dialog.dart';
 import '../../../../../changes/services/api.dart';
 import '../../../../../changes/services/api/result_http_model.dart';
+import '../../../../../changes/services/health/backend_health.dart';
+import '../../../../../changes/services/shift/shift_sync_queue.dart';
 import '../../../../../utils/helpers/auth_reset.dart';
+import '../../../../../widgets/my_snackbar.dart';
 import 'item_list_tile.dart';
 import '../dialogs/language_dialog.dart';
 import '../dialogs/tarozi_prefix_dialog.dart';
@@ -99,6 +102,29 @@ class _ChildSettingsContentState extends State<ChildSettingsContent> {
                 builder: (_) => const BeforeLogOutDialog(isAboutShift: true),
               );
             } else {
+              // Smena yopiq. Chiqishda butun Pref tozalanadi — serverga
+              // yetmagan smena ochish/yopishlari ham. Avval ularni yuboramiz;
+              // ketmasa chiqish to'xtatiladi, aks holda yopilish yo'qolib,
+              // server kassani "ochiq" deb qoladi.
+              if (ShiftSyncQueue.hasPending) {
+                BackendHealth.markUserInitiatedAction();
+                await ShiftSyncQueue.flush(reason: 'before-logout');
+                if (ShiftSyncQueue.hasPending) {
+                  if (!context.mounted) return;
+                  final bool isUz = loc.ha.toLowerCase() == 'ha';
+                  ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
+                    context,
+                    msg: isUz
+                        ? 'Smena ma\'lumotlari serverga hali yuborilmagan. '
+                            'Internetni tekshirib, keyinroq qayta urinib '
+                            'ko\'ring.'
+                        : 'Данные смены ещё не отправлены на сервер. '
+                            'Проверьте интернет и попробуйте позже.',
+                    duration: 4000,
+                  ));
+                  return;
+                }
+              }
               HttpResult httpResult = await ShiftApi4.closeCashBox();
               if (!httpResult.isSuccess) {
                 showDialog(
```

### 6.7. `lib/features/home/components/offline_mode_badge.dart`

```diff
diff --git a/lib/features/home/components/offline_mode_badge.dart b/lib/features/home/components/offline_mode_badge.dart
index 68e677f..9ed2ace 100644
--- a/lib/features/home/components/offline_mode_badge.dart
+++ b/lib/features/home/components/offline_mode_badge.dart
@@ -75,7 +75,7 @@ class _OfflineModeBadgeState extends State<OfflineModeBadge> {
           .build();
       total = query.count();
       query.close();
-      if (ShiftSyncQueue.hasPending) total++;
+      total += ShiftSyncQueue.pendingCount;
     } catch (_) {
       // Sanoq ixtiyoriy — xato bo'lsa belgi baribir ko'rsatiladi.
     }
```

### 6.8. `lib/utils/constants/pref_keys.dart`

```dart
  /// Smena navbati — serverga yetmagan ochish/yopishlar ro'yxati (JSON).
  /// Qarang: `ShiftSyncQueue`.
  static const String shiftSyncQueue = 'shift_sync_queue';
  /// ESKI navbat kalitlari (2026-10-02 gacha). Yangi kod ularga yozmaydi —
  /// faqat yangilangan kassada qolib ketgan navbatni `ShiftSyncQueue`
  /// ro'yxatiga ko'chirish uchun o'qiladi.
```

(Eski kalitlar — `openedDate`, `openedCount`, `closedDate`, `closedCount` — o'z joyida qoladi.)

### 6.9. Testlar

<details><summary>YANGI: <code>test/shift_queue_scenarios_test.dart</code></summary>

```dart
// Smena navbati — "haqiqiy serverga o'xshash" stend.
//
// Nima uchun: smena ochish/yopishning serverga yetishi kassaning eng nozik
// joyi. Kassir har xil ketma-ketlik qiladi (ochdi-yopdi-ochdi...), tarmoq esa
// istalgan paytda uzilishi, server yiqilishi, javob yo'qolishi mumkin.
//
// Stend:
// - lokal HTTP server kassa holatini (ochiq/yopiq) ESLAYDI va noto'g'ri
//   o'tishni (ochiq kassani ochish, yopiq kassani yopish) RAD ETADI — xuddi
//   haqiqiy backend kabi. Rad etish kodi sozlanadi (400/409/500/200/403),
//   chunki haqiqiy server aynan qaysi kodni qaytarishi jonli tekshirilmagan;
// - uzilishlar qo'lda beriladi: server 500, internet yo'q (ulanish uziladi),
//   Wi-Fi login sahifasi (200 + HTML), token eskirgan (401), javob yo'qolishi
//   (server bajardi, lekin javob kassaga yetmadi);
// - ilovaning HAQIQIY kodi ishlaydi: ShiftSingleton4.openShift,
//   ShiftSingleton4.syncCloseToServer, ShiftSyncQueue, ShiftApi4, ApiProvider,
//   BackendHealth. Faqat transport lokal serverga yo'naltiriladi.
//
// Asosiy talab — har qanday ketma-ketlikdan keyin, aloqa tiklangach:
// 1. navbat bo'sh (hech narsa tiqilib qolmagan);
// 2. serverdagi kassa holati kassadagi bilan bir xil;
// 3. server qabul qilgan amallar = kassir bajargan amallar: aynan shu
//    tartibda, aynan shu vaqtlar bilan, har biri BIR martadan.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:invan2/changes/models/log/log_model.dart';
import 'package:invan2/changes/models/shift/shift_hive_model.dart';
import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/health/backend_health.dart';
import 'package:invan2/changes/services/shift/shift_sync_queue.dart';
import 'package:invan2/features/get_employees/model/employees_find_response.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

/// Tarmoq / server holati.
enum _Net {
  /// Hammasi ishlaydi.
  up,

  /// Server yiqilgan — har so'rovga 500.
  down500,

  /// Internet yo'q — ulanish javobsiz uziladi.
  internetOff,

  /// Wi-Fi login sahifasi: har so'rovga 200 + HTML.
  captivePortal,

  /// Token eskirgan — har so'rovga 401.
  unauthorized,
}

/// Kassa holatini eslaydigan soxta backend.
class _FakeBackend {
  late HttpServer _http;

  _Net net = _Net.up;

  /// Noto'g'ri o'tishga (ochiq kassani ochish / yopiq kassani yopish) server
  /// javobi. 200 — "idempotent" server: xato demaydi, holat o'zgarmaydi.
  int rejectStatus = 400;

  /// Keyingi ochish/yopish BAJARILADI, lekin javob kassaga yetmaydi.
  bool loseNextResponse = false;

  /// Keyingi ochish/yopish BAJARILMAYDI va shu status qaytadi — server
  /// bir lahzaga yiqildi (qayta ishga tushyapti), so'ng darhol tirildi.
  int? failNextMutationWith;

  /// Server ochishni DOIMIY rad etadi (masalan validatsiya xatosi) — kassa
  /// yopiq bo'lsa ham.
  bool refuseOpens = false;

  /// Backend'da o'chirilgan kassirlar: ularning ochish/yopishiga haqiqiy
  /// server 500 "sql: no rows in result set" qaytaradi (jonli dev sinovi).
  final Set<String> unknownUsers = {};

  /// cashbox_id → serverda ochiqmi.
  final Map<String, bool> open = {};

  /// Server qabul qilgan amallar: `open@vaqt@kassa`.
  final List<String> accepted = [];

  int get port => _http.port;

  Future<void> start() async {
    _http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _http.listen(_handle);
  }

  Future<void> stop() => _http.close(force: true);

  void reset() {
    net = _Net.up;
    rejectStatus = 400;
    loseNextResponse = false;
    failNextMutationWith = null;
    refuseOpens = false;
    unknownUsers.clear();
    open
      ..clear()
      ..['kassa-1'] = false;
    accepted.clear();
  }

  Future<void> _handle(HttpRequest req) async {
    final String body = await utf8.decoder.bind(req).join();
    switch (net) {
      case _Net.internetOff:
        await _drop(req);
        return;
      case _Net.down500:
        await _reply(req, 500, '{"message":"Internal Server Error"}');
        return;
      case _Net.unauthorized:
        await _reply(req, 401, '{"message":"Unauthorized"}');
        return;
      case _Net.captivePortal:
        await _reply(req, 200, '<html><body>Wi-Fi login</body></html>');
        return;
      case _Net.up:
        break;
    }

    final String path = req.uri.path;
    if (path.endsWith('shift_statuses')) {
      final List<Map<String, dynamic>> list = open.entries
          .map((e) => <String, dynamic>{
                'cashbox_id': e.key,
                'cashbox_name': 'Kassa ${e.key}',
                'status': e.value ? 'open' : 'closed',
                'opened_by_pos': e.value,
                'opened_by_web': false,
                'opened_by_user_id': e.value ? 'kimdir' : '',
              })
          .toList();
      await _reply(req, 200, jsonEncode(list));
      return;
    }

    if (path.endsWith('shift_pos')) {
      final Map<String, dynamic> data = jsonDecode(body);
      final String cashbox = '${data['cashbox_id']}';
      final bool wantsOpen = data['method'] == 'open';
      final String at =
          wantsOpen ? '${data['opened_at']}' : '${data['closed_at']}';
      final bool isOpen = open[cashbox] ?? false;
      final int? fail = failNextMutationWith;
      if (fail != null) {
        failNextMutationWith = null;
        await _reply(req, fail, '{"message":"temporarily unavailable"}');
        return;
      }
      if (wantsOpen && refuseOpens) {
        await _reply(req, 400, '{"message":"validation failed"}');
        return;
      }
      if (unknownUsers.contains('${data['user_id']}')) {
        await _reply(req, 500,
            '{"error":"rpc error: code = Unknown desc = sql: no rows in result set"}');
        return;
      }
      if (wantsOpen == isOpen) {
        await _reply(
          req,
          rejectStatus,
          wantsOpen
              ? '{"message":"cashbox already open"}'
              : '{"message":"cashbox is not open"}',
        );
        return;
      }
      open[cashbox] = wantsOpen;
      accepted.add('${data['method']}@$at@$cashbox');
      if (loseNextResponse) {
        loseNextResponse = false;
        await _drop(req);
        return;
      }
      await _reply(req, 200, '{"message":"Success"}');
      return;
    }

    await _reply(req, 200, '{"message":"Success"}');
  }

  static Future<void> _reply(HttpRequest req, int status, String body) async {
    req.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(body);
    await req.response.close();
  }

  /// Javobsiz uzish: ulanish yopiladi, kassa javob olmaydi.
  static Future<void> _drop(HttpRequest req) async {
    final Socket socket =
        await req.response.detachSocket(writeHeaders: false);
    socket.destroy();
  }
}

/// Ilovaning barcha HTTP so'rovlarini lokal serverga yo'naltiradi.
class _ToLocal extends HttpOverrides {
  _ToLocal(this.port);

  final int port;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _LocalClient(super.createHttpClient(context), port);
}

class _LocalClient implements HttpClient {
  _LocalClient(this._inner, this._port);

  final HttpClient _inner;
  final int _port;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => _inner.openUrl(
      method, url.replace(scheme: 'http', host: '127.0.0.1', port: _port));

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// `ShiftSingleton4.openShift` kontekstdan foydalanmaydi.
class _FakeContext extends Fake implements BuildContext {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final _FakeBackend backend = _FakeBackend();
  final BuildContext ctx = _FakeContext();
  final DateFormat fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

  DateTime simTime = DateTime.utc(2026, 10, 2, 3);

  /// Kassir kassada bajargan amallar: `open@vaqt@kassa`.
  final List<String> posLog = [];

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('shift_queue_scenarios');
    Hive.init(tempDir.path);

    void reg<T>(int typeId, TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(adapter);
    }

    reg(27, LogModelAdapter());
    reg(0, EmployeeAdapter());
    reg(2, EmployeeAccessAdapter());
    reg(101, EmployeeUserAdapter());
    reg(102, EmployeeRoleAdapter());
    reg(30, ShiftModelHiveAdapter());
    reg(31, CashDrawerHiveAdapter());
    reg(32, SalesSummaryHiveAdapter());
    reg(33, PaysHiveAdapter());

    await Hive.openBox<dynamic>('prefs');
    await Hive.openBox<LogModel>('logs');
    await Hive.openBox<LogModel>('tg_logs');
    await Hive.openBox<Employee>('employees');
    await Hive.openBox<ShiftModelHive>('shifts');

    // Testda Telegramga haqiqiy xabar ketmasin.
    await Pref.setBool(PrefKeys.isSendToTelegram, false);

    await backend.start();
    HttpOverrides.global = _ToLocal(backend.port);
    BackendHealth.configureProbeUrl(ApiProvider.baseUrlINVAN2);
  });

  tearDownAll(() async {
    ShiftSingleton4.clock = DateTime.now;
    ShiftSyncQueue.now = DateTime.now;
    BackendHealth.reset();
    BackendHealth.autoProbe = true;
    HttpOverrides.global = null;
    await backend.stop();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  void setNet(_Net net) {
    backend.net = net;
    BackendHealth.internetCheck = () async => net != _Net.internetOff;
  }

  /// Server/internet tiklandi va `BackendHealth` buni sezdi (ilovada buni
  /// fon tekshiruvi qiladi).
  void recovered() {
    setNet(_Net.up);
    BackendHealth.reset();
  }

  /// Fonda ketayotgan yuborishlar tugashi uchun.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 30));

  /// Aloqa tiklangach ilova navbatni oxirigacha yuboradi.
  Future<void> deliverAll() async {
    recovered();
    final Stopwatch sw = Stopwatch()..start();
    while (ShiftSyncQueue.hasPending && sw.elapsed.inSeconds < 10) {
      // Ilovada `BackendHealth` fon tekshiruvi (har 30 soniyada) server
      // tirikligini o'zi aniqlaydi va holatni `up` qiladi. Testda fon
      // tekshiruvi o'chiq — eskirgan tasdiqlovchi so'rov holatni `down`
      // qilib qo'yishi mumkin, shuning uchun o'sha tiklanishni shu yerda
      // qaytaramiz.
      BackendHealth.reset();
      await ShiftSyncQueue.flush(reason: 'test-final');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await settle();
  }

  Future<void> resetWorld() async {
    await settle();
    backend.reset();
    BackendHealth.reset();
    BackendHealth.autoProbe = false;
    BackendHealth.now = DateTime.now;
    BackendHealth.internetCheck = () async => true;
    await Pref.setString(PrefKeys.shiftSyncQueue, '');
    await Pref.setString(PrefKeys.openedDate, '');
    await Pref.setString(PrefKeys.closedDate, '');
    await Pref.setInt(PrefKeys.openedCount, 0);
    await Pref.setInt(PrefKeys.closedCount, 0);
    await Pref.setBool(PrefKeys.shiftsOpened, false);
    await Pref.setString(PrefKeys.activatedPosId, 'kassa-1');
    await Pref.setString(PrefKeys.userId, 'kassir-1');
    await Pref.setString(PrefKeys.token, 'test-token');
    await Hive.box<ShiftModelHive>('shifts').clear();
    simTime = DateTime.utc(2026, 10, 2, 3);
    ShiftSingleton4.clock = () => simTime;
    ShiftSyncQueue.now = DateTime.now;
    posLog.clear();
  }

  String kassa() => Pref.getString(PrefKeys.activatedPosId, '');

  bool posOpen() => Pref.getBool(PrefKeys.shiftsOpened, false);

  /// Kassir "Smena ochish"ni bosdi (`OpenShiftProvider.openShift` kabi).
  Future<bool?> cashierOpens() async {
    simTime = simTime.add(const Duration(minutes: 7));
    final bool? result =
        await ShiftSingleton4.openShift(ctx, startingCash: 0);
    await Pref.setBool(PrefKeys.shiftsOpened, result ?? false);
    if (result == true) posLog.add('open@${fmt.format(simTime)}@${kassa()}');
    return result;
  }

  /// Kassir "Smena yopish"ni bosdi (`OpenShiftProvider` oqimi: internet
  /// bo'lsa avval navbat yuboriladi, keyin yopiladi).
  Future<void> cashierCloses() async {
    simTime = simTime.add(const Duration(minutes: 7));
    if (await BackendHealth.isUsable() && ShiftSyncQueue.hasPending) {
      await ShiftSyncQueue.flush(reason: 'before-close');
    }
    await ShiftSingleton4.syncCloseToServer(
      closedAt: fmt.format(simTime),
      userId: Pref.getString(PrefKeys.userId, ''),
      cashboxId: kassa(),
    );
    posLog.add('close@${fmt.format(simTime)}@${kassa()}');
    expect(posOpen(), isFalse,
        reason: 'yopish kassada HAR DOIM bajarilishi kerak');
  }

  void expectConsistent([String label = '']) {
    expect(ShiftSyncQueue.hasPending, isFalse,
        reason: '$label\nnavbat tiqilib qoldi: ${ShiftSyncQueue.describe()}');
    expect(backend.open[kassa()] ?? false, posOpen(),
        reason: '$label\nserverdagi va kassadagi smena holati farq qiladi');
    expect(backend.accepted, posLog,
        reason: '$label\nserver qabul qilgan amallar kassir amallariga '
            'teng emas');
  }

  setUp(resetWorld);

  group('Aniq stsenariylar', () {
    test('server ertalabdan o\'chiq: ochish → yopish → ochish → yopish — '
        'server qaytgach to\'rttalasi tartib bilan yetadi', () async {
      setNet(_Net.down500);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(backend.accepted, isEmpty);
      expect(ShiftSyncQueue.pendingCount, 4);

      await deliverAll();
      expectConsistent();
      expect(backend.accepted.length, 4);
    });

    test('internet yo\'q: xuddi shu ketma-ketlik', () async {
      setNet(_Net.internetOff);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(await cashierOpens(), isTrue);
      await cashierCloses();

      await deliverAll();
      expectConsistent();
    });

    test('ertalab server ishlagan → o\'chdi → yopish → yana ochish → server '
        'qaytdi (foydalanuvchi savoli)', () async {
      expect(await cashierOpens(), isTrue);
      expect(backend.open['kassa-1'], isTrue, reason: 'onlayn ochildi');

      setNet(_Net.down500);
      await cashierCloses();
      expect(await cashierOpens(), isTrue);

      await deliverAll();
      expectConsistent();
    });

    test('server ertalabdan o\'chiq, kunduzi qaytdi, kechqurun yopildi — '
        'kechki yopish oflayn ochilishdan KEYIN yetadi', () async {
      setNet(_Net.down500);
      expect(await cashierOpens(), isTrue);

      // Server qaytdi, lekin navbat hali yuborilmadi (trigger kechikdi).
      recovered();
      await cashierCloses();

      await deliverAll();
      expectConsistent();
    });

    test('Wi-Fi login sahifasi (200 + HTML) — kassa oflayndagidek ishlaydi',
        () async {
      setNet(_Net.captivePortal);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(backend.accepted, isEmpty);

      await deliverAll();
      expectConsistent();
    });

    test('onlayn ochishning JAVOBI yo\'qoldi (server ochdi, kassa bilmadi) — '
        'takror yuborilmaydi, yopish to\'g\'ri yetadi', () async {
      backend.loseNextResponse = true;
      expect(await cashierOpens(), isTrue);
      expect(backend.open['kassa-1'], isTrue);
      expect(ShiftSyncQueue.pendingCount, 1,
          reason: 'javob kelmagani uchun ochish navbatga tushadi');

      await cashierCloses();
      await deliverAll();
      expectConsistent();
    });

    test('navbatdan yuborishda javob yo\'qoldi — server holatidan "bajarilgan" '
        'deb aniqlanadi, takror yuborilmaydi, qolganlari shu zahoti yetadi',
        () async {
      setNet(_Net.down500);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(await cashierOpens(), isTrue);

      recovered();
      backend.loseNextResponse = true;
      await ShiftSyncQueue.flush(reason: 'backend-recovered');
      expect(ShiftSyncQueue.pendingCount, 0);
      expectConsistent();
    });

    test('yopishning javobi yo\'qoldi (onlayn) — kassa yopiq, server yopiq',
        () async {
      expect(await cashierOpens(), isTrue);
      backend.loseNextResponse = true;
      await cashierCloses();
      expect(backend.open['kassa-1'], isFalse);
      expect(ShiftSyncQueue.pendingCount, 1);

      await deliverAll();
      expectConsistent();
    });

    test('token eskirdi (401): yopish kassada bajariladi va saqlanadi; '
        'navbatda yetmagan voqea bor — ochish ham lokal bajariladi; token '
        'yangilangach hammasi yetadi', () async {
      expect(await cashierOpens(), isTrue);
      setNet(_Net.unauthorized);
      await cashierCloses();
      expect(ShiftSyncQueue.pendingCount, 1);

      // Server bizning yopilishimizni hali bilmaydi ("ochiq" deydi) — uning
      // eskirgan holatiga ishonib kassirni to'xtatib bo'lmaydi.
      expect(await cashierOpens(), isTrue);
      expect(ShiftSyncQueue.pendingCount, 2);

      await deliverAll();
      expectConsistent();
    });

    test('token eskirdi (401), navbat BO\'SH — ochish bloklanadi (dizayn: '
        'server tirik, lekin rad etyapti, lokal ochib yashirilmaydi)',
        () async {
      setNet(_Net.unauthorized);
      expect(await cashierOpens(), isFalse);
      expect(ShiftSyncQueue.hasPending, isFalse);
      expect(posOpen(), isFalse);
    });

    test('server ochilmagan kassani "ochiq" ko\'rsatyapti, navbat bo\'sh — '
        'ochish bloklanadi va sabab ko\'rsatiladi (o\'zgarmagan xulq)',
        () async {
      backend.open['kassa-1'] = true; // masalan, web orqali ochilgan
      expect(await cashierOpens(), isNull);
      expect(ShiftSyncQueue.hasPending, isFalse);
    });

    for (final int status in [409, 422, 500]) {
      test('server noto\'g\'ri o\'tishni $status bilan rad etsa ham navbat '
          'tiqilmaydi', () async {
        backend.rejectStatus = status;
        setNet(_Net.down500);
        expect(await cashierOpens(), isTrue);
        await cashierCloses();

        recovered();
        backend.loseNextResponse = true; // birinchi voqea takror ketadi
        await ShiftSyncQueue.flush(reason: 'backend-recovered');

        await deliverAll();
        expectConsistent();
      });
    }

    test('server takrorga 200 qaytarsa (idempotent) ham hammasi izchil',
        () async {
      backend.rejectStatus = 200;
      backend.loseNextResponse = true;
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(await cashierOpens(), isTrue);
      await deliverAll();
      expectConsistent();
    });

    test('server takrorni 403 bilan rad etsa ham — kassa holati allaqachon '
        'mosligi serverdan tekshiriladi, navbat tiqilmaydi', () async {
      backend.rejectStatus = 403;
      setNet(_Net.down500);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();

      recovered();
      backend.loseNextResponse = true;
      await ShiftSyncQueue.flush(reason: 'backend-recovered');
      // Kassa sotishda davom etadi, keyingi ochish/yopish ham yetadi.
      expect(await cashierOpens(), isTrue);
      await cashierCloses();

      await deliverAll();
      expectConsistent();
    });

    for (final int status in [500, 502, 503, 404]) {
      test('server bir lahza $status qaytardi va DARHOL tirildi — haqiqiy '
          'voqea tashlab yuborilmaydi (tasodifiy testda topilgan)', () async {
        setNet(_Net.down500);
        expect(await cashierOpens(), isTrue);
        await cashierCloses();
        expect(await cashierOpens(), isTrue);

        recovered();
        backend.failNextMutationWith = status; // birinchi voqea bajarilmaydi
        await ShiftSyncQueue.flush(reason: 'backend-recovered');
        expect(ShiftSyncQueue.pendingCount, 3,
            reason: 'server tirik chiqdi, lekin ochish unda AKS ETMAGAN — '
                'voqea navbatda qolishi shart');

        await deliverAll();
        expectConsistent();
      });
    }

    test('server ochishni DOIMIY rad etadi (holat mos emas) — navbat kutadi, '
        'hech narsa yo\'qolmaydi, kassa ishlashda davom etadi', () async {
      setNet(_Net.down500);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();

      recovered();
      backend.refuseOpens = true;
      await ShiftSyncQueue.flush(reason: 'backend-recovered');
      expect(ShiftSyncQueue.pendingCount, 2,
          reason: 'ochish serverda yo\'q — tashlab yuborilmaydi');

      // Kassir bemalol ishlayveradi.
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(ShiftSyncQueue.pendingCount, 4);
      expect(backend.accepted, isEmpty);

      // Backend tuzatildi.
      backend.refuseOpens = false;
      await deliverAll();
      expectConsistent();
    });

    test('kassir backend\'da O\'CHIRILGAN (server 500 "sql: no rows") — '
        'voqea 1 soat kutadi, so\'ng hisobot bilan olib tashlanadi; navbat '
        'tiqilib qolmaydi', () async {
      DateTime clock = DateTime.now();
      ShiftSyncQueue.now = () => clock;

      setNet(_Net.down500);
      await Pref.setString(PrefKeys.userId, 'ochirilgan-kassir');
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      await Pref.setString(PrefKeys.userId, 'kassir-1');
      final List<String> poisoned = List<String>.of(posLog);

      recovered();
      backend.unknownUsers.add('ochirilgan-kassir');
      for (int i = 0; i < 6; i++) {
        await ShiftSyncQueue.flush(reason: 'receipts-uploaded');
        clock = clock.add(const Duration(minutes: 5));
      }
      expect(ShiftSyncQueue.pendingCount, 2,
          reason: '1 soat o\'tmaguncha haqiqiy voqea tashlanmaydi');
      expect(ShiftSyncQueue.pending.first.failures, greaterThanOrEqualTo(5));

      // Kassa baribir ishlaydi (to'g'ri kassir bilan).
      expect(await cashierOpens(), isTrue);

      clock = clock.add(const Duration(minutes: 61));
      await deliverAll();

      expect(ShiftSyncQueue.hasPending, isFalse,
          reason: 'zaharli voqea navbatni abadiy to\'smasligi kerak');
      expect(backend.open['kassa-1'], posOpen());
      expect(backend.accepted,
          posLog.where((e) => !poisoned.contains(e)).toList(),
          reason: 'faqat o\'chirilgan kassirning amallari yetmaydi');
    });

    test('tez-tez uzilish: har amaldan keyin tarmoq holati almashadi',
        () async {
      final List<_Net> pattern = [
        _Net.down500,
        _Net.up,
        _Net.internetOff,
        _Net.up,
        _Net.captivePortal,
        _Net.down500,
        _Net.up,
        _Net.internetOff,
      ];
      for (int i = 0; i < 16; i++) {
        final _Net net = pattern[i % pattern.length];
        if (net == _Net.up) {
          recovered();
        } else {
          setNet(net);
        }
        if (posOpen()) {
          await cashierCloses();
        } else {
          expect(await cashierOpens(), isTrue, reason: 'qadam $i ($net)');
        }
      }
      await deliverAll();
      expectConsistent();
    });

    test('kassir navbat yuborilayotgan PAYTDA smenani yopadi', () async {
      setNet(_Net.down500);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(await cashierOpens(), isTrue);

      recovered();
      final Future<void> background =
          ShiftSyncQueue.flush(reason: 'backend-recovered');
      await cashierCloses(); // fon yuborish tugashini kutmasdan
      await background;

      await deliverAll();
      expectConsistent();
    });

    test('kassa boshqa kassaga qayta aktivlashtirildi — eski amallar o\'z '
        'kassasiga ketadi', () async {
      backend.open['kassa-2'] = false;
      setNet(_Net.down500);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();

      await Pref.setString(PrefKeys.activatedPosId, 'kassa-2');
      expect(await cashierOpens(), isTrue);

      await deliverAll();
      expect(ShiftSyncQueue.hasPending, isFalse);
      expect(backend.accepted, posLog);
      expect(backend.open['kassa-1'], isFalse);
      expect(backend.open['kassa-2'], isTrue);
    });

    test('har amal o\'z kassiri nomidan ketadi (kassir almashdi)', () async {
      final List<String> users = [];
      setNet(_Net.down500);
      await Pref.setString(PrefKeys.userId, 'ali');
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      await Pref.setString(PrefKeys.userId, 'vali');
      expect(await cashierOpens(), isTrue);

      users.addAll(ShiftSyncQueue.pending.map((e) => e.userId));
      expect(users, ['ali', 'ali', 'vali']);

      await deliverAll();
      expectConsistent();
    });

    test('ko\'p amal: 30 marta ochish/yopish internetsiz — hammasi yetadi',
        () async {
      setNet(_Net.internetOff);
      for (int i = 0; i < 15; i++) {
        expect(await cashierOpens(), isTrue);
        await cashierCloses();
      }
      expect(ShiftSyncQueue.pendingCount, 30);
      await deliverAll();
      expectConsistent();
    });
  });

  group('Tasodifiy stsenariylar', () {
    // Odatda 100; og'ir tekshiruv uchun:
    // flutter test test/shift_queue_scenarios_test.dart \
    //   --dart-define=SHIFT_FUZZ_SEEDS=2000
    const int seeds =
        int.fromEnvironment('SHIFT_FUZZ_SEEDS', defaultValue: 100);
    // Bitta muvaffaqiyatsiz holatni qayta ko'rish uchun:
    // --dart-define=SHIFT_FUZZ_SEED=247 --dart-define=SHIFT_FUZZ_REJECT=500
    const int onlySeed = int.fromEnvironment('SHIFT_FUZZ_SEED');
    const int onlyReject = int.fromEnvironment('SHIFT_FUZZ_REJECT');

    test(
        'TASODIFIY: 4 xil server xulqi × $seeds ta ketma-ketlik × 25 qadam — '
        'har doim izchil', () async {
      int runs = 0;
      for (final int rejectStatus in [400, 409, 500, 200]) {
        if (onlyReject != 0 && rejectStatus != onlyReject) continue;
        for (int seed = 1; seed <= seeds; seed++) {
          if (onlySeed != 0 && seed != onlySeed) continue;
          await resetWorld();
          backend.rejectStatus = rejectStatus;
          final Random rnd = Random(seed * 1000 + rejectStatus);
          final List<String> trace = [];

          for (int step = 0; step < 25; step++) {
            final int roll = rnd.nextInt(100);
            if (roll < 35) {
              if (posOpen()) {
                trace.add('yopish');
                await cashierCloses();
              } else {
                trace.add('ochish');
                final _Net net = backend.net;
                final bool? result = await cashierOpens();
                // 401 da ikkala natija ham dizayn bo'yicha: navbat bo'sh va
                // server "tirik" bo'lsa bloklanadi, aks holda lokal ochiladi.
                // Boshqa har qanday holatda ochish bloklanmasligi SHART.
                if (net != _Net.unauthorized) {
                  expect(result, isTrue,
                      reason: 'ochish bloklanmasligi kerak ($net): '
                          '${trace.join(', ')}');
                }
              }
            } else if (roll < 45) {
              trace.add('server-500');
              setNet(_Net.down500);
            } else if (roll < 55) {
              trace.add('internet-yoq');
              setNet(_Net.internetOff);
            } else if (roll < 59) {
              trace.add('wifi-login');
              setNet(_Net.captivePortal);
            } else if (roll < 63) {
              trace.add('401');
              setNet(_Net.unauthorized);
            } else if (roll < 80) {
              trace.add('tiklandi');
              recovered();
              if (rnd.nextBool()) {
                await ShiftSyncQueue.flush(reason: 'backend-recovered');
              }
            } else if (roll < 84) {
              trace.add('javob-yoqoladi');
              backend.loseNextResponse = true;
            } else if (roll < 88) {
              final int status = [500, 502, 404][rnd.nextInt(3)];
              trace.add('bir-lahza-$status');
              backend.failNextMutationWith = status;
            } else if (roll < 95) {
              trace.add('flush');
              await ShiftSyncQueue.flush(reason: 'receipts-uploaded');
            } else {
              trace.add('yopishni-yuborish');
              BackendHealth.markUserInitiatedAction();
              await ShiftSyncQueue.flush(reason: 'manual');
            }
          }

          await deliverAll();
          expectConsistent('rad etish=$rejectStatus seed=$seed\n'
              'qadamlar: ${trace.join(', ')}');
          runs++;
        }
      }
      if (onlySeed == 0 && onlyReject == 0) expect(runs, 4 * seeds);
    }, timeout: const Timeout(Duration(hours: 2)));
  });
}
```

</details>

<details><summary><code>test/server_down_behaviour_test.dart</code> (diff)</summary>

```diff
diff --git a/test/server_down_behaviour_test.dart b/test/server_down_behaviour_test.dart
index 5f476b9..5aa7077 100644
--- a/test/server_down_behaviour_test.dart
+++ b/test/server_down_behaviour_test.dart
@@ -48,6 +48,10 @@ enum ServerMode {
   /// Server SOG'LOM, lekin bitta so'rov (chek yuborish) unda xatoga olib
   /// keladi — faqat `order_pos` 500 qaytaradi.
   poisonedOrderPos,
+
+  /// Server TIRIK, lekin smena YOPISHni rad etadi (400 — "kassa ochiq
+  /// emas"). Qolgan so'rovlar normal.
+  rejectShiftClose,
 }
 
 /// Chegaraga yetilgach `BackendHealth` serverning tirikligini TEKSHIRIB
@@ -115,6 +119,25 @@ void main() {
         await request.response.close();
         return;
       }
+      if (mode == ServerMode.rejectShiftClose) {
+        // Kassa serverda YOPIQ: yopish rad etiladi, holat so'ralsa "yopiq".
+        if (request.uri.path.contains('shift_statuses')) {
+          request.response.statusCode = 200;
+          request.response.write('[{"cashbox_id":"kassa-1",'
+              '"status":"closed","opened_by_pos":false,'
+              '"opened_by_web":false,"opened_by_user_id":""}]');
+          await request.response.close();
+          return;
+        }
+        final bool reject = request.uri.path.contains('shift_pos') &&
+            body.contains('"method":"close"');
+        request.response.statusCode = reject ? 400 : 200;
+        request.response.write(reject
+            ? '{"message":"cashbox is not open"}'
+            : '{"message":"Success"}');
+        await request.response.close();
+        return;
+      }
       if (mode == ServerMode.partialEmployees) {
         if (request.uri.path.contains('role_with_permissions')) {
           request.response.statusCode = 500;
@@ -475,30 +498,35 @@ void main() {
 
   group('Smena navbati — server o\'chgan kun stsenariysi', () {
     setUp(() async {
+      await Pref.setString(PrefKeys.shiftSyncQueue, '');
       await Pref.setString(PrefKeys.openedDate, '');
       await Pref.setString(PrefKeys.closedDate, '');
       await Pref.setInt(PrefKeys.openedCount, 0);
       await Pref.setInt(PrefKeys.closedCount, 0);
+      await Pref.setString(PrefKeys.userId, 'kassir-1');
+      await Pref.setString(PrefKeys.activatedPosId, 'kassa-1');
     });
 
+    List<String> shiftCalls() =>
+        requestLog.where((r) => r.contains('shift_pos')).toList();
+
     test('ertalab oflayn ochilgan + kechqurun oflayn yopilgan smena — '
         'serverga AVVAL ochish, KEYIN yopish ketadi', () async {
       // Server o'chgan kun: ikkalasi ham navbatda qoldi.
-      await Pref.setString(PrefKeys.openedDate, '2026-09-02 09:00:00');
-      await Pref.setInt(PrefKeys.openedCount, 1);
-      await Pref.setString(PrefKeys.closedDate, '2026-09-02 21:00:00');
-      await Pref.setInt(PrefKeys.closedCount, 1);
+      await ShiftSyncQueue.enqueueOpen('2026-09-02 09:00:00');
+      await ShiftSyncQueue.enqueueClose('2026-09-02 21:00:00');
 
       // Ertasiga server ko'tarildi.
       mode = ServerMode.ok;
       await ShiftSyncQueue.flush(reason: 'test');
 
-      final List<String> shiftCalls =
-          requestLog.where((r) => r.contains('shift_pos')).toList();
-      expect(shiftCalls.length, 2, reason: 'ikkalasi ham yuborilishi kerak');
-      expect(shiftCalls.first.contains('"method":"open"'), isTrue,
+      final List<String> calls = shiftCalls();
+      expect(calls.length, 2, reason: 'ikkalasi ham yuborilishi kerak');
+      expect(calls.first, contains('"method":"open"'),
           reason: 'ochilmagan smenani yopib bo\'lmaydi — tartib muhim');
-      expect(shiftCalls.last.contains('"method":"close"'), isTrue);
+      expect(calls.first, contains('"opened_at":"2026-09-02 09:00:00"'));
+      expect(calls.last, contains('"method":"close"'));
+      expect(calls.last, contains('"closed_at":"2026-09-02 21:00:00"'));
 
       expect(ShiftSyncQueue.hasPending, isFalse,
           reason: 'ikkalasi ketgach navbat bo\'shashi kerak');
@@ -506,38 +534,145 @@ void main() {
 
     test('oldingi smena yopilishi navbatda, keyin yangi smena ochilgan — '
         'AVVAL yopish ketadi', () async {
-      await Pref.setString(PrefKeys.closedDate, '2026-09-02 08:00:00');
-      await Pref.setInt(PrefKeys.closedCount, 1);
-      await Pref.setString(PrefKeys.openedDate, '2026-09-02 09:00:00');
-      await Pref.setInt(PrefKeys.openedCount, 1);
+      await ShiftSyncQueue.enqueueClose('2026-09-02 08:00:00');
+      await ShiftSyncQueue.enqueueOpen('2026-09-02 09:00:00');
+
+      await ShiftSyncQueue.flush(reason: 'test');
+
+      final List<String> calls = shiftCalls();
+      expect(calls.length, 2);
+      expect(calls.first, contains('"method":"close"'));
+      expect(calls.last, contains('"method":"open"'));
+    });
+
+    test('server ertalabdan o\'chiq: ochish → yopish → yana ochish — '
+        'UCHALASI ham o\'z vaqti bilan, tartib bilan ketadi', () async {
+      // 2026-10-02 da topilgan bug: eski navbatda ikkinchi ochish
+      // birinchisining vaqtini o'chirardi va navbatda "yopish 14:00,
+      // ochish 14:05" qolardi — server ochilmagan smenani yopishni rad
+      // etardi, ochish esa hech qachon ketmasdi.
+      await ShiftSyncQueue.enqueueOpen('2026-10-02 08:00:00');
+      await ShiftSyncQueue.enqueueClose('2026-10-02 14:00:00');
+      await ShiftSyncQueue.enqueueOpen('2026-10-02 14:05:00');
+
+      expect(ShiftSyncQueue.pendingCount, 3,
+          reason: 'hech bir voqea boshqasini o\'chirmasligi kerak');
 
       await ShiftSyncQueue.flush(reason: 'test');
 
-      final List<String> shiftCalls =
-          requestLog.where((r) => r.contains('shift_pos')).toList();
-      expect(shiftCalls.length, 2);
-      expect(shiftCalls.first.contains('"method":"close"'), isTrue);
-      expect(shiftCalls.last.contains('"method":"open"'), isTrue);
+      final List<String> calls = shiftCalls();
+      expect(calls.length, 3);
+      expect(calls[0], contains('"opened_at":"2026-10-02 08:00:00"'));
+      expect(calls[1], contains('"closed_at":"2026-10-02 14:00:00"'));
+      expect(calls[2], contains('"opened_at":"2026-10-02 14:05:00"'));
+      expect(ShiftSyncQueue.hasPending, isFalse);
+    });
+
+    test('internetsiz IKKI MARTA yopish — ikkala yopilish ham saqlanadi va '
+        'tartib bilan yuboriladi', () async {
+      await ShiftSyncQueue.enqueueOpen('2026-10-02 08:00:00');
+      await ShiftSyncQueue.enqueueClose('2026-10-02 14:00:00');
+      await ShiftSyncQueue.enqueueOpen('2026-10-02 14:05:00');
+      await ShiftSyncQueue.enqueueClose('2026-10-02 22:00:00');
+
+      await ShiftSyncQueue.flush(reason: 'test');
+
+      final List<String> calls = shiftCalls();
+      expect(
+        calls.map((c) => c.contains('"method":"open"') ? 'open' : 'close'),
+        ['open', 'close', 'open', 'close'],
+      );
+      expect(calls[1], contains('"closed_at":"2026-10-02 14:00:00"'));
+      expect(calls[3], contains('"closed_at":"2026-10-02 22:00:00"'));
+      expect(ShiftSyncQueue.hasPending, isFalse);
     });
 
     test('server hali ham o\'chiq bo\'lsa navbat SAQLANADI', () async {
-      await Pref.setString(PrefKeys.openedDate, '2026-09-02 09:00:00');
-      await Pref.setInt(PrefKeys.openedCount, 1);
-      await Pref.setString(PrefKeys.closedDate, '2026-09-02 21:00:00');
-      await Pref.setInt(PrefKeys.closedCount, 1);
+      await ShiftSyncQueue.enqueueOpen('2026-09-02 09:00:00');
+      await ShiftSyncQueue.enqueueClose('2026-09-02 21:00:00');
 
       mode = ServerMode.error500;
       await ShiftSyncQueue.flush(reason: 'test');
 
-      expect(ShiftSyncQueue.hasPendingOpen, isTrue);
-      expect(ShiftSyncQueue.hasPendingClose, isTrue,
-          reason: 'yuborilmagan yopish yo\'qolmasligi kerak');
+      expect(ShiftSyncQueue.pendingCount, 2,
+          reason: 'yuborilmagan voqealar yo\'qolmasligi kerak');
 
       // Birinchi qadam (ochish) yiqilgach ikkinchisi urinilmasligi kerak:
       // ochilmagan smenani yopishga urinish server uchun ma'nosiz.
-      final List<String> shiftCalls =
-          requestLog.where((r) => r.contains('shift_pos')).toList();
-      expect(shiftCalls.length, 1);
+      expect(shiftCalls().length, 1);
+    });
+
+    test('sessiya muammosi (401) — voqea navbatda QOLADI, yuborish '
+        'to\'xtaydi', () async {
+      await ShiftSyncQueue.enqueueClose('2026-10-02 08:00:00');
+      await ShiftSyncQueue.enqueueOpen('2026-10-02 09:00:00');
+
+      mode = ServerMode.unauthorized401;
+      await ShiftSyncQueue.flush(reason: 'test');
+
+      expect(ShiftSyncQueue.pendingCount, 2,
+          reason: 'token yangilangach qayta yuborilishi kerak');
+      expect(shiftCalls().length, 1);
+    });
+
+    test('server yopishni rad etsa va kassa serverda ALLAQACHON yopiq bo\'lsa '
+        '— yopish navbatdan olinadi, keyingisi yuboriladi', () async {
+      await ShiftSyncQueue.enqueueClose('2026-10-02 08:00:00');
+      await ShiftSyncQueue.enqueueOpen('2026-10-02 09:00:00');
+
+      mode = ServerMode.rejectShiftClose;
+      await ShiftSyncQueue.flush(reason: 'test');
+
+      final List<String> calls = shiftCalls();
+      expect(calls.length, 2);
+      expect(calls.first, contains('"method":"close"'));
+      expect(calls.last, contains('"method":"open"'),
+          reason: 'rad etilgan yopish ochishni to\'sib qo\'ymasligi kerak');
+      expect(ShiftSyncQueue.hasPending, isFalse);
+    });
+
+    test('har voqea o\'z kassiri nomidan yuboriladi (user_id)', () async {
+      await Pref.setString(PrefKeys.userId, 'ali');
+      await ShiftSyncQueue.enqueueOpen('2026-10-02 08:00:00');
+      await ShiftSyncQueue.enqueueClose('2026-10-02 14:00:00');
+      await Pref.setString(PrefKeys.userId, 'vali');
+      await ShiftSyncQueue.enqueueOpen('2026-10-02 14:05:00');
+
+      await ShiftSyncQueue.flush(reason: 'test');
+
+      final List<String> calls = shiftCalls();
+      expect(calls.length, 3);
+      expect(calls[0], contains('"user_id":"ali"'));
+      expect(calls[1], contains('"user_id":"ali"'),
+          reason: 'Alining smenasi Vali nomidan ketmasligi kerak');
+      expect(calls[2], contains('"user_id":"vali"'));
+    });
+
+    test('eski versiyadan qolgan navbat (to\'rt kalit) yo\'qolmaydi va '
+        'yangi voqealardan OLDIN ketadi', () async {
+      // Kassa server o'chgan paytda yangilangan: navbat eski kalitlarda.
+      await Pref.setString(PrefKeys.openedDate, '2026-09-02 09:00:00');
+      await Pref.setInt(PrefKeys.openedCount, 1);
+      await Pref.setString(PrefKeys.closedDate, '2026-09-02 21:00:00');
+      await Pref.setInt(PrefKeys.closedCount, 1);
+
+      expect(ShiftSyncQueue.pendingCount, 2);
+
+      // Yangi versiyada yana bir smena ochildi.
+      await ShiftSyncQueue.enqueueOpen('2026-09-03 08:00:00');
+      expect(Pref.getInt(PrefKeys.closedCount, 0), 0,
+          reason: 'eski kalitlar ro\'yxatga ko\'chgach tozalanadi');
+      expect(ShiftSyncQueue.pendingCount, 3,
+          reason: 'ko\'chirishda takrorlanmasligi kerak');
+
+      await ShiftSyncQueue.flush(reason: 'test');
+
+      final List<String> calls = shiftCalls();
+      expect(calls.length, 3);
+      expect(calls[0], contains('"opened_at":"2026-09-02 09:00:00"'));
+      expect(calls[1], contains('"closed_at":"2026-09-02 21:00:00"'));
+      expect(calls[2], contains('"opened_at":"2026-09-03 08:00:00"'));
+      expect(ShiftSyncQueue.hasPending, isFalse);
     });
   });
 }
```

</details>

<details><summary><code>test/shift_close_guard_test.dart</code> (diff)</summary>

````diff
diff --git a/test/shift_close_guard_test.dart b/test/shift_close_guard_test.dart
index 498bab7..ed85cd1 100644
--- a/test/shift_close_guard_test.dart
+++ b/test/shift_close_guard_test.dart
@@ -1,23 +1,14 @@
 import 'package:flutter_test/flutter_test.dart';
 import 'package:invan2/changes/services/shift/shift_diagnostics.dart';
 
-/// Smenani yopish mumkinmi — `ShiftSingleton4.closeShift` ning oflayn
-/// shoxidagi shart bilan bir xil bo'lishi kerak:
+/// Smena yopishdagi ogohlantirishlar va kassirga ko'rsatiladigan matnlar.
 ///
-/// ```dart
-/// if (closedCount == 0) { ...yopiladi... }
-/// ```
-///
-/// 2026-08-17 da UI shu shartni bilmasdi: kassirga "Smena yopildi" deb xabar
-/// berilardi, kod esa smenani yopmasdi.
-///
-/// 2026-09-02 da shart YUMSHATILDI (BackendHealth taski): ilgari u
-/// `openedCount == 0` ni ham talab qilardi. Oqibati og'ir edi — server
-/// o'chgan kunda ertalab oflayn ochilgan smenani kechqurun UMUMAN yopib
-/// bo'lmasdi. Endi `ShiftSyncQueue` ochish va yopishni vaqt tartibida
-/// yuboradi (avval ochish, keyin yopish), shuning uchun navbatdagi ochish
-/// to'siq emas. Navbatda YOPISH turgani esa hamon to'siq: unda bitta
-/// yopish uchungina joy bor.
+/// Tarix: 2026-08-17 da oflayn yopish uchun shart (`closedCount == 0`,
+/// keyin `openedCount == 0` ham) va uni UI'da oldindan tekshiradigan
+/// `blockingCloseIssue` qo'shilgan edi — navbatda ochish va yopish uchun
+/// bittadan joy bor edi. 2026-10-02 dan navbat ro'yxat (`ShiftSyncQueue`):
+/// internetsiz ham istalgancha yopish mumkin, to'siq yo'q. Navbatning o'zi
+/// test/server_down_behaviour_test.dart da sinaladi.
 ShiftSnapshot _snapshot({
   bool internet = false,
   int openedCount = 0,
@@ -44,63 +35,6 @@ ShiftSnapshot _snapshot({
 }
 
 void main() {
-  group('canCloseOffline — ShiftSingleton4 sharti bilan bir xil', () {
-    test('ikkala hisoblagich 0 bo\'lsa yopish mumkin', () {
-      expect(_snapshot().canCloseOffline, isTrue);
-    });
-
-    test('oflayn ochilgan smena (openedCount=1) — YOPISH MUMKIN', () {
-      expect(_snapshot(openedCount: 1).canCloseOffline, isTrue,
-          reason: 'server o\'chgan kunda ochilgan smena kechqurun '
-              'yopilishi shart — navbat ikkalasini tartib bilan yuboradi');
-    });
-
-    test('navbatda yopish turibdi (closedCount=1) — yopib bo\'lmaydi', () {
-      expect(_snapshot(closedCount: 1).canCloseOffline, isFalse);
-    });
-  });
-
-  group('blockingCloseIssue', () {
-    test('internet bor — hech qachon bloklamaydi (server hal qiladi)', () {
-      expect(
-        ShiftDiagnostics.blockingCloseIssue(
-          _snapshot(internet: true, openedCount: 1, closedCount: 1),
-        ),
-        isNull,
-      );
-    });
-
-    test('oflayn, hisoblagichlar toza — bloklamaydi', () {
-      expect(ShiftDiagnostics.blockingCloseIssue(_snapshot()), isNull);
-    });
-
-    test('oflayn ochilgan smena — BLOKLANMAYDI', () {
-      expect(
-        ShiftDiagnostics.blockingCloseIssue(_snapshot(openedCount: 1)),
-        isNull,
-        reason: 'ochish navbatda tursa ham yopish navbatga qo\'shiladi',
-      );
-    });
-
-    test('navbatdagi yopish — pendingClose sababi bilan bloklanadi', () {
-      expect(
-        ShiftDiagnostics.blockingCloseIssue(_snapshot(closedCount: 1)),
-        ShiftIssue.offlineCloseBlockedByPendingClose,
-      );
-    });
-
-    test('ikkalasi ham 1 bo\'lsa — yopish navbati band, bloklanadi', () {
-      expect(
-        ShiftDiagnostics.blockingCloseIssue(
-          _snapshot(openedCount: 1, closedCount: 1),
-        ),
-        ShiftIssue.offlineCloseBlockedByPendingClose,
-        reason: 'navbatda allaqachon yopish bor — ikkinchisi birinchisining '
-            'sanasini o\'chirib yuborardi',
-      );
-    });
-  });
-
   group('Kassirga ko\'rsatiladigan matn', () {
     test('bloklovchi sabab — nima bo\'ldi / sabab / nima qilish kerak', () {
       final String uz = ShiftDiagnostics.explain(
@@ -117,19 +51,33 @@ void main() {
     });
 
     test('bloklovchi sabab sarlavhasi "yopilmadi" deyishi shart', () {
-      for (final issue in [
-        ShiftIssue.offlineCloseBlockedByPendingOpen,
-        ShiftIssue.offlineCloseBlockedByPendingClose,
-      ]) {
-        expect(
-          ShiftDiagnostics.title(issue, isUz: true).toLowerCase(),
-          contains('yopilmadi'),
-        );
-        expect(
-          ShiftDiagnostics.title(issue, isUz: false).toLowerCase(),
-          contains('не закрыта'),
-        );
-      }
+      const ShiftIssue issue = ShiftIssue.offlineCloseBlockedByPendingOpen;
+      expect(
+        ShiftDiagnostics.title(issue, isUz: true).toLowerCase(),
+        contains('yopilmadi'),
+      );
+      expect(
+        ShiftDiagnostics.title(issue, isUz: false).toLowerCase(),
+        contains('не закрыта'),
+      );
+    });
+
+    test(
+        'internet yo\'q — "keyingi smenani yopib bo\'lmaydi" deb '
+        'ogohlantirmaydi (navbat ro\'yxat, cheklov yo\'q)', () {
+      final String uz = ShiftDiagnostics.explain(
+        ShiftIssue.noInternet,
+        _snapshot(closedCount: 1, pendingCloseAt: '2026-10-02 09:00:00'),
+        isUz: true,
+      );
+      final String ru = ShiftDiagnostics.explain(
+        ShiftIssue.noInternet,
+        _snapshot(closedCount: 1, pendingCloseAt: '2026-10-02 09:00:00'),
+        isUz: false,
+      );
+      expect(uz, isNot(contains('yopib bo\'lmaydi')));
+      expect(ru, isNot(contains('не получится')));
+      expect(uz, contains('navbatiga tushadi'));
     });
 
     test(
````

</details>

## 7. Tekshirish

- Stend: 28 test; og'ir rejim 8000 ketma-ketlik × 25 qadam — hammasi o'tgan. To'liq to'plam — 1616/1616 (2026-10-02, `c4e42e1`).
- Jonli dev API (2026-10-02): ochish/yopish ketma-ketliklari, takror, o'tgan vaqt, yaroqsiz token — 2-bo'lim oxiridagi xulq.
- Qo'lda (Mac, dev): 4-5 marta ochish/yopish, orada sotuv, internetsiz ochish/yopish; internet qaytgach `shift_pos` ×7+ aynan tartibda, hammasi 200.
- **Windows'da qo'lda sinov kutilmoqda:** (1) internetsiz ochish → yopish → ochish → yopish — ikkinchi yopishda dialog CHIQMASLIGI; (2) internet qaytgach `shift_pos` ×4 aynan shu tartibda; (3) eski versiyada navbat to'la holda yangilash — navbat yo'qolmasligi.

## 8. Eslatmalar

- `isDocumentRejection` (status kodiga qarab voqea tashlash) qoidasiga QAYTMANG — haqiqiy smena yo'qoladi.
- Odoo forkiga: kerak (navbat mantig'i umumiy; Odoo forkida `ShiftApi4` Odoo endpointlariga moslangan — `openShift/closeShift` imzolari (vaqt, `userId`, `cashboxId`) moslanadi).

---

# 12-TASK — Shorebird build/patch olingani Telegram kanalga hisobot (1.1.2+129)

> **Commit:** `f21c8d8` (modul) va PatchUpdater'ga ulanishi `40bc8c2` (8-TASK bilan), 2026-10-02; reliz `c4e42e1` 1.1.2+129.
> **Sessiya hujjati:** docs/sessions/2026-10-02-shorebird-telegram-hisobot.md
> **Holat 2026-10-02:** Mac sinov relizida haqiqiy kanalga yuborilishi tasdiqlandi (patch 4 va 5 — "build olindi"); prod'da 1.1.2+129 dan.

## 1. Nima va nima uchun

Qaysi do'konning qaysi kassasi oxirgi build'ni (reliz yoki patch) olganini kuzatish. Dastur yangi build'da **ishga tushganda** (yuklangani emas, haqiqatan ishlayotgani) har qurilma uchun bir marta kanalga "✅ Yangi build olindi — muammo yo'q" (tashkilot, do'kon, kassa, kompyuter, build, oldingi build). Shuningdek: patch orqaga qaytarilsa (rollback), yuklangan patch ishga tushmasa (Shorebird uni yaroqsiz deb eski versiyaga qaytsa) va Shorebird yangilanish yo'lidagi xatolar (tarmoq uzilishi emas).

## 2. Qanday ishlaydi

- `PatchUpdater.start` → `PatchReporter.start(updater)`: birinchi tekshiruv 20 s dan keyin (ochilishda sotuvga xalaqit bermasin), keyin har 5 daqiqada va server qaytganda.
- Kalit `<reliz versiyasi>#<patch raqami>`; muvaffaqiyatli yuborilgach `PrefKeys.patchReportedBuild` ga yoziladi — yuborilmasa (internet yo'q, kassa aktivatsiya qilinmagan) keyingi tekshiruvda qayta uriniladi.
- Diskda yangi patch kutib turgan bo'lsa `patchPendingBuild` saqlanadi; keyingi ochilishda u ishlamasa — "❌ Patch ishga tushmadi".
- Xatolar: bir xil xato bir build uchun bir marta, kuniga ko'pi bilan 10 ta (`patchReportErrors`). Tarmoq xatolari (`SocketException`, timeout va h.k.) yuborilmaydi; Shorebird'ning o'z yuklovchisi bilan poyga ("Update already in progress") ham yuborilmaydi (8-TASK `isUpdateInProgress`).
- Sotuvga ta'sir qilmaydi: barcha xatolar yutiladi, faqat `[PATCH-TG]` log.

## 3. O'zgarishlar ro'yxati

| Fayl | Tur | Nima |
|---|---|---|
| `lib/changes/services/patch_reporter.dart` | YANGI | Hisobot mantig'i (`PatchReporter`) va sof qoidalar (`PatchReportLogic`) |
| `lib/changes/services/patch_updater.dart` | o'zgargan | `PatchReporter.start` va `PatchReporter.error` chaqiruvlari (8-TASK 6.5 dagi to'liq faylda bor) |
| `lib/utils/constants/pref_keys.dart` | o'zgargan | `patchReportedBuild`, `patchPendingBuild`, `patchReportErrors` |
| `test/patch_reporter_test.dart` | YANGI | Kalitlar, boot hodisalari, xato takrori/kunlik chegara, tarmoq xatolari |

## 4. Bog'liqliklar

- **Bot tokeni va kanal ID** `patch_reporter.dart` da `const` (`_botToken`, `_chatId`) — InVan 2 ning kanali. InVan 1 o'z bot/kanalini qo'yadi yoki ikkalasini bo'sh qoldiradi (hisobot o'chadi, faqat log).
- `SettingsInnerSingleton.deviceData['computerName']`, `PrefKeys.organizationName/storeName/posName`, `package_info_plus`, `BackendHealth`.

## 5. Qo'llash tartibi

1. `pref_keys.dart` ga uch kalit (6.2).
2. `patch_reporter.dart` (6.1) — token/kanalni o'zingizniki bilan almashtiring yoki bo'sh qoldiring.
3. `patch_updater.dart` 8-TASK dagi to'liq holatda bo'lsa — chaqiruvlar allaqachon bor.
4. Test (6.3).

## 6. Kod

### 6.1. YANGI: `lib/changes/services/patch_reporter.dart`

```dart
/*
    Shorebird yangilanishlari haqida Telegram kanaliga hisobot.

    Maqsad: qaysi do'konning qaysi kassasi oxirgi build'ni (reliz yoki patch)
    olganini kuzatish.

    1. "Build olindi" — dastur yangi build'da ISHGA TUSHGANDA (yuklangani
       emas, haqiqatan ishlayotgani) har qurilma uchun BIR MARTA yuboriladi.
       Kalit: `<reliz versiyasi>#<patch raqami>`. Yuborilmasa (internet yo'q,
       kassa hali aktivatsiya qilinmagan) — keyingi tekshiruvda qayta
       uriniladi; muvaffaqiyatli yuborilgach kalit saqlanadi.
    2. Shorebird xatolari — faqat yangilanish yo'lidagi xatolar:
       - `update()` / `checkForUpdate()` xatosi (tarmoq uzilishi emas —
         oflayn kassa kanalni to'ldirmasin);
       - yuklangan patch ishga tushmadi (Shorebird uni yaroqsiz deb eski
         versiyaga qaytdi);
       - rollback (patch raqami kamaydi).
       Bir xil xato bir build uchun bir marta, kuniga ko'pi bilan
       [_dailyErrorCap] ta.

    Sotuvga ta'sir qilmaydi: barcha xatolar yutiladi, faqat `[PATCH-TG]` log.
    Debug yoki `shorebird release` siz build'da hech narsa qilmaydi
    (`PatchUpdater.start` ichidan chaqiriladi).
*/

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:invan2/changes/providers/settings_provider.dart';
import 'package:invan2/changes/services/health/backend_health.dart';
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class PatchReporter {
  PatchReporter._();

  // @invan_update_monitor_bot → "Invan Shorebird Builds" kanali.
  // Bot faqat shu kanalda admin. Bo'sh bo'lsa hisobot o'chiq (faqat log).
  static const String _botToken =
      '8765885617:AAHQpp0sHIMoUyuQl1L_eFl_EsMjMeEX9hc';
  static const String _chatId = '-1003904407778';

  static bool get _configured => _botToken.isNotEmpty && _chatId.isNotEmpty;

  static const Duration _interval = Duration(minutes: 5);
  static const int _dailyErrorCap = 10;
  static const int _maxQueuedErrors = 20;

  static ShorebirdUpdater? _updater;
  static Timer? _timer;
  static bool _busy = false;
  static String? _version;

  /// `start` dan oldin (main() boshida, Hive ochilmasdan) yuz bergan xatolar
  /// ham shu yerda kutadi.
  static final List<PatchErrorReport> _errors = <PatchErrorReport>[];

  /// `PatchUpdater.start` dan — runApp'dan keyin, Hive ochiq.
  static void start(ShorebirdUpdater updater) {
    if (_timer != null) return;
    _updater = updater;
    _timer = Timer.periodic(_interval, (_) => _tick());
    // Ochilishda sotuvga xalaqit bermasin — biroz kutamiz.
    Timer(const Duration(seconds: 20), _tick);
    BackendHealth.status.addListener(_onConnectivityChanged);
  }

  static void _onConnectivityChanged() {
    if (BackendHealth.status.value == BackendStatus.up) _tick();
  }

  /// Shorebird yo'lidagi xato. Tarmoq uzilishi bo'lsa faqat log.
  static void error(String stage, Object error) {
    if (PatchReportLogic.isNetworkError(error)) return;
    if (_errors.length >= _maxQueuedErrors) return;
    _errors.add(PatchErrorReport(stage: stage, message: '$error'));
    if (_timer != null) unawaited(_tick());
  }

  static Future<void> _tick() async {
    final ShorebirdUpdater? updater = _updater;
    if (_busy || updater == null) return;
    _busy = true;
    try {
      // Aktivatsiyagacha do'kon/kassa nomi yo'q — keyinroq.
      if (Pref.getString(PrefKeys.storeName, '').isEmpty) return;
      final String version = _version ??= await _appVersion();
      if (version.isEmpty) return;

      final int? current = (await updater.readCurrentPatch())?.number;
      final int? next = (await updater.readNextPatch())?.number;
      final String currentKey = PatchReportLogic.buildKey(version, current);

      final List<PatchBootEvent> events = PatchReportLogic.bootEvents(
        version: version,
        current: current,
        next: next,
        lastReported: Pref.getString(PrefKeys.patchReportedBuild, ''),
        pending: Pref.getString(PrefKeys.patchPendingBuild, ''),
      );
      for (final PatchBootEvent event in events) {
        if (!await _send(_bootMessage(event, currentKey))) return;
        if (event.kind == PatchBootKind.notApplied) {
          await Pref.setString(PrefKeys.patchPendingBuild, '');
        } else {
          await Pref.setString(PrefKeys.patchReportedBuild, currentKey);
        }
      }

      // Diskda yangi patch kutmoqda — keyingi ochilishda u ishga tushmasa
      // "qo'llanmadi" deb xabar beriladi.
      final String pending = PatchReportLogic.pendingKey(
        version: version,
        current: current,
        next: next,
        previous: Pref.getString(PrefKeys.patchPendingBuild, ''),
      );
      await Pref.setString(PrefKeys.patchPendingBuild, pending);

      await _flushErrors(currentKey);
    } catch (e) {
      _log('tick xatosi: $e');
    } finally {
      _busy = false;
    }
  }

  static Future<void> _flushErrors(String buildKey) async {
    while (_errors.isNotEmpty) {
      final PatchErrorReport report = _errors.first;
      final Map<dynamic, dynamic> state = _errorState();
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final PatchErrorDecision decision = PatchReportLogic.errorDecision(
        state: state,
        buildKey: buildKey,
        today: today,
        signature: report.signature,
        dailyCap: _dailyErrorCap,
      );
      if (decision.send) {
        if (!await _send(_errorMessage(report, buildKey))) return;
        await Pref.setObject(PrefKeys.patchReportErrors, decision.newState);
      }
      _errors.removeAt(0);
    }
  }

  static Map<dynamic, dynamic> _errorState() {
    final dynamic raw = Pref.getObject(PrefKeys.patchReportErrors);
    return raw is Map ? raw : <dynamic, dynamic>{};
  }

  static Future<String> _appVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return '';
    }
  }

  // ---- Xabarlar ----

  static String _header() {
    final String org = Pref.getString(PrefKeys.organizationName, '-');
    final String store = Pref.getString(PrefKeys.storeName, '-');
    final String pos = Pref.getString(PrefKeys.posName, '-');
    final String computer =
        '${SettingsInnerSingleton.deviceData['computerName'] ?? '-'}';
    return '🏢 <b>Tashkilot:</b> ${_esc(org)}\n'
        '🏬 <b>Do\'kon:</b> ${_esc(store)}\n'
        '🖥 <b>Kassa:</b> ${_esc(pos)}\n'
        '💻 <b>Kompyuter:</b> ${_esc(computer)} (${Platform.operatingSystem})';
  }

  static String _time() =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  static String _bootMessage(PatchBootEvent event, String currentKey) {
    final String now = PatchReportLogic.describe(currentKey);
    switch (event.kind) {
      case PatchBootKind.installed:
        final String prev = event.previous.isEmpty
            ? '— (birinchi hisobot)'
            : PatchReportLogic.describe(event.previous);
        return '✅ <b>Yangi build olindi — muammo yo\'q</b>\n\n'
            '${_header()}\n\n'
            '📦 <b>Build:</b> ${_esc(now)}\n'
            '⬅️ <b>Oldingi:</b> ${_esc(prev)}\n'
            '🕒 ${_time()}';
      case PatchBootKind.rolledBack:
        return '⚠️ <b>Patch orqaga qaytarildi (rollback)</b>\n\n'
            '${_header()}\n\n'
            '📦 <b>Hozir:</b> ${_esc(now)}\n'
            '⬅️ <b>Oldin:</b> ${_esc(PatchReportLogic.describe(event.previous))}\n'
            '🕒 ${_time()}';
      case PatchBootKind.notApplied:
        return '❌ <b>Patch ishga tushmadi</b>\n'
            'Yuklangan edi, lekin dastur unda ochilmadi — Shorebird eski '
            'versiyaga qaytdi (yoki patch konsoldan bekor qilingan).\n\n'
            '${_header()}\n\n'
            '📥 <b>Yuklangan:</b> ${_esc(PatchReportLogic.describe(event.previous))}\n'
            '📦 <b>Ishlayapti:</b> ${_esc(now)}\n'
            '🕒 ${_time()}';
    }
  }

  static String _errorMessage(PatchErrorReport report, String buildKey) {
    final String message = report.message.length > 1500
        ? '${report.message.substring(0, 1500)}…'
        : report.message;
    return '❌ <b>Shorebird xatosi</b>\n\n'
        '${_header()}\n\n'
        '📦 <b>Build:</b> ${_esc(PatchReportLogic.describe(buildKey))}\n'
        '🔧 <b>Bosqich:</b> ${_esc(report.stage)}\n'
        '🕒 ${_time()}\n\n'
        '<pre>${_esc(message)}</pre>';
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// `true` — Telegram qabul qildi.
  static Future<bool> _send(String text) async {
    if (!_configured) {
      _log('kanal sozlanmagan, yuborilmadi:\n$text');
      return false;
    }
    try {
      final http.Response response = await http.post(
        Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage'),
        body: <String, String>{
          'chat_id': _chatId,
          'text': text,
          'parse_mode': 'HTML',
          'disable_web_page_preview': 'true',
        },
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return true;
      _log('Telegram ${response.statusCode}: ${response.body}');
    } catch (e) {
      _log('yuborib bo\'lmadi: $e');
    }
    return false;
  }

  static void _log(String message) {
    if (kDebugMode) debugPrint('[PATCH-TG] $message');
    unawaited(LogHelper.write(LogLevel.info, '[PATCH-TG] $message'));
  }
}

/// Navbatdagi xato hisoboti.
class PatchErrorReport {
  const PatchErrorReport({required this.stage, required this.message});

  final String stage;
  final String message;

  /// Takrorni aniqlash uchun — raqamlar (port, vaqt) olib tashlanadi.
  String get signature {
    final String m = message.replaceAll(RegExp(r'\d+'), '#');
    return '$stage|${m.length > 160 ? m.substring(0, 160) : m}';
  }
}

enum PatchBootKind {
  /// Yangi build ishga tushdi (yangi patch yoki yangi reliz).
  installed,

  /// Shu relizda patch raqami kamaydi.
  rolledBack,

  /// Yuklangan patch ishga tushmadi.
  notApplied,
}

class PatchBootEvent {
  const PatchBootEvent(this.kind, this.previous);

  final PatchBootKind kind;

  /// installed/rolledBack — oldingi hisobot qilingan build kaliti;
  /// notApplied — ishga tushmagan patch kaliti.
  final String previous;
}

class PatchErrorDecision {
  const PatchErrorDecision(this.send, this.newState);

  final bool send;
  final Map<dynamic, dynamic> newState;
}

/// Sof qarorlar (Shorebird/Hive/tarmoqsiz) — testlanadi.
class PatchReportLogic {
  PatchReportLogic._();

  /// `1.1.2+128` (patch yo'q) yoki `1.1.2+128#3`.
  static String buildKey(String version, int? patch) =>
      patch == null ? version : '$version#$patch';

  static String versionOf(String key) => key.split('#').first;

  static int? patchOf(String key) {
    final List<String> parts = key.split('#');
    return parts.length > 1 ? int.tryParse(parts[1]) : null;
  }

  /// Odam o'qiydigan ko'rinish: `1.1.2+128 · patch 3` / `1.1.2+128 · asl reliz`.
  static String describe(String key) {
    final int? patch = patchOf(key);
    return '${versionOf(key)} · ${patch == null ? 'asl reliz' : 'patch $patch'}';
  }

  /// Joriy ishga tushirish bo'yicha yuboriladigan xabarlar.
  static List<PatchBootEvent> bootEvents({
    required String version,
    required int? current,
    required int? next,
    required String lastReported,
    required String pending,
  }) {
    final List<PatchBootEvent> events = <PatchBootEvent>[];
    final String currentKey = buildKey(version, current);

    // Oldingi ochilishda diskda kutgan patch — endi u ham ishlamayapti, ham
    // navbatda emas, va undan yangisi ham ishlamayapti.
    final int? pendingPatch = patchOf(pending);
    if (pendingPatch != null &&
        versionOf(pending) == version &&
        next != pendingPatch &&
        (current == null || current < pendingPatch)) {
      events.add(PatchBootEvent(PatchBootKind.notApplied, pending));
    }

    if (lastReported != currentKey) {
      final int? lastPatch = patchOf(lastReported);
      final bool rolledBack = lastReported.isNotEmpty &&
          versionOf(lastReported) == version &&
          lastPatch != null &&
          (current == null || current < lastPatch);
      events.add(PatchBootEvent(
          rolledBack ? PatchBootKind.rolledBack : PatchBootKind.installed,
          lastReported));
    }
    return events;
  }

  /// Saqlanadigan "kutayotgan patch" kaliti. Bo'sh — kutayotgan yo'q.
  static String pendingKey({
    required String version,
    required int? current,
    required int? next,
    required String previous,
  }) {
    if (next != null && (current == null || next > current)) {
      return buildKey(version, next);
    }
    // Patch ishga tushdi (yoki yangi reliz) — kutish tugadi.
    final int? prevPatch = patchOf(previous);
    if (prevPatch == null || versionOf(previous) != version) return '';
    if (current != null && current >= prevPatch) return '';
    // Hali "qo'llanmadi" xabari yuborilmagan — saqlanadi.
    return previous;
  }

  /// Xatoni yuborish kerakmi va yangi holat.
  /// Holat: `{build, day, count, sigs: [..]}`.
  static PatchErrorDecision errorDecision({
    required Map<dynamic, dynamic> state,
    required String buildKey,
    required String today,
    required String signature,
    required int dailyCap,
  }) {
    final bool sameBuild = state['build'] == buildKey;
    final List<String> sigs = sameBuild
        ? List<String>.from((state['sigs'] as List?) ?? const <String>[])
        : <String>[];
    final int count =
        state['day'] == today ? (state['count'] as int? ?? 0) : 0;

    if (sigs.contains(signature) || count >= dailyCap) {
      return PatchErrorDecision(false, state);
    }
    return PatchErrorDecision(true, <String, dynamic>{
      'build': buildKey,
      'day': today,
      'count': count + 1,
      'sigs': <String>[...sigs, signature],
    });
  }

  /// Internet/server uzilishi — kassa oflayn ishlayotganda kutiladigan holat,
  /// kanalga yuborilmaydi.
  static bool isNetworkError(Object error) {
    if (error is SocketException ||
        error is HttpException ||
        error is TimeoutException ||
        error is HandshakeException ||
        error is http.ClientException) {
      return true;
    }
    if (error is UpdateException &&
        error.reason == UpdateFailureReason.installFailed) {
      return false;
    }
    final String m = '$error'.toLowerCase();
    const List<String> markers = <String>[
      'failed host lookup',
      'dns error',
      'error sending request',
      'connection refused',
      'connection reset',
      'connection closed',
      'network is unreachable',
      'timed out',
      'actively refused',
      'no route to host',
    ];
    return markers.any(m.contains);
  }
}
```

### 6.2. `lib/utils/constants/pref_keys.dart`

```dart
  /// Telegram kanaliga "build olindi" deb oxirgi yuborilgan build kaliti
  /// (`<versiya>#<patch>`). Qarang: `PatchReporter`.
  static const String patchReportedBuild = 'patch_reported_build';
  /// Diskda yuklangan, hali ishga tushmagan patch kaliti. Keyingi ochilishda
  /// u ishlamasa — "patch ishga tushmadi" xabari.
  static const String patchPendingBuild = 'patch_pending_build';
  /// Shorebird xato hisobotlari takrori/kunlik chegarasi holati (Map).
  static const String patchReportErrors = 'patch_report_errors';
```

### 6.3. Test

<details><summary>YANGI: <code>test/patch_reporter_test.dart</code></summary>

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/services/patch_reporter.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() {
  const String v = '1.1.2+128';

  group('bootEvents — "build olindi" har build uchun bir marta', () {
    test('birinchi hisobot (hech narsa yuborilmagan) → installed', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 3, next: 3, lastReported: '', pending: '');
      expect(events.single.kind, PatchBootKind.installed);
      expect(events.single.previous, '');
    });

    test('shu build allaqachon yuborilgan → hech narsa', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 3, next: 3, lastReported: '$v#3', pending: '');
      expect(events, isEmpty);
    });

    test('yangi patch ishga tushdi → installed, oldingi ko\'rsatiladi', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 4, next: 4, lastReported: '$v#3', pending: '$v#4');
      expect(events.single.kind, PatchBootKind.installed);
      expect(events.single.previous, '$v#3');
    });

    test('yangi reliz (patchsiz) — eski relizning patch\'idan keyin → installed', () {
      final events = PatchReportLogic.bootEvents(
          version: '1.1.2+129',
          current: null,
          next: null,
          lastReported: '$v#5',
          pending: '');
      expect(events.single.kind, PatchBootKind.installed);
    });

    test('shu relizda patch raqami kamaydi → rolledBack', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 2, next: 2, lastReported: '$v#3', pending: '');
      expect(events.single.kind, PatchBootKind.rolledBack);
    });

    test('patch\'dan asl relizga qaytdi → rolledBack', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: null, next: null, lastReported: '$v#3', pending: '');
      expect(events.single.kind, PatchBootKind.rolledBack);
    });

    test('yuklangan patch ishga tushmadi (eski patch\'da qoldi) → notApplied', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 3, next: 3, lastReported: '$v#3', pending: '$v#4');
      expect(events.single.kind, PatchBootKind.notApplied);
      expect(events.single.previous, '$v#4');
    });

    test('patch hali navbatda (qayta ochilmagan) → xato emas', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 3, next: 4, lastReported: '$v#3', pending: '$v#4');
      expect(events, isEmpty);
    });

    test('kutilgandan yangiroq patch ishladi → faqat installed', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 5, next: 5, lastReported: '$v#3', pending: '$v#4');
      expect(events.single.kind, PatchBootKind.installed);
    });

    test('pending boshqa relizdan (yangi .exe o\'rnatildi) → notApplied emas', () {
      final events = PatchReportLogic.bootEvents(
          version: '1.1.2+129',
          current: null,
          next: null,
          lastReported: '1.1.2+129',
          pending: '$v#4');
      expect(events, isEmpty);
    });

    test('patch ishga tushmadi + undan oldingisi hali yuborilmagan → ikkalasi', () {
      final events = PatchReportLogic.bootEvents(
          version: v, current: 3, next: 3, lastReported: '$v#2', pending: '$v#4');
      expect(events.map((e) => e.kind),
          [PatchBootKind.notApplied, PatchBootKind.installed]);
    });
  });

  group('pendingKey', () {
    test('diskda yangiroq patch → saqlanadi', () {
      expect(
          PatchReportLogic.pendingKey(
              version: v, current: 3, next: 4, previous: ''),
          '$v#4');
    });

    test('patchsiz relizda birinchi patch yuklandi', () {
      expect(
          PatchReportLogic.pendingKey(
              version: v, current: null, next: 1, previous: ''),
          '$v#1');
    });

    test('patch ishga tushdi → tozalanadi', () {
      expect(
          PatchReportLogic.pendingKey(
              version: v, current: 4, next: 4, previous: '$v#4'),
          '');
    });

    test('ishga tushmagan patch xabari hali yuborilmagan → saqlanib qoladi', () {
      expect(
          PatchReportLogic.pendingKey(
              version: v, current: 3, next: 3, previous: '$v#4'),
          '$v#4');
    });

    test('rollback kutilmoqda (next null) → pending emas', () {
      expect(
          PatchReportLogic.pendingKey(
              version: v, current: 3, next: null, previous: ''),
          '');
    });

    test('boshqa relizdagi pending → tozalanadi', () {
      expect(
          PatchReportLogic.pendingKey(
              version: '1.1.2+129', current: null, next: null, previous: '$v#4'),
          '');
    });
  });

  group('errorDecision — takror va kunlik chegara', () {
    const String day = '2026-10-02';

    test('yangi xato → yuboriladi, holat yoziladi', () {
      final d = PatchReportLogic.errorDecision(
          state: {}, buildKey: '$v#3', today: day, signature: 'a', dailyCap: 10);
      expect(d.send, isTrue);
      expect(d.newState['sigs'], ['a']);
      expect(d.newState['count'], 1);
    });

    test('shu build\'da shu xato bor → yuborilmaydi', () {
      final d = PatchReportLogic.errorDecision(
          state: {'build': '$v#3', 'day': day, 'count': 1, 'sigs': ['a']},
          buildKey: '$v#3',
          today: day,
          signature: 'a',
          dailyCap: 10);
      expect(d.send, isFalse);
    });

    test('yangi build\'da shu xato → yana yuboriladi', () {
      final d = PatchReportLogic.errorDecision(
          state: {'build': '$v#3', 'day': day, 'count': 1, 'sigs': ['a']},
          buildKey: '$v#4',
          today: day,
          signature: 'a',
          dailyCap: 10);
      expect(d.send, isTrue);
      expect(d.newState['sigs'], ['a']);
      expect(d.newState['count'], 2);
    });

    test('kunlik chegara → yuborilmaydi, ertasiga yana', () {
      final state = {'build': '$v#3', 'day': day, 'count': 10, 'sigs': ['x']};
      expect(
          PatchReportLogic.errorDecision(
                  state: state,
                  buildKey: '$v#3',
                  today: day,
                  signature: 'b',
                  dailyCap: 10)
              .send,
          isFalse);
      expect(
          PatchReportLogic.errorDecision(
                  state: state,
                  buildKey: '$v#3',
                  today: '2026-10-03',
                  signature: 'b',
                  dailyCap: 10)
              .send,
          isTrue);
    });
  });

  group('isNetworkError — oflayn kassa kanalni to\'ldirmaydi', () {
    test('tarmoq istisnolari', () {
      expect(PatchReportLogic.isNetworkError(const SocketException('x')), isTrue);
      expect(PatchReportLogic.isNetworkError(TimeoutException('x')), isTrue);
      expect(PatchReportLogic.isNetworkError(http.ClientException('x')), isTrue);
    });

    test('Shorebird yuklash xatosi tarmoq sababli → tarmoq', () {
      const e = UpdateException(
          message: 'error sending request for url (https://api.shorebird.dev)',
          reason: UpdateFailureReason.downloadFailed);
      expect(PatchReportLogic.isNetworkError(e), isTrue);
    });

    test('yaroqsiz patch (installFailed) → doim yuboriladi', () {
      const e = UpdateException(
          message: 'connection reset while hashing',
          reason: UpdateFailureReason.installFailed);
      expect(PatchReportLogic.isNetworkError(e), isFalse);
    });

    test('noma\'lum Shorebird xatosi → yuboriladi', () {
      const e = UpdateException(
          message: 'Patch hash mismatch',
          reason: UpdateFailureReason.downloadFailed);
      expect(PatchReportLogic.isNetworkError(e), isFalse);
    });
  });

  test('describe va signature', () {
    expect(PatchReportLogic.describe('$v#3'), '1.1.2+128 · patch 3');
    expect(PatchReportLogic.describe(v), '1.1.2+128 · asl reliz');
    expect(
        const PatchErrorReport(stage: 'update', message: 'port 5123 fail')
            .signature,
        const PatchErrorReport(stage: 'update', message: 'port 7000 fail')
            .signature);
  });
}
```

</details>

## 7. Tekshirish

- `flutter test test/patch_reporter_test.dart`; to'liq to'plam — 1616/1616 (2026-10-02, `c4e42e1`).
- Mac sinov relizi (2026-10-02): patch 4 va patch 5 da kanalga "build olindi" yuborildi (Telegram 200, `patch_reported_build` yangilandi).

## 8. Eslatmalar

- Token kod ichida — repo yopiq bo'lishi shart; bot faqat shu kanalda admin (sizib chiqsa ham faqat kanalga yozish mumkin). Xohlansa `--dart-define` + GitHub secret'ga ko'chirish mumkin (u holda lokal sinov build'larida hisobot o'chiq bo'ladi — bu ham qulay).
- Odoo forkiga: kerak emas — InVan Shorebird `app_id` va InVan Telegram kanaliga bog'langan; Odoo xohlasa o'z bot/kanali bilan oladi.

---

# Kod o'zgarishisiz hujjatlar (shu davrda yozilgan)

| Fayl | Nima | Port uchun |
|---|---|---|
| `docs/fiskal-tolov-turlari-va-qqs.md` | Tahlil (2026-09): to'lov turlari → fiskal maydonlar (`Cash`/`Card`/`Other`), Click/Payme qanday hisoblanadi, QQS hisoblash (`VAT`, chop etilgan chek, QQS foizi manbai), cashback xulosasi, nomuvofiqliklar ro'yxati. Kod o'zgarmagan; 5-task shundan chiqdi | Ma'lumot uchun; InVan 1 dagi fiskal item quruvchini shu tahlil bilan solishtirish foydali |
| `docs/invan1-mac-github-release-port.md` | InVan 1 ni Mac'da ishga tushirish (macOS target) va GitHub Actions orqali Windows `.exe` reliz (CMakeLists MSVC coroutine tuzatishi, `installer.iss`, `release.yml`, tag `v*`) | To'g'ridan-to'g'ri InVan 1 uchun yozilgan — alohida qo'llang |
| `docs/fiscal-sale-integration.md`, `.ru.md` | Fiskal sotuv spec (item maydonlari, `Price`/`Discount`/`Other`/`VAT`, `OwnerType`, `CommissionInfo`) — VAT formulasi 5-task bilan yangilandi | Spec; InVan 1 fiskal body'sini shu bilan tekshirish |
| `docs/shorebird-qoidalari.md` | Shorebird: nima patch bilan o'tadi / nima reliz talab qiladi, patch chiqarish (staging → preview → promote), rollback, Mac sinovi, xavflar (2026-10-02) | 8-task ishlatilsa — InVan 1 o'z relizlari va `app_id` si bilan moslab oladi |
| `docs/fiskal-tolov-turlari-qisqa.md` | To'lov turlari → fiskal maydon (`Cash`/`Card`/`Other`), QQS va provayderga qaytarish — qisqa jadval (9-task holatida) | Ma'lumot uchun |
| `docs/bhm-naqd-chegara-port.md`, `docs/fiskal-mxik-fallback-port.md` | 1- va 2-taskning per-task port hujjatlari — yuqorida to'liq kiritilgan | Dublikat, alohida kerak emas |

---

# Hujjatni yangilash qoidasi (InVan 2 tomonida)

Bu fayl — boshqa nusxa uchun **yagona** manba. `CLAUDE.md` dagi "PORT HUJJATI" bo'limiga qarang. Qisqacha: har commit qilingan task uchun quyidagi shablon bo'yicha bo'lim qo'shiladi, jadval (`## Tasklar ro'yxati`) va commit xronologiyasi yangilanadi; reliz chiqqanda "InVan 2 reliz" ustuni to'ldiriladi; commit qilinmagan ishlar faqat qisqa **WIP** bo'lim sifatida ("PORT QILINMASIN").

```markdown
---

# N-TASK — <nom> (<reliz yoki "relizda emas">)

> **Commit:** `<hash>` (<sana>), reliz `<hash>` <versiya>.
> **Sessiya hujjati:** docs/sessions/<fayl>.md
> **Holat <sana>:** ...

## 1. Nima va nima uchun         (simptom, sabab, yechim — 1 abzasdan)
## 2. Qanday ishlaydi            (oqim; eski vs yangi)
## 3. O'zgarishlar ro'yxati      (jadval: fayl | tur (YANGI/o'zgargan) | nima)
## 4. Bog'liqliklar              (InVan 1 da bo'lmasligi mumkin bo'lgan sinflar + minimal variant)
## 5. Qo'llash tartibi           (raqamlangan qadamlar, har biri kod bo'limiga ishora)
## 6. Kod                        (yangi fayl TO'LIQ, o'zgargan fayl DIFF; testlar <details> ichida)
## 7. Tekshirish                 (testlar, E2E, do'kon sinovi holati)
## 8. Eslatmalar va ochiq savollar
```

Kodni olish: `git show <commit> -- lib/ test/` (docs va pubspec'siz). Yangi fayl uchun `git show <commit>:<yo'l>`.
