import 'package:supabase_flutter/supabase_flutter.dart';

class LookupOption {
  final String id;
  final String name;

  const LookupOption({required this.id, required this.name});
}

class DogSubmission {
  final String id;
  final String dogNumber;
  final String? dogName;
  final String status;
  final DateTime? updatedAt;

  const DogSubmission({
    required this.id,
    required this.dogNumber,
    required this.dogName,
    required this.status,
    required this.updatedAt,
  });
}

class DogSubmissionDetail {
  final String id;
  final String dogNumber;
  final String? dogName;
  final String dogSex;
  final String? dogBreedId;
  final String? dogColor;
  final DateTime? dogDob;
  final String? microchipId;
  final String? notes;
  final String status;
  final String ownerId;
  final String ownerFirstName;
  final String ownerLastName;
  final String? ownerPhone;
  final String? ownerEmail;
  final String? ownerNationalId;
  final String? ownerAddressLine1;
  final String? ownerAddressLine2;
  final String? ownerRegionId;
  final DateTime? ownershipStartDate;

  const DogSubmissionDetail({
    required this.id,
    required this.dogNumber,
    required this.dogName,
    required this.dogSex,
    required this.dogBreedId,
    required this.dogColor,
    required this.dogDob,
    required this.microchipId,
    required this.notes,
    required this.status,
    required this.ownerId,
    required this.ownerFirstName,
    required this.ownerLastName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.ownerNationalId,
    required this.ownerAddressLine1,
    required this.ownerAddressLine2,
    required this.ownerRegionId,
    required this.ownershipStartDate,
  });
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

  Future<List<DogSubmission>> fetchSubmissions() async {
    final ownerId = await _fetchOwnerId();
    if (ownerId == null) {
      return [];
    }
    final response = await _client
        .from('dogs')
        .select('id,dog_number,name,status,updated_at')
        .eq('current_owner_id', ownerId)
        .order('updated_at', ascending: false);

    return (response as List<dynamic>).map((row) {
      return DogSubmission(
        id: row['id'] as String,
        dogNumber: row['dog_number'] as String,
        dogName: row['name'] as String?,
        status: row['status'] as String? ?? 'pending',
        updatedAt: row['updated_at'] == null ? null : DateTime.parse(row['updated_at'] as String),
      );
    }).toList();
  }

  Future<DogSubmissionDetail?> fetchSubmissionDetail(String dogId) async {
    final dog = await _client
        .from('dogs')
        .select('id,dog_number,name,sex,breed_id,color,dob,microchip_id,notes,status,current_owner_id')
        .eq('id', dogId)
        .maybeSingle();
    if (dog == null) {
      return null;
    }
    final ownerId = dog['current_owner_id'] as String;
    final owner = await _client
        .from('owners')
        .select('id,first_name,last_name,phone,email,national_id,address_line1,address_line2,region_id')
        .eq('id', ownerId)
        .maybeSingle();
    if (owner == null) {
      return null;
    }
    final ownership = await _client
        .from('dog_ownerships')
        .select('start_date')
        .eq('dog_id', dogId)
        .eq('owner_id', ownerId)
        .maybeSingle();
    return DogSubmissionDetail(
      id: dog['id'] as String,
      dogNumber: dog['dog_number'] as String,
      dogName: dog['name'] as String?,
      dogSex: dog['sex'] as String? ?? 'unknown',
      dogBreedId: dog['breed_id'] as String?,
      dogColor: dog['color'] as String?,
      dogDob: dog['dob'] == null ? null : DateTime.parse(dog['dob'] as String),
      microchipId: dog['microchip_id'] as String?,
      notes: dog['notes'] as String?,
      status: dog['status'] as String? ?? 'pending',
      ownerId: owner['id'] as String,
      ownerFirstName: owner['first_name'] as String,
      ownerLastName: owner['last_name'] as String,
      ownerPhone: owner['phone'] as String?,
      ownerEmail: owner['email'] as String?,
      ownerNationalId: owner['national_id'] as String?,
      ownerAddressLine1: owner['address_line1'] as String?,
      ownerAddressLine2: owner['address_line2'] as String?,
      ownerRegionId: owner['region_id'] as String?,
      ownershipStartDate:
          ownership == null || ownership['start_date'] == null ? null : DateTime.parse(ownership['start_date'] as String),
    );
  }

  Future<String> registerDog({
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
    String? existingDogId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final ownerPayload = <String, dynamic>{
      'auth_user_id': userId,
      'first_name': ownerFirstName,
      'last_name': ownerLastName,
      'phone': ownerPhone,
      'email': ownerEmail,
      'national_id': ownerNationalId,
      'address_line1': ownerAddressLine1,
      'address_line2': ownerAddressLine2,
      'region_id': ownerRegionId,
    }..removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    final ownerId = await _upsertOwner(ownerPayload, userId);

    final dogPayload = <String, dynamic>{
      'dog_number': dogNumber,
      'name': dogName,
      'sex': dogSex ?? 'unknown',
      'breed_id': dogBreedId,
      'color': dogColor,
      'dob': dogDob?.toIso8601String().split('T').first,
      'microchip_id': microchipId,
      'status': 'pending',
      'current_owner_id': ownerId,
      'notes': dogNotes,
    }..removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    final resolvedDogId = await _upsertDog(dogPayload, ownerId, existingDogId);
    await _ensureOwnership(
      dogId: resolvedDogId,
      ownerId: ownerId,
      ownershipStartDate: ownershipStartDate,
    );
    return resolvedDogId;
  }

  Future<String> _upsertOwner(Map<String, dynamic> ownerPayload, String userId) async {
    final existingOwner = await _client
        .from('owners')
        .select('id')
        .eq('auth_user_id', userId)
        .maybeSingle();

    if (existingOwner != null) {
      final ownerId = existingOwner['id'] as String;
      if (ownerPayload.isNotEmpty) {
        await _client.from('owners').update(ownerPayload).eq('id', ownerId);
      }
      return ownerId;
    }

    final ownerResponse = await _client.from('owners').insert(ownerPayload).select('id').single();
    return ownerResponse['id'] as String;
  }

  Future<String?> _fetchOwnerId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    final existingOwner = await _client
        .from('owners')
        .select('id')
        .eq('auth_user_id', userId)
        .maybeSingle();
    return existingOwner == null ? null : existingOwner['id'] as String;
  }

  Future<String> _upsertDog(
    Map<String, dynamic> dogPayload,
    String ownerId,
    String? existingDogId,
  ) async {
    if (existingDogId != null) {
      await _client.from('dogs').update(dogPayload).eq('id', existingDogId);
      return existingDogId;
    }

    final existingDog = await _client
        .from('dogs')
        .select('id')
        .eq('dog_number', dogPayload['dog_number'])
        .eq('current_owner_id', ownerId)
        .maybeSingle();

    if (existingDog != null) {
      final dogId = existingDog['id'] as String;
      await _client.from('dogs').update(dogPayload).eq('id', dogId);
      return dogId;
    }

    final dogResponse = await _client.from('dogs').insert(dogPayload).select('id').single();
    return dogResponse['id'] as String;
  }

  Future<void> _ensureOwnership({
    required String dogId,
    required String ownerId,
    required DateTime? ownershipStartDate,
  }) async {
    final ownershipPayload = <String, dynamic>{
      'dog_id': dogId,
      'owner_id': ownerId,
      'start_date': ownershipStartDate?.toIso8601String().split('T').first,
    }..removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    final existingOwnership = await _client
        .from('dog_ownerships')
        .select('id')
        .eq('dog_id', dogId)
        .eq('owner_id', ownerId)
        .maybeSingle();

    if (existingOwnership != null) {
      if (ownershipPayload.containsKey('start_date')) {
        await _client.from('dog_ownerships').update({
          'start_date': ownershipPayload['start_date'],
        }).eq('id', existingOwnership['id']);
      }
      return;
    }

    await _client.from('dog_ownerships').insert(ownershipPayload);
  }
}
