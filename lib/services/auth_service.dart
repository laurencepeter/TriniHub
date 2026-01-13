import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_app_tt/services/owner_service.dart';

class AuthService {
  AuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        _ownerService = OwnerService(client ?? Supabase.instance.client);

  final SupabaseClient _client;
  final OwnerService _ownerService;

  Future<User?> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }

  Future<void> signOut() async {
    await _client.auth.signOut(scope: SignOutScope.global);
  }

  Future<User?> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? regionId,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user ?? _client.auth.currentUser;
    if (user != null) {
      await _ownerService.ensureOwnerProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        regionId: regionId,
      );
    }
    return user;
  }

  Future<OwnerProfile> ensureOwnerProfile() async {
    return _ownerService.ensureOwnerProfile();
  }

  OwnerService get ownerService => _ownerService;
}
