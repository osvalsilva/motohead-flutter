package com.motohead.motohead_app

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.PowerManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "motohead/native"
        const val CRASH_FILE = "crash_native.txt"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        installCrashHandler()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "deviceInfo" -> result.success(deviceInfo())
                "readNativeCrash" -> {
                    val f = File(filesDir, CRASH_FILE)
                    result.success(if (f.exists()) f.readText() else null)
                }
                "clearNativeCrash" -> {
                    val f = File(filesDir, CRASH_FILE)
                    if (f.exists()) f.delete()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /// Captura exceções Java/Kotlin não tratadas (que fecham o app) e grava
    /// o stack trace em arquivo antes do processo morrer. O Dart lê esse
    /// arquivo no próximo boot e envia ao servidor junto com os logs.
    private fun installCrashHandler() {
        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                val ts = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())
                val text = buildString {
                    append("=== NATIVE CRASH ===\n")
                    append("time: $ts\n")
                    append("thread: ${thread.name}\n")
                    append("device: ${Build.MANUFACTURER} ${Build.MODEL} — Android ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})\n")
                    append("exception: ${throwable.javaClass.name}: ${throwable.message}\n")
                    append(Log.getStackTraceString(throwable))
                    append("\n")
                }
                val f = File(filesDir, CRASH_FILE)
                FileOutputStream(f, true).use { it.write(text.toByteArray()) }
            } catch (_: Throwable) {
            }
            defaultHandler?.uncaughtException(thread, throwable)
        }
    }

    /// Info do dispositivo + restrições do sistema que podem fechar o app
    /// (otimização de bateria, restrição de segundo plano).
    private fun deviceInfo(): Map<String, Any> {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val info = HashMap<String, Any>()
        info["manufacturer"] = Build.MANUFACTURER
        info["model"] = Build.MODEL
        info["android_release"] = Build.VERSION.RELEASE ?: ""
        info["sdk_int"] = Build.VERSION.SDK_INT
        info["isIgnoringBatteryOptimizations"] = pm.isIgnoringBatteryOptimizations(packageName)
        info["isBackgroundRestricted"] = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) am.isBackgroundRestricted else false
        } catch (e: Exception) {
            false
        }
        return info
    }
}
