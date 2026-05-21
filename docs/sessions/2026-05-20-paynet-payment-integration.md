# Task: Paynet Pass to'lov turini integratsiya qilish

**Boshlangan:** ~2026 (aniq sana noma'lum — branch tarixiga qarang)
**Holat:** in-progress (prod URL kutilmoqda)
**Branch:** main

## Maqsad

Paynet Pass — yangi to'lov provayderi (Click/Payme/Uzum singari QR/OTP asosida ishlaydigan). Foydalanuvchi telefonida ko'rsatilgan OTP/QR kodni skaner orqali o'qib, summa Paynet API'siga yuboriladi, status polling qilinadi va muvaffaqiyatli bo'lgach OFD'ga fiskal chek jo'natiladi.

Task amalda **deyarli yakunlangan** — barcha API integratsiya, BLoC, dialog, fiskal chek yo'lash kodlari yozilgan va test URL bilan ishlaydi. **Faqat prod URL hali yoqilmagan** (Paynet tomonida) — yoqilgach bir necha qator o'zgartirib test qilib done'ga o'tkazish kerak.

## Scope

**Yangi qo'shilgan fayllar:**
- `lib/changes/services/payment/paynet_service.dart` — asosiy servis (422 qator)
- `lib/changes/models/paynet_response_model.dart` — response modeli
- `lib/features/payment/right/dilogs/paynet/paynet_dialog.dart` — UI dialog
- `lib/features/payment/right/dilogs/paynet/bloc/paynet_bloc.dart` — BLoC
- `lib/features/payment/right/dilogs/paynet/bloc/paynet_event.dart`
- `lib/features/payment/right/dilogs/paynet/bloc/paynet_state.dart`

**Mavjud fayllarga qo'shilgan o'zgarishlar:**
- `lib/app/app.dart:51, 152` — `PaynetBloc` MultiBlocProvider'ga qo'shildi
- `lib/changes/providers/ordering_provider_4.dart:40-42, 3084, 3905, 4017-4073` — `typePaynet()` metodi, `_paynetPayIsWorking` flag
- `lib/changes/services/local_selling_service.dart:17, 134-145` — fiskal chek muvaffaqiyatdan keyin `PaynetService.sendFiscalReceipt` chaqirig'i
- `lib/changes/singletons/organization_singleton.dart:159-170` — `_onSubmittedPaynet`: backend'dan EPay konfiguratsiyasini olib Hive ga yozish
- `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart:204, 248-251` — `receivedPaynet` flag fiskal so'rovga qo'shildi
- `lib/features/payment/right/keyboard_of_payment_page.dart:206, 293, 310, 320` — to'lov klaviaturasiga Paynet tugmasi
- `lib/changes/models/epay/e_pay_model.dart:138` — `EPayEnum.paynet('paynet')`
- `lib/utils/constants/pref_keys.dart:96, 111` — `paynetEnable`, `paynetId` kalitlari
- `assets/images/paynet-logo.png` — tugmacha ikonkasi

**Scope dan tashqari:**
- Boshqa to'lov turlari (Click, Payme, Uzum) — alohida implementatsiyalari mavjud
- Paynet refund/return mantiqi — hozircha `reversalPayment` metodi yozilgan, lekin checks/return oqimida ishlatilmagan (kerak bo'lsa keyingi task)

## Bajarilgan ishlar

### 1. PaynetService — API qatlami
[lib/changes/services/payment/paynet_service.dart](../../lib/changes/services/payment/paynet_service.dart)

**v1.07 API yangilanishi to'liq qabul qilindi:**
- Base URL `https://pass-test.paynet.uz/v2/merchant` → `https://pass-test.paynet.uz` (test) / `https://api.paynet.uz` (prod) ([qator 42-44](../../lib/changes/services/payment/paynet_service.dart#L42-L44))
- `/v2/merchant` o'rniga har bir endpoint'ga `/api` prefiksi qo'shildi
- Auth header `Auth` → `AUTH` (katta harf) ([qator 416](../../lib/changes/services/payment/paynet_service.dart#L416))
- Yangi xato kodi `-29: TRANSACTION_ID_ALREADY_EXISTS` qo'llab-quvvatlandi ([qator 77-81](../../lib/changes/services/payment/paynet_service.dart#L77-L81))
- `merchant_user_id` kassa identifikatori sifatida ishlatilmoqda

**Implementatsiya qilingan endpointlar:**

| Metod | Endpoint | Maqsad |
|-------|----------|--------|
| `payment()` | POST `/api/paynet-pass/payment` | To'lovni yaratish (OTP+summa) — [qator 48-89](../../lib/changes/services/payment/paynet_service.dart#L48-L89) |
| `checkPaymentStatus(pid)` | GET `/api/paynet-pass/payment/status/by-payment-id/{service_id}/{payment_id}` | Status — payment_id bo'yicha — [qator 93-125](../../lib/changes/services/payment/paynet_service.dart#L93-L125) |
| `checkPaymentStatusByTransactionId(tx)` | GET `/api/payment/status/by-transaction-id/{service_id}/{transaction_id}` | Status — transaction_id bo'yicha (YANGI v1.07) — [qator 129-162](../../lib/changes/services/payment/paynet_service.dart#L129-L162) |
| `reversalPayment(pid)` | DELETE `/api/paynet-pass/payment/reversal/{service_id}/{payment_id}` | To'lovni bekor qilish — [qator 166-198](../../lib/changes/services/payment/paynet_service.dart#L166-L198) |
| `confirm(pid)` | POST `/api/paynet-pass/payment/confirm` | Confirm mode'da to'lovni tasdiqlash — [qator 202-214](../../lib/changes/services/payment/paynet_service.dart#L202-L214) |
| `enableConfirmMode()` | PUT `/api/paynet-pass/confirmation/{service_id}` | Confirm rejimini yoqish — [qator 218-243](../../lib/changes/services/payment/paynet_service.dart#L218-L243) |
| `disableConfirmMode()` | DELETE `/api/paynet-pass/confirmation/{service_id}` | Confirm rejimini o'chirish — [qator 247-272](../../lib/changes/services/payment/paynet_service.dart#L247-L272) |
| `sendFiscalReceipt(...)` | POST `/api/paynet-pass/ofd-data/submit-qrcode` | Fiskal QR Paynet'ga yuborish — [qator 276-311](../../lib/changes/services/payment/paynet_service.dart#L276-L311) |

**Autentifikatsiya** ([qator 396-421](../../lib/changes/services/payment/paynet_service.dart#L396-L421)):
- `AUTH` header format: `merchant_user_id:sha1(timestamp+secret_key):timestamp`
- Timestamp — joriy sekundlar (`millisecondsSinceEpoch ~/ 1000`)
- Sha1 ichida `timestamp + secret_key` concat qilinadi
- Credentials `EPayHelper.instance.box.get(EPayEnum.paynet.value)` orqali olinadi

**Xato boshqaruvi** ([qator 370-393](../../lib/changes/services/payment/paynet_service.dart#L370-L393)):
- SocketException / TimeoutException / HttpException — `errorCode: -1, errorNote: <xabar>`
- Status 200 dan farq qilsa — `errorCode: statusCode, errorNote: body`
- Telegram log'ga jo'natiladi (`LogRepository.addLog` orqali)

**Xato kodlari ro'yxati** — fayl oxirida ([qator 424-460](../../lib/changes/services/payment/paynet_service.dart#L424-L460)) batafsil jadval bilan hujjatlangan (-2 dan -29 gacha, har biri Uzbek tavsifi bilan).

### 2. PaynetResponseModel
[lib/changes/models/paynet_response_model.dart](../../lib/changes/models/paynet_response_model.dart)

Maydonlari: `errorCode`, `errorNote`, `paymentId`, `paymentStatus`, `confirmMode`, `cardType`, `cardNumber`, `phoneNumber`.

Diqqat:
- `paymentId` int yoki string'dan parse qilinadi (backend ikkala formatda yuborishi mumkin) — [qator 34-36](../../lib/changes/models/paynet_response_model.dart#L34-L36)
- `confirm_mode` int yoki bool sifatida kelishi mumkin, ichkarida int (0/1) ga normallashtiriladi — [qator 30, 38](../../lib/changes/models/paynet_response_model.dart#L30)
- `isConfirmMode` getter `confirmMode == 1` — [qator 27](../../lib/changes/models/paynet_response_model.dart#L27)

### 3. PaynetBloc — to'lov oqimi mantiqi
[lib/features/payment/right/dilogs/paynet/bloc/paynet_bloc.dart](../../lib/features/payment/right/dilogs/paynet/bloc/paynet_bloc.dart)

**Hodisalar:**
- `PaynetPayEvent(otp, summa, receiptNumber, isRetry)` — to'lovni boshlash
- `PaynetCallInitialEvent` — state'ni Initial ga qaytarish (dialog ochilganda)

**Holatlar:** `PaynetInitial`, `PaynetLoadingState(status)`, `PaynetPaymentSuccessState`, `PaynetPaymentErrorState(error)`, `PaynetNoInternetState(otp)`
- `PaynetLoadingStatus` enum: `internet | paying | polling`

**Asosiy oqim** ([qator 20-77](../../lib/features/payment/right/dilogs/paynet/bloc/paynet_bloc.dart#L20-L77)):
1. `_pay()`: `internet` → `paying` loading
2. `PaynetService.payment()` chaqiriladi (summa tiyinda — `(summa * 100).toInt()`)
3. Birinchi javobdanoq `confirm_mode` saqlab olinadi (keyingi status so'rovlarida bu maydon kelmaydi)
4. `payment_status == 2` → muvaffaqiyatli, `_handleSuccess()` ga o'tadi
5. `payment_status == 0 || 1` → `_pollStatus()` ga o'tadi
6. Xato status (< 0) yoki `error_code < 0` → `PaynetPaymentErrorState`

**Polling** ([qator 80-119](../../lib/features/payment/right/dilogs/paynet/bloc/paynet_bloc.dart#L80-L119)):
- Har 2 soniyada `checkPaymentStatus(pid)`
- Maksimum 15 marta urinish (jami 30 soniya timeout)
- Muvaffaqiyatli → `_handleSuccess()`, xato → ErrorState, timeout → "To'lov vaqti tugadi"

**Confirm rejimi** ([qator 122-138](../../lib/features/payment/right/dilogs/paynet/bloc/paynet_bloc.dart#L122-L138)):
- Agar birinchi javobda `confirm_mode == 1` bo'lsa, status `2` ga yetgach `PaynetService.confirm(pid)` chaqiriladi
- Confirm xato bersa → ErrorState

### 4. PaynetDialog — UI
[lib/features/payment/right/dilogs/paynet/paynet_dialog.dart](../../lib/features/payment/right/dilogs/paynet/paynet_dialog.dart)

- Top-right pozitsiyada modal dialog (`Alignment.topRight`, [qator 40](../../lib/features/payment/right/dilogs/paynet/paynet_dialog.dart#L40))
- `MyBarcodeListener` orqali skaner OTP/QR kodni kutadi ([qator 200-213](../../lib/features/payment/right/dilogs/paynet/paynet_dialog.dart#L200-L213))
- `BlBloc` (barcode listener) bilan integratsiya: dialog ochilganda `BLStatus.click` ga o'tadi, yopilganda `BLStatus.other` ga qaytadi
- 5 ta UI holati: Loading / Success ("To'lov amalga oshirildi") / Error / NoInternet (qayta urinish tugmasi) / Initial (QR kutish)
- Internet yo'q holatda OTP saqlanib qoladi va "qayta urinish" tugmasi orqali yana yuborish mumkin

### 5. OrderingProvider4 — typePaynet metodi
[lib/changes/providers/ordering_provider_4.dart:4017-4073](../../lib/changes/providers/ordering_provider_4.dart#L4017-L4073)

- `typePaynet(context, payment)` — Paynet tugmasi bosilganda chaqiriladi
- `_paynetPayIsWorking` flag ([qator 3905](../../lib/changes/providers/ordering_provider_4.dart#L3905)) — ikki marta bosilishni oldini oladi
- `receiptNumber` — `checkId + ObjectBox dagi cheklar soni` formatida yaratiladi
- `getAvailableSumma()` orqali to'lanmagan qoldiq summa olinadi (qisman to'lovga yo'l qo'yiladi)
- `showGeneralDialog` orqali PaynetDialog ochiladi, `barrierDismissible: false`
- Muvaffaqiyatli to'lovdan keyin `pay()` callback orqali `allPaymentType(payment)` chaqiriladi — to'lov OrderingProvider4 da ro'yxatga olinadi

`_selectedPaymentType` ga `@${payment.id}` yoki `payment.id` yoziladi (type == 1 bo'lsa `@` prefiks bilan) — bu OFD/fiskal request da ishlatiladi.

### 6. LocalSellingService — fiskal chekdan keyin Paynet'ga jo'natish
[lib/changes/services/local_selling_service.dart:134-145](../../lib/changes/services/local_selling_service.dart#L134-L145)

Fiskal modul muvaffaqiyatli javob bergach (sotuv qabul qilingan), agar `receivedPaynet == true` bo'lsa:
1. `pid` ni `PaynetService.paymentId` static field'dan oladi
2. `qrcode` ni fiskal modul javobidan (`res.info?.qrCodeUrl`) oladi
3. `address` ni `PrefKeys.serviceAddress` dan oladi
4. `PaynetService.sendFiscalReceipt(pid, qrcode, address)` chaqiradi
5. `PaynetService.paymentId = null` — keyingi sotuv uchun tozalaydi

### 7. ReceiptSingleton4 — saleOnOFD'ga receivedPaynet qo'shildi
[lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart:204, 248-251, 289](../../lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart#L204)

- Pref'dan `paynetId` o'qiladi (Click/Uzum/Payme kabi)
- `receivedPaynet` bool — agar biror payment.payId Paynet ID ga teng bo'lsa true
- Fiskal modul body `params.receivedPaynet` ichiga qo'shiladi

### 8. OrganizationSingleton — konfiguratsiyani yuklash
[lib/changes/singletons/organization_singleton.dart:159-170](../../lib/changes/singletons/organization_singleton.dart#L159-L170)

`_onSubmittedPaynet(payment)` — tashkilot ro'yxatdan o'tganda backend'dan kelgan Payment ma'lumotlarini saqlaydi:
- Hive: `EPayModel(type: EPayEnum.paynet, serviceId, merchantUserId, secretKey, merchantId)`
- Pref: `paynetId`, `paynetEnable`

### 9. Payment klaviatura
[lib/features/payment/right/keyboard_of_payment_page.dart:206, 293-310](../../lib/features/payment/right/keyboard_of_payment_page.dart#L206)

- Tugma rasmi: `assets/images/paynet-logo.png`
- Paynet ID Pref'dan o'qiladi, mos kelgan to'lov turi uchun `typePaynet()` chaqiriladi

## Keyingi qadamlar (prod URL yoqilgandan keyin)

- [ ] **Prod URL'ga o'tish**
  → [paynet_service.dart:44](../../lib/changes/services/payment/paynet_service.dart#L44) — `_baseUrl = _baseUrlTest` ni `_baseUrl = _baseUrlProd` ga o'zgartirish
  → Yoki yaxshiroq: build mode bo'yicha avtomatik tanlash (`kReleaseMode ? _baseUrlProd : _baseUrlTest`)
- [ ] **Real merchant credentials bilan test**
  - Test merchant uchun ishlayotgan secretKey/merchantUserId prod'da boshqa bo'ladi
  - Tashkilot konfiguratsiyasi backend tomondan kelishi kerak
- [ ] **Asosiy oqimlarni qo'lda test qilish:**
  - [ ] Oddiy to'lov (status 0 → 1 → 2 polling oqimi)
  - [ ] Confirm mode bilan to'lov (PUT confirmation → payment → confirm)
  - [ ] Internet uzilishi va qayta urinish (NoInternetState)
  - [ ] Timeout holati (30+ soniya javob yo'q)
  - [ ] Fiskal chekni Paynet'ga yuborish (OFD qrcode submit)
  - [ ] `-29 TRANSACTION_ID_ALREADY_EXISTS` xatosi (`receiptNumber` qayta jo'natilganda — hozir kommentlangan, [qator 63](../../lib/changes/services/payment/paynet_service.dart#L63))
- [ ] **Done'ga o'tkazish** (test muvaffaqiyatli bo'lgach)

## Qabul qilingan qarorlar

- **Click/Uzum/Payme'ga mos pattern tanlandi.** PaynetService static class sifatida yozildi (boshqa to'lov servislari ham shunday), shunda mavjud `local_selling_service.dart` ichidagi `if (body['params']['receivedX'])` shabloniga aniq mos keladi.
- **Polling interval 2s, max 15 urinish (= 30s timeout).** Sabab: Paynet javob vaqti odatda 5-15 sekund, 30 sekund yetarli, lekin kassir uzoq kutmasligi kerak.
- **`confirm_mode` birinchi javobda saqlanadi.** Keyingi status so'rovlarida bu maydon kelmaydi, shuning uchun `PaynetBloc._pay()` ([qator 62](../../lib/features/payment/right/dilogs/paynet/bloc/paynet_bloc.dart#L62)) da darhol lokal o'zgaruvchiga olinadi.
- **`transaction_id` (receiptNumber) hozircha yuborilmaydi** — [qator 63](../../lib/changes/services/payment/paynet_service.dart#L63) kommentlangan. Sabab: takroriy chek raqami `-29` xatosini chiqaradi, hozir test merchant uchun bu bezovta qiladi. Prod'da yoqish kerak (idempotency uchun foydali).
- **Pref + Hive (EPayHelper) ikkala joyda saqlanadi.** Sabab: `paynetId` payment type ID (Pref'da, oddiy), `serviceId/secretKey/merchantUserId` esa Hive EPayHelper'da (boshqa to'lov servislari ham shunday).
- **`paymentId` static field sifatida saqlanadi** (`PaynetService.paymentId`). Sabab: BLoC va LocalSellingService ikkalasi ham unga murojaat qilishi kerak. `initPaymentPageValues` va `sendFiscalReceipt` chaqiriqlaridan keyin tozalanadi.

## Ochiq savollar

- **Refund/Reversal oqimi:** `reversalPayment()` metodi yozilgan, lekin `checks/return_page/` ichida hozircha ishlatilmagan. Paynet to'lovi qaytarilganda qanday qilamiz?
  - Variant A: fiskal qaytarish (refund) chaqirilgach, avtomatik Paynet'ga reversal yuborish
  - Variant B: kassir qo'lda tasdiqlashi (xavfsizroq)
  - Qaror keyinroq, real foydalanish boshlanganda
- **Prod credentials qachon beriladi?** — Paynet tomondan kutilmoqda. Qachon kelsa, [organization_singleton.dart:159](../../lib/changes/singletons/organization_singleton.dart#L159) avtomatik to'g'ri qiymatlarni o'qiydi (kod o'zgarmasligi kerak).
- **Print log'lari (`print` chaqiriqlari):** [paynet_service.dart:336-349](../../lib/changes/services/payment/paynet_service.dart#L336-L349) va boshqa joylarda debug `print` lar bor. Prod'ga chiqarishdan oldin tozalash yoki `kDebugMode` ichiga o'rash kerak.
- **`enableConfirmMode`/`disableConfirmMode`** Settings UI'da mavjudmi? Kassir bu rejimni qaerdan yoqadi? — tekshirish kerak.

## Test / Verifikatsiya

**Bajarilgan (test URL bilan):**
- [x] To'lov yaratish oqimi ishlaydi (test merchant credentials bilan)
- [x] Status polling ishlaydi
- [x] Confirm rejimi tekshirilgan
- [x] AUTH header format to'g'ri (sha1 hash)
- [x] Fiskal chek QR'ni Paynet'ga jo'natish ishlaydi

**Prod yoqilgach kerak:**
- [ ] Yuqoridagi "Keyingi qadamlar" bo'limi
- [ ] Haqiqiy karta bilan kichik summada to'lov (1000-5000 so'm)
- [ ] Bekor qilish (reversal) tekshiruvi
- [ ] Internet uzilishi simulyatsiyasi
- [ ] Bir vaqtning o'zida bir nechta sotuv (`_paynetPayIsWorking` flag tekshiruvi)

## Diqqatga loyiq joylar

- **`_baseUrl` const** ([qator 44](../../lib/changes/services/payment/paynet_service.dart#L44)) — `final` yoki getter ga aylantirilsa, runtime'da rejim almashtirish oson bo'lardi (test/prod toggle Settings'da).
- **`print` log'lari ko'p** — prod'ga chiqarmaslik uchun cleanup yoki `kDebugMode` shart.
- **Xato kod jadvali fayl ichida** — agar boshqa joylarda ham ishlatilsa, alohida konstantalar fayliga ko'chirish mumkin (hozir kommentlangan, kelajak uchun).
- **`_baseUrlProd = 'https://api.paynet.uz'`** ekanligini Paynet hujjatidan ikkilantirib tasdiqlang — ba'zan provayder prod URL'ini `pass.paynet.uz` yoki shunga o'xshash variantda beradi.
