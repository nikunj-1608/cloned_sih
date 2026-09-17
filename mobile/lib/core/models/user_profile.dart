import 'user_role.dart';

/// Active authenticated user profile.
///
/// Contains profile metadata stored in Supabase (`auth.users` user_metadata or
/// `profiles` table), with local caching to maintain identity offline at sea.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.assignedPort,
    this.vesselRegistration,
    this.isOffline = false,
    this.createdAt,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? fullName;
  final String? assignedPort;
  final String? vesselRegistration;
  final bool isOffline;
  final DateTime? createdAt;

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    return email.split('@').first;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromMetadata(json['role'] as String?),
      fullName: json['full_name'] as String?,
      assignedPort: json['assigned_port'] as String?,
      vesselRegistration: json['vessel_registration'] as String?,
      isOffline: json['is_offline'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.metadataKey,
      if (fullName != null) 'full_name': fullName,
      if (assignedPort != null) 'assigned_port': assignedPort,
      if (vesselRegistration != null) 'vessel_registration': vesselRegistration,
      'is_offline': isOffline,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    UserRole? role,
    String? fullName,
    String? assignedPort,
    String? vesselRegistration,
    bool? isOffline,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      assignedPort: assignedPort ?? this.assignedPort,
      vesselRegistration: vesselRegistration ?? this.vesselRegistration,
      isOffline: isOffline ?? this.isOffline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          role == other.role &&
          fullName == other.fullName &&
          assignedPort == other.assignedPort &&
          vesselRegistration == other.vesselRegistration &&
          isOffline == other.isOffline;

  @override
  int get hashCode => Object.hash(
        id,
        email,
        role,
        fullName,
        assignedPort,
        vesselRegistration,
        isOffline,
      );

  @override
  String toString() =>
      'UserProfile(id: $id, email: $email, role: ${role.metadataKey}, isOffline: $isOffline)';
}
