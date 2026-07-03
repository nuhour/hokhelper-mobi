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

  UserProfile _readProfile(
    Map<String, dynamic> json, {
    required String fallbackMessage,
  }) {
    if (json['success'] == false) {
      throw ApiError(
        kind: ApiErrorKind.backend,
        message: (json['message'] ?? json['msg'] ?? fallbackMessage).toString(),
      );
    }

    final result = json['result'];
    if (result is! Map) {
      throw ApiError(kind: ApiErrorKind.backend, message: fallbackMessage);
    }

    return UserProfile.fromJson(result);
  }
}
