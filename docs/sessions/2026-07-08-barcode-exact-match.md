# Task: Barcode orqali mahsulot topishni 100% aniq moslikka o'tkazish

**Boshlangan:** 2026-07-08
**Holat:** in-progress (kod tayyor, Windows/do'kon testi kutilmoqda)
**Branch:** ayyubxon

## Maqsad
Do'konda Pringles (barcode 5053990107339) skan qilinganda chekka "Shakar 5kg"
(barcode 2100000001842, SKU 206) tushib qolgan. Muammo BIR MARTA chiqqan,
qayta skan qilganda to'g'ri mahsulot topilgan — demak doimiy data-xato emas,
tranzient (poyga/fragment) muammo. Barcode orqali mahsulot qo'shish faqat
100% teng moslikda ishlaydigan qilinadi.

## Muammo tahlili (root cause)

To'g'ridan-to'g'ri skan yo'li (`getProductByBarcode`) allaqachon `==` bilan
ishlaydi — data-xato bo'lsa har skanda takrorlanardi. Tranzient xatoga olib
keladigan 2 ta real mexanizm topildi:

**1. ≤5 belgi = SKU taxmini (eng ehtimolli sabab).**
`ItemsSingleton.getProductByBarcode` ≤5 belgili har qanday kiritishni SKU deb
qidiradi (`int.tryParse` bilan). Pringles bankasida EAN yonida ASL BELGISI
DataMatrix ham bor (`01<GTIN14>21<serial><GS>93<crypto>`). Skaner DataMatrix'ni
o'qiganda: (a) `MyBarcodeListener`ning 300ms bufer tozalash logikasi UI jank
paytida skan o'rtasida buferni tozalab, faqat DUM qismini yuborishi mumkin;
(b) ba'zi skanerlar GS belgisini Enter qilib yuboradi — kod bo'laklarga
bo'linadi. Qisqa raqamli fragment (masalan "0206") SKU 206 ga int-parse
bo'lib "Shakar 5kg"ni indamay savatga qo'shadi (value: 1 — chekdagi 1×64,990
bilan mos). Keyingi skan toza o'tadi — "qayta ursa o'zini topdi".

**2. Qidiruv dialogi Enter poygasi.**
Skaner belgilarni text-input pipeline orqali yozadi, Enter esa
RawKeyboardListener'ga alohida (oldinroq) yetib keladi. Enter bosilganda
`controller.text` hali QISMAN bo'lishi mumkin (masalan "5") va eski kod
`results[0]` yoki eskirgan `state.selected` indeksdagi mahsulotni pop qilardi.
Nom qidiruvida "Shakar 5kg" nomida "5" bor — qisman matnda birinchi natija
bo'lib chiqishi mumkin. `build_typeahead.onSubmitted` ham oxirgi callback'da
keshlangan `oneProduct`ni ishlatardi (stale). Bundan tashqari raw-Enter va
TextField.onSubmitted IKKALASI ham pop qilardi (double-pop xavfi).

Istisno qilingan versiyalar: data-kolliziya (ikkinchi barcode / box_barcode) —
qayta skanda tuzalib qolmasdi; tarozi prefiksi (28, Pringles 50 bilan
boshlanadi); prefix-match (`startsWith`) — Shakar barcode "21" bilan
boshlanadi, Pringles prefikslari unga mos kelmaydi.

## Bajarilgan
- [x] `MyBarcodeListener.isScannerBurst` qo'shildi (6+ tugma <100ms oraliqda)
  → lib/utils/helpers/my_barcode_listener.dart:40
  → Sabab: skaner kiritishini qo'lda terilgan SKU'dan ishonchli ajratish;
    odam 6 tugmani <100ms oraliqda tera olmaydi, skaner fragmenti esa Enter
    yetib kelguncha counter'da ≥6 bo'ladi (bufer tozalansa ham counter qoladi)
- [x] `getProductByBarcode`ga `allowSkuFallback` parametri
  → lib/features/get_products/singletons/items_singleton.dart:241
  → Sabab: false bo'lsa ≤5 belgi SKU deb taxmin qilinmaydi (null qaytadi);
    default true — tarozi PLU (scanWeightItem substring(2,7)) va qo'lda
    terilgan SKU oqimlari buzilmaydi
- [x] `onBarcodeScanned`: funksiya boshida `fromScanner` olinadi, asosiy
  lookup'ga `allowSkuFallback: !fromScanner` beriladi
  → lib/changes/providers/ordering_provider_4.dart:4532 (boshi), :4705 atrofi
  → Sabab: skan fragmenti endi SKU'ga aylanib boshqa mahsulot qo'shmaydi —
    "topilmadi" dialogi chiqadi
- [x] Qidiruv dialogi: yagona `_submit()` (raw Enter + onSubmitted + virtual
  klaviatura SDStatus.pop), `_popped` double-pop guard, skaner/barcode-simon
  (faqat raqam ≥6) kiritishda FAQAT 100% teng barcode; skaner Enter'i erta
  kelsa 300ms kutib qayta tekshirish, baribir topilmasa maydonni tozalash;
  strelka bilan aniq tanlov saqlanadi; barcode rejimida aniq moslik bo'lmasa
  avto-qo'shish yo'q
  → lib/features/home/features/home_products/shift_opened/product_search/dialog/search_dialog_content.dart:67-140
- [x] `build_typeahead.onSubmitted`: stale `oneProduct` keshi o'chirildi,
  natija topshirilgan matndan yangidan hisoblanadi, barcode uchun exact-only
  → lib/features/home/features/home_products/shift_opened/product_search/build_typeahead.dart
- [x] `flutter analyze` — 0 error (qolganlari oldindan mavjud deprecated/info)
- [x] SKU qidiruvi qat'iylashtirildi (foydalanuvchi talabi: "nima o'qitilsa
  o'sha bo'yicha qidirsin, noto'g'ri format → kick"):
  * `getProductByBarcode` SKU branch: faqat `^\d+$` (sof raqam) qabul qiladi,
    `int.tryParse` normalizatsiyasi olib tashlandi — "0206" endi "206"ga
    aylantirib qidirilmaydi, aynan kiritilganidek solishtiriladi
    → lib/features/get_products/singletons/items_singleton.dart:246
  * Tarozi PLU: nol-to'ldirish tarozi FORMATining qoidasi bo'lgani uchun
    scanWeightItem ichida avval aynan "00206", topilmasa "206" ko'rinishida
    qidiriladi (SKU branch'dagi umumiy normalizatsiya o'rniga)
    → lib/changes/providers/ordering_provider_4.dart scanWeightItem
  * `extractBarcode` BUTUNLAY O'CHIRILDI — ixtiyoriy satrdan raqamlar
    ketma-ketligini ajratib olib qidirish endi hech qayerda yo'q. >18 belgili
    kod strukturaviy parserlar (GS1 "01"+GTIN14, tarozi, utsenka QR) ga
    tushmasa — satr o'z holicha exact solishtiriladi, mos kelmasa "topilmadi".
    → lib/changes/providers/ordering_provider_4.dart onBarcodeScanned,
      lib/features/get_products/singletons/items_singleton.dart (funksiya o'chirildi)
    → Eslatma: standart bo'lmagan marking formatlar (01-prefikssiz DataMatrix)
      endi asosiy oqimda topilmaydi — kassir EAN'ni skan qilishi kerak.
      Bu ataylab qilingan (foydalanuvchi talabi: noto'g'ri format → kick).

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows buildda real skaner bilan test:
  1) Pringles EAN skan → Pringles tushishi;
  2) DataMatrix skan → Pringles yoki "topilmadi" (hech qachon boshqa mahsulot emas);
  3) qo'lda SKU terish (masalan 206 + Enter) → Shakar tushishi (regressiya yo'qligi);
     "0206" terish endi ATAYIN topmaydi (aynan kiritilganidek qidiriladi);
     harf aralash qisqa kod ("a12") → topilmaydi (kick);
  4) tarozi barcode (28…) → to'g'ri PLU;
  5) qidiruv dialogi ochiq holda skan → faqat aniq moslik qo'shilishi.
- [ ] Kuzatuv: do'konda yana takrorlansa request_logs'dan skan stringini olish
  (scanBarcode `where:` loglari bor).

## Qabul qilingan qarorlar
- SKU fallback butunlay o'chirilmadi — faqat skaner-burst kiritishda o'chadi.
  Sabab: qo'lda SKU terish va tarozi PLU ishlashda qolishi kerak.
- Qidiruv RO'YXATINI ko'rsatishda prefix/contains saqlanadi (interaktiv UX),
  qat'iylik faqat AVTO-QO'SHISH (Enter/scan) nuqtalariga qo'llandi.
- Skaner kiritishi ≥6 raqam bo'lsa dialog rejimidan qat'i nazar global exact
  barcode lookup ishlatiladi (`allowSkuFallback: false`).

## Ochiq savollar
- Do'kondagi aynan o'sha holatda skaner EAN emas DataMatrix'ni o'qiganmi —
  faqat request_logs / kassir kuzatuvi bilan tasdiqlash mumkin.

## Test / Verifikatsiya
- `flutter analyze` toza (0 error).
- Real skaner testi kutilmoqda (yuqoridagi 5 stsenariy).
