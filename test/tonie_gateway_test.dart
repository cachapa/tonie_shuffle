import 'package:test/test.dart';
import 'package:tonie_shuffle/models.dart';
import 'package:tonie_shuffle/tonie_gateway.dart';

import 'config.dart';

Future<void> main() async {
  final gateway = TonieGateway((_) => {}, null);

  setUp(() async {
    // Avoid spamming auth calls
    if (!gateway.isLoggedIn) {
      await gateway.login(email, password);
    }
  });

  group('token', () {
    test('valid token', () async {
      final expiry =
          DateTime.now().add(Duration(days: 1)).toUtc().toIso8601String();
      final token = Token.fromJson(
          '{"accessToken":"","refreshToken":"","expiry":"$expiry"}');
      expect(token.isExpired, isFalse);
    });

    test('expired token', () async {
      final token =
          Token('', '', DateTime.now().subtract(Duration(seconds: 1)));
      expect(token.isExpired, isTrue);
    });
  });

  group('auth', () {
    test('login', () async {
      expect(gateway.isLoggedIn, isTrue);
    });

    test('refresh token', () async {
      final expired = Token(
          gateway.token.accessToken,
          gateway.token.refreshToken,
          DateTime.now().subtract(Duration(seconds: 1)));
      gateway.token = expired;
      await gateway.getHouseholds();
      expect(gateway.isLoggedIn, isTrue);
      expect(gateway.token.isExpired, isFalse);
    });

    test('logout on failed refresh', () async {
      final expired = Token(gateway.token.accessToken, 'bad_refresh_token',
          DateTime.now().subtract(Duration(seconds: 1)));
      gateway.token = expired;
      await expectLater(gateway.getHouseholds(), throwsA(anything));
      expect(gateway.isLoggedIn, isFalse);
    });

    test('logout', () async {
      await gateway.logout();
      expect(gateway.isLoggedIn, isFalse);
    });
  });

  group('operations', () {
    test('get households', () async {
      var households = await gateway.getHouseholds();
      expect(households, isNotNull);
    });

    test('get tonies', () async {
      var tonies = await gateway.getTonies(householdId);
      expect(tonies, isNotNull);
    });

    test('get single tonie', () async {
      var tonie = await gateway.getTonie(householdId, tonieId);
      expect(tonie, isNotNull);
    });

    test('update tonie', () async {
      var tonie = await gateway.getTonie(householdId, tonieId);
      // Reverse playlist order
      tonie = Tonie(tonie.id, tonie.name, tonie.chapters.reversed.toList());
      await gateway.updateTonie(householdId, tonie);
      var remoteTonie = await gateway.getTonie(householdId, tonieId);
      expect(tonie.toMap(), remoteTonie.toMap());
    });
  });
}
