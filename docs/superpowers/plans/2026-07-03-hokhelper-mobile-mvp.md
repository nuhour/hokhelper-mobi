# HOK Helper Mobile MVP 1.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Android-first Flutter foundation for HOK Helper Mobile, backed by the existing Django `/hokx/` API, with login, region/language/theme state, and real-data core portal browsing.

**Architecture:** Create a Flutter app in the repository root using a layered structure: app shell, feature modules, repositories, and a shared core API client. Riverpod owns app state, Dio owns HTTP, secure storage owns JWT, and cached network images support image-heavy game content.

**Tech Stack:** Flutter, Dart, Riverpod, Dio, flutter_secure_storage, shared_preferences, go_router, cached_network_image, intl, existing Django `/hokx/` REST API.

---

## File Structure

Create a standard Flutter project in `/Users/nourhr/dev/pycharm/projects/hokhelper-mobi` and keep feature code under `lib/src`.

- Create: `pubspec.yaml` - Flutter package metadata and dependencies.
- Create: `analysis_options.yaml` - Dart lint configuration.
- Create: `.gitignore` - Flutter, Android, and IDE ignores.
- Create: `.env.example` - Environment keys for API base URL and API prefix.
- Create: `lib/main.dart` - App entrypoint.
- Create: `lib/src/app/hok_helper_app.dart` - Material app, router, theme, localization bootstrap.
- Create: `lib/src/app/router.dart` - `go_router` route table.
- Create: `lib/src/app/app_shell.dart` - Bottom-tab scaffold.
- Create: `lib/src/core/config/app_config.dart` - Build-time API configuration.
- Create: `lib/src/core/constants/regions.dart` - Region and language mapping.
- Create: `lib/src/core/network/api_client.dart` - Dio setup, auth header injection, response parsing.
- Create: `lib/src/core/network/api_error.dart` - Typed API errors.
- Create: `lib/src/core/network/api_envelope.dart` - Standard backend response envelope.
- Create: `lib/src/core/storage/secure_token_store.dart` - JWT storage.
- Create: `lib/src/core/storage/preferences_store.dart` - Region, language, and theme persistence.
- Create: `lib/src/core/theme/app_theme.dart` - Dark game visual system.
- Create: `lib/src/core/widgets/*` - Shared loading, empty, error, image, and card widgets.
- Create: `lib/src/features/auth/*` - Email login, registration, reset, auth state.
- Create: `lib/src/features/home/*` - Home aggregation screen and repository.
- Create: `lib/src/features/heroes/*` - Hero gallery/detail screens, models, repository.
- Create: `lib/src/features/content/*` - Skin, CG, and topic list/detail screens.
- Create: `lib/src/features/builds/*` - Build scheme explorer.
- Create: `lib/src/features/rankings/*` - Tier and ranking screens.
- Create: `lib/src/features/search/*` - Global search.
- Create: `lib/src/features/profile/*` - Profile screen.
- Create: `lib/src/features/settings/*` - Language, region, theme settings.
- Modify: `README.md` - Add mobile development commands and environment notes.

The plan below intentionally creates a working vertical slice first, then adds features. Each task should end with a focused commit.

---

### Task 1: Flutter Project Scaffold

**Files:**
- Create: `pubspec.yaml`
- Create: `analysis_options.yaml`
- Create: `.gitignore`
- Create: `.env.example`
- Create: `lib/main.dart`
- Modify: `README.md`

- [ ] **Step 1: Verify Flutter is available**

Run:

```bash
flutter --version
```

Expected: Flutter prints an installed SDK version. If Flutter is missing, install Flutter before continuing.

- [ ] **Step 2: Generate the Flutter project in the current repository**

Run from `/Users/nourhr/dev/pycharm/projects/hokhelper-mobi`:

```bash
flutter create --platforms=android --org com.hokhelper .
```

Expected: Flutter creates `android/`, `lib/`, `test/`, `pubspec.yaml`, and supporting files without deleting `docs/`.

- [ ] **Step 3: Replace `pubspec.yaml` dependencies**

Set the dependencies section to include these packages:

```yaml
dependencies:
  cached_network_image: ^3.4.1
  dio: ^5.7.0
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  flutter_secure_storage: ^9.2.2
  go_router: ^14.6.2
  intl: ^0.19.0
  shared_preferences: ^2.3.3
```

Keep `dev_dependencies` with `flutter_test` and `flutter_lints`.

- [ ] **Step 4: Add environment sample**

Create `.env.example` with:

```bash
HOK_API_BASE_URL=https://localhost:8000
HOK_API_PREFIX=/hokx
```

- [ ] **Step 5: Add a temporary app entrypoint**

Replace `lib/main.dart` with:

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const HokHelperBootstrap());
}

class HokHelperBootstrap extends StatelessWidget {
  const HokHelperBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF070A12),
        body: Center(
          child: Text(
            'HOK Helper Mobile',
            style: TextStyle(color: Color(0xFFF5D06F), fontSize: 24),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run dependency install and static analysis**

Run:

```bash
flutter pub get
flutter analyze
```

Expected: dependency resolution succeeds and analysis reports no errors.

- [ ] **Step 7: Build Android debug APK**

Run:

```bash
flutter build apk --debug
```

Expected: debug APK is produced under `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 8: Commit**

```bash
git add .
git commit -m "feat: scaffold Flutter Android app"
```

---

### Task 2: Core Configuration, Theme, and Routing

**Files:**
- Create: `lib/src/app/hok_helper_app.dart`
- Create: `lib/src/app/router.dart`
- Create: `lib/src/app/app_shell.dart`
- Create: `lib/src/core/config/app_config.dart`
- Create: `lib/src/core/theme/app_theme.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Create app config**

Create `lib/src/core/config/app_config.dart`:

```dart
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.apiPrefix,
  });

  final String apiBaseUrl;
  final String apiPrefix;

  static const current = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'HOK_API_BASE_URL',
      defaultValue: 'https://localhost:8000',
    ),
    apiPrefix: String.fromEnvironment(
      'HOK_API_PREFIX',
      defaultValue: '/hokx',
    ),
  );

  String get apiRoot {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final prefix = apiPrefix.startsWith('/') ? apiPrefix : '/$apiPrefix';
    return '$base$prefix';
  }
}
```

- [ ] **Step 2: Create app theme**

Create `lib/src/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF070A12);
  static const Color panel = Color(0xFF101624);
  static const Color panelAlt = Color(0xFF151D2E);
  static const Color gold = Color(0xFFF5D06F);
  static const Color cyan = Color(0xFF45D5FF);
  static const Color text = Color(0xFFF4F7FB);
  static const Color muted = Color(0xFF94A3B8);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: cyan,
        surface: panel,
        error: Color(0xFFFF6B6B),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: panel,
        indicatorColor: gold.withOpacity(0.16),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (_) => const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create app shell with tabs**

Create `lib/src/app/app_shell.dart`:

```dart
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.onTabSelected,
  });

  final int currentIndex;
  final Widget child;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTabSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Heroes'),
          NavigationDestination(icon: Icon(Icons.collections_outlined), selectedIcon: Icon(Icons.collections), label: 'Content'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Tools'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Create initial tab screens and router**

Create `lib/src/app/router.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(
          currentIndex: navigationShell.currentIndex,
          onTabSelected: navigationShell.goBranch,
          child: navigationShell,
        );
      },
      branches: [
        StatefulShellBranch(routes: [_tabRoute('/', 'Home')]),
        StatefulShellBranch(routes: [_tabRoute('/heroes', 'Heroes')]),
        StatefulShellBranch(routes: [_tabRoute('/content', 'Content')]),
        StatefulShellBranch(routes: [_tabRoute('/tools', 'Tools')]),
        StatefulShellBranch(routes: [_tabRoute('/me', 'Me')]),
      ],
    ),
  ],
);

GoRoute _tabRoute(String path, String title) {
  return GoRoute(
    path: path,
    builder: (context, state) => _InitialTabScreen(title: title),
  );
}

class _InitialTabScreen extends StatelessWidget {
  const _InitialTabScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
```

- [ ] **Step 5: Wire the Material app**

Create `lib/src/app/hok_helper_app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class HokHelperApp extends StatelessWidget {
  const HokHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'HOK Helper',
      theme: AppTheme.dark(),
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
        Locale('id'),
      ],
    );
  }
}
```

Replace `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/hok_helper_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HokHelperApp()));
}
```

- [ ] **Step 6: Verify**

Run:

```bash
flutter analyze
flutter test
```

Expected: no analyzer errors. Remove the generated `test/widget_test.dart` before running tests if it still expects the original counter app.

- [ ] **Step 7: Commit**

```bash
git add lib pubspec.yaml test
git commit -m "feat: add mobile app shell and routing"
```

---

### Task 3: Core API Client and Storage

**Files:**
- Create: `lib/src/core/network/api_envelope.dart`
- Create: `lib/src/core/network/api_error.dart`
- Create: `lib/src/core/network/api_client.dart`
- Create: `lib/src/core/storage/secure_token_store.dart`
- Create: `lib/src/core/storage/preferences_store.dart`
- Create: `lib/src/core/constants/regions.dart`
- Test: `test/core/network/api_envelope_test.dart`

- [ ] **Step 1: Add API envelope model**

Create `lib/src/core/network/api_envelope.dart`:

```dart
class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.success,
    this.message,
    this.result,
  });

  final bool success;
  final String? message;
  final T? result;

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parseResult,
  ) {
    return ApiEnvelope<T>(
      success: json['success'] == true,
      message: (json['message'] ?? json['msg'])?.toString(),
      result: parseResult(json['result']),
    );
  }
}
```

- [ ] **Step 2: Add envelope tests**

Create `test/core/network/api_envelope_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hokhelper_mobi/src/core/network/api_envelope.dart';

void main() {
  test('parses standard backend envelope', () {
    final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
      {
        'success': true,
        'message': 'ok',
        'result': {'total': 1},
      },
      (value) => value as Map<String, dynamic>,
    );

    expect(envelope.success, isTrue);
    expect(envelope.message, 'ok');
    expect(envelope.result?['total'], 1);
  });

  test('uses msg as message fallback', () {
    final envelope = ApiEnvelope<Object?>.fromJson(
      {'success': false, 'msg': 'failed', 'result': null},
      (value) => value,
    );

    expect(envelope.success, isFalse);
    expect(envelope.message, 'failed');
  });
}
```

- [ ] **Step 3: Run failing test before import paths are final**

Run:

```bash
flutter test test/core/network/api_envelope_test.dart
```

Expected: pass after package name is correct. If the package name generated by Flutter differs, update the import to match `name:` in `pubspec.yaml`.

- [ ] **Step 4: Add typed API error**

Create `lib/src/core/network/api_error.dart`:

```dart
enum ApiErrorKind {
  network,
  backend,
  authExpired,
  forbidden,
  validation,
  unknown,
}

class ApiError implements Exception {
  const ApiError({
    required this.kind,
    required this.message,
    this.statusCode,
  });

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiError($kind, $statusCode, $message)';
}
```

- [ ] **Step 5: Add token store**

Create `lib/src/core/storage/secure_token_store.dart`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
```

- [ ] **Step 6: Add preferences and regions**

Create `lib/src/core/constants/regions.dart`:

```dart
enum HokRegion {
  cn(1, 'zh', 'China'),
  en(2, 'en', 'English'),
  id(3, 'id', 'Indonesia');

  const HokRegion(this.id, this.languageCode, this.label);

  final int id;
  final String languageCode;
  final String label;
}
```

Create `lib/src/core/storage/preferences_store.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/regions.dart';

class PreferencesStore {
  PreferencesStore(this._preferences);

  static const _regionKey = 'selected_region_id';
  static const _languageKey = 'selected_language_code';
  static const _themeKey = 'selected_theme';

  final SharedPreferences _preferences;

  int readRegionId() => _preferences.getInt(_regionKey) ?? HokRegion.en.id;

  Future<void> saveRegionId(int regionId) => _preferences.setInt(_regionKey, regionId);

  String readLanguageCode() => _preferences.getString(_languageKey) ?? HokRegion.en.languageCode;

  Future<void> saveLanguageCode(String languageCode) => _preferences.setString(_languageKey, languageCode);

  String readThemeName() => _preferences.getString(_themeKey) ?? 'classic';

  Future<void> saveThemeName(String themeName) => _preferences.setString(_themeKey, themeName);
}
```

- [ ] **Step 7: Add Dio API client**

Create `lib/src/core/network/api_client.dart`:

```dart
import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_token_store.dart';
import 'api_error.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    SecureTokenStore? tokenStore,
    AppConfig config = AppConfig.current,
  })  : _dio = dio ?? Dio(BaseOptions(baseUrl: config.apiRoot)),
        _tokenStore = tokenStore ?? SecureTokenStore() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Content-Type'] = 'application/json';
          final token = await _tokenStore.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final SecureTokenStore _tokenStore;

  Future<Map<String, dynamic>> getJson(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get<Object?>(path, queryParameters: query);
      return _asMap(response.data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    try {
      final response = await _dio.post<Object?>(path, data: body);
      return _asMap(response.data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw const ApiError(kind: ApiErrorKind.backend, message: 'Unexpected backend response');
  }

  ApiError _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return ApiError(kind: ApiErrorKind.authExpired, message: 'Authentication expired', statusCode: statusCode);
    }
    if (statusCode != null && statusCode >= 400) {
      final data = error.response?.data;
      final message = data is Map<String, dynamic>
          ? (data['message'] ?? data['msg'] ?? data['error'] ?? 'Request failed').toString()
          : 'Request failed';
      return ApiError(kind: ApiErrorKind.backend, message: message, statusCode: statusCode);
    }
    return ApiError(kind: ApiErrorKind.network, message: error.message ?? 'Network unavailable');
  }
}
```

- [ ] **Step 8: Verify**

Run:

```bash
flutter analyze
flutter test
```

Expected: no analyzer errors and all tests pass.

- [ ] **Step 9: Commit**

```bash
git add lib/src/core test/core
git commit -m "feat: add core API client and storage"
```

---

### Task 4: Auth State and Email Login

**Files:**
- Create: `lib/src/features/auth/data/auth_repository.dart`
- Create: `lib/src/features/auth/domain/auth_user.dart`
- Create: `lib/src/features/auth/presentation/auth_controller.dart`
- Create: `lib/src/features/auth/presentation/login_screen.dart`
- Modify: `lib/src/app/router.dart`

- [ ] **Step 1: Create auth user model**

Create `lib/src/features/auth/domain/auth_user.dart`:

```dart
class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.avatar,
  });

  final int id;
  final String username;
  final String email;
  final String displayName;
  final String? avatar;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['first_name']?.toString().isNotEmpty == true
          ? json['first_name'].toString()
          : json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
    );
  }
}
```

- [ ] **Step 2: Create auth repository**

Create `lib/src/features/auth/data/auth_repository.dart`:

```dart
import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/storage/secure_token_store.dart';
import '../domain/auth_user.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SecureTokenStore tokenStore,
  })  : _apiClient = apiClient,
        _tokenStore = tokenStore;

  final ApiClient _apiClient;
  final SecureTokenStore _tokenStore;

  Future<AuthUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final json = await _apiClient.postJson(
      '/auth/email/login',
      body: {'email': email, 'password': password},
    );
    final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
      json,
      (value) => value as Map<String, dynamic>,
    );
    final result = envelope.result ?? json;
    final access = result['access']?.toString();
    final refresh = result['refresh']?.toString();
    final userJson = result['user'];
    if (access == null || refresh == null || userJson is! Map<String, dynamic>) {
      throw StateError('Login response missing token or user');
    }
    await _tokenStore.saveTokens(access: access, refresh: refresh);
    return AuthUser.fromJson(userJson);
  }

  Future<void> logout() => _tokenStore.clear();
}
```

- [ ] **Step 3: Create auth controller providers**

Create `lib/src/features/auth/presentation/auth_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_token_store.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

final tokenStoreProvider = Provider<SecureTokenStore>((ref) => SecureTokenStore());
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStore: ref.watch(tokenStoreProvider));
});
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  );
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async => null;

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).loginWithEmail(email: email, password: password);
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
```

- [ ] **Step 4: Create login screen**

Create `lib/src/features/auth/presentation/login_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: auth.isLoading
                ? null
                : () {
                    ref.read(authControllerProvider.notifier).login(
                          email: _emailController.text.trim(),
                          password: _passwordController.text,
                        );
                  },
            child: auth.isLoading ? const CircularProgressIndicator() : const Text('Login'),
          ),
          if (auth.hasError) ...[
            const SizedBox(height: 12),
            Text(
              auth.error.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Register login route**

Add `/login` to `lib/src/app/router.dart`:

```dart
GoRoute(
  path: '/login',
  builder: (context, state) => const LoginScreen(),
),
```

Import `LoginScreen`.

- [ ] **Step 6: Verify**

Run:

```bash
flutter analyze
flutter test
```

Expected: no analyzer errors and tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/src/features/auth lib/src/app/router.dart
git commit -m "feat: add email login foundation"
```

---

### Task 5: Shared UI States and Image Components

**Files:**
- Create: `lib/src/core/widgets/app_async_view.dart`
- Create: `lib/src/core/widgets/app_empty_state.dart`
- Create: `lib/src/core/widgets/app_error_state.dart`
- Create: `lib/src/core/widgets/app_image.dart`
- Create: `lib/src/core/widgets/app_section_header.dart`

- [ ] **Step 1: Add async view wrapper**

Create `lib/src/core/widgets/app_async_view.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_error_state.dart';

class AppAsyncView<T> extends StatelessWidget {
  const AppAsyncView({
    super.key,
    required this.value,
    required this.data,
    this.retry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => AppErrorState(message: error.toString(), onRetry: retry),
    );
  }
}
```

- [ ] **Step 2: Add empty and error states**

Create `lib/src/core/widgets/app_empty_state.dart`:

```dart
import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key, required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 44),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
```

Create `lib/src/core/widgets/app_error_state.dart`:

```dart
import 'package:flutter/material.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Add image and section widgets**

Create `lib/src/core/widgets/app_image.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
  });

  final String? url;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageUrl == null || imageUrl.isEmpty
          ? const ColoredBox(color: Color(0xFF1F2937), child: SizedBox.expand())
          : CachedNetworkImage(
              imageUrl: imageUrl,
              fit: fit,
              progressIndicatorBuilder: (context, url, progress) => const ColoredBox(color: Color(0xFF1F2937)),
              errorWidget: (context, url, error) => const ColoredBox(
                color: Color(0xFF1F2937),
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
    );
  }
}
```

Create `lib/src/core/widgets/app_section_header.dart`:

```dart
import 'package:flutter/material.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (action != null) action!,
      ],
    );
  }
}
```

- [ ] **Step 4: Verify**

Run:

```bash
flutter analyze
flutter test
```

Expected: no analyzer errors and tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/src/core/widgets
git commit -m "feat: add shared mobile UI states"
```

---

### Task 6: Home and Me Vertical Slice

**Files:**
- Create: `lib/src/features/home/data/home_repository.dart`
- Create: `lib/src/features/home/presentation/home_screen.dart`
- Create: `lib/src/features/profile/presentation/me_screen.dart`
- Modify: `lib/src/app/router.dart`

- [ ] **Step 1: Create home repository**

Create `lib/src/features/home/data/home_repository.dart`:

```dart
import '../../../core/network/api_client.dart';

class HomeRepository {
  HomeRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> loadHomeStats() {
    return _apiClient.getJson('/home/stats');
  }
}
```

- [ ] **Step 2: Create home screen**

Create `lib/src/features/home/presentation/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_section_header.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(apiClientProvider));
});

final homeStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(homeRepositoryProvider).loadHomeStats();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(homeStatsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(homeStatsProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSectionHeader(title: 'HOK Helper'),
          const SizedBox(height: 12),
          Text('Heroes, builds, rankings, and tools for Honor of Kings.'),
          const SizedBox(height: 20),
          stats.when(
            data: (data) => Text('Backend connected: ${data.keys.length} groups'),
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text('Home data unavailable: $error'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create Me screen**

Create `lib/src/features/profile/presentation/me_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.valueOrNull;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Me', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        if (user == null)
          FilledButton.icon(
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.login),
            label: const Text('Login'),
          )
        else ...[
          Text(user.displayName, style: Theme.of(context).textTheme.titleLarge),
          Text(user.email),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text('Logout'),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 4: Replace initial tab screens for Home and Me**

Update `lib/src/app/router.dart` so `/` uses `HomeScreen` and `/me` uses `MeScreen`.

```dart
StatefulShellBranch(routes: [
  GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
]),
StatefulShellBranch(routes: [
  GoRoute(path: '/me', builder: (context, state) => const MeScreen()),
]),
```

Import both screens.

- [ ] **Step 5: Verify**

Run:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Expected: all commands succeed.

- [ ] **Step 6: Commit**

```bash
git add lib/src/features/home lib/src/features/profile lib/src/app/router.dart
git commit -m "feat: add home and profile vertical slice"
```

---

### Task 7: Hero Gallery and Detail

**Files:**
- Create: `lib/src/features/heroes/domain/hero_summary.dart`
- Create: `lib/src/features/heroes/data/heroes_repository.dart`
- Create: `lib/src/features/heroes/presentation/hero_gallery_screen.dart`
- Create: `lib/src/features/heroes/presentation/hero_detail_screen.dart`
- Modify: `lib/src/app/router.dart`

- [ ] **Step 1: Create hero summary model**

Create `lib/src/features/heroes/domain/hero_summary.dart`:

```dart
class HeroSummary {
  const HeroSummary({
    required this.id,
    required this.name,
    this.avatar,
    this.title,
  });

  final int id;
  final String name;
  final String? avatar;
  final String? title;

  factory HeroSummary.fromJson(Map<String, dynamic> json) {
    return HeroSummary(
      id: ((json['heroId'] ?? json['hero_id'] ?? json['id']) as num).toInt(),
      name: (json['heroName'] ?? json['name'] ?? json['hero_name'] ?? '').toString(),
      avatar: (json['avatar'] ?? json['icon'] ?? json['image'])?.toString(),
      title: (json['title'] ?? json['heroTitle'])?.toString(),
    );
  }
}
```

- [ ] **Step 2: Create heroes repository**

Create `lib/src/features/heroes/data/heroes_repository.dart`:

```dart
import '../../../core/network/api_client.dart';
import '../domain/hero_summary.dart';

class HeroesRepository {
  HeroesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<HeroSummary>> loadHeroes({required int regionId}) async {
    final json = await _apiClient.postJson(
      '/hero/gallery',
      body: {
        'page': 1,
        'pageSize': 60,
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ],
      },
    );
    final result = json['result'];
    final rows = result is Map<String, dynamic>
        ? (result['data'] ?? result['rows'] ?? [])
        : (json['rows'] ?? []);
    return (rows as List).whereType<Map<String, dynamic>>().map(HeroSummary.fromJson).toList();
  }

  Future<Map<String, dynamic>> loadHeroDetail({required int heroId, required int regionId}) {
    return _apiClient.getJson('/hero/$heroId', query: {'region_id': regionId});
  }
}
```

- [ ] **Step 3: Create gallery screen**

Create `lib/src/features/heroes/presentation/hero_gallery_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/heroes_repository.dart';

final heroesRepositoryProvider = Provider<HeroesRepository>((ref) {
  return HeroesRepository(ref.watch(apiClientProvider));
});

final heroGalleryProvider = FutureProvider((ref) {
  return ref.watch(heroesRepositoryProvider).loadHeroes(regionId: 2);
});

class HeroGalleryScreen extends ConsumerWidget {
  const HeroGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroes = ref.watch(heroGalleryProvider);
    return heroes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text(error.toString())),
      data: (items) {
        if (items.isEmpty) {
          return const AppEmptyState(title: 'No heroes found');
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final hero = items[index];
            return InkWell(
              onTap: () => context.push('/heroes/${hero.id}'),
              child: Column(
                children: [
                  Expanded(child: AppImage(url: hero.avatar)),
                  const SizedBox(height: 6),
                  Text(hero.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 4: Create detail screen**

Create `lib/src/features/heroes/presentation/hero_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/heroes_repository.dart';

final heroDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, heroId) {
  return ref.watch(heroesRepositoryProvider).loadHeroDetail(heroId: heroId, regionId: 2);
});

class HeroDetailScreen extends ConsumerWidget {
  const HeroDetailScreen({super.key, required this.heroId});

  final int heroId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(heroDetailProvider(heroId));
    return Scaffold(
      appBar: AppBar(title: Text('Hero #$heroId')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (json) {
          final result = json['result'];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Hero Detail', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(result?.toString() ?? json.toString()),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 5: Wire hero routes**

Update `lib/src/app/router.dart`:

```dart
StatefulShellBranch(routes: [
  GoRoute(
    path: '/heroes',
    builder: (context, state) => const HeroGalleryScreen(),
    routes: [
      GoRoute(
        path: ':heroId',
        builder: (context, state) {
          final heroId = int.parse(state.pathParameters['heroId']!);
          return HeroDetailScreen(heroId: heroId);
        },
      ),
    ],
  ),
]),
```

- [ ] **Step 6: Verify**

Run:

```bash
flutter analyze
flutter test
```

Expected: no analyzer errors and tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/src/features/heroes lib/src/app/router.dart
git commit -m "feat: add hero gallery and detail"
```

---

### Task 8: Content, Builds, Rankings, Search, and Settings Foundations

**Files:**
- Create: `lib/src/features/content/data/content_repository.dart`
- Create: `lib/src/features/content/presentation/content_screen.dart`
- Create: `lib/src/features/builds/data/builds_repository.dart`
- Create: `lib/src/features/rankings/data/rankings_repository.dart`
- Create: `lib/src/features/search/data/search_repository.dart`
- Create: `lib/src/features/settings/presentation/settings_screen.dart`
- Modify: `lib/src/app/router.dart`

- [ ] **Step 1: Add content repository**

Create `lib/src/features/content/data/content_repository.dart`:

```dart
import '../../../core/network/api_client.dart';

class ContentRepository {
  ContentRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> loadSkins({required int regionId}) {
    return _apiClient.postJson('/skin/list', body: {
      'page': 1,
      'pageSize': 20,
      'filterRules': [
        {'field': 'region_id', 'op': 'eq', 'value': regionId},
      ],
    });
  }

  Future<Map<String, dynamic>> loadCgs({required int regionId}) {
    return _apiClient.postJson('/cg/list', body: {
      'page': 1,
      'pageSize': 20,
      'filterRules': [
        {'field': 'region_id', 'op': 'eq', 'value': regionId},
      ],
    });
  }
}
```

- [ ] **Step 2: Add builds, rankings, and search repositories**

Create `lib/src/features/builds/data/builds_repository.dart`:

```dart
import '../../../core/network/api_client.dart';

class BuildsRepository {
  BuildsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> loadPublicSchemes({required int regionId}) {
    return _apiClient.getJson('/build/schemes', query: {
      'action': 'explore',
      'page': 1,
      'pageSize': 20,
      'filterRules': '[{"field":"region_id","op":"eq","value":$regionId}]',
    });
  }
}
```

Create `lib/src/features/rankings/data/rankings_repository.dart`:

```dart
import '../../../core/network/api_client.dart';

class RankingsRepository {
  RankingsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> loadHeroRanking({required int regionId}) {
    return _apiClient.postJson('/ranking/heroes', body: {
      'page': 1,
      'pageSize': 20,
      'filterRules': [
        {'field': 'region_id', 'op': 'eq', 'value': regionId},
      ],
    });
  }
}
```

Create `lib/src/features/search/data/search_repository.dart`:

```dart
import '../../../core/network/api_client.dart';

class SearchRepository {
  SearchRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> search(String keyword, {required int regionId}) {
    return _apiClient.postJson('/search/global', body: {
      'keyword': keyword,
      'region_id': regionId,
    });
  }
}
```

- [ ] **Step 3: Add content and tools screens**

Create `lib/src/features/content/presentation/content_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(ref.watch(apiClientProvider));
});

final skinsProvider = FutureProvider((ref) {
  return ref.watch(contentRepositoryProvider).loadSkins(regionId: 2);
});

class ContentScreen extends ConsumerWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skins = ref.watch(skinsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Content', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        skins.when(
          data: (data) => Text('Skin data loaded: ${data.keys.length} groups'),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => Text('Content unavailable: $error'),
        ),
      ],
    );
  }
}
```

Create `lib/src/features/rankings/presentation/tools_screen.dart`:

```dart
import 'package:flutter/material.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tools', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const ListTile(
          leading: Icon(Icons.leaderboard_outlined),
          title: Text('Rankings'),
          subtitle: Text('Hero and tier list views'),
        ),
        const ListTile(
          leading: Icon(Icons.build_outlined),
          title: Text('Build Explorer'),
          subtitle: Text('Public build schemes'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Add settings screen**

Create `lib/src/features/settings/presentation/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const ListView(
        children: [
          ListTile(title: Text('Language'), subtitle: Text('English / Chinese / Indonesian')),
          ListTile(title: Text('Region'), subtitle: Text('CN / EN / ID')),
          ListTile(title: Text('Theme'), subtitle: Text('Classic dark')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Wire content, tools, and settings routes**

Update `lib/src/app/router.dart` so `/content` uses `ContentScreen`, `/tools` uses `ToolsScreen`, and add `/settings` as a top-level route.

- [ ] **Step 6: Verify**

Run:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Expected: all commands succeed.

- [ ] **Step 7: Commit**

```bash
git add lib/src/features/content lib/src/features/builds lib/src/features/rankings lib/src/features/search lib/src/features/settings lib/src/app/router.dart
git commit -m "feat: add core content and tools foundations"
```

---

### Task 9: README, Environment Commands, and Final Verification

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update README**

Replace `README.md` with:

```markdown
# hokhelper-mobi

Flutter Android-first mobile app for HOK Helper.

## Backend

The app calls the existing Django backend from `okhok/hok` through `/hokx/` APIs.

Default local API settings:

```bash
HOK_API_BASE_URL=https://localhost:8000
HOK_API_PREFIX=/hokx
```

For Android emulator access to a local host backend, use:

```bash
--dart-define=HOK_API_BASE_URL=https://10.0.2.2:8000
```

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=HOK_API_BASE_URL=https://10.0.2.2:8000
flutter build apk --debug
```

## Product Plan

See `docs/superpowers/specs/2026-07-03-hokhelper-mobile-mvp-design.md`.
```

- [ ] **Step 2: Run final verification**

Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
git status --short
```

Expected:

- Flutter dependencies resolve.
- Analyzer reports no errors.
- Tests pass.
- Debug APK builds.
- Git status only shows intentional README changes before commit.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add mobile development commands"
```

---

## Plan Self-Review

- Spec coverage: This plan covers the Flutter Android scaffold, API client, JWT storage, Riverpod state, app shell, home, auth, heroes, content, builds/rankings/search foundations, settings, and final Android build verification.
- Scope control: Community creation, BP simulator, BuildSim editor, TierList editor, AI image generation, push notifications, offline sync, iOS, and release automation remain outside MVP 1.0 implementation.
- Type consistency: Core providers use `ApiClient`, `SecureTokenStore`, and Riverpod consistently. Feature repositories receive `ApiClient`. Routes use `go_router`.
- Contract consistency: Requests use `/hokx` via `AppConfig.apiRoot`, preserve `region_id`, and follow existing JSON envelope and filterRules patterns.
