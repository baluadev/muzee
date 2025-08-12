import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:muzee/models/user.dart';
import 'package:muzee/views/dialogs/dialog_helper.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState()) {
    checkUserLogined();
  }

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Timer? _timer;

  final String _clientId =
      '812387227185-emvo8h4ins2k1fnkqbj0a99iq1lhatcs.apps.googleusercontent.com';
  final String _redirectUrl =
      'com.googleusercontent.apps.812387227185-emvo8h4ins2k1fnkqbj0a99iq1lhatcs:/oauth2redirect';
  final List<String> _scopes = [
    'openid',
    'email',
    'profile',
    'https://www.googleapis.com/auth/user.phonenumbers.read',
    'https://www.googleapis.com/auth/youtube.readonly',
  ];

  Future<void> checkUserLogined() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken != null) {
      await refreshAccessToken();
      final accessToken = await getAccessToken();
      if (accessToken != null) {
        _fetchUserProfile(accessToken);
      }
    } else {
      // start();
    }
  }

//
  void start() {
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!state.isLoggedIn) {
        DialogHelper.showSuggesstLoginGoogle();
      }
    });
  }

  void stop() {
    _timer?.cancel();
  }

  // String? _tempRefreshToken;
  Future<void> signInWithGoogle() async {
    try {
      emit(state.copyWith(isLoading: true));

      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          scopes: _scopes,
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint:
                'https://accounts.google.com/o/oauth2/v2/auth',
            tokenEndpoint: 'https://oauth2.googleapis.com/token',
          ),
        ),
      );

      if (result.accessToken != null && result.refreshToken != null) {
        final accessToken = result.accessToken;
        final refreshToken = result.refreshToken;

        // Lưu token an toàn
        await _secureStorage.write(key: 'accessToken', value: accessToken);
        await _secureStorage.write(key: 'refreshToken', value: refreshToken);
        //
        emit(state.copyWith(
          isLoggedIn: true,
        ));

        await _fetchUserProfile(result.accessToken!);
      }

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      // print('Login error: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: 'accessToken');
  }

  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: 'refreshToken');
  }

  Future<void> _fetchUserProfile(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data);
        emit(state.copyWith(
          user: user,
          isLoggedIn: true,
        ));
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    try {
      if (refreshToken == null) {
        print("No refresh token available in memory. User must login again.");
        return;
      }

      final result = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUrl,
          refreshToken: refreshToken,
          scopes: _scopes,
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint:
                'https://accounts.google.com/o/oauth2/v2/auth',
            tokenEndpoint: 'https://oauth2.googleapis.com/token',
          ),
        ),
      );

      if (result.accessToken != null) {
        await _secureStorage.write(
          key: 'accessToken',
          value: result.accessToken,
        );
        final user = state.user?.copyWith(
          accessToken: result.accessToken,
        );
        emit(state.copyWith(user: user));
      }
    } catch (e) {
      print('Token refresh error: $e');
    }
  }

  Future<void> signOut() async {
    _secureStorage.deleteAll();
    emit(const AuthState());
  }

  Future<bool> revokeGoogleAccess() async {
    final accessToken = await getAccessToken();
    final response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/revoke'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'token': accessToken},
    );
    signOut();
    return response.statusCode == 200;
  }
}
