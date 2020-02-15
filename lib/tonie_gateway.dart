import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';

const endpoint = 'https://api.tonie.cloud/v2';

class TonieGateway {
  final String jwt;
  final http.Client _client;

  TonieGateway(this.jwt) : _client = http.Client();

  static Future<String> login(String email, String password) async {
    var response = await _post(http.Client(), 'sessions', {
      'email': email,
      'password': password,
    });
    return response['jwt'];
  }

  Future<List<Household>> getHouseholds() async {
    var response = await _get(_client, 'households', jwt);
    return (response as List).map((map) => Household.fromMap(map)).toList();
  }

  Future<List<Tonie>> getTonies(String householdId) async {
    var response =
        await _get(_client, 'households/$householdId/creativetonies', jwt);
    return (response as List).map((map) => Tonie.fromMap(map)).toList();
  }

  Future<Tonie> getTonie(String householdId, String tonieId) async {
    var response = await _get(
        _client, 'households/$householdId/creativetonies/$tonieId', jwt);
    return Tonie.fromMap(response);
  }

  Future<void> updateTonie(String householdId, Tonie tonie) async => _patch(
      _client,
      'households/$householdId/creativetonies/${tonie.id}',
      tonie.toMap(),
      jwt);

  static dynamic _get(http.Client client, String path, String jwt) async {
    var response = await client.get('$endpoint/$path', headers: {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer $jwt',
    });

    return _handleResponse(response);
  }

  static dynamic _post(http.Client client, String path, Map body,
      [String jwt]) async {
    var response = await client.post('$endpoint/$path',
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          if (jwt != null) HttpHeaders.authorizationHeader: 'Bearer $jwt',
        },
        body: jsonEncode(body));

    return _handleResponse(response);
  }

  static dynamic _patch(
      http.Client client, String path, Map body, String jwt) async {
    var response = await client.patch('$endpoint/$path',
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          if (jwt != null) HttpHeaders.authorizationHeader: 'Bearer $jwt',
        },
        body: jsonEncode(body));

    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          '${response.statusCode} ${response.reasonPhrase} ${response.body}');
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
