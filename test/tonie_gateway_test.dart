import 'package:test/test.dart';
import 'package:tonie_shuffle/models.dart';
import 'package:tonie_shuffle/tonie_gateway.dart';

import 'config.dart';

void main() {
  group('login', () {
    test('login', () async {
      var gateway = await TonieGateway.login(email, password);
      expect(gateway, isNotNull);
    });
  });

  group('operations', () {
    var gateway = TonieGateway(jwt);

    test('get households', () async {
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
