import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'paginated_anime_screen.dart';

Future<Map<String, dynamic>> fetchAnimeBySeason(
    int page, String season, int year) async {
  final url = Uri.parse(
      "https://api.jikan.moe/v4/seasons/$year/$season?page=$page");
  final res = await http.get(url);

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    // KECUALIKAN GENRE HENTAI
    final items = (data["data"] as List<dynamic>? ?? []).where((anime) {
      final genres = (anime['genres'] as List?)
              ?.map((g) => g['name'].toString().toLowerCase())
              .toList() ??
          [];
      return !genres.contains("hentai");
    }).toList();

    return {
      "data": items,
      "lastPage": data["pagination"]?["last_visible_page"] ?? page,
    };
  } else {
    throw Exception("Failed to load anime by season");
  }
}

class AnimeSeasonListScreen extends StatelessWidget {
  final String season;
  final int year;

  const AnimeSeasonListScreen({
    super.key,
    required this.season,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return PaginatedAnimeScreen(
      title: "Season: ${season[0].toUpperCase()}${season.substring(1)} $year",
      initialPage: 1,
      fetchPage: (page) => fetchAnimeBySeason(page, season, year),
    );
  }
}