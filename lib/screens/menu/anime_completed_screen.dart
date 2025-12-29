import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'paginated_anime_screen.dart';

Future<Map<String, dynamic>> fetchCompletedPage(int page) async {
  final url = Uri.parse(
    'https://api.jikan.moe/v4/anime?status=complete&page=$page',
  );

  final res = await http.get(url);

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    List<dynamic> items = data['data'] as List<dynamic>? ?? [];

    // KECUALIKAN GENRE HENTAI
    items = items.where((anime) {
      final genres = (anime['genres'] as List?)
              ?.map((g) => g['name'].toString().toLowerCase())
              .toList() ?? [];
      return !genres.contains("hentai");
    }).toList();

    // SORT DESCENDING berdasarkan aired.to (tanggal selesai)
    items.sort((a, b) {
      final aDate = a['aired']?['to'] ?? a['aired']?['from'] ?? '';
      final bDate = b['aired']?['to'] ?? b['aired']?['from'] ?? '';
      return bDate.toString().compareTo(aDate.toString());
    });

    final int last = (data['pagination']?['last_visible_page'] as int?) ?? page;

    return {
      'data': items,
      'lastPage': last,
    };
  } else {
    throw Exception('API error ${res.statusCode}');
  }
}

class AnimeCompletedScreen extends StatelessWidget {
  final int initialPage;

  const AnimeCompletedScreen({Key? key, this.initialPage = 1}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    int startPage = initialPage;

    if (args is Map && args['page'] is int) {
      startPage = args['page'];
    }

    return PaginatedAnimeScreen(
      title: 'Completed Anime',
      initialPage: startPage,
      fetchPage: fetchCompletedPage,
    );
  }
}