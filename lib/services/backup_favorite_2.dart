import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class FavoriteService {
  static const String _localKey = 'favorite_anime';
  static const String _apiUrl =
      'https://692c6a37c829d464006f81bc.mockapi.io/Favorites';

  /// =====================================================
  ///           FAVORITE LOCAL (GUEST / NON-LOGIN)
  /// =====================================================

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

  /// =====================================================
  ///                FAVORITE SERVER (USER LOGIN)
  /// =====================================================

  static Future<List<dynamic>> getServerFavorites(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$_apiUrl?userId=$userId"),
      );

      print("📥 GET favorites response: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data.map((anime) {
          // normalisasi image
          final imageUrl = anime['image_url'] ??
              anime['imageUrl'] ??
              anime['images']?['jpg']?['image_url'] ??
              'https://via.placeholder.com/150';

          // normalisasi studios & genres → list of strings
          final studios = (anime['studios'] as List<dynamic>?)
                  ?.map((e) => e['name'] ?? '')
                  .toList() ??
              [];
          final genres = (anime['genres'] as List<dynamic>?)
                  ?.map((e) => e['name'] ?? '')
                  .toList() ??
              [];

          return {
            'mal_id': anime['mal_id'],
            'title': anime['title'],
            'title_english': anime['title_english'],
            'title_japanese': anime['title_japanese'],
            'type': anime['type'],
            'episodes': anime['episodes'],
            'status': anime['status'],
            'score': anime['score'],
            'season': anime['season'],
            'duration': anime['duration'],
            'synopsis': anime['synopsis'],

            'images': {
              'jpg': {'image_url': imageUrl}
            },

            'studios': studios,
            'genres': genres,

            'id': anime['id'],
            'userId': anime['userId'],
          };
        }).toList();
      }
    } catch (e) {
      print("❌ Error getServerFavorites: $e");
    }

    return [];
  }

  static Future<bool> addFavoriteServer(
      String userId, Map<String, dynamic> anime) async {
    try {
      // normalisasi studios & genres → list of strings
      final studios = (anime['studios'] as List<dynamic>?)
              ?.map((e) => e['name'] ?? e.toString())
              .toList() ??
          [];
      final genres = (anime['genres'] as List<dynamic>?)
              ?.map((e) => e['name'] ?? e.toString())
              .toList() ??
          [];
      final imageUrl = anime['image_url'] ??
          (anime['images']?['jpg']?['image_url'] ?? '');

      final payload = {
        "userId": userId,
        "mal_id": anime['mal_id'],
        "title": anime["title"] ?? "N/A",
        "title_english": anime["title_english"] ?? "",
        "title_japanese": anime["title_japanese"] ?? "",
        "type": anime["type"] ?? "",
        "episodes": anime["episodes"] ?? 0,
        "status": anime["status"] ?? "",
        "score": anime["score"] ?? 0,
        "season": anime["season"] ?? "",
        "duration": anime["duration"] ?? "",
        "synopsis": anime["synopsis"] ?? "",
        "image_url": imageUrl,
        "studios": studios,
        "genres": genres,
      };

      print("📤 SENDING DATA:");
      print(payload);

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("📥 RESPONSE STATUS: ${response.statusCode}");
      print("📥 RESPONSE BODY: ${response.body}");

      return response.statusCode == 201;
    } catch (e) {
      print("⚠ Error addFavoriteServer: $e");
    }
    return false;
  }

  static Future<bool> removeFavoriteServer(String favoriteId) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/$favoriteId'));
      print("📥 DELETE RESPONSE: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("⚠ Error removeFavoriteServer: $e");
    }
    return false;
  }

  /// =====================================================
  ///                        TOGGLE ❤
  /// =====================================================
  static Future<bool> toggleFavorite(
    Map<String, dynamic> anime, {
    String? userId,
  }) async {
    print("➡ TOGGLE FAVORITE: ${anime['title']} (userId: $userId)");

    // USER LOGIN → server
    if (userId != null) {
      try {
        final favorites = await getServerFavorites(userId);

        Map<String, dynamic>? exist;
        for (var item in favorites) {
          if (item['mal_id'].toString() == anime['mal_id'].toString()) {
            exist = item;
            break;
          }
        }

        if (exist != null) {
          await removeFavoriteServer(exist['id'].toString());
          return false;
        }

        return await addFavoriteServer(userId, anime);
      } catch (e) {
        print("⚠ Error toggleFavorite: $e");
      }
    }

    // GUEST → LOCAL
    final isFav = await isFavoriteLocal(anime['mal_id']);
    if (isFav) {
      await removeFavoriteLocal(anime['mal_id']);
      return false;
    } else {
      await addFavoriteLocal(anime);
      return true;
    }
  }

  /// =====================================================
  ///                CHECK FAVORITE (DETAIL PAGE)
  /// =====================================================
  static Future<bool> checkFavorite(
    Map<String, dynamic> anime, {
    String? userId,
  }) async {
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