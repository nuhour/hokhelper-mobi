import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/secure_token_store.dart';

final tokenStoreProvider = Provider<SecureTokenStore>((ref) {
  return SecureTokenStore();
});

final authSessionInvalidationProvider = StateProvider<int>((ref) {
  return 0;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);
  return ApiClient(
    tokenStore: tokenStore,
    onAuthFailure: (error) async {
      await tokenStore.clear();
      ref.read(authSessionInvalidationProvider.notifier).state++;
    },
  );
});
