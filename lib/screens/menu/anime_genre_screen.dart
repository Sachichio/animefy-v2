import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'anime_genre_list_screen.dart';

class AnimeGenreScreen extends StatefulWidget {
  const AnimeGenreScreen({super.key});

  @override
  State<AnimeGenreScreen> createState() => _AnimeGenreScreenState();
}

class _AnimeGenreScreenState extends State<AnimeGenreScreen> {
  List<dynamic> genres = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchGenres();
  }

  Future<void> fetchGenres() async {
    final url = Uri.parse("https://api.jikan.moe/v4/genres/anime");

    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        genres = (data["data"] ?? [])
            .where((g) => g["name"].toString().toLowerCase() != "hentai")
            .toList();

        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  // EMOJI BERDASARKAN GENRE
  String emojiForGenre(String name) {
    final n = name.toLowerCase();
    if (n.contains("action")) return "⚔";
    if (n.contains("adventure")) return "🧭";
    if (n.contains("comedy")) return "😂";
    if (n.contains("drama")) return "🎭";
    if (n.contains("fantasy")) return "✨";
    if (n.contains("horror")) return "👻";
    if (n.contains("mystery")) return "🕵️";
    if (n.contains("romance")) return "❤️";
    if (n.contains("sci-fi")) return "🔭";
    if (n.contains("sports")) return "🏆";
    if (n.contains("supernatural")) return "🔮";
    if (n.contains("military")) return "🎖";
    if (n.contains("psychological")) return "🧠";
    if (n.contains("slice")) return "🍃";
    return "⭐"; // default emoji
  }

  // CARD COLOR (DARK/LIGHT MODE)
  Color cardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.grey.shade900
        : Colors.grey.shade200;
  }

  // TEXT COLOR AUTO
  Color textColor(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.color!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Genre Anime",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: genres.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,        // Grid 2 kolom
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) {
                final g = genres[index];
                final name = g["name"];
                final count = g["count"] ?? 0;
                final emoji = emojiForGenre(name);

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnimeGenreListScreen(
                          genreId: g["mal_id"],
                          genreName: name,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          emoji,
                          style: const TextStyle(
                            fontSize: 36,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$count anime",
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor(context).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}