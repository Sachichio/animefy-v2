import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'anime_season_list_screen.dart';

class AnimeSeasonScreen extends StatefulWidget {
  const AnimeSeasonScreen({super.key});

  @override
  State<AnimeSeasonScreen> createState() => _AnimeSeasonScreenState();
}

class _AnimeSeasonScreenState extends State<AnimeSeasonScreen> {
  List<Map<String, dynamic>> seasons = [];
  bool loading = true;
  bool newestFirst = true; // 🔥 Sorting toggle

  @override
  void initState() {
    super.initState();
    fetchSeasons();
  }

  Future<void> fetchSeasons() async {
    final url = Uri.parse("https://api.jikan.moe/v4/seasons");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List<dynamic> raw = data["data"] ?? [];

      List<Map<String, dynamic>> temp = [];

      for (var item in raw) {
        final year = item["year"];
        final List<dynamic> listSeason = item["seasons"] ?? [];

        for (var s in listSeason) {
          temp.add({
            "season": s.toString().toLowerCase(),
            "year": year,
          });
        }
      }

      temp.sort((a, b) => b["year"].compareTo(a["year"])); // default newest first

      setState(() {
        seasons = temp;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  // ICON EMOJI MUSIM
  String getEmoji(String season) {
    switch (season) {
      case "winter":
        return "❄";
      case "spring":
        return "🌸";
      case "summer":
        return "☀";
      case "fall":
        return "🍁";
    }
    return "";
  }

  // WARNA CARD YANG ADAPTIF DARK/LIGHT MODE
  Color cardColor(BuildContext context, String season) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      switch (season) {
        case "winter":
          return Colors.blueGrey.shade800;
        case "spring":
          return Colors.pink.shade700;
        case "summer":
          return Colors.orange.shade700;
        case "fall":
          return Colors.brown.shade700;
      }
      return Colors.grey.shade800;
    } else {
      switch (season) {
        case "winter":
          return Colors.blue.shade100;
        case "spring":
          return Colors.pink.shade100;
        case "summer":
          return Colors.yellow.shade200;
        case "fall":
          return Colors.orange.shade200;
      }
      return Colors.grey.shade300;
    }
  }

  // 🔥 Fungsi toggle sorting
  void toggleSort() {
    setState(() {
      newestFirst = !newestFirst;

      seasons.sort((a, b) =>
          newestFirst ? b["year"].compareTo(a["year"]) : a["year"].compareTo(b["year"]));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Season Anime", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip:
                newestFirst ? "Sort: Newest First" : "Sort: Oldest First",
            icon: Icon(newestFirst ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: toggleSort,
          ),
        ],
        elevation: 2,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: seasons.length,
              itemBuilder: (context, index) {
                final s = seasons[index];
                final season = s["season"];
                final year = s["year"];
                final emoji = getEmoji(season);

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AnimeSeasonListScreen(season: season, year: year),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor(context, season),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "$emoji ${season[0].toUpperCase()}${season.substring(1)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "$year",
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(context).textTheme.bodyLarge!.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}