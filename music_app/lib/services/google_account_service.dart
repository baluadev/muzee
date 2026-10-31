import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:muzee/main.dart' show logger;

/// The signed-in Google account.
@immutable
class GoogleAccount {
  const GoogleAccount({required this.email, this.name, this.pictureUrl});

  factory GoogleAccount.fromUserInfo(Map<String, dynamic> json) =>
      GoogleAccount(
        email: json['email'] as String,
        name: json['name'] as String?,
        pictureUrl: json['picture'] as String?,
      );

  final String email;
  final String? name;
  final String? pictureUrl;
}

/// Google sign-in (OAuth with flutter_appauth), as in Muzee 1.x: same client,
/// scopes and stored token keys, so people signed in before the update stay
/// signed in. Used for the account card and cloud backup.
class GoogleAccountService {
  GoogleAccountService._();
  static final GoogleAccountService instance = GoogleAccountService._();

  static const _clientId =
      '812387227185-emvo8h4ins2k1fnkqbj0a99iq1lhatcs.apps.googleusercontent.com';
  static const _redirectUrl =
      'com.googleusercontent.apps.812387227185-emvo8h4ins2k1fnkqbj0a99iq1lhatcs:/oauth2redirect';
  static const _scopes = [
    'openid',
    'email',
    'profile',
    'https://www.googleapis.com/auth/user.phonenumbers.read',
    'https://www.googleapis.com/auth/youtube.readonly',
  ];
  static const _service = AuthorizationServiceConfiguration(
    authorizationEndpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
    tokenEndpoint: 'https://oauth2.googleapis.com/token',
  );
  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final account = ValueNotifier<GoogleAccount?>(null);
  final busy = ValueNotifier<bool>(false);

  /// Signs back in with a stored refresh token, if there is one.
  Future<void> restore() async {
    final refreshToken = await _read(_refreshTokenKey);
    if (refreshToken == null) return;
    final accessToken = await _refresh(refreshToken);
    if (accessToken != null) await _loadProfile(accessToken);
  }

  /// Signs in. Returns true when signed in, false when it failed, and null
  /// when the user closed the Google page.
  Future<bool?> signIn() async {
    if (busy.value) return false;
    busy.value = true;
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          scopes: _scopes,
          serviceConfiguration: _service,
        ),
      );
      final accessToken = result.accessToken;
      if (accessToken == null) return false;
      await _storage.write(key: _accessTokenKey, value: accessToken);
      if (result.refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: result.refreshToken);
      }
      return _loadProfile(accessToken);
    } on FlutterAppAuthUserCancelledException {
      return null;
    } catch (e, stackTrace) {
      logger.log('Google sign-in failed', error: e, stackTrace: stackTrace);
      return false;
    } finally {
      busy.value = false;
    }
  }

  Future<void> signOut() async {
    final accessToken = await _read(_accessTokenKey);
    if (accessToken != null) {
      try {
        await http.post(
          Uri.parse('https://oauth2.googleapis.com/revoke'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'token': accessToken},
        );
      } catch (e) {
        logger.log('Revoking the Google token failed', error: e);
      }
    }
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      logger.log('Clearing stored Google tokens failed', error: e);
    }
    account.value = null;
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      // Unreadable (e.g. the keystore was reset): treat as signed out.
      logger.log('Reading stored $key failed', error: e);
      return null;
    }
  }

  Future<String?> _refresh(String refreshToken) async {
    try {
      final result = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUrl,
          refreshToken: refreshToken,
          scopes: _scopes,
          serviceConfiguration: _service,
        ),
      );
      final accessToken = result.accessToken;
      if (accessToken != null) {
        await _storage.write(key: _accessTokenKey, value: accessToken);
      }
      return accessToken;
    } catch (e) {
      logger.log('Refreshing the Google token failed', error: e);
      return null;
    }
  }

  Future<bool> _loadProfile(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode != 200) return false;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['email'] is! String) return false;
      account.value = GoogleAccount.fromUserInfo(json);
      return true;
    } catch (e) {
      logger.log('Loading the Google profile failed', error: e);
      return false;
    }
  }
}
