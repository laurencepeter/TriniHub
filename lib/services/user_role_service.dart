import 'package:supabase_flutter/supabase_flutter.dart';

enum AppRole {
  admin,
  corporation,
  public,
}

extension AppRoleX on AppRole {
  String get value {
    switch (this) {
      case AppRole.admin:
        return 'admin';
      case AppRole.corporation:
        return 'corporation';
      case AppRole.public:
        return 'public';
    }
  }

  String get label {
    switch (this) {
      case AppRole.admin:
        return 'Administrator';
      case AppRole.corporation:
        return 'Corporation';
      case AppRole.public:
        return 'Public';
    }
  }

  static AppRole fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return AppRole.admin;
      case 'corporation':
      case 'corp':
        return AppRole.corporation;
      default:
        return AppRole.public;
    }
  }
}

class UserRoleAssignment {
  final String userId;
  final AppRole role;
  final String? organization;
  final String? displayName;
  final String? email;
  final DateTime? updatedAt;

  const UserRoleAssignment({
    required this.userId,
    required this.role,
    this.organization,
    this.displayName,
    this.email,
    this.updatedAt,
  });

  factory UserRoleAssignment.fromJson(Map<String, dynamic> json) {
    return UserRoleAssignment(
      userId: json['user_id'] as String,
      role: AppRoleX.fromValue(json['role'] as String?),
      organization: json['organization'] as String?,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      updatedAt: json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String),
    );
  }
}

class UserRoleService {
  UserRoleService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AppRole> fetchCurrentRole() async {
    try {
      await _client.auth.refreshSession();
    } catch (_) {}

    final user = _client.auth.currentUser;
    if (user == null) {
      return AppRole.public;
    }
    final metadataRole = user.appMetadata['role'] ??
        user.appMetadata['app_role'] ??
        user.userMetadata?['role'] ??
        user.userMetadata?['app_role'];
    if (metadataRole != null) {
      return AppRoleX.fromValue(metadataRole.toString());
    }
    final response = await _client
        .from('user_roles')
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();
    if (response == null || response is! Map<String, dynamic>) {
      return AppRole.public;
    }
    return AppRoleX.fromValue(response['role'] as String?);
  }

  Future<List<UserRoleAssignment>> fetchAssignments() async {
    final response = await _client
        .from('user_roles')
        .select('user_id,role,organization,display_name,email,updated_at')
        .order('updated_at', ascending: false);
    if (response is! List) {
      return [];
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(UserRoleAssignment.fromJson)
        .toList();
  }

  Future<UserRoleAssignment?> fetchCurrentAssignment() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }
    final response = await _client
        .from('user_roles')
        .select('user_id,role,organization,display_name,email,updated_at')
        .eq('user_id', user.id)
        .maybeSingle();
    if (response == null || response is! Map<String, dynamic>) {
      return null;
    }
    return UserRoleAssignment.fromJson(response);
  }

  Future<void> upsertAssignment({
    required String userId,
    required AppRole role,
    String? organization,
    String? displayName,
    String? email,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'role': role.value,
      'organization': organization,
      'display_name': displayName,
      'email': email,
      'updated_at': DateTime.now().toIso8601String(),
    }..removeWhere((key, value) => value == null || (value is String && value.trim().isEmpty));

    await _client.from('user_roles').upsert(payload, onConflict: 'user_id');
  }

  Future<void> deleteAssignment(String userId) async {
    await _client.from('user_roles').delete().eq('user_id', userId);
  }
}
