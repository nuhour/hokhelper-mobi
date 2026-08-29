import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

typedef CacheUsageReader = Future<AppCacheUsage> Function();
typedef CacheClearer = Future<void> Function();

class AppCacheUsage {
  const AppCacheUsage({required this.bytes, required this.fileCount});

  const AppCacheUsage.empty() : bytes = 0, fileCount = 0;

  final int bytes;
  final int fileCount;

  String get formattedSize => formatCacheBytes(bytes);
}

class AppCacheService {
  AppCacheService({CacheUsageReader? usageReader, CacheClearer? clearer})
    : _usageReader = usageReader ?? _readDefaultCacheUsage,
      _clearer = clearer ?? _clearDefaultCache;

  final CacheUsageReader _usageReader;
  final CacheClearer _clearer;

  Future<AppCacheUsage> measure() => _usageReader();

  Future<void> clear() => _clearer();
}

Future<AppCacheUsage> _readDefaultCacheUsage() async {
  final cacheManager = DefaultCacheManager();
  final probe = await cacheManager.config.fileSystem.createFile(
    '.hokhelper-cache-size-probe',
  );
  final cacheDirectory = Directory(probe.path).parent;
  try {
    await probe.delete();
  } on FileSystemException {
    // 统计前的探针文件删除失败时，不影响后续缓存目录扫描。
  }
  if (!await cacheDirectory.exists()) {
    return const AppCacheUsage.empty();
  }

  var bytes = 0;
  var fileCount = 0;
  await for (final entity in cacheDirectory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) {
      continue;
    }
    try {
      bytes += await entity.length();
      fileCount++;
    } on FileSystemException {
      // 单个缓存文件在统计期间消失时，保留已统计的可用结果。
    }
  }

  return AppCacheUsage(bytes: bytes, fileCount: fileCount);
}

Future<void> _clearDefaultCache() async {
  Object? clearError;
  StackTrace? clearStackTrace;
  try {
    await DefaultCacheManager().emptyCache();
  } catch (error, stackTrace) {
    clearError = error;
    clearStackTrace = stackTrace;
  } finally {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  if (clearError != null) {
    Error.throwWithStackTrace(clearError, clearStackTrace!);
  }
}

String formatCacheBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }

  const units = ['KB', 'MB', 'GB'];
  var value = bytes / 1024;
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final decimals = value >= 10 ? 0 : 1;
  return '${value.toStringAsFixed(decimals)} ${units[unitIndex]}';
}
