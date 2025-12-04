import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class FavoriteService {
  static const String _localKey = 'favorite_anime';
  static const String _apiUrl =
      'https://692c6a37c829d464006f81bc.mockapi.io/Favorites';

  /// ================= LOCAL FAVORITE =================
  static Future<void> saveFavoritesLocal(List<dynamic> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_localKey, jsonEncode(favorites));
  }

  static Future<List<dynamic>> getFavoritesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_localKey);
    if (data != null) return jsonDecode(data);
    return [];
  }

  static Future<void> addFavoriteLocal(Map<String, dynamic> anime) async {
    final favorites = await getFavoritesLocal();
    if (!favorites.any((item) => item['mal_id'] == anime['mal_id'])) {
      favorites.add(anime);
      await saveFavoritesLocal(favorites);
    }
  }

  static Future<void> removeFavoriteLocal(int malId) async {
    final favorites = await getFavoritesLocal();
    favorites.removeWhere((item) => item['mal_id'] == malId);
    await saveFavoritesLocal(favorites);
  }

  static Future<bool> isFavoriteLocal(int malId) async {
    final favorites = await getFavoritesLocal();
    return favorites.any((item) => item['mal_id'] == malId);
  }

  /// ================= SERVER FAVORITE (PER USER) =================
  static Future<List<dynamic>> getServerFavorites(String userId) async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl?userId=$userId'));

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((anime) {
          anime['image_url'] = anime['image_url'] ??
              anime['imageUrl'] ??
              (anime['images']?['jpg']?['image_url'] ?? '');
          return anime;
        }).toList();
      }
    } catch (e) {
      print('⚠ Error getServerFavorites: $e');
    }
    return [];
  }

  static Future<bool> addFavoriteServer(
      String userId, Map<String, dynamic> anime) async {
    try {
      final imageUrl = anime['image_url'] ??
          anime['imageUrl'] ??
          (anime['images']?['jpg']?['image_url'] ?? '');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'userId': userId,
          'mal_id': anime['mal_id'], // ⬅ JANGAN toString()
          'title': anime['title'] ?? 'N/A',
          'image_url': imageUrl,
          'score': anime['score'] ?? 0,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('⚠ Error addFavoriteServer: $e');
    }
    return false;
  }

  static Future<bool> removeFavoriteServer(String favoriteId) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/$favoriteId'));
      return response.statusCode == 200;
    } catch (e) {
      print('⚠ Error removeFavoriteServer: $e');
    }
    return false;
  }

  static Future<bool> toggleFavorite(Map<String, dynamic> anime,
      {String? userId}) async {
    if (userId != null) {
      try {
        final favorites = await getServerFavorites(userId);

        final exist = favorites.firstWhere(
          (item) => item['mal_id'].toString() == anime['mal_id'].toString(),
          orElse: () => null,
        );

        if (exist != null && exist['id'] != null) {
          await removeFavoriteServer(exist['id'].toString());
          return false;
        } else {
          return await addFavoriteServer(userId, anime);
        }
      } catch (e) {
        print('⚠ Error toggleFavorite: $e');
      }
    } else {
      final isFav = await isFavoriteLocal(anime['mal_id']);
      if (isFav) {
        await removeFavoriteLocal(anime['mal_id']);
        return false;
      } else {
        await addFavoriteLocal(anime);
        return true;
      }
    }
    return false;
  }

  static Future<bool> checkFavorite(Map<String, dynamic> anime,
      {String? userId}) async {
    return userId != null
        ? await isFavoriteServer(userId, anime['mal_id'])
        : await isFavoriteLocal(anime['mal_id']);
  }

  static Future<bool> isFavoriteServer(String userId, int malId) async {
    final favorites = await getServerFavorites(userId);
    return favorites.any(
      (item) => item['mal_id'].toString() == malId.toString(),
    );
  }
}