class UserModel {
  final String id;
  final String email;
  final String role;
  final String name;
  final String? avatarUrl;
  final String? address;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.name = '',
    this.avatarUrl,
    this.address,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      role: map['role'],
      name: map['name'] ?? '',
      avatarUrl: map['avatar_url'],
      address: map['address'],
    );
  }

  // ✅ Add this getter for role-based checks
  bool get isAdmin => role == 'admin';
}
