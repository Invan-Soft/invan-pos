# Task: Kaftpay — kaft (palm) bilan to'lov, yangi to'lov turi

**Boshlangan:** 2026-10-29
**Holat:** in-progress (2-bosqich kodi tayyor — Windows'da qurilma bilan sinov kutilmoqda)
**Branch:** feature/kaftpay (worktree `../pos-invan-2-kaftpay`, `ayyubxon` 1570ae1 dan)

## Maqsad
Kaftpay (PP palm-payment) — mijoz kaftini VP930 skanerga qo'yadi, kassa uni aniqlaydi
(`/identify`) va kartasidan yechadi (`/pay`). 1-bosqich: swagger bo'yicha API qatlami
(imzo, kaft vektorini shifrlash, barcha endpointlar, xato kodlari, to'lov/vozvrat oqimining
pul xavfsizligi) — kassaga ulanmagan, faqat testlar bilan. UI, skaner (FFI), fiskal va
backend sozlamalari keyingi bosqichlarda.

## Manbalar
- Swagger: https://pos-api.kaftpay.uz/pp-pos-api/swagger-ui/index.html
  (spec: `/pp-pos-api/v3/api-docs`, OpenAPI `info.description` da to'liq qo'llanma)
- Skaner SDK + hujjatlar: https://gitlab.com/Akhadjon-Bokijanov/pp-integration-resources
  (`docs/pos-payment.md`, `pos-onboarding.md`, `palm-vector-encryption.md`,
  `pos-scanner-sdk-integration.md`, `windows/prebuilt/palm_wrapper.dll`)
- Swagger'dagi `/docs/api/pos-scanner-sdk-integration.md` havolasi 404/9999 qaytaradi —
  GitLab'dagisi ishlaydi.

## API qisqacha (2026-10-29 holati)
Base: `https://pos-api.kaftpay.uz/pp-pos-api`. Token yo'q — har so'rov imzolanadi:
`X-Client-Id`, `X-Timestamp` (unix soniya, ±300 s), `X-Nonce` (UUID, bir martalik),
`X-Signature` = `base64(HMAC-SHA256(secret, "METHOD\nPATH\nbase64(sha256(body))\nTS\nNONCE"))`.
PATH context'siz (`/api/v1/pay`). Summalar **tiyinda**.

| Endpoint | Vazifa |
|---|---|
| `GET /api/v1/ping` | imzo/kalitni tekshirish; `ofdEnabled`, `isTest`, `committentTin` |
| `POST /api/v1/identify` | kaft vektori → `requestId` (~120 s) + nomzodlar; `confident`/`ambiguous`/`no_match` |
| `POST /api/v1/pay` (+`Idempotency-Key`) | yechish; `ofdStatus` `PENDING`/`AWAITING_EXTERNAL`/`TEST` |
| `GET /api/v1/pay/status/{key}` | javob yo'qolganda: 200 = pul ketdi, `1210` = ketmadi |
| `POST /api/v1/pay/{tx}/refund` | to'liq vozvrat; `1223` = noma'lum, QAYTA YUBORILMAYDI |
| `POST /api/v1/pay/{tx}/ofd-receipt` | o'zimiz fiskallagan chek URL'ini bildirish (`ofdEnabled=false`) |
| `POST /api/v1/enroll` | mijoz QR (`PPENROLL:`) + kaft → ro'yxatdan o'tkazish |
| `POST /api/v1/ofd/receipts/send` | palm oqimidan tashqari fiskal — bizga kerak emas |

`palmDataEnc` = base64(IV‖ciphertext‖tag), AES-256-GCM, kalit = HKDF-SHA256(ikm=secret,
salt=`TS\nNONCE`, info=`pp-palm-vector:v1`). TS/NONCE — aynan o'sha so'rov header'lari.

## Jonli serverda kuzatilgan (2026-10-29, soxta client_id bilan)
- 401 javob `Content-Type: application/json;charset=ISO-8859-1` — tanani har doim UTF-8
  sifatida o'qish kerak (`response.body` emas, `bodyBytes`).
- 401 `reason` lokalizatsiya qilinmaydi: `"unknown or inactive terminal"`,
  `"timestamp out of range"` (soat tekshiruvi terminal qidiruvidan oldin).
- Imzo header'lari umuman bo'lmasa — Spring'ning envelope'siz 403
  `{"timestamp":..,"status":403,"error":"Forbidden","path":..}`.
- Har javobda HTTP `Date` header bor — kassa soati noto'g'ri bo'lsa shundan tuzatiladi.

## Scope
- 1-bosqich (shu sessiya): `lib/changes/services/payment/kaftpay/` — imzo, shifrlash,
  modellar, xatolar, API klient, to'lov/vozvrat oqimi; `test/kaftpay_*_test.dart`.
- Scope'dan tashqari (keyin): to'lov ekrani tugmasi/dialoglari, skaner FFI
  (`palm_wrapper.dll`), fiskal (`ReceivedCard`?), serverga to'lov turi id'si, X/Z,
  vozvrat ekrani, credentials manbai (backend/admin), enroll UI.

## Bajarilgan
- [x] Imzo (HMAC-SHA256 canonical) va `palmDataEnc` shifri
  → lib/changes/services/payment/kaftpay/kaftpay_crypto.dart
  → Sabab: hujjatdagi known-answer vektori (kalit + blob) bayt-ma-bayt mos; imzo Python bilan mustaqil tekshirilgan.
- [x] Xato modeli: `KaftpayResult` (ok/fail), `KaftpayErrorKind` (auth/business/validation/server/network/badResponse/local), swagger'dagi 46 kodning o'zbekcha izohi
  → lib/changes/services/payment/kaftpay/kaftpay_error.dart
  → Sabab: `success` HTTP status'dan ustun (9999 HTTP 200 bilan keladi); kod bo'yicha tarmoqlanish, matn bo'yicha emas.
- [x] Modellar: skan (516 float tekshiruvi, nol RGB → null, SDK palm_type → hand), ping, identify (`suggested` faqat confident'da), pay so'rovi (mahalliy 1204/1211 tekshiruvi), status, refund, ofd-receipt (`matchesUrl`), enroll; tiyin va GMT+5 vaqt
  → lib/changes/services/payment/kaftpay/kaftpay_models.dart
- [x] API klient: 7 endpoint (`ofd/receipts/send` yo'q — bizga kerak emas), UTF-8 majburiy o'qish, `Date` header'dan soat tuzatish + 1100 da bir marta qayta yuborish (palmDataEnc qayta shifrlanadi), Alice/log'da vektor qisqartiriladi
  → lib/changes/services/payment/kaftpay/kaftpay_api.dart
  → Sabab: jonli serverda 401 `charset=ISO-8859-1`; kassa soati noto'g'ri bo'lsa hamma so'rov 1100.
- [x] To'lov/vozvrat oqimi: aniq rad → notCharged; boshqa hamma narsa (timeout, 1215, 9999, 5xx, 1207, 1209, noma'lum kod) → status (3 urinish, 2 s); status topgan to'lov requestId/summa bilan solishtiriladi; `/pay` hech qachon qayta yuborilmaydi. Vozvrat: 1223 → to'xtash; tarmoq xatosida asl kalit statusidan REFUNDED.
  → lib/changes/services/payment/kaftpay/kaftpay_payment_flow.dart
- [x] Testlar: crypto 15, api 51, flow 50 (+ jonli 6, odatda skip); soxta server imzoni o'zi tekshiradi. Mutatsiya tekshiruvi: 8 ta ataylab xato — hammasi tutildi. To'liq to'plam: 2347 o'tdi, 19 skip.
  → test/kaftpay_crypto_test.dart, test/kaftpay_api_test.dart, test/kaftpay_payment_flow_test.dart, test/kaftpay_live_test.dart, test/support/kaftpay_fake_server.dart
- [x] Jonli server (soxta client_id): 401/1100 tahlili, soat 10 daqiqa orqada bo'lsa ham tuzatilib o'tadi, identify/status 401.
- [x] `cryptography: ^2.9.0` to'g'ridan dependency (lock'da faqat `transitive` → `direct main`).
- [x] port-changelog'ga 20-task WIP bo'limi.
- [x] Kaftpay namunaviy kassasi (`~/Desktop/kaftpay`, Python `pp-pos-app` + `docs-ref/`) bilan solishtirildi
  (2026-10-30), 4 kamchilik tuzatildi:
  1) `/pay` 200 javobi `status` ga qaramay `charged` deyilardi → SUCCESS = charged, FAILED = notCharged,
     PENDING / yo'q / noma'lum = status orqali (`/pay` qayta yuborilmaydi); statusdagi FAILED ham notCharged
     → lib/changes/services/payment/kaftpay/kaftpay_payment_flow.dart (`charge`, `resolve`)
     → Sabab: ekvayer PENDING'ida pul yechilmagan bo'lishi mumkin; namunaviy kassa ham shunday qiladi
  2) identify'ga SDK `palm_type` dan qo'l yuborilardi → yuborilmaydi (`filterByHand`, default false)
     → kaftpay_api.dart (`identify`)
     → Sabab: SDK kodlanishi qarama-qarshi (palm_arithmetic.h:125 va :282), qurilmada tasdiqlanmagan; noto'g'ri
       qo'l → server boshqa qo'lni qidirib haqiqiy mijozni `no_match` qiladi
  3) enroll'da qo'l majburiy (LEFT/RIGHT, kassir tanlaydi); UNSPECIFIED → mahalliy xato
     → kaftpay_api.dart (`enroll`)
     → Sabab: server UNSPECIFIED da adashtiruvchi `1104` beradi, QR sessiyasi PENDING qoladi
  4) nomzod ismi: `name` amalda GUID (matcher'dan) → `displayName` = `firstName`, GUID ko'rsatilmaydi
     → kaftpay_models.dart (`KaftpayCandidate.displayName/label`)
  + RGB yaroqsiz (NaN / uzunlik / hammasi 0) bo'lsa skan rad etilmaydi, RGB tashlab yuboriladi (`hasUsableRgb`)
    — SDK RGB'ni NaN'ga tekshirmaydi, VP930 RGB'ni 0 bilan beradi; asosiysi IR.
  Testlar: 124 o'tdi (+8), mutatsiya (status tarmoqlanishi olib tashlansa) — 4 test yiqiladi.
- [x] 2-bosqich (birinchi to'lovgacha minimal), 2026-10-30 — foydalanuvchi: "birinchi martalik to'lovgacha zarur ishlar":
  - Test terminal kalitlari (`~/Desktop/kaftpay/.env`, TERM-764414) haqiqiy serverda: `/ping` → ACTIVE, `isTest=true`,
    `ofdEnabled=false`; `/pay/status` → 1210; identify sun'iy vektor bilan → `no_match` (palmDataEnc server tomonda
    ochildi). Jonli test: `test/kaftpay_live_test.dart` (+1).
  - Skaner: `dart:ffi` + `palm_wrapper.dll`, isolate, 3 urinish × 12 s, bekor qilish darhol, qurilma band bo'lsa kutish;
    Windows bo'lmasa debug'da sun'iy (Python `_lcg_vec` bilan bir xil)
    → lib/changes/services/payment/kaftpay/kaftpay_scanner.dart
  - Sozlamalar/jurnal: kalitlar adminka (`merchantId`/`secretKey`) → kassa sozlamasi; jurnal (kalit `/pay` dan OLDIN)
    → kaftpay_settings.dart; PrefKeys `kaftpay*`
  - Oyna mantig'i: skan → identify → tasdiq/tanlash (ambiguous'da avtomatik yo'q) → `/pay` → noma'lum bo'lsa
    "Holatni tekshirish"; `requestId` muddati
    → kaftpay_checkout.dart, lib/features/payment/right/dilogs/kaftpay/kaftpay_pay_dialog.dart
  - Ro'yxatdan o'tkazish: QR (barcode skaner) + qo'l (kassir) + kaft → `/enroll`
    → lib/features/payment/right/dilogs/kaftpay/kaftpay_enroll_dialog.dart
  - POS: "Kaftpay" to'lov turi nom bo'yicha (YagonaQr kabi: `Kaftpay.isName`, OrganizationSingleton, WS type 40),
    to'lov tugmasi, `kaftpayAmount`/`recordKaftpay` (YECHILGAN summa yoziladi), chekda `KAFTPAY`, fiskalda karta,
    Kaftpay qatorini o'chirib bo'lmaydi, pul yechilgach to'lov sahifasidan chiqishda tasdiq
    → lib/changes/domain/payment/kaftpay.dart, keyboard_of_payment_page.dart, ordering_provider_4.dart,
      payment_tally_controller.dart, receipt_payments.dart, receipt_vat.dart, left.dart, payment_page.dart,
      check_view_bottom.dart, organization_singleton.dart, products_ws_service.dart
  - Sozlamalar → Kaftpay (PIN): holat, kalitlar, SDK papkasi, aloqa/skaner tekshiruvi, ro'yxatdan o'tkazish, jurnal
    ("Tekshirish" / "Vozvrat") → lib/features/settings/view/payments/kaftpay_content.dart, settings bloc/left_side
  - Testlar: checkout 11, scanner+settings 26, POS integratsiya 8 (fiskal JSON — karta), oynalar 4; to'liq to'plam
    2404 o'tdi, 20 skip; analyze — yangi xato yo'q. Windows'da (FFI, haqiqiy skaner) SINALMAGAN.

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] **Windows'da birinchi to'lov sinovi** (foydalanuvchi, qurilma bilan):
  1. Adminkada (dev) test kassasiga "Kaftpay" nomli to'lov turi, "Apps" da yoqilgan → POS "Ma'lumotlarni yangilash".
  2. VP930 uchun WinUSB drayveri (Kaftpay'dan `WinUsb-InstallDriver.exe` yoki Zadig: "Veinshine 01", VID 3251 PID 3130 → WinUSB).
  3. `~/Desktop/kaftpay/runtime/` dan `palm_wrapper.dll`, `palm_sdk.dll`, `dim_palm.dll`, `TNN.dll` va `config\` →
     `C:\ProgramData\InVanPos2\kaftpay\` (Linux `.so` va `palm_frame.dll` kerak emas). DLL yuklanmasa — VC++ 2015-2022 x64.
  4. POS: Sozlamalar → Kaftpay (PIN) → Client ID / Secret (`~/Desktop/kaftpay/.env`) → Saqlash → "Aloqani tekshirish"
     (TEST terminal) → "Skanerni tekshirish".
  5. "Mijozni ro'yxatdan o'tkazish": telefonda Kaftpay ilovasi + karta → QR barcode skanerda → qo'l → kaft.
  6. Sotuv → To'lov → "Kaftpay" → kaft → mijozni tasdiqlash → "To'lash" → sotuvni yakunlash (fiskal: karta).
  7. Sozlamalar → Kaftpay → jurnalda tx; "Vozvrat" (test terminal pul yechmaydi).
  Tekshirilsin: `palm_type` → qo'l (SDK "Skanerni tekshirish" da ko'rsatadi) — tasdiqlansa identify'da `filterByHand`.
- [ ] Commit + `feature/kaftpay` ni push (Windows kompyuterda olish uchun) — foydalanuvchi ruxsati bilan.
- [ ] 2-bosqich qoldig'i (do'konga chiqishdan oldin):
  - fiskal chek URL'ini Kaftpay'ga yuborish (`attachOfdReceipt`) — real terminal `AWAITING_EXTERNAL` (test'da `TEST`);
  - `transactionId` ni chekka bog'lash (hozir faqat jurnalda) → cheklar sahifasidan vozvrat;
  - X/Z hisobotda alohida "Kaftpay" qatori (hozir "Plastik" ichida, nomi `kaftpay` → default);
  - kalitlarni adminkadan (`merchant_id`/`secret_key`) berish — backend/admin tomoni;
  - ruscha xabarlar (server/xato matnlari hozir o'zbekcha).
- [ ] Skaner protokoli (namunadan, `kaftpay_scanner.dart` shunga yozilgan):
  Namunaviy kassa (`~/Desktop/kaftpay/palm.py`, `app/scanner.py`) dan aniq protokol:
  - `palm_capture(float* ir[516], float* rgb[516], int* palm_type, int timeout_ms)` → 0 ok, 1 timeout (kaft
    topilmadi), 2 to'xtatildi (`palm_stop`), -98 "kaftni tekis tuting"; boshqasi — xato.
  - Har urinishda `palm_open` → capture → `palm_close` (ochiq handle'da qayta capture `StopPalmCapture` bilan
    poyga qiladi va "to'xtatildi" qaytaradi); 3 urinish × 12 s.
  - `palm_get_threshold(&ir,&rgb)` (0.707 / 0.725) — bizga kerak emas (solishtirish serverda).
  - Windows: `AddDllDirectory(runtime)` — palm_sdk.dll, dim_palm.dll, TNN.dll yonida; `config/` (pbtxt +
    `palm_models_1.3.5.bin` 31 MB) ham shu papkada. Jami ~57 MB.
  - Fayllar: `~/Desktop/kaftpay/runtime/` (Windows DLL'lar + Linux .so), SDK header'lar `native/sdk/include/`,
    `palm_sdk.lib`.

## Qabul qilingan qarorlar
- Alohida worktree/branch — asosiy papkada `fix/tolov-summasi-mijoz-almashganda` WIP'i bor.
- `palmDataEnc` (shifrlangan) ishlatiladi, ochiq `ir`/`rgb` emas — hujjat tavsiyasi,
  biometrik ma'lumot log/proxy'da ochiq yotmaydi.
- Shifrlash uchun `cryptography` paketi (lock'da 2.9.0 tranzitiv bor edi) to'g'ridan
  dependency qilindi — yangi yuklab olish yo'q.
- (Foydalanuvchi, 2026-10-30) SDK runtime (~57 MB) repo'ga QO'SHILMAYDI — faqat skanerli kompyuterlarga alohida
  (WinUSB drayveri bilan birga); sinovda qo'lda, keyin Kaftpay yoqilgan kassa serverdan yuklab olishi mumkin.
- (Foydalanuvchi, 2026-10-30) Enroll QR (`PPENROLL:`) do'kondagi oddiy 2D barcode skaner bilan o'qiladi (Click Pass
  kabi); VP930 kamerasi QR uchun ishlatilmaydi. Kaft esa doim VP930 da.
- `/pay` 200 javobida ham `status` qaraladi: faqat SUCCESS = pul ketdi; FAILED = ketmadi; qolgani — status orqali.
- identify'da qo'l yuborilmaydi (SDK kodlanishi tasdiqlanmagan); enroll'da qo'lni kassir tanlaydi.
- `/pay` dan keyin "aniq rad" faqat oq ro'yxatdagi kodlar; noma'lum kod ham status orqali
  tekshiriladi — yangi kod qo'shilsa "pul ketmadi" deb noto'g'ri xulosa chiqmasin.
- Oqim `/pay` ni O'ZI hech qachon qayta yubormaydi; `unknown` → faqat `resolve()` (status).
- `ofd/receipts/send` qilinmadi — swagger: palm to'lovlari uchun kerak emas, ikki marta
  fiskallash xavfi.
- Kod Dart 2.19 tilida (pubspec `sdk: >=2.19.2`) — sealed/record/pattern yo'q.

## Ochiq savollar
- O'sha mijoz o'sha qo'lni qayta ro'yxatdan o'tkazsa server jim almashtiradi (upsert, xato yo'q) — Kaftpay'ga
  savol yuborilgan (`~/Desktop/kaftpay/prompt-pp-pos-api-reenroll.md`), javob kutilmoqda. Kassir "yangi" va
  "almashtirildi" ni ajrata olmaydi. — Kaftpay
- `palm_type` → qo'l mosligi qurilmada tasdiqlanishi kerak (tasdiqlansa identify'da `filterByHand: true`). — do'kon sinovi
- Qayta enroll savoli Kaftpay'ga yuborilganmi — foydalanuvchi "hozircha turib tursin" dedi (2026-10-30).
- Kim fiskallaydi? Kassa o'zi fiskal modul orqali chek chiqaradi → terminal Kaftpay'da
  `ofdEnabled=false` (merchant-fiscalized) qilib onboard qilinishi kerak, aks holda chek
  ikki marta fiskallanadi. — Kaftpay/foydalanuvchi
- `client_id` / `secret` qayerdan keladi: backend (`Payment` ro'yxati, Click/Uzum kabi
  `merchantId`/`secretKey`) yoki kassa sozlamalari? Har kassa = alohida terminal
  (IP whitelist ham har terminalga). — backend/foydalanuvchi
- Test muhiti: alohida URL bormi yoki `isTest=true` terminal shu URL'dami? — Kaftpay
- Skaner: kassa kompyuteri Windows → `palm_wrapper.dll` (+ WinUSB drayver). Qurilma bormi? — foydalanuvchi

## Test / Verifikatsiya
- Shifrlash: hujjatdagi known-answer test vektori (kalit + blob).
- Imzo: Python (hmac/hashlib) bilan mustaqil hisoblangan qiymatlar.
- API: `http/testing.dart` MockClient — har endpoint, xato shakllari, charset, soat tuzatish.
- Jonli: soxta client_id bilan `/ping` → 401/1100 to'g'ri tahlil qilinishi.
