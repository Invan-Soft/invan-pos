# Fiskal chek: to'lov turlari qaysi maydonga ketadi (qisqa)

**Sana:** 2026-10-01 · **Manba loyiha:** InVan 2 POS

## Nima o'zgardi

Click Pass va Payme Go endi fiskalga `Other` da emas, `ReceivedCard` da ketadi va QQS to'liq hisoblanadi.
Sababi: soliq organi mobil ilova orqali to'lovni karta (beznal) to'lovi deb hisoblaydi.
QR variantlari (Click QR, Payme QR) va qolgan to'lov turlari **o'zgarmagan**.

## Jadval (sotuv)

| To'lov turi | Fiskal maydon | QQS (VAT) | Provayderga fiskal chek yuboriladimi |
|---|---|---|---|
| Naqd | `ReceivedCash` | to'liq | — |
| Karta (Uzcard / Humo / terminal) | `ReceivedCard` | to'liq | — |
| **Click Pass** | `ReceivedCard` ⬅ *o'zgardi* (oldin `Other`) | to'liq ⬅ *o'zgardi* (oldin 0) | ✅ ha |
| **Payme Go** | `ReceivedCard` ⬅ *o'zgardi* (oldin `Other`) | to'liq ⬅ *o'zgardi* (oldin 0) | ✅ ha |
| Click QR | `Other` (qatorlarga taqsimlanadi) | 0 | ❌ yo'q ⬅ *tuzatildi* (oldin xato yuborilardi) |
| Payme QR | `Other` | 0 | ❌ yo'q ⬅ *tuzatildi* |
| Uzum (Pass) | `Other` | 0 | ✅ ha |
| Uzum QR | `Other` | 0 | ❌ yo'q ⬅ *tuzatildi* |
| Cashback (do'kon bonusi) | `Other` | 0 (ulushi qadar) | — |
| Nasiya (debt) | `ReceivedCard` (fallback) | to'liq | — |
| Boshqa / noma'lum tur | `ReceivedCard` (fallback) | to'liq | — |

**Vozvrat:** to'lov turidan qat'iy nazar hammasi `ReceivedCash` ga ketadi (o'zgarmagan).

QQS formulasi qatorda: `VAT = (Price − Discount − Other) × p / (100 + p)`. Shuning uchun `Other` ga tushgan
summa QQS'ni kamaytiradi, `ReceivedCard` ga tushgan summa esa kamaytirmaydi.

## Pass va QR qanday ajratiladi

To'lov ekranida Click / Payme tugmasi ikkiga bo'linadi:
- **Pass / Go**: integratsiya orqali to'lanadi. To'lov ID'si oddiy (`id`), nomi `CLICK PASS` / `PAYME GO`.
- **QR**: kassir qo'lda belgilaydi (`type = 1`). To'lov ID'si `@` bilan boshlanadi (`@id`), nomi `CLICK QR` / `PAYME QR`.

Qoida: **ID `@` bilan boshlansa YOKI nomida `QR` bo'lsa, bu QR to'lov.** Nom ham tekshiriladi, chunki
serverdan qaytgan chekda `@` olib tashlangan bo'lishi mumkin.

## Kod

To'lov tasnifi (sotuv):

```dart
static bool isQr(ReceiptModelPaymentType4 p) =>
    p.payId.trim().startsWith('@') || p.name.toUpperCase().contains('QR');

for (final p in receipt.payment) {
  final nameUpper = p.name.toUpperCase().trim();
  final id = p.payId.replaceFirst('@', '').trim();

  if (nameUpper == 'CASH' || id == cashId) {
    cash += p.value;                                   // ReceivedCash
  } else if (nameUpper == 'CARD' || nameUpper == 'UZCARD' ||
      nameUpper == 'HUMO' || id == cardId) {
    card += p.value;                                   // ReceivedCard
  } else if (id == cashbackId) {
    cashback += p.value;                               // Other
  } else if ((id == clickId && nameUpper.contains('CLICK')) ||
      (id == paymeId && nameUpper.contains('PAYME'))) {
    if (isQr(p)) {
      epay += p.value;                                 // QR → Other
    } else {
      card += p.value;                                 // Pass / Go → ReceivedCard
    }
  } else if (id == uzumId && nameUpper.contains('UZUM')) {
    epay += p.value;                                   // Other
  } else {
    card += p.value;                                   // nasiya va boshqalar → ReceivedCard
  }
}
// Other umumiy summasi = cashback + epay (qatorlarga nisbat bo'yicha taqsimlanadi)
```

Provayderga fiskal chek URL'ini qaytarish bayroqlari (faqat Pass/Go):

```dart
static bool hasPass(ReceiptModel4 receipt, String providerId) {
  if (providerId.isEmpty) return false;
  return receipt.payment.any(
    (p) => p.payId.replaceFirst('@', '').trim() == providerId && !isQr(p),
  );
}

"receivedClick": hasPass(receipt, Pref.getString(PrefKeys.clickId, "")),
"receivedUzum":  hasPass(receipt, Pref.getString(PrefKeys.uzumId, "")),
"receivedPayme": hasPass(receipt, Pref.getString(PrefKeys.paymeId, "")),
```

Oldin bu bayroqlar to'lov ID'si mos kelsa (QR'da ham) `true` bo'lardi. Natijada QR chekidan keyin ham
Click/Payme/Uzum API'siga oldingi to'lovdan qolgan `payment_id` bilan so'rov ketardi.
Serverga ketadigan `has_click` / `has_payme` / `has_uzum` maydonlariga **tegilmagan**.

## Provayderga nima yuboriladi (Pass/Go, sotuvdan keyin)

| Provayder | Metod | Asosiy maydonlar |
|---|---|---|
| Click Pass | `POST /payment/ofd_data/submit_qrcode` | `service_id`, `payment_id`, `qrcode` (fiskal chek URL'i) |
| Payme Go | `receipts.set_fiscal_data` | `receipt_id`, `qr_code_url` (majburiy) |

Fiskal chekning `ExtraInfo` qismida Pass/Go uchun `QRPaymentProvider` (Click 64, Payme 141), `QRPaymentID`
va `PhoneNumber` ketadi. Bu qism ham o'zgarmagan.

## Tekshirish

- Click Pass / Payme Go chekida fiskal JSON: `ReceivedCard` = to'lov summasi, `Other` = 0, `VAT` > 0.
- Click QR / Payme QR chekida: eskidek, summa `Other` da, `VAT` = 0, provayderga so'rov ketmaydi.
- Aralash (masalan naqd + Click Pass + Payme QR): naqd `ReceivedCash` ga, Pass `ReceivedCard` ga, QR `Other` ga.
