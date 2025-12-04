import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/favorite_service.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> anime;
  final String? userId;

  const DetailScreen({
    super.key,
    required this.anime,
    this.userId,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isFavorite = false;

  Map<String, dynamic>? fullData;
  bool isLoadingDetail = true;

  @override
  void initState() {
    super.initState();
    checkFavorite();
    fetchDetail();
  }

  // ============================================================
  // CEK FAVORIT
  // ============================================================
  Future<void> checkFavorite() async {
    bool fav;

    if (widget.userId != null) {
      fav = await FavoriteService.isFavoriteServer(
        widget.userId!,
        widget.anime['mal_id'],
      );
    } else {
      fav = await FavoriteService.isFavoriteLocal(widget.anime['mal_id']);
    }

    if (mounted) setState(() => isFavorite = fav);
  }

  // ============================================================
  // FETCH DETAIL (JIKAN)
  // ============================================================
  Future<void> fetchDetail() async {
    try {
      final malId = widget.anime['mal_id'];

      final url = Uri.parse("https://api.jikan.moe/v4/anime/$malId/full");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];

        if (mounted) {
          setState(() {
            fullData = data;
            isLoadingDetail = false;
          });
        }
      }
    } catch (e) {
      print("Fetch detail error: $e");
      if (mounted) setState(() => isLoadingDetail = false);
    }
  }

  // ============================================================
  // NORMALISASI GAMBAR
  // ============================================================
  String getImage(Map anime) {
    return anime['image_url'] ??
        anime['imageUrl'] ??
        anime['images']?['jpg']?['image_url'] ??
        "https://via.placeholder.com/200";
  }

  // ============================================================
  // TOGGLE FAVORITE (FIXED & NORMALIZED)
  // ============================================================
  Future<void> toggleFavorite() async {
    final raw = fullData ?? widget.anime;

    // NORMALISASI DATA → agar cocok dengan FavoriteService & MockAPI
    final normalized = {
      "mal_id": raw["mal_id"] ?? raw["malId"],
      "title": raw["title"],
      "title_english": raw["title_english"] ?? raw["titleEnglish"],
      "title_japanese": raw["title_japanese"] ?? raw["titleJapanese"],
      "type": raw["type"],
      "episodes": raw["episodes"],
      "status": raw["status"],
      "score": raw["score"],
      "season": raw["season"],
      "duration": raw["duration"],
      "synopsis": raw["synopsis"],

      // Normalisasi gambar dari Jikan
      "image_url": raw['image_url']
          ?? raw['imageUrl']
          ?? raw['images']?['jpg']?['image_url'],

      // Normalisasi List → List<String>
      "studios": (raw["studios"] as List<dynamic>?)
              ?.map((e) => e["name"] ?? "")
              .toList() ??
          [],

      "genres": (raw["genres"] as List<dynamic>?)
              ?.map((e) => e["name"] ?? "")
              .toList() ??
          [],
    };

    final result = await FavoriteService.toggleFavorite(
      normalized,
      userId: widget.userId,
    );

    setState(() => isFavorite = result);
  }

  // ============================================================
  // UI HELPERS
  // ============================================================
  Widget _infoBox(String? text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      child: Text(text ?? "N/A"),
    );
  }

  Widget _infoChip(String label, String? value) {
    return Chip(
      label: Text("$label: ${value ?? 'N/A'}"),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _studioOrGenreList(List<dynamic>? list) {
    if (list == null || list.isEmpty) return const Text("N/A");

    // Karena kita NORMALISASI menjadi List<String>
    return Wrap(
      spacing: 8,
      children: list.map((e) => Chip(label: Text(e.toString()))).toList(),
    );
  }

  // ============================================================
  // BUILD UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final anime = fullData ?? widget.anime;

    return Scaffold(
      appBar: AppBar(
        title: Text(anime['title'] ?? "Detail Anime"),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: toggleFavorite,
          )
        ],
      ),
      body: isLoadingDetail && fullData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        getImage(anime),
                        height: 260,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _infoChip("Type", anime['type']?.toString()),
                      _infoChip("Episode", anime['episodes']?.toString()),
                      _infoChip("Status", anime['status']?.toString()),
                      _infoChip("Score", anime['score']?.toString()),
                      _infoChip("Season", anime['season']?.toString()),
                      _infoChip("Duration", anime['duration']?.toString()),
                    ],
                  ),

                  const SizedBox(height: 30),
                  Text("English", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _infoBox(anime['title_english']?.toString()),

                  const SizedBox(height: 20),
                  Text("Japanese", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _infoBox(anime['title_japanese']?.toString()),

                  const SizedBox(height: 20),
                  Text("Studio", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _studioOrGenreList(anime['studios']),

                  const SizedBox(height: 20),
                  Text("Genre", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _studioOrGenreList(anime['genres']),

                  const SizedBox(height: 40),
                  Text(
                    "Sinopsis",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    anime['synopsis'] ?? "Tidak ada sinopsis.",
                    textAlign: TextAlign.justify,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
    );
  }
}