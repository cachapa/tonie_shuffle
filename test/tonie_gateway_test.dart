import 'package:test/test.dart';
import 'package:tonie_shuffle/models.dart';
import 'package:tonie_shuffle/tonie_gateway.dart';

import 'config.dart';

Future<void> main() async {
  var gateway = TonieGateway((_) {}, null);

  group('auth', () {
    test('login', () async {
      await gateway.login(email, password);
      expect(gateway.isLoggedIn, isTrue);
    });

    test('refresh token', () async {
      await gateway.refreshToken();
      expect(gateway.isLoggedIn, isTrue);
    });

    test('logout', () async {
      await gateway.logout();
      expect(gateway.isLoggedIn, isFalse);
    });
  });

  group('operations', () {
    test('get households', () async {
      await gateway.login(email, password);
      var households = await gateway.getHouseholds();
      print(households);
      expect(gateway, isNotNull);
    });

    test('get tonies', () async {
      var tonies = await gateway.getTonies(householdId);
      print(tonies);
      expect(gateway, isNotNull);
    });

    test('get single tonie', () async {
      var tonie = await gateway.getTonie(householdId, tonieId);
      print(tonie);
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
