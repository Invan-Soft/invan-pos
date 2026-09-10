# Fiskal modul — Sotuv API (integratorlar uchun)

Hujjat **endpoint, so'rov formati (body), o'lchov birliklari va javob ko'rinishini** tavsiflaydi.
Faqat **sotuv** (sale) operatsiyasi.

> POS dasturi fiskal chekni lokal `FiscalDriveAPI` xizmatiga yuboradi.
> Soliq serveriga (OFD) chekni o'sha xizmat o'zi fonda jo'natadi — sizning dasturingiz OFD bilan bevosita ishlamaydi.

## Base URL (lokal kontur)

```
BASE_URL=http://127.0.0.1:3448/rpc/api
```

Barcha so'rovlar shu bitta manzilga `POST` bilan boradi. Metod URL da emas, body ichidagi `method` maydonida ko'rsatiladi.

## Sarlavhalar va format

- `Content-Type: application/json`
- Protokol: **JSON-RPC 2.0**

```json
{
  "jsonrpc": "2.0",
  "id": 45,
  "method": "Api.<MetodNomi>",
  "params": { }
}
```

## Misollardagi qiymatlar (albatta almashtiriladi)

> **Diqqat.** Quyidagi misollardagi barcha aniq qiymatlar — **namuna**.
> Ishlatishdan oldin o'zingiznikiga almashtiring, aks holda chek o'tmaydi.

| Misoldagi qiymat | Bu nima | Qayerdan olinadi |
|---|---|---|
| `UZ123456789012` | `FactoryID` | `Api.ListFiscalDrives` javobidan (startda bir marta) |
| `"name": "Invan"` | POS dasturi nomi | **o'z dasturingiz nomi**, `Invan` emas |
| `"sn": "SN-000123"` | dastur / kassa seriya raqami | o'z qiymatingiz |
| `"version": "1.1.2+88"` | dastur versiyasi | o'z versiyangiz |
| `"Latitude": 41.311081, "Longitude": 69.240562` | do'kon koordinatasi | **o'z** do'koningiz koordinatasi |
| `06305001002000000`, `4780000000017`, `Coca-Cola 1L`, `1512199` | `SPIC`, `Barcode`, `Name`, `PackageCode` | o'z mahsulot kartochkangiz |
| `2026-09-07 14:33:01` | `Time` | kassaning joriy vaqti, UTC+5 |

Alohida: `TerminalID` (`VG300750000021`), `ReceiptSeq` (`108`), `FiscalSign` (`696533213005`), `DateTime` (`20260907143301`) —
**sotuv so'rovida yuborilmaydi**. Bular modul javobda qaytaradigan qiymatlar.

## Bazaviy endpointlar

### 1) ФМ ro'yxati (FactoryID olish)

`method: Api.ListFiscalDrives`

```json
{"jsonrpc":"2.0","id":47360,"method":"Api.ListFiscalDrives","params":{}}
```

Javob:

```json
{"jsonrpc":"2.0","id":47360,"result":{"FactoryID":["UZ123456789012"]}}
```

`FactoryID = result.FactoryID[0]` — sotuv so'rovida majburiy. Bir marta olib keshlanadi.

### 2) Modul ma'lumoti (TerminalID olish)

`method: Api.GetInfo`

```json
{"jsonrpc":"2.0","id":47360,"method":"Api.GetInfo",
 "params":{"FactoryID":"UZ123456789012"}}
```

Javob: `result.TerminalID` → `"VG300750000021"`.

### 3) Sotuv cheki (asosiy nuqta)

`method: Api.SendSaleReceipt`

Body — quyidagi bo'limda.

## Birliklar va pul (muhim)

- `Price`, `Discount`, `Other`, `VAT`, `ReceivedCash`, `ReceivedCard` — **tiyinda** (so'm × 100), **butun son**.
- `Amount` — **miqdor × 1000** (2 dona → `2000`, 0.29 kg → `290`).
- `VATPercent` — foiz, butun son (12, 15, 0).
- `Units` — `0`.
- `Time` — `yyyy-MM-dd HH:mm:ss` ko'rinishidagi satr, **Toshkent vaqti (UTC+5)**.

### Majburiy shart — §10.2.1

Body yuborishdan **oldin** ikkala tenglama bajarilishi shart, aks holda modul chekni rad etadi (`65531`):

```
1) har item uchun:  Other + Discount ≤ Price
2) chek bo'yicha:   Σ(Price − Discount) = ReceivedCash + ReceivedCard + Σ(Other)
```

Bir tiyin farq ham chekni rad ettiradi. `Other` — naqd va kartadan tashqari to'lov (Click, Payme, Uzum, keshbek): u chek darajasida emas, **itemlar bo'ylab** taqsimlanadi.

## Markirovka va shtrix-kodlar (muhim)

- `Label` — markirovka kodi. Skanerdan kelgan kod **1:1 emas**, tozalab yuboriladi:
  `(93)` va undan keyingi kripto qism kesiladi, boshqaruv belgilari (`\x00–\x1F`, `\x7F`) o'chiriladi,
  qavslar tekislanadi — **raqam saqlanadi**: `(01)` → `01`, `(21)` → `21`.
- Markirovkasiz tovarda `Label: ""`.
- `SPIC` (MXIK) — 17 xonali, **har item uchun majburiy**. Bo'sh yuborilsa chek rad etiladi.

## Sotuv body (module: Api.SendSaleReceipt)

```json
{
  "jsonrpc": "2.0",
  "id": 45,
  "method": "Api.SendSaleReceipt",
  "params": {
    "FactoryID": "UZ123456789012",
    "Receipt": {
      "Time": "2026-09-07 14:33:01",
      "ReceivedCash": 4660600,
      "ReceivedCard": 0,
      "Location": { "Latitude": 41.311081, "Longitude": 69.240562 },
      "SenderInfo": { "name": "Invan", "sn": "SN-000123", "version": "1.1.2+88" },
      "ExtraInfo": {
        "PINFL": "",
        "TIN": "",
        "CarNumber": "",
        "PhoneNumber": "",
        "CardType": 0,
        "CardNumber": "",
        "PPTID": "",
        "QRPaymentID": "",
        "QRPaymentProvider": 0,
        "CashedOutFromCard": 0
      },
      "Items": [
        {
          "SPIC": "06305001002000000",
          "Barcode": "4780000000017",
          "Name": "Coca-Cola 1L",
          "Amount": 2000,
          "Price": 2400000,
          "Discount": 0,
          "Other": 0,
          "VAT": 257142,
          "VATPercent": 12,
          "Units": 0,
          "Label": "",
          "PackageCode": "1512199",
          "OwnerType": 1,
          "CommissionInfo": { "TIN": "", "PINFL": "" }
        },
        {
          "SPIC": "02011001001000000",
          "Barcode": "2100015000000",
          "Name": "Mol go'shti",
          "Amount": 290,
          "Price": 2260600,
          "Discount": 0,
          "Other": 0,
          "VAT": 242207,
          "VATPercent": 12,
          "Units": 0,
          "Label": "",
          "PackageCode": "1512199",
          "OwnerType": 1,
          "CommissionInfo": { "TIN": "", "PINFL": "" }
        }
      ]
    }
  }
}
```

Balans tekshiruvi (§10.2.1):
`Σ(Price − Discount) = 2400000 + 2260600 = 4660600` = `ReceivedCash + ReceivedCard + ΣOther = 4660600`.

### Receipt maydonlari

- `Time` — `yyyy-MM-dd HH:mm:ss`, UTC+5.
- `ReceivedCash` / `ReceivedCard` — tiyin. Elektron to'lov bu yerga **yozilmaydi**, u itemlarning `Other` iga ketadi.
- `Location` — do'kon koordinatasi (`Latitude`, `Longitude`).
- `SenderInfo` — POS dasturi haqida: `name`, `sn` (seriya raqami), `version`. Misoldagi emas, **o'z** dasturingiz qiymatlarini yozing.
- `ExtraInfo` — ixtiyoriy maydonlar; kerak bo'lmasa `""` / `0` qilib yuboring, olib tashlamang.
- `Items` — chek qatorlari.

### Items maydonlari

```json
{
  "SPIC": "06305001002000000",
  "Barcode": "4780000000017",
  "Name": "Coca-Cola 1L",
  "Amount": 2000,
  "Price": 2400000,
  "Discount": 0,
  "Other": 0,
  "VAT": 257142,
  "VATPercent": 12,
  "Units": 0,
  "Label": "",
  "PackageCode": "1512199",
  "OwnerType": 1,
  "CommissionInfo": { "TIN": "", "PINFL": "" }
}
```

Nyuanslar:

- `SPIC` — MXIK kodi, **satr**, majburiy.
- `Amount` — miqdor × 1000. Kasrli miqdor shu yerda ifodalanadi (0.29 kg → `290`).
- `Price` — **qatorning to'liq summasi** (dona narxi emas!): `round(qty × narx) × 100`, chegirmasiz.
- `Discount` — qator bo'yicha **umumiy chegirma summasi**: `(eski narx − yangi narx) × qty × 100`.
- `Other` — shu itemga to'g'ri keluvchi elektron to'lov ulushi, tiyinda.
- `VAT` — `(Price − Other) × VATPercent / (100 + VATPercent)`. `Price − Discount` dan **emas**. Manfiy chiqsa `0`.
- `PackageCode` — qadoq kodi, **satr** (raqamga o'xshasa ham).
- `OwnerType` — oddiy tovar uchun `1`.
- `CommissionInfo` — komissiya savdosida `TIN` (9 xona) yoki `PINFL` (14 xona); bo'lmasa ikkalasi ham `""`.

## Javob (response)

FiscalDriveAPI **doim HTTP 200** qaytaradi. Muvaffaqiyat/xato body ichidan aniqlanadi:
`result` bo'lsa — muvaffaqiyat, `error` bo'lsa — xato.

### Muvaffaqiyat

```json
{
  "jsonrpc": "2.0",
  "id": 45,
  "result": {
    "TerminalID": "VG300750000021",
    "ReceiptSeq": "108",
    "DateTime": "20260907143301",
    "FiscalSign": "696533213005",
    "QRCodeURL": "https://ofd.soliq.uz/check?t=VG300750000021&r=108&c=20260907143301&s=696533213005",
    "AppletVersion": "1.7"
  }
}
```

| Maydon | Izoh |
|---|---|
| `TerminalID` | Kassa terminali raqami |
| `ReceiptSeq` | Chek tartib raqami |
| `DateTime` | **`yyyyMMddHHmmss`** — so'rovdagi formatdan farq qiladi |
| `FiscalSign` | Fiskal belgi (ФП) — chekda chop etiladi |
| `QRCodeURL` | Chek QR havolasi — chekda chop etiladi |
| `AppletVersion` | ФМ applet versiyasi |

Birinchi 4 maydon — chekning fiskal pasporti. **Bazaga saqlash majburiy**: keyinchalik shu chekni qaytarish uchun aynan ular kerak bo'ladi.

### Xato

```json
{
  "jsonrpc": "2.0",
  "id": 45,
  "error": { "code": 65531, "message": "...", "data": "..." }
}
```

| Kod | Ma'nosi |
|---|---|
| `65531` | Chekda xato parametrlar — §10.2.1 tenglamasi buzilgan (eng ko'p uchraydi) |
| `65532` | JSON da noto'g'ri parametr (maydon nomi yoki turi xato) |
| `65534` / `65535` | ФМ ga ulanib bo'lmadi (ulanmagan yoki FactoryID xato) |
| `65533` | ФМ da applet tanlanmadi |
| `65529` | Javobni deshifrlab bo'lmadi — qayta urining |
| `65528` | Chekni bazaga saqlashda xato |
| `65525` | Applet versiyasi qo'llab-quvvatlanmaydi |
| `65279` | OFD ФМ ni bloklagan — OFD ga murojaat qiling |

Tarmoq darajasidagi holatlar: ulanish yo'q → xizmat ishga tushmagan; timeout (30 s) → ФМ javob bermayapti.

## curl misollar (PowerShell)

```powershell
$env:BASE_URL = "http://127.0.0.1:3448/rpc/api"
```

### FactoryID olish

```powershell
curl -X POST "$env:BASE_URL" `
  -H "Content-Type: application/json" `
  -d '{"jsonrpc":"2.0","id":47360,"method":"Api.ListFiscalDrives","params":{}}'
```

### TerminalID olish

```powershell
curl -X POST "$env:BASE_URL" `
  -H "Content-Type: application/json" `
  -d '{
    "jsonrpc":"2.0",
    "id":47360,
    "method":"Api.GetInfo",
    "params":{"FactoryID":"UZ123456789012"}
  }'
```

### Sotuv (Api.SendSaleReceipt)

```powershell
curl -X POST "$env:BASE_URL" `
  -H "Content-Type: application/json" `
  -d '{
    "jsonrpc": "2.0",
    "id": 45,
    "method": "Api.SendSaleReceipt",
    "params": {
      "FactoryID": "UZ123456789012",
      "Receipt": {
        "Time": "2026-09-07 14:33:01",
        "ReceivedCash": 2400000,
        "ReceivedCard": 0,
        "Location": { "Latitude": 41.311081, "Longitude": 69.240562 },
        "SenderInfo": { "name": "Invan", "sn": "SN-000123", "version": "1.1.2+88" },
        "ExtraInfo": {
          "PINFL": "", "TIN": "", "CarNumber": "", "PhoneNumber": "",
          "CardType": 0, "CardNumber": "", "PPTID": "",
          "QRPaymentID": "", "QRPaymentProvider": 0, "CashedOutFromCard": 0
        },
        "Items": [
          {
            "SPIC": "06305001002000000",
            "Barcode": "4780000000017",
            "Name": "Coca-Cola 1L",
            "Amount": 2000,
            "Price": 2400000,
            "Discount": 0,
            "Other": 0,
            "VAT": 257142,
            "VATPercent": 12,
            "Units": 0,
            "Label": "",
            "PackageCode": "1512199",
            "OwnerType": 1,
            "CommissionInfo": { "TIN": "", "PINFL": "" }
          }
        ]
      }
    }
  }'
```
