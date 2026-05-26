# Task: Markirovkali mahsulot uchun product_type/product_package nomuvofiqligini tuzatish

**Boshlangan:** 2026-05-21
**Holat:** in-progress
**Branch:** fix/macos-binding-init

## Maqsad
Markirovkali mahsulot sotuvida `marking_names` to'lib, lekin `product_type` va `product_package` bo'sh ketishi muammosini hal qilish. Sababi: MXIK prefix ro'yxati noto'liq (`02009` yo'q) va `isMarking` flagga fallback yo'q.

## Scope
- `lib/changes/providers/ordering_provider_4.dart` — markirovka aniqlash logikasi, `_getProductType`, `_isMxikMarking`, `_createSoldItem`, `addSeperatedProduct`, `_addBoxProduct`, barcode skan flow
- Scope dan tashqari: `ReceiptModelSoldItem4` modeli, fiscal service, server tomondagi mantiq

## Muammoning kelib chiqishi
Real misol (chek ID `019e4392-33fa-7a8b-8eae-1a828ff1b6c6`):
- Tropic Yablоkо-Banan: MXIK `02202...` → `product_type='5'`, `product_package='KIZ'` ✓
- Sharbat Olcha: MXIK `02202...` → `product_type='5'`, `product_package='KIZ'` ✓
- **Bliss Ananas**: MXIK `02009...` → `product_type=''`, `product_package=''` ✗ (`marking_names` to'lgan)
- **Bliss Olma**: MXIK `02009...` → `product_type=''`, `product_package=''` ✗ (`marking_names` to'lgan)

Sabab:
1. `_getProductType()` MXIK prefix `02009` ni tanimaydi → bo'sh qaytaradi
2. Skaner DataMatrix kodini o'qiganda `item.mark = _markirovka(barcode)` shartsiz set qilinadi — MXIK tekshirilmaydi
3. Natija: `mark` to'ladi (→ `marking_names`) lekin `productType` bo'sh qoladi

## Bajarilgan
- [x] Bug analiz qilindi, 100% sabab aniqlandi
  → docs/sessions/2026-05-21-marking-product-type-fix.md (bu fayl)
  → Sabab: 4 ta turli joyda mustaqil MXIK ro'yxatlar — bittasi 02009 ni tanimaydi
- [x] `02009` prefixi `_isMxikMarking` ga qo'shildi
  → lib/changes/providers/ordering_provider_4.dart:4368-4372
  → Sabab: sharbatlar (02009) markirovkali deb tanilishi kerak
- [x] `02009` prefixi `_getProductType` ga qo'shildi (type='5')
  → lib/changes/providers/ordering_provider_4.dart:4418-4420
  → Sabab: sharbatlar ichimlik bilan bir guruh — '5' eng to'g'ri
- [x] `addProduct` ichidagi hardcoded ro'yxat `_isMxikMarking` chaqiruvi bilan almashtirildi
  → lib/changes/providers/ordering_provider_4.dart:379-380
  → Sabab: DRY — bitta markaziy ro'yxat
- [x] Yangi helperlar qo'shildi: `_isProductMarkable`, `_resolveProductType`, `_resolveProductPackage`
  → lib/changes/providers/ordering_provider_4.dart:4384-4408
  → Sabab: fallback mantig'i markazda; "agar MXIK topilmasa-yu mahsulot markirovkali bo'lsa → '5' + 'KIZ'"
- [x] `_isProductMarkable` "Avto markirovkani aniqlash" (PrefKeys.sellProductsWithMarking) sozlamasiga bog'landi
  → lib/changes/providers/ordering_provider_4.dart:4384-4394
  → Qoida: isMarking=true → har doim markirovkali; isMarking=false va sozlama OFF → MXIK tekshirilmaydi; sozlama ON → MXIK orqali aniqlanadi
  → Sabab: foydalanuvchi talabi — "Avto markirovkani aniqlash" o'chirilgan bo'lsa MXIK bo'yicha avto-aniqlash to'liq o'chishi kerak
- [x] `_isProductMarkable` ga master kill switch qo'shildi — `markCheckWithOfd` OFF bo'lsa hammasi `false` qaytaradi
  → lib/changes/providers/ordering_provider_4.dart:4390
  → Avval helper OFD ni tekshirmasdi; natijada OFD OFF bo'lganda ham `item.mark`, `product_type`, `product_package` server'ga ketardi (lekin marking dialog ochilmasdi — nomuvofiq holat)
  → Endi OFD OFF → barcha markirovka-bog'liq maydonlar bo'sh ketadi, mahsulot oddiy mahsulot kabi ishlanadi
- [x] 3 ta yaratish joyida helperlar ishlatildi
  → lib/changes/providers/ordering_provider_4.dart:964-965 (`_createSoldItem`)
  → lib/changes/providers/ordering_provider_4.dart:1987-1988 (`addSeperatedProduct`)
  → lib/changes/providers/ordering_provider_4.dart:2200-2201 (`_addBoxProduct`)
  → Sabab: 3 joyda bir xil mantiq, helper orqali markazlashtirilgan
- [x] Skan paytida `item.mark` filter qilinadi: faqat mahsulot markirovkali bo'lsa yoziladi
  → lib/changes/providers/ordering_provider_4.dart:4248, 4261
  → Sabab: foydalanuvchi talabi — markirovkali bo'lmagan mahsulotga DataMatrix kod skan qilinsa, marking_names ga ketmasin
- [x] `ReceiptModelSoldItem4` ga `mark` yozish nuqtalariga defensiv filter qo'shildi
  → lib/changes/providers/ordering_provider_4.dart:1951 (addSeperatedProduct)
  → lib/changes/providers/ordering_provider_4.dart:2164 (_addBoxProduct)
  → `mark: _isProductMarkable(freshProduct) ? markValue : null` — final yozish nuqtasida ham markability tekshiriladi
  → Sabab: ko'p path orqali mark yozilishi mumkin, markazlashtirilgan defensiv tekshiruv kerak

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Real qurilmada test qilish: sharbat (02009) ni savatga qo'sh, markirovka skanerla, JSON da `product_type='5'`, `product_package='KIZ'`, `marking_names` to'la kelishini tasdiqla
- [ ] Markirovkali bo'lmagan mahsulot uchun DataMatrix kod skan qilinsa `mark` bo'sh qolishi kerakligini tekshir
- [ ] Eski 02202 (suv) va alkogol mahsulotlari hamon to'g'ri ishlashini tasdiqla
- [ ] Test muvaffaqiyatli bo'lsa — task arxivlanadi

## Qabul qilingan qarorlar
- `02009` (sharbat) → product_type `'5'` (suv/ichimlik bilan bir guruh) — Sabab: foydalanuvchi tasdiqlagan, va sharbat mantiqan ichimlik kategoriyasiga yaqin
- Helper alohida metod sifatida — Sabab: 3 ta joyda DRY, fallback mantig'i markazda turishi kerak
- Fallback: agar mahsulot markirovkali bo'lib ham MXIK ro'yxatda yo'q bo'lsa → `'5'` + `'KIZ'` — Sabab: foydalanuvchi tasdiqlagan, server uchun bo'sh ketishidan ko'ra default ketishi xavfsizroq
- Skan paytida filter: faqat haqiqiy markirovkali mahsulot uchun mark saqlash — Sabab: foydalanuvchi tasdiqlagan, noto'g'ri mahsulotga DataMatrix kod o'qilsa baribir saqlanib qolishidan ko'ra rad etgan ma'qul

## Ochiq savollar
- 02009 dan boshqa qaysi MXIK prefixlar ham yetishmasligi mumkin? (kelajakda bug bo'lib qaytishi mumkin) — kelajakdagi sessiyalarda tahlil
- MXIK prefix ro'yxati hardcode emas, balki konfiguratsiyadan kelishi kerakmi? (uzoq muddatli refaktor) — alohida ADR sifatida ko'rib chiqilishi mumkin

## Test / Verifikatsiya
- [ ] Sharbat (MXIK `02009...`) ni savatga qo'sh, markirovka skanerlab sotuvni amalga oshir → JSON da `product_type='5'`, `product_package='KIZ'`, `marking_names` to'la
- [ ] Markirovkali bo'lmagan mahsulot uchun DataMatrix kod skanerlash sinab ko'r → `mark` bo'sh qolishi kerak
- [ ] Eski 02202 mahsulotlar (suv) hamon to'g'ri ishlashi kerak
- [ ] Alkogol (024, 02203-08) mahsulotlar markirovka flow toza ishlashi kerak
