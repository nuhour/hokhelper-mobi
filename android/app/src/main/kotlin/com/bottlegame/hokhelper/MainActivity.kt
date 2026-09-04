package com.bottlegame.hokhelper

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager

class MainActivity : FlutterActivity() {
    private var standardIntegrityManager: StandardIntegrityManager? = null
    private var standardIntegrityTokenProvider:
        StandardIntegrityManager.StandardIntegrityTokenProvider? = null

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
            "hokhelper/integrity"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "prepare" -> prepareIntegrityToken(call, result)
                "getToken" -> requestIntegrityToken(call, result)
                else -> result.notImplemented()
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

    private fun prepareIntegrityToken(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val cloudProjectNumber = readCloudProjectNumber(call)
        if (cloudProjectNumber == null) {
            result.error(
                "INTEGRITY_CONFIGURATION",
                "App integrity cloud project is not configured",
                null
            )
            return
        }

        val existingProvider = standardIntegrityTokenProvider
        if (existingProvider != null) {
            result.success(true)
            return
        }

        try {
            getStandardIntegrityManager()
                .prepareIntegrityToken(
                    StandardIntegrityManager.PrepareIntegrityTokenRequest.builder()
                        .setCloudProjectNumber(cloudProjectNumber)
                        .build()
                )
                .addOnSuccessListener { provider ->
                    standardIntegrityTokenProvider = provider
                    result.success(true)
                }
                .addOnFailureListener { exception ->
                    standardIntegrityTokenProvider = null
                    result.error(
                        "INTEGRITY_PREPARE_FAILED",
                        integrityErrorMessage(exception),
                        null
                    )
                }
        } catch (exception: Exception) {
            result.error(
                "INTEGRITY_PREPARE_FAILED",
                integrityErrorMessage(exception),
                null
            )
        }
    }

    private fun requestIntegrityToken(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val cloudProjectNumber = readCloudProjectNumber(call)
        val requestHash = call.argument<String>("requestHash")?.trim().orEmpty()
        if (cloudProjectNumber == null || requestHash.isEmpty()) {
            result.error(
                "INTEGRITY_CONFIGURATION",
                "App integrity request is incomplete",
                null
            )
            return
        }

        val request = try {
            StandardIntegrityManager.StandardIntegrityTokenRequest.builder()
                .setRequestHash(requestHash)
                .build()
        } catch (exception: Exception) {
            result.error(
                "INTEGRITY_REQUEST_FAILED",
                integrityErrorMessage(exception),
                null
            )
            return
        }

        val provider = standardIntegrityTokenProvider
        if (provider != null) {
            requestIntegrityToken(provider, requestHash, request, result)
            return
        }

        prepareIntegrityToken(
            call,
            object : MethodChannel.Result {
                override fun success(response: Any?) {
                    val preparedProvider = standardIntegrityTokenProvider
                    if (preparedProvider == null) {
                        result.error(
                            "INTEGRITY_PREPARE_FAILED",
                            "App integrity provider is unavailable",
                            null
                        )
                    } else {
                        requestIntegrityToken(
                            preparedProvider,
                            requestHash,
                            request,
                            result
                        )
                    }
                }

                override fun error(code: String, message: String?, details: Any?) {
                    result.error(code, message, details)
                }

                override fun notImplemented() {
                    result.notImplemented()
                }
            }
        )
    }

    private fun requestIntegrityToken(
        provider: StandardIntegrityManager.StandardIntegrityTokenProvider,
        requestHash: String,
        request: StandardIntegrityManager.StandardIntegrityTokenRequest,
        result: MethodChannel.Result
    ) {
        try {
            provider.request(request)
                .addOnSuccessListener { response ->
                    result.success(
                        mapOf(
                            "provider" to "play_integrity",
                            "token" to response.token(),
                            "requestHash" to requestHash
                        )
                    )
                }
                .addOnFailureListener { exception ->
                    // 提供器可能已经过期，下一次请求会重新预热。
                    standardIntegrityTokenProvider = null
                    result.error(
                        "INTEGRITY_TOKEN_FAILED",
                        integrityErrorMessage(exception),
                        null
                    )
                }
        } catch (exception: Exception) {
            standardIntegrityTokenProvider = null
            result.error(
                "INTEGRITY_TOKEN_FAILED",
                integrityErrorMessage(exception),
                null
            )
        }
    }

    private fun readCloudProjectNumber(call: MethodCall): Long? {
        val value = call.argument<Number>("cloudProjectNumber")?.toLong() ?: return null
        return value.takeIf { it > 0L }
    }

    private fun getStandardIntegrityManager(): StandardIntegrityManager {
        val manager = standardIntegrityManager
        if (manager != null) {
            return manager
        }
        return IntegrityManagerFactory.createStandard(applicationContext).also {
            standardIntegrityManager = it
        }
    }

    private fun integrityErrorMessage(exception: Exception): String {
        return "App integrity provider is unavailable (${exception.javaClass.simpleName})"
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
