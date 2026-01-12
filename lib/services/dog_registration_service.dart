import 'package:supabase_flutter/supabase_flutter.dart';

class LookupOption {
  final String id;
  final String name;

  const LookupOption({required this.id, required this.name});
}

class DogRegistrationService {
  DogRegistrationService._();
  static final DogRegistrationService instance = DogRegistrationService._();

  final SupabaseClient _client = Supabase.instance.client;

  Future<List<LookupOption>> fetchBreeds() async {
    final response = await _client.from('breeds').select('id,name').order('name');
    return (response as List<dynamic>)
        .map((row) => LookupOption(id: row['id'] as String, name: row['name'] as String))
        .toList();
  }

  Future<List<LookupOption>> fetchRegions() async {
    final response = await _client.from('regions').select('id,name').order('name');
    return (response as List<dynamic>)
        .map((row) => LookupOption(id: row['id'] as String, name: row['name'] as String))
        .toList();
  }

  Future<void> registerDog({
    required String ownerFirstName,
    required String ownerLastName,
    String? ownerPhone,
    String? ownerEmail,
    String? ownerNationalId,
    String? ownerAddressLine1,
    String? ownerAddressLine2,
    String? ownerRegionId,
    required String dogNumber,
    String? dogName,
    String? dogSex,
    String? dogBreedId,
    String? dogColor,
    DateTime? dogDob,
    String? microchipId,
    String? dogNotes,
    DateTime? ownershipStartDate,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final ownerPayload = <String, dynamic>{
      'user_id': userId,
      'first_name': ownerFirstName,
      'last_name': ownerLastName,
      'phone': ownerPhone,
      'email': ownerEmail,
      'national_id': ownerNationalId,
      'address_line1': ownerAddressLine1,
      'address_line2': ownerAddressLine2,
      'region_id': ownerRegionId,
    }..removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    final ownerId = await _ensureOwner(ownerPayload, userId);

    final dogPayload = <String, dynamic>{
      'dog_number': dogNumber,
      'name': dogName,
      'sex': dogSex ?? 'unknown',
      'breed_id': dogBreedId,
      'color': dogColor,
      'dob': dogDob?.toIso8601String().split('T').first,
      'microchip_id': microchipId,
      'status': 'active',
      'current_owner_id': ownerId,
      'notes': dogNotes,
    }..removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    final dogResponse = await _client.from('dogs').insert(dogPayload).select('id').single();
    final dogId = dogResponse['id'] as String;

    final ownershipPayload = <String, dynamic>{
      'dog_id': dogId,
      'owner_id': ownerId,
      'start_date': ownershipStartDate?.toIso8601String().split('T').first,
    }..removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    await _client.from('dog_ownerships').insert(ownershipPayload);
  }

  Future<String> _ensureOwner(Map<String, dynamic> ownerPayload, String userId) async {
    final existingOwner = await _client
        .from('owners')
        .select('id')
        .eq('auth_user_id', userId)
        .maybeSingle();

    if (existingOwner != null) {
      return existingOwner['id'] as String;
    }

    final ownerResponse = await _client.from('owners').insert(ownerPayload).select('id').single();
    return ownerResponse['id'] as String;
  }
}
