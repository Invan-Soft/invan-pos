# Task: Skaner home ekranda ishlamasligini tuzatish (macOS)

**Boshlangan:** 2026-05-22
**Holat:** done
**Yakunlangan:** 2026-05-22
**Branch:** fix/macos-binding-init

## Maqsad
Home ekranda skaner orqali mahsulot skanerlash vaqtincha-vaqtincha ishlamay qolishi muammosini hal qilish. macOS'da bu muammo deyarli har safar takrorlanardi.

## Scope
- `lib/features/lock/lock/view/lock_buttons_with_shortcuts.dart` — Lock screen VisibilityDetector
- Scope dan tashqari: `MyBarcodeListener` ichidagi `RawKeyboard` deprecated muammosi (alohida task — `HardwareKeyboard` ga migratsiya), 2 ta listener bir vaqtda yashashi (functional muammo emas)

## Muammoning kelib chiqishi

Diagnostika print'lar bilan timeline o'rnatildi:
```
1. Lock screen → BLStatus.magneticStripe (build)
2. Lock screen → isVisible false → true   (lock visible)
3. Lock screen → BLStatus.home (goHomepage)
4. Home page initState → BLStatus.home (Home)
5. Home page initState → isVisible true → true
6. Home page VisibilityDetector → isVisible true → true
7. ❗ isVisible true → false   ← Lock screen ekrandan ketganda
```

7-qadam — Lock screen'ning `VisibilityDetector` ekrandan g'oyib bo'lganda
`v.visibleFraction == 0` qaytarib, `BlVisibilityChangedEvent(false)` yuborib
qo'yardi. Bu Home page'ning oldindan o'rnatgan `isVisible=true` ni bekor qilardi.

Natija: kassir home ekranda turibdi, skanerladi, lekin `isVisible=false`
bo'lgani uchun `MyBarcodeListener.onKeyEvent` da `return` qilinardi → key event'lar
butunlay tashlanardi.

## Bajarilgan
- [x] Diagnostika print'lar qo'shildi (BlBloc, MyBarcodeListener, addProduct, organization_singleton)
  → Sabab: visibility/status o'zgarishi kim qachon yuborayotganini aniqlash
- [x] Real qurilmada test bilan timeline aniqlandi
  → Muammo: Lock screen unmount paytida `false` yubordi, Home page'ning `true`ni bekor qildi
- [x] Lock screen VisibilityDetector tuzatildi
  → lib/features/lock/lock/view/lock_buttons_with_shortcuts.dart:141-145
  → Endi faqat ekranga kelganda (`v.visibleFraction > 0`) `true` yuboriladi; g'oyib bo'lganda hech narsa qilmaydi (keyingi ekran o'z visibility'sini claim qiladi)
- [x] Mac'da real test — skan ishladi, mahsulot savatga qo'shildi
- [x] Diagnostika print'lari olib tashlandi

## Qabul qilingan qarorlar
- **Lock screen `false` yubormasligi** — Sabab: bir nechta widget bir vaqtda visibility'ni boshqarayotganida, ekranni tark etayotgan widget keyingisini bekor qilishi mumkin. Yechim: tark etayotgan widget visibility'ga tegmasin, keyingi widget o'zini claim qilsin.
- **Home page'da `visibilityDetector` unconditional `true` yuboradi** — buni o'zgartirmadik, chunki bu safe direction (visibility'ni doim true qilib qo'yadi) va boshqa joylarni buzishi mumkin.

## Ochiq savollar (kelajak uchun, hozir blocker emas)
- **`RawKeyboard` deprecated** — Flutter 3.18 dan keyin `HardwareKeyboard` ga migratsiya tavsiya etilgan. macOS'da NumLock exception (`'event is! RawKeyDownEvent || _keysPressed.isNotEmpty'`) shundan kelib chiqadi. Migration alohida task.
- **2 ta `MyBarcodeListener`** bir vaqtda yashayapti (home_page + SearchButtons). Har biri `RawKeyboard.instance.addListener` qiladi, har key event 2 marta tutiladi. Hozir muammo bermaydi (SearchButtons'da `onBarcodeScanned` bo'sh callback), lekin xotirada keraksiz takrorlash.
- **300ms debounce** — agar 2 ta skan 300ms ichida ketma-ket kelsa, ikkinchisi tashlanadi. Tez skanerlash uchun bu muammo bo'lishi mumkin.
- **`isVisible` arxitekturasi** — bir nechta widget bitta global flag ustida raqobat qilyapti. Kelajakda har bir listener'ga o'z visibility'sini berish (ya'ni global emas, lokal) yaxshiroq bo'lar edi.

## Test / Verifikatsiya
- [x] Mac'da skan paytida `[BarcodeListener] CALLBACK home: "..."` chiqdi
- [x] `[addProduct] name="Вода Hydrolife Eco..."` chiqdi
- [x] Mahsulot UI'da savatga qo'shildi
- [x] Bir nechta ketma-ket skan qilinganda ham ishladi
- [x] Kod tuzatildi va print'lar olib tashlandi
