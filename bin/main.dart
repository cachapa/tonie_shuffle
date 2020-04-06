import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:tonie_shuffle/models.dart';
import 'package:tonie_shuffle/tonie_gateway.dart';

const configPath = '.tonie-shuffle';
const tokenFilename = 'token';

void main(List<String> arguments) {
  CommandRunner('tonie-shuffle', 'Utility to manage your Toniebox.')
    ..addCommand(Login())
    ..addCommand(Logout())
    ..addCommand(ListHouseholds())
    ..addCommand(ListTonies())
    ..addCommand(ShuffleTonie())
    ..addCommand(AutoShuffle())
    ..run(arguments).catchError((error) {
      if (error is! UsageException) throw error;
      print(error);
      exit(64); // Exit code 64 indicates a usage error.
    }).whenComplete(() => exit(0));
}

class Login extends Command {
  @override
  final name = 'login';
  @override
  final description = 'Login to your account.';
  @override
  final invocation = 'EMAIL PASSWORD';

  @override
  Future<void> run() async {
    var args = argResults.rest;
    if (args.length != 2) {
      printUsage();
      exit(64);
    }

    var email = args[0];
    var password = args[1];

    try {
      var jwt = await TonieGateway.login(email, password);

      // Store the jwt in the user's directory
      var home = Platform.environment['HOME'];
      Directory('$home/$configPath').createSync();
      File('$home/$configPath/$tokenFilename').writeAsStringSync(jwt);

      print('Logged in.');
    } catch (e) {
      print(e);
      exit(1);
    }
  }
}

class Logout extends Command {
  @override
  final name = 'logout';
  @override
  final description = 'Logout from your account.';

  @override
  Future<void> run() async {
    try {
      // Delete the jwt from the user's directory
      var home = Platform.environment['HOME'];
      File('$home/$configPath/$tokenFilename').deleteSync();

      print('Logged out.');
    } catch (e) {
      print(e);
      exit(1);
    }
  }
}

abstract class TonieCommand extends Command {
  @override
  Future<void> run() async {
    try {
      // Try to load jwt from disk
      var home = Platform.environment['HOME'];
      var jwt = File('$home/$configPath/$tokenFilename').readAsStringSync();
      await runTonie(TonieGateway(jwt));
    } catch (e) {
      print('Please use the login command to authenticate first.');
      exit(1);
    }
  }

  Future<void> runTonie(TonieGateway gateway);
}

class ListHouseholds extends TonieCommand {
  @override
  final name = 'households';
  @override
  final description = 'List households.';

  @override
  Future<void> runTonie(TonieGateway gateway) async {
    try {
      var households = await gateway.getHouseholds();
      for (var household in households) {
        print('${household.id} ${household.name}');
      }
    } catch (e) {
      print(e);
      exit(1);
    }
  }
}

class ListTonies extends TonieCommand {
  @override
  final name = 'tonies';
  @override
  final description = 'List creative tonies.';
  @override
  final invocation = 'HOUSEHOLD_ID';

  @override
  Future<void> runTonie(TonieGateway gateway) async {
    var args = argResults.rest;
    if (args.length != 1) {
      printUsage();
      exit(64);
    }

    var householdId = args[0];

    try {
      var tonies = await gateway.getTonies(householdId);
      for (var tonie in tonies) {
        print('${tonie.id} ${tonie.name}');
      }
    } catch (e) {
      print(e);
      exit(1);
    }
  }
}

class ShuffleTonie extends TonieCommand {
  @override
  final name = 'shuffle';
  @override
  final description = 'Shuffle creative tonie.';
  @override
  final invocation = 'HOUSEHOLD_ID TONIE_ID';

  @override
  Future<void> runTonie(TonieGateway gateway) async {
    var args = argResults.rest;
    if (args.length != 2) {
      printUsage();
      exit(64);
    }

    var householdId = args[0];
    var tonieId = args[1];

    try {
      var tonie = await gateway.getTonie(householdId, tonieId);
      await _shuffle(gateway, householdId, tonie);
    } catch (e) {
      print(e);
      exit(1);
    }
  }
}

class AutoShuffle extends TonieCommand {
  @override
  final name = 'autoshuffle';
  @override
  final description = 'Shuffle all creative tonies whose name ends with "[s]".';

  @override
  Future<void> runTonie(TonieGateway gateway) async {
    try {
      // Iterate through households
      var households = await gateway.getHouseholds();
      for (var household in households) {
        var tonies = await gateway.getTonies(household.id);
        tonies.retainWhere((tonie) => tonie.name.endsWith('[s]'));
        if (tonies.isEmpty) {
          print('No creative tonies ending with "[s]" found.');
        }

        for (var tonie in tonies) {
          await _shuffle(gateway, household.id, tonie);
        }
      }
    } catch (e) {
      print(e);
      exit(1);
    }
  }
}

Future<void> _shuffle(
    TonieGateway gateway, String householdId, Tonie tonie) async {
  tonie = Tonie(tonie.id, tonie.name, tonie.chapters..shuffle());
  await gateway.updateTonie(householdId, tonie);
  print('Shuffled ${tonie.name}');
}
