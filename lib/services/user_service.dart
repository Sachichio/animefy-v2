import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  static const String baseUrl =
      "https://692c6a37c829d464006f81bc.mockapi.io/Users";

  // Cache userId → username
  static final Map<String, String> _usernameCache = {};

  /// ================================
  /// GET FULL USER DATA BY ID
  /// ================================
  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final url = Uri.parse("$baseUrl/$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error getUserById: $e");
    }
    return null;
  }

  /// ================================
  /// GET USERNAME BY ID (AUTO CACHE)
  /// ================================
  static Future<String?> getUsernameById(String userId) async {
    // Cek cache dulu
    if (_usernameCache.containsKey(userId)) {
      return _usernameCache[userId];
    }

    try {
      final user = await getUserById(userId);

      if (user != null && user['username'] != null) {
        final username = user['username'] as String;

        // Simpan ke cache
        _usernameCache[userId] = username;

        return username;
      }
    } catch (e) {
      print("Error getUsernameById: $e");
    }

    return null;
  }

  /// OPTIONAL: ambil role user (admin/user)
  static Future<String?> getUserRole(String userId) async {
    final user = await getUserById(userId);
    return user?['role'];
  }
}