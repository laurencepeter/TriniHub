import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_app_tt/services/owner_service.dart';

class SignUpOutcome {
  SignUpOutcome({
    required this.user,
    required this.requiresEmailVerification,
  });

  final User? user;
  final bool requiresEmailVerification;

  bool get hasActiveSession => user != null && !requiresEmailVerification;
}

class AuthService {
  AuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        _ownerService = OwnerService(client ?? Supabase.instance.client);

  final SupabaseClient _client;
  final OwnerService _ownerService;

  String? _signUpRedirectTo() {
    final redirect = dotenv.env['SUPABASE_SIGNUP_REDIRECT'];
    if (redirect == null || redirect.trim().isEmpty) {
      return null;
    }
    return redirect;
  }

  String? _metadataString(Map<String, dynamic>? metadata, String key) {
    final value = metadata?[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  bool _shouldRetryWithoutRedirect(AuthException error) {
    final message = error.message.toLowerCase();
    return message.contains('error sending confirmation email') ||
        message.contains('unexpected_failure') ||
        message.contains('unexpected failure') ||
        message.contains('invalid redirect') ||
        message.contains('redirect url') ||
        message.contains('redirect_uri') ||
        message.contains('redirect uri') ||
        message.contains('redirect');
  }

  Future<User?> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user != null) {
      await _ownerService.ensureOwnerProfile(
        firstName: _metadataString(user.userMetadata, 'first_name'),
        lastName: _metadataString(user.userMetadata, 'last_name'),
        phone: _metadataString(user.userMetadata, 'phone'),
        regionId: _metadataString(user.userMetadata, 'region_id'),
      );
    }
    return user;
  }

  Future<void> signOut() async {
    await _client.auth.signOut(scope: SignOutScope.global);
  }

  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? regionId,
  }) async {
    final metadata = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'region_id': regionId,
    }..removeWhere((key, value) => value == null || (value is String && value.trim().isEmpty));
    final redirectTo = _signUpRedirectTo();
    AuthResponse response;
    try {
      response = await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata.isEmpty ? null : metadata,
        emailRedirectTo: redirectTo,
      );
    } on AuthException catch (error) {
      if (_shouldRetryWithoutRedirect(error) && redirectTo != null) {
        response = await _client.auth.signUp(
          email: email,
          password: password,
          data: metadata.isEmpty ? null : metadata,
          emailRedirectTo: null,
        );
      } else {
        rethrow;
      }
    }
    final user = response.user ?? response.session?.user ?? _client.auth.currentUser;
    final requiresEmailVerification = response.session == null;
    if (user == null && !requiresEmailVerification) {
      throw const AuthException('Unable to create your account. Please try again.');
    }
    if (!requiresEmailVerification && user != null) {
      await _ownerService.ensureOwnerProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        regionId: regionId,
      );
    }
    return SignUpOutcome(
      user: user,
      requiresEmailVerification: requiresEmailVerification,
    );
  }

  Future<void> resendSignUpEmail({required String email}) async {
    final redirectTo = _signUpRedirectTo();
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: redirectTo,
      );
    } on AuthException catch (error) {
      if (_shouldRetryWithoutRedirect(error) && redirectTo != null) {
        await _client.auth.resend(
          type: OtpType.signup,
          email: email,
          emailRedirectTo: null,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<OwnerProfile> ensureOwnerProfile() async {
    return _ownerService.ensureOwnerProfile();
  }

  OwnerService get ownerService => _ownerService;
}
