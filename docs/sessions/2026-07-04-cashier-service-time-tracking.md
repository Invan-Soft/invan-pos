# Task: Kassir xizmat vaqtini hisoblash (service time tracking)

**Boshlangan:** 2026-07-04
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Har bir sotuv uchun kassir mijozga qancha vaqt xizmat ko'rsatganini o'lchash:
savatga birinchi mahsulot qo'shilishi = started_time, chek yopilishi (sotuv
muvaffaqiyatli yakunlanishi) = closed_time. Chek raqami va (tanlangan bo'lsa)
mijoz ma'lumoti ham yig'iladi. Hozircha API tayyor emas — payload API'ga
tayyor holda debug console'ga print qilinadi; API chiqqach ulanadi.

## Scope
- `lib/changes/models/cashier_service_time_model.dart` — yangi model (toJson bilan)
- `lib/changes/services/cashier_service_time/` — tracker, api stub, facade service
- `lib/changes/providers/ordering_provider_4.dart` — 3 ta hook nuqtasi
- Scope'dan tashqari: haqiqiy API endpoint (hali yo'q), qaytarish (refund) cheklari

## Talablar (foydalanuvchidan)
1. API request sotuv OXIRIDA, hammasi tugagandan keyin, orqa fonda yuboriladi.
   API xato bersa → telegram'ga; kassada error ko'rsatilmaydi, sotuv to'xtamaydi.
2. Edge case: kassir bo'sh savatga mahsulot urdi, sotuvsiz savatni tozaladi →
   started_time SAQLANIB QOLADI (keyingi sotuv o'sha start bilan hisoblanadi).
   Start faqat sotuv yakunlanganda tozalanadi.
3. Clean code, MVVM, SOLID.

## Arxitektura qarorlari
- Start vaqtlar `clientNumber` (6-mijoz sloti) bo'yicha `CashierServiceTimeTracker`
  singleton'ida saqlanadi — SixClientModel4 instansiyalari sotuvdan keyin qayta
  yaratiladi/o'chiriladi, tracker esa yashab qoladi (edge case #2 shuning uchun).
- `markStarted` = putIfAbsent (birinchi qo'shilish g'olib); `takeStartedTime`
  faqat sotuv yakunida remove qiladi.
- Chek raqami = `receiptModel4.externalId` (ReceiptSingleton4.toOBJECTBOX ichida
  getCheckNo() bilan beriladi) — shuning uchun hook toOBJECTBOX'dan KEYIN turadi.
- Telegram xato yuborish: mavjud `LogRepository.addLog` (network xatolarni o'zi
  filtrlab tashlaydi, spam bo'lmaydi).

## Hook nuqtalari
- `addProduct` boshida → `onProductAdded(_currentClient.clientNumber)`
- `pressPaymentButton` — toOBJECTBOX'dan keyin → `onSaleCompleted(...)`
- `pressPaymentButtonOnlyOFD` — `paymentResult.success` blokida,
  `_paymentOnClients()` dan OLDIN → `onSaleCompleted(...)`

## Bajarilgan
- [x] Kod o'rganildi: sotuv oqimi, chek raqami manbai, telegram log servisi
  → lib/changes/providers/ordering_provider_4.dart:2896 (pressPaymentButton),
    :3154 (pressPaymentButtonOnlyOFD), :355 (addProduct)
  → lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart:32 (externalId)
  → Sabab: hook nuqtalarini aniqlash
- [x] Model yaratildi (toJson bilan, API'ga tayyor payload)
  → lib/changes/models/cashier_service_time_model.dart
- [x] Tracker (slot bo'yicha start vaqtlar, faqat sotuv yakunida tozalanadi)
  → lib/changes/services/cashier_service_time/cashier_service_time_tracker.dart
- [x] API stub (hozircha debugPrint; xato → LogRepository.addLog → telegram;
  hech qachon throw qilmaydi)
  → lib/changes/services/cashier_service_time/cashier_service_time_api.dart
- [x] Facade service (onProductAdded / onSaleCompleted, unawaited send)
  → lib/changes/services/cashier_service_time/cashier_service_time_service.dart
- [x] 3 ta hook ulandi: addProduct boshida markStarted; pressPaymentButton'da
  toOBJECTBOX'dan keyin va pressPaymentButtonOnlyOFD'da success blokida
  onSaleCompleted
  → lib/changes/providers/ordering_provider_4.dart
- [x] flutter analyze: yangi fayllar toza, provider'da issue soni o'zgarmadi
  (43 → 43, hammasi eski)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows'da real sotuv bilan tekshirish: debug console'da payload chiqishi
- [ ] API endpoint chiqqach `cashier_service_time_api.dart` dagi TODO'ni ulash

## Ochiq savollar
- API endpoint URL/format — backend'dan kutilmoqda

## Test / Verifikatsiya
- Windows build'da: mahsulot qo'shish → to'lov → debug console'da
  `🕒 KASSIR XIZMAT VAQTI` payload chiqishi kerak
- Edge case: mahsulot qo'shib savatni tozalash → yana qo'shib sotish →
  started_time birinchi qo'shilgan vaqt bo'lishi kerak
