import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef ApplicationSupportDirectoryProvider = Future<Directory> Function();

class AvatarBackgroundStore {
  AvatarBackgroundStore({
    required this.preferences,
    ApplicationSupportDirectoryProvider? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const preferenceKey = 'profile_avatar_background_path';
  static const _filePrefix = 'profile_avatar_background';

  final SharedPreferences preferences;
  final ApplicationSupportDirectoryProvider _directoryProvider;

  static Future<AvatarBackgroundStore> create({
    ApplicationSupportDirectoryProvider? directoryProvider,
  }) async {
    return AvatarBackgroundStore(
      preferences: await SharedPreferences.getInstance(),
      directoryProvider: directoryProvider,
    );
  }

  Future<String?> readPath() async {
    final path = preferences.getString(preferenceKey)?.trim();
    if (path == null || path.isEmpty) {
      return null;
    }
    if (await File(path).exists()) {
      return path;
    }

    await preferences.remove(preferenceKey);
    return null;
  }

  Future<String> save(XFile source) async {
    final directory = await _directoryProvider();
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    final extension = _safeExtension(
      source.name.isEmpty ? source.path : source.name,
    );
    final target = File(
      '${directory.path}${Platform.pathSeparator}$_filePrefix$extension',
    );
    final previousPath = preferences.getString(preferenceKey)?.trim();
    final bytes = await source.readAsBytes();
    await target.writeAsBytes(bytes);
    await preferences.setString(preferenceKey, target.path);

    if (previousPath != null &&
        previousPath.isNotEmpty &&
        previousPath != target.path) {
      await _deleteIfPresent(previousPath);
    }
    return target.path;
  }

  Future<void> clear() async {
    final path = preferences.getString(preferenceKey)?.trim();
    await preferences.remove(preferenceKey);
    if (path != null && path.isNotEmpty) {
      await _deleteIfPresent(path);
    }
  }

  Future<void> _deleteIfPresent(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // A stale local file should not block the next background selection.
    }
  }

  String _safeExtension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) {
      return '.jpg';
    }
    final extension = name.substring(dot).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,5}$').hasMatch(extension)
        ? extension
        : '.jpg';
  }
}
