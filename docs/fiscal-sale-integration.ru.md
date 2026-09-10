# Фискальный модуль — API продажи (для интеграторов)

Документ описывает **эндпоинты, формат запросов (body), единицы измерения и формат ответа**.
Только операция **продажи** (sale).

> Приложение отправляет фискальный чек в локальную службу `FiscalDriveAPI`.
> На сервер ОФД (налоговая) чек уходит уже из этой службы в фоне — ваше приложение с ОФД напрямую не работает.

## Base URL (локальный контур)

```
BASE_URL=http://127.0.0.1:3448/rpc/api
```

Все запросы идут на **один и тот же адрес** методом `POST`. Тип операции указывается не в URL, а в поле `method` внутри body.

## Заголовки и формат данных

- `Content-Type: application/json`
- Протокол: **JSON-RPC 2.0**

```json
{
  "jsonrpc": "2.0",
  "id": 45,
  "method": "Api.<ИмяМетода>",
  "params": { }
}
```

## Значения в примерах (обязательно заменить)

> **Внимание.** Все конкретные значения в примерах ниже — **демонстрационные**.
> Перед использованием замените их на свои, иначе чек не пройдёт.

| Значение в примере | Что это | Откуда брать |
|---|---|---|
| `UZ123456789012` | `FactoryID` | из ответа `Api.ListFiscalDrives` (запрашивается один раз при старте) |
| `"name": "Invan"` | название POS-приложения | **название вашего приложения**, не `Invan` |
| `"sn": "SN-000123"` | серийный номер приложения / кассы | ваше значение |
| `"version": "1.1.2+88"` | версия приложения | ваша версия |
| `"Latitude": 41.311081, "Longitude": 69.240562` | координаты торговой точки | координаты **вашей** точки |
| `06305001002000000`, `4780000000017`, `Coca-Cola 1L`, `1512199` | `SPIC`, `Barcode`, `Name`, `PackageCode` | карточка вашего товара |
| `2026-09-07 14:33:01` | `Time` | текущее время кассы, UTC+5 |

Отдельно: `TerminalID` (`VG300750000021`), `ReceiptSeq` (`108`), `FiscalSign` (`696533213005`), `DateTime` (`20260907143301`) —
**в запросе продажи не передаются**. Это значения, которые модуль возвращает в ответе.

## Базовые эндпоинты

### 1) Список ФМ (получение FactoryID)

`method: Api.ListFiscalDrives`

```json
{"jsonrpc":"2.0","id":47360,"method":"Api.ListFiscalDrives","params":{}}
```

Ответ:

```json
{"jsonrpc":"2.0","id":47360,"result":{"FactoryID":["UZ123456789012"]}}
```

`FactoryID = result.FactoryID[0]` — обязателен в запросе продажи. Запрашивается один раз и кэшируется.

### 2) Информация о модуле (получение TerminalID)

`method: Api.GetInfo`

```json
{"jsonrpc":"2.0","id":47360,"method":"Api.GetInfo",
 "params":{"FactoryID":"UZ123456789012"}}
```

Ответ: `result.TerminalID` → `"VG300750000021"`.

### 3) Чек продажи (основная точка)

`method: Api.SendSaleReceipt`

Body — в разделе ниже.

## Единицы измерения и деньги (важно)

- `Price`, `Discount`, `Other`, `VAT`, `ReceivedCash`, `ReceivedCard` — **в тийинах** (сум × 100), **целые числа**.
- `Amount` — **количество × 1000** (2 шт → `2000`, 0.29 кг → `290`).
- `VATPercent` — процент, целое число (12, 15, 0).
- `Units` — `0`.
- `Time` — строка вида `yyyy-MM-dd HH:mm:ss`, **по времени Ташкента (UTC+5)**.

### Обязательное условие — §10.2.1

**До** отправки body должны выполняться оба равенства, иначе модуль отклонит чек (`65531`):

```
1) для каждой позиции:  Other + Discount ≤ Price
2) по чеку:             Σ(Price − Discount) = ReceivedCash + ReceivedCard + Σ(Other)
```

Расхождение даже в один тийин приводит к отказу. `Other` — оплата, отличная от наличных и карты (Click, Payme, Uzum, кешбэк): она передаётся **не на уровне чека, а распределяется по позициям**.

## Маркировка и штрихкоды (важно)

- `Label` — код маркировки. Код со сканера передаётся **не 1:1**, а очищенным:
  `(93)` и всё, что после (крипто-часть), отрезается; управляющие символы (`\x00–\x1F`, `\x7F`) удаляются;
  скобки убираются, **цифры сохраняются**: `(01)` → `01`, `(21)` → `21`.
- Для немаркированного товара `Label: ""`.
- `SPIC` (ИКПУ/МХИК) — 17 знаков, **обязателен для каждой позиции**. При пустом значении чек отклоняется.

## Body продажи (method: Api.SendSaleReceipt)

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
          "Name": "Говядина",
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

Проверка баланса (§10.2.1):
`Σ(Price − Discount) = 2400000 + 2260600 = 4660600` = `ReceivedCash + ReceivedCard + ΣOther = 4660600`.

### Поля Receipt

- `Time` — `yyyy-MM-dd HH:mm:ss`, UTC+5.
- `ReceivedCash` / `ReceivedCard` — тийины. Электронная оплата сюда **не записывается**, она уходит в `Other` позиций.
- `Location` — координаты торговой точки (`Latitude`, `Longitude`).
- `SenderInfo` — информация о POS-приложении: `name`, `sn` (серийный номер), `version`. Укажите **своё** приложение, а не значения из примера.
- `ExtraInfo` — необязательные поля; если не нужны, передавайте `""` / `0`, но **не удаляйте**.
- `Items` — строки чека.

### Поля Items

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

Нюансы:

- `SPIC` — код ИКПУ, **строка**, обязателен.
- `Amount` — количество × 1000. Дробное количество выражается именно здесь (0.29 кг → `290`).
- `Price` — **полная сумма позиции** (не цена за единицу!): `round(qty × цена) × 100`, без учёта скидки.
- `Discount` — **общая сумма скидки по позиции**: `(старая цена − новая цена) × qty × 100`.
- `Other` — доля электронной оплаты, приходящаяся на эту позицию, в тийинах.
- `VAT` — `(Price − Other) × VATPercent / (100 + VATPercent)`. **Не** от `Price − Discount`. Если результат отрицательный — `0`.
- `PackageCode` — код упаковки, **строка** (даже если выглядит как число).
- `OwnerType` — для обычного товара `1`.
- `CommissionInfo` — при комиссионной торговле `TIN` (9 знаков) либо `PINFL` (14 знаков); если нет — оба `""`.

## Ответ (response)

FiscalDriveAPI **всегда возвращает HTTP 200**. Успех/ошибка определяются по телу ответа:
есть `result` — успех, есть `error` — ошибка.

### Успех

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

| Поле | Описание |
|---|---|
| `TerminalID` | Номер кассового терминала |
| `ReceiptSeq` | Порядковый номер чека |
| `DateTime` | **`yyyyMMddHHmmss`** — отличается от формата в запросе |
| `FiscalSign` | Фискальный признак (ФП) — печатается на чеке |
| `QRCodeURL` | Ссылка QR-кода чека — печатается на чеке |
| `AppletVersion` | Версия апплета ФМ |

Первые 4 поля — фискальный «паспорт» чека. **Сохранение в базу обязательно**: именно они потребуются, чтобы позже оформить возврат по этому чеку.

### Ошибка

```json
{
  "jsonrpc": "2.0",
  "id": 45,
  "error": { "code": 65531, "message": "...", "data": "..." }
}
```

| Код | Значение |
|---|---|
| `65531` | Ошибочные параметры в чеке — нарушено уравнение §10.2.1 (встречается чаще всего) |
| `65532` | Передан недействительный параметр в JSON (неверное имя поля или тип) |
| `65534` / `65535` | Не удалось подключиться к ФМ (не подключен или неверный FactoryID) |
| `65533` | Не удалось выбрать апплет в ФМ |
| `65529` | Не удалось декодировать ответ — повторите попытку |
| `65528` | Ошибка при сохранении чека в БД |
| `65525` | Версия апплета не поддерживается |
| `65279` | Сервер ОФД заблокировал ФМ — обратитесь в ОФД |

Сетевые ситуации: нет соединения → служба не запущена; таймаут (30 с) → ФМ не отвечает.

## Примеры curl (готовые шаблоны)

```powershell
$env:BASE_URL = "http://127.0.0.1:3448/rpc/api"
```

### Получение FactoryID

```powershell
curl -X POST "$env:BASE_URL" `
  -H "Content-Type: application/json" `
  -d '{"jsonrpc":"2.0","id":47360,"method":"Api.ListFiscalDrives","params":{}}'
```

### Получение TerminalID

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

### Продажа (Api.SendSaleReceipt)

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
