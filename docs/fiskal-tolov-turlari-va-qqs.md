# Fiskal chek: to'lov turlari, maydonlar va QQS

**Sana:** 2026-09-24
**Branch:** ayyubxon (1.1.2+126)
**Maqsad:** har bir to'lov turi soliqqa (fiskal modulga) qaysi maydonda ketadi, QQS qachon
hisoblanadi, QQS foizi qayerdan olinadi, Click/Payme qaysi maydonda ketishi kerak.
Bu tahlil hujjati, kod o'zgartirilmagan.

---

## 1. Qisqa xulosa

| Savol | Javob |
|---|---|
| Cashback bilan to'lansa QQS ketadimi? | Fiskalga **ketmaydi** (VAT=0), chekka/serverga **ketadi**. Ikkisi zid. Fiskal tomoni mantiqan to'g'ri, chek noto'g'ri. |
| QQS foizi qayerdan? | **Adminkadan**, mahsulotning `vat.percentage` maydoni. Mahsulotda `vat` bo'lmasa statik **12**. 6% kodda yo'q. |
| Click/Payme/Uzum qaysi maydonda ketishi kerak? | Rasmiy talab bo'yicha **ReceivedCard** (beznal) + `ExtraInfo.QRPaymentProvider/QRPaymentID`. Bizda **Other** ga ketyapti, bu noto'g'ri, va shu sabab Click chekida ham QQS 0 ketyapti. |
| `Other` nima uchun? | Spetsifikatsiya: "Прочие (оплата по страховке и др.)". Xaridordan naqd/karta sifatida olinmagan, uchinchi tomon yoki do'kon o'zi qoplagan qism. Do'kon bonusi (cashback) shu yerga mos keladi. |

---

## 2. Rasmiy manba nima deydi

### 2.1 Fiscal Drive spetsifikatsiyasi (Soliq fiskal moduli drayveri)

Chek darajasi:

| Maydon | Rasmiy ta'rif |
|---|---|
| `ReceivedCash` | Наличная сумма полученная от продажи в тийин |
| `ReceivedCard` | Безналичная сумма полученная от продажи в тийин |
| `PaymentType` | Форма оплаты: 1 — Наличными, 2 — Безналичными, **3 — По QR-коду**, 4 — Смешанная |
| `ExtraInfo.QRPaymentProvider` | Код провайдера услуг по оплате по QR-коду |
| `ExtraInfo.QRPaymentID` | Идентификатор платежа по QR-коду |
| `ExtraInfo.PPTID` | Идентификатор транзакции платежа процессингового центра |
| `ExtraInfo.CardType` | 1 — корпоративная, 2 — личная, 3 — социальная |

Qator (Item) darajasi:

| Maydon | Rasmiy ta'rif |
|---|---|
| `Price` | Общая сумма позиции **без учета скидок** |
| `Discount` | Скидка |
| `Other` | **Прочие (Оплата по страховки и др.)** |
| `VATPercent` | % НДС |
| `VAT` | НДС сумма |

Majburiy balans:

```
ReceivedCard + ReceivedCash − Σ(Price − Discount − Other) ≤ 10000 tiyin
Price − Discount − Other ≥ 0   (har qator)
```

Ya'ni `Other` xaridordan **olinmagan** pul: u naqd/kartaga qo'shilmaydi, aksincha qator summasidan ayriladi.
VAT formulasi spetsifikatsiyada **yozilmagan**.

### 2.2 Click/Payme qanday to'lov hisoblanadi

- Soliq organi (norma.uz sharhi): *"Налоговый орган рассматривает оплату при помощи платежных
  мобильных приложений как оплату при помощи банковских карт"* — mobil ilova orqali to'lov
  **bank kartasi orqali to'lov** deb qaraladi, ya'ni beznal.
- buxgalter.uz (savol 8): *"мобильное платежное приложение используется для проводки платежа
  за покупку с пластиковой карты, при этом кассовый чек формируется ... при помощи онлайн-ККМ"*.
- Spetsifikatsiyaning o'zida QR to'lov uchun alohida `PaymentType=3` va `ExtraInfo.QRPayment*`
  maydonlari bor. `Other` QR uchun mo'ljallanmagan.

**Xulosa:** Click / Payme / Uzum / Paynet summasi `ReceivedCard` ga, provayder va to'lov ID si
`ExtraInfo` ga. QQS to'liq hisoblanadi, chunki bu haqiqiy pul.

---

## 3. Hozirgi kod: to'lov turi → fiskal maydon

Manba: `lib/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart:241-292`
(`saleOnOFD`). To'lov turi `payId` (adminkadan kelgan ID, `OrganizationSingleton`) va `name` bo'yicha aniqlanadi.

| To'lov turi | Kodda qanday aniqlanadi | Fiskalga qaysi maydon | QQS | Rasmiy talab | Mos? |
|---|---|---|---|---|---|
| Naqd | `name == CASH` yoki `id == cashId` | `ReceivedCash` | ✅ to'liq | `ReceivedCash` | ✅ |
| Karta (Uzcard/Humo, terminal) | `name ∈ {CARD, UZCARD, HUMO}` yoki `id == cardId` | `ReceivedCard` | ✅ to'liq | `ReceivedCard` + `ExtraInfo.CardType/PPTID` | ✅ (ExtraInfo qisman) |
| **Cashback (do'kon bonusi)** | `id == cashbackId` | qatorlar bo'ylab `Other` | ❌ 0 (ulushi qadar) | `Other` ("прочие") | ✅ mantiqan, buxgalter tasdiqlasin |
| **Click** | `id == clickId && name ∋ CLICK` | qatorlar bo'ylab `Other` | ❌ 0 | `ReceivedCard` + `QRPaymentProvider/ID` | ❌ |
| **Payme** | `id == paymeId && name ∋ PAYME` | `Other` | ❌ 0 | `ReceivedCard` + `QRPaymentProvider/ID` | ❌ |
| **Uzum** | `id == uzumId && name ∋ UZUM` | `Other` | ❌ 0 | `ReceivedCard` + `QRPaymentProvider/ID` | ❌ |
| Paynet | hech bir shartga tushmaydi → fallback | `ReceivedCard` | ✅ to'liq | `ReceivedCard` | ✅ (tasodifan) |
| Nasiya (debt) | fallback | `ReceivedCard` | ✅ to'liq | spetsifikatsiyada `Type=2 Кредит` bor | ❓ ochiq savol |
| Boshqa (gift, nfc, credit, advance...) | fallback | `ReceivedCard` | ✅ | — | ❓ |
| **Vozvrat (har qanday to'lov)** | `isRefund` | hammasi `ReceivedCash` | ✅ | — | ❓ |

Muhim: `params.receivedClick / receivedPayme / receivedUzum / receivedPaynet / receivedDept`
bayroqlari fiskal body'ga **kirmaydi** (`lib/fiscal_service/model/fiscal_receipt_model.dart:36-121`
ularni o'qimaydi). Ular faqat sotuvdan keyin fiskal chek URL'ini Click/Uzum/Paynet/Payme'ga
qaytarib yuborish uchun ishlatiladi (`lib/changes/services/local_selling_service.dart:113-152`).
`PaymentType` maydoni umuman yuborilmaydi.

`ExtraInfo` (`local_selling_service.dart:266-283`): `qrPaymentProvider` va `qrPaymentID` faqat ilova
ichidagi Click/Payme/Uzum integratsiyasi orqali to'langanda to'ldiriladi:

| Provayder | Kod (`Pref 'epayPay_Id'`) | Qayerda |
|---|---|---|
| Click | 64 | `lib/changes/services/payment/click_service.dart:219` |
| Payme | 141 | `lib/changes/services/payment/payme_service.dart:64` |
| Uzum | 161 | `lib/changes/services/payment/uzum_service.dart:52` |

Bu kodlarning Soliq ro'yxatiga mosligi tekshirilmagan (spetsifikatsiyada ro'yxat yo'q).

---

## 4. QQS qanday hisoblanadi

### 4.1 Fiskalga ketadigan `VAT`

`receipt_singleton_4.dart:546`:

```
VAT = (Price − Other) × VATPercent / (100 + VATPercent)     (manfiy bo'lsa 0)
```

- `Price` = chegirmasiz qator summasi (`realPrice × qty`, `:539`)
- `Other` = shu qatorga tushgan cashback + Click/Payme/Uzum ulushi (`:586`)
- `Discount` **ayrilmaydi** (loyiha hujjati `docs/fiscal-sale-integration.md:217` da ham shunday yozilgan)

Natija:

| Holat | Fiskal VAT |
|---|---|
| 500 so'm naqd/karta | 500 × 12/112 = 53.57 → 54 |
| 500 so'm 100% cashback | Other = 500 → **0** |
| 500 so'm 100% Click | Other = 500 → **0** (rasmiy talabga zid, 54 bo'lishi kerak) |
| 500 so'm, 250 cashback + 250 naqd | (500−250) × 12/112 = 27 |
| 1000 so'm, 200 chegirma, naqd | Price=1000, Disc=200 → 1000 × 12/112 = **107** (chegirma hisobga olinmaydi) |

### 4.2 Chop etilgan chek va ekran

To'lov turini **umuman hisobga olmaydi**, doim `chegirmali narx × qty × 12/112`:

| Joy | Fayl:qator |
|---|---|
| Chek qatori "sh.j QQS" | `lib/features/printing/api/components/sold_api_components.dart:465` |
| Chek pastidagi jami QQS | `lib/features/printing/api/components/sold_api_components.dart:621` |
| Ruscha chek "В том числе НДС" | `lib/features/printing/api/print_payment_page_api.dart:640` |
| Ekrandagi jami QQS | `lib/features/get_products/singletons/items_singleton.dart:29` |
| Serverga `order_pos` qator `vat` | `lib/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart:542` (qiymat `sold_item_builder.dart:50-52` dan) |

Shu sabab 500 so'mlik cashback chekida fiskalda 0, qog'ozda 54.

Yuqoridagi 1000/200 misolida esa teskari: fiskalda 107, chekda 800 × 12/112 = 86.
Ya'ni chek va fiskal **ikki yo'nalishda** farq qiladi: cashback/Click da chek ko'p ko'rsatadi,
chegirmada chek kam ko'rsatadi.

### 4.3 QQS foizi manbai

- Adminkadan mahsulot bilan keladi: `ItemModel.vat` → `Vat{id, name, percentage}`
  (`lib/changes/models/product/item_model.dart:557-575`).
- Savat qatoriga yozilganda: `product.vat?.percentage ?? 12`
  (`lib/changes/domain/cart/sold_item_builder.dart:50-57`, shuningdek `box_row_builder.dart:58-63`,
  `marked_row_builder.dart:56-59`, `row_repricer.dart:62`).
- Demak: adminkada mahsulotga QQS biriktirilgan bo'lsa o'sha foiz (12, 0, yoki boshqa),
  biriktirilmagan bo'lsa **statik 12**. Kodda 6% yo'q, `nds` sozlamasi (`settings_features_model.dart:11`)
  hech qayerda ishlatilmaydi.
- QQS to'lovchi bo'lmagan do'kon uchun adminkada mahsulot QQS'i 0 qilinishi kerak, aks holda
  fallback 12 ketadi. Buni adminka tomonida tekshirish kerak.

---

## 5. Cashback bo'yicha xulosa (asosiy savol)

Bizdagi cashback do'konning o'z bonusi (BonusPoint diskonti bilan beriladi, xaridor pul to'lamagan).
Xaridor u bilan to'laganda do'kon **hech qanday pul olmaydi**, iqtisodiy jihatdan bu chegirma.
Spetsifikatsiya `Other` ni "xaridordan olinmagan, boshqa manbadan qoplangan" qism sifatida
ta'riflaydi (misol: sug'urta). Do'kon bonusi shu ta'rifga tushadi, va `VAT = (Price − Other) × …`
formulasi bilan QQS 0 bo'ladi.

**Shuning uchun RPC dagi VAT=0 to'g'ri, chekdagi 54 noto'g'ri.**

Shart: buxgalteriya cashbackni chegirma emas, "to'lov vositasi" deb hisoblasa, unda QQS
to'liq bo'lishi kerak va cashback `Other` ga emas, boshqa yo'l bilan ketishi kerak. Bu kod emas,
buxgalter qarori; bir marta yozma tasdiqlab olish kerak.

---

## 6. Topilgan nomuvofiqliklar (prioritet bo'yicha)

1. **Click/Payme/Uzum `Other` da** → fiskalda QQS 0 ketyapti, `PaymentType` yo'q. Rasmiy talab
   `ReceivedCard`. Soliq nuqtai nazaridan eng jiddiy: haqiqiy pul QQS'siz ketyapti.
   Kod: `receipt_singleton_4.dart:280-284` (`otherValue += p.value`) va `:326-330`
   (`cashback: receipt.cashback + otherValue`).
2. **Chek/ekran/server QQS'i fiskal bilan mos emas** (4.2-bo'lim, 5 joy).
3. **Chegirma QQS bazasidan ayrilmaydi** fiskalda (`VAT = (Price − Other)`, `Discount` yo'q).
   Spetsifikatsiya formulani bermaydi, lekin balans `Price − Discount − Other` asosida. Mantiqan
   QQS bazasi ham shu bo'lishi kerak. OFD hozir qabul qilyapti, lekin ortiqcha QQS deklaratsiya
   qilinayotgan bo'lishi mumkin. Fiskal modul vendori bilan aniqlashtirish kerak.
4. **Nasiya `ReceivedCard` ga** ketyapti (fallback). Spetsifikatsiyada `Type=2 Кредит` bor.
5. **Vozvrat hammasi `ReceivedCash`**, asl to'lov turi hisobga olinmaydi.
6. Provayder kodlari 64/141/161 rasmiy ro'yxat bilan solishtirilmagan.

---

## 7. Agar tuzatiladigan bo'lsa (ish hajmi, kod o'zgartirilmagan)

- (1) uchun: `saleOnOFD` da Click/Payme/Uzum ni `receivedCardValue` ga o'tkazish, `Other` da faqat
  cashback qoldirish. `_enforce1021Balance` avtomatik mos keladi. Xavf: 06-24 dagi yaxlitlash
  muammosi (`docs/sessions/archive/2026-06-24-ofd-1021-electronic-payment-rounding.md`) Click uchun
  endi `ReceivedCard` orqali hal bo'ladi, cashback uchun o'sha algoritm qoladi.
- (2) uchun: 5 joyda QQS formulasini `(qator summasi − qatorga tushgan cashback ulushi) × p/(100+p)`
  ga o'tkazish. Ulushni `_countOtherOFD` bilan bir xil hisoblash kerak, aks holda yana farq chiqadi.
- (3), (4), (5): avval buxgalter/vendor javobi, keyin qaror.

---

## 8. Manbalar

- Fiscal Drive Service spetsifikatsiyasi (maydonlar, balans qoidasi):
  https://github.com/qo0p/fiscal-drive-service
- Soliq organi Click/Payme'ni karta to'lovi deb qarashi (norma.uz):
  https://gazeta.norma.uz/publish/doc/text171140_chek_onlayn-kkm_i_payme
- buxgalter.uz, onlayn-KKM cheklari bo'yicha savol-javob, 8-savol:
  https://buxgalter.uz/publish/doc/text189174_goryachie_voprosy-otvety_pro_cheki_onlayn-kkt_chast_2
- ГНК to'lovlarni fiskallashtirish bo'yicha izohi (gazeta.uz, 2022-11-01):
  https://www.gazeta.uz/ru/2022/11/01/fiscalization-of-payments/
- Loyiha ichki hujjati: `docs/fiscal-sale-integration.md` (§10.2.1, `Other`, `VAT` formulasi)
