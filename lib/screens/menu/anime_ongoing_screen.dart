import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'paginated_anime_screen.dart';

Future<Map<String, dynamic>> fetchOngoingPage(int page) async {
  final url = Uri.parse('https://api.jikan.moe/v4/seasons/now?page=$page');
  final res = await http.get(url);

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    final items = data['data'] as List<dynamic>? ?? [];

    // KECUALIKAN GENRE HENTAI
    final filtered = items.where((anime) {
      final genres = (anime['genres'] as List?)
              ?.map((g) => g['name'].toString().toLowerCase())
              .toList() ??
          [];

      return !genres.contains("hentai");
    }).toList();

    final int last = (data['pagination']?['last_visible_page'] as int?) ?? page;

    return {
      'data': filtered,
      'lastPage': last,
    };
  } else {
    throw Exception('API error ${res.statusCode}');
  }
}

class AnimeOngoingScreen extends StatelessWidget {
  final int initialPage;

  const AnimeOngoingScreen({Key? key, this.initialPage = 1}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Read arguments like popular screen
    final args = ModalRoute.of(context)?.settings.arguments;
    int startPage = initialPage;

    if (args is Map && args['page'] is int) {
      startPage = args['page'] as int;
    }

    return PaginatedAnimeScreen(
      title: 'Ongoing Anime',
      initialPage: startPage,
      fetchPage: fetchOngoingPage,
    );
  }
}