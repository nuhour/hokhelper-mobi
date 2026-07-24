import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/auth/data/oauth_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('creates a provider-bound state and consumes it once', () async {
    final store = OAuthStateStore();
    final state = await store.create('Google');

    expect(
      state,
      matches(RegExp(r'^hokhelper-mobile\.google\.[A-Za-z0-9_-]{43}$')),
    );
    expect(await store.consume(provider: 'google', state: state), isTrue);
    expect(await store.consume(provider: 'google', state: state), isFalse);
  });

  test('rejects a state created for another provider', () async {
    final store = OAuthStateStore();
    final state = await store.create('google');

    expect(await store.consume(provider: 'discord', state: state), isFalse);
  });
}
