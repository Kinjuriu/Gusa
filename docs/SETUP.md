# Gusa — Developer machine setup

Every developer runs this once. When all four PCs pass `scripts/doctor.sh`, Week 0 task W0.9 is done.

## 1. Tools

| Tool | Version | Notes |
|---|---|---|
| Flutter | pinned in `.fvmrc` (stable) | `flutter --version` must match. Use FVM or install that exact version. |
| Android Studio | latest stable | Install SDK Platform 35 and 36, Build-Tools 35.0.0+, Platform-Tools |
| JDK | 17 | Gradle needs it. `java -version` |
| Node | 20+ | Proxy only (Lane C, but everyone runs `wrangler dev` sometimes) |
| Wrangler | latest | `npm i -g wrangler` |
| GitHub CLI | latest | `gh auth login` — used by scripts and for PRs |

## 2. A physical Android phone

Required. The emulator has no vibration motor, so nothing in the Tactile lane can be verified without a phone.

1. Enable Developer Options and USB debugging.
2. `adb devices` shows the phone.
3. Note the model and Android version in `docs/TEST-RESULTS.md` under Device matrix.

## 3. Clone and build

```bash
git clone https://github.com/Kinjuriu/Gusa.git gusa
cd gusa
git checkout develop
flutter pub get
flutter build apk --debug
flutter install            # onto the connected phone
```

## 4. Enable the accessibility service without touching Settings

```bash
scripts/enable-service.sh   # wraps: adb shell settings put secure enabled_accessibility_services <pkg>/<service>
```

## 5. Environment

Copy `.env.example` to `.env.json` (git-ignored) and fill:

```json
{ "GUSA_PROXY_URL": "https://gusa-dev.<account>.workers.dev", "GUSA_PROXY_SECRET": "<ask Lane C>" }
```

Run with `flutter run --dart-define-from-file=.env.json`. To work with no network and no keys: `flutter run --dart-define=GUSA_USE_FAKES=true`.

Nobody receives the OpenAI key. It lives only in Cloudflare Worker secrets.

## 6. Proxy locally (Lane C, optional for others)

```bash
cd proxy && npm ci && npm test && wrangler dev
```

## 7. Check everything

```bash
scripts/doctor.sh
```

It checks Flutter version, Android SDK, JDK, a connected phone, Node, wrangler, and that `flutter analyze` is clean. Post its output in the Week 0 issue.
