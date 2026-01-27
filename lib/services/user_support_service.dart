import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:local_app_tt/services/civsnap_service.dart';
import 'package:local_app_tt/services/dog_registration_service.dart';
import 'package:local_app_tt/services/user_role_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportUser {
  final String userId;
  final String? displayName;
  final String? email;
  final String? organization;
  final AppRole role;
  final DateTime? updatedAt;

  const SupportUser({
    required this.userId,
    required this.role,
    this.displayName,
    this.email,
    this.organization,
    this.updatedAt,
  });

  factory SupportUser.fromJson(Map<String, dynamic> json) {
    return SupportUser(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      organization: json['organization'] as String?,
      role: AppRoleX.fromValue(json['role'] as String?),
      updatedAt: json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String),
    );
  }
}

class OwnerProfile {
  final String ownerId;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? nationalId;
  final String? addressLine1;
  final String? addressLine2;
  final String? regionId;
  final String? regionName;

  const OwnerProfile({
    required this.ownerId,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.nationalId,
    this.addressLine1,
    this.addressLine2,
    this.regionId,
    this.regionName,
  });
}

class UserSupportService {
  UserSupportService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final DogRegistrationService _dogService = DogRegistrationService.instance;

  SupabaseClient? _buildServiceRoleClient() {
    final url = dotenv.env['SUPABASE_URL'];
    final serviceKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];
    if (url == null || url.trim().isEmpty || serviceKey == null || serviceKey.trim().isEmpty) {
      return null;
    }
    return SupabaseClient(url, serviceKey);
  }

  String? _displayNameFromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) {
      return null;
    }
    final firstName = metadata['first_name'];
    final lastName = metadata['last_name'];
    final displayName = [
      if (firstName is String && firstName.trim().isNotEmpty) firstName.trim(),
      if (lastName is String && lastName.trim().isNotEmpty) lastName.trim(),
    ].join(' ');
    return displayName.isEmpty ? null : displayName;
  }

  DateTime? _parseSupabaseTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(timestamp);
  }

  Future<List<SupportUser>> fetchUsers() async {
    final adminClient = _buildServiceRoleClient();
    final roleClient = adminClient ?? _client;
    final response = await roleClient
        .from('user_roles')
        .select('user_id,role,display_name,email,organization,updated_at')
        .order('updated_at', ascending: false);
    if (response is! List) {
      return [];
    }
    final roleAssignments = response
        .whereType<Map<String, dynamic>>()
        .map(SupportUser.fromJson)
        .toList();

    final ownerClient = adminClient ?? _client;

    final ownerResponse = await ownerClient
        .from('owners')
        .select('auth_user_id,first_name,last_name,email')
        .not('auth_user_id', 'is', null);

    final byUserId = <String, SupportUser>{
      for (final assignment in roleAssignments) assignment.userId: assignment,
    };

    if (ownerResponse is List) {
      for (final row in ownerResponse.whereType<Map<String, dynamic>>()) {
        final userId = row['auth_user_id'] as String?;
        if (userId == null || byUserId.containsKey(userId)) {
          continue;
        }
        final firstName = (row['first_name'] ?? '').toString();
        final lastName = (row['last_name'] ?? '').toString();
        final displayName = '$firstName $lastName'.trim();
        byUserId[userId] = SupportUser(
          userId: userId,
          role: AppRole.public,
          displayName: displayName.isEmpty ? null : displayName,
          email: row['email'] as String?,
        );
      }
    }

    if (adminClient != null) {
      try {
        final users = await adminClient.auth.admin.listUsers();
        for (final user in users) {
          final existing = byUserId[user.id];
          final displayName = _displayNameFromMetadata(user.userMetadata);
          final email = user.email;
          final updatedAt = _parseSupabaseTimestamp(user.updatedAt) ?? _parseSupabaseTimestamp(user.createdAt);
          if (existing == null) {
            byUserId[user.id] = SupportUser(
              userId: user.id,
              role: AppRole.public,
              displayName: displayName,
              email: email,
              updatedAt: updatedAt,
            );
          } else {
            final mergedDisplayName = existing.displayName ?? displayName;
            final mergedEmail = existing.email ?? email;
            final mergedUpdatedAt = existing.updatedAt ?? updatedAt;
            if (mergedDisplayName != existing.displayName ||
                mergedEmail != existing.email ||
                mergedUpdatedAt != existing.updatedAt) {
              byUserId[user.id] = SupportUser(
                userId: existing.userId,
                role: existing.role,
                displayName: mergedDisplayName,
                email: mergedEmail,
                organization: existing.organization,
                updatedAt: mergedUpdatedAt,
              );
            }
          }
        }
      } catch (_) {}
    }

    return byUserId.values.toList();
  }

  Future<SupportUser> createUser({
    required String email,
    required String password,
    required AppRole role,
    String? displayName,
    String? organization,
  }) async {
    final adminClient = _buildServiceRoleClient();
    if (adminClient == null) {
      throw StateError('Service role credentials are required to create users.');
    }

    final metadata = <String, dynamic>{};
    if (displayName != null && displayName.trim().isNotEmpty) {
      metadata['display_name'] = displayName.trim();
    }

    final response = await adminClient.auth.admin.createUser(
      AdminUserAttributes(
        email: email.trim(),
        password: password,
        emailConfirm: true,
        userMetadata: metadata.isEmpty ? null : metadata,
      ),
    );

    final user = response.user;
    if (user == null) {
      throw StateError('User creation failed.');
    }

    await updateUser(
      userId: user.id,
      role: role,
      displayName: displayName,
      email: email.trim(),
      organization: organization,
    );

    return SupportUser(
      userId: user.id,
      role: role,
      displayName: displayName,
      email: email.trim(),
      organization: organization,
      updatedAt: DateTime.now(),
    );
  }

  Future<OwnerProfile?> fetchOwnerProfile(String userId) async {
    final owner = await _client
        .from('owners')
        .select(
          'id,first_name,last_name,phone,email,national_id,address_line1,address_line2,region_id',
        )
        .eq('auth_user_id', userId)
        .maybeSingle();
    if (owner == null) {
      return null;
    }
    final regionId = owner['region_id'] as String?;
    String? regionName;
    if (regionId != null && regionId.isNotEmpty) {
      final regions = await _dogService.fetchRegions();
      for (final region in regions) {
        if (region.id == regionId) {
          regionName = region.name;
          break;
        }
      }
    }
    return OwnerProfile(
      ownerId: owner['id'] as String,
      firstName: (owner['first_name'] ?? '').toString(),
      lastName: (owner['last_name'] ?? '').toString(),
      phone: owner['phone'] as String?,
      email: owner['email'] as String?,
      nationalId: owner['national_id'] as String?,
      addressLine1: owner['address_line1'] as String?,
      addressLine2: owner['address_line2'] as String?,
      regionId: regionId,
      regionName: regionName,
    );
  }

  Future<List<CivSnapReport>> fetchReportsForUser(String userId) async {
    final response = await _client
        .from('civsnap_reports')
        .select(
          'id,title,description,photo_url,latitude,longitude,accuracy_m,location_label,status,created_at,civsnap_votes(count)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    if (response is! List) {
      return [];
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(CivSnapReport.fromJson)
        .toList();
  }

  Future<void> updateUser({
    required String userId,
    required AppRole role,
    String? displayName,
    String? email,
    String? organization,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'role': role.value,
      'display_name': displayName,
      'email': email,
      'organization': organization,
      'updated_at': DateTime.now().toIso8601String(),
    }..removeWhere((key, value) => value == null || (value is String && value.trim().isEmpty));

    await _client.from('user_roles').upsert(payload, onConflict: 'user_id');
  }

  Future<void> deleteUserRole(String userId) async {
    await _client.from('user_roles').delete().eq('user_id', userId);
  }
}
