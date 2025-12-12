import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _themeKey = 'theme_mode';
  static const String _cartKey = 'cart_items';

  static Future<bool> saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_themeKey, isDark);
  }

  static Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  static Future<bool> saveCart(List<Map<String, dynamic>> cart) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_cartKey, jsonEncode(cart));
  }

  static Future<List<Map<String, dynamic>>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString(_cartKey);
    if (cartString == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(cartString));
  }

  static Future<bool> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }
}