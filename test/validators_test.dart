import 'package:flutter_test/flutter_test.dart';
import 'package:local_app_tt/utils/validators.dart';

void main() {
  group('Validators', () {
    test('validates email format', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('invalid'), isNotNull);
      expect(Validators.email('test@example.com'), isNull);
    });

    test('validates password length', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('short', minLength: 8), isNotNull);
      expect(Validators.password('longenough', minLength: 8), isNull);
    });

    test('validates confirm password', () {
      expect(Validators.confirmPassword('', 'secret123'), isNotNull);
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
      expect(Validators.confirmPassword('mismatch', 'secret123'), isNotNull);
    });
  });
}
