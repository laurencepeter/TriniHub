class Validators {
  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email is required.';
    }
    const emailRegex = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    if (!RegExp(emailRegex).hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    final raw = value ?? '';
    if (raw.isEmpty) {
      return 'Password is required.';
    }
    if (raw.length < minLength) {
      return 'Password must be at least $minLength characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final raw = value ?? '';
    if (raw.isEmpty) {
      return 'Confirm your password.';
    }
    if (raw != original) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? requiredField(String? value, {String label = 'This field'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '$label is required.';
    }
    return null;
  }
}
