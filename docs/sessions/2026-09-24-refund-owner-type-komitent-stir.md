# Task: Vozvrat fiskal chekida OwnerType va komitent STIR sotuv bilan bir xil ketishi

**Boshlangan:** 2026-09-24
**Holat:** in-progress
**Branch:** ayyubxon

## Maqsad
Foydalanuvchi soliq sahifasida vozvrat chekida (23.09.2026 16:46, chek 38391, "TIIN OPTOM")
"Komitent STIR/JSHSHIR: 0" ko'rdi. Vozvrat qatori serverdan keladi va `ChecksSingleton`
unga `ownerType: 0`, `tin: ""` qattiq yozardi; sotuvda esa `OwnerType` katalogdagi
mahsulotdan (`1`) olinadi. Vozvrat sotuv bilan bir xil manbadan olsin.

## Avvalgi implementatsiya
docs/sessions/2026-09-22-refund-fiscal-url-to-server.md (vozvrat tartibi, hali arxivlanmagan)
↑ U yerda vozvrat oqimi tartibi tuzatilgan. Bu task fiskal body'dagi qator maydonlari haqida.

## Scope
- `lib/changes/domain/receipt/refund_item_origin.dart` — yangi, sof helper
- `lib/features/get_products/singletons/checks_singleton.dart` — `_globalToLocalSoldItem`
- Scope dan tashqari: sotuv yo'lida komitent STIR'ning fiskalga ketmasligi (pastda "Ochiq savollar")

## Tahlil (2026-09-24)
- "Komitent STIR/JSHSHIR" = fiskal item `CommissionInfo.TIN/PINFL` — komissiya savdosida tovar
  egasining STIR (9 xona) yoki JSHSHIR (14 xona). O'z tovari uchun bo'sh.
  Spec: docs/fiscal-sale-integration.md:219-220 (`OwnerType` oddiy tovar `1`; CommissionInfo bo'lmasa `""`).
- Sotuv: `SoldItemBuilder.build` → `ownerType = product.ownerType (default 1)`, `tin = product.commissionTin`.
  `saleOnOFD` → `SalingItemModel(ownerType: e.ownerType, tin: e.commissionTIN, commissionInfo: {TIN: e.commissionTIN ?? ""})`.
  `SalingItemModel.toJson` kaliti `ownerType` → `FiscalItems.fromJson` `ownerType` — mos. Sotuvda `OwnerType: 1`.
- Vozvrat: `ChecksSingleton._globalToLocalSoldItem` (server `api/v1/order` itemlaridan) → `ownerType: 0`,
  `tin: ""` qattiq. Server itemida `owner_type`/`commission_tin` YO'Q (DEV javob kalitlari tekshirildi).
  → Vozvrat soliqqa `OwnerType: 0` bilan ketardi. Sotuv bilan farq aynan shu.
- `CommissionInfo.TIN` ikkala yo'lda ham `""` (pastga qarang) — "0" soliq sahifasining bo'sh qiymatni
  ko'rsatishi yoki OwnerType 0 ta'siri; sotuv chekining soliq sahifasi bilan solishtirish kerak.

## Bajarilgan
- [x] `RefundItemOrigin` — vozvrat qatori uchun OwnerType va STIR'ni katalogdan, sotuv qoidasi bilan
    → lib/changes/domain/receipt/refund_item_origin.dart
    → Sabab: bitta manba (`SoldItemBuilder` bilan bir xil); katalogda yo'q bo'lsa spec default `1`, `""`;
      qidiruv exception tashlamaydi (`id == null` mahsulot)
- [x] `ChecksSingleton._globalToLocalSoldItem` → `ownerType: origin.ownerType`, `tin: origin.tin`
    → checks_singleton.dart

## Keyingi qadamlar (prioritet bo'yicha)
- [x] Testlar: test/refund_item_origin_test.dart — 12 ta (sof qoida, SoldItemBuilder bilan tenglik,
      globalToLocall katalogdan, modul JSON'ida OwnerType 1 / komissiya 2)
- [ ] Foydalanuvchi: o'sha sotuv chekining soliq sahifasida "Komitent STIR" nima ko'rinadi? (0 bo'lsa —
      bu bo'sh qiymatning ko'rinishi, sotuv/vozvrat endi bir xil; boshqa qiymat bo'lsa — adminkada
      commission_tin bor, "Ochiq savollar" 1-band)
- [ ] Reliz

## Qabul qilingan qarorlar
- Vozvrat qatori OwnerType/STIR ni serverdan emas, katalogdan oladi. Sabab: server itemida bu
  maydonlar yo'q; sotuv ham katalogdan oladi — bir xil manba, bir xil natija.

## Ochiq savollar
- **Sotuvda adminkadagi komitent STIR fiskalga KETMAYDI**: `SoldItemBuilder` uni `tin` ga yozadi,
  `saleOnOFD` esa `e.commissionTIN` (hech qayerda to'ldirilmaydi, `null`) ni o'qiydi →
  `CommissionInfo.TIN` doim `""`. Komissiya tovari (adminkada owner_type=2 + STIR) bo'lsa soliqqa
  STIR'siz ketadi. Tuzatish `saleOnOFD` da `e.commissionTIN ?? e.tin` — lekin bu SOTUV xulqini
  o'zgartiradi (adminkada STIR to'ldirilgan har bir mahsulot uchun), do'kon sinovisiz qilinmadi.
  — foydalanuvchi qaror qilsin

## Test / Verifikatsiya
- [x] flutter analyze (faqat eski info: checks_singleton.dart:74 `dateTimeOFD == 0`), flutter test to'liq — 2026-09-24
- [ ] Do'konda: vozvrat → soliq sahifasida OwnerType/Komitent sotuv bilan bir xil
