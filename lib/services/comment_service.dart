import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CommentService {
  static const String baseUrl =
      "https://692c6b34c829d464006f84a7.mockapi.io/Comments";

  /// URL Users untuk ambil username, role, avatar
  static const String usersUrl =
      "https://692c6a37c829d464006f81bc.mockapi.io/Users";

  // ============================================================
  // GET COMMENTS BY mal_id
  // ============================================================
  static Future<List<dynamic>> getComments(int malId) async {
    final url = Uri.parse("$baseUrl?mal_id=$malId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw Exception("Failed to load comments");
    }
  }

  // ============================================================
  // POST NEW COMMENT
  // ============================================================
  static Future<bool> addComment(
      String userId, int malId, String commentText) async {
    final url = Uri.parse(baseUrl);

    final body = jsonEncode({
      "userId": userId,
      "mal_id": malId,
      "commentText": commentText,
      "timestamp": DateTime.now().toIso8601String(),
      "edited": false,
    });

    final response = await http.post(
      url,
      body: body,
      headers: {"Content-Type": "application/json"},
    );

    return response.statusCode == 201;
  }

  // ============================================================
  // EDIT COMMENT
  // ============================================================
  static Future<bool> editComment(String commentId, String newText) async {
    final url = Uri.parse("$baseUrl/$commentId");

    final body = jsonEncode({
      "commentText": newText,
      "edited": true,
    });

    final response = await http.put(
      url,
      body: body,
      headers: {"Content-Type": "application/json"},
    );

    return response.statusCode == 200;
  }

  // ============================================================
  // DELETE COMMENT
  // ============================================================
  static Future<bool> deleteComment(String commentId) async {
    final url = Uri.parse("$baseUrl/$commentId");

    final response = await http.delete(url);

    return response.statusCode == 200;
  }

  // ============================================================
  // GET USERNAME (via userId)
  // ============================================================
  static Future<String> getUsername(String userId) async {
    final url = Uri.parse("$usersUrl/$userId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['username'] ?? "Unknown";
      }
    } catch (e) {
      debugPrint("getUsername error: $e");
    }

    return "Unknown";
  }

  // ============================================================
  // GET USER ROLE (admin / user)
  // ============================================================
  static Future<String> getUserRole(String userId) async {
    final url = Uri.parse("$usersUrl/$userId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['role'] ?? "user";
      }
    } catch (e) {
      debugPrint("getUserRole error: $e");
    }

    return "user";
  }

  // ============================================================
  // GET USER AVATAR (nullable, fallback ke ui-avatars)
  // ============================================================
  static Future<String?> getUserAvatar(String userId) async {
    final url = Uri.parse("$usersUrl/$userId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // MockAPI sering beda nama field → cek semua kemungkinan
        final avatar =
            data['avatarUrl'] ?? data['avatar'] ?? data['image'] ?? "";

        if (avatar is String && avatar.trim().isNotEmpty) {
          return avatar; // punya avatar
        }
      }
    } catch (e) {
      debugPrint("getUserAvatar error: $e");
    }

    // return null → UI fallback di comment_section
    return null;
  }
}