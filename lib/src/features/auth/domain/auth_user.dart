class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.avatar,
  });

  final int id;
  final String username;
  final String email;
  final String? displayName;
  final String? avatar;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse(json['id'].toString());
    if (id == null) {
      throw const FormatException('Auth user id is required');
    }

    return AuthUser(
      id: id,
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      displayName: _readOptionalString(
        json['displayName'] ?? json['display_name'],
      ),
      avatar: _readOptionalString(json['avatar'] ?? json['avatar_url']),
    );
  }

  static String? _readOptionalString(Object? value) {
    if (value == null) {
      return null;
    }

    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}
