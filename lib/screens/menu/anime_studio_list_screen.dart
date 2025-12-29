import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'paginated_anime_screen.dart';

Future<Map<String, dynamic>> fetchAnimeByStudio(int page, int studioId) async {
  final url = Uri.parse(
    "https://api.jikan.moe/v4/anime?producers=$studioId&page=$page",
  );

  final res = await http.get(url);

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    return {
      "data": data["data"] ?? [],
      "lastPage": data["pagination"]?["last_visible_page"] ?? page,
    };
  } else {
    throw Exception("Failed to load anime by studio");
  }
}

class AnimeStudioListScreen extends StatelessWidget {
  final int studioId;
  final String studioName;

  const AnimeStudioListScreen({
    super.key,
    required this.studioId,
    required this.studioName,
  });

  @override
  Widget build(BuildContext context) {
    return PaginatedAnimeScreen(
      title: "Studio: $studioName",
      initialPage: 1,
      fetchPage: (page) => fetchAnimeByStudio(page, studioId),
    );
  }
}