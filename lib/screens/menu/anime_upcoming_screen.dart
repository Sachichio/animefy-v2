import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'paginated_anime_screen.dart';

Future<Map<String, dynamic>> fetchUpcomingPage(int page) async {
  final url = Uri.parse(
    'https://api.jikan.moe/v4/seasons/upcoming?page=$page',
  );

  final res = await http.get(url);

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    final items = data['data'] as List<dynamic>? ?? [];
    final int last = (data['pagination']?['last_visible_page'] as int?) ?? page;

    return {
      'data': items,
      'lastPage': last,
    };
  } else {
    throw Exception('API error ${res.statusCode}');
  }
}

class AnimeUpcomingScreen extends StatelessWidget {
  final int initialPage;

  const AnimeUpcomingScreen({Key? key, this.initialPage = 1}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    int startPage = initialPage;

    if (args is Map && args['page'] is int) {
      startPage = args['page'];
    }

    return PaginatedAnimeScreen(
      title: 'Upcoming Anime',
      initialPage: startPage,
      fetchPage: fetchUpcomingPage,
    );
  }
}