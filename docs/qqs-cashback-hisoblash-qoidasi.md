# QQS va Cashback — fiskal hisoblash qoidasi

**Sana:** 2026-09-30
**Kimga:** boshqa integratsiyada (masalan InVan 1 yoki boshqa tizim) xuddi shu QQS/cashback
mantiqini qo'llaydigan dasturchiga.
**Maqsad:** cashback (do'kon bonusi) va chegirma bilan to'langan tovarlarda soliqqa (fiskal
modulga) ketadigan QQS qanday hisoblanishi kerakligi — formula, misollar, keng tarqalgan
noto'g'ri tushunish.

---

## 1. Qisqa xulosa

- QQS bazasi **hech qachon** to'liq (chegirmasiz) narxdan emas, `Price − Discount − Other`
  dan hisoblanadi.
- `Other` — xaridordan **olinmagan** pul (cashback, do'kon bonusi va h.k.). U ham QQS
  bazasidan chiqadi: 100% cashback bilan to'lansa QQS 0 bo'ladi. Bu bug emas, to'g'ri.
- `Price` va `Other` **qo'shilmaydi**. `Price` — tovarning to'liq qiymati, `Other` shu
  qiymatning ichidan qancha qismi pul bo'lmagani.
- Cashback bir nechta mahsulotli chekda har qatorga **narx nisbatiga proporsional**
  taqsimlanadi, teng bo'lib emas.

---

## 2. Rasmiy fiskal maydonlar (chek qatori darajasida)

Manba: FiscalDriveService spetsifikatsiyasi — https://github.com/qo0p/fiscal-drive-service

| Maydon | Ma'nosi |
|---|---|
| `Price` | Qatorning **to'liq qiymati, chegirmasiz**: `round(narx × miqdor) × 100` (tiyinda) |
| `Discount` | Chegirma summasi: `(eski narx − yangi narx) × miqdor × 100` |
| `Other` | Xaridordan **olinmagan** qism — "прочие" (cashback, sug'urta bilan to'lash va h.k.) |
| `VATPercent` | QQS foizi |
| `VAT` | QQS summasi |

Rasmiy misol (spec'dan, o'zgarishsiz): `Price: 100000, Discount: 50000, VATPercent: 12` →
`VAT: 5357` = `(100000 − 50000) × 12 / 112`.

---

## 3. Balans qoidasi (modulning o'zi talab qiladi)

```
ReceivedCash + ReceivedCard + ΣOther = Σ(Price − Discount)
Price − Discount − Other ≥ 0        (har bir qatorda)
```

**Muhim tushunish:** `Price` va `Other` bir-biriga qo'shiladigan ikki alohida summa emas.
`Price` — mahsulotning to'liq qiymati, `Other` esa shu qiymatning **ichidan** qancha qismi
pul bo'lmaganini ko'rsatadi.

Misol: 30 000 so'mlik tovarda `Other = 15000` bo'lsa —

- ❌ Noto'g'ri tushunish: "30 000 + 15 000 = 45 000 ga sotilgan"
- ✅ To'g'ri: "30 000 so'mlik tovar, shundan 15 000 cashback (pul emas), 15 000 haqiqiy
  naqd/karta"

Tekshiruv: `naqd/karta qismi + Other = Price` → `15000 + 15000 = 30000` ✓

---

## 4. QQS formulasi

```
VAT = (Price − Discount − Other) × VATPercent / (100 + VATPercent)
```

Manfiy chiqsa 0 deb olinadi. `Discount` HAM, `Other` HAM bazadan ayriladi — ikkalasi ham
xaridordan real pul sifatida olinmagan qism.

### Tekshirilgan real misol (production, 1+1 aksiya)

Bitta chek qatori, fiskal moduliga ketgan JSON:

```json
{
  "Price": 11996000,
  "Discount": 5998000,
  "Other": 0,
  "VATPercent": 12,
  "VAT": 642642
}
```

Tekshiruv: `(11996000 − 5998000) × 12 / 112 = 642642.86` → `642642` (kasr kesiladi). Mos.

---

## 5. Cashback bir nechta qatorga qanday taqsimlanadi

Cashback butun chekka **bitta summa** sifatida keladi (masalan to'lov ekranida "Cashback"
tugmasi). Fiskalga yuborishdan oldin har qatorga **narx nisbatiga proporsional** bo'linadi:

```
qator_Other = cashback_jami × (qator_summasi / chek_jami_summasi)
```

### Misol: 3 ta mahsulot, aralash to'lov

Savat: 30 000 + 20 000 + 10 000 = 60 000 so'm. 30 000 so'm cashback bilan, qolgan 30 000
naqd bilan to'landi.

| Mahsulot | Narx | Other hisobi | Other | Naqd qismi |
|---|---|---|---|---|
| A | 30 000 | 30000 × (30000/60000) | 15 000 | 15 000 |
| B | 20 000 | 30000 × (20000/60000) | 10 000 | 10 000 |
| C | 10 000 | 30000 × (10000/60000) | 5 000 | 5 000 |
| **Jami** | 60 000 | | **30 000** | 30 000 |

**Diqqat:** teng bo'lib (10 000/10 000/10 000) emas, narxga proporsional taqsimlanadi.
Qimmatroq mahsulotga cashback'dan ko'proq ulush tushadi.

Har qatorning QQS'i (12%, chegirmasiz deb olsak):

| Mahsulot | Baza (Price − Other) | VAT |
|---|---|---|
| A | 30000 − 15000 = 15000 | 15000 × 12/112 = 1607.14 |
| B | 20000 − 10000 = 10000 | 10000 × 12/112 = 1071.43 |
| C | 10000 − 5000 = 5000 | 5000 × 12/112 = 535.71 |
| **Jami** | 30000 | **3214.28** |

Tekshiruv: butun chek bo'yicha ham `(60000 − 30000) × 12/112 = 3214.28` — mos keladi.

---

## 6. Chegirma + cashback birga bo'lsa

Ikkalasi bir vaqtda bo'lishi mumkin (masalan tovar chegirmada, qolgan qismi cashback bilan
to'lanadi). Formula o'zgarmaydi, ikkalasi ham bir xil bazadan ayriladi:

```
VAT bazasi = Price − Discount − Other
```

100% cashback bilan to'lansa (`Other = Price − Discount`) → `VAT = 0`. Bu **to'g'ri**, bug
emas — cashback xaridordan olinmagan pul, xuddi spec'dagi "sug'urta bilan to'lash" misoli
kabi.

---

## 7. Keng tarqalgan xato (bizda topilgan bug, tuzatilgan)

Eski (noto'g'ri) formula: `VAT = (Price − Other) × p/(100+p)` — `Discount` ayrilmasdi.
Natijada chegirmali tovarda QQS chegirmasiz to'liq narxdan hisoblanardi (masalan 50 000
so'mlik tovar 30 000 chegirma bilan 20 000 ga sotilsa, QQS 50 000 dan olinardi, to'g'risi
20 000 dan olinishi kerak edi). `Other` (cashback) tomoni boshidanoq to'g'ri edi — faqat
`Discount` unutilgan edi.

Tuzatish: formulaga `Discount` ham qo'shildi → `(Price − Discount − Other)`.

---

## 8. Manbalar

- FiscalDriveService spetsifikatsiyasi (rasmiy maydon ta'riflari, balans qoidasi):
  https://github.com/qo0p/fiscal-drive-service
- InVan 2 loyihasidagi ichki hujjat: `docs/fiscal-sale-integration.md` (§10.2.1, `Other`,
  `VAT` formulasi)
