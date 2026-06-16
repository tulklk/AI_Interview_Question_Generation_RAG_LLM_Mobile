enum UserRole { hrManager, candidate }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final UserRole role;
  final String? company;
  final String? title;
  final String? department;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    this.company,
    this.title,
    this.department,
  });
}
