# 电能波动 · Charger

**[English](README.md) | 中文**

> 一款 Android 全屏充电动画 App — 粒子从屏幕四周向中央能量圆圈汇聚，实时显示电量百分比与充电功率，灵感来自电动车充电仪表盘。

---

## 功能介绍

- **粒子动画** — 数百个青色粒子从屏幕四周向中央能量圆圈汇聚，接触圆圈时被「吸收」并触发脉冲光晕效果
- **实时电量百分比** — 通过读取 `BatteryManager` 的 `CHARGE_COUNTER` 显示小数精度电量（如 `87.34%`）；不支持的设备自动降级为随机跳动数字特效
- **实时充电功率** — 读取瞬时电流（`BATTERY_PROPERTY_CURRENT_NOW`）× 电压，实时显示充电功率（如 `23.5 W`），配套弧形功率计：功率高显橙色，接近充满渐变为青色，体验类似电动车充电仪表盘
- **插电自动启动** — `BroadcastReceiver` 监听 `ACTION_POWER_CONNECTED`，插入充电器后自动唤醒屏幕并启动 App
- **Kiosk 锁定模式** — 使用 Android `startLockTask()` 将 App 固定在屏幕，无法被意外退出；退出需长按 3 秒后通过锁屏密码验证
- **防息屏** — 唤醒锁前台服务 + `FLAG_KEEP_SCREEN_ON`，充电期间屏幕始终亮起
- **动画速度随充电状态联动** — 充电时旋转、呼吸光晕、数字跳动全部加速；拔出后自动降速，数字停止跳动
- **前台服务保活** — 锁屏、切换 App 后动画持续运行，通知栏保持前台服务图标

---

## 环境要求

| 项目 | 最低版本 |
|---|---|
| Android | 8.0（API 26） |
| Target SDK | 36（Android 16） |
| Flutter | 3.10+ |
| Dart | 3.0+ |

---

## 快速开始

```bash
git clone https://github.com/lllomh/Charger.git
cd Charger
flutter pub get
flutter run
```

构建 Release APK：

```bash
flutter build apk --split-per-abi --release
```

APK 输出目录：`build/app/outputs/flutter-apk/`

---

## 退出方式

在屏幕任意位置**长按 3 秒**，系统弹出锁屏密码 / 生物识别验证界面，验证通过后退出。

设备未设置锁屏密码时，长按 3 秒后直接退出。

---

## 自动构建 / CI

推送到 `main` 分支后，GitHub Actions 自动：

1. 构建三架构拆分 APK（armeabi-v7a · arm64-v8a · x86_64）
2. 创建以 `v{版本号}-{短 SHA}` 命名的 GitHub Release
3. 将所有 APK 作为资产附加到 Release

也可在仓库 **Actions** 标签页手动触发（`workflow_dispatch`）。

---

## 项目结构

```
lib/
├── main.dart                           # 入口，唤醒锁，前台任务初始化
├── models/particle.dart                # 粒子数据类 + 生成工厂
├── painters/particle_painter.dart      # CustomPainter，全部 Canvas 绘制逻辑
├── providers/battery_provider.dart     # 封装 battery_plus 的 ChangeNotifier
├── screens/charger_screen.dart         # 状态、动画控制器、定时器
└── services/foreground_task_handler.dart

android/.../com/henry/charger/
├── MainActivity.kt                     # Kiosk 通道、密码退出、精细电量、功率读取
├── ChargerReceiver.kt                  # ACTION_POWER_CONNECTED 广播接收
└── ChargerForegroundService.kt         # 前台服务 + 唤醒锁
```

---

## 权限说明

| 权限 | 用途 |
|---|---|
| `FOREGROUND_SERVICE` | 运行前台服务 |
| `FOREGROUND_SERVICE_SPECIAL_USE` | Android 14+ 前台服务类型声明 |
| `WAKE_LOCK` | 充电时保持 CPU 和屏幕唤醒 |
| `POST_NOTIFICATIONS` | 显示持久通知（Android 13+） |
| `RECEIVE_BOOT_COMPLETED` | 重启后重新注册广播接收器 |
| `USE_FULL_SCREEN_INTENT` | 在锁屏上方显示 App |
| `TURN_SCREEN_ON` | 插入充电器时唤醒屏幕 |

---

## 依赖库

| 包名 | 用途 |
|---|---|
| [`battery_plus`](https://pub.dev/packages/battery_plus) | 电量与充电状态 |
| [`flutter_foreground_task`](https://pub.dev/packages/flutter_foreground_task) | 前台服务管理 |
| [`wakelock_plus`](https://pub.dev/packages/wakelock_plus) | 屏幕常亮 |
| [`provider`](https://pub.dev/packages/provider) | 状态管理 |

---

## 开源协议

[MIT](LICENSE)
