# 电能波动 · Charger

**English | [中文](README_CN.md)**

> A full-screen charging animation app for Android — particles flow from the screen edges toward a central energy circle, displaying real-time battery percentage and charging power. Inspired by EV charger dashboards.

---

## Features

- **Particle animation** — hundreds of cyan particles stream from the screen edges toward the central circle, absorbed on contact and triggering a pulse glow
- **Real-time battery percentage** — shows fine-grained decimal percentage (e.g. `87.34%`) by reading `CHARGE_COUNTER` from `BatteryManager`; falls back to animated jitter digits on unsupported devices
- **Real-time charging power** — reads instantaneous current (`BATTERY_PROPERTY_CURRENT_NOW`) × voltage to display live wattage (e.g. `23.5 W`), with an arc gauge that shifts from orange (high power) to cyan (near full) — just like an EV charger display
- **Auto-launch on plug-in** — `BroadcastReceiver` listens for `ACTION_POWER_CONNECTED` and starts the app automatically when a charger is connected
- **Kiosk / screen-pin mode** — the app locks itself using Android's `startLockTask()` API so it cannot be dismissed by accident; exiting requires a 3-second long press followed by the device lock-screen password
- **Screen always on** — wake lock foreground service + `FLAG_KEEP_SCREEN_ON` keep the display alive while charging
- **Adaptive animation speed** — rotation, breathing glow, and digit jitter all run faster while charging, slow down when unplugged
- **Foreground service** — keeps the animation alive when the screen is locked or the user switches apps

---

## Requirements

| Item | Minimum |
|---|---|
| Android | 8.0 (API 26) |
| Target SDK | 36 (Android 16) |
| Flutter | 3.10+ |
| Dart | 3.0+ |

---

## Getting Started

```bash
git clone https://github.com/lllomh/Charger.git
cd Charger
flutter pub get
flutter run
```

Build a release APK:

```bash
flutter build apk --split-per-abi --release
```

Output: `build/app/outputs/flutter-apk/`

---

## Exiting the App

Long-press anywhere on the screen for **3 seconds**. The system will show a lock-screen credential prompt. The app exits only after successful verification.

If the device has no lock-screen password, the app exits immediately after the hold.

---

## CI / Auto Release

Pushing to `main` triggers a GitHub Actions workflow that:

1. Builds split APKs (armeabi-v7a · arm64-v8a · x86_64)
2. Creates a GitHub Release tagged `v{version}-{short SHA}`
3. Attaches all APKs as release assets

You can also trigger it manually from the **Actions** tab (`workflow_dispatch`).

---

## Architecture

```
lib/
├── main.dart                           # Entry point, wake lock, ForegroundTask init
├── models/particle.dart                # Particle data class + spawn factory
├── painters/particle_painter.dart      # CustomPainter — all canvas drawing
├── providers/battery_provider.dart     # ChangeNotifier wrapping battery_plus
├── screens/charger_screen.dart         # State, animation controllers, timers
└── services/foreground_task_handler.dart

android/.../com/henry/charger/
├── MainActivity.kt                     # Kiosk channel, credential exit, fine %, power W
├── ChargerReceiver.kt                  # ACTION_POWER_CONNECTED broadcast
└── ChargerForegroundService.kt         # Foreground service + wake lock
```

---

## Permissions

| Permission | Purpose |
|---|---|
| `FOREGROUND_SERVICE` | Run foreground service |
| `FOREGROUND_SERVICE_SPECIAL_USE` | Service type required on Android 14+ |
| `WAKE_LOCK` | Keep CPU and screen on while charging |
| `POST_NOTIFICATIONS` | Show persistent notification (Android 13+) |
| `RECEIVE_BOOT_COMPLETED` | Re-register receiver after device reboot |
| `USE_FULL_SCREEN_INTENT` | Display app over the lock screen |
| `TURN_SCREEN_ON` | Wake screen when charger is connected |

---

## Dependencies

| Package | Purpose |
|---|---|
| [`battery_plus`](https://pub.dev/packages/battery_plus) | Battery level & charging state |
| [`flutter_foreground_task`](https://pub.dev/packages/flutter_foreground_task) | Foreground service management |
| [`wakelock_plus`](https://pub.dev/packages/wakelock_plus) | Keep screen on |
| [`provider`](https://pub.dev/packages/provider) | State management |

---

## License

[MIT](LICENSE)
