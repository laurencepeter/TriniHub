import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:functions_client/functions_client.dart';
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
  final String? ownerId;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? nationalId;
  final String? addressLine1;
  final String? addressLine2;
  final String? regionId;
  final String? regionName;

  const SupportUser({
    required this.userId,
    required this.role,
    this.displayName,
    this.email,
    this.organization,
    this.updatedAt,
    this.ownerId,
    this.firstName,
    this.lastName,
    this.phone,
    this.nationalId,
    this.addressLine1,
    this.addressLine2,
    this.regionId,
    this.regionName,
  });

  factory SupportUser.fromJson(Map<String, dynamic> json) {
    return SupportUser(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      organization: json['organization'] as String?,
      role: AppRoleX.fromValue(json['role'] as String?),
      updatedAt: json['updated_at'] == null && json['created_at'] == null
          ? null
          : DateTime.parse((json['updated_at'] ?? json['created_at']) as String),
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
  static const int _adminPageSize = 200;

  SupabaseClient? _buildServiceRoleClient() {
    final url = dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL');
    final serviceKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ??
        const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
    if (url == null || url.trim().isEmpty || serviceKey == null || serviceKey.trim().isEmpty) {
      return null;
    }
    return SupabaseClient(url, serviceKey);
  }

  DateTime? _parseSupabaseTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(timestamp);
  }

  Future<List<User>> _listAdminUsers(SupabaseClient adminClient) async {
    final users = <User>[];
    var page = 1;
    while (true) {
      final batch = await adminClient.auth.admin.listUsers(
        page: page,
        perPage: _adminPageSize,
      );
      if (batch.isEmpty) {
        break;
      }
      users.addAll(batch);
      if (batch.length < _adminPageSize) {
        break;
      }
      page += 1;
    }
    return users;
  }

  Future<List<SupportUser>> fetchUsers() async {
    final adminClient = _buildServiceRoleClient();
    final roleClient = adminClient ?? _client;
    final response = await roleClient
        .from('user_profiles')
        .select('user_id,role,display_name,created_at')
        .order('created_at', ascending: false);
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
        .select(
          'id,auth_user_id,first_name,last_name,phone,email,national_id,address_line1,address_line2,region_id',
        )
        .not('auth_user_id', 'is', null);

    final byUserId = <String, SupportUser>{
      for (final assignment in roleAssignments) assignment.userId: assignment,
    };

    Map<String, String> regionLookup = {};
    if (ownerResponse is List) {
      final regionIds = ownerResponse
          .whereType<Map<String, dynamic>>()
          .map((row) => row['region_id'] as String?)
          .whereType<String>()
          .where((regionId) => regionId.isNotEmpty)
          .toSet();
      if (regionIds.isNotEmpty) {
        final regions = await _dogService.fetchRegions();
        regionLookup = {
          for (final region in regions) region.id: region.name,
        };
      }
      for (final row in ownerResponse.whereType<Map<String, dynamic>>()) {
        final userId = row['auth_user_id'] as String?;
        if (userId == null) {
          continue;
        }
        final firstName = (row['first_name'] ?? '').toString();
        final lastName = (row['last_name'] ?? '').toString();
        final displayName = '$firstName $lastName'.trim();
        final regionId = row['region_id'] as String?;
        final existing = byUserId[userId];
        byUserId[userId] = SupportUser(
          userId: userId,
          role: existing?.role ?? AppRole.public,
          displayName: existing?.displayName ?? (displayName.isEmpty ? null : displayName),
          email: existing?.email ?? row['email'] as String?,
          organization: existing?.organization,
          updatedAt: existing?.updatedAt,
          ownerId: row['id'] as String?,
          firstName: firstName.isEmpty ? existing?.firstName : firstName,
          lastName: lastName.isEmpty ? existing?.lastName : lastName,
          phone: row['phone'] as String? ?? existing?.phone,
          nationalId: row['national_id'] as String? ?? existing?.nationalId,
          addressLine1: row['address_line1'] as String? ?? existing?.addressLine1,
          addressLine2: row['address_line2'] as String? ?? existing?.addressLine2,
          regionId: regionId ?? existing?.regionId,
          regionName: regionLookup[regionId] ?? existing?.regionName,
        );
      }
    }

    try {
      if (adminClient != null) {
        final adminUsers = await _listAdminUsers(adminClient);
        for (final user in adminUsers) {
          final userId = user.id;
          if (userId.isEmpty) {
            continue;
          }
          final email = user.email;
          final createdAt = _parseSupabaseTimestamp(user.createdAt);
          final roleValue =
              user.appMetadata['role'] ?? user.appMetadata['app_role'] ?? user.userMetadata?['role'];
          final authRole = AppRoleX.fromValue(roleValue?.toString());
          final existing = byUserId[userId];
          if (existing == null) {
            byUserId[userId] = SupportUser(
              userId: userId,
              role: authRole,
              email: email,
              updatedAt: createdAt,
            );
          } else {
            final mergedRole = existing.role == AppRole.public ? authRole : existing.role;
            final mergedEmail = existing.email ?? email;
            final mergedUpdatedAt = existing.updatedAt ?? createdAt;
            if (mergedRole != existing.role ||
                mergedEmail != existing.email ||
                mergedUpdatedAt != existing.updatedAt) {
              byUserId[userId] = SupportUser(
                userId: existing.userId,
                role: mergedRole,
                displayName: existing.displayName,
                email: mergedEmail,
                organization: existing.organization,
                updatedAt: mergedUpdatedAt,
                ownerId: existing.ownerId,
                firstName: existing.firstName,
                lastName: existing.lastName,
                phone: existing.phone,
                nationalId: existing.nationalId,
                addressLine1: existing.addressLine1,
                addressLine2: existing.addressLine2,
                regionId: existing.regionId,
                regionName: existing.regionName,
              );
            }
          }
        }
      } else {
        final adminResponse = await roleClient.rpc('admin_list_users');
        if (adminResponse is List) {
          for (final row in adminResponse.whereType<Map<String, dynamic>>()) {
            final userId = row['user_id']?.toString();
            if (userId == null || userId.isEmpty) {
              continue;
            }
            final email = row['email'] as String?;
            final createdAt = _parseSupabaseTimestamp(row['created_at']?.toString());
            final roleValue = row['role'] as String?;
            final rpcRole = AppRoleX.fromValue(roleValue);
            final existing = byUserId[userId];
            if (existing == null) {
              byUserId[userId] = SupportUser(
                userId: userId,
                role: rpcRole,
                email: email,
                updatedAt: createdAt,
              );
            } else {
              final mergedRole = existing.role == AppRole.public ? rpcRole : existing.role;
              final mergedEmail = existing.email ?? email;
              final mergedUpdatedAt = existing.updatedAt ?? createdAt;
              if (mergedRole != existing.role ||
                  mergedEmail != existing.email ||
                  mergedUpdatedAt != existing.updatedAt) {
                byUserId[userId] = SupportUser(
                  userId: existing.userId,
                  role: mergedRole,
                  displayName: existing.displayName,
                  email: mergedEmail,
                  organization: existing.organization,
                  updatedAt: mergedUpdatedAt,
                  ownerId: existing.ownerId,
                  firstName: existing.firstName,
                  lastName: existing.lastName,
                  phone: existing.phone,
                  nationalId: existing.nationalId,
                  addressLine1: existing.addressLine1,
                  addressLine2: existing.addressLine2,
                  regionId: existing.regionId,
                  regionName: existing.regionName,
                );
              }
            }
          }
        }
      }
    } catch (_) {}

    final users = byUserId.values.toList();
    users.sort((a, b) {
      final left = a.updatedAt;
      final right = b.updatedAt;
      if (left == null && right == null) {
        return (a.displayName ?? a.email ?? a.userId)
            .toLowerCase()
            .compareTo((b.displayName ?? b.email ?? b.userId).toLowerCase());
      }
      if (left == null) {
        return 1;
      }
      if (right == null) {
        return -1;
      }
      return right.compareTo(left);
    });
    return users;
  }

  Future<SupportUser> createUser({
    required String email,
    required String password,
    required AppRole role,
    String? displayName,
    String? organization,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw StateError('Not logged in.');
    }

    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'admin-create-user',
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: {
          'email': email.trim(),
          'temp_password': password,
          'role': role.value,
          'display_name': displayName,
          'corporation_id': organization?.trim().isEmpty ?? true ? null : organization?.trim(),
        },
      );
    } on FunctionException catch (error) {
      final details = error.details;
      final message = details is Map && details['message'] != null
          ? details['message'].toString()
          : details is String && details.isNotEmpty
              ? details
              : error.reasonPhrase ?? 'User creation failed.';
      throw StateError(message);
    }

    final data = response.data;
    final payload = data is String
        ? jsonDecode(data) as Map<String, dynamic>
        : Map<String, dynamic>.from(data as Map);
    final userId = payload['user_id']?.toString();
    if (userId == null || userId.isEmpty) {
      throw StateError('User creation failed.');
    }

    await updateUser(
      userId: userId,
      role: role,
      displayName: displayName,
      email: email.trim(),
      organization: organization,
    );

    return SupportUser(
      userId: userId,
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
    final trimmedOrg = organization?.trim();
    final payload = <String, dynamic>{
      'user_id': userId,
      'role': role.value,
      'display_name': displayName,
      'corporation_id': trimmedOrg,
    }..removeWhere((key, value) => value == null || (value is String && value.trim().isEmpty));

    await _client.from('user_profiles').upsert(payload, onConflict: 'user_id');
  }

  Future<void> deleteUserRole(String userId) async {
    await _client.from('user_profiles').delete().eq('user_id', userId);
  }

  Future<void> updateOwnerProfile({
    required String userId,
    required String firstName,
    required String lastName,
    String? phone,
    String? email,
    String? nationalId,
    String? addressLine1,
    String? addressLine2,
    String? regionId,
  }) async {
    String? normalize(String? value) {
      final trimmed = value?.trim() ?? '';
      return trimmed.isEmpty ? null : trimmed;
    }

    final payload = <String, dynamic>{
      'auth_user_id': userId,
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'phone': normalize(phone),
      'email': normalize(email),
      'national_id': normalize(nationalId),
      'address_line1': normalize(addressLine1),
      'address_line2': normalize(addressLine2),
      'region_id': normalize(regionId),
    };

    await _client.from('owners').upsert(payload, onConflict: 'auth_user_id');
  }
}
