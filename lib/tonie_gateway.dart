import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'jwt_utils.dart';
import 'models.dart';

const endpoint = 'https://api.tonie.cloud/v2';

typedef JwtUpdateCallback = void Function(String jwt);

class TonieGateway {
  final JwtUpdateCallback onJwtUpdated;
  final String email;
  final String password;

  final http.Client _client;

  String _jwt;

  TonieGateway(this.onJwtUpdated, this.email, this.password, this._jwt)
      : _client = http.Client();

  Future<List<Household>> getHouseholds() async {
    var response = await _request('get', 'households');
    return (response as List).map((map) => Household.fromMap(map)).toList();
  }

  Future<List<Tonie>> getTonies(String householdId) async {
    var response =
        await _request('get', 'households/$householdId/creativetonies');
    return (response as List).map((map) => Tonie.fromMap(map)).toList();
  }

  Future<Tonie> getTonie(String householdId, String tonieId) async {
    var response = await _request(
        'get', 'households/$householdId/creativetonies/$tonieId');
    return Tonie.fromMap(response);
  }

  Future<void> updateTonie(String householdId, Tonie tonie) async => _request(
        'patch',
        'households/$householdId/creativetonies/${tonie.id}',
        tonie.toMap(),
      );

  Future<void> _login() async {
    var response = await _request(
        'post',
        'sessions',
        {
          'email': email,
          'password': password,
        },
        true);
    _jwt = response['jwt'];
    onJwtUpdated(_jwt);
  }

  dynamic _request(String method, String path,
      [Map<String, dynamic> body, bool isLogin = false]) async {
    if (!isLogin && (_jwt == null || !JwtUtils.isValid(_jwt))) {
      await _login();
    }

    var request = http.Request(method, Uri.parse('$endpoint/$path'))
      ..headers.addAll({
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $_jwt',
      })
      ..body = jsonEncode(body);
    var response = await _client.send(request);

    var responseBody = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          '${response.statusCode} ${response.reasonPhrase} $responseBody');
    }

    return jsonDecode(responseBody);
  }
}
