import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const String _key = 'favorite_anime';

  static Future<void> saveFavorites(List<dynamic> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_key, jsonEncode(favorites));
  }

  static Future<List<dynamic>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      return jsonDecode(data);
    }
    return [];
  }

  static Future<void> addFavorite(Map<String, dynamic> anime) async {
    final favorites = await getFavorites();
    if (!favorites.any((item) => item['mal_id'] == anime['mal_id'])) {
      favorites.add(anime);
      await saveFavorites(favorites);
    }
  }

  static Future<void> removeFavorite(int malId) async {
    final favorites = await getFavorites();
    favorites.removeWhere((item) => item['mal_id'] == malId);
    await saveFavorites(favorites);
  }

  static Future<bool> isFavorite(int malId) async {
    final favorites = await getFavorites();
    return favorites.any((item) => item['mal_id'] == malId);
  }
}