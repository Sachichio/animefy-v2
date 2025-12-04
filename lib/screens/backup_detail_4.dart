import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/favorite_service.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> anime;
  final String? userId;

  const DetailScreen({super.key, required this.anime, this.userId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isFavorite = false;

  /// Data lengkap dari API Jikan
  Map<String, dynamic>? fullData;
  bool isLoadingDetail = true;

  @override
  void initState() {
    super.initState();
    checkFavorite();
    fetchDetail();
  }

  /// ============================
  /// CEK FAVORIT
  /// ============================
  Future<void> checkFavorite() async {
    bool fav;

    if (widget.userId != null) {
      fav = await FavoriteService.isFavoriteServer(widget.userId!, widget.anime['mal_id']);
    } else {
      fav = await FavoriteService.isFavoriteLocal(widget.anime['mal_id']);
    }

    if (mounted) {
      setState(() => isFavorite = fav);
    }
  }

  /// ============================
  /// FETCH DETAIL DARI JIKAN API
  /// ============================
  Future<void> fetchDetail() async {
    try {
      final malId = widget.anime['mal_id'];
      if (malId == null) {
        setState(() => isLoadingDetail = false);
        return;
      }

      final url = Uri.parse("https://api.jikan.moe/v4/anime/$malId/full");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final data = json['data'];

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

  /// ============================
  /// IMAGE HELPER
  /// ============================
  String getImage(Map anime) {
    return anime['image_url'] ??
        anime['imageUrl'] ??
        anime['images']?['jpg']?['image_url'] ??
        "https://via.placeholder.com/200";
  }

  /// Box for info
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
    return Wrap(
      spacing: 8,
      children: list.map((e) => Chip(label: Text(e['name'] ?? ''))).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Gunakan data lengkap jika sudah ada
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
            onPressed: () async {
              // Gunakan data lengkap kalau sudah ada
              final dataToSave = fullData ?? widget.anime;
              
              final result = await FavoriteService.toggleFavorite(
                dataToSave,
                userId: widget.userId,
              );

              setState(() => isFavorite = result);
            },
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
                  /// IMAGE
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

                  /// BASIC INFO
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
                  _studioOrGenreList(anime['studios'] as List<dynamic>?),

                  const SizedBox(height: 20),

                  Text("Genre", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _studioOrGenreList(anime['genres'] as List<dynamic>?),

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