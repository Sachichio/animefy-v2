import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://api.jikan.moe/v4";

  // Fitur home popular anime
  static Future<List<dynamic>> fetchTopAnime() async {
    final response = await http.get(Uri.parse("$baseUrl/top/anime"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception("Gagal memuat data anime populer");
    }
  }

  // Fitur home ongoing anime
  static Future<List<dynamic>> fetchAiringAnime() async {
    final response = await http.get(Uri.parse("$baseUrl/seasons/now"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception("Gagal memuat anime yang sedang tayang");
    }
  }

  // Fitur home upcoming anime
  static Future<List<dynamic>> fetchUpcomingAnime() async {
    final response = await http.get(Uri.parse("$baseUrl/seasons/upcoming"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception("Gagal memuat anime mendatang");
    }
  }

  // Fitur pencarian
  static Future<List<dynamic>> searchAnime(String query) async {
    final response = await http.get(
      Uri.parse("$baseUrl/anime?q=$query"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception("Gagal mencari anime");
    }
  }
}