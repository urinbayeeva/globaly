import 'package:flutter_test/flutter_test.dart';

import 'package:globaly/core/utils/input_validators.dart';

void main() {
  group('InputValidators', () {
    test('email accepts a valid address', () {
      expect(InputValidators.email('user@example.com'), isNull);
    });

    test('email rejects malformed input', () {
      expect(InputValidators.email('nope'), isNotNull);
      expect(InputValidators.email(''), isNotNull);
      expect(InputValidators.email(null), isNotNull);
    });

    test('password requires 8+ chars', () {
      expect(InputValidators.password('1234567'), isNotNull);
      expect(InputValidators.password('12345678'), isNull);
    });
  });
}
