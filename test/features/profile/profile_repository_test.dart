import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/profile/data/profile_repository.dart';
import 'package:hok_helper_mobile/src/features/profile/domain/user_profile.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.response)
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  final Map<String, dynamic> response;
  String? getPath;
  Map<String, dynamic>? getQuery;
  String? postPath;
  Object? postBody;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    getPath = path;
    getQuery = query;
    if (path == '/user/following/list') {
      return {
        'success': true,
        'result': {
          'following': [
            {
              'id': 77,
              'username': 'arthur',
              'first_name': 'Arthur',
              'avatar': 'https://example.test/arthur.png',
              'bio': 'Clash lane',
              'is_following': true,
              'is_self': false,
            },
          ],
          'count': 1,
          'total': 1,
          'page': 2,
          'page_size': 20,
          'has_more': false,
        },
      };
    }
    if (path == '/user/followers/list') {
      return {
        'success': true,
        'result': {
          'followers': [
            {
              'id': 88,
              'username': 'angela',
              'first_name': 'Angela',
              'avatar': '',
              'bio': 'Mid mage',
              'is_following': false,
              'is_self': false,
            },
          ],
          'count': 1,
          'total': 1,
          'page': 1,
          'page_size': 20,
          'has_more': true,
        },
      };
    }
    return response;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    return response;
  }
}

Map<String, dynamic> _profileResponse() {
  return {
    'success': true,
    'result': {
      'user': {
        'id': 42,
        'username': 'lam',
        'first_name': 'Lam',
        'email': 'lam@example.test',
        'avatar': 'https://example.test/avatar.png',
        'source': 1,
      },
      'profile': {
        'level': 7,
        'points': 1200,
        'xp_total': 1400,
        'xp_current_level': 260,
        'xp_to_next_level': 740,
        'level_progress': 26,
        'level_cap': false,
        'bio': 'Jungle main',
        'social_links': {'discord': 'lam#0001'},
      },
      'stats': {'posts': 3, 'following': 4, 'followers': 5, 'likes': 6},
      'is_following': true,
      'is_liked': false,
      'is_self': false,
    },
  };
}

void main() {
  group('UserProfile', () {
    test('parses hokx profile response fields', () {
      final profile = UserProfile.fromJson(_profileResponse()['result']);

      expect(profile.id, 42);
      expect(profile.displayName, 'Lam');
      expect(profile.email, 'lam@example.test');
      expect(profile.avatar, 'https://example.test/avatar.png');
      expect(profile.level, 7);
      expect(profile.points, 1200);
      expect(profile.xpTotal, 1400);
      expect(profile.levelProgress, 26);
      expect(profile.bio, 'Jungle main');
      expect(profile.socialLinks['discord'], 'lam#0001');
      expect(profile.stats.followers, 5);
      expect(profile.isFollowing, isTrue);
      expect(profile.isLiked, isFalse);
      expect(profile.isSelf, isFalse);
    });
  });

  group('ProfileRepository', () {
    test('loads current user profile without user id query', () async {
      final apiClient = _FakeApiClient(_profileResponse());
      final repository = ProfileRepository(apiClient: apiClient);

      final profile = await repository.loadProfile();

      expect(apiClient.getPath, '/user/profile/get');
      expect(apiClient.getQuery, isNull);
      expect(profile.id, 42);
    });

    test('loads public user profile with user id query', () async {
      final apiClient = _FakeApiClient(_profileResponse());
      final repository = ProfileRepository(apiClient: apiClient);

      await repository.loadProfile(userId: 99);

      expect(apiClient.getPath, '/user/profile/get');
      expect(apiClient.getQuery, {'user_id': 99});
    });

    test('updates profile with hokx request fields', () async {
      final apiClient = _FakeApiClient(_profileResponse());
      final repository = ProfileRepository(apiClient: apiClient);

      await repository.updateProfile(
        displayName: 'Lam Updated',
        avatar: 'https://example.test/new.png',
        bio: 'Roamer',
        socialLinks: {'discord': 'updated'},
      );

      expect(apiClient.postPath, '/user/profile/update');
      expect(apiClient.postBody, {
        'first_name': 'Lam Updated',
        'avatar': 'https://example.test/new.png',
        'bio': 'Roamer',
        'social_links': {'discord': 'updated'},
      });
    });

    test('changes password with hokx request fields', () async {
      final apiClient = _FakeApiClient({'success': true});
      final repository = ProfileRepository(apiClient: apiClient);

      await repository.changePassword(
        oldPassword: 'OldPass1!',
        newPassword: 'NewPass1!',
      );

      expect(apiClient.postPath, '/user/password/change');
      expect(apiClient.postBody, {
        'old_password': 'OldPass1!',
        'new_password': 'NewPass1!',
      });
    });

    test('follows and unfollows users with hokx request fields', () async {
      final apiClient = _FakeApiClient({
        'success': true,
        'result': {'is_following': true, 'target_user_id': 99},
      });
      final repository = ProfileRepository(apiClient: apiClient);

      final followed = await repository.followUser(99);

      expect(apiClient.postPath, '/user/follow');
      expect(apiClient.postBody, {'target_user_id': 99});
      expect(followed.isFollowing, isTrue);

      apiClient.response['result'] = {
        'is_following': false,
        'target_user_id': 99,
      };
      final unfollowed = await repository.unfollowUser(99);

      expect(apiClient.postPath, '/user/unfollow');
      expect(apiClient.postBody, {'target_user_id': 99});
      expect(unfollowed.isFollowing, isFalse);
    });

    test('toggles profile likes with hokx request fields', () async {
      final apiClient = _FakeApiClient({
        'success': true,
        'result': {'is_liked': true, 'likes_count': 7, 'target_user_id': 99},
      });
      final repository = ProfileRepository(apiClient: apiClient);

      final result = await repository.toggleProfileLike(99);

      expect(apiClient.postPath, '/user/profile/like');
      expect(apiClient.postBody, {'target_user_id': 99});
      expect(result.isLiked, isTrue);
      expect(result.likesCount, 7);
    });

    test('loads following and followers with hokx request fields', () async {
      final apiClient = _FakeApiClient(_profileResponse());
      final repository = ProfileRepository(apiClient: apiClient);

      final following = await repository.loadFollowing(userId: 42, page: 2);

      expect(apiClient.getPath, '/user/following/list');
      expect(apiClient.getQuery, {'page': 2, 'user_id': 42});
      expect(following.users.single.displayName, 'Arthur');
      expect(following.users.single.isFollowing, isTrue);
      expect(following.hasMore, isFalse);

      final followers = await repository.loadFollowers(userId: 42);

      expect(apiClient.getPath, '/user/followers/list');
      expect(apiClient.getQuery, {'page': 1, 'user_id': 42});
      expect(followers.users.single.username, 'angela');
      expect(followers.users.single.isFollowing, isFalse);
      expect(followers.hasMore, isTrue);
    });
  });
}
