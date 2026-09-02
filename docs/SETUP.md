# Gusa — Developer machine setup

Run once per developer. When all four PCs pass `scripts/doctor.sh` and all four phones run the demo slice, Week 0 task W0.4 is done.

## 1. Tools

| Tool | Version | Notes |
|---|---|---|
| Flutter | pinned in `.fvmrc`, stable channel | `flutter --version` must match. Use FVM or install that exact version. |
| Android Studio | latest stable | Install SDK Platform 35 and 36, Build-Tools 35.0.0 or newer, Platform-Tools |
| JDK | 17 | You will not write Kotlin. Gradle still needs a JDK to build the APK. |
| GitHub CLI | latest | `gh auth login` |
| Node 20+ and Wrangler | latest | Lane V builds and deploys the Worker. Others need it only to run `wrangler dev` locally. |

## 2. A physical Android phone

Required for everyone. The emulator has no vibration motor, so the Tactile and Input lanes cannot verify anything without a phone, and the App lane cannot run the loop.

1. Enable Developer Options and USB debugging.
2. `adb devices` shows the phone.
3. Post the model, Android version, and whether `hasAmplitudeControl()` returns true in the Week 0 issue. Ian copies them into `docs/TEST-RESULTS.md`.

## 3. Clone, build, install

```bash
git clone https://github.com/Kinjuriu/Gusa.git gusa
cd gusa
git checkout develop            # wait until the Week 0 issue says develop is ready (W0.1 merged)
flutter pub get
flutter run --dart-define=GUSA_USE_FAKES=true     # loop runs on fakes, no permissions needed
cp .env.example .env.json                           # GUSA_PROXY_URL and GUSA_PROXY_SECRET from Lane V
flutter run --dart-define-from-file=.env.json      # real ports: asks for microphone, calls the Worker
```

## 4. Flags

| Flag | Default | Effect |
|---|---|---|
| `GUSA_USE_FAKES` | `false` | Every port is a fake. Braille cells print to the log, haptics log timings, voice returns canned text. |
| `GUSA_CLOUD_VOICE` | `on` | `off` forces Android text-to-speech for every reply. |
| `GUSA_AI` | `on` | `off` forces the rule-based shortener and generic replies. Use it for a demo with no network. `on` needs `GUSA_PROXY_URL` and `GUSA_PROXY_SECRET` in `.env.json`. |

## 5. Check everything

```bash
scripts/doctor.sh
```

It checks the Flutter version, Android SDK, JDK, a connected phone, and that `flutter analyze` is clean. Post its output in the Week 0 issue.
