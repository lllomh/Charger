package com.henry.charger

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.math.abs

class MainActivity : FlutterActivity() {
    private val kioskChannel = "com.henry.charger/kiosk"
    private val requestExitCode = 4242

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            if (km.isKeyguardLocked) {
                km.requestDismissKeyguard(this, null)
            }
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, kioskChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startKiosk" -> {
                        try {
                            if (!isKioskActive()) startLockTask()
                            result.success(isKioskActive())
                        } catch (e: Exception) {
                            result.error("KIOSK_FAILED", e.message, null)
                        }
                    }
                    "isKioskActive" -> result.success(isKioskActive())
                    "requestExit" -> handleRequestExit(result)
                    "getFinePercent" -> result.success(computeFinePercent())
                    "getPowerWatts" -> result.success(computePowerWatts())
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleRequestExit(result: MethodChannel.Result) {
        val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (!km.isKeyguardSecure) {
            // 设备未设锁屏密码，直接退出
            exitApp()
            result.success(true)
            return
        }
        @Suppress("DEPRECATION")
        val intent: Intent? = km.createConfirmDeviceCredentialIntent(
            "退出充电动画",
            "请输入锁屏密码以退出"
        )
        if (intent != null) {
            startActivityForResult(intent, requestExitCode)
            result.success(true)
        } else {
            result.success(false)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == requestExitCode && resultCode == RESULT_OK) {
            exitApp()
        }
    }

    private fun exitApp() {
        try {
            if (isKioskActive()) stopLockTask()
        } catch (_: Exception) {
        }
        finishAndRemoveTask()
    }

    private fun computeFinePercent(): Double? {
        return try {
            val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            val counter = bm.getLongProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER)
            if (counter <= 0L) return null
            val full = readChargeFullUah() ?: return null
            val pct = counter.toDouble() / full.toDouble() * 100.0
            if (pct.isFinite() && pct in 0.0..100.0) pct else null
        } catch (_: Throwable) {
            null
        }
    }

    private fun computePowerWatts(): Double? {
        return try {
            val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            val currentMicroA = bm.getLongProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
            if (currentMicroA == Long.MIN_VALUE) return null
            val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                ?: return null
            val voltageMv = batteryIntent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1)
            if (voltageMv <= 0) return null
            val watts = abs(currentMicroA) / 1_000_000.0 * voltageMv / 1000.0
            if (watts.isFinite() && watts >= 0) watts else null
        } catch (_: Throwable) {
            null
        }
    }

    private fun readChargeFullUah(): Long? {
        val candidates = listOf(
            "/sys/class/power_supply/battery/charge_full",
            "/sys/class/power_supply/battery/charge_full_design",
            "/sys/class/power_supply/bms/charge_full"
        )
        for (p in candidates) {
            try {
                val v = File(p).readText().trim().toLongOrNull() ?: continue
                if (v > 0) return v
            } catch (_: Throwable) {
            }
        }
        return null
    }

    private fun isKioskActive(): Boolean {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
        } else {
            @Suppress("DEPRECATION")
            am.isInLockTaskMode
        }
    }

    override fun onResume() {
        super.onResume()
        if (!isKioskActive()) {
            try {
                startLockTask()
            } catch (_: Exception) {
            }
        }
    }
}
