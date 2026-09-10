# Task: Naqd to'lov chegarasini (400 × BHM) Soliq API'dan olish

**Boshlangan:** 2026-09-10
**Holat:** in-progress (1.1.2+123 relizga kiritildi 2026-09-10; do'konda real API bilan sinov kutilmoqda)
**Branch:** ayyubxon

## Maqsad
2026-07-20 393-son qaror va 2026-08-27 PF-175 Farmon: narxi 400 × BHM dan
oshadigan tovar/xizmat uchun naqd to'lov taqiqlanadi. Ilgari chegara kodga
qattiq yozilgan edi (25 mln, keyin 175 mln). Endi BHM Soliq API'sidan
olinib lokalga saqlanadi, cheklov lokaldan o'qiydi, yangilash kam
bo'ladigan amallarga bog'lanadi.

## API
```
GET https://txkm.soliq.uz/api/txkm-api/ccm-api/info/check/is-vat/<STIR>
accept: */*
→ {"success":true,"reason":"So'rov bajarildi","data":true,"percent":12,
   "cashSaleAllowed":false,"fractionalSale":false,"baseCalculationAmount":440000}
```
- Auth kerak emas (2026-09-10 da tekshirildi, HTTP 200).
- Postdagi URL to'liq emas edi (`check/` va STIR yetishmagan) — Elnor'ning
  forward'idan olindi.
- 400 × 440 000 = **176 000 000** (175 emas — avval so'ralgan raqam 1 mln kam edi).
- STIR manbai: `PrefKeys.organizationINN` (organization_singleton.dart:18,
  `taxPayerId` dan to'ldiriladi).

## Scope
- lib/changes/services/cash_limit/bhm_service.dart (YANGI)
- lib/changes/domain/cart/cash_restriction_rules.dart (`limit` parametr)
- lib/changes/providers/ordering_provider_4.dart (`isBigTotalHidden`)
- lib/features/home/features/home_orders/order_list/order_list_item.dart
- lib/changes/providers/open_shift_provider.dart (hook)
- lib/app/wrapper/wrapper.dart (hook)
- lib/utils/constants/pref_keys.dart, l10n arb
- Scope'dan tashqari: javobdagi `cashSaleAllowed`, `percent`, `data`
  maydonlari (hozircha ishlatilmaydi, qarang: Ochiq savollar).

## Bajarilgan
- [x] `BhmService`: API → Pref kesh (`bhm_amount`, `bhm_fetched_at`),
  `cashLimit = bhm × 400`, fallback 440 000, TTL 24 soat, in-flight guard,
  test uchun `request`/`now` inyeksiyasi
  → lib/changes/services/cash_limit/bhm_service.dart
  → Sabab: cheklov sotuv paytida tarmoqqa chiqmasligi kerak; xato bo'lsa
    eski kesh qoladi, exception chiqmaydi.
- [x] `CashRestrictionRules.bigTotalHidden` ga `required double limit`
  → lib/changes/domain/cart/cash_restriction_rules.dart
  → Sabab: qoida sof qoladi (Pref/Hive'siz testlanadi); qiymatni
    chaqiruvchi (`BhmService.cashLimit`) beradi. Eski `bigTotalLimit`
    konstantasi olib tashlandi.
- [x] Hook: smena ochilganda (`OpenShiftProvider.openShift`, result==true)
  `unawaited(BhmService.refreshIfStale(reason: 'shift-open'))`
  → Sabab: foydalanuvchi talabi — kam bo'ladigan amalga bog'lash; smena
    har sotuvdan oldin ochiladi, demak birinchi sotuvgacha kesh to'ladi.
- [x] Hook: startup (`Wrapper`, auth'dan keyin, navbatlar flush'i yonida)
  → Sabab: ilova smena ochiq holda yangilangan/qayta ochilgan holatni
    qoplaydi. TTL tufayli arzon.
- [x] order_list_item.dart va ordering_provider_4.dart `BhmService.cashLimit`
- [x] l10n `narx_limit_oshdi` → "BHMning 400 baravaridan oshdi" (raqamsiz,
  eskirmaydi). Kodda ishlatilmagan matn, lekin arb'da qoldi.
- [x] Testlar: test/bhm_service_test.dart (yangi), cash_restriction_rules_test,
  cash_restriction_test (176 mln + Pref'dagi BHM testi)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows'da real sinov: smena ochish → loglarda
  `BHM (shift-open): 0 → 440000` yozuvi; naqd tugmasi 176 000 001 so'mlik
  qatorda yopilishi.
- [ ] Elnor'dan aniqlashtirish: chegara QATOR bo'yicha (hozirgi) yoki CHEK
  JAMI bo'yicha? (lib/changes/domain/cart/cash_restriction_rules.dart —
  `bigTotalHidden` sikli). 2 × 100 mln savat hozir naqdga ochiq.
- [ ] Elnor'dan aniqlashtirish: `cashSaleAllowed:false` nimani anglatadi?
  Tashkilot darajasida naqd taqiqmi? Agar shunday bo'lsa alohida task.

## Qabul qilingan qarorlar
- Chegara `limit` parametr sifatida uzatiladi, rules sinfi Pref'ga
  bog'lanmaydi — testlar sof qoladi.
- Yangilash: smena ochilishi + startup, ikkalasi 24 soat TTL bilan. Timer
  yo'q — BHM juda sekin o'zgaradi.
- Fallback 440 000 kodda qoladi — kesh bo'sh va oflayn bo'lsa ham qonuniy
  chegara (176 mln) ishlaydi.
- API xatosi hech qachon smena/startup'ni to'xtatmaydi (fire-and-forget).

## Ochiq savollar
- Qator vs chek jami — Elnor / Soliq texnik qo'llanmasi.
- `cashSaleAllowed` maydoni — Elnor.
- BHM yangilanganda `narx_limit_oshdi` matni ishlatilmaydi; dialog umumiy
  "naqd to'lov mumkin emas" ni ko'rsatadi — kassirga summa ko'rsatish
  kerakmi? (UX qarori, foydalanuvchi)

## Test / Verifikatsiya
- 2026-09-10: `flutter test` to'liq to'plam — 1096 test o'tdi; `dart analyze`
  o'zgargan fayllarda error/warning yo'q.
- `flutter test test/bhm_service_test.dart test/cash_restriction_rules_test.dart test/cash_restriction_test.dart`
- Real API: `curl 'https://txkm.soliq.uz/api/txkm-api/ccm-api/info/check/is-vat/<STIR>' -H 'accept: */*'`
