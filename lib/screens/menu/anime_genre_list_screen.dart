import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'paginated_anime_screen.dart';

Future<Map<String, dynamic>> fetchAnimeByGenre(int page, int genreId) async {
  final url = Uri.parse(
    "https://api.jikan.moe/v4/anime?genres=$genreId&page=$page"
  );

  final res = await http.get(url);

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    return {
      "data": data["data"] ?? [],
      "lastPage": data["pagination"]?["last_visible_page"] ?? page,
    };
  } else {
    throw Exception("Failed to load anime by genre");
  }
}

class AnimeGenreListScreen extends StatelessWidget {
  final int genreId;
  final String genreName;

  const AnimeGenreListScreen({
    super.key,
    required this.genreId,
    required this.genreName,
  });

  @override
  Widget build(BuildContext context) {
    return PaginatedAnimeScreen(
      title: "Genre: $genreName",
      initialPage: 1,
      fetchPage: (page) => fetchAnimeByGenre(page, genreId),
    );
  }
}