package com.hokhelper.hok_helper_mobile

import android.content.Intent
import android.net.Uri
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
    }

    private fun openDiscordAuthorization(uri: Uri): Boolean {
        val discordPackages = listOf(
            "com.discord",
            "com.discord.beta",
            "com.discord.canary"
        )
        for (packageName in discordPackages) {
            val intent = Intent(Intent.ACTION_VIEW, uri).setPackage(packageName)
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                return true
            }
        }
        return false
    }
}
