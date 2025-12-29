import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'paginated_anime_screen.dart';

Future<Map<String, dynamic>> fetchPopularPage(int page) async {
  final url = Uri.parse('https://api.jikan.moe/v4/top/anime?page=$page');
  final res = await http.get(url);

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    List<dynamic> items = data['data'] as List<dynamic>? ?? [];

    // KECUALIKAN GENRE HENTAI
    items = items.where((anime) {
      final genres = anime['genres'] as List<dynamic>? ?? [];
      final genreNames = genres.map((g) => g['name']?.toString().toLowerCase()).toList();
      return !genreNames.contains("hentai");
    }).toList();

    final int last = (data['pagination']?['last_visible_page'] as int?) ?? page;
    return {'data': items, 'lastPage': last};
  } else {
    throw Exception('API error ${res.statusCode}');
  }
}

class AnimePopularScreen extends StatelessWidget {
  final int initialPage;
  const AnimePopularScreen({Key? key, this.initialPage = 1}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // jika route di-push dengan arguments: {"page": 3}, ambil itu:
    final args = ModalRoute.of(context)?.settings.arguments;
    int startPage = initialPage;
    if (args is Map && args['page'] is int) {
      startPage = args['page'] as int;
    }

    return PaginatedAnimeScreen(
      title: 'Popular Anime',
      initialPage: startPage,
      fetchPage: fetchPopularPage,
    );
  }
}