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

  Future<List<SupportUser>> fetchUsers() async {
    final response = await _client
        .from('user_roles')
        .select('user_id,role,display_name,email,organization,updated_at')
        .order('updated_at', ascending: false);
    if (response is! List) {
      return [];
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(SupportUser.fromJson)
        .toList();
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
}
