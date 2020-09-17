import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';

const loginUrl =
    'https://login.tonies.com/auth/realms/tonies/protocol/openid-connect/token';
const apiUrl = 'https://api.tonie.cloud/v2';

typedef TokenUpdateCallback = void Function(String tokenJson);

class TonieGateway {
  final TokenUpdateCallback onTokenUpdated;

  final http.Client _client;

  Token _token;

  bool get isLoggedIn => _token != null;

  TonieGateway(this.onTokenUpdated, String tokenJson)
      : _client = http.Client(),
        _token = tokenJson != null && tokenJson.isNotEmpty
            ? Token.fromJson(tokenJson)
            : null;

  Future<void> login(String username, String password) =>
      _authenticate(username, password);

  Future<void> refreshToken() => _authenticate();

  void logout() {
    _token = null;
    onTokenUpdated(null);
  }

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

  Future<void> _authenticate([String username, String password]) async {
    final isRefresh = username == null;

    final response = await http.post(
      loginUrl,
      body: {
        'scope': 'openid',
        'client_id': 'my-tonies',
        if (isRefresh) ...{
          'grant_type': 'refresh_token',
          'refresh_token': _token.refreshToken,
        },
        if (!isRefresh) ...{
          'grant_type': 'password',
          'username': username,
          'password': password,
        }
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      logout();
      throw Exception(
          '${response.statusCode} ${response.reasonPhrase} ${response.body}');
    }

    final map = jsonDecode(response.body);
    final expiresIn = map['expires_in'] - (map['expires_in'] * 0.05).floor();
    _token = Token(
      map['access_token'],
      map['refresh_token'],
      DateTime.now().add(Duration(seconds: expiresIn)),
    );

    onTokenUpdated(_token.toJson());
  }

  dynamic _request(String method, String path,
      [Map<String, dynamic> body]) async {
    if (!isLoggedIn) {
      throw Exception('Logged out');
    }

    if (_token.expired) {
      await refreshToken();
    }

    var request = http.Request(method, Uri.parse('$apiUrl/$path'))
      ..headers.addAll({
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer ${_token.accessToken}',
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

class Token {
  final String accessToken;
  final String refreshToken;
  final DateTime expiry;

  bool get expired => DateTime.now().isAfter(expiry);

  Token(this.accessToken, this.refreshToken, this.expiry)
      : assert(accessToken != null),
        assert(refreshToken != null),
        assert(expiry != null);

  factory Token.fromJson(String json) {
    final map = jsonDecode(json);
    return Token(
        map['accessToken'], map['refreshToken'], DateTime.parse(map['expiry']));
  }

  String toJson() => jsonEncode({
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiry': expiry.toUtc().toIso8601String(),
      });
}
