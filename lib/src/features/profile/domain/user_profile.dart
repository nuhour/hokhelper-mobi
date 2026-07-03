class ProfileStats {
  const ProfileStats({
    required this.posts,
    required this.following,
    required this.followers,
    required this.likes,
  });

  final int posts;
  final int following;
  final int followers;
  final int likes;

  factory ProfileStats.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return ProfileStats(
      posts: _readInt(map['posts']),
      following: _readInt(map['following']),
      followers: _readInt(map['followers']),
      likes: _readInt(map['likes']),
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    required this.avatar,
    required this.level,
    required this.points,
    required this.xpTotal,
    required this.xpCurrentLevel,
    required this.xpToNextLevel,
    required this.levelProgress,
    required this.levelCap,
    required this.bio,
    required this.socialLinks,
    required this.stats,
    required this.isFollowing,
    required this.isLiked,
    required this.isSelf,
  });

  final int id;
  final String username;
  final String displayName;
  final String email;
  final String avatar;
  final int level;
  final int points;
  final int xpTotal;
  final int xpCurrentLevel;
  final int xpToNextLevel;
  final int levelProgress;
  final bool levelCap;
  final String bio;
  final Map<String, dynamic> socialLinks;
  final ProfileStats stats;
  final bool isFollowing;
  final bool isLiked;
  final bool isSelf;

  factory UserProfile.fromJson(Object? json) {
    final root = json is Map ? json : const <String, Object?>{};
    final user = root['user'] is Map ? root['user'] as Map : root;
    final profile = root['profile'] is Map ? root['profile'] as Map : root;

    final id = _readInt(user['id']);
    final username = _readString(user['username']);
    final firstName = _readString(user['first_name']);
    final displayName = firstName.isNotEmpty ? firstName : username;
    final socialLinks = profile['social_links'];

    return UserProfile(
      id: id,
      username: username,
      displayName: displayName.isEmpty ? 'User #$id' : displayName,
      email: _readString(user['email']),
      avatar: _readString(user['avatar'] ?? user['avatar_url']),
      level: _readInt(profile['level'], fallback: 1),
      points: _readInt(profile['points']),
      xpTotal: _readInt(profile['xp_total'] ?? profile['points']),
      xpCurrentLevel: _readInt(profile['xp_current_level']),
      xpToNextLevel: _readInt(profile['xp_to_next_level']),
      levelProgress: _readInt(profile['level_progress']),
      levelCap: profile['level_cap'] == true,
      bio: _readString(profile['bio']),
      socialLinks: socialLinks is Map
          ? Map<String, dynamic>.from(socialLinks)
          : const {},
      stats: ProfileStats.fromJson(root['stats']),
      isFollowing: root['is_following'] == true,
      isLiked: root['is_liked'] == true,
      isSelf: root['is_self'] != false,
    );
  }
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
