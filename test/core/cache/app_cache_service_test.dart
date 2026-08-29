import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/cache/app_cache_service.dart';

void main() {
  test('formats cache sizes for the confirmation copy', () {
    expect(formatCacheBytes(0), '0 B');
    expect(formatCacheBytes(1023), '1023 B');
    expect(formatCacheBytes(1024), '1.0 KB');
    expect(formatCacheBytes(10 * 1024), '10 KB');
    expect(formatCacheBytes(3 * 1024 * 1024), '3.0 MB');
  });

  test(
    'delegates measurement and clearing to the configured cache adapter',
    () async {
      var clearCalled = false;
      const usage = AppCacheUsage(bytes: 4096, fileCount: 2);
      final service = AppCacheService(
        usageReader: () async => usage,
        clearer: () async {
          clearCalled = true;
        },
      );

      expect(await service.measure(), usage);
      await service.clear();
      expect(clearCalled, isTrue);
    },
  );
}
