/// Authenticated user, mirroring the API shape (see server/src/models/User.js).
class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;

  /// Saved product slugs (e.g. ["p1", "p3"]).
  final List<String> wishlist;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.wishlist = const [],
  });

  /// Two-letter initials for avatars (e.g. "Rishika Patel" -> "RP").
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      wishlist: (json['wishlist'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}
