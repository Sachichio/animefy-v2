import 'dart:convert';
import 'package:http/http.dart' as http;

class CommentService {
  static const String baseUrl =
      "https://692c6b34c829d464006f84a7.mockapi.io/Comments";

  /// GET comments by mal_id
  static Future<List<dynamic>> getComments(int malId) async {
    final url = Uri.parse("$baseUrl?mal_id=$malId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw Exception("Failed to load comments");
    }
  }

  /// POST new comment
  static Future<bool> addComment(
      String userId, int malId, String commentText) async {
    final url = Uri.parse(baseUrl);

    final body = jsonEncode({
      "userId": userId,
      "mal_id": malId,
      "commentText": commentText,
      "timestamp": DateTime.now().toIso8601String()
    });

    final response = await http.post(
      url,
      body: body,
      headers: {"Content-Type": "application/json"},
    );

    return response.statusCode == 201;
  }
}