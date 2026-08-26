package com.hokhelper.hok_helper_mobile

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // FlutterActivity 会把 intent 转发给 Flutter 引擎；同时保留最新
        // intent，确保应用已打开时收到的回调也能被插件或路由读取。
        setIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "hokhelper/open_url"
        ).setMethodCallHandler { call, result ->
            if (call.method != "openOAuthUrl") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val url = call.argument<String>("url")?.trim().orEmpty()
            val provider = call.argument<String>("provider")?.trim()?.lowercase().orEmpty()
            if (url.isEmpty()) {
                result.success(false)
                return@setMethodCallHandler
            }

            try {
                val uri = Uri.parse(url)
                val openedInProviderApp =
                    provider == "discord" && openDiscordAuthorization(uri)
                if (!openedInProviderApp) {
                    startActivity(Intent(Intent.ACTION_VIEW, uri))
                }
                result.success(true)
            } catch (_: Exception) {
                result.success(false)
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "hokhelper/media"
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveImage") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val bytes = call.argument<ByteArray>("bytes")
            val name = call.argument<String>("name").orEmpty()
            val mimeType = call.argument<String>("mimeType") ?: "image/png"
            if (bytes == null || name.isEmpty()) {
                result.success(false)
                return@setMethodCallHandler
            }
            try {
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, name)
                    put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                    put(
                        MediaStore.Images.Media.RELATIVE_PATH,
                        "${Environment.DIRECTORY_PICTURES}/HOKHelper"
                    )
                }
                val uri = contentResolver.insert(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                    values
                )
                if (uri == null) {
                    result.success(false)
                } else {
                    contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
                    result.success(true)
                }
            } catch (_: Exception) {
                result.success(false)
            }
        }
    }

    private fun openDiscordAuthorization(uri: Uri): Boolean {
        // 这里采用 Discord Social SDK 使用的 Android 跳转方式：将
        // https://discord.com/oauth2/authorize 转成
        // discord://action/oauth2/authorize 后交给 Discord 应用。
        // 保留完整查询参数，确保 PKCE 和 state 在应用间跳转时不丢失。
        // 若设备没有受支持的 Discord 版本，则回退到 HTTPS 浏览器流程。
        val discordPackages = listOf(
            "com.discord",
            "com.discord.beta",
            "com.discord.canary"
        )

        val discordDeepLink = uri.toString()
            .takeIf { it.startsWith("https://discord.com/oauth2/authorize") }
            ?.replaceFirst("https://discord.com", "discord://action")
            ?.let(Uri::parse)
        if (discordDeepLink != null) {
            for (packageName in discordPackages) {
                val packageIntent = Intent(Intent.ACTION_VIEW, discordDeepLink)
                    .setPackage(packageName)
                if (packageIntent.resolveActivity(packageManager) != null) {
                    try {
                        startActivity(packageIntent)
                        return true
                    } catch (_: Exception) {
                        // 继续尝试其他 Discord 版本。
                    }
                }
            }
        }

        for (packageName in discordPackages) {
            val packageIntent = Intent(Intent.ACTION_VIEW, uri)
                .addCategory(Intent.CATEGORY_BROWSABLE)
                .addCategory(Intent.CATEGORY_DEFAULT)
                .setPackage(packageName)
            if (packageIntent.resolveActivity(packageManager) != null) {
                try {
                    startActivity(packageIntent)
                    return true
                } catch (_: Exception) {
                    // 继续尝试其他 Discord 版本。
                }
            }
        }
        return false
    }
}
