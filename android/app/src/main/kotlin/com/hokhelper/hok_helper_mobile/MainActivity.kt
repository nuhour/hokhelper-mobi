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
        // Discord's mobile authorization handoff uses the same deep link as
        // its official Android authentication activity:
        // discord://action/oauth2/authorize?... . The old guessed URI forms
        // do not match the Discord mobile client's intent filter and therefore
        // always fall through to Chrome.
        val deepLink = uri.buildUpon()
            .scheme("discord")
            .authority("action")
            .path("/oauth2/authorize")
            .build()
        val deepLinkIntent = Intent(Intent.ACTION_VIEW, deepLink)
            .addCategory(Intent.CATEGORY_BROWSABLE)
            .addCategory(Intent.CATEGORY_DEFAULT)
        if (deepLinkIntent.resolveActivity(packageManager) != null) {
            try {
                startActivity(deepLinkIntent)
                return true
            } catch (_: Exception) {
                // Fall through to the package-specific and browser paths.
            }
        }

        val discordPackages = listOf(
            "com.discord",
            "com.discord.beta",
            "com.discord.canary"
        )
        for (packageName in discordPackages) {
            val packageIntent = Intent(Intent.ACTION_VIEW, deepLink)
                .addCategory(Intent.CATEGORY_BROWSABLE)
                .addCategory(Intent.CATEGORY_DEFAULT)
                .setPackage(packageName)
            if (packageIntent.resolveActivity(packageManager) != null) {
                try {
                    startActivity(packageIntent)
                    return true
                } catch (_: Exception) {
                    // Continue looking for another installed Discord flavor.
                }
            }

            // Some Discord distributions expose only the HTTPS intent filter;
            // prefer it over Chrome when that package is installed.
            val webIntent = Intent(Intent.ACTION_VIEW, uri)
                .addCategory(Intent.CATEGORY_BROWSABLE)
                .addCategory(Intent.CATEGORY_DEFAULT)
                .setPackage(packageName)
            if (webIntent.resolveActivity(packageManager) != null) {
                try {
                    startActivity(webIntent)
                    return true
                } catch (_: Exception) {
                    // Continue looking for another installed Discord flavor.
                }
            }
        }
        return false
    }
}
