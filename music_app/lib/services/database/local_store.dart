import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static final LocalStore _inst = LocalStore._internal();
  static LocalStore inst = LocalStore();

  factory LocalStore() {
    return _inst;
  }

  final String _keyAdsRemoved = 'is_ads_removed';
  // final String _user = 'user';
  final String _languageCode = 'languageCode';
  final String _countryCode = 'countryCode';
  late SharedPreferences prefs;
  LocalStore._internal();

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  String get getLanguageCode => prefs.getString(_languageCode) ?? 'en';

  Future<bool> setLanguageCode(String languageCode) async {
    return await prefs.setString(_languageCode, languageCode);
  }

  String get getCountryCode =>
      prefs.getString(_countryCode) ??
      WidgetsBinding.instance.platformDispatcher.locale.countryCode ??
      'US';

  Future<bool> setCountryCode(String countryCode) async {
    return await prefs.setString(_countryCode, countryCode);
  }

  bool get adsRemoved => prefs.getBool(_keyAdsRemoved) ?? false;

  Future<bool> setAdsRemoved(bool value) async {
    return await prefs.setBool(_keyAdsRemoved, value);
  }
}
