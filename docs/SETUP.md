# Gusa — Developer machine setup

Run once per developer. When all four PCs pass `scripts/doctor.sh` and all four phones run the demo slice, Week 0 task W0.4 is done.

## 1. Tools

| Tool | Version | Notes |
|---|---|---|
| Flutter | pinned in `.fvmrc`, stable channel | `flutter --version` must match. Use FVM or install that exact version. |
| Android Studio | latest stable | Install SDK Platform 35 and 36, Build-Tools 35.0.0 or newer, Platform-Tools |
| JDK | 17 | You will not write Kotlin. Gradle still needs a JDK to build the APK. |
| GitHub CLI | latest | `gh auth login` |
| Node + Wrangler | only if `GUSA_AI=on` | Lane V only, and only if the AI flag is ever turned on |

## 2. A physical Android phone

Required for everyone. The emulator has no vibration motor, so the Tactile and Input lanes cannot verify anything without a phone, and the App lane cannot run the loop.

1. Enable Developer Options and USB debugging.
2. `adb devices` shows the phone.
3. Note the model and Android version in `docs/TEST-RESULTS.md` under Device matrix, plus whether `hasAmplitudeControl()` returns true.

## 3. Clone, build, install

```bash
git clone https://github.com/Kinjuriu/Gusa.git gusa
cd gusa
git checkout develop
flutter pub get
flutter run --dart-define=GUSA_USE_FAKES=true     # loop runs on fakes, no permissions needed
flutter run                                         # real ports: asks for microphone
```

## 4. Flags

| Flag | Default | Effect |
|---|---|---|
| `GUSA_USE_FAKES` | `false` | Every port is a fake. Braille cells print to the log, haptics log timings, voice returns canned text. |
| `GUSA_AI` | `off` | `on` switches the simplifier to the OpenAI-backed one via the proxy. Needs `GUSA_PROXY_URL` and `GUSA_PROXY_SECRET` in `.env.json`. |

## 5. Check everything

```bash
scripts/doctor.sh
```

It checks the Flutter version, Android SDK, JDK, a connected phone, and that `flutter analyze` is clean. Post its output in the Week 0 issue.
