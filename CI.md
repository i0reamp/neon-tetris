# CI — собрать игру без своего мака

Здесь два workflow для GitHub Actions, бесплатно на `macos-15` runner'ах.

- `.github/workflows/build.yml` — собирает проект и гоняет тесты на каждый
  push/PR. Запускается автоматически. Падает или зеленеет — видно сразу.
- `.github/workflows/testflight.yml` — ручной workflow, делает Release
  архив, экспортирует IPA и заливает в TestFlight. Требует пары секретов.

## Шаг 1. Просто проверить, что собирается

1. Создай пустой репозиторий на GitHub.
2. Положи туда содержимое этой папки:
   ```bash
   cd /path/to/tiphone
   git init
   git add .
   git commit -m "initial"
   git branch -M main
   git remote add origin git@github.com:YOU/NeonTetris.git
   git push -u origin main
   ```
3. Открой репозиторий → вкладка **Actions**. Сразу запустится **Build & Test**.
4. Через ~5–10 минут получишь зелёную галку (или красные логи, если я где-то
   ошибся — приноси сюда, починим).

На этом этапе у тебя есть подтверждение, что проект чистый. Ставить на
устройство ещё нельзя.

## Шаг 2. Залить в TestFlight через CI

Это требует **Apple Developer Program** ($99/год) и одной серии секретов в
GitHub. Пошагово.

### 2.1. Получить ключ App Store Connect API

1. Зайди на <https://appstoreconnect.apple.com/access/integrations/api>.
2. Tab **Team Keys** → `+` → Имя `GitHub CI`, доступ `Developer`.
3. Скачай `.p8` файл — **больше его скачать нельзя**.
4. Запиши: **Key ID** (10 символов), **Issuer ID** (UUID наверху страницы).

### 2.2. Создать App ID и провижн-профиль

1. В Xcode (или на mac-руке у друга на 10 минут):
   - Открой `NeonTetris.xcodeproj`.
   - Поменяй `PRODUCT_BUNDLE_IDENTIFIER` в Signing & Capabilities, например
     на `com.tvoy.neontetris`.
   - Выбери Team. Xcode автоматически создаст провижн-профиль на
     <https://developer.apple.com>.
2. Альтернатива без мака: вручную создать App ID на
   developer.apple.com → Identifiers → +, и App Store provisioning profile
   на Profiles → +. Скачай `.mobileprovision`.

### 2.3. Экспортировать distribution-сертификат

Тут нужен Mac хотя бы на 15 минут (свой, друга, в облаке):

1. Keychain Access → Certificate Assistant → Request a Certificate from a
   Certificate Authority. Сохрани `.certSigningRequest`.
2. На <https://developer.apple.com/account/resources/certificates>:
   `+` → Apple Distribution → загрузи CSR → скачай `.cer`.
3. Двойной клик по `.cer` — он добавится в Keychain.
4. В Keychain найди сертификат, правый клик → Export → формат `.p12`,
   задай пароль. Сохрани файл.

### 2.4. Закодировать всё в base64 для GitHub секретов

На любой машине (хоть Linux):

```bash
base64 -w0 cert.p12 > cert.p12.b64
base64 -w0 profile.mobileprovision > profile.b64
cat AuthKey_XXXXXXXXXX.p8     # просто скопируй содержимое
```

### 2.5. Завести секреты в GitHub

Settings → Secrets and variables → Actions → **New repository secret**.
Создай по очереди:

| Имя | Что туда положить |
|-----|---|
| `BUILD_CERTIFICATE_BASE64` | содержимое `cert.p12.b64` |
| `BUILD_CERTIFICATE_PASSWORD` | пароль, которым ты экспортил `.p12` |
| `PROVISIONING_PROFILE_BASE64` | содержимое `profile.b64` |
| `KEYCHAIN_PASSWORD` | любая случайная строка (CI заведёт временный keychain) |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID из 2.1 |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer ID из 2.1 |
| `APP_STORE_CONNECT_API_PRIVATE_KEY` | содержимое `.p8` файла целиком, включая `-----BEGIN PRIVATE KEY-----` |
| `TEAM_ID` | 10 символов твоего Apple Team ID |
| `BUNDLE_IDENTIFIER` | например `com.tvoy.neontetris` |

### 2.6. Запустить workflow

GitHub Actions → **TestFlight** → **Run workflow**. По умолчанию build
number берётся из `github.run_number` — можно переопределить, но он должен
быть **строго больше предыдущего успешного**, иначе App Store Connect
отклонит загрузку.

Через 15–25 минут билд появится в App Store Connect → твоё приложение →
TestFlight → Builds. Дальше — как в [TESTFLIGHT.md](TESTFLIGHT.md): отвечаешь
на вопросник про шифрование, добавляешь себя в Internal Testing, ставишь
TestFlight на iPhone, принимаешь invite.

## Часто отваливается на

- **`Code signing is required for product type...`** — забыл секрет
  `BUILD_CERTIFICATE_BASE64` или провижн-профиль не для того bundle ID.
- **`No profiles for 'com.example.NeonTetris' were found`** — bundle ID в
  Xcode-проекте не совпадает с тем, под который выписан профиль. Поменяй
  локально и пушни.
- **`Build number must be greater than previous`** — увеличь build number
  в Xcode или передай через `workflow_dispatch` ввод.
- **`Invalid distribution certificate`** — `.p12` экспортирован без
  private key. Перешли с галочкой "include private key".

## Поиграть в браузере (без iPhone и без Apple Developer)

Третий workflow — **`.github/workflows/simulator.yml`** — собирает `.app`
для iOS Simulator и кладёт его в Actions artifacts. Это нужно если у тебя
вообще нет iPhone или нет Apple Developer аккаунта.

1. Actions → **Simulator build + screenshots** → **Run workflow**. Можно
   выбрать модель симулятора (по умолчанию iPhone 16 Pro).
2. Через ~10 минут на странице workflow run появятся два артефакта:
   - `NeonTetris-Simulator-app` — `NeonTetris-Simulator.zip` (внутри
     `NeonTetris.app` бандл для симулятора).
   - `NeonTetris-Screenshots` — 4 PNG со splash/game/pause экранами,
     заскриншоченные напрямую из симулятора через `xcrun simctl io`.
3. Скачай zip → загружаешь в <https://appetize.io>:
   - Sign up (free trial — 30 минут в месяц).
   - "Upload App" → распакованный `NeonTetris.app` (либо сам zip — они
     умеют).
   - Получишь URL вида `https://appetize.io/app/<id>`. Откроется
     симулятор iOS прямо в браузере, играешь мышью.
4. После 30 бесплатных минут — $40/мес за безлимит, или просто
   перезаливай новой бесплатной попыткой (Appetize не банит за это).

> Appetize-симулятор медленнее реального устройства, нет настоящей
> хаптики, и нельзя проверить TestFlight-флоу. Но визуальную часть и
> игровую механику посмотришь.

## Альтернативные подходы

- **Xcode Cloud** — Apple-нативное CI. Нужен Mac, чтобы один раз
  настроить. Дальше работает само, бесплатные часы включены в
  Apple Developer Program.
- **Fastlane match + GitHub Actions** — те же runners, но матч хранит
  сертификаты в приватном git-репо, не нужно копаться с base64. Удобнее
  для команды.
- **Bitrise / Codemagic** — платные CI с UI для iOS, проще настроить
  чем raw GitHub Actions, но и платно после free tier.
