import 'dart:convert';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:package_info/package_info.dart';
import 'package:reddigram/api/api.dart';
import 'package:reddigram/consts.dart';

class RedditRepository {
  Dio _client;
  String _refreshToken;

  RedditRepository() {
    _client = Dio(BaseOptions(
      baseUrl: 'https://www.reddit.com',
    ));

    _client.interceptors.add(InterceptorsWrapper(
      onError: (DioError e) {
        if (e.response.statusCode == 401 &&
            !e.request.path.contains('access_token')) {
          refreshAccessToken();
        }
      },
    ));

    PackageInfo.fromPlatform().then((info) =>
        _client.options.headers['User-Agent'] =
            '${info.packageName}:${info.version} (by /u/Albert221)');
  }

  set _accessToken(String accessToken) {
    if (accessToken != null) {
      _client.options.headers['Authorization'] = 'Bearer $accessToken';
      _client.options.baseUrl = 'https://oauth.reddit.com';
    } else {
      _client.options.headers.remove('Authorization');
      _client.options.baseUrl = 'https://www.reddit.com';
    }
  }

  Future<void> refreshAccessToken([String refreshToken]) {
    final basicAuth = 'Basic ' +
        base64.encode(utf8.encode('${ReddigramConsts.oauthClientId}:'));

    return post(
      '/api/v1/access_token',
      data:
          'grant_type=refresh_token&refresh_token=${refreshToken ?? _refreshToken}',
      headers: {'Authorization': basicAuth},
    ).then((response) => _accessToken = response.data['access_token']);
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  static ListingResponse _filterOnlyPhotos(ListingResponse response) {
    return response.rebuild((b) => b
      ..data = response.data
          .rebuild((b) => b
            ..children = ListBuilder(response.data.children
                .where((child) => child.data.preview != null)))
          .toBuilder());
  }

  void _assertAuthorized() {
    assert(
        _client.options.headers.containsKey('Authorization'), 'User required.');
  }

  Future<Response> post(String path,
      {String data, Map<String, dynamic> headers}) async {
    return _client.post(
      path,
      data: data,
      options: Options(
        headers: headers,
        contentType: ContentType.parse('application/x-www-form-urlencoded'),
      ),
    );
  }

  Future<String> retrieveTokens(String code) async {
    final basicAuth = 'Basic ' +
        base64.encode(utf8.encode('${ReddigramConsts.oauthClientId}:'));

    return post(
      '/api/v1/access_token',
      data: 'grant_type=authorization_code&code=$code'
          '&redirect_uri=https://reddigram.wolszon.me/redirect',
      headers: {'Authorization': basicAuth},
    ).then((response) {
      _accessToken = response.data['access_token'];
      return _refreshToken = response.data['refresh_token'];
    });
  }

  Future<ListingResponse> best({String after = '', int limit = 25}) async {
    return _client
        .get('/best.json?after=$after&limit=$limit')
        .then((response) => serializers.deserializeWith(
            ListingResponse.serializer, response.data))
        .then(_filterOnlyPhotos);
  }

  Future<ListingResponse> subreddit(String name,
      {String after = '', int limit = 25}) async {
    return _client
        .get('/r/$name.json?after=$after&limit=$limit')
        .then((response) => serializers.deserializeWith(
            ListingResponse.serializer, response.data))
        .then(_filterOnlyPhotos);
  }

  Future<String> username() async {
    _assertAuthorized();

    return _client.get('/api/v1/me').then((response) => response.data['name']);
  }

  Future<void> upvote(String id) async {
    _assertAuthorized();

    return post('/api/vote', data: 'dir=1&id=$id');
  }

  Future<void> cancelUpvote(String id) async {
    _assertAuthorized();

    return post('/api/vote', data: 'dir=0&id=$id');
  }
}