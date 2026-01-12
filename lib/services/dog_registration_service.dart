import 'package:supabase_flutter/supabase_flutter.dart';

class DogRegistrationService {
  DogRegistrationService._();
  static final DogRegistrationService instance = DogRegistrationService._();

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> registerDog({
    required String ownerName,
    required String ownerContact,
    required String dogName,
    required String breed,
    required double ageYears,
    required double weight,
    String? microchipId,
    required String vaccinationStatus,
    String? temperamentNotes,
    String? careNotes,
    required bool isNeutered,
    required int activityLevel,
    required List<String> traits,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client.from('dog_registrations').insert({
      'user_id': userId,
      'owner_name': ownerName,
      'owner_contact': ownerContact,
      'dog_name': dogName,
      'breed': breed,
      'age_years': ageYears,
      'weight': weight,
      'microchip_id': microchipId,
      'vaccination_status': vaccinationStatus,
      'temperament_notes': temperamentNotes,
      'care_notes': careNotes,
      'is_neutered': isNeutered,
      'activity_level': activityLevel,
      'traits': traits,
    });
  }
}
