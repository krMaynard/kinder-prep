import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';
import '../models/style_template.dart';

class StorageService {
  static const _keyApiKey = 'gemini_api_key';
  static const _keyRememberKey = 'remember_api_key';
  static const _keyProfile = 'profile';
  static const _keyStyleGuide = 'style_guide';
  static const _keyUserTemplates = 'user_style_templates';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ---------------------------------------------------------------------------
  // API key
  // ---------------------------------------------------------------------------

  Future<String?> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyRememberKey) != true) return null;
    return _secureStorage.read(key: _keyApiKey);
  }

  Future<void> saveApiKey(String key) async {
    await _secureStorage.write(key: _keyApiKey, value: key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberKey, true);
  }

  Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: _keyApiKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberKey, false);
  }

  Future<bool> isRememberKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberKey) ?? false;
  }

  Future<void> setRememberKey(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberKey, value);
    if (!value) await _secureStorage.delete(key: _keyApiKey);
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  Future<Profile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProfile);
    if (raw == null) return Profile();
    return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
  }

  // ---------------------------------------------------------------------------
  // Style guide & templates
  // ---------------------------------------------------------------------------

  Future<String> loadStyleGuide() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStyleGuide) ?? kDefaultStyleGuide;
  }

  Future<void> saveStyleGuide(String guide) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStyleGuide, guide);
  }

  Future<Map<String, String>> loadUserTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUserTemplates);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as String));
  }

  Future<void> saveUserTemplates(Map<String, String> templates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserTemplates, jsonEncode(templates));
  }

  Future<Map<String, String>> loadAllTemplates() async {
    final user = await loadUserTemplates();
    return {...kBuiltinTemplates, ...user};
  }
}
