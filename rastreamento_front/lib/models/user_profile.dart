class UserProfile {
  final int id;
  final String email;
  final String? name;
  final String? imageSrc;
  final bool isAdmin;

  const UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.imageSrc,
    required this.isAdmin,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final source = json['object'] is Map<String, dynamic>
        ? json['object'] as Map<String, dynamic>
        : json;

    bool parseIsAdmin(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value == 1;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'admin';
      }
      return false;
    }

    return UserProfile(
      id: source['id'] ?? source['user_id'] ?? 0,
      email: source['email'] ?? '',
      name: source['name'],
      imageSrc: source['image_src'],
      isAdmin: parseIsAdmin(source['is_admin']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'image_src': imageSrc,
      'is_admin': isAdmin,
    };
  }

  String get displayName => (name != null && name!.isNotEmpty) ? name! : email;
}
