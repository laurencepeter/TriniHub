import 'package:supabase_flutter/supabase_flutter.dart';

String mapSupabaseError(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'The email or password is incorrect.';
    }
    if (message.contains('user already registered')) {
      return 'An account already exists for this email.';
    }
    if (message.contains('email') && message.contains('confirm')) {
      return 'Check your email to confirm your account.';
    }
    return error.message;
  }
  if (error is PostgrestException) {
    final code = error.code ?? '';
    if (code == '42501' || error.message.toLowerCase().contains('row-level security')) {
      return 'You do not have permission to perform this action.';
    }
    if (error.message.toLowerCase().contains('duplicate key')) {
      return 'That record already exists.';
    }
    return error.message;
  }
  return 'Something went wrong. Please try again.';
}
