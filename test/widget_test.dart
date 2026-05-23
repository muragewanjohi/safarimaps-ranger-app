import 'package:flutter_test/flutter_test.dart';
import 'package:ranger/data/datasources/auth_remote_datasource.dart';

void main() {
  group('AuthRemoteDataSource validation', () {
    late AuthRemoteDataSource auth;

    setUp(() {
      auth = AuthRemoteDataSource(null);
    });

    test('validateEmail accepts valid email', () {
      expect(auth.validateEmail('ranger@safarimap.com'), isTrue);
    });

    test('validateEmail rejects invalid email', () {
      expect(auth.validateEmail('not-an-email'), isFalse);
    });

    test('validatePassword requires minimum length', () {
      expect(auth.validatePassword('123'), isNotNull);
      expect(auth.validatePassword('123456'), isNull);
    });

    test('validateRangerId accepts ABC-123 format', () {
      expect(auth.validateRangerId('ABC-123'), isTrue);
      expect(auth.validateRangerId('abc-123'), isFalse);
    });
  });
}
