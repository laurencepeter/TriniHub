import 'package:supabase_flutter/supabase_flutter.dart';

class OwnerProfile {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? regionId;
  final String? nationalId;

  const OwnerProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.regionId,
    required this.nationalId,
  });

  bool get isIncomplete =>
      (firstName == null || firstName!.trim().isEmpty) ||
      (lastName == null || lastName!.trim().isEmpty);
}

class OwnerService {
  OwnerService(this._client);

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  Future<OwnerProfile?> fetchOwnerProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    final response = await _client
        .from('owners')
        .select('id,first_name,last_name,phone,region_id,national_id')
        .eq('auth_user_id', userId)
        .maybeSingle();
    if (response == null) {
      return null;
    }
    return OwnerProfile(
      id: response['id'] as String,
      firstName: response['first_name'] as String?,
      lastName: response['last_name'] as String?,
      phone: response['phone'] as String?,
      regionId: response['region_id'] as String?,
      nationalId: response['national_id'] as String?,
    );
  }

  Future<OwnerProfile> upsertOwnerProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? regionId,
    String? nationalId,
  }) async {
    final payload = <String, dynamic>{
      'auth_user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'region_id': regionId,
      'national_id': nationalId,
    }..removeWhere((key, value) => value == null || (value is String && value.trim().isEmpty));

    final existing = await _client
        .from('owners')
        .select('id,first_name,last_name,phone,region_id,national_id')
        .eq('auth_user_id', userId)
        .maybeSingle();

    if (existing != null) {
      final updated = await _client
          .from('owners')
          .update(payload)
          .eq('id', existing['id'])
          .select('id,first_name,last_name,phone,region_id,national_id')
          .single();
      return OwnerProfile(
        id: updated['id'] as String,
        firstName: updated['first_name'] as String?,
        lastName: updated['last_name'] as String?,
        phone: updated['phone'] as String?,
        regionId: updated['region_id'] as String?,
        nationalId: updated['national_id'] as String?,
      );
    }

    final inserted = await _client
        .from('owners')
        .insert(payload)
        .select('id,first_name,last_name,phone,region_id,national_id')
        .single();
    return OwnerProfile(
      id: inserted['id'] as String,
      firstName: inserted['first_name'] as String?,
      lastName: inserted['last_name'] as String?,
      phone: inserted['phone'] as String?,
      regionId: inserted['region_id'] as String?,
      nationalId: inserted['national_id'] as String?,
    );
  }

  Future<OwnerProfile> ensureOwnerProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? regionId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('User not authenticated');
    }
    final existing = await fetchOwnerProfile();
    if (existing != null) {
      if ((firstName != null && firstName.trim().isNotEmpty) ||
          (lastName != null && lastName.trim().isNotEmpty) ||
          (phone != null && phone.trim().isNotEmpty) ||
          (regionId != null && regionId.trim().isNotEmpty)) {
        return upsertOwnerProfile(
          userId: userId,
          firstName: firstName ?? existing.firstName,
          lastName: lastName ?? existing.lastName,
          phone: phone ?? existing.phone,
          regionId: regionId ?? existing.regionId,
        );
      }
      return existing;
    }

    return upsertOwnerProfile(
      userId: userId,
      firstName: firstName ?? 'New',
      lastName: lastName ?? 'User',
      phone: phone,
      regionId: regionId,
    );
  }

  Future<OwnerProfile> updateCurrentUserProfile({
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('User not authenticated');
    }
    return upsertOwnerProfile(
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
  }
}
