# InVan 1: Mac'da ishlatish va GitHub orqali versiya chiqarish — tartib

**Manba (namuna) loyiha:** InVan 2 — `~/Documents/pos-invan-2-ayyubxon` (GitHub `Invan-Soft/invan-pos`).
Pipeline fayllari: `.github/workflows/release.yml`, `installer.iss`, `windows/CMakeLists.txt:35-38`, `.claude/skills/release/SKILL.md`.
Xuddi shu tartib 2026-09-09 da Odoo forkiga ham qo'llangan (`odoo-pos-invan-2`, commitlar `16ab6d3`, `2e05a6c`) — u ham namuna.

**Maqsad loyiha:** InVan 1 — `~/Documents/pos-desktop-for-ofd-ayyubxon`
(pubspec nomi `invan003`, versiya `1.0.0+41`, GitHub `Invan-Soft/pos-invan-1`, branch `main`).

**Tekshirilgan:** 2026-09-11. Hujjat yozilayotganda InVan 1 papkasida hech narsa o'zgartirilmadi — faqat o'qildi.

---

## 0. Tizim InVan 2 da qanday ishlaydi

```
Mac (kod yoziladi, sinaladi:  flutter run -d macos)
  │
  │  git push origin ayyubxon:main            → GitHub Invan-Soft/invan-pos
  │  git tag v1.1.2+124 ; git push origin v1.1.2+124
  ▼
GitHub Actions — .github/workflows/release.yml   (runs-on: windows-2022)
  1) flutter build windows --release
  2) Inno Setup: installer.iss  →  installers/1.1.2+124.exe
  3) GitHub Release "1.1.2+124" + .exe biriktiriladi
  │
  ▼  QO'LDA:  gh release download  →  curl POST {api}/upload/build
Backend api.7i.uz → ilova drawer "Yangilanish" → GET {api}file → cdn.7i.uz/file/pos_1.1.2+124.exe
```

To'rt qism bor, har biri alohida sozlanadi:

| # | Qism | Nima qiladi | InVan 2 da qayerda |
|---|------|-------------|--------------------|
| 1 | **macOS target** | Loyiha Mac'da `flutter run -d macos` bilan ochiladi. Windows .exe Mac'da HECH QACHON qurilmaydi. | `macos/` (Runner, Podfile, entitlements) |
| 2 | **Git → GitHub** | Kod GitHub'ga push qilinadi; tag push qilinsa build boshlanadi | remote `origin` |
| 3 | **CI build** | Windows runner'da exe + Inno Setup o'rnatuvchi + GitHub Release | `release.yml`, `installer.iss`, `CMakeLists.txt` |
| 4 | **Tarqatish** | .exe do'konlarga yetib borishi | backend `upload/build` (InVan 1 da BOSHQACHA, 8-qadam) |

---

## 1. InVan 1 ning hozirgi holati (2026-09-11)

| Nima | InVan 2 | InVan 1 | Kerak |
|------|---------|---------|-------|
| Paket nomi / exe | `invan2` / `pos_desktop_flutter.exe` | `invan003` / `invan003.exe` | — |
| Versiya | `1.1.2+124` | `1.0.0+41` | keyingi reliz `1.0.0+42` |
| Git remote | `origin` (GitHub) + `gitlab` | faqat `origin` = `Invan-Soft/pos-invan-1`, `main`, "Initial commit" push qilingan | — |
| `macos/` | to'liq (Runner, Podfile, xcworkspace) | faqat `macos/Flutter/` — Runner yo'q | **1-qadam** |
| Hive Mac fallback | bor | bor: `lib/main.dart:183` `getApplicationSupportDirectory()` | o'zgarish yo'q |
| CMake coroutine fix | bor (`windows/CMakeLists.txt:38`) | yo'q | **3-qadam** |
| `.gitignore` `/installers`, `/build/` | bor | bor (`:48`, `:33`) | o'zgarish yo'q |
| `release.yml`, `installer.iss` | bor | yo'q | **4–5-qadam** |
| Flutter | 3.41.3 (Mac), lock `flutter >=3.35.0` | lock `flutter >=3.35.0` | mos, 3.41.3 ishlatiladi |
| `String.fromEnvironment` | yo'q | yo'q | dart-define kerak emas |
| Yangilanish kanali | `GET {api}file` + `POST upload/build` | socket `newVersion` + `http://116.203.177.198:7000/<file>` | **8-qadam, ochiq savol** |

Mac'da ishlamaydigan (faqat Windows) joylar — InVan 2 da ham xuddi shunday, `flutter run` ga to'siq emas:
`lib/changes/services/file_receipt_service.dart:34,70`, `lib/features/file_crud/operations/file_printer_image.dart:8,18`,
`lib/utils/upgrade/bloc/upg_bloc.dart:40` (hammasi `C:\ProgramData\InVanPos\cache\`).

Mac muhiti tayyor: Xcode 26.5, CocoaPods 1.16.2, `gh` (`ayyubxonahmadjonov`, scope `repo, workflow`), Flutter 3.41.3.

---

## 2. Tartib (qadamma-qadam)

### 1-qadam — Mac'da ishga tushirish (macOS target)

```bash
cd ~/Documents/pos-desktop-for-ofd-ayyubxon
flutter create --platforms=macos .
```
Bu `macos/Runner/`, `macos/Podfile`, `Runner.xcodeproj`, `Runner.xcworkspace` yaratadi; mavjud `lib/`, `windows/`, `pubspec.yaml` ga tegmaydi.

Keyin InVan 2 dagi kabi sozlash:

1. `macos/Runner/DebugProfile.entitlements` ni to'liq shunga almashtiring (InVan 2 dan nusxa; sandbox o'chiq — aks holda http, `127.0.0.1:3448` fiskal va ObjectBox ishlamaydi):
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
   	<key>com.apple.security.app-sandbox</key>
   	<false/>
   	<key>com.apple.security.cs.allow-jit</key>
   	<true/>
   	<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
   	<true/>
   	<key>com.apple.security.cs.disable-library-validation</key>
   	<true/>
   	<key>com.apple.security.network.client</key>
   	<true/>
   	<key>com.apple.security.network.server</key>
   	<true/>
   </dict>
   </plist>
   ```
   `Release.entitlements` ga tegilmaydi (Mac'da release qurilmaydi).
2. `macos/Podfile` birinchi qatori `platform :osx, '10.15'` bo'lsin (kommentda bo'lsa oching). ObjectBox 10.15+ talab qiladi.
3. `.gitignore` oxiriga qo'shing (InVan 2 `e5f48a1` da qo'shilgan):
   ```
   .build/
   .swiftpm/
   ```
4. `macos/Runner/MainFlutterWindow.swift` standart holda qoladi — InVan 2 da `bitsdojo_window` uchun hech narsa sozlanmagan, `doWhenWindowReady` shunday ham ishlaydi.
5. Ishga tushirish:
   ```bash
   flutter pub get
   flutter run -d macos        # birinchi safar pod install avtomatik, 2-5 daqiqa
   ```
   Tekshiruv: oyna ochiladi, `pos.in1.uz` ga login o'tadi.
6. Commit:
   ```bash
   git add macos .gitignore
   git commit -m "chore(macos): Mac'da ishga tushirish uchun macOS target"
   ```

### 2-qadam — Git / GitHub tartibi

InVan 2 da: lokal `ayyubxon` → GitHub `main` (`git push origin ayyubxon:main`) + GitLab `ayyubxon`.
InVan 1 da soddaroq: lokal `main` → GitHub `main`:
```bash
git push origin main
```
GitLab keyin qo'shilsa, InVan 2 dagi "dual push" qoidasi (ikkalasiga birga) shu yerda ham amal qiladi.

`gh` tokenida `workflow` scope bor — `.github/workflows/*` ni HTTPS orqali push qilish uchun aynan shu kerak.

### 3-qadam — `windows/CMakeLists.txt` (MSVC coroutine tuzatishi)

`add_definitions(-DUNICODE -D_UNICODE)` qatoridan (hozir `:33`) KEYIN qo'shing:
```cmake
# Yangi MSVC <experimental/coroutine> ni hard-error qiladi (STL1011).
# Ba'zi plaginlar hali o'shani ishlatadi — build buzilmasligi uchun deprecation'ni jimlatamiz.
add_definitions(-D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)
```
InVan 2 da bu 2026-06-17 da (`9910222`) `windows-latest` buzilganda qo'shilgan. InVan 1 da `permission_handler` yo'q, lekin zarar qilmaydi — oldindan qo'yib qo'yish yaxshi.

### 4-qadam — `installer.iss` (repo ildizida)

```ini
; Inno Setup script for InVan POS (InVan 1)
; Compiled by GitHub Actions on Windows runner.
; Version is injected via /DMyAppVersion="..." flag from the workflow.

#define MyAppName "InVan POS"
#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif
#define MyAppPublisher "Invan Soft"
#define MyAppExeName "invan003.exe"
#define MyAppURL "https://github.com/Invan-Soft/pos-invan-1"

[Setup]
AppId={{EC687DDB-2099-4225-962C-9E3C0297CDBF}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\InVan POS
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=installers
OutputBaseFilename=invan1-{#MyAppVersion}
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
ArchitecturesAllowed=x64
WizardStyle=modern
PrivilegesRequired=admin
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{userdesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
```

InVan 2 dan farqlar: `MyAppName` ("InVan POS" — `lib/main.dart:86` oyna sarlavhasi bilan bir xil), `MyAppExeName` (`invan003.exe` — `windows/CMakeLists.txt:7` `BINARY_NAME`), `MyAppURL`, `AppId`, `DefaultDirName`, `OutputBaseFilename` (`invan1-1.0.0+42.exe` — InVan 2 ning `1.1.2+124.exe` bilan adashmaslik uchun).

⚠️ **AppId haqida.** Yuqoridagi GUID `uuidgen` bilan yangi yaratilgan. Agar InVan 1 ilgari do'konlarga Inno Setup o'rnatuvchisi bilan tarqatilgan bo'lsa, **o'sha eski `.iss` dagi AppId ni qo'ying** — shunda yangi versiya eskisining ustiga o'rnatiladi. AppId boshqa bo'lsa Windows uni alohida dastur deb hisoblaydi ("Dasturlar" ro'yxatida ikkita InVan POS). AppId bir marta tanlangach hech qachon o'zgartirilmaydi.

⚠️ `windows/runner/Runner.rc:92-98` (`CompanyName "com.example"`, `ProductName "invan003"`) ga **tegmang**: Windows'da `path_provider` papkalari shu nomlardan yasaladi (Odoo forkida shu sabab bilan ProductName ataylab o'zgartirilgan edi — bu yerda esa do'konlardagi mavjud ma'lumot yo'li o'zgarib ketadi).

### 5-qadam — `.github/workflows/release.yml`

```yaml
name: Release Windows Build (InVan 1)

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build-windows:
    runs-on: windows-2022

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Extract version from pubspec.yaml
        id: version
        shell: pwsh
        run: |
          $line = (Select-String -Path pubspec.yaml -Pattern '^version:\s*(.+)$').Matches.Groups[1].Value.Trim()
          echo "full=$line" >> $env:GITHUB_OUTPUT

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: '3.41.3'
          cache: true

      - name: Flutter info
        run: flutter --version

      - name: Install dependencies
        run: flutter pub get

      # InVan 2 dagi TELEGRAM_BOT_TOKEN / TELEGRAM_CHANNEL_ID / FISCAL_API_TOKEN dart-define lari
      # bu yerda yo'q: kodda String.fromEnvironment ishlatilmaydi (Odoo forkida ham olib tashlangan, 2e05a6c).
      - name: Build Windows release
        run: flutter build windows --release

      - name: Compile installer with Inno Setup
        shell: pwsh
        run: |
          & "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe" `
            /DMyAppVersion="${{ steps.version.outputs.full }}" `
            installer.iss

      - name: Upload installer as artifact
        uses: actions/upload-artifact@v4
        with:
          name: pos-invan-1-${{ steps.version.outputs.full }}
          path: installers/*.exe

      - name: Create GitHub Release
        if: startsWith(github.ref, 'refs/tags/')
        uses: softprops/action-gh-release@v2
        with:
          files: installers/*.exe
          generate_release_notes: true
          name: ${{ steps.version.outputs.full }}
```

GitHub Secrets kerak emas. Release yaratish huquqi `permissions: contents: write` orqali keladi. Inno Setup 6 `windows-2022` runner'da oldindan o'rnatilgan.

### 6-qadam — pipeline'ni commit qilish va tagsiz sinash

```bash
git add .github/workflows/release.yml installer.iss windows/CMakeLists.txt
git commit -m "ci: Release Windows Build (GitHub Actions) + Inno Setup installer"
git push origin main
```

Tag qo'ymasdan sinash (`workflow_dispatch` — build + artifact bo'ladi, Release bo'lmaydi):
```bash
gh workflow run release.yml -R Invan-Soft/pos-invan-1
gh run list --workflow=release.yml -R Invan-Soft/pos-invan-1 --limit 1     # ID olish
gh run watch <ID> -R Invan-Soft/pos-invan-1
```
Yashil bo'lsa — Actions sahifasidagi artifact ichida `invan1-1.0.0+41.exe` bo'ladi. Bu qadam InVan 1 ning Windows'da 3.41.3 bilan umuman qurilishini tekshiradi (Mac'da buni tekshirib bo'lmaydi).

### 7-qadam — Versiya chiqarish (har relizda takrorlanadi)

Bu InVan 2 dagi `/release` skill'ining InVan 1 varianti.

1. `git status` toza, branch `main`.
2. Backend manzili PROD ekanini tekshiring: `lib/changes/services/api/api_provider.dart:12-13` (`baseUrl` = `pos.in1.uz`, `baseUrlDev` = `dev.in1.uz`) — kod qaysi birini ishlatayotganini `grep -rn baseUrlDev lib` bilan ko'ring.
3. `pubspec.yaml` `version:` ni oshiring: `1.0.0+41` → `1.0.0+42`. Build raqami do'konlardagidan katta bo'lishi shart va faqat o'sadi.
4. Commit + push:
   ```bash
   git commit -am "release: 1.0.0+42"
   git push origin main
   ```
5. Tag → build boshlanadi:
   ```bash
   git tag v1.0.0+42
   git push origin v1.0.0+42
   ```
   Tag nomi = `v` + pubspec'dagi versiya, aynan. (Exe nomi tag'dan emas, pubspec'dan olinadi — mos bo'lmasa chalkashadi.)
6. Kuzatish (10–20 daqiqa):
   ```bash
   gh run list --workflow=release.yml -R Invan-Soft/pos-invan-1 --limit 1
   gh run watch <ID> -R Invan-Soft/pos-invan-1
   ```
7. Natija: `https://github.com/Invan-Soft/pos-invan-1/releases/tag/v1.0.0+42` — ichida `invan1-1.0.0+42.exe`.
   ```bash
   gh release download v1.0.0+42 -R Invan-Soft/pos-invan-1 --pattern '*.exe' --dir ~/Downloads
   ```
8. Build yiqilsa:
   ```bash
   gh run view <ID> --log-failed -R Invan-Soft/pos-invan-1
   ```
   Tuzatish commit qilinadi, keyin tag qayta yaratiladi:
   ```bash
   git push origin :refs/tags/v1.0.0+42 && git tag -d v1.0.0+42
   git tag v1.0.0+42 && git push origin v1.0.0+42
   ```

### 8-qadam — Do'konlarga yetkazish (InVan 1 da InVan 2 dan FARQ QILADI)

| | InVan 2 | InVan 1 |
|--|---------|---------|
| Ilova yangilanishni qanday biladi | drawer "Yangilanish" → `GET {api}file` (`update_checker.dart:23`) | server socket `newVersion` hodisasi (`lib/features/home/home_page.dart:66-73`) |
| Faylni qayerdan oladi | `cdn.7i.uz/file/pos_<versiya>.exe` | `http://116.203.177.198:7000/<file>` → `C:/ProgramData/InVanPos/cache/invanPosSetup.exe` (`upg_bloc.dart:35-43`) |
| .exe serverga qanday chiqadi | `curl -X POST {api}upload/build -F version -F changelog -F file` | **POS kodidan ko'rinmaydi** — `pos.in1.uz` backend/admin qanday yuklashini aniqlash kerak |

Ya'ni GitHub Release tayyor bo'lgach InVan 1 uchun "qo'lda yuklash" qadami hozircha aniq emas. Bu aniqlanmaguncha `.exe` GitHub Release'dan qo'lda tarqatiladi.

### 9-qadam (ixtiyoriy) — `/release` skill va CLAUDE.md

InVan 2 dagi `.claude/skills/release/SKILL.md` ni InVan 1 ga nusxalab moslang:
- repo `Invan-Soft/pos-invan-1`, branch `main`, GitLab yo'q (dual push bo'limi olib tashlanadi);
- PROD/DEV tekshiruvi `api_provider.dart:12-13` ga;
- 5-bo'lim (backend yuklash) 8-qadamdagi InVan 1 mexanizmiga almashtiriladi.
Odoo forkida aynan shu qilingan (`16ab6d3`, `.claude/skills/release/SKILL.md`).

---

## 3. Gotchalar (InVan 2 tajribasidan)

- `runs-on: windows-2022` — `windows-latest` emas. Yangi VS/MSVC `<experimental/coroutine>` ni xato deb to'xtatadi (3-qadam bilan birga).
- Workflow'dagi `flutter-version: '3.41.3'` Mac'dagi versiya bilan bir xil turishi kerak. Mac'da Flutter yangilansa — workflow ham.
- Inno `AppId` doimiy. `OutputBaseFilename` ni keyin o'zgartirish mumkin, AppId ni — yo'q.
- Build raqami faqat o'sadi. Ikki loyiha alohida versiya oqimida (InVan 1 `1.0.0+4x`, InVan 2 `1.1.2+12x`) — bir-biriga tegmaydi.
- Bir kompyuterda ikkalasi tursa ham kesh aralashmaydi: `C:\ProgramData\InVanPos\` (InVan 1) va `InVanPos2\` (InVan 2).
- Mac'da Windows-only funksiyalar (chek fayllari, printer rasmi, yangilanish yuklash) ishlamaydi — InVan 2 da ham shunday, bu Mac'da ishlab chiqish uchun to'siq emas.
- `installers/` va `build/` git'ga tushmaydi (`.gitignore:48`, `:33`).

## 4. Ochiq savollar

- InVan 1 ning eski Windows o'rnatuvchisi qanday qurilgan (Inno? qaysi AppId?) — 4-qadamdagi ogohlantirish.
- `pos.in1.uz` backendiga yangi `.exe` qanday yuklanadi va `newVersion` socket hodisasi kim tomonidan yuboriladi — 8-qadam.
- InVan 1 uchun GitLab repo ochiladimi (InVan 2 dagi kabi dual push) — 2-qadam.

## 5. Qisqa checklist

- [ ] 1. `flutter create --platforms=macos .` + entitlements + Podfile 10.15 + `.gitignore` → `flutter run -d macos` ishladi
- [ ] 2. `git push origin main`
- [ ] 3. `windows/CMakeLists.txt` coroutine define
- [ ] 4. `installer.iss` (AppId qarori bilan)
- [ ] 5. `.github/workflows/release.yml`
- [ ] 6. push + `gh workflow run release.yml` — yashil
- [ ] 7. pubspec `1.0.0+42` → commit → push → `git tag v1.0.0+42` → push → Release'da `.exe`
- [ ] 8. Tarqatish mexanizmi aniqlandi (backend)
- [ ] 9. `/release` skill nusxasi
