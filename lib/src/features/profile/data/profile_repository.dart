import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/user_profile.dart';

class ProfileRepository {
  const ProfileRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<UserProfile> loadProfile({int? userId}) async {
    final json = await apiClient.getJson(
      '/user/profile/get',
      query: userId == null ? null : {'user_id': userId},
    );
    return _readProfile(json, fallbackMessage: 'Failed to load profile');
  }

  Future<UserProfile> updateProfile({
    String? displayName,
    String? avatar,
    String? bio,
    Map<String, dynamic>? socialLinks,
  }) async {
    final body = <String, Object>{};
    if (displayName != null) {
      body['first_name'] = displayName;
    }
    if (avatar != null) {
      body['avatar'] = avatar;
    }
    if (bio != null) {
      body['bio'] = bio;
    }
    if (socialLinks != null) {
      body['social_links'] = socialLinks;
    }

    final json = await apiClient.postJson('/user/profile/update', body: body);
    return _readProfile(json, fallbackMessage: 'Failed to update profile');
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final json = await apiClient.postJson(
      '/user/password/change',
      body: {'old_password': oldPassword, 'new_password': newPassword},
    );
    _ensureSuccess(json, fallbackMessage: 'Failed to change password');
  }

  Future<ProfileFollowResult> followUser(int userId) async {
    final json = await apiClient.postJson(
      '/user/follow',
      body: {'target_user_id': userId},
    );
    _ensureSuccess(json, fallbackMessage: 'Failed to follow user');
    return ProfileFollowResult.fromJson(_readResultMap(json));
  }

  Future<ProfileFollowResult> unfollowUser(int userId) async {
    final json = await apiClient.postJson(
      '/user/unfollow',
      body: {'target_user_id': userId},
    );
    _ensureSuccess(json, fallbackMessage: 'Failed to unfollow user');
    return ProfileFollowResult.fromJson(_readResultMap(json));
  }

  Future<ProfileLikeResult> toggleProfileLike(int userId) async {
    final json = await apiClient.postJson(
      '/user/profile/like',
      body: {'target_user_id': userId},
    );
    _ensureSuccess(json, fallbackMessage: 'Failed to like profile');
    return ProfileLikeResult.fromJson(_readResultMap(json));
  }

  Future<ProfileFollowList> loadFollowing({int? userId, int page = 1}) async {
    final query = <String, Object>{'page': page};
    if (userId != null) {
      query['user_id'] = userId;
    }
    final json = await apiClient.getJson('/user/following/list', query: query);
    _ensureSuccess(json, fallbackMessage: 'Failed to load following');
    return ProfileFollowList.fromJson(_readResultMap(json), key: 'following');
  }

  Future<ProfileFollowList> loadFollowers({int? userId, int page = 1}) async {
    final query = <String, Object>{'page': page};
    if (userId != null) {
      query['user_id'] = userId;
    }
    final json = await apiClient.getJson('/user/followers/list', query: query);
    _ensureSuccess(json, fallbackMessage: 'Failed to load followers');
    return ProfileFollowList.fromJson(_readResultMap(json), key: 'followers');
  }

  UserProfile _readProfile(
    Map<String, dynamic> json, {
    required String fallbackMessage,
  }) {
    _ensureSuccess(json, fallbackMessage: fallbackMessage);

    final result = json['result'];
    if (result is! Map) {
      throw ApiError(kind: ApiErrorKind.backend, message: fallbackMessage);
    }

    return UserProfile.fromJson(result);
  }

  void _ensureSuccess(
    Map<String, dynamic> json, {
    required String fallbackMessage,
  }) {
    if (json['success'] == false) {
      throw ApiError(
        kind: ApiErrorKind.backend,
        message: (json['message'] ?? json['msg'] ?? fallbackMessage).toString(),
      );
    }
  }

  Map<String, Object?> _readResultMap(Map<String, dynamic> json) {
    final result = json['result'];
    return result is Map
        ? Map<String, Object?>.from(result)
        : const <String, Object?>{};
  }
}

class ProfileFollowResult {
  const ProfileFollowResult({
    required this.isFollowing,
    required this.targetUserId,
  });

  final bool isFollowing;
  final int targetUserId;

  factory ProfileFollowResult.fromJson(Map<String, Object?> json) {
    return ProfileFollowResult(
      isFollowing: _readBool(json['is_following'] ?? json['isFollowing']),
      targetUserId: _readInt(json['target_user_id'] ?? json['targetUserId']),
    );
  }
}

class ProfileLikeResult {
  const ProfileLikeResult({
    required this.isLiked,
    required this.likesCount,
    required this.targetUserId,
  });

  final bool isLiked;
  final int likesCount;
  final int targetUserId;

  factory ProfileLikeResult.fromJson(Map<String, Object?> json) {
    return ProfileLikeResult(
      isLiked: _readBool(json['is_liked'] ?? json['isLiked']),
      likesCount: _readInt(json['likes_count'] ?? json['likesCount']),
      targetUserId: _readInt(json['target_user_id'] ?? json['targetUserId']),
    );
  }
}

class ProfileFollowList {
  const ProfileFollowList({
    required this.users,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<ProfileFollowUser> users;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  factory ProfileFollowList.fromJson(
    Map<String, Object?> json, {
    required String key,
  }) {
    final rows = json[key];
    return ProfileFollowList(
      users: rows is List
          ? rows.map(ProfileFollowUser.fromJson).toList(growable: false)
          : const [],
      total: _readInt(json['total']),
      page: _readInt(json['page'], fallback: 1),
      pageSize: _readInt(json['page_size'] ?? json['pageSize']),
      hasMore: _readBool(json['has_more'] ?? json['hasMore']),
    );
  }
}

class ProfileFollowUser {
  const ProfileFollowUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatar,
    required this.bio,
    required this.isFollowing,
    required this.isSelf,
  });

  final int id;
  final String username;
  final String displayName;
  final String avatar;
  final String bio;
  final bool isFollowing;
  final bool isSelf;

  factory ProfileFollowUser.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final username = _readString(map['username']);
    final firstName = _readString(map['first_name'] ?? map['firstName']);
    return ProfileFollowUser(
      id: _readInt(map['id']),
      username: username,
      displayName: firstName.isNotEmpty ? firstName : username,
      avatar: _readString(map['avatar'] ?? map['avatar_url']),
      bio: _readString(map['bio']),
      isFollowing: _readBool(map['is_following'] ?? map['isFollowing']),
      isSelf: _readBool(map['is_self'] ?? map['isSelf']),
    );
  }
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final normalized = value?.toString().toLowerCase() ?? '';
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _readString(Object? value) {
  return value?.toString() ?? '';
}
