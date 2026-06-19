enum UserRole { hrManager, candidate, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final UserRole role;
  final String? phone;
  final String? company;
  final String? title;
  final String? department;
  final String? experienceLevel;
  final List<String>? techStack;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    this.phone,
    this.company,
    this.title,
    this.department,
    this.experienceLevel,
    this.techStack,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    UserRole? role,
    String? phone,
    String? company,
    String? title,
    String? department,
    String? experienceLevel,
    List<String>? techStack,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        role: role ?? this.role,
        phone: phone ?? this.phone,
        company: company ?? this.company,
        title: title ?? this.title,
        department: department ?? this.department,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        techStack: techStack ?? this.techStack,
      );
}
