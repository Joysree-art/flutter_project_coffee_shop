class UserModel {
  final String id;
  final String email;
  final String role;
  final String name; // name added

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.name = '', // default empty
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
      name: map['name'] != null ? map['name'] as String : '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
    };
  }

  bool get isAdmin => role == 'admin';
}
