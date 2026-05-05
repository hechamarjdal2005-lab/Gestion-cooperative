class Profile {
  final String id;
  final String? email;
  final String? fullName;
  final String role;
  final String? cooperativeId;
  final bool mustChangePassword;

  Profile({
    required this.id,
    this.email,
    this.fullName,
    required this.role,
    this.cooperativeId,
    this.mustChangePassword = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'],
      cooperativeId: json['cooperative_id'],
      mustChangePassword: json['must_change_password'] ?? false,
    );
  }
}
