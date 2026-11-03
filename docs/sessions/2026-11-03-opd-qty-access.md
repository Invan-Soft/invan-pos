# Task: OPD dialogida qty kamaytirish va narx tahriri ruxsatsiz o'tardi

**Boshlangan:** 2026-11-03
**Holat:** in-progress (`ayyubxon` da, relizda emas, Shorebird'ga chiqarilmagan; Windows/do'kon sinovi kutilmoqda)
**Branch:** fix/opd-qty-access

## Maqsad
`deletePrice` ruxsati yo'q kassir savatdagi mahsulotni PIN siz kamaytira olardi:
qatorni bosib kichik son yozib tez Saqlash bossa qty o'zgarardi, PIN oynasi
chiqishga ulgurmasdi, to'lov sahifasida esa eski summa turardi. Shu xato va
shunga o'xshash yo'llarni yopish.

## Sabab
`OperationOnProductProvider.onCountChanged` qty ni darhol o'zgartirib, tekshiruvni
400 ms kechikkan taymerga qoldirardi, `onSaveButtonPressed` esa hech narsa
tekshirmasdi va taymerni to'xtatmasdi. Tuzatilmagan kodda o'lchangan natija
(10 × 10 000, "3" + Saqlash):

| Vaqt | Savat qty | `getTotalPrice` | Holat |
|---|---|---|---|
| Saqlashdan keyin | 3 | 30 000 | `deleted_items`: 7 ta, kassir nomidan, PIN siz |
| +400 ms | **10** | **100 000** | taymer qatorni qaytardi (saqlangach `target` savat qatorining o'zi), ro'yxat yangilanmagan |

Ya'ni ro'yxatda 3 ta, to'lov sahifasida (`left.dart` → `getTotalPrice`) 10 talik
summa, yopilgan oyna ortidan PIN oynasi yoki `focusNode.context!` da xato.

## Shu tekshiruvda tasdiqlangan boshqa yo'llar (eski kodda)
- Backspace → 0 → Saqlash: qator PIN siz o'chadi; taymer umuman ishga tushmaydi
- Backspace, Backspace, raqam: kutsa ham PIN yo'q (snapshot 0 ga tushib qolardi)
- "0" + tez Saqlash: qator PIN siz o'chadi
- Klaviatura `-` (`decreaseQuantity`): PIN siz
- Quti maydonidagi `-` (`opd_box`): PIN siz
- Blok va marka guruhi: Backspace → 0 → Saqlash butun guruhni PIN siz o'chiradi
- Narx/asl narx/chegirma maydonida Backspace: `editPrice` tekshirilmaydi. Qo'lda
  narxi bor qatorda (`isPriceOnlyChanged`) narx 0 gacha tushib qolardi
- Raqam + O'chirish: PIN oynasi ustidan taymer ikkinchi PIN oynasini ochardi
- Oynani yopgach taymer PIN oynasini asosiy sahifa ustida ochardi

## Bajarilgan
- [x] Ruxsat Saqlash paytida tekshiriladi, barcha yo'llar shu yerdan o'tadi
  → lib/changes/providers/operation_on_product_provider.dart (`onSaveButtonPressed`, `_askDecreaseApproval`)
  → Sabab: yagona majburiy nuqta; taymer endi faqat qulaylik (terib to'xtaganda PIN)
- [x] `_approvedQty`: PIN siz tushib bo'lmaydigan qty (ochilgandagi yoki oxirgi ruxsat etilgan)
  → Sabab: "10 → 15 → 12" da hech narsa savatdan chiqmaydi, PIN kerak emas; "ruxsat 7 → 3" da yana kerak
- [x] `_finished` + `dispose`: saqlangach yoki yopilgach provider qatorga tegmaydi, taymerlar to'xtaydi
  → Sabab: xatoning ikkinchi yarmi — savat qatorini jim o'zgartirish
- [x] Klaviatura `-` va quti `-` → `attemptDecreaseQuantity`; O'chirish va `-` kutilayotgan taymerni bekor qiladi
  → opd_center.dart, opd_box.dart, opd_bottom.dart, opd_value.dart
- [x] Backspace narx maydonlarida `editPrice` talab qiladi (raqam tugmalaridagi kabi)
- [x] Kg og'irlik oynasi: `qtyBeforeAdd` = qo'shishdan oldingi qty
  → ordering_provider_4.dart (`addProduct`), operation_on_product.dart, operation_on_product_dialog.dart
  → Sabab: kg mahsulot `value: 1` bilan qo'shilib oyna o'zi ochiladi; 0.35 kiritish kamaytirish emas. Yangi tekshiruv buni har sotuvda PIN ga aylantirib qo'yardi.
- [x] Statik `4615@` va skaner yo'lidagi `'4615'` olib tashlandi, chaqirilmaydigan `onUniversalPinEntered` ham (fd369e9)
  → lib/features/home/features/operation_on_product/delete_item/input_alert_dialog.dart
  → Sabab: foydalanuvchi qarori; kod joriy kassir nomidan barcha PIN oynalarini (accessCheck ham) o'tkazardi
- [x] Og'irlik kiritish `deleted_items` ga soxta yozilmaydi (fd369e9)
  → ordering_provider_4.dart (`pressDialogSaveButton`, `qtyBeforeAdd`)
  → Sabab: foydalanuvchi qarori; 1 kg → 0.35 da 0.65 "o'chirilgan" ko'rinardi
- [x] Testlar: test/opd_qty_access_test.dart (69 ta, haqiqiy dialog ustida)

## Keyingi qadamlar (prioritet bo'yicha)
- [ ] Windows'da qo'lda sinov (§ Test / Verifikatsiya)
- [ ] Keyingi Shorebird patch/relizga kiritish — foydalanuvchi qarori (hozircha chiqarilmaydi)

## Qabul qilingan qarorlar
- PIN rad etilsa oyna ochiq qoladi, qty oxirgi ruxsat etilganga qaytadi — saqlash bekor.
- Terib to'xtagandagi PIN saqlandi (mavjud UX), lekin Backspace uchun qo'shilmadi: "12 → 1 → 15" tuzatishda keraksiz oyna chiqmasin; Saqlashda baribir tekshiriladi.
- Yangi kg qatorni og'irlik oynasida 0 qilish PIN siz: savatda oldin bo'lmagan tovar.
- "Rad etilganda" qty `_approvedQty` ga qaytadi (oldin terish boshidagi songa): "10 → +5 → 15 → 3 → rad" endi 10 ga qaytadi.

## Ochiq savollar
- Og'irlik oynasida qatorni butunlay o'chirish (0 yoki O'chirish) qo'shilgan miqdor bilan yoziladi: yangi qatorda 1 kg, savatda 2 kg bo'lsa 3 kg. Tovar haqiqatan qo'shilib o'chirilgan, nazorat uchun qoldirildi.
- `_updateExistingProduct` qatorni olib, `_checkAndShowDialogsIfNeeded` true qaytarsa qaytarib qo'ymaydi (narx 0 ga aylangan mahsulot qayta skanerlansa qator yo'qoladi). Kassir qo'lidagi yo'l emas, tegilmadi.

## Test / Verifikatsiya
- `flutter test test/opd_qty_access_test.dart` — 69 o'tdi
- Sezgirlik: 1-commit olib tashlanganda o'sha paytdagi 48 testdan 29 tasi, 2-commit olib tashlanganda 8 tasi yiqildi
- `flutter test` to'liq — 2575 o'tdi, 11 skip, 0 yiqildi; `flutter analyze` — xato yo'q
- Haqiqiy ilovada (Windows) sinalmagan. Qo'lda: ruxsatsiz kassir bilan (1) Pepsi 10 → 3 → darhol Saqlash: PIN, rad etilsa 10; (2) PIN bilan: ro'yxat va to'lov sahifasi 3 talik; (3) Backspace → Saqlash: PIN; (4) kg mahsulot qo'shib 0.35: PIN yo'q, hisobotda o'chirilgan yozuv yo'q; (5) ruxsatli kassir: PIN siz, 3 da qoladi; (6) `4615@` hech qaysi PIN oynasidan o'tmaydi.
